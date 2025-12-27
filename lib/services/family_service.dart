
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_model.dart';
import '../services/notification_service.dart';

class FamilyService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;
  User? get currentUser => _client.auth.currentUser;

  // --- Aile oluştur ---
  Future<String> createFamily({required String name, String address = ''}) async {
    print("DEBUG: createFamily RPC calling...");
    final response = await _client.rpc('create_family', params: {
      'family_name': name,
      'user_address': address,
    });
    print("DEBUG: createFamily response: $response");
    if (response is Map && response['success'] == true) {
      return response['family_id']?.toString() ?? 'ok';
    } else {
      throw Exception(response['message'] ?? 'Aile oluşturulamadı.');
    }
  }

  Future<Map<String, dynamic>> createFamilyWrapper(String name, String address) async {
    try {
      await createFamily(name: name, address: address);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Davet Gönder / Üye Ekle ---
  Future<void> addMemberByEmail({required String email}) async {
    print("DEBUG: addMemberByEmail RPC calling for $email...");
    final response = await _client.rpc('send_family_invite', params: {
      'target_email': email,
    });
    print("DEBUG: addMemberByEmail response: $response");
    if (response is Map && response['success'] != true) {
      throw Exception(response['message'] ?? 'Üye eklenemedi.');
    }
  }

  Future<Map<String, dynamic>> sendFamilyInvite(String email) async {
    try {
      await addMemberByEmail(email: email);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
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
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Üye Çıkar (Email ile) ---
  Future<void> removeMemberByEmail({required String email}) async {
    try {
      print("DEBUG: removeMemberByEmail started for $email");
      // Önce bu email'in user_id'sini bir yerden bulmalı veya 
      // RPC'yi email kabul edecek şekilde güncellemeli.
      // Eski sistemde rpc target_user_id alıyordu.
      // Fallback: getFamilyStatus içinden bul.
      final status = await getFamilyStatus();
      final members = (status['members'] as List?) ?? [];
      final member = members.firstWhere((m) => m['email'].toString().toLowerCase() == email.toLowerCase(), orElse: () => null);
      
      if (member != null && member['user_id'] != null) {
          await removeFamilyMemberById(member['user_id']);
      } else {
          throw Exception("Üye bulunamadı.");
      }
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
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Aile Durumunu Getir ---
  Future<Map<String, dynamic>> getFamilyStatus() async {
    print("DEBUG: getFamilyStatus RPC calling...");
    try {
      final response = await _client.rpc('get_family_status');
      print("DEBUG: getFamilyStatus response: $response");
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'has_family': false};
    } catch (e) {
      print("DEBUG: getFamilyStatus error: $e");
      return {'has_family': false};
    }
  }

  // --- Canlı Aile İzleme ---
  Stream<Family?> watchMyFamily() {
    // RPC ile canlı izleme zor, bu yüzden periyodik olarak getFamilyStatus çağırabiliriz 
    // veya Supabase realtime ile 'household_members' dinleyebiliriz.
    // Şimdilik derleme hatası olmasın diye stream dönelim.
    return Stream.periodic(const Duration(seconds: 10)).asyncMap((_) async {
       final status = await getFamilyStatus();
       if (status['has_family'] != true) return null;
       
       final membersRaw = (status['members'] as List?) ?? [];
       final members = membersRaw.map((m) => FamilyMember(
         userId: m['user_id'] ?? '',
         email: m['email'] ?? '',
         role: m['role'] ?? 'member',
         status: m['status'] ?? 'active',
       )).toList();

       return Family(
         id: '', // RPC id dönmüyor olabilir, şimdilik boş
         name: status['household_name'] ?? 'Ailem',
         ownerUserId: members.firstWhere((m) => m.role == 'owner', orElse: () => const FamilyMember(userId: '', email: '', role: '')).userId,
         members: members,
         memberEmails: members.map((m) => m.email).toList(),
         createdAt: DateTime.now(),
       );
    }).asBroadcastStream();
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
