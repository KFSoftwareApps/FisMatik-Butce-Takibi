import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../core/app_theme.dart';
import '../screens/ai_chat_screen.dart';
import '../services/auth_service.dart';
import '../models/membership_model.dart';
import '../screens/upgrade_screen.dart';

class AICoachHeaderButton extends StatefulWidget {
  const AICoachHeaderButton({super.key});

  @override
  State<AICoachHeaderButton> createState() => _AICoachHeaderButtonState();
}

class _AICoachHeaderButtonState extends State<AICoachHeaderButton> {
  final AuthService _authService = AuthService();
  MembershipTier? _currentTier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTier();
  }

  Future<void> _checkTier() async {
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

    final bool canAccess = _currentTier?.canAccessAICoach ?? false;

    return IconButton(
      onPressed: () {
        if (canAccess) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIChatScreen()),
          );
        } else {
          _showUpgradeDialog();
        }
      },
      icon: Stack(
        children: [
          Icon(
            Icons.auto_awesome,
            color: canAccess ? Colors.white : Colors.white60,
            size: 24,
          ),
          if (!canAccess)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 8),
              ),
            ),
        ],
      ),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white10,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}
