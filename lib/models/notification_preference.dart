import 'package:supabase_flutter/supabase_flutter.dart';

/// Bildirim Tercihleri Modeli
class NotificationPreference {
  final String id;
  final String userId;
  final bool dailyReminderEnabled;
  final String dailyReminderTime; // "20:00" formatında
  final bool weeklySummaryEnabled;
  final bool monthlySummaryEnabled;
  final bool budgetAlertsEnabled;
  final bool subscriptionRemindersEnabled;
  final DateTime createdAt;

  NotificationPreference({
    required this.id,
    required this.userId,
    this.dailyReminderEnabled = true,
    this.dailyReminderTime = '20:00',
    this.weeklySummaryEnabled = true,
    this.monthlySummaryEnabled = true,
    this.budgetAlertsEnabled = true,
    this.subscriptionRemindersEnabled = true,
    required this.createdAt,
  });

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    return NotificationPreference(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      dailyReminderEnabled: map['daily_reminder_enabled'] as bool? ?? true,
      dailyReminderTime: map['daily_reminder_time'] as String? ?? '20:00',
      weeklySummaryEnabled: map['weekly_summary_enabled'] as bool? ?? true,
      monthlySummaryEnabled: map['monthly_summary_enabled'] as bool? ?? true,
      budgetAlertsEnabled: map['budget_alerts_enabled'] as bool? ?? true,
      subscriptionRemindersEnabled: map['subscription_reminders_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'daily_reminder_enabled': dailyReminderEnabled,
      'daily_reminder_time': dailyReminderTime,
      'weekly_summary_enabled': weeklySummaryEnabled,
      'monthly_summary_enabled': monthlySummaryEnabled,
      'budget_alerts_enabled': budgetAlertsEnabled,
      'subscription_reminders_enabled': subscriptionRemindersEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationPreference copyWith({
    String? id,
    String? userId,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
    bool? weeklySummaryEnabled,
    bool? monthlySummaryEnabled,
    bool? budgetAlertsEnabled,
    bool? subscriptionRemindersEnabled,
    DateTime? createdAt,
  }) {
    return NotificationPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      monthlySummaryEnabled: monthlySummaryEnabled ?? this.monthlySummaryEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      subscriptionRemindersEnabled: subscriptionRemindersEnabled ?? this.subscriptionRemindersEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
