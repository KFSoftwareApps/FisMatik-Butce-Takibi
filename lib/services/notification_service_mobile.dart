import 'package:universal_io/io.dart';

import 'package:universal_html/html.dart' as html; // [NEW] Web Support
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // TimeOfDay için
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/subscription_model.dart';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 100;

  Future<void> init() async {
    // Android icon: android/app/src/main/res/mipmap-*/ic_launcher
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS / macOS: izinleri sonra ayrıca isteyeceğiz
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(initSettings);

    // zonedSchedule için timezone init
    // WEB veya MOBILE
    // zonedSchedule için timezone init
    // WEB veya MOBILE
    if (!kIsWeb && !Platform.isLinux) { 
      // DİKKAT: Platform kullanımını kIsWeb ile ayırmalıyız.
    }
    
    // Doğru mantık:
    if (kIsWeb) {
      // Web için basit init
      try {
        tz.initializeTimeZones();
        // Web'de varsayılan olarak bir timezone atayalım (örneğin Europe/Istanbul veya UTC)
        // Kullanıcının tarayıcı saatini almak zor olabilir, sabit bir değer güvenli.
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul')); 
      } catch (e) {
        debugPrint('Web Timezone init hatası: $e');
      }
    } else if (!Platform.isLinux) {
      // MOBİL (Android/iOS)
      tz.initializeTimeZones();
      try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        // ... (mevcut kod)
        try {
          final location = tz.getLocation(timeZoneName);
          tz.setLocalLocation(location);
        } catch (e) {
          tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
        }
      } catch (e) {
         tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      }
    }
  }

  /// Bildirim izni iste (Android 13+ ve iOS/macOS)
  Future<bool> requestPermissions() async {
    // WEB: Tarayıcı izni iste
    if (kIsWeb) {
      try {
        final permission = await html.Notification.requestPermission();
        return permission == 'granted';
      } catch (e) {
        debugPrint('Web bildirim izni hatası: $e');
        return false;
      }
    }

    // iOS / macOS
    if (Platform.isIOS || Platform.isMacOS) {
      final iosImpl = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final macImpl = _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();

      await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      await macImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return true;
    }

    // Android 13+ için notification izni
    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted =
          await androidImpl?.requestNotificationsPermission();

      debugPrint('🔔 System notification permission: $granted');
      return granted ?? false;
    }

    return false;
  }

  /// Anında tek seferlik bildirim
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_channel',
      'Anlık Bildirimler',
      channelDescription: 'FişMatik anlık bildirim kanalı',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      0,
      title,
      body,
      details,
    );
  }

  /// Günlük hatırlatıcı:
  /// - Android: inexact tekrar eden (günde 1 kez)
  /// - iOS/macOS: her gün belirtilen saatte exact
  Future<void> scheduleDailyReminder(BuildContext context, {TimeOfDay? time}) async {


    final l10n = AppLocalizations.of(context)!;
    // Varsayılan: 21:00
    final targetTime = time ?? const TimeOfDay(hour: 21, minute: 0);

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Günlük Hatırlatıcı',
      channelDescription: 'Her gün fişlerini hatırlatır',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    // Seçilen saate ayarlı zonedSchedule kullanıyoruz
    final now = tz.TZDateTime.now(tz.local);
    
    // Bugün hedef saat
    var scheduled = tz.TZDateTime(
      tz.local, 
      now.year, 
      now.month, 
      now.day, 
      targetTime.hour, 
      targetTime.minute,
    );

    // Saat geçmişse yarına kaydır
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        _dailyReminderId,
        l10n.notificationDailyReminderTitle,
        l10n.notificationDailyReminderBody,
        scheduled,
        details,
        // Android: Doze modunda bile çalışsın
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, 
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte tekrar et
      );

      debugPrint(
        '⏰ Günlük hatırlatıcı ${targetTime.hour}:${targetTime.minute} için planlandı: $scheduled (Timezone: ${tz.local.name})',
      );
    } catch (e) {
      debugPrint('⚠️ Bildirim planlama hatası: $e');
    }
  }

  /// Sadece günlük hatırlatıcıyı iptal et
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  /// Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
  /// Bütçe kontrolü ve bildirim
  Future<void> checkBudgetAndNotify(BuildContext context, double currentSpending, double limit) async {
    if (limit <= 0) return;

    final l10n = AppLocalizations.of(context)!;
    final ratio = currentSpending / limit;

    if (ratio >= 1.0) {
      await showInstantNotification(
        title: l10n.notificationBudgetExceededTitle,
        body: l10n.notificationBudgetExceededBody,
      );
    } else if (ratio >= 0.8) {
      await showInstantNotification(
        title: l10n.notificationBudgetWarningTitle,
        body: l10n.notificationBudgetWarningBody((ratio * 100).toInt().toString()),
      );
    }
  }

  /// Abonelik ödeme hatırlatıcısı
  Future<void> scheduleSubscriptionReminder(BuildContext context, Subscription sub) async {


    const androidDetails = AndroidNotificationDetails(
      'subscription_channel',
      'Abonelik Hatırlatıcı',
      channelDescription: 'Abonelik ödemelerini hatırlatır',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    
    // Yenileme günü (örn. 15)
    // Eğer bugün ayın 15'i ise ve saat 10:00'ı geçtiyse bir sonraki aya
    // Hatırlatma 1 gün önce yapılsın (renewalDay - 1)
    
    int reminderDay = sub.renewalDay - 1;
    if (reminderDay < 1) reminderDay = 1; // Basit çözüm: Ayın 1'i ise 1'inde hatırlat (veya bir önceki ayın sonu ama karmaşık)

    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, reminderDay, 10, 0);

    if (scheduledDate.isBefore(now)) {
      // Bu ay geçtiyse bir sonraki ay
      scheduledDate = tz.TZDateTime(tz.local, now.year, now.month + 1, reminderDay, 10, 0);
    }

    try {
      final l10n = AppLocalizations.of(context)!;
      // ID olarak unique bir int lazım. String ID'den hashcode üretelim.
      final notificationId = sub.id.hashCode;

      await _plugin.zonedSchedule(
        notificationId,
        l10n.notificationSubscriptionReminderTitle(sub.name),
        l10n.notificationSubscriptionReminderBody(sub.name, sub.price.toStringAsFixed(2)),
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, // Her ay aynı gün ve saatte
      );

      debugPrint('📅 Abonelik hatırlatıcı planlandı: ${sub.name} -> $scheduledDate');
    } catch (e) {
      debugPrint('⚠️ Abonelik bildirim hatası: $e');
    }
  }

  /// Kategori bütçe kontrolü ve bildirim
  Future<void> checkCategoryBudgetAndNotify(BuildContext context, String categoryName, double currentSpending, double limit) async {
    if (limit <= 0) return;

    final l10n = AppLocalizations.of(context)!;
    final ratio = currentSpending / limit;

    if (ratio >= 1.0) {
      await showInstantNotification(
        title: l10n.notificationCategoryExceededTitle(categoryName),
        body: l10n.notificationCategoryExceededBody(categoryName),
      );
    } else if (ratio >= 0.8) {
      await showInstantNotification(
        title: l10n.notificationCategoryWarningTitle(categoryName),
        body: l10n.notificationCategoryWarningBody(categoryName, (ratio * 100).toInt().toString()),
      );
    }
  }
  /// Fiyat değişimlerini kontrol et ve bildirim gönder
  Future<void> checkPriceChangesAndNotify(BuildContext context, List<Map<String, dynamic>> items, Map<String, dynamic> priceHistory) async {
    final l10n = AppLocalizations.of(context)!;
    
    for (final item in items) {
      final name = item['name'].toString();
      final currentPrice = (item['price'] is int) ? (item['price'] as int).toDouble() : (item['price'] as double);
      
      if (priceHistory.containsKey(name.toLowerCase())) {
        final history = priceHistory[name.toLowerCase()];
        final prevPrice = (history['price'] is int) ? (history['price'] as int).toDouble() : (history['price'] as double);
        
        // %20'den fazla İNDİRİM (Fırsat)
        if (currentPrice < prevPrice * 0.8) {
           await showInstantNotification(
             title: "🔥 ${l10n.priceDropAlertTitle} ($name)",
             body: "${l10n.priceDropAlertBody(name, prevPrice.toStringAsFixed(2), currentPrice.toStringAsFixed(2))}",
           );
           // Bir bildirim yeterli, kullanıcıyı boğmayalım
           return; 
        }
        
        // %30'dan fazla ZAM (Uyarı)
        if (currentPrice > prevPrice * 1.3) {
           await showInstantNotification(
             title: "📈 ${l10n.priceRiseAlertTitle} ($name)",
             body: "${l10n.priceRiseAlertBody(name, prevPrice.toStringAsFixed(2), currentPrice.toStringAsFixed(2))}",
           );
           return;
        }
      }
    }
  }
}
