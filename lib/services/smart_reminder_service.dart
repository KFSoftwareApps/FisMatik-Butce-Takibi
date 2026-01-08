import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart'; // TimeOfDay için
import 'package:intl/intl.dart';
import '../models/notification_preference.dart';
import '../services/supabase_database_service.dart';
import '../services/notification_service.dart';

/// Akıllı Hatırlatıcı Servisi
/// Bağlam farkındalığı olan bildirimler gönderir
class SmartReminderService {
  SmartReminderService._internal();
  static final SmartReminderService _instance = SmartReminderService._internal();
  factory SmartReminderService() => _instance;

  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final NotificationService _notificationService = NotificationService();
  final _supabase = Supabase.instance.client;

  /// Kullanıcının bildirim tercihlerini al
  Future<NotificationPreference?> getPreferences() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // Varsayılan tercihler oluştur
        return await _createDefaultPreferences(user.id);
      }

      return NotificationPreference.fromMap(response);
    } catch (e) {
      print('Notification preferences error: $e');
      return null;
    }
  }

  /// Varsayılan tercihleri oluştur
  Future<NotificationPreference> _createDefaultPreferences(String userId) async {
    final pref = NotificationPreference(
      id: '',
      userId: userId,
      createdAt: DateTime.now(),
    );

    final map = pref.toMap();
    map.remove('id'); // ID'yi Supabase oluştursun

    final response = await _supabase
        .from('notification_preferences')
        .insert(map)
        .select()
        .single();

    return NotificationPreference.fromMap(response);
  }

  /// Tercihleri güncelle
  Future<void> updatePreferences(NotificationPreference pref) async {
    final map = pref.toMap();
    map.remove('id'); // ID güncellenmemeli
    map.remove('user_id'); // User ID güncellenmemeli (zaten where ile kullanıyoruz)
    map.remove('created_at'); // Created At güncellenmemeli

    await _supabase
        .from('notification_preferences')
        .update(map)
        .eq('user_id', pref.userId);
  }

  /// Günlük hatırlatıcı zamanlaması (mevcut NotificationService kullanır)
  Future<void> scheduleDailyReminder(BuildContext context, String time) async {
    // String saati (HH:mm) TimeOfDay'e çevir
    try {
      final parts = time.split(':');
      final timeOfDay = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      
      // NotificationService'e saati gönder
      await _notificationService.scheduleDailyReminder(context, time: timeOfDay);
    } catch (e) {
      print("Saat formatı hatası ($time): $e");
      // Hata durumunda varsayılan (21:00) çalışsın
      await _notificationService.scheduleDailyReminder(context);
    }
  }
}
