import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/supabase_database_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  bool _isInitialized = false;
  final Set<String> _processedPurchaseIds = {};

  // Google Play Console'da oluşturacağın ürün kimlikleri (ID)
  // DİKKAT: Bu ID'leri Google Play Console'da AYNEN oluşturmalısın.
  static const String premiumId = 'fismatik_premium_1month';   // Standart (Kod adı: premium)
  static const String limitlessId = 'fismatik_limitless_1month'; // Pro (Kod adı: limitless)
  static const String familyId = 'fismatik_family_1month';     // Aile (Kod adı: limitless_family)

  static const Set<String> _productIds = {premiumId, limitlessId, familyId};

  // Web Payment Links (Shopier links - user will fill these)
  static const Map<String, String> customWebLinks = {
    'premium': 'https://www.shopier.com/kfsoftware/42431387', // Shopier Standart Link
    'limitless': 'https://www.shopier.com/kfsoftware/42431458', // Shopier Premium Link
    'limitless_family': 'https://www.shopier.com/kfsoftware/42431491', // Shopier Family Link
  };

  // WhatsApp Support Number for fallback
  static const String _supportWhatsApp = '905054717288';

  List<ProductDetails> _products = [];
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Satın alma işlemi tamamlandığında arayüzü güncellemek için callback
  Function(String message, bool isSuccess)? onPurchaseCompleted;

  // Servisi Başlat
  void init() {
    if (_isInitialized) {
      print("PaymentService zaten başlatılmış.");
      return;
    }

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
        _isInitialized = false;
      },
      onError: (error) {
        print("PaymentService Stream Hatası: $error");
        onPurchaseCompleted?.call("Hata oluştu: $error", false);
      },
    );
    
    _isInitialized = true;
    _loadProducts();
  }

  // Mağazadaki Ürünleri Yükle
  Future<void> _loadProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      print("Mağaza kullanılamıyor.");
      return;
    }
    
    final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      print("Bulunamayan ürünler: ${response.notFoundIDs}");
    }
    
    _products = response.productDetails;
    print("Yüklenen Ürünler: ${_products.map((e) => e.id).toList()}");
  }

  // Satın Almayı Başlat (UI'dan çağrılacak)
  Future<void> buyProduct(String tierId) async {
    try {
      // Tier ID'ye göre doğru ürün ID'sini bul
      String targetProductId;
      if (tierId == 'premium') {
        targetProductId = premiumId;
      } else if (tierId == 'limitless') {
        targetProductId = limitlessId;
      } else if (tierId == 'limitless_family') {
        targetProductId = familyId;
      } else {
        print("Geçersiz Tier ID: $tierId");
        onPurchaseCompleted?.call("Geçersiz ürün seçimi.", false);
        return;
      }
      
      // Ürün listesi boşsa veya yenilenmesi gerekiyorsa tekrar yüklemeyi dene
      if (_products.isEmpty) {
        print("⚠️ Ürün listesi boş, tekrar yükleniyor...");
        await _loadProducts();
      }

      // Hala boşsa hata dön
      if (_products.isEmpty) {
         print("⚠️ Ürünler yüklenemedi. Liste hala boş.");
         
         // SADECE DEBUG MODDA TEST İZNİ VER
         if (kDebugMode) {
           print("🔧 DEBUG MODE: Test satın alımı yapılıyor...");
           await _databaseService.updateUserTier(tierId);
           onPurchaseCompleted?.call("(TEST) Satın alma başarılı! $tierId", true);
           return;
         }

         // PROD MODDA HATA DÖN
         final storeName = defaultTargetPlatform == TargetPlatform.iOS ? 'App Store' : 'Google Play';
         onPurchaseCompleted?.call("$storeName ürünleri yüklenemedi. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.", false);
         return;
      }

      ProductDetails productDetails;
      try {
        productDetails = _products.firstWhere((product) => product.id == targetProductId);
      } catch (_) {
        print("❌ HEDEF ÜRÜN BULUNAMADI: $targetProductId");
        print("Mevcut Ürünler: ${_products.map((e) => e.id).toList()}");
        
        onPurchaseCompleted?.call("Seçilen ürün mağazada bulunamadı ($targetProductId). Lütfen daha sonra tekrar deneyin.", false);
        return;
      }

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      
      // Satın alma akışını başlat
      print("Starting purchase for: ${productDetails.id}");
      final bool result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!result) {
        // Başlatılamadı
        print("❌ buyNonConsumable returned FALSE");
        onPurchaseCompleted?.call("Satın alma başlatılamadı. Mağaza bağlantısını kontrol edin.", false);
      }
    } catch (e) {
      print("buyProduct Hatası: $e");
      onPurchaseCompleted?.call("Bir hata oluştu: $e", false);
    }
  }

  // Satın Almaları Geri Yükle (Apple Compliance)
  Future<void> restorePurchases() async {
    try {
      final bool available = await _iap.isAvailable();
      if (!available) {
        onPurchaseCompleted?.call("Mağaza şu anda kullanılamıyor.", false);
        return;
      }
      
      await _iap.restorePurchases();
    } catch (e) {
      print("restorePurchases Hatası: $e");
      onPurchaseCompleted?.call("Geri yükleme sırasında hata oluştu: $e", false);
    }
  }

  // Abonelikleri Yönet (Apple App Store Ayarlarına Yönlendir)
  Future<void> manageSubscriptions() async {
    final Uri url = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse("https://apps.apple.com/account/subscriptions")
        : Uri.parse("https://play.google.com/store/account/subscriptions");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Satın Alma Dinleyicisi (Google/Apple'dan gelen cevabı işler)
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      try {
        if (purchaseDetails.status == PurchaseStatus.pending) {
          // İşlem bekliyor
          continue;
        }

        if (purchaseDetails.status == PurchaseStatus.error) {
          print("IAP Hatası: ${purchaseDetails.error}");
          onPurchaseCompleted?.call("Ödeme başarısız oldu: ${purchaseDetails.error?.message}", false);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
           print("IAP İptal Edildi");
           onPurchaseCompleted?.call("İşlem iptal edildi.", false);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // Mükerrer işlem kontrolü
          if (_processedPurchaseIds.contains(purchaseDetails.purchaseID)) {
             print("İşlem zaten listede: ${purchaseDetails.purchaseID}. Backend senkronizasyonu deneniyor...");
             
             // Listede olsa bile backend'e gitmeyi dene (Idempotent call)
             // Bu sayede "Success ama Free" durumundaki kullanıcı tekrar basıp düzeltebilir.
             try {
                await _verifyAndGrantAccess(purchaseDetails);
                // verifyAndGrantAccess içinde onPurchaseCompleted çağrıldığı için burada tekrar çağırmaya gerek yok.
             } catch (e) {
                print("Retry verification failed: $e");
                // Sessizce geç veya logla, kullanıcıya zaten önceki başarısı gösterilmiş olabilir.
                // Ama eğer kullanıcı tekrar butona bastıysa, bu hatayı görmeli.
                onPurchaseCompleted?.call("İşlem kaydı mevcut ancak aktivasyon tamamlanamadı: $e", false);
             }
          } else {
            // ✅ ÖDEME BAŞARILI!
            try {
              // Önce veritabanını güncelle
              await _verifyAndGrantAccess(purchaseDetails);
              
              // Veritabanı güncellemesi BAŞARILI olursa listeye ekle
              if (purchaseDetails.purchaseID != null) {
                _processedPurchaseIds.add(purchaseDetails.purchaseID!);
              }
            } catch (e) {
              // Hata olursa listeye ekleme
              print("_verifyAndGrantAccess HATASI: $e");
              onPurchaseCompleted?.call("Aktivasyon sırasında hata oluştu. Lütfen tekrar deneyin: $e", false);
            }
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      } catch (e) {
        print("_listenToPurchaseUpdated içinde hata: $e");
        onPurchaseCompleted?.call("Ödeme alındı ancak aktivasyon hatası: $e. Lütfen destekle iletişime geçin.", false);
      }
    }
  }

  // Yetkiyi Ver (Veritabanını Güncelle)
  Future<void> _verifyAndGrantAccess(PurchaseDetails purchase) async {
    String tierId = 'standart';
    if (purchase.productID == premiumId) tierId = 'premium';
    if (purchase.productID == limitlessId) tierId = 'limitless';
    if (purchase.productID == familyId) tierId = 'limitless_family';

    // 1. Düşük seviye kontrolü (Eski işlem yüksek seviyeyi ezmesin)
    final currentTier = await _databaseService.getCurrentTier();
    final newLevel = _getTierLevel(tierId);
    final currentLevel = _getTierLevel(currentTier.id);

    if (purchase.status == PurchaseStatus.restored) {
      // A. Seviye Kontrolü
      if (newLevel <= currentLevel) {
        print("⚠️ Eski işlem (Restored) yoksayıldı: Mevcut ($currentLevel) >= Yeni ($newLevel)");
        onPurchaseCompleted?.call("Mevcut üyeliğiniz zaten bu seviyede veya daha yüksek.", true);
        return;
      }
      
      // B. Tarih Kontrolü ve Robust Parsing
      if (purchase.transactionDate != null) {
        try {
          int? transactionDateMs;
          
          // 1. Önce milisaniye string olarak dene ("1678234234234")
          transactionDateMs = int.tryParse(purchase.transactionDate!);

          // 2. Eğer başarısızsa, belki saniye cinsindendir veya double'dır? ("1678234234.234")
          if (transactionDateMs == null) {
             final double? transactionDateDouble = double.tryParse(purchase.transactionDate!);
             if (transactionDateDouble != null) {
               // Saniye mi milisaniye mi? (1970'den bu yana saniye 10 basamaklı olur, ms 13)
               if (transactionDateDouble < 100000000000) {
                 transactionDateMs = (transactionDateDouble * 1000).toInt(); // Saniyeyi ms'ye çevir
               } else {
                 transactionDateMs = transactionDateDouble.toInt(); // Zaten ms
               }
             }
          }

          // 3. Yine başarısızsa, ISO8601 string olabilir mi? ("2023-01-01T12:00:00Z")
          if (transactionDateMs == null) {
            try {
               final date = DateTime.parse(purchase.transactionDate!);
               transactionDateMs = date.millisecondsSinceEpoch;
            } catch (_) {
              // ISO formatı da değil
            }
          }

          // hala null ise
          if (transactionDateMs == null || transactionDateMs == 0) {
            print("⚠️ Geçersiz işlem tarihi (Restored): ${purchase.transactionDate} - Format anlaşılamadı. İzin veriliyor.");
            // Tarih okunamadı ama status 'restored' veya 'purchased' ise ve buraya kadar geldiyse
            // Kullanıcıyı engellemek yerine log basıp devam etmek daha güvenli (False negative engellemek için)
            // onPurchaseCompleted?.call("İşlem tarihi doğrulanamadı.", false);
            // return; 
            
            // FALLBACK: Tarih doğrulanamadı ama işlem geçerli kabul edilsin.
          } else {
             // Tarih başarılı şekilde parse edildi, şimdi kontrol et
            final transactionDate = DateTime.fromMillisecondsSinceEpoch(transactionDateMs);
            final now = DateTime.now();
            final difference = now.difference(transactionDate).inDays;
            
            // 30 günden eski işlemse (veya 5 gün tolerans ile 35)
            if (difference > 35) {
               print("⚠️ Süresi dolmuş işlem (Restored) yoksayıldı. Tarih: $transactionDate, Fark: $difference gün");
               onPurchaseCompleted?.call("Önceki aboneliğinizin süresi dolmuş görünüyor.", false);
               return;
            }
          }

        } catch (e) {
          print("Tarih kontrolü hatası (Restored): $e. İşlem güvenlik için yoksayıldı.");
          // Tarih hatası yüzünden engelleme yapmayalım, loglayıp geçelim.
        }
      } else {
        // Tarih yoksa restored işlemi, eğer verified ise kabul edelim.
        print("⚠️ İşlem tarihi NULL. İşleme devam ediliyor.");
      }
    }
    
    // Veritabanında rolü güncelle
    await _databaseService.updateUserTier(tierId);

    // Cache temizle ki UI anında güncellensin (Çok Kritik!)
    AuthService().clearCache();

    onPurchaseCompleted?.call("Tebrikler! Üyeliğiniz güncellendi.", true);
  }

  int _getTierLevel(String tierId) {
    switch (tierId) {
      case 'limitless_family': return 3;
      case 'limitless': return 2;
      case 'premium': return 1;
      case 'standart': return 0;
      default: return 0;
    }
  }

  // --- WEB PAYMENT LOGIC ---
  Future<void> openWebPaymentLink(String tierId) async {
    final String? shopierLink = customWebLinks[tierId];
    
    // 1. If Shopier link exists, open it
    if (shopierLink != null && shopierLink.isNotEmpty) {
      final Uri url = Uri.parse(shopierLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // 2. Fallback: WhatsApp support
    String tierName = 'Premium';
    if (tierId == 'limitless') tierName = 'Limitless';
    if (tierId == 'limitless_family') tierName = 'Aile Ekonomisi';

    final String message = "Merhaba, FişMatik üzerinden $tierName paketini web üzerinden satın almak istiyorum. Ödeme konusunda yardımcı olabilir misiniz?";
    final String whatsappUrl = "https://wa.me/$_supportWhatsApp?text=${Uri.encodeFull(message)}";
    
    final Uri url = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      onPurchaseCompleted?.call("Ödeme sayfası açılamadı. Lütfen destek ile iletişime geçin.", false);
    }
  }
  
  void dispose() {
    _subscription.cancel();
  }
}
