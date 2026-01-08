import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sms_service.dart';
import '../core/app_theme.dart';

class SmsOnboardingDialog extends StatelessWidget {
  const SmsOnboardingDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeen = prefs.getBool('sms_onboarding_seen') ?? false;

    if (!hasSeen && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const SmsOnboardingDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sms_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Otomatik SMS Takibi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Banka ve alışveriş sitelerinden gelen SMS\'leri yakalayarak harcamalarınızı otomatik olarak bütçenize ekleyebiliriz.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(Icons.account_balance, 'Banka harcamalarınızı anında algılar'),
            const SizedBox(height: 12),
            _buildFeatureRow(Icons.shopping_bag, 'Trendyol, Amazon ve Hepsiburada siparişlerini yakalar'),
            const SizedBox(height: 12),
            _buildFeatureRow(Icons.security, 'Sadece harcama verilerini yerel olarak işler'),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleAction(context, false),
                    child: const Text('Şimdi Değil', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Aktif Et'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_onboarding_seen', true);
    await prefs.setBool('sms_tracking_enabled', enable);

    if (enable) {
      await SmsService().init();
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
