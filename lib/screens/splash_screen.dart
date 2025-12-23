import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka planı gri yapıyoruz (Giriş ekranıyla uyumlu)
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO (Mavi daire içinde ikon)
            Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1565C0), // Koyu Mavi Zemin
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 88,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // UYGULAMA ADI
            const Text(
              "FişMatik",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              "Harcamalarını Yönet",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 48),

            // YÜKLENİYOR ÇUBUĞU
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
