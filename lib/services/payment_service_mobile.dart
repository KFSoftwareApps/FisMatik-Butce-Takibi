import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/supabase_database_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
        if (onPurchaseCompleted != null) {
          onPurchaseCompleted!("Hata oluştu: $error", false);
        }
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
        if (onPurchaseCompleted != null) {
          onPurchaseCompleted!("Geçersiz ürün seçimi.", false);
        }
        return;
      }
      
      // Ürün listesi boşsa
      if (_products.isEmpty) {
         print("⚠️ Ürünler yüklenemedi. Liste boş.");
         
         // SADECE DEBUG MODDA TEST İZNİ VER
         if (kDebugMode) {
           print("🔧 DEBUG MODE: Test satın alımı yapılıyor...");
           await _databaseService.updateUserTier(tierId);
           if (onPurchaseCompleted != null) {
             onPurchaseCompleted!("(TEST) Satın alma başarılı! $tierId", true);
           }
           return;
         }

         // PROD MODDA HATA DÖN
         final storeName = defaultTargetPlatform == TargetPlatform.iOS ? 'App Store' : 'Google Play';
         if (onPurchaseCompleted != null) {
           onPurchaseCompleted!("$storeName bağlantısı kurulamadı veya ürünler bulunamadı. Lütfen internetinizi kontrol edin.", false);
         }
         return;
      }

      ProductDetails productDetails;
      try {
        productDetails = _products.firstWhere((product) => product.id == targetProductId);
      } catch (_) {
        productDetails = _products.first;
      }

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      
      // Satın alma akışını başlat
      final bool result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!result) {
        // Başlatılamadı
        if (onPurchaseCompleted != null) {
          onPurchaseCompleted!("Satın alma başlatılamadı.", false);
        }
      }
    } catch (e) {
      print("buyProduct Hatası: $e");
      if (onPurchaseCompleted != null) {
        onPurchaseCompleted!("Bir hata oluştu: $e", false);
      }
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
          if (onPurchaseCompleted != null) {
            onPurchaseCompleted!("Ödeme başarısız oldu: ${purchaseDetails.error?.message}", false);
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // Mükerrer işlem kontrolü
          if (_processedPurchaseIds.contains(purchaseDetails.purchaseID)) {
            print("Bu işlem zaten işlendi: ${purchaseDetails.purchaseID}");
          } else {
            if (purchaseDetails.purchaseID != null) {
              _processedPurchaseIds.add(purchaseDetails.purchaseID!);
            }
            // ✅ ÖDEME BAŞARILI!
            await _verifyAndGrantAccess(purchaseDetails);
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      } catch (e) {
        print("_listenToPurchaseUpdated içinde hata: $e");
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
        return;
      }
      
      // B. Tarih Kontrolü (Süresi dolmuş işlemi yoksay)
      if (purchase.transactionDate != null) {
        try {
          // transactionDate formatı platforma göre (iOS/Android) milisaniye veya string olabilir.
          // in_app_purchase paketi genellikle milisaniye stringi döner.
          final int? transactionDateMs = int.tryParse(purchase.transactionDate!);
          
          if (transactionDateMs == null || transactionDateMs == 0) {
            print("⚠️ Geçersiz işlem tarihi (Restored): ${purchase.transactionDate}. İşlem yoksayıldı.");
            return;
          }

          final transactionDate = DateTime.fromMillisecondsSinceEpoch(transactionDateMs);
          final now = DateTime.now();
          final difference = now.difference(transactionDate).inDays;
          
          // 30 günden eski işlemse (veya 5 gün tolerans ile 35)
          if (difference > 35) {
             print("⚠️ Süresi dolmuş işlem (Restored) yoksayıldı. Tarih: $transactionDate, Fark: $difference gün");
             return;
          }
        } catch (e) {
          print("Tarih kontrolü hatası (Restored): $e. İşlem güvenlik için yoksayıldı.");
          return;
        }
      } else {
        // Tarih yoksa restored işlemi asla kabul etme (Güvenlik)
        print("⚠️ İşlem tarihi bulunamadı (Restored). İşlem yoksayıldı.");
        return;
      }
    }
    
    // Veritabanında rolü güncelle
    await _databaseService.updateUserTier(tierId);

    if (onPurchaseCompleted != null) {
      onPurchaseCompleted!("Tebrikler! Üyeliğiniz güncellendi.", true);
    }
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
      if (onPurchaseCompleted != null) {
        onPurchaseCompleted!("Ödeme sayfası açılamadı. Lütfen destek ile iletişime geçin.", false);
      }
    }
  }
  
  void dispose() {
    _subscription.cancel();
  }
}
