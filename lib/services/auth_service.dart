import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For debugPrint/SnackBar if needed context passed later

import '../models/membership_model.dart';


class AuthService {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  // Caching membership tier to avoid redundant queries
  static MembershipTier? _cachedTier;
  static String? _cachedTierUserId;

  /// Cache clean func
  void clearCache() {
    _cachedTier = null;
    _cachedTierUserId = null;
  }

  /// Şu anki Supabase kullanıcısı
  supa.User? get currentUser => _supabase.auth.currentUser;

  /// Auth state değişimlerini dinlemek istersen
  Stream<supa.AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // Cihaz ID'si için
  String? _deviceId;

  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('device_id');
    
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('device_id', id);
    }
    
    _deviceId = id;
    return id;
  }

  Future<void> _updateDeviceIdInDb(String userId) async {
    try {
      final deviceId = await getDeviceId();
      await _supabase.from('user_roles').update({
        'current_device_id': deviceId,
        'last_login': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e) {
      print("Cihaz ID güncelleme hatası: $e");
    }
  }

  // Session dinleyicisi (Single Device Login)
  Stream<bool> listenToSessionValidity() async* {
    final user = currentUser;
    if (user == null) yield true;

    final deviceId = await getDeviceId();
    
    // Realtime stream
    yield* _supabase
        .from('user_roles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', user!.id)
        .map((event) {
          if (event.isEmpty) return true;
          final remoteDeviceId = event.first['current_device_id'] as String?;
          
          // Eğer remote null ise (yeni özellik), sorun yok
          if (remoteDeviceId == null) return true;
          
          // Eşleşmiyorsa oturum geçersiz
          return remoteDeviceId == deviceId;
        });
  }

  Future<DateTime?> getJoinDate() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final res = await _supabase
          .from('user_roles')
          .select('join_date')
          .eq('user_id', user.id)
          .maybeSingle();

      if (res != null && res['join_date'] != null) {
        return DateTime.parse(res['join_date']);
      }
    } catch (e) {
      print("Join date çekme hatası: $e");
    }
    return null;
  }

  // --- E-POSTA DOĞRULAMA ---

  /// Supabase tarafında emailConfirmedAt varsa doğrulanmış kabul ediyoruz.
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  /// Supabase signup sırasında zaten doğrulama maili gönderiyor.
  /// Gerekirse burada ekstra resend logic ekleyebilirsin.
  Future<void> sendEmailVerification() async {
    // İstersen:
    // final email = currentUser?.email;
    // await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  // --- ÜYELİK VE ROL İŞLEMLERİ (Supabase user_roles tablosu) ---

  Future<MembershipTier> getCurrentTier() async {
    final user = currentUser;
    if (user == null) {
      _cachedTier = null;
      _cachedTierUserId = null;
      return MembershipTier.Tiers['standart']!;
    }

    // Return cached value if user is same
    if (_cachedTier != null && _cachedTierUserId == user.id) {
      return _cachedTier!;
    }

    try {
      final res = await _supabase
          .from('user_roles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle() as Map<String, dynamic>?;

      if (res != null && res['tier_id'] != null) {
        final tierId = res['tier_id'] as String;
        final tier = MembershipTier.Tiers[tierId] ?? MembershipTier.Tiers['standart']!;
        
        // Cache the result
        _cachedTier = tier;
        _cachedTierUserId = user.id;
        
        return tier;
      }

      return MembershipTier.Tiers['standart']!;
    } catch (e) {
      print("Rol çekme hatası (Supabase): $e");
      return MembershipTier.Tiers['standart']!;
    }
  }

  /// Supabase tarafında Firestore gibi realtime stream yok,
  /// şimdilik tek seferlik okuma yapıyoruz.
  Stream<MembershipTier> getCurrentTierStream() async* {
    yield await getCurrentTier();
  }

  Future<String?> getCurrentFamilyId() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final res = await _supabase
          .from('household_members')
          .select('household_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (res != null && res['household_id'] != null) {
        return res['household_id'] as String;
      }
    } catch (e) {
      print("familyId çekme hatası (Supabase): $e");
    }
    return null;
  }

  Future<String?> getCurrentFamilyRole() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final familyId = await getCurrentFamilyId();
      if (familyId == null) return null;

      final res = await _supabase
          .from('households')
          .select('owner_id')
          .eq('id', familyId)
          .maybeSingle();

      if (res != null) {
        return res['owner_id'] == user.id ? 'owner' : 'member';
      }
    } catch (e) {
      print("familyRole çekme hatası (Supabase): $e");
    }
    return null;
  }

  Future<bool> isFamilyPlan() async {
    final tier = await getCurrentTier();
    return tier.id == 'limitless_family';
  }

  Future<void> ensureUserRole(String userId, String email) async {
    try {
      // "ensure_user_role" fonksiyonu:
      // - Eğer kayıt varsa DOKUNMAZ (Mevcut veriyi/premium'u korur).
      // - Eğer kayıt yoksa STANDART olarak açar.
      // Bu sayede "Overwriting" (Üzerine yazma) riski olmaz.
      await _supabase.rpc('ensure_user_role');
      print('✅ Role ensured for user: $userId');
    } catch (e) {
      print('⚠️ Error ensuring role: $e');
      // Kritik değil, zaten trigger var ama loglayalım.
    }
  }

  // --- KULLANIM LİMİT KONTROLLERİ ---

  Future<bool> canAddReceipts(int currentCount) async {
    final tier = await getCurrentTier();
    return currentCount < tier.receiptLimit;
  }

  Future<bool> canAddManualEntries(int currentCount) async {
    final tier = await getCurrentTier();
    return currentCount < tier.manualEntryLimit;
  }

  Future<bool> canAccessAICoach() async {
    final tier = await getCurrentTier();
    return tier.canAccessAICoach;
  }

  // --- GİRİŞ / KAYIT / ÇIKIŞ (SADECE SUPABASE) ---

  // --- BLOK KONTROLÜ ---
  Future<bool> isBlocked() async {
    final user = currentUser;
    if (user == null) {
      print('⚠️ isBlocked check failed: currentUser is null');
      return false;
    }

    try {
      print('🔍 Checking block status for user: ${user.id}');
      final roleData = await _supabase
          .from('user_roles')
          .select('is_blocked')
          .eq('user_id', user.id)
          .maybeSingle();

      print('📦 Block status data: $roleData');
      final isBlocked = roleData?['is_blocked'] == true;
      print('🚫 Result isBlocked: $isBlocked');
      return isBlocked;
    } catch (e) {
      print('❌ Error checking block status: $e');
      return false;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session == null) {
        throw 'Giriş başarısız. Oturum oluşturulamadı.';
      }

      // Blok kontrolü main.dart üzerinden yapılacak.
      
      // Cihaz ID güncelle
      if (res.user != null) {
        await ensureUserRole(res.user!.id, email); // Role kaydını garantiye al
        await _updateDeviceIdInDb(res.user!.id);
      }

    } on supa.AuthException catch (e) {
      throw e.message ?? 'Giriş başarısız. E-posta veya şifre hatalı.';
    } catch (e) {
      throw 'Giriş sırasında bir hata oluştu: $e';
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      print('📝 Starting signup for email: $email');
      
      // ÖNCE: Email zaten kayıtlı mı kontrol et
      final existingUser = await _supabase
          .from('user_roles')
          .select('email')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (existingUser != null) {
        print('❌ Email already registered: $email');
        // Email zaten kayıtlı, açık hata mesajı ver
        throw 'Bu e-posta adresine kayıtlı hesap mevcuttur.\n\nLütfen giriş yapın veya farklı bir e-posta kullanın.';
      }

      print('✅ Email is new, proceeding with signup');
      
      // Email yeni, kayıt işlemine devam et
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb 
            ? Uri.base.origin // Web: Uygulamanın olduğu URL'ye dön
            : 'fismatik://login-callback', // Mobil Deep Link
      );

      print('📧 Supabase signUp response received');
      final user = res.user;
      
      if (user == null) {
        print('⚠️ User is null after signUp');
      } else {
        print('✅ User created: ${user.id}');
        print('🔄 Calling ensureUserRole...');
        // Sadece yeni kullanıcı oluşturulduysa role ata
        await ensureUserRole(user.id, email);
        print('✅ ensureUserRole completed');
      }
      
    } on supa.AuthException catch (e) {
      print('❌ AuthException: ${e.message}');
      // Gerçek hataları fırlat (şifre zayıf, network hatası, vb.)
      throw e.message ?? 'Kayıt olurken bir hata oluştu.';
    } catch (e) {
      print('❌ General exception: $e');
      // Eğer bizim custom hata mesajımızsa olduğu gibi fırlat
      if (e.toString().contains('Bu e-posta adresine kayıtlı hesap mevcuttur')) {
        rethrow;
      }
      throw 'Kayıt sırasında bir hata oluştu: $e';
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // 1. WEB PLATFORMU İÇİN (Supabase Native OAuth Flow)
      // Web'de Supabase'in kendi OAuth akışını kullanmak, Google Cloud Console'da redirect_uri 
      // karmaşasını önler. Çünkü Google sadece Supabase URL'sini tanır, Supabase ise bizim localhost portumuzu.
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(
          supa.OAuthProvider.google,
          // Geliştirme aşamasında portun çakışmaması için sabit bir port öneriyoruz.
          redirectTo: kDebugMode ? 'http://localhost:5000' : Uri.base.origin,
        );
        return; 
      }
      
      // 2. MOBİL PLATFORM İÇİN (Native Flow - idToken)
      const webClientId = '650635272198-sf9ha4oi6bsifebnq0ocdhd7skmsvohs.apps.googleusercontent.com';

      final googleSignIn = gsi.GoogleSignIn(
        serverClientId: webClientId,
        scopes: ['email', 'profile', 'openid'],
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google girişi iptal edildi.';
      }
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Google ID Token alınamadı.';
      }

      final res = await _supabase.auth.signInWithIdToken(
        provider: supa.OAuthProvider.google,
        idToken: idToken,
      );
      
      final user = res.user;
      if (user != null) {
        await ensureUserRole(user.id, user.email ?? '');
        await _updateDeviceIdInDb(user.id);
        
        final blocked = await isBlocked();
        if (blocked) {
          await signOut();
          throw 'Hesabınız engellenmiştir.\n\nLütfen yönetici ile iletişime geçin.';
        }
      }

    } on supa.AuthException catch (e) {
      throw e.message ?? 'Google ile giriş başarısız.';
    } catch (e) {
      throw 'Google girişi sırasında hata: $e';
    }
  }

  Future<void> signInWithApple() async {
    try {
      final rawNonce = _supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = appleIdCredential.identityToken;
      if (idToken == null) {
        throw 'Apple ID Token alınamadı.';
      }

      final res = await _supabase.auth.signInWithIdToken(
        provider: supa.OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final user = res.user;
      if (user != null) {
        await ensureUserRole(user.id, user.email ?? '');
        await _updateDeviceIdInDb(user.id);
        
        final blocked = await isBlocked();
        if (blocked) {
          await signOut();
          throw 'Hesabınız engellenmiştir.\n\nLütfen yönetici ile iletişime geçin.';
        }
      }
    } on supa.AuthException catch (e) {
      throw e.message ?? 'Apple ile giriş başarısız.';
    } catch (e) {
      if (e.toString().contains('canceled')) {
        throw 'Apple girişi iptal edildi.';
      }
      throw 'Apple girişi sırasında hata: $e';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb 
            ? Uri.base.origin 
            : 'fismatik://login-callback',
      );
    } on supa.AuthException catch (e) {
      throw e.message ?? 'Şifre sıfırlama e-postası gönderilemedi.';
    } catch (e) {
      throw 'Bir hata oluştu: $e';
    }
  }

  // Alias for resetPassword to fix build error
  Future<void> sendPasswordResetEmail(String email) async {
    await resetPassword(email);
  }

  Future<void> signOut() async {
    try {
      // Clear caches
      _cachedTier = null;
      _cachedTierUserId = null;
      
      await _supabase.auth.signOut();
      // Session temizliği için kısa bir bekleme
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('Çıkış yaparken hata: $e');
      // Hata olsa bile devam et, kullanıcıyı login ekranına atacağız
    }
  }

  Future<void> refreshSession() async {
    await _supabase.auth.refreshSession();
  }

  Future<Map<String, dynamic>> cancelDeletionRequest() async {
    final res = await _supabase.rpc('cancel_deletion_request');
    return res as Map<String, dynamic>;
  }

  Future<void> updateUserPassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        supa.UserAttributes(password: newPassword),
      );
    } on supa.AuthException catch (e) {
      throw e.message ?? 'Şifre güncellenemedi.';
    } catch (e) {
      throw 'Bir hata oluştu: $e';
    }
  }
}
