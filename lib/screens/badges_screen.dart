import 'package:flutter/material.dart' hide Badge;
import '../core/app_theme.dart';
import '../models/badge_model.dart';
import '../services/badge_service.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../utils/l10n_helper.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final BadgeService _badgeService = BadgeService();

  // Helper method to create IconData from hex string
  IconData _getIconData(String iconCode) {
    switch (iconCode) {
      case 'e8f8': return Icons.camera_alt;
      case 'e8ef': return Icons.receipt_long;
      case 'e838': return Icons.workspace_premium;
      case 'e8f5': return Icons.military_tech;
      case 'e263': return Icons.monetization_on;
      case 'e8e1': return Icons.shopping_bag;
      case 'f091': return Icons.savings;
      case 'ef49': return Icons.dark_mode;
      case 'e518': return Icons.wb_sunny;
      case 'e8cc': return Icons.weekend;
      case 'e87d': return Icons.favorite;
      case 'e574': return Icons.category;
      case 'e8e8': return Icons.emoji_events;
      default: return Icons.help_outline;
    }
  }

  @override
  void initState() {
    super.initState();
    _badgeService.init().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final badges = _badgeService.badges;
    final earnedCount = badges.where((b) => b.isEarned).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.badgesTitle, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Column(
        children: [
          // ÖZET KART
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.earnedBadges,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  "$earnedCount / ${badges.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: badges.isEmpty ? 0 : earnedCount / badges.length,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          // ROZET LİSTESİ (GRID)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return _buildBadgeCard(badge);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Badge badge) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final isFlipped = value >= 0.5;
        final angle = value * 3.14159; // π radians = 180 degrees

        return GestureDetector(
          onTap: () {
            // Flip animasyonu tetikle
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (ctx) => BadgeFlipDialog(badge: badge),
            );
          },
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                border: badge.isEarned ? Border.all(color: Color(badge.colorValue).withOpacity(0.5), width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: badge.isEarned ? Color(badge.colorValue).withOpacity(0.1) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconData(badge.iconCode),
                      color: badge.isEarned ? Color(badge.colorValue) : Colors.grey,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    L10nHelper.getBadgeName(context, badge.id),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: badge.isEarned ? AppColors.textDark : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      L10nHelper.getBadgeDescription(context, badge.id),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge.isEarned)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Icon(Icons.check_circle, color: Color(badge.colorValue), size: 16),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Flip Dialog Widget
class BadgeFlipDialog extends StatefulWidget {
  final Badge badge;

  const BadgeFlipDialog({required this.badge});

  @override
  State<BadgeFlipDialog> createState() => _BadgeFlipDialogState();
}

class _BadgeFlipDialogState extends State<BadgeFlipDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  // Helper method to create IconData from hex string
  IconData _getIconData(String iconCode) {
    switch (iconCode) {
      case 'e8f8': return Icons.camera_alt;
      case 'e8ef': return Icons.receipt_long;
      case 'e838': return Icons.workspace_premium;
      case 'e8f5': return Icons.military_tech;
      case 'e263': return Icons.monetization_on;
      case 'e8e1': return Icons.shopping_bag;
      case 'f091': return Icons.savings;
      case 'ef49': return Icons.dark_mode;
      case 'e518': return Icons.wb_sunny;
      case 'e8cc': return Icons.weekend;
      case 'e87d': return Icons.favorite;
      case 'e574': return Icons.category;
      case 'e8e8': return Icons.emoji_events;
      default: return Icons.help_outline;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // Otomatik flip
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
        setState(() => _showFront = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159;
          final isFlipped = _animation.value >= 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(widget.badge.colorValue), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Color(widget.badge.colorValue).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(isFlipped ? 3.14159 : 0),
                child: isFlipped ? _buildBack() : _buildFront(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(widget.badge.colorValue).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconData(widget.badge.iconCode),
            color: Color(widget.badge.colorValue),
            size: 60,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          L10nHelper.getBadgeName(context, widget.badge.id),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(widget.badge.colorValue),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          L10nHelper.getBadgeDescription(context, widget.badge.id),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBack() {
    // Eğer rozet kazanılmamışsa kilitli göster
    if (!widget.badge.isEarned) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock,
            color: Colors.grey,
            size: 60,
          ),
          const SizedBox(height: 16),
          Icon(
            Icons.link,
            color: Colors.grey.shade400,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            "🔒 ${AppLocalizations.of(context)!.locked}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${AppLocalizations.of(context)!.earnThisBadge}:\n${L10nHelper.getBadgeDescription(context, widget.badge.id)}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      );
    }

    // Kazanılmış rozet için motivasyon mesajı
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.auto_awesome,
          color: Color(widget.badge.colorValue),
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          L10nHelper.getBadgeMessage(context, widget.badge.id, fallback: widget.badge.backMessage),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(widget.badge.colorValue),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(widget.badge.colorValue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Color(widget.badge.colorValue), size: 20),
              const SizedBox(width: 8),
              Text(
                widget.badge.id == 'ultimate_master' ? AppLocalizations.of(context)!.oneMonthProGift : AppLocalizations.of(context)!.earned,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.badge.id == 'ultimate_master' ? Color(widget.badge.colorValue) : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
