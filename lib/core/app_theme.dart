import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler (Marka Rengi - O mor/mavi buton rengi)
  static const Color primary = Color(0xFF5C61F4); 
  static const Color secondary = Color(0xFF2D3436);

  // Arka Planlar
  static const Color background = Color(0xFFF1F2F6); // Uygulama genel arka planı (Hafif gri)
  static const Color headerBackground = Color(0xFF1A1E29); // Üstteki koyu alan
  static const Color cardBackground = Colors.white;

  // Metin Renkleri
  static const Color textDark = Color(0xFF2D3436); // Ana yazılar
  static const Color textLight = Color(0xFFA4B0BE); // Alt yazılar (tarih vb.)
  static const Color textWhite = Colors.white;     // Koyu zemin üstü yazılar
  static const Color headerText = Colors.white;    // Header yazı rengi
  static const Color text = Color(0xFF2D3436);     // Genel text rengi

  // Durum Renkleri (Fiş listesindeki ikonlar için)
  static const Color success = Color(0xFF00B894); // Market (Yeşil)
  static const Color warning = Color(0xFFFDCB6E); // Yeme İçme (Sarı)
  static const Color danger = Color(0xFFFF7675);  // Ulaşım/Benzin (Kırmızı)
  static const Color info = Color(0xFF74B9FF);    // Diğer
}

class AppTheme {
  static InputDecoration get inputDecoration {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Poppins',
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        background: AppColors.background,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: defaultTargetPlatform == TargetPlatform.iOS,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
