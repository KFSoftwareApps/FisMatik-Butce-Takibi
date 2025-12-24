import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/subscription_model.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      // Web'de varsayılan bir timezone.
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul')); 
    } catch (e) {
      debugPrint('Web Timezone init hatası: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    } catch (e) {
      debugPrint('Web bildirim izni hatası: $e');
      return false;
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    try {
      if (html.Notification.permission == 'granted') {
        html.Notification(title, body: body);
      }
    } catch (e) {
      debugPrint('Web bildirim gösterme hatası: $e');
    }
  }

  Future<void> scheduleDailyReminder(BuildContext context, {TimeOfDay? time}) async {
    // Web platformunda arka planda zamanlanmış bildirimler Service Worker gerektirir.
    // Mevcut yapıda manuel desteklenmiyor.
  }

  Future<void> cancelDailyReminder() async {}
  Future<void> cancelAllNotifications() async {}
  
  Future<void> checkBudgetAndNotify(BuildContext context, double currentSpending, double limit) async {
    // Web'de anlık bildirim ile bütçe kontrolü yapılabilir.
    if (limit <= 0) return;
    if (currentSpending >= limit) {
      await showInstantNotification(title: "Bütçe Aşıldı", body: "Aylık bütçe limitinizi aştınız.");
    }
  }

  Future<void> scheduleSubscriptionReminder(BuildContext context, Subscription sub) async {}
  Future<void> checkCategoryBudgetAndNotify(BuildContext context, String categoryName, double currentSpending, double limit) async {}
  
  // Web için stub metod (Exact Alarm desteği yok)
  Future<bool> canScheduleExactNotifications() async {
    return false;
  }
}
