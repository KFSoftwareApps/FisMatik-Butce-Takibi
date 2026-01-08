import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../utils/currency_formatter.dart';
import 'package:uuid/uuid.dart';
import 'package:fismatik/models/receipt_model.dart';
import 'package:fismatik/models/credit_model.dart';
import 'package:fismatik/models/category_model.dart';
import 'package:fismatik/models/subscription_model.dart';
import 'package:fismatik/models/shopping_item_model.dart';
import 'package:fismatik/services/notification_service.dart';
import 'package:fismatik/services/auth_service.dart';
import 'package:fismatik/models/membership_model.dart';
import 'package:fismatik/services/product_normalization_service.dart';
import 'package:fismatik/services/network_time_service.dart';
import 'package:fismatik/services/data_refresh_service.dart';

class SupabaseDatabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final DataRefreshService _refreshService = DataRefreshService();



  // Static cache for household_id to prevent redundant queries in streams
  static String? _cachedHouseholdId;
  static String? _cachedHouseholdUserId;
  static String? _cachedOwnerId;
  static String? _cachedTier;

  // --- KULLANICI ID ---
  User? get currentUser => _client.auth.currentUser;

  // --- KREDİLER İŞLEMLERİ ---
  
  Future<void> deleteDemoData() async {
    final uid = _userId;
    try {
      await _client.from('receipts').delete().eq('user_id', uid).eq('source', 'demo');
      await _client.from('subscriptions').delete().eq('user_id', uid).eq('source', 'demo');
      await _client.from('user_credits').delete().eq('user_id', uid).eq('source', 'demo');
    } catch (e) {
      print("Demo verileri silinirken hata: $e");
    }
  }

  Stream<List<Credit>> getCredits() async* {
    final uid = _userId;
    final familyId = await _getFamilyIdForCurrentUser();
    
    if (familyId == null) {
      yield* _client
          .from('user_credits')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .map((data) => data.map((e) => Credit.fromMap(e)).toList());
    } else {
      yield* _client
          .from('user_credits')
          .stream(primaryKey: ['id'])
          .eq('household_id', familyId)
          .order('created_at', ascending: false)
          .map((data) => data.map((e) => Credit.fromMap(e)).toList());
    }
  }

  Future<void> addCredit(Credit credit) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu kapalı');

    final familyId = await _getFamilyIdForCurrentUser();

    if (credit.source != 'demo') {
      await deleteDemoData();
    }

    await _client.from('user_credits').insert({
      ...credit.toMap(),
      'user_id': user.id,
      if (familyId != null) 'household_id': familyId,
    });
    _refreshService.notifyUpdate();
  }

  Future<void> deleteCredit(String creditId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu kapalı');
    
    await _client.from('user_credits').delete().eq('id', creditId);
    _refreshService.notifyUpdate();
  }

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception("Kullanıcı girişi yapılmamış!");
    }
    return user.id;
  }

  // --- AİLE / SCOPE YARDIMCILARI ---

  Future<String?> _getFamilyIdForCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        _cachedHouseholdId = null;
        _cachedHouseholdUserId = null;
        return null; // Sessizce çık
      }

      // Return cached value if user is same
      if (_cachedHouseholdId != null && _cachedHouseholdUserId == user.id) {
        return _cachedHouseholdId;
      }

      final response = await _client
          .from('household_members')
          .select('household_id')
          .eq('user_id', user.id)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );

      if (response != null && response['household_id'] != null) {
        final familyId = response['household_id'] as String;
        
        // Cache the result
        _cachedHouseholdId = familyId;
        _cachedHouseholdUserId = user.id;
        
        return familyId;
      }
    } catch (e) {
      // Log kirliliği yapma
    }
    return null;
  }

  /// Caches can be cleared if needed (e.g. after leaving family)
  static void clearCache() {
    _cachedHouseholdId = null;
    _cachedHouseholdUserId = null;
    _cachedOwnerId = null;
    _cachedTier = null;
  }

  Future<String> _getScopeOwnerId() async {
    if (_cachedOwnerId != null) return _cachedOwnerId!;

    try {
      final familyId = await _getFamilyIdForCurrentUser();
      if (familyId != null) {
        final familyRes = await _client
            .from('households')
            .select('owner_id')
            .eq('id', familyId)
            .maybeSingle();
        
        if (familyRes != null && familyRes['owner_id'] != null) {
          _cachedOwnerId = familyRes['owner_id'] as String;
          return _cachedOwnerId!;
        }
      }
    } catch (e) {
      print("Scope owner ID alınırken hata: $e");
    }
    _cachedOwnerId = _userId;
    return _userId;
  }

  Future<List<Receipt>> getReceiptsOnce() async {
    final userIds = await _getScopeUserIds();
    final response = await _client
        .from('receipts')
        .select()
        .filter('user_id', 'in', userIds)
        .order('date', ascending: false);
    return (response as List).map((e) => Receipt.fromMap(e)).toList();
  }

  Future<MembershipTier> getCurrentTier() async {
    final authService = AuthService();
    final tier = await authService.getCurrentTier();
    _cachedTier = tier.id;
    return tier;
  }

  Future<double> getMonthlyLimitOnce() async {
    final ownerId = await _getScopeOwnerId();
    final res = await _client.from('user_settings').select('monthly_limit').eq('user_id', ownerId).maybeSingle();
    return (res?['monthly_limit'] as num?)?.toDouble() ?? 0;
  }

  Future<List<String>> _getScopeUserIds() async {
    final uid = _userId;
    final familyId = await _getFamilyIdForCurrentUser();

    if (familyId == null) {
      return [uid];
    }

    try {
      final membersRes = await _client
          .from('household_members')
          .select('user_id')
          .eq('household_id', familyId);

      final ids = <String>{};
      for (final m in membersRes) {
        if (m['user_id'] != null) {
          ids.add(m['user_id'] as String);
        }
      }
      return ids.toList();
    } catch (e) {
      print("scope userId listesi alınırken hata: $e");
      return [uid];
    }
  }

  // --- AİLE PLAN RPC METOTLARI ---

  Future<Map<String, dynamic>> createFamily(String name, String address) async {
    try {
      final response = await _client.rpc('create_family', params: {
        'family_name': name,
        'user_address': address,
      });
      clearCache();
      _refreshService.notifyUpdate();
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Aile oluşturma hatası: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendFamilyInvite(String email) async {
    try {
      final response = await _client.rpc('send_family_invite', params: {
        'target_email': email.trim().toLowerCase(),
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Davet gönderme hatası: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> acceptFamilyInvite(String inviteId, String address) async {
    try {
      final response = await _client.rpc('accept_family_invite', params: {
        'invite_id': inviteId,
        'user_address': address,
      });
      clearCache();
      _refreshService.notifyUpdate();
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Davet kabul hatası: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectFamilyInvite(String inviteId) async {
    try {
      final response = await _client.rpc('reject_family_invite', params: {
        'invite_id': inviteId,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Davet reddetme hatası: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> leaveFamily() async {
    try {
      final response = await _client.rpc('leave_family');
      clearCache();
      _refreshService.notifyUpdate();
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Aileden ayrılma hatası: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeFamilyMember(String userId) async {
    try {
      final response = await _client.rpc('remove_family_member', params: {
        'target_user_id': userId,
      });
      clearCache();
      _refreshService.notifyUpdate();
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Üye çıkarma hatası: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFamilyStatus() async {
    try {
      final response = await _client.rpc('get_family_status');
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Aile durumu sorgulama hatası: $e");
      return {'has_family': false};
    }
  }

  // --- KULLANICI AYARLARI ---

  Stream<Map<String, dynamic>> getUserSettings() async* {
    final ownerId = await _getScopeOwnerId();

    yield* _client
        .from('user_settings')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', ownerId)
        .map((event) {
          if (event.isNotEmpty) {
            return {
              'monthly_limit': (event.first['monthly_limit'] as num?)?.toDouble() ?? 5000.0,
              'salary_day': (event.first['salary_day'] as int?) ?? 1,
            };
          }
          return {'monthly_limit': 5000.0, 'salary_day': 1};
        });
  }

  Future<void> updateSalaryDay(int day) async {
    try {
      final ownerId = await _getScopeOwnerId();
      
      await _client.from('user_settings').upsert({
        'user_id': ownerId,
        'salary_day': day,
      });
      
      _refreshService.notifyUpdate();
    } catch (e) {
      if (e.toString().contains('42501') || e.toString().contains('violates row-level security')) {
        print("RLS Error in updateSalaryDay. Clearing cache and retrying...");
        clearCache();
        try {
            final freshOwnerId = await _getScopeOwnerId();
            await _client.from('user_settings').upsert({
              'user_id': freshOwnerId,
              'salary_day': day,
            });
            _refreshService.notifyUpdate();
            return;
        } catch (retryError) {
             throw "Maaş gününü sadece aile yöneticisi değiştirebilir.";
        }
      }
      rethrow;
    }
  }

  // --- ÜYELİK İŞLEMLERİ ---

  Stream<String> getUserTierStream() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value('standart');

    return _client
        .from('user_roles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', uid)
        .map((event) {
          if (event.isEmpty) return 'standart';
          return (event.first['tier_id'] ?? 'standart') as String;
        });
  }

  Stream<Map<String, dynamic>> getUserRoleDataStream() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value({});

    return _client
        .from('user_roles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', uid)
        .map((event) {
          return event.isEmpty ? {} : event.first;
        });
  }

  Future<void> checkAndDowngradeIfExpired() async {
    try {
      print("🔍 checkAndDowngradeIfExpired: Başlatılıyor...");
      
      final familyId = await _getFamilyIdForCurrentUser();
      
      // 1. Önce yerel kontrol (Safe Guard)
      final currentTier = await getCurrentTier();
      final userRole = await _client
          .from('user_roles')
          .select('expires_at')
          .eq('user_id', _userId)
          .maybeSingle();
      
      final expiresAtStr = userRole?['expires_at'] as String?;
      
      // Eğer yerel veriye göre süremiz varsa, hemen çık.
      if (expiresAtStr != null) {
        final now = DateTime.now().toUtc();
        final expiresAt = DateTime.parse(expiresAtStr).toUtc();
        
        if (expiresAt.difference(now).inHours > 24) {
          print("✅ (Local Check) Üyelik geçerli (${expiresAt.toIso8601String()}). Sunucu kontrolü atlanıyor.");
          
          // Arka planda sessizce sync dene, ama sonucu bekleme/önemseme
          if (currentTier.id == 'limitless_family' && familyId != null) {
             _syncFamilyData(familyId).catchError((_) {}); 
             syncFamilyPlanValidity().catchError((_) => false);
          }
          return;
        }
      }

      // 2. Aile Planı Senkronizasyonu (Kritik)
      // Önce gerçekten bir ailede miyiz bakalım.
      
      if (familyId == null && currentTier.id == 'limitless_family') {
         print("⚠️ Aile ID alınamadı ama lokal rol 'limitless_family' görünüyor. Güvenlik için işlem durduruluyor.");
         return;
      }
      
      if (familyId != null) {
        // Aile üyesiyiz, mutlaka sync denemeliyiz.
        print("👨‍👩‍👧‍👦 Aile üyesi tespit edildi ($familyId). Sync deneniyor...");
        final syncSuccess = await syncFamilyPlanValidity();
        
        if (!syncSuccess) {
          // Sync başarısız olduysa (internet yok, owner bulunamadı vs)
          // RİSK ALMA: Düşürme işlemini iptal et. Belki internet yok.
          print("⚠️ Aile Sync başarısız veya owner süresi dolmuş olabilir. Ancak risk almamak için işlem durduruluyor.");
          
          // Eğer gerçekten owner süresi dolduysa, 'check_my_expiration' bunu yakalamalı mı?
          // Hayır, önce sync ile expires_at güncellenmeli. Güncellenemiyorsa dokunma.
          return; 
        } else {
           print("✅ Aile Sync başarılı.");
        }
      }

      // 3. Sunucu Tarafı Kontrol (RPC)
      // Buraya geldiysek:
      // a) Ailede değiliz.
      // b) Ailedeyiz ve Sync başarılı oldu (tarihler güncellendi).
      // Artık sunucunun son kararı vermesine izin verebiliriz.
      print("📡 Sunucu kontrolü çağrılıyor (check_my_expiration)...");
      await _client.rpc('check_my_expiration');
      print("✅ checkAndDowngradeIfExpired tamamlandı.");

    } catch (e) {
      print("❌ Expiration check failed: $e");
    }
  }

  /// Aile üyelerinin planını, aile yöneticisiyle senkronize eder.
  /// Başarı durumunu döner.
  Future<bool> syncFamilyPlanValidity() async {
    try {
      final familyId = await _getFamilyIdForCurrentUser();
      if (familyId == null) return true; // Ailede değil, sorun yok (kendi başına takılabilir)

      // Aile yöneticisini bul
      final familyRes = await _client
          .from('households')
          .select('owner_id')
          .eq('id', familyId)
          .maybeSingle();
      
      final ownerId = familyRes?['owner_id'] as String?;
      if (ownerId == null || ownerId == _userId) return true; // Yönetici kendisi

      // Yöneticinin rol bilgilerini al
      final ownerRole = await _client
          .from('user_roles')
          .select('tier_id, expires_at')
          .eq('user_id', ownerId)
          .maybeSingle();
      
      if (ownerRole == null) return false; // Yönetici rolü alınamadı, sync başarısız

      final ownerTier = ownerRole['tier_id'] as String?;
      final ownerExpiresAtStr = ownerRole['expires_at'] as String?;

      // Sadece yönetici 'limitless_family' ise senkronize et
      if (ownerTier == 'limitless_family' && ownerExpiresAtStr != null) {
        final now = DateTime.now().toUtc();
        final ownerExpiresAt = DateTime.parse(ownerExpiresAtStr).toUtc();
        
        // Eğer yöneticinin süresi hala geçerliyse
        if (ownerExpiresAt.isAfter(now)) {
          print("🔄 Syncing family plan from owner ($ownerId)...");
          
          await _client.from('user_roles').update({
            'tier_id': 'limitless_family',
            'expires_at': ownerExpiresAtStr,
            'update_date': DateTime.now().toUtc().toIso8601String(),
          }).eq('user_id', _userId);
          
          print("✅ Family plan synced successfully.");
          return true;
        }
      }
      return false; // Yönetici premium değil veya süresi dolmuş
    } catch (e) {
      print("Family plan sync error: $e");
      return false;
    }
  }

  Future<void> updateUserTier(String tierId) async {
    try {
      // RPC kullanarak güvenli güncelleme (SQL: update_user_tier)
      // 15 saniye timeout ekle
      await _client.rpc('update_user_tier', params: {
        'target_tier_id': tierId,
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("Sunucu yanıt vermedi (RPC Timeout).");
        },
      );
    } catch (e) {
      print("Tier update error: $e");
      // RPC hatası durumunda yukarı fırlat, PaymentService yakalasın
      throw e;
    }
  }

  // --- FİŞ İŞLEMLERİ ---
  
  Future<void> saveReceipt(Map<String, dynamic> aiData, {String? city, String? district}) async {
    final source = aiData['source'] ?? 'scan';
    if (source != 'demo') {
      await deleteDemoData();
    }
    try {
      final String userId = _userId;
      final String? familyId = await _getFamilyIdForCurrentUser();
      
      // Eğer konum parametre olarak gelmediyse veritabanından/profilden çek
      String? finalCity = city;
      String? finalDistrict = district;
      
      if (finalCity == null) {
        final location = await _getUserLocation();
        finalCity = location['city'];
        finalDistrict = location['district'];
      }

      final newReceipt = Receipt(
        id: const Uuid().v4(),
        userId: userId,
        merchantName: aiData['merchantName'] ?? 'Bilinmiyor',
        date: DateTime.tryParse(aiData['date'] ?? '') ?? DateTime.now(),
        totalAmount: (aiData['totalAmount'] is int)
            ? (aiData['totalAmount'] as int).toDouble()
            : (aiData['totalAmount'] ?? 0.0),
        taxAmount: (aiData['taxAmount'] is int)
            ? (aiData['taxAmount'] as int).toDouble()
            : (aiData['taxAmount'] ?? 0.0),
        discountAmount: (aiData['discountAmount'] is int)
            ? (aiData['discountAmount'] as int).toDouble()
            : (aiData['discountAmount'] ?? 0.0),
        category: aiData['category'] ?? 'Diğer',
        items: (aiData['items'] as List)
            .map((item) => ReceiptItem(
                  name: item['name'] ?? 'Ürün',
                  price: (item['price'] is int)
                      ? (item['price'] as int).toDouble()
                      : (item['price'] ?? 0.0),
                  quantity: (item['quantity'] is int) ? (item['quantity'] as int) : 1,
                ))
            .toList(),
        isManual: false,
        familyId: familyId,
        city: finalCity,
        district: finalDistrict,
      );

      await _client.from('receipts').insert(newReceipt.toMap());
    } catch (e) {
      print("Kaydetme Hatası: $e");
      rethrow;
    }
  }

  Future<Map<String, String?>> _getUserLocation() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return {'city': null, 'district': null};

      final profile = await _client
          .from('user_profiles')
          .select('city, district')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return {'city': null, 'district': null};

      return {
        'city': profile['city'] as String?,
        'district': profile['district'] as String?,
      };
    } catch (e) {
      print("Konum getirme hatası: $e");
      return {'city': null, 'district': null};
    }
  }

  Future<void> deleteAccount(String reason) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception("Kullanıcı oturumu yok");

      // Yeni RPC çağrısı (reason parametresi ile)
      final response = await _client.rpc('request_account_deletion', params: {
        'reason': reason
      });
      
      print("Deletion request response: $response");
      
      // İşlem başarılıysa hesaptan çıkış yapma (UI tarafında yapılıyor ki dialog kapanabilsin)
      // await _client.auth.signOut();
      
    } catch (e) {
      print("Error requesting account deletion: $e");
      rethrow;
    }
  }

  Future<void> saveManualReceipt({
    required String merchantName,
    required DateTime date,
    required double totalAmount,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    required String category,
    List<ReceiptItem>? items,
    String? city,
    String? district,
    String source = 'manual',
  }) async {
    if (source != 'demo') {
      await deleteDemoData();
    }
    try {
      final String userId = _userId;
      final String? familyId = await _getFamilyIdForCurrentUser();
      
      String? finalCity = city;
      String? finalDistrict = district;

      if (finalCity == null) {
        final location = await _getUserLocation();
        finalCity = location['city'];
        finalDistrict = location['district'];
      }

      final newReceipt = Receipt(
        id: const Uuid().v4(),
        userId: userId,
        merchantName: merchantName,
        date: date,
        totalAmount: totalAmount,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        imageUrl: null,
        category: category,
        items: items ?? <ReceiptItem>[],
        isManual: true,
        familyId: familyId,
        city: finalCity,
        district: finalDistrict,
        source: source,
      );

      await _client.from('receipts').insert(newReceipt.toMap());
    } catch (e) {
      print("Manuel kayıt hatası: $e");
      rethrow;
    }
  }

  Future<void> deleteReceiptsBySource(String source) async {
    final uid = _userId;
    try {
      await _client.from('receipts').delete().eq('user_id', uid).eq('source', source);
    } catch (e) {
      print("Fiş silme hatası ($source): $e");
      rethrow;
    }
  }

  Stream<List<Receipt>> getReceipts({int? limit}) async* {
    final uid = _userId;
    final familyId = await _getFamilyIdForCurrentUser();

    // Senkronizasyonu arka planda tetikle (Opsiyonel ama geçmiş veriler için kritik)
    if (familyId != null) {
      _syncFamilyData(familyId).catchError((e) => print("Sync error: $e"));
    }

    if (familyId == null) {
      // Sadece kendi fişleri
      var query = _client
          .from('receipts')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid)
          .order('date', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      yield* query.map((data) => data.map((e) => Receipt.fromMap(e)).toList());
    } else {
      // Tüm ailenin fişleri (household_id bazlı)
      var query = _client
          .from('receipts')
          .stream(primaryKey: ['id'])
          .eq('household_id', familyId)
          .order('date', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      yield* query.map((data) => data.map((e) => Receipt.fromMap(e)).toList());
    }
  }

  Future<void> _syncFamilyData(String familyId) async {
    final userIds = await _getScopeUserIds();
    if (userIds.isEmpty) return;

    try {
      // 1. Receipts Sync
      await _client
          .from('receipts')
          .update({'household_id': familyId})
          .filter('user_id', 'in', userIds)
          .filter('household_id', 'is', null);
      
      // 2. User Credits Sync
      await _client
          .from('user_credits')
          .update({'household_id': familyId})
          .filter('user_id', 'in', userIds)
          .filter('household_id', 'is', null);

      // 3. Subscriptions Sync
      await _client
          .from('subscriptions')
          .update({'household_id': familyId})
          .filter('user_id', 'in', userIds)
          .filter('household_id', 'is', null);

      print("Family data synced for $familyId");
    } catch (e) {
      print("Sync data error: $e");
    }
  }

  /// Fişleri, abonelikleri ve kredi taksitlerini birleştirerek canlı yayınlar
  /// Fişleri, abonelikleri ve kredi taksitlerini birleştirerek canlı yayınlar
  Stream<List<Receipt>> getUnifiedReceiptsStream({DateTime? rangeStart, DateTime? rangeEnd, int limit = 50}) {
    final controller = StreamController<List<Receipt>>();
    
    // Varsayılan aralık: Son 12 ay ve gelecek 1 ay
    final start = rangeStart ?? DateTime.now().subtract(const Duration(days: 365));
    final end = rangeEnd ?? DateTime.now().add(const Duration(days: 31));

    List<Receipt> lastReceipts = [];
    List<Subscription> lastSubs = [];
    List<Credit> lastCredits = [];
    List<String> userIds = [];

    void emit() {
      final familyId = userIds.length > 1 ? "family" : null; // Basit kontrol, aslında _getFamilyIdForCurrentUser kullanılmalı ama stream içinde zor.
      
      final List<Receipt> all = List.from(lastReceipts);
      
      // Her ay için sanal fiş üret
      int totalMonths = (end.year - start.year) * 12 + end.month - start.month;
      for (int m = 0; m <= totalMonths; m++) {
        final targetMonth = (start.month + m - 1) % 12 + 1;
        final targetYear = start.year + (start.month + m - 1) ~/ 12;
        
        // Abonelikleri ekle
        for (final sub in lastSubs) {
           all.add(Receipt(
             id: 'sub_${sub.id}_${targetYear}_${targetMonth}',
             userId: userIds.first,
             merchantName: sub.name,
             date: DateTime(targetYear, targetMonth, sub.renewalDay),
             totalAmount: sub.price,
             taxAmount: 0,
             category: 'Sabit Gider',
             items: [],
             isManual: true,
           ));
        }

        // Kredileri ekle
        for (final credit in lastCredits) {
          final monthsPassed = (targetYear - credit.createdAt.year) * 12 + targetMonth - credit.createdAt.month;
          
          if (credit.totalInstallments == 999 || (monthsPassed >= 0 && monthsPassed < credit.totalInstallments)) {
             all.add(Receipt(
               id: 'credit_${credit.id}_${targetYear}_${targetMonth}',
               userId: userIds.first,
               merchantName: credit.title,
               date: DateTime(targetYear, targetMonth, credit.paymentDay),
               totalAmount: credit.monthlyAmount,
               taxAmount: 0,
               category: 'Sabit Gider',
               items: [],
               isManual: true,
             ));
          }
        }
      }

      all.sort((a, b) => b.date.compareTo(a.date));
      if (!controller.isClosed) {
        controller.add(all);
      }
    }

    _getScopeUserIds().then((ids) {
      userIds = ids;
      
      final rSub = getReceipts(limit: limit).listen((r) { lastReceipts = r; emit(); });
      final sSub = getSubscriptions().listen((s) { lastSubs = s; emit(); });
      final cSub = getCredits().listen((c) { lastCredits = c; emit(); });

      controller.onCancel = () {
        rSub.cancel();
        sSub.cancel();
        cSub.cancel();
      };
    });

    return controller.stream;
  }

  Future<List<Receipt>> getUnifiedReceiptsOnce({DateTime? rangeStart, DateTime? rangeEnd}) async {
    final start = rangeStart ?? DateTime.now().subtract(const Duration(days: 365));
    final end = rangeEnd ?? DateTime.now().add(const Duration(days: 31));

    final userIds = await _getScopeUserIds();
    if (userIds.isEmpty) return [];

    final receipts = await getReceiptsOnce();
    final subscriptions = await getSubscriptionsOnce();
    // Krediler için ayrı bir Once metodumuz yok ama stream'den ilkini alabiliriz veya sorgu atabiliriz
    // Performans için doğrudan sorgu atalım
    final credits = await _getCreditsOnce();

    final List<Receipt> all = List.from(receipts);

    // Her ay için sanal fiş üret
    int totalMonths = (end.year - start.year) * 12 + end.month - start.month;
    for (int m = 0; m <= totalMonths; m++) {
      final targetMonth = (start.month + m - 1) % 12 + 1;
      final targetYear = start.year + (start.month + m - 1) ~/ 12;
      
      // Abonelikleri ekle
      for (final sub in subscriptions) {
          all.add(Receipt(
            id: 'sub_${sub.id}_${targetYear}_${targetMonth}',
            userId: userIds.first,
            merchantName: sub.name,
            date: DateTime(targetYear, targetMonth, sub.renewalDay),
            totalAmount: sub.price,
            taxAmount: 0,
            category: 'Sabit Gider',
            items: [],
            isManual: true,
          ));
      }

      // Kredileri ekle
      for (final credit in credits) {
        final monthsPassed = (targetYear - credit.createdAt.year) * 12 + targetMonth - credit.createdAt.month;
        
        if (credit.totalInstallments == 999 || (monthsPassed >= 0 && monthsPassed < credit.totalInstallments)) {
            all.add(Receipt(
              id: 'credit_${credit.id}_${targetYear}_${targetMonth}',
              userId: userIds.first,
              merchantName: credit.title,
              date: DateTime(targetYear, targetMonth, credit.paymentDay),
              totalAmount: credit.monthlyAmount,
              taxAmount: 0,
              category: 'Sabit Gider',
              items: [],
              isManual: true,
            ));
        }
      }
    }

    // Tarih aralığına göre filtrele (Manuel fişler zaten veritabanından filtrelenebilir ama burada garantiye alalım)
    final filtered = all.where((r) => 
      r.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
      r.date.isBefore(end.add(const Duration(seconds: 1)))
    ).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<List<Credit>> _getCreditsOnce() async {
    final ownerId = await _getScopeOwnerId();
    final response = await _client
        .from('user_credits')
        .select()
        .eq('user_id', ownerId);
    return (response as List).map((e) => Credit.fromMap(e)).toList();
  }

  Stream<Receipt> getReceiptStream(String id) {
    return _client
        .from('receipts')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => Receipt.fromMap(data.first));
  }

  Future<void> updateReceipt(Receipt receipt) async {
    await _client
        .from('receipts')
        .update(receipt.toMap())
        .eq('id', receipt.id);
  }

  Future<void> deleteReceipt(String id) async {
    await _client.from('receipts').delete().eq('id', id);
  }

  Future<List<Receipt>> getAllReceiptsOnce() async {
    final userIds = await _getScopeUserIds();
    final response = await _client
        .from('receipts')
        .select()
        .filter('user_id', 'in', userIds)
        .order('date', ascending: false);
    return (response as List).map((e) => Receipt.fromMap(e)).toList();
  }

  // --- GEÇMİŞ / TARİHÇE ---

  Future<List<DateTime>> getAvailableMonths() async {
    final uid = _userId;
    final familyId = await _getFamilyIdForCurrentUser();
    
    final userIds = await _getScopeUserIds();
    final response = await _client
        .from('receipts')
        .select('date')
        .filter('user_id', 'in', userIds)
        .order('date', ascending: false);

    final Set<String> uniqueMonths = {};
    final List<DateTime> months = [];

    for (final item in response) {
      final dateStr = item['date'] as String;
      final date = DateTime.parse(dateStr);
      // YYYY-MM formatında unique key oluştur
      final key = "${date.year}-${date.month}";
      
      if (!uniqueMonths.contains(key)) {
        uniqueMonths.add(key);
        months.add(DateTime(date.year, date.month));
      }
    }
    
    return months;
  }

  Future<List<Receipt>> getReceiptsForMonth(DateTime month) async {
    final uid = _userId;
    final familyId = await _getFamilyIdForCurrentUser();
    
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    
    final userIds = await _getScopeUserIds();
    final response = await _client
        .from('receipts')
        .select()
        .filter('user_id', 'in', userIds)
        .gte('date', startOfMonth.toIso8601String())
        .lt('date', endOfMonth.toIso8601String())
        .order('date', ascending: false);

    return (response as List).map((e) => Receipt.fromMap(e)).toList();
  }

  // --- ABONELİKLER (SABİT GİDERLER) ---
  Future<void> saveSubscription(Subscription sub) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('subscriptions').upsert({
      ...sub.toMap(),
      'user_id': user.id,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Belirli bir ay için tüm harcamaları (fişler, krediler, abonelikler) birleştirir
  Future<List<Receipt>> getMonthAnalysisData(DateTime month) async {
    final uid = _userId;
    final familyId = await _getFamilyIdForCurrentUser();
    final userIds = await _getScopeUserIds(); // Subs ve Credits için hala userIds listesine ihtiyacımız olabilir
    
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    
    // 1. Fişleri çek
    var query = _client.from('receipts').select();
    if (familyId != null) {
        query = query.eq('household_id', familyId);
    } else {
        query = query.eq('user_id', uid);
    }

    final receiptsResponse = await (query as PostgrestFilterBuilder)
        .gte('date', startOfMonth.toIso8601String())
        .lt('date', endOfMonth.toIso8601String());
        
    final List<Receipt> allData = (receiptsResponse as List)
        .map((e) => Receipt.fromMap(e))
        .toList();
        
    // 2. Abonelikleri çek (Her ay aktiftirler)
    final subsResponse = await _client
        .from('subscriptions')
        .select()
        .filter('user_id', 'in', userIds);
        
    for (final sMap in subsResponse) {
      final sub = Subscription.fromMap(sMap);
      allData.add(Receipt(
        id: 'sub_${sub.id}',
        userId: userIds.first,
        merchantName: sub.name,
        date: DateTime(month.year, month.month, sub.renewalDay),
        totalAmount: sub.price,
        taxAmount: 0,
        category: 'Sabit Gider', // Sabit gider kategorisi
        items: [],
        isManual: true, // Sabit giderler "manuel" gibi davranır
      ));
    }
    
    // 3. Kredileri çek
    final creditsResponse = await _client
        .from('user_credits')
        .select()
        .filter('user_id', 'in', userIds);
        
    for (final cMap in creditsResponse) {
      final credit = Credit.fromMap(cMap);
      
      // Kredi bu ay aktif mi?
      // Kredi oluşturulma tarihi ile target month arasındaki fark
      final monthsPassed = (month.year - credit.createdAt.year) * 12 + month.month - credit.createdAt.month;
      
      // Eğer kredi kartı borcuysa (999) veya taksitleri bitmediyse ekle
      if (credit.totalInstallments == 999 || (monthsPassed >= 0 && monthsPassed < credit.totalInstallments)) {
         allData.add(Receipt(
           id: 'credit_${credit.id}',
           userId: userIds.first,
           merchantName: credit.title,
           date: DateTime(month.year, month.month, credit.paymentDay),
           totalAmount: credit.monthlyAmount,
           taxAmount: 0,
           category: 'Sabit Gider',
           items: [],
           isManual: true,
         ));
      }
    }
    
    // Tarihe göre sırala
    allData.sort((a, b) => b.date.compareTo(a.date));
    return allData;
  }

  Future<void> deleteAllData() async {
    try {
      await _client.from('receipts').delete().eq('user_id', _userId);

      final ownerId = await _getScopeOwnerId();
      if (ownerId == _userId) {
        await _client.from('user_settings').delete().eq('user_id', ownerId);
        await _client.from('user_categories').delete().eq('user_id', ownerId);
        await _client.from('subscriptions').delete().eq('user_id', ownerId);
      }
      
      await _client.from('user_roles').delete().eq('user_id', _userId);
    } catch (e) {
      print("Sıfırlama Hatası: $e");
      rethrow;
    }
  }

  // --- BÜTÇE / AYAR İŞLEMLERİ ---

  Stream<double> getMonthlyLimit() async* {
    final ownerId = await _getScopeOwnerId();
    
    yield* _client
        .from('user_settings')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', ownerId)
        .map((event) {
          if (event.isEmpty) return 5000.0;
          return (event.first['monthly_limit'] ?? 5000.0).toDouble();
        });
  }

  Future<void> updateMonthlyLimit(double newLimit) async {
    try {
      final ownerId = await _getScopeOwnerId();
      await _client.from('user_settings').upsert({
        'user_id': ownerId,
        'monthly_limit': newLimit,
      });
      _refreshService.notifyUpdate();
    } catch (e) {
      // Stale cache check: If we get RLS error, maybe we are no longer in that family?
      if (e.toString().contains('42501') || e.toString().contains('violates row-level security')) {
        // Clear cache and retry once
        print("RLS Error encountered. Clearing cache and retrying updateMonthlyLimit...");
        clearCache();
        
        try {
          final freshOwnerId = await _getScopeOwnerId();
          await _client.from('user_settings').upsert({
            'user_id': freshOwnerId,
            'monthly_limit': newLimit,
          });
           _refreshService.notifyUpdate();
           return; // Success on retry
        } catch (retryError) {
           // If it fails again, then it's a real permission issue
           throw "Bütçe limitini sadece aile yöneticisi değiştirebilir.";
        }
      }
      rethrow;
    }
  }

  // --- KATEGORİ İŞLEMLERİ ---

  Stream<List<Category>> getCategories() async* {
    final ownerId = await _getScopeOwnerId();

    yield* _client
        .from('user_categories')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', ownerId)
        .map((event) {
          if (event.isEmpty) return Category.defaultCategories;
          final List<dynamic> catList = event.first['categories'] ?? [];
          return catList.map((e) => Category.fromMap(e)).toList();
        });
  }

  Future<List<Category>> getCategoriesOnce() async {
    final ownerId = await _getScopeOwnerId();
    final response = await _client
        .from('user_categories')
        .select()
        .eq('user_id', ownerId)
        .maybeSingle();

    if (response == null) return List.from(Category.defaultCategories);
    
    final List<dynamic> catList = response['categories'] ?? [];
    return catList.map((e) => Category.fromMap(e)).toList();
  }

  Future<void> updateCategories(List<Category> categories) async {
    final ownerId = await _getScopeOwnerId();
    await _client.from('user_categories').upsert({
      'user_id': ownerId,
      'categories': categories.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> addCategory(Category newCategory) async {
    final ownerId = await _getScopeOwnerId();
    final response = await _client
        .from('user_categories')
        .select()
        .eq('user_id', ownerId)
        .maybeSingle();

    List<Category> currentList = [];
    if (response != null) {
      currentList = (response['categories'] as List)
          .map((e) => Category.fromMap(e))
          .toList();
    } else {
      currentList = List.from(Category.defaultCategories);
    }

    currentList.add(newCategory);
    await updateCategories(currentList);
  }

  // --- ABONELİK İŞLEMLERİ ---

  Future<void> addSubscription(Subscription sub) async {
    final uid = _userId;
    final familyId = await _getFamilyIdForCurrentUser();
    
    final data = sub.toMap();
    data['user_id'] = uid;
    if (familyId != null) data['household_id'] = familyId;
    
    await _client.from('subscriptions').upsert(data);
    _refreshService.notifyUpdate();
  }

  Stream<List<Subscription>> getSubscriptions() async* {
    final uid = _userId;
    final familyId = await _getFamilyIdForCurrentUser();

    if (familyId == null) {
      yield* _client
          .from('subscriptions')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid)
          .order('renewal_day', ascending: true)
          .map((event) => event.map((e) => Subscription.fromMap(e)).toList());
    } else {
      yield* _client
          .from('subscriptions')
          .stream(primaryKey: ['id'])
          .eq('household_id', familyId)
          .order('renewal_day', ascending: true)
          .map((event) => event.map((e) => Subscription.fromMap(e)).toList());
    }
  }

  Future<List<Subscription>> getSubscriptionsOnce() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final response = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', uid)
        .order('renewal_day', ascending: true);
        
    return (response as List).map((e) => Subscription.fromMap(e)).toList();
  }

  Future<void> deleteSubscription(String id) async {
    await _client.from('subscriptions').delete().eq('id', id);
  }

  // --- İSTATİSTİK ---

  Future<int> getCurrentReceiptCount() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startStr = startOfMonth.toIso8601String();

    final userIds = await _getScopeUserIds();

    final response = await _client
        .from('receipts')
        .select('id')
        .filter('user_id', 'in', userIds)
        .eq('is_manual', false)
        .gte('date', startStr)
        .count(CountOption.exact);

    return response.count;
  }

  Future<int> getTotalReceiptCount() async {
    final userIds = await _getScopeUserIds();

    final response = await _client
        .from('receipts')
        .select('id')
        .filter('user_id', 'in', userIds)
        .count(CountOption.exact);

    return response.count;
  }

  Future<double> getTotalSpending() async {
    final userIds = await _getScopeUserIds();
    final response = await _client
        .from('receipts')
        .select('total_amount')
        .filter('user_id', 'in', userIds);

    double total = 0;
    for (final item in response) {
      total += (item['total_amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  // --- FAZ 3: ALIŞVERİŞ REHBERİ ---

  /// Verilen sorguya göre ürünleri arar ve market bazlı en uygun fiyatları getirir
  /// [sourceReceipts] verilirse client-side arama yapar, verilmezse DB'den son fişleri çeker.
  Future<List<Map<String, dynamic>>> getProductsByPrice(String query, {List<Receipt>? sourceReceipts}) async {
    if (query.isEmpty || query.length < 2) return [];

    List<Receipt> receiptsToSearch = sourceReceipts ?? [];
    
    // Eğer kaynak verilmediyse son 100 fişi çekelim (Performans için limitli)
    if (receiptsToSearch.isEmpty) {
      final userIds = await _getScopeUserIds();
      final response = await _client
          .from('receipts')
          .select()
          .filter('user_id', 'in', userIds)
          .order('date', ascending: false)
          .limit(100);
      
      receiptsToSearch = (response as List).map((e) => Receipt.fromMap(e)).toList();
    }

    final Map<String, Map<String, dynamic>> productMap = {};
    final lowerQuery = query.toLowerCase();

    for (final receipt in receiptsToSearch) {
      for (final item in receipt.items) {
        final lowerItemName = item.name.toLowerCase();
        
        // Basit "contains" araması
        if (lowerItemName.contains(lowerQuery)) {
          // Ürün adı + Market adı kombinasyonu ile unique key
          // Böylece aynı ürünün farklı marketlerdeki fiyatlarını ayrı ayrı tutabiliriz
          // Veya aynı markette farklı zamanlardaki fiyatlarını.
          // Bizim amacımız: "Hangi markette ne kadar?"
          // Bu yüzden (Ürün Adı - Market) bazında en güncelini tutalım.
          
          // Use normalized names for search results if possible
          final normalizedName = normalizeProductName(item.name);
          final key = "$normalizedName-${receipt.merchantName}";
          
          if (!productMap.containsKey(key)) {
             productMap[key] = {
               'productName': normalizedName,
               'merchantName': receipt.merchantName,
               'price': item.price,
               'date': receipt.date,
               'receiptId': receipt.id,
             };
          }
        }
      }
    }

    // Listeye çevir ve fiyata göre artan sırala (En ucuz en üstte)
    final List<Map<String, dynamic>> results = productMap.values.toList();
    results.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));

    return results;
  }


  Future<int> getCurrentManualEntryCount() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startStr = startOfMonth.toIso8601String();

    final userIds = await _getScopeUserIds();

    final response = await _client
        .from('receipts')
        .select('id')
        .filter('user_id', 'in', userIds)
        .eq('is_manual', true)
        .gte('date', startStr)
        .count(CountOption.exact);

    return response.count;
  }

  Future<int> getCurrentSubscriptionCount() async {
    final ownerId = await _getScopeOwnerId();
    final response = await _client
        .from('subscriptions')
        .select('id')
        .eq('user_id', ownerId)
        .count(CountOption.exact);
        
    return response.count;
  }

  Future<Map<String, double>> getCategorySpendingThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startStr = startOfMonth.toIso8601String();

    final userIds = await _getScopeUserIds();

    final response = await _client
        .from('receipts')
        .select('category, total_amount')
        .filter('user_id', 'in', userIds)
        .gte('date', startStr);

    final Map<String, double> spending = {};

    for (final item in response) {
      final category = item['category'] as String? ?? 'Diğer';
      final amount = (item['total_amount'] as num?)?.toDouble() ?? 0.0;
      spending[category] = (spending[category] ?? 0.0) + amount;
    }

    return spending;
  }

  Future<String> getFinancialSummary() async {
    try {
      final total = await getTotalSpending();
      final categories = await getCategorySpendingThisMonth();
      
      final buffer = StringBuffer();
      buffer.writeln("Mevcut Ay Finansal Özeti:");
      buffer.writeln("- Toplam Harcama: ${CurrencyFormatter.format(total)}");
      buffer.writeln("- Kategori Dağılımı:");
      
      categories.forEach((key, value) {
        buffer.writeln("  * $key: ${CurrencyFormatter.format(value)}");
      });
      
      return buffer.toString();
    } catch (e) {
      print("Finansal özet hatası: $e");
      return "Finansal veriler şu an alınamıyor.";
    }
  }

  // --- ADMİN İŞLEMLERİ ---

  Future<void> toggleBlockUser(String targetUserId, bool isBlocked) async {
    await _client.rpc('toggle_block_user', params: {
      'target_user_id': targetUserId,
      'is_blocked': isBlocked,
    });
  }

  Future<void> updateUserTierForAdmin(String userId, String tierId) async {
    await _client.rpc('update_user_tier_admin', params: {
      'target_user_id': userId,
      'new_tier_id': tierId,
    });
  }

  Future<void> toggleAdminStatus(String userId, bool makeAdmin) async {
    await _client.rpc('toggle_admin_status', params: {
      'target_user_id': userId,
      'make_admin': makeAdmin,
    });
  }

  Future<void> deleteUserForAdmin(String userId) async {
    try {
      await _client.rpc('admin_delete_user', params: {'target_user_id': userId});
    } catch (e) {
      print("RPC ile silme başarısız, fallback deneniyor: $e");
      await _client.from('user_roles').delete().eq('user_id', userId);
    }
  }

  Future<void> logAdminAction({
    required String action,
    required String targetUserId,
    required String details,
  }) async {
    try {
      await _client.from('admin_logs').insert({
        'admin_id': _userId,
        'action': action,
        'target_user_id': targetUserId,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Loglama hatası: $e");
    }
  }

  Future<Map<String, dynamic>> cancelDeletionRequest() async {
    try {
      final response = await _client.rpc('cancel_deletion_request');
      return response as Map<String, dynamic>;
    } catch (e) {
      print("İptal talebi hatası: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> createUserForAdmin(String email, String password, String? fullName) async {
    try {
      final response = await _client.rpc('admin_create_user', params: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Bilinmeyen hata');
      }
      
      await logAdminAction(
        action: 'CREATE_USER',
        targetUserId: response['user_id'] ?? 'unknown',
        details: 'Created user: $email',
      );
      
    } catch (e) {
      print("Kullanıcı oluşturma hatası: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _client.rpc('get_admin_stats');
      print("getAdminStats response: $response");
      return response as Map<String, dynamic>;
    } catch (e) {
      print("getAdminStats error: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsersForAdmin() async {
    try {
      final response = await _client.rpc('get_all_users_for_admin');
      print("getAllUsersForAdmin response: $response");
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print("getAllUsersForAdmin error: $e");
      rethrow;
    }
  }

  Future<Map<String, Map<String, dynamic>>> getUserStatsForAdmin() async {
    try {
      final response = await _client
          .from('receipts')
          .select('user_id, created_at');
      
      final Map<String, Map<String, dynamic>> stats = {};

      for (final item in response) {
        final userId = item['user_id'] as String;
        final createdAt = DateTime.parse(item['created_at']);

        if (!stats.containsKey(userId)) {
          stats[userId] = {
            'receipt_count': 0,
            'last_receipt_date': null,
          };
        }

        stats[userId]!['receipt_count'] = (stats[userId]!['receipt_count'] as int) + 1;
        
        final lastDate = stats[userId]!['last_receipt_date'] as DateTime?;
        if (lastDate == null || createdAt.isAfter(lastDate)) {
          stats[userId]!['last_receipt_date'] = createdAt;
        }
      }

      return stats;
    } catch (e) {
      print("Kullanıcı istatistikleri hesaplanırken hata: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getUserFamilyStatsForAdmin(String userId) async {
    try {
      final response = await _client.rpc('get_user_family_stats_for_admin', params: {
        'target_user_id': userId,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Aile istatistikleri çekilirken hata: $e");
      return {'has_family': false};
    }
  }

  Future<List<Receipt>> getRecentReceiptsForAdmin(int limit) async {
    try {
      final response = await _client
          .from('receipts')
          .select()
          .order('date', ascending: false)
          .limit(limit);

      return (response as List).map((e) => Receipt.fromMap(e)).toList();
    } catch (e) {
      print("Admin son fişler hatası: $e");
      return [];
    }
  }

  Future<List<Receipt>> getReceiptsForUser(String userId) async {
    try {
      final response = await _client
          .from('receipts')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List).map((e) => Receipt.fromMap(e)).toList();
    } catch (e) {
      print("Kullanıcı fişleri çekilirken hata: $e");
      return [];
    }
  }

  Future<bool> hasAnyUserActivity() async {
    try {
      final response = await _client
          .from('receipts')
          .select('id')
          .eq('user_id', _userId)
          .limit(1)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print("Aktivite kontrolü hatası: $e");
      return false;
    }
  }


  Future<void> archiveDeletedUser(String email) async {
    try {
      await _client.from('deleted_users').insert({
        'email': email,
        'deleted_by': _userId,
      });
    } catch (e) {
      print("Silinen kullanıcı arşivlenirken hata: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getDeletedUsers() async {
    try {
      final response = await _client
          .from('deleted_users')
          .select()
          .order('deleted_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Silinen kullanıcılar çekilirken hata: $e");
      return [];
    }
  }

  // --- ALIŞVERİŞ LİSTESİ ---
  Stream<List<ShoppingItem>> getShoppingList() async* {
    final uid = _userId;
    if (uid == null) {
      yield [];
      return;
    }

    // Üyelik tipini kontrol et
    final tier = await getCurrentTier();
    
    // Sadece Limitless Aile paketinde liste ortaktır
    final bool isShared = tier.id == 'limitless_family';
    
    List<String> targetUserIds;
    if (isShared) {
      targetUserIds = await _getScopeUserIds();
    } else {
      targetUserIds = [uid];
    }
    
    // Not: Stream üzerinden birden fazla userId filtresi 'in' ile yapılabilir
    yield* _client
        .from('shopping_items')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((event) => event
            .where((e) => targetUserIds.contains(e['user_id']))
            .map((e) => ShoppingItem.fromMap(e))
            .toList());
  }

  Future<void> addShoppingItem(String name) async {
    final uid = _userId;
    if (uid == null) return;
    
    final newItem = ShoppingItem(
      id: const Uuid().v4(),
      userId: uid,
      name: name,
      createdAt: DateTime.now(),
    );

    await _client.from('shopping_items').insert(newItem.toMap());
  }

  Future<void> toggleShoppingItem(String id, bool isChecked) async {
    await _client.from('shopping_items').update({'is_checked': isChecked}).eq('id', id);
  }

  Future<void> deleteShoppingItem(String id) async {
    await _client.from('shopping_items').delete().eq('id', id);
  }

  Future<void> deleteAllShoppingItems() async {
    final userIds = await _getScopeUserIds();
    await _client.from('shopping_items')
        .delete()
        .filter('user_id', 'in', userIds);
  }

  /// Kullanıcının son 3 aydaki en sık aldığı 10 ürünün ismini döner (normalleştirilmiş)
  Future<List<String>> getFrequentlyBoughtProducts() async {
    final receipts = await getReceiptsOnce();
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3);

    final Map<String, int> counts = {};
    for (var r in receipts) {
      if (r.date.isBefore(threeMonthsAgo)) continue;
      for (var item in r.items) {
        final normalized = normalizeProductName(item.name).trim();
        if (normalized.length > 2) {
          counts[normalized] = (counts[normalized] ?? 0) + 1;
        }
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(10).map((e) => e.key).toList();
  }

  // --- BİLDİRİMLER ---

  // --- BİLDİRİMLER ---
    Stream<List<Map<String, dynamic>>> getNotifications() {
    final controller = StreamController<List<Map<String, dynamic>>>();
    final user = _client.auth.currentUser;

    if (user == null) {
      controller.add([]);
      return controller.stream;
    }

    final email = user.email;
    final uid = user.id;
    List<Map<String, dynamic>> latestNotifications = [];
    List<Map<String, dynamic>> latestInvitations = [];

    // Helper to emit combined list
    void emitCombined() {
      // Sort by date descending
      final combined = [...latestInvitations, ...latestNotifications]..sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'].toString()) ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at'].toString()) ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      if (!controller.isClosed) {
        controller.add(combined);
      }
    }

    // 1. Realtime Notifications Stream
    final subNotifications = _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .listen((data) {
          latestNotifications = List<Map<String, dynamic>>.from(data);
          emitCombined();
        });

    // 2. Periodic Family Invitations Poll
    // Initial fetch
    Future<void> fetchInvitations() async {
      if (email == null) return;
      try {
        final res = await _client
            .from('household_invitations')
            .select('id, households(name), created_at')
            .eq('email', email.toLowerCase())
            .eq('status', 'pending');
        
        if (res is List) {
          latestInvitations = res.map((inv) {
            final household = inv['households'] as Map?;
            return {
              'id': 'invite_${inv['id']}',
              'user_id': uid,
              'title': 'Aile Daveti',
              'message': '${household?['name'] ?? 'Bilinmeyen'} ailesine davet edildiniz.',
              'type': 'family_invite',
              'is_read': false,
              'created_at': inv['created_at'] ?? DateTime.now().toIso8601String(),
              'data': {'invite_id': inv['id']}
            };
          }).toList().cast<Map<String, dynamic>>();
          emitCombined();
        }
      } catch (e) {
        print("Polling invitations error: $e");
      }
    }
    
    // Initial fetch immediately
    fetchInvitations();

    // Poll every minute
    final timer = Timer.periodic(const Duration(minutes: 1), (_) => fetchInvitations());

    controller.onCancel = () {
      subNotifications.cancel();
      timer.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> deleteNotification(String notificationId) async {
    // Sanal davet bildirimi ise veritabanı işlemini atla (RPC zaten halledecek)
    if (notificationId.startsWith('invite_')) return;

    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      print("Bildirim silme hatası ($notificationId): $e");
      rethrow;
    }
  }

  Future<void> deleteNotifications(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    try {
      await _client.from('notifications').delete().filter('id', 'in', notificationIds);
    } catch (e) {
      print("Toplu bildirim silme hatası: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getLastPriceForProduct(String productName) async {
    final userIds = await _getScopeUserIds();
    
    try {
      final response = await _client
          .from('receipts')
          .select('items, date, merchant_name')
          .filter('user_id', 'in', userIds)
          .order('date', ascending: false)
          .limit(50); 

      for (final receipt in response) {
        final items = List<dynamic>.from(receipt['items'] ?? []);
        for (final item in items) {
          if (item['name'].toString().toLowerCase() == productName.toLowerCase()) {
            return {
              'price': (item['price'] as num).toDouble(),
              'date': DateTime.parse(receipt['date']),
              'merchant': receipt['merchant_name'] ?? 'Bilinmiyor',
            };
          }
        }
      }
    } catch (e) {
      print("Fiyat geçmişi hatası: $e");
    }
    return null;
  }

  /// Birden fazla ürün için son fiyatları toplu getirir (Optimizasyon için)
  Future<Map<String, Map<String, dynamic>>> getPriceHistoryForProducts(List<String> productNames) async {
    final userIds = await _getScopeUserIds();
    final Map<String, Map<String, dynamic>> results = {};
    
    try {
      // Son 30 fişi çek ve içlerinde bu ürünleri ara
      final response = await _client
          .from('receipts')
          .select('items, date, merchant_name')
          .filter('user_id', 'in', userIds)
          .order('date', ascending: false)
          .limit(30);

      for (final receipt in response) {
        final items = List<dynamic>.from(receipt['items'] ?? []);
        for (final item in items) {
          final name = item['name'].toString().toLowerCase();
          for (final searchName in productNames) {
            final searchLower = searchName.toLowerCase();
            // Tam eşleşme kontrolü
            if (name == searchLower && !results.containsKey(searchLower)) {
              results[searchLower] = {
                'price': (item['price'] as num).toDouble(),
                'date': DateTime.parse(receipt['date']),
                'merchant': receipt['merchant_name'] ?? 'Bilinmiyor',
              };
            }
          }
        }
        // Tüm ürünler bulunduysa aramayı kes
        if (results.length == productNames.length) break;
      }
    } catch (e) {
      print("Toplu fiyat geçmişi hatası: $e");
    }
    return results;
  }

  // --- PRODUCT NORMALIZATION MAPPINGS ---

  Future<List<Map<String, dynamic>>> getGlobalProductMappings() async {
    try {
      final response = await _client
          .from('product_mappings')
          .select()
          .order('raw_name');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print("Global mapping çekme hatası: $e");
      return [];
    }
  }


  Future<void> upsertProductMapping({
    required String rawName,
    required String normalizedName,
    String? category,
  }) async {
    await _client.from('product_mappings').upsert({
      'raw_name': rawName,
      'normalized_name': normalizedName,
      'category': category,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'raw_name');
  }

  Future<void> deleteProductMapping(String id) async {
    await _client.from('product_mappings').delete().eq('id', id);
  }

  /// Finds unique product names from all receipts that are NOT in product_mappings.
  /// Also returns the count of occurances for each.
  Future<List<Map<String, dynamic>>> getUnmappedProductNames() async {
    try {
      // Step 1: Get all mappings to filter out
      final mappings = await getGlobalProductMappings();
      final mappedNames = mappings.map((m) => m['raw_name'] as String).toSet();

      // Step 2: Get all receipt items
      // Note: In a large DB, this should be done via a View or RPC for performance.
      // For now, we'll fetch unique names from all receipts.
      final response = await _client
          .from('receipts')
          .select('items');
      
      final Map<String, int> counts = {};
      
      for (final row in response) {
        final items = row['items'] as List?;
        if (items != null) {
          for (final item in items) {
            final name = item['name'] as String?;
            if (name != null && !mappedNames.contains(name)) {
              if (!counts.containsKey(name)) {
                counts[name] = 0;
                // Guess category for context
                final guessedCat = this.normalizeProductName(name); 
                // Actually, I should use the guessing logic which is in AnalysisScreen or similar. 
                // But wait, the guessing logic is better placed in the service.
              }
              counts[name] = counts[name]! + 1;
            }
          }
        }
      }

      final result = counts.entries.map((e) => {
        'name': e.key,
        'count': e.value,
        'guessed_category': 'Diğer', // Will be filled better later or via a helper
      }).toList();

      // Sort by count descending
      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return result;
    } catch (e) {
      print("Unmapped ürün getirme hatası: $e");
      return [];
    }
  }

  /// Topluluk bazlı fiyat istatistiklerini getirir (Phase 7)
  Future<Map<String, dynamic>?> getGlobalPriceStats(String normalizedName) async {
    return getLocationPriceStats(normalizedName);
  }

  /// Konum bazlı (Şehir/İlçe) fiyat istatistiklerini getirir (Phase 11)
  Future<Map<String, dynamic>?> getLocationPriceStats(
    String normalizedName, {
    String? city,
    String? district,
  }) async {
    try {
      final response = await _client.rpc('get_location_price_stats', params: {
        'p_normalized_name': normalizedName,
        'p_city': city,
        'p_district': district,
      });

      if (response != null && (response as List).isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        if (data['data_count'] == 0 || data['data_count'] == null) return null;

        return {
          'avg_price': (data['avg_price'] as num).toDouble(),
          'min_price': (data['min_price'] as num).toDouble(),
          'cheapest_merchant': data['cheapest_merchant'] ?? 'Bilinmiyor',
          'last_seen_at': DateTime.parse(data['last_seen_at']),
          'data_count': (data['data_count'] as num).toInt(),
        };
      }
    } catch (e) {
      print("Konum bazlı fiyat istatistikleri çekilirken hata: $e");
    }
    return null;
  }

  // --- AI KOÇU KULLANIM TAKİBİ ---

  Future<int> getAICoachUsageCount() async {
    final user = currentUser;
    if (user == null) return 0;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Caching logic for tier
    String tierId = _cachedTier ?? 'standart';
    if (_cachedTier == null) {
      final tier = await getCurrentTier();
      tierId = tier.id;
    }

    if (tierId == 'limitless_family') {
      final householdId = await _getFamilyIdForCurrentUser();

      if (householdId != null) {
        // Aile üyelerinin toplam harcamalarını say (SQL JOIN gerektirmeyen optimize edilmiş versiyon)
        final List<String> familyUserIds = await _getScopeUserIds();

        final res = await _client
            .from('ai_interactions')
            .select('id')
            .inFilter('user_id', familyUserIds)
            .gte('created_at', firstDayOfMonth.toIso8601String())
            .count(CountOption.exact);
        
        return res.count;
      }
    }

    // Bireysel veya ailede olmayan kullanıcı
    final res = await _client
        .from('ai_interactions')
        .select('id')
        .eq('user_id', user.id)
        .gte('created_at', firstDayOfMonth.toIso8601String())
        .count(CountOption.exact);

    return res.count;
  }

  Future<void> recordAICoachInteraction([Map<String, dynamic>? metadata]) async {
    final user = currentUser;
    if (user == null) return;

    await _client.from('ai_interactions').insert({
      'user_id': user.id,
      'metadata': metadata,
    });
  }
  Future<void> deleteUserViaEdgeFunction(String targetUserId) async {
    try {
      final response = await _client.functions.invoke(
        'delete-user',
        body: {'target_user_id': targetUserId},
      );

      if (response.status != 200) {
        throw "Fonksiyon hatası: ${response.status} - ${response.data}";
      }
      
      final data = response.data;
      if (data != null && data['error'] != null) {
        throw data['error'];
      }
    } catch (e) {
      print("Delete user edge function error: $e");
      rethrow;
    }
  }
}
