import 'package:flutter/material.dart';
import '../screens/upgrade_screen.dart';
import 'package:fismatik/core/app_theme.dart';
import 'package:fismatik/screens/ai_chat_screen.dart';
import 'package:fismatik/services/auth_service.dart';
import 'package:fismatik/models/membership_model.dart';
import 'package:fismatik/screens/subscriptions_screen.dart'; // Upgrade ekranı

class AICoachBubble extends StatefulWidget {
  const AICoachBubble({super.key});

  @override
  State<AICoachBubble> createState() => _AICoachBubbleState();
}

class _AICoachBubbleState extends State<AICoachBubble> {
  final AuthService _authService = AuthService();
  MembershipTier? _currentTier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTier();
  }

  Future<void> _checkTier() async {
    // Bu method artık AuthService içindeki cache mekanizması sayesinde çok daha hızlı çalışacak
    final tier = await _authService.getCurrentTier();
    if (mounted) {
      setState(() {
        _currentTier = tier;
        _isLoading = false;
      });
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("💎 Premium Özellik"),
        content: const Text(
            "AI Finans Koçu sadece Premium ve Aile paketlerinde mevcuttur.\n\n"
            "Harcamalarını analiz etmek ve tasarruf ipuçları almak için paketinizi yükseltin."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Abonelik ekranına yönlendir
              // Not: SubscriptionScreen, uygulama içi satın almaları listeler
               Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Paketleri İncele", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox();

    // Erişim izni var mı?
    final bool canAccess = _currentTier?.canAccessAICoach ?? false;

    return Positioned(
      bottom: 100, // BottomNavigationBar üzerinde durması için
      right: 20,
      child: GestureDetector(
        onTap: () {
          if (canAccess) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIChatScreen()),
            );
          } else {
            _showUpgradeDialog();
          }
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: canAccess 
                ? const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)], // Mor tonları (Premium)
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.grey, Colors.blueGrey], // Gri tonları (Kilitli)
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (canAccess ? const Color(0xFF6C5CE7) : Colors.grey).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.white.withOpacity(canAccess ? 1.0 : 0.5),
                size: 28,
              ),
              if (!canAccess)
                const Positioned(
                  right: 12,
                  bottom: 12,
                  child: Icon(Icons.lock, color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
