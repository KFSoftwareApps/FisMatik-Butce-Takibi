import 'package:flutter/material.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../core/app_theme.dart';
import 'home_screen.dart';
import 'analysis_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart'; // <--- Geçmiş ekranı eklendi
import 'calendar_screen.dart';

import 'package:home_widget/home_widget.dart';
import '../services/supabase_database_service.dart';
import '../services/smart_reminder_service.dart'; // [NEW]

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Uygulama her açıldığında üyelik süresini kontrol et
    SupabaseDatabaseService().checkAndDowngradeIfExpired();
    // Bildirimlerin kurulu olduğundan emin ol (Self-Healing)
    _ensureNotificationsScheduled();
    // Widget tıklamalarını dinle
    _handleWidgetLaunch();
  }

  void _handleWidgetLaunch() {
    HomeWidget.setAppGroupId('group.fismatik.widget');
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null && uri.scheme == 'fismatik' && uri.host == 'scan') {
        if (mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ScanScreen()));
        }
      }
    });

    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null && uri.scheme == 'fismatik' && uri.host == 'scan') {
        if (mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ScanScreen()));
        }
      }
    });
  }

  Future<void> _ensureNotificationsScheduled() async {
    // Kullanıcının tercihlerini kontrol et ve alarmı tazele
    final prefs = await SmartReminderService().getPreferences();
    if (prefs != null && prefs.dailyReminderEnabled && mounted) {
      await SmartReminderService().scheduleDailyReminder(context, prefs.dailyReminderTime);
    }
  }

  // Gösterilecek Sayfalar Listesi
  final List<Widget> _pages = [
    const HomeScreen(),
    const AnalysisScreen(),
    const SizedBox(), 
    const CalendarScreen(), // <--- İndeks 3: Artık Takvim
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Seçili sayfayı göster
      body: _pages[_currentIndex],

      // ORTADAKİ SCAN (TARAMA) BUTONU
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Tarama ekranına git (Menüden bağımsız tam ekran açılır)
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ScanScreen()));
        },
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ALT MENÜ (BOTTOM NAVIGATION BAR)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Sol Taraf
              _buildNavItem(Icons.home_rounded, AppLocalizations.of(context)!.summary, 0),
              _buildNavItem(Icons.pie_chart_rounded, AppLocalizations.of(context)!.analysis, 1),

              // Orta Boşluk (FAB Butonu için)
              const SizedBox(width: 40),

              // Sağ Taraf
              _buildNavItem(Icons.calendar_month, AppLocalizations.of(context)!.calendar, 3), // <--- İKONA DİKKAT
              _buildNavItem(Icons.person_rounded, AppLocalizations.of(context)!.profileTitle, 4),
            ],
          ),
        ),
      ),
    );
  }

  // Alt Menü Elemanı Oluşturan Yardımcı Fonksiyon
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.grey.shade400,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }
}
