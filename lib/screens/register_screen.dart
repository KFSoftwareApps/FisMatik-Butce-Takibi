import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _agreedToTerms = false;

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fillAllFields),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.passwordsDoNotMatch),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mustAgreeToTerms),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kayıt ol ve doğrulama maili gönder (AuthService içinde yapılıyor)
      await AuthService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        // Başarılı mesajı göster
        // Not: Supabase email zaten kayıtlıysa bile başarılı döner ve doğrulama maili gönderir
        // Bu güvenlik özelliğidir (email enumeration saldırısını önler)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.verificationEmailSentTitle),
            content: Text(AppLocalizations.of(context)!.verificationEmailSentBody),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Dialogu kapat
                  Navigator.pop(context); // Login ekranına dön
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        String displayMessage;

        if (errorMessage.contains("Password") || 
                   errorMessage.contains("password")) {
          displayMessage = AppLocalizations.of(context)!.weakPasswordError;
        } else if (errorMessage.contains("Invalid email") || 
                   errorMessage.contains("email")) {
          displayMessage = AppLocalizations.of(context)!.invalidEmailError;
        } else if (errorMessage.contains("Network") || 
                   errorMessage.contains("network")) {
          displayMessage = AppLocalizations.of(context)!.noInternetError;
        } else {
          displayMessage = "${AppLocalizations.of(context)!.generalError}\n\n$errorMessage";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.registerTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.registerSubtitle,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.loginEmailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.loginPasswordHint,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.passwordConfirmLabel,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Gizlilik Politikası ve Kullanım Şartları Onay Kutusu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() => _agreedToTerms = value ?? false);
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textLight,
                            ),
                            children: [
                              TextSpan(
                                text: AppLocalizations.of(context)!.readAndAcceptPre,
                              ),
                              TextSpan(
                                text: AppLocalizations.of(context)!.privacyPolicy,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PrivacyPolicyScreen(),
                                      ),
                                    );
                                  },
                              ),
                              TextSpan(text: AppLocalizations.of(context)!.readAndAcceptAnd),
                              TextSpan(
                                text: AppLocalizations.of(context)!.termsOfService,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TermsOfServiceScreen(),
                                      ),
                                    );
                                  },
                              ),
                              TextSpan(text: AppLocalizations.of(context)!.readAndAcceptPost),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // SOCIAL LOGINS
                Column(
                  children: [
                    // APPLE SIGN IN
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
                        icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
                        label: Text(
                          AppLocalizations.of(context)!.googleSignUp,
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

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
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
                            AppLocalizations.of(context)!.registerButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
