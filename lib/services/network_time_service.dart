import 'package:ntp/ntp.dart';
import 'package:flutter/foundation.dart';

class NetworkTimeService {
  static int? _offset;
  static DateTime? _lastSyncTime;
  static const Duration _syncInterval = Duration(hours: 1);

  /// NTP sunucusundan zaman farkını (offset) alır ve önbelleğe kaydeder.
  /// Uygulama açılışında bir kez çağrılması önerilir.
  static Future<void> initialize() async {
    try {
      _offset = await NTP.getNtpOffset(localTime: DateTime.now());
      _lastSyncTime = DateTime.now();
      debugPrint('✅ NetworkTimeService: NTP offset synced: $_offset ms');
    } catch (e) {
      debugPrint('⚠️ NetworkTimeService: NTP sync failed: $e');
      // Hata durumunda offset null kalır, cihaz saati kullanılır.
    }
  }

  /// Güvenli zamanı döndürür.
  /// Eğer NTP senkronizasyonu yapılmışsa, cihaz saatine offset eklenerek gerçek zaman bulunur.
  /// Senkronizasyon yoksa veya başarısızsa cihaz saati (DateTime.now()) döner.
  static Future<DateTime> get now async {
    // Eğer hiç senkronizasyon yapılmamışsa veya süre geçmişse tekrar dene
    if (_offset == null || 
        (_lastSyncTime != null && DateTime.now().difference(_lastSyncTime!) > _syncInterval)) {
      await initialize();
    }

    if (_offset != null) {
      return DateTime.now().add(Duration(milliseconds: _offset!));
    }
    
    // Fallback: Cihaz saati
    return DateTime.now();
  }
}
