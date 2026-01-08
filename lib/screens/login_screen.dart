import 'dart:io';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Giriş yapma işlemi
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fillAllFields),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Önceki session kalıntılarını temizle (Donma sorununa karşı)
      await AuthService().signOut();

      // Sadece giriş yap. Email doğrulama kontrolü main.dart'ta.
      await AuthService().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // authStateChanges stream'i kullanıcının doğrulanıp doğrulanmadığına göre
      // zaten Login / VerifyEmail / MainWrapper arasında yönlendirecek.
    } catch (e) {
      if (mounted) {
        // Hata mesajını kullanıcı dostu hale getir
        String errorMessage = e.toString();
        String displayMessage = "";
        Color backgroundColor = Colors.red;

        // Localize authentication errors
        if (errorMessage.contains("Email not confirmed")) {
          displayMessage = AppLocalizations.of(context)!.unconfirmedEmailError;
          backgroundColor = Colors.orange;
        } else if (errorMessage.contains("Invalid login credentials") || 
                   errorMessage.contains("şifre hatalı")) {
          displayMessage = AppLocalizations.of(context)!.invalidCredentialsError;
        } else if (errorMessage.contains("engellenmiştir")) {
          displayMessage = AppLocalizations.of(context)!.accountBlockedError;
        } else if (errorMessage.contains("Network") || errorMessage.contains("network")) {
          displayMessage = AppLocalizations.of(context)!.noInternetError;
        } else {
          // General error message
          displayMessage = "${AppLocalizations.of(context)!.generalError}\n\n$errorMessage";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Hafif gri arka plan
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        // LOGO ALANI
                        Center(
                          child: Hero(
                            tag: 'app_logo',
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/login_hero.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context)!.loginTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.loginSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // SOCIAL LOGINS
                        Column(
                          children: [
                            // APPLE SIGN IN (Only if platform is iOS/macOS or if you want it everywhere)
                            if (Platform.isIOS || Platform.isMacOS)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading 
                                    ? null 
                                    : () async {
                                        setState(() => _isLoading = true);
                                        try {
                                          await AuthService().signInWithApple();
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                            );
                                          }
                                        } finally {
                                          if (mounted) setState(() => _isLoading = false);
                                        }
                                      },
                                  icon: const Icon(Icons.apple, size: 28, color: Colors.white),
                                  label: Text(
                                    AppLocalizations.of(context)!.appleSignIn,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            
                            if (Platform.isIOS || Platform.isMacOS) const SizedBox(height: 12),

                            // GOOGLE SIGN IN BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading 
                                  ? null 
                                  : () async {
                                      setState(() => _isLoading = true);
                                      try {
                                        await AuthService().signInWithGoogle();
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                          );
                                        }
                                      } finally {
                                        if (mounted) setState(() => _isLoading = false);
                                      }
                                    },
                                icon: Image.asset('assets/images/google_logo.png', width: 24, height: 24, errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, size: 32, color: Colors.red)),
                                label: Text(
                                  AppLocalizations.of(context)!.googleSignIn,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // OR DIVIDER
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "veya e-posta ile",
                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // EMAIL
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: AppTheme.inputDecoration.copyWith(
                            labelText: AppLocalizations.of(context)!.loginEmailHint,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PASSWORD
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: AppTheme.inputDecoration.copyWith(
                            labelText: AppLocalizations.of(context)!.loginPasswordHint,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                        ),
                        
                        // FORGOT PASSWORD
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(AppLocalizations.of(context)!.forgotPassword),
                          ),
                        ), 

                        const SizedBox(height: 12),

                        // LOGIN BUTTON
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    AppLocalizations.of(context)!.loginButton,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const SizedBox(height: 24),

                        // REGISTER LINK
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.dontHaveAccount),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                AppLocalizations.of(context)!.registerButton,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
