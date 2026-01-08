
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_model.dart';
import '../services/notification_service.dart';
import '../services/supabase_database_service.dart';

class FamilyService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;
  User? get currentUser => _client.auth.currentUser;

  // --- Aile oluştur ---
  Future<String> createFamily({required String name, String address = ''}) async {
    print("DEBUG: createFamily RPC calling...");
    try {
      final response = await _client.rpc('create_family', params: {
        'name': name,
        'address': address,
      });

      print("DEBUG: createFamily RPC response: $response");

      if (response is Map && response['success'] == true) {
        return response['family_id'] as String;
      } else {
        throw Exception(response['message'] ?? "Aile oluşturulamadı.");
      }
    } catch (e) {
      print("DEBUG: createFamily error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createFamilyWrapper(String name, String address) async {
    try {
      final id = await createFamily(name: name, address: address);
      return {'success': true, 'family_id': id};
    } catch (e) {
      return {'success': false, 'message': e.toString().replaceAll("Exception:", "").trim()};
    }
  }

  // --- Davet Gönder / Üye Ekle ---
  Future<void> addMemberByEmail({required String email}) async {
    final userId = _userId;
    if (userId == null) throw Exception("Oturum açmanız gerekiyor.");

    print("DEBUG: addMemberByEmail RPC calling for $email...");
    try {
      final response = await _client.rpc('send_family_invite', params: {
        'target_email': email.trim().toLowerCase(),
      });
      print("DEBUG: addMemberByEmail RPC response: $response");
      
      if (response is Map && response['success'] == false) {
        throw Exception(response['message'] ?? "Davet gönderilemedi.");
      }
    } catch (e) {
      print("DEBUG: addMemberByEmail error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendFamilyInvite(String email) async {
    try {
      await addMemberByEmail(email: email);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString().replaceAll("Exception:", "").trim()};
    }
  }

  // --- Daveti Kabul Et ---
  Future<Map<String, dynamic>> acceptFamilyInvite(String familyId) async {
    try {
      print("DEBUG: acceptFamilyInvite RPC calling for $familyId...");
      final response = await _client.rpc('accept_family_invite', params: {
        'invite_id': familyId,
        'user_address': '',
      });
      print("DEBUG: acceptFamilyInvite response: $response");
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Daveti Reddet ---
  Future<Map<String, dynamic>> rejectFamilyInvite(String familyId) async {
    try {
      print("DEBUG: rejectFamilyInvite RPC calling for $familyId...");
      final response = await _client.rpc('reject_family_invite', params: {
        'invite_id': familyId,
      });
      print("DEBUG: rejectFamilyInvite response: $response");
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Aileden Ayrıl ---
  Future<Map<String, dynamic>> leaveFamily() async {
    try {
      print("DEBUG: leaveFamily RPC calling...");
      final response = await _client.rpc('leave_family');
      print("DEBUG: leaveFamily response: $response");
      
      // Cache'i temizle ki UI güncellensin ve eski aile verileri görünmesin
      SupabaseDatabaseService.clearCache();
      
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Üye Çıkar (Email ile) ---
  Future<void> removeMemberByEmail({required String email}) async {
    try {
      print("DEBUG: removeMemberByEmail started for $email");
      
      // 1. Önce aktif üyelerde ara
      final status = await getFamilyStatus();
      final members = (status['members'] as List?) ?? [];
      final matches = members.where((m) => m['email'].toString().toLowerCase() == email.toLowerCase());
      final member = matches.isEmpty ? null : matches.first;
      
      if (member != null && member['user_id'] != null) {
          await removeFamilyMemberById(member['user_id']);
          return;
      } 
      
      // 2. Aktif değilse, bekleyen davetlerde ara
      // (Bunu householder_id ile eşleştirerek yapmak daha güvenli olurdu ama şuanlık email/user context'i yeterli)
      final invitationRes = await _client
          .from('household_invitations')
          .select('id')
          .eq('email', email.toLowerCase())
          .eq('status', 'pending')
          .maybeSingle();

      if (invitationRes != null) {
        await _client
            .from('household_invitations')
            .delete()
            .eq('id', invitationRes['id']);
        print("DEBUG: Invitation deleted for $email");
        return;
      }
      
      throw Exception("Üye veya davet bulunamadı.");
      
    } catch (e) {
      print("DEBUG: removeMemberByEmail error: $e");
      rethrow;
    }
  }

  // --- Üye Çıkar (ID ile) ---
  Future<Map<String, dynamic>> removeFamilyMemberById(String targetId) async {
    try {
      print("DEBUG: removeFamilyMember RPC calling for $targetId...");
      final response = await _client.rpc('remove_family_member', params: {
        'target_user_id': targetId,
      });
      print("DEBUG: removeFamilyMember response: $response");
      
      // Önbelleği temizle (Kendi kendimizi silmiş olabiliriz veya durum değişti)
      SupabaseDatabaseService.clearCache();
      
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Aile Durumunu Getir ---
  Future<Map<String, dynamic>> getFamilyStatus() async {
    final userId = _userId;
    if (userId == null) return {'has_family': false};

    print("DEBUG: getFamilyStatus direct table query for $userId...");
    try {
      // 1. Üyelik kaydını bul (Ana kaynak burası olsun artık)
      final membership = await _client
          .from('household_members')
          .select()
          .eq('user_id', userId)
          .order('joined_at', ascending: false)
          .maybeSingle();

      if (membership == null) {
        print("DEBUG: No membership record found in table.");
        return {'has_family': false, 'message': 'No membership found'};
      }

      final householdId = membership['household_id'];
      print("DEBUG: Direct membership found: $householdId");

      // 2. Detayları RPC'den almayı dene (Email ve isimler için)
      try {
        final rpcRes = await _client.rpc('get_family_status');
        if (rpcRes is Map && rpcRes['has_family'] == true) {
          print("DEBUG: RPC returned family details successfully.");
          final result = Map<String, dynamic>.from(rpcRes);
          // GARANTİ: Root level role'ü buraya da koyalım (RPC'den gelmeyebilir eski versiyonda)
          if (!result.containsKey('role')) {
             result['role'] = membership['role'];
          }
          return result;
        }
      } catch (e) {
         print("DEBUG: getFamilyStatus RPC fallback failed: $e");
      }

      // 3. RPC fail olsa bile temel veriyi dönelim (Nükleer Fallback)
      final householdRes = await _client
          .from('households')
          .select()
          .eq('id', householdId)
          .single();

      final membersTable = await _client
          .from('household_members')
          .select()
          .eq('household_id', householdId);

      // Üye e-postalarını user_roles'dan ayrıca çekmeye çalış (İsteğe bağlı)
      final List<dynamic> members = membersTable as List;
      final List<String> memberIds = members.map((m) => m['user_id'] as String).toList();
      
      final Map<String, String> emailMap = {};
      try {
        final rolesRes = await _client
            .from('user_roles')
            .select('user_id, email')
            .inFilter('user_id', memberIds);
        
        for (var r in rolesRes) {
          if (r['user_id'] != null && r['email'] != null) {
            emailMap[r['user_id']] = r['email'];
          }
        }
      } catch (_) {
        // Hata olsa da devam et (Grup Üyesi fallback çalışır)
      }

      return {
        'has_family': true,
        'household_id': householdId,
        'household_name': householdRes['name'] ?? 'Ailem',
        'role': membership['role'], 
        'members': members.map((m) {
          final uid = m['user_id'] as String;
          final email = emailMap[uid] ?? (uid == userId ? (currentUser?.email ?? 'Sen') : 'Grup Üyesi');
          
          return {
            'user_id': uid,
            'email': email,
            'role': m['role'],
            'status': 'active'
          };
        }).toList(),
      };
    } catch (e) {
      print("DEBUG: getFamilyStatus fatal error: $e");
      return {'has_family': false};
    }
  }

  // --- Canlı Aile İzleme ---
  // --- Canlı Aile İzleme ---
  Stream<Family?> watchMyFamily() async* {
    // 1. Hemen ilk veriyi çek ve gönder (Bekleme yok)
    yield await _fetchFamilyData();

    // 2. Periyodik döngüye gir
    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      yield await _fetchFamilyData();
    }
  }

  Future<Family?> _fetchFamilyData() async {
    try {
       final status = await getFamilyStatus();
       if (status['has_family'] != true) {
         // Aileden çıkmışsak cache'i temizle
         SupabaseDatabaseService.clearCache();
         return null;
       }
       
       final householdId = status['household_id'];
       final membersRaw = (status['members'] as List?) ?? [];
       
       final members = membersRaw.map((m) => FamilyMember(
         userId: m['user_id'] ?? '',
         email: m['email'] ?? '',
         role: m['role'] ?? 'member',
         status: m['status'] ?? 'active',
       )).toList();

       // 2. Bekleyen Davetleri Çek ve Ekle
       if (householdId != null) {
         final pendingInvites = await getSentInvitations(householdId);
         for (var inv in pendingInvites) {
           if (!members.any((m) => m.email.toLowerCase() == inv['email'].toString().toLowerCase())) {
             members.add(FamilyMember(
               userId: 'invite_${inv['id']}',
               email: inv['email'],
               role: 'member',
               status: 'pending',
             ));
           }
         }
       }

       return Family(
         id: householdId ?? '',
         name: status['household_name'] ?? 'Ailem',
         ownerUserId: members.firstWhere((m) => m.role == 'owner', orElse: () => const FamilyMember(userId: '', email: '', role: '')).userId,
         members: members,
         memberEmails: members.map((m) => m.email).toList(),
         createdAt: DateTime.now(),
       );
    } catch (e) {
      print("DEBUG: watchMyFamily error: $e");
      return null;
    }
  }

  // --- Gönderilen Davetleri Getir ---
  Future<List<Map<String, dynamic>>> getSentInvitations(String householdId) async {
    try {
      final response = await _client
          .from('household_invitations')
          .select('id, email, status, created_at')
          .eq('household_id', householdId)
          .eq('status', 'pending'); // Sadece bekleyenler
      
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print("DEBUG: getSentInvitations error: $e");
    }
    return [];
  }

  // --- Daveti Tekrar Gönder ---
  Future<void> resendInvite(String email) async {
     await addMemberByEmail(email: email);
  }

  // --- Bekleyen Davetleri Getir ---
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    final email = currentUser?.email;
    if (email == null) return [];

    try {
      print("DEBUG: Fetching invitations for $email");
      final response = await _client
          .from('household_invitations')
          .select('id, household_id, households(name)')
          .eq('email', email.toLowerCase())
          .eq('status', 'pending');

      print("DEBUG: Raw invitations response: $response");
      
      if (response is List) {
        return response.map((inv) {
          final household = inv['households'] as Map?;
          return {
            'invitation_id': inv['id'],
            'family_id': inv['id'], // PlanScreen expects family_id to be the invite_id for accept RPC
            'family_name': household?['name'] ?? 'Bilinmeyen Aile',
            'owner_email': 'Aile Yöneticisi', // For now, simple
          };
        }).toList();
      }
    } catch (e) {
      print("DEBUG: getPendingInvitations error: $e");
    }
    return [];
  }

  // Otomatik Bağlama
  Future<void> attachCurrentUserToFamilyIfInvited() async {
    try {
      final invitations = await getPendingInvitations();
      if (invitations.isNotEmpty) {
        print("🔔 DEBUG: User has ${invitations.length} pending family invitations.");
        // Gerekirse burada bir broadcast stream veya bildirim tetiklenebilir
      }
    } catch (e) {
      print("DEBUG: attachCurrentUserToFamilyIfInvited error: $e");
    }
  }
}
