import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:shared_preferences/shared_preferences.dart';

// enum BiometricType { face, fingerprint, iris, weak, strong } // local_auth'dan geliyor

/// Biometrik Güvenlik Servisi
/// Parmak izi ve yüz tanıma ile kimlik doğrulama
class BiometricService {
  BiometricService._internal();
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;

  final LocalAuthentication _auth = LocalAuthentication();

  /// Cihazda biometrik desteği var mı?
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      print("Biometrik kontrol hatası: $e");
      return false;
    }
  }

  /// Kullanılabilir biometrik türlerini al
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print("Biometrik türleri alma hatası: $e");
      return [];
    }
  }

  /// Biometrik kimlik doğrulama yap
  Future<bool> authenticate({
    String reason = 'Lütfen kimliğinizi doğrulayın',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          IOSAuthMessages(),
          AndroidAuthMessages(),
        ],
      );
    } on PlatformException catch (e) {
      print("Kimlik doğrulama hatası: $e");
      return false;
    }
  }

  /// Biometrik ayarlarını kaydet
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }

  /// Biometrik ayarlarını al
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  /// Auto-lock süresini ayarla
  Future<void> setAutoLockDuration(String duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auto_lock_duration', duration);
  }

  /// Auto-lock süresini al
  Future<String> getAutoLockDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auto_lock_duration') ?? 'immediate';
  }

  /// Son aktivite zamanını kaydet
  Future<void> updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
  }

  /// Kilitleme gerekli mi kontrol et
  Future<bool> shouldLock() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('last_activity');
    if (lastActivity == null) return false;

    final durationStr = await getAutoLockDuration();
    if (durationStr == 'immediate') return true;

    int minutes = 0;
    if (durationStr == '1min') minutes = 1;
    if (durationStr == '5min') minutes = 5;
    if (durationStr == '15min') minutes = 15;

    final diff = DateTime.now().millisecondsSinceEpoch - lastActivity;
    return diff > (minutes * 60 * 1000);
  }

  /// Biometrik türünü string olarak al
  String getBiometricTypeString(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Yüz Tanıma (Face ID)';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Parmak İzi (Touch ID)';
    } else if (types.contains(BiometricType.iris)) {
      return 'İris Tarama';
    }
    return 'Biometrik Kimlik Doğrulama';
  }
}
