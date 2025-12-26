import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For debugPrint/SnackBar if needed context passed later

import '../models/membership_model.dart';


class AuthService {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

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
      return MembershipTier.Tiers['standart']!;
    }

    try {
      final res = await _supabase
          .from('user_roles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle() as Map<String, dynamic>?;

      if (res != null && res['tier_id'] != null) {
        final tierId = res['tier_id'] as String;
        return MembershipTier.Tiers[tierId] ??
            MembershipTier.Tiers['standart']!;
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
          .from('user_roles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle() as Map<String, dynamic>?;

      final fam = res?['family_id'];
      if (fam is String && fam.isNotEmpty) {
        return fam;
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
      final res = await _supabase
          .from('user_roles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle() as Map<String, dynamic>?;

      final role = res?['family_role'];
      if (role is String && role.isNotEmpty) {
        return role;
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

  Future<void> _assignInitialRole(String userId, String email) async {
    // ARTIK GEREKSİZ:
    // Supabase tarafında 'on_auth_user_created' trigger'ı çalışıyor.
    // Bu trigger otomatik olarak public.users ve public.user_roles tablolarına kayıt atıyor.
    // Client tarafında manuel insert yapmaya çalışmak RLS hatasına sebep oluyor.
    
    print('✅ _assignInitialRole: Trigger should handle user creation for $userId');
    
    // Opsiyonel: Trigger'ın çalışmasını beklemek için kısa bir süre beklenebilir
    // veya UI tarafında stream ile dinlenebilir.
    await Future.delayed(const Duration(milliseconds: 500));
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
            : 'io.supabase.flutterquickstart://login-callback', // Mobil Deep Link
      );

      print('📧 Supabase signUp response received');
      final user = res.user;
      
      if (user == null) {
        print('⚠️ User is null after signUp');
      } else {
        print('✅ User created: ${user.id}');
        print('🔄 Calling _assignInitialRole...');
        // Sadece yeni kullanıcı oluşturulduysa role ata
        await _assignInitialRole(user.id, email);
        print('✅ _assignInitialRole completed');
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
      // WEB PLATFORMU İÇİN (Redirect Flow)
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(
          supa.OAuthProvider.google,
          redirectTo: Uri.base.origin, // Web'de açıkça origin belirt
          // authScreenLaunchMode: supa.LaunchMode.inAppWebView, // Gerekirse
        );
        return; // Redirect olacağı için buradan sonrası çalışmaz
      }
      
      // MOBİL PLATFORM İÇİN (Native Flow)
      // 1. Google Sign In başlat
      const webClientId = '650635272198-sf9ha4oi6bsifebnq0ocdhd7skmsvohs.apps.googleusercontent.com'; // Supabase'den alınacak

      final googleSignIn = GoogleSignIn.instance;
      
      // Google Sign In 7.x+ requires authenticate() instead of signIn()
      final googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        throw 'Google girişi iptal edildi.';
      }
      
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Google ID Token alınamadı.';
      }

      // 2. Supabase ile giriş yap
      final res = await _supabase.auth.signInWithIdToken(
        provider: supa.OAuthProvider.google,
        idToken: idToken,
      );
      
      final user = res.user;
      if (user != null) {
        await _assignInitialRole(user.id, user.email ?? '');
        await _updateDeviceIdInDb(user.id);
        
        // 🛡️ BLOK KONTROLÜ
        final blocked = await isBlocked();
        if (blocked) {
          print('🚫 User is blocked (Google), signing out immediately.');
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

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb 
            ? Uri.base.origin 
            : 'io.supabase.flutterquickstart://login-callback',
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
}
