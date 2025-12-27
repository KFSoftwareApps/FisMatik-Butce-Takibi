import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemChrome için
import 'package:flutter/foundation.dart'; // kIsWeb için
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_theme.dart';
import 'providers/theme_provider.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_wrapper.dart';
import 'screens/verify_email_screen.dart';
import 'services/supabase_database_service.dart';
import 'services/sms_service.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/family_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-Edge (Uçtan uca) ekranı etkinleştir (Android 15+ uyumluluğu için)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // 1. .env dosyasını yükle
    await dotenv.load(fileName: ".env");

    // 2. Supabase başlat
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    // 3. Bildirim servisi başlat
    await NotificationService().init();

    // 4. Reklam servisi başlat (Sadece mobil platformlarda)
    if (!kIsWeb) {
      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        debugPrint("ADS INIT ERROR: $e");
      }
    }
    
    // 5. Ödeme servisi başlat (Satın alımları ve yenilemeleri dinle)
    if (!kIsWeb) {
      PaymentService().init(); 
    }

    // 6. SMS servisi başlat (Sadece Android ve mobil platformlarda)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await SmsService().init();
    }


    // 5. Dil ayarları için initialize
    final prefs = await SharedPreferences.getInstance();
    final String? savedLanguage = prefs.getString('selected_language');
    
    Locale initialLocale;
    if (savedLanguage != null) {
      initialLocale = Locale(savedLanguage);
    } else {
      // Cihaz dilini kontrol et
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (deviceLocale.languageCode == 'tr') {
        initialLocale = const Locale('tr');
      } else {
        initialLocale = const Locale('en');
      }
    }
    
    languageNotifier.value = initialLocale;

    await initializeDateFormatting('tr_TR', null);
    await initializeDateFormatting('en_US', null);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const FismatikApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint("STARTUP ERROR: $e");
    debugPrint(stack.toString());
    // Hata durumunda basit bir ekran göster ki çökmesin
    runApp(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text("Başlatma hatası oluştu."))),
      ),
    );
  }
}

