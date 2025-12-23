import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt_model.dart';
// import '../models/household_model.dart'; // Removed missing file
import '../models/credit_model.dart';
import '../models/category_model.dart';
import '../models/subscription_model.dart';
import '../models/shopping_item_model.dart';
import 'notification_service.dart';
import 'package:fismatik/services/product_normalization_service.dart';

class SupabaseDatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- KULLANICI ID ---
  User? get currentUser => _client.auth.currentUser;

  // --- KREDİLER İŞLEMLERİ ---

  Stream<List<Credit>> getCredits() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value([]);
    
    return _client
        .from('user_credits')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((data) {
          final now = DateTime.now();
          final List<Credit> activeCredits = [];

          for (final map in data) {
            final credit = Credit.fromMap(map);
            
            // Ay farkını hesapla
            final monthsPassed = (now.year - credit.createdAt.year) * 12 + now.month - credit.createdAt.month;
            
            // Eğer taksit süresi dolduysa sil (Arka planda)
            if (monthsPassed >= credit.totalInstallments) {
              _client.from('user_credits').delete().eq('id', credit.id).then((_) {
                print("Süresi dolan kredi silindi: ${credit.title}");
              });
            } else {
              activeCredits.add(credit);
            }
          }
          return activeCredits;
        });
  }

  Future<void> addCredit(Credit credit) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu kapalı');

    await _client.from('user_credits').insert({
      ...credit.toMap(),
      'user_id': user.id,
    });
  }

  Future<void> deleteCredit(String creditId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu kapalı');
    
    await _client.from('user_credits').delete().eq('id', creditId);
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
      final response = await _client
          .from('household_members')
          .select('household_id')
          .eq('user_id', _userId)
          .maybeSingle();

      if (response != null && response['household_id'] != null) {
        return response['household_id'] as String;
      }
    } catch (e) {
      print("familyId okunurken hata: $e");
    }
    return null;
  }

  Future<String> _getScopeOwnerId() async {
    final familyId = await _getFamilyIdForCurrentUser();
    if (familyId != null) {
      final familyRes = await _client
          .from('households')
          .select('owner_id')
          .eq('id', familyId)
          .maybeSingle();
      
      if (familyRes != null && familyRes['owner_id'] != null) {
        return familyRes['owner_id'] as String;
      }
    }
    return _userId;
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
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Aile oluşturma hatası: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendFamilyInvite(String email) async {
    try {
      final response = await _client.rpc('send_family_invite', params: {
        'target_email': email,
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

  Stream<Map<String, dynamic>> getUserSettings() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return Stream.value({'monthly_limit': 5000.0, 'salary_day': 1});
    }

    return _client
        .from('user_settings')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', uid)
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
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    
    await _client.from('user_settings').upsert({
      'user_id': uid,
      'salary_day': day,
    });
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
          if (event.isEmpty) return {};
          return event.first;
        });
  }

  Future<void> checkAndDowngradeIfExpired() async {
    try {
      await _client.rpc('check_my_expiration');
    } catch (e) {
      print("Expiration check failed: $e");
      rethrow; // Hatayı yukarı fırlat ki UI yakalayabilsin
    }
  }

  Future<void> updateUserTier(String tierId) async {
    // Kullanıcının kendi tier'ını güncellemesi (PaymentService için)
    // Güvenlik notu: Bu işlem normalde sunucu tarafında (webhook ile) yapılmalıdır.
    // Şimdilik client-side yapıyoruz.
    
    // Standart paket ise süresiz (null), diğerleri için 30 gün
    final DateTime? expiresAt = (tierId == 'standart') 
        ? null 
        : DateTime.now().add(const Duration(days: 30));

    await _client.from('user_roles').update({
      'tier_id': tierId,
      'update_date': DateTime.now().toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    }).eq('user_id', _userId);
  }

  // --- FİŞ İŞLEMLERİ ---

  Future<void> saveReceipt(Map<String, dynamic> aiData) async {
    try {
      final String userId = _userId;
      final String? familyId = await _getFamilyIdForCurrentUser();

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
                ))
            .toList(),
        isManual: false,
        familyId: familyId,
      );

      await _client.from('receipts').insert(newReceipt.toMap());
    } catch (e) {
      print("Kaydetme Hatası: $e");
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
  }) async {
    try {
      final String userId = _userId;
      final String? familyId = await _getFamilyIdForCurrentUser();

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
      );

      await _client.from('receipts').insert(newReceipt.toMap());
    } catch (e) {
      print("Manuel kayıt hatası: $e");
      rethrow;
    }
  }

  Stream<List<Receipt>> getReceipts() async* {
    final userIds = await _getScopeUserIds();

    // 1. Tek kullanıcı (Standart veya Aile Üyesi olmayan Admin)
    if (userIds.length == 1) {
      yield* _client
          .from('receipts')
          .stream(primaryKey: ['id'])
          .eq('user_id', userIds.first) // CRITICAL: Explicit filter
          .order('date', ascending: false)
          .map((data) => data.map((e) => Receipt.fromMap(e)).toList());
    } 
    // 2. Aile (Birden fazla kullanıcı)
    else {
      // Not: Stream 'in' filtresi eski sürümlerde sorunlu olabilir.
      // Admin kullanıcısı RLS yüzünden TÜM verileri görebileceği için
      // client-side filtreleme yapıyoruz.
      yield* _client
          .from('receipts')
          .stream(primaryKey: ['id'])
          .order('date', ascending: false)
          .map((data) {
            // Client-side filtering
            final filtered = data.where((e) => userIds.contains(e['user_id']));
            return filtered.map((e) => Receipt.fromMap(e)).toList();
          });
    }
  }

  /// Fişleri, abonelikleri ve kredi taksitlerini birleştirerek canlı yayınlar
  Stream<List<Receipt>> getUnifiedReceiptsStream() async* {
    final userIds = await _getScopeUserIds();
    final now = DateTime.now();

    // Diğer streamleri hazırla
    final receiptsStream = getReceipts();
    final subsStream = getSubscriptions();
    final creditsStream = getCredits();

    // Not: StreamZip veya combineLatest kullanılabilir ama rxdart bağımlılığı yoksa manuel birleştirme
    await for (final receipts in receiptsStream) {
       final List<Receipt> all = List.from(receipts);
       
       // Abonelikleri ekle (Statik listenin o anki hali)
       final subs = await getSubscriptionsOnce();
       for (final sub in subs) {
          all.add(Receipt(
            id: 'sub_${sub.id}',
            userId: userIds.first,
            merchantName: sub.name,
            date: DateTime(receipts.isNotEmpty ? receipts.first.date.year : now.year, receipts.isNotEmpty ? receipts.first.date.month : now.month, sub.renewalDay),
            totalAmount: sub.price,
            taxAmount: 0,
            category: 'Sabit Gider',
            items: [],
            isManual: true,
          ));
       }

       // Kredileri ekle
       final credits = await _client.from('user_credits').select().filter('user_id', 'in', userIds);
       for (final cMap in credits) {
         final credit = Credit.fromMap(cMap);
         final targetMonth = receipts.isNotEmpty ? receipts.first.date.month : now.month;
         final targetYear = receipts.isNotEmpty ? receipts.first.date.year : now.year;
         
         final monthsPassed = (targetYear - credit.createdAt.year) * 12 + targetMonth - credit.createdAt.month;
         
         if (credit.totalInstallments == 999 || (monthsPassed >= 0 && monthsPassed < credit.totalInstallments)) {
            all.add(Receipt(
              id: 'credit_${credit.id}',
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

       all.sort((a, b) => b.date.compareTo(a.date));
       yield all;
    }
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
    final userIds = await _getScopeUserIds();
    
    // Sadece tarihleri çekiyoruz
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
    final userIds = await _getScopeUserIds();
    
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    
    final response = await _client
        .from('receipts')
        .select()
        .filter('user_id', 'in', userIds)
        .gte('date', startOfMonth.toIso8601String())
        .lt('date', endOfMonth.toIso8601String())
        .order('date', ascending: false);

    return (response as List).map((e) => Receipt.fromMap(e)).toList();
  }

  /// Belirli bir ay için tüm harcamaları (fişler, krediler, abonelikler) birleştirir
  Future<List<Receipt>> getMonthAnalysisData(DateTime month) async {
    final userIds = await _getScopeUserIds();
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    
    // 1. Fişleri çek
    final receiptsResponse = await _client
        .from('receipts')
        .select()
        .filter('user_id', 'in', userIds)
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
    final ownerId = await _getScopeOwnerId();
    await _client.from('user_settings').upsert({
      'user_id': ownerId,
      'monthly_limit': newLimit,
    });
  }

  // --- KATEGORİ İŞLEMLERİ ---

  Stream<List<Category>> getCategories() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value(Category.defaultCategories);

    return _client
        .from('user_categories')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', uid)
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
    final ownerId = await _getScopeOwnerId();
    final data = sub.toMap();
    data['user_id'] = ownerId;
    await _client.from('subscriptions').upsert(data);
  }

  Stream<List<Subscription>> getSubscriptions() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return Stream.value([]);
    }

    return _client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)  // CRITICAL: Filter by user_id to prevent data leakage
        .order('renewal_day', ascending: true)
        .map((event) => event.map((e) => Subscription.fromMap(e)).toList());
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
      buffer.writeln("- Toplam Harcama: ${total.toStringAsFixed(2)} TL");
      buffer.writeln("- Kategori Dağılımı:");
      
      categories.forEach((key, value) {
        buffer.writeln("  * $key: ${value.toStringAsFixed(2)} TL");
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

  Future<void> createUserForAdmin(String email, String password) async {
    try {
      final response = await _client.rpc('admin_create_user', params: {
        'new_email': email,
        'new_password': password,
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
  Stream<List<ShoppingItem>> getShoppingList() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value([]);

    return _client
        .from('shopping_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at')
        .map((event) => event.map((e) => ShoppingItem.fromMap(e)).toList());
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

  // --- BİLDİRİMLER ---

  Stream<List<Map<String, dynamic>>> getNotifications() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value([]);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> deleteNotification(String notificationId) async {
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
}
