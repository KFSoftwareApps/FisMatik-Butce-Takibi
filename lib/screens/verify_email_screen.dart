import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                "E-posta Doğrulaması Gerekli",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Hesabını kullanabilmek için e-posta adresine gönderilen doğrulama linkine tıklaman gerekiyor. Spam klasörünü kontrol ediniz.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await authService.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Doğrulama e-postası tekrar gönderildi."),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Doğrulama E-postasını Tekrar Gönder",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      await authService.refreshSession();
                      // Eğer doğrulandıysa main.dart stream'i otomatik yakalayacak
                      if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Durum kontrol ediliyor..."),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Hata: $e")),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Doğrulamayı Kontrol Et",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await authService.signOut();
                  // authStateChanges → null → main.dart LoginScreen'e döndürecek
                },
                child: const Text(
                  "Çıkış Yap",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
