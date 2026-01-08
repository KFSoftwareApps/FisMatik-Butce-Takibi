import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import '../core/app_theme.dart';
import '../models/notification_preference.dart';
import '../services/smart_reminder_service.dart';
import '../services/notification_service.dart';
import 'package:flutter/services.dart';

/// Bildirim Ayarları Ekranı
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  final SmartReminderService _reminderService = SmartReminderService();
  final NotificationService _notificationService = NotificationService();
  
  NotificationPreference? _preferences;
  bool _isLoading = true;
  bool _isExactAlarmPermitted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
    _checkExactAlarmPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkExactAlarmPermission();
    }
  }

  Future<void> _checkExactAlarmPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final permitted = await _notificationService.canScheduleExactNotifications();
    if (mounted) {
      setState(() => _isExactAlarmPermitted = permitted);
    }
  }

  Future<void> _openExactAlarmSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _notificationService.openExactAlarmSettings();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    final prefs = await _reminderService.getPreferences();
    setState(() {
      _preferences = prefs;
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(NotificationPreference newPref) async {
    try {
      // Optimistic update: önce UI'ı güncelle
      setState(() => _preferences = newPref);
      
      // Sonra sunucuyu güncelle
      await _reminderService.updatePreferences(newPref);
    } catch (e) {
      // Hata olursa geri al
      if (mounted) {
        // Eski haline döndürmek için _loadPreferences çağırabiliriz veya bir önceki state'i tutabiliriz.
        // Şimdilik basitçe reload yapalım.
        _loadPreferences();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.settingsSaveError}: $e')),
        );
      }
    }
  }

  Future<void> _selectTime() async {
    if (_preferences == null) return;

    final currentTime = _parseTime(_preferences!.dailyReminderTime);
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await _updatePreference(_preferences!.copyWith(dailyReminderTime: timeString));
      
      // Günlük hatırlatıcıyı yeniden zamanla
      if (_preferences!.dailyReminderEnabled) {
        await _reminderService.scheduleDailyReminder(context, timeString);
      }
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }



// ...

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationSettings),
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerText,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
              ? Center(child: Text(AppLocalizations.of(context)!.settingsLoadError))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (!_isExactAlarmPermitted && defaultTargetPlatform == TargetPlatform.android)
                      _buildExactAlarmWarning(),
                    // Günlük Hatırlatıcı
                    _buildSection(
                      title: '🔔 ${AppLocalizations.of(context)!.dailyReminder}',
                      children: [
                        _buildSwitchTile(
                          title: AppLocalizations.of(context)!.dailyReminder,
                          subtitle: AppLocalizations.of(context)!.dailyReminderDesc,
                          value: _preferences!.dailyReminderEnabled,
                          onChanged: (value) async {
                            await _updatePreference(
                              _preferences!.copyWith(dailyReminderEnabled: value),
                            );
                            
                            if (value) {
                              final granted = await _notificationService.requestPermissions();
                              if (granted) {
                                await _reminderService.scheduleDailyReminder(context, _preferences!.dailyReminderTime);
                              }
                            } else {
                              await _notificationService.cancelDailyReminder();
                            }
                          },
                        ),
                        if (_preferences!.dailyReminderEnabled)
                          _buildTimeTile(
                            title: AppLocalizations.of(context)!.reminderTime,
                            time: _preferences!.dailyReminderTime,
                            onTap: _selectTime,
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Özet Bildirimleri
                    _buildSection(
                      title: '📊 ${AppLocalizations.of(context)!.summaryNotifications}',
                      children: [
                        _buildSwitchTile(
                          title: AppLocalizations.of(context)!.weeklySummary,
                          subtitle: AppLocalizations.of(context)!.weeklySummaryDesc,
                          value: _preferences!.weeklySummaryEnabled,
                          onChanged: (value) async {
                            if (value) {
                              final granted = await _notificationService.requestPermissions();
                              if (!granted) return; // İzni vermezse açma
                              await _notificationService.scheduleWeeklySummary(context);
                            } else {
                              await _notificationService.cancelWeeklySummary();
                            }
                            await _updatePreference(
                              _preferences!.copyWith(weeklySummaryEnabled: value),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          title: AppLocalizations.of(context)!.monthlySummary,
                          subtitle: AppLocalizations.of(context)!.monthlySummaryDesc,
                          value: _preferences!.monthlySummaryEnabled,
                          onChanged: (value) async {
                            if (value) {
                              final granted = await _notificationService.requestPermissions();
                              if (!granted) return;
                              await _notificationService.scheduleMonthlySummary(context);
                            } else {
                              await _notificationService.cancelMonthlySummary();
                            }
                            await _updatePreference(
                              _preferences!.copyWith(monthlySummaryEnabled: value),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Bütçe Uyarıları
                    _buildSection(
                      title: '💰 ${AppLocalizations.of(context)!.budgetAlerts}',
                      children: [
                        _buildSwitchTile(
                          title: AppLocalizations.of(context)!.budgetAlerts,
                          subtitle: AppLocalizations.of(context)!.budgetAlertsDesc,
                          value: _preferences!.budgetAlertsEnabled,
                          onChanged: (value) async {
                            if (value) {
                              final granted = await _notificationService.requestPermissions();
                              if (!granted) return;
                            }
                            await _updatePreference(
                              _preferences!.copyWith(budgetAlertsEnabled: value),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Abonelik Hatırlatıcıları
                    _buildSection(
                      title: '🔄 ${AppLocalizations.of(context)!.subscriptionReminders}',
                      children: [
                        _buildSwitchTile(
                          title: AppLocalizations.of(context)!.subscriptionReminders,
                          subtitle: AppLocalizations.of(context)!.subscriptionRemindersDesc,
                          value: _preferences!.subscriptionRemindersEnabled,
                          onChanged: (value) async {
                            if (value) {
                              final granted = await _notificationService.requestPermissions();
                              if (!granted) return;
                            }
                            await _updatePreference(
                              _preferences!.copyWith(subscriptionRemindersEnabled: value),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Test Butonu
                    ElevatedButton.icon(
                      onPressed: () async {
                        final granted = await _notificationService.requestPermissions();
                        if (granted) {
                          await _notificationService.showInstantNotification(
                            title: AppLocalizations.of(context)!.testNotificationTitle,
                            body: AppLocalizations.of(context)!.testNotificationBody,
                          );
                        } else {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(AppLocalizations.of(context)!.notificationPermissionDenied)),
                             );
                           }
                        }
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: Text(AppLocalizations.of(context)!.sendTestNotification),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildExactAlarmWarning() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.notificationExactAlarmWarning,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.notificationExactAlarmDesc,
            style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _openExactAlarmSettings,
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.notificationOpenSettings),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
