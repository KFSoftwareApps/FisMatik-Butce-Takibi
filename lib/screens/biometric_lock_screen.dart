import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/biometric_service.dart';

/// Biometrik Kilit Ekranı
class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isAuthenticating = false;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    final success = await _biometricService.authenticate(
      reason: 'FişMatik\'e giriş yapmak için kimliğinizi doğrulayın',
    );

    if (success) {
      await _biometricService.updateLastActivity();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _failedAttempts++;
        _isAuthenticating = false;
      });

      if (_failedAttempts >= 3) {
        // 3 başarısız denemeden sonra login ekranına yönlendir
        if (mounted) {
          Navigator.of(context).pop(false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo veya ikon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 40),

                // Başlık
                const Text(
                  'FişMatik Kilitli',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 12),

                // Açıklama
                Text(
                  'Devam etmek için kimliğinizi doğrulayın',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 40),

                // Tekrar dene butonu
                if (!_isAuthenticating)
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Kimlik Doğrula'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  const CircularProgressIndicator(),

                const SizedBox(height: 20),

                // Başarısız deneme sayısı
                if (_failedAttempts > 0)
                  Text(
                    'Başarısız deneme: $_failedAttempts/3',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