// Global notifier for language changes (initialized in main)
final ValueNotifier<Locale> languageNotifier = ValueNotifier(const Locale('tr'));

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FismatikApp extends StatelessWidget {
  const FismatikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: languageNotifier,
          builder: (context, locale, child) {
            return MaterialApp(
              title: 'FişMatik',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.lightTheme, // Şimdilik dark theme aynı olsun
              themeMode: themeProvider.themeMode,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('tr'),
                Locale('en'),
              ],
              navigatorKey: navigatorKey,
              home: const AuthWrapper(),
            );
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  
  // State variables
  User? _currentUser;
  bool _isLoading = true; // Initial loading state
  
  // Block status
  bool? _isBlocked;
  bool _isLoadingBlockCheck = false;
  
  // Onboarding status
  bool? _hasCompletedOnboarding;
  bool _isLoadingOnboardingCheck = false;
  
  // Password Recovery Flow
  bool _isPasswordRecoveryMode = false;
  
  // Subscriptions
  StreamSubscription<AuthState>? _authSubscription;
  RealtimeChannel? _blockStatusChannel;
  StreamSubscription<bool>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _blockStatusChannel?.unsubscribe();
    _sessionSubscription?.cancel();
    super.dispose();
  }

  void _initializeAuth() {
    // Current user check
    final session = Supabase.instance.client.auth.currentSession;
    _currentUser = session?.user;
    
    if (_currentUser != null) {
      _handleUserLogin(_currentUser!);
      if (mounted) setState(() => _isLoading = false);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }

    // Listen for auth changes
    _authSubscription = _authService.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      final User? user = session?.user;

      if (!mounted) return;

      // Handle user change
      if (user?.id != _currentUser?.id || event == AuthChangeEvent.passwordRecovery) {
        setState(() {
          _currentUser = user;
          _isLoading = false; 
          if (event == AuthChangeEvent.passwordRecovery) {
            _isPasswordRecoveryMode = true;
            // Şifre sıfırlama moduna geçildiğinde Navigator yığınını temizle
            // Bu sayede "Şifremi Unuttum" sayfasında takılı kalma sorunu çözülür.
            navigatorKey.currentState?.popUntil((route) => route.isFirst);
          } else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
            _isPasswordRecoveryMode = false;
          }
        });

        if (user != null) {
          _handleUserLogin(user);
        } else {
          _handleUserLogout();
        }
      }
    });
  }

  void _handleUserLogin(User user) {
    print('✅ User logged in: ${user.id}');
    // 1. Setup Block Listener
    _setupBlockStatusListener(user.id);
    
    // 2. Check Initial Block Status
    _checkBlockStatus();

    // 3. Check Onboarding
    _checkOnboardingStatus(user.id);

    // 4. Setup Session Listener
    _setupSessionListener();

    // 6. Check for Family Invitations [NEW]
    FamilyService().attachCurrentUserToFamilyIfInvited();
  }

  void _handleUserLogout() {
    print('🚪 User logged out');
    // Cleanup listeners
    _blockStatusChannel?.unsubscribe();
    _blockStatusChannel = null;
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
    
    // Reset state
    setState(() {
      _isBlocked = null;
      _hasCompletedOnboarding = null;
    });
  }

  void _setupBlockStatusListener(String userId) {
    // Unsubscribe existing if any
    _blockStatusChannel?.unsubscribe();

    print('🔍 Setting up block listener for user: $userId');
    
    // Listen to changed in user_roles table for this specific user
    _blockStatusChannel = Supabase.instance.client
        .channel('user_block_status_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_roles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            print('🔔 Realtime callback triggered!');
            final newData = payload.newRecord;
            
            if (newData['user_id'] != userId) return;

            final isBlocked = newData['is_blocked'] == true;
            print('🚫 Is blocked report: $isBlocked');
            
            if (mounted) {
              setState(() {
                _isBlocked = isBlocked;
              });
            }
          },
        )
        .subscribe((status, error) {
          if (status == 'SUBSCRIBED' || status.toString().contains('SUBSCRIBED')) {
             print('📡 Block status listener subscribed.');
          }
        });
  }

  void _setupSessionListener() {
    _sessionSubscription?.cancel();
    _sessionSubscription = _authService.listenToSessionValidity().listen((isValid) {
      if (!isValid && mounted) {
        _handleInvalidSession();
      }
    });
  }

  Future<void> _handleInvalidSession() async {
    _sessionSubscription?.cancel();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.sessionEndedTitle),
        content: Text(AppLocalizations.of(context)!.sessionEndedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.okButton),
          ),
        ],
      ),
    );

    await _authService.signOut();
  }

  Future<void> _checkBlockStatus() async {
    if (_currentUser == null) return;
    
    // Only set loading if not already blocked/checked to avoid flicker
    if (_isBlocked == null) {
       setState(() => _isLoadingBlockCheck = true);
    }
    
    try {
      // 5 saniye içinde yanıt gelmezse varsayılan olarak engellenmedi kabul et (kilitlenmeyi önle)
      final blocked = await _authService.isBlocked().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Block status check timed out!');
          return false;
        },
      );
      if (mounted) {
        setState(() {
          _isBlocked = blocked;
          _isLoadingBlockCheck = false;
        });
      }
    } catch (e) {
      print('Error checking block status: $e');
      if (mounted) {
        setState(() {
          // Default to false on error to let user in, listener will catch up
          _isBlocked = false; 
          _isLoadingBlockCheck = false;
        });
      }
    }
  }

  Future<void> _checkOnboardingStatus(String userId) async {
    // Only load if needed
    if (_hasCompletedOnboarding != null) return;

    setState(() => _isLoadingOnboardingCheck = true);
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      final key = 'onboarding_completed_${userId}';
      final completed = prefs.getBool(key) ?? false;
      
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = completed;
          _isLoadingOnboardingCheck = false;
        });
      }
    } catch (e) {
      print("Onboarding status error or timeout: $e");
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = true; // Skip on error to avoid hang
          _isLoadingOnboardingCheck = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    // 2. Not Logged In
    if (_currentUser == null) {
      return const LoginScreen();
    }

    // 3. Logged In Check Flow
    
    // A. Email Verification Check
    if (_currentUser!.emailConfirmedAt == null) {
      return const VerifyEmailScreen();
    }

    // B. Account Deletion Pending Check
    final accountStatus = _currentUser!.userMetadata?['account_status'];
    if (accountStatus == 'pending_deletion') {
       return _buildDeletionPendingScreen();
    }

    // C. Blocked Check
    if (_isBlocked == true) {
      return _buildBlockedScreen();
    }

    // D. Onboarding Check
    if (_hasCompletedOnboarding == false) {
      return OnboardingScreen(
        onComplete: () async {
          final prefs = await SharedPreferences.getInstance();
          final key = 'onboarding_completed_${_currentUser!.id}';
          await prefs.setBool(key, true);
          if (mounted) {
            setState(() {
              _hasCompletedOnboarding = true;
            });
          }
        },
      );
    }

    // E. Main App
    if (_isPasswordRecoveryMode) {
      return ResetPasswordScreen(
        onComplete: () {
          if (mounted) {
            setState(() {
              _isPasswordRecoveryMode = false;
            });
          }
        },
      );
    }
    
    return const MainWrapper();
  }

  Widget _buildBlockedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.accountBlockedTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.accountBlockedMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _authService.signOut(),
                child: Text(AppLocalizations.of(context)!.loginLogout),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletionPendingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.accountDeletionPendingTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.accountDeletionPendingMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await _authService.signOut();
                },
                child: Text(AppLocalizations.of(context)!.loginLogout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
