import 'package:flutter/services.dart';

/// Haptic feedback yardımcı sınıfı
/// Kullanıcı etkileşimlerinde titreşim geri bildirimi sağlar
class HapticHelper {
  /// Hafif titreşim - Başarılı işlemler için
  static void success() {
    HapticFeedback.lightImpact();
  }

  /// Orta şiddette titreşim - Önemli aksiyonlar için
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Güçlü titreşim - Kritik aksiyonlar için (silme, hata)
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Seçim titreşimi - Buton tıklamaları için
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Hata titreşimi - Hata durumları için
  static void error() {
    HapticFeedback.vibrate();
  }
}
