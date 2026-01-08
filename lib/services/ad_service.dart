import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Debug/Release kontrolü için
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/web_ad_banner.dart';
import '../l10n/generated/app_localizations.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;

  // --- REKLAM KİMLİKLERİ (BURAYI DOLDUR) ---
  // AdMob panelinden aldığın "Geçiş Reklamı (Interstitial)" kimliğini buraya yapıştır.
  final String _androidRealAdUnitId = 'ca-app-pub-3855771133052397/2830899233'; 
  final String _iosRealAdUnitId = 'ca-app-pub-3855771133052397/XXXXXXXXXX'; // iOS ID'si varsa buraya

  // --- TEST KİMLİKLERİ (Google'ın sabit test ID'leri - Dokunma) ---
  final String _androidTestAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  final String _iosTestAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  // --- WEB ADSENSE ---
  final String webAdSenseClientId = 'ca-pub-3855771133052397';
  final String webAdSenseSlot320x100 = '8945074304';
  final String webAdSenseSlot728x90 = '7909719452';

  // Hangi kimliği kullanacağımıza karar veren akıllı değişken
  String get _adUnitId {
    // Debug modunda test reklamları, Release modunda gerçek reklamlar gösterilir.
    bool forceTestAds = false; 
    // DİKKAT: Emülatörde gerçek reklam görmek için geçici olarak açıldı.
    // Kendi reklamına tıklarsan hesabın banlanabilir!
    bool forceRealAds = false; 

    if ((kDebugMode && !forceRealAds) || forceTestAds) {
      // Geliştirme yaparken veya emülatördeysen TEST reklamı göster (Güvenlik için)
      print("⚠️ MOD: Debug/Forced (Test Reklamları Aktif)");
      if (kIsWeb) return '';
      return Platform.isAndroid ? _androidTestAdUnitId : _iosTestAdUnitId;
    } else {
      // APK aldığında veya markete yüklediğinde GERÇEK reklam göster
      print("🚀 MOD: Release (Gerçek Reklamlar Aktif)");
      if (kIsWeb) return '';
      return Platform.isAndroid ? _androidRealAdUnitId : _iosRealAdUnitId;
    }
  }

  // Reklamı Yükle
  void loadAd() {
    if (kIsWeb) {
      print("⚠️ Web platformunda reklamlar devre dışı.");
      return;
    }
    if (_isAdLoaded || _isLoading) return;

    _isLoading = true;
    print("⏳ Reklam yükleniyor...");

    InterstitialAd.load(
      adUnitId: _adUnitId, // Yukarıdaki akıllı ID'yi kullanır
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print("✅ REKLAM YÜKLENDİ ($ad)");
          _interstitialAd = ad;
          _isAdLoaded = true;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          print('❌ REKLAM YÜKLENEMEDİ: $error');
          _isAdLoaded = false;
          _isLoading = false;
        },
      ),
    );
  }



  // Reklamı Göster
  void showInterstitialAd({BuildContext? context, Function? onAdDismissed}) {
    if (kIsWeb) {
      if (context != null) {
        _showWebInterstitial(context, onAdDismissed);
      } else {
        if (onAdDismissed != null) onAdDismissed();
      }
      return;
    }

    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print("Reklam kapatıldı.");
          ad.dispose();
          loadAd(); // Bir sonraki için yenisini yükle
          if (onAdDismissed != null) onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print("Reklam gösterilemedi: $error");
          ad.dispose();
          loadAd();
          if (onAdDismissed != null) onAdDismissed();
        },
      );
      _interstitialAd!.show();
      _isAdLoaded = false;
    } else {
      print("⚠️ Reklam hazır değil, pas geçiliyor.");
      if (onAdDismissed != null) onAdDismissed();
      loadAd(); // Arka planda yüklemeyi dene
    }
  }

  void _showWebInterstitial(BuildContext context, Function? onAdDismissed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  if (onAdDismissed != null) onAdDismissed();
                  Navigator.pop(context);
                },
              ),
              title: Text(
                AppLocalizations.of(context)!.standardMembershipAdWarning,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WebAdBanner(
                      adSlot: '8945074304', // 320x100 yerine 336x280 kare daha iyi olurdu ama mevcut slotları kullanalım
                      width: 320,
                      height: 100,
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Reklamdan sonra devam edebilirsiniz.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (onAdDismissed != null) onAdDismissed();
                    Navigator.pop(context);
                  },
                  child: const Text("Kapat ve Devam Et"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
