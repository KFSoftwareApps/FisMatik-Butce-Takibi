import 'dart:convert';
import 'package:flutter/material.dart' hide Badge;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge_model.dart';
import 'supabase_database_service.dart';
import '../screens/badges_screen.dart';

class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  List<Badge> _badges = Badge.allBadges;

  Future<void> init() async {
    await _loadBadges();
  }

  List<Badge> get badges => _badges;

  Future<void> _loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final earnedList = prefs.getStringList('earned_badges') ?? [];
    
    _badges = Badge.allBadges.map((badge) {
      if (earnedList.contains(badge.id)) {
        return badge.copyWith(isEarned: true, earnedAt: DateTime.now()); // Tarihi kaydetmediysek şu anı ver
      }
      return badge;
    }).toList();
  }

  Future<void> _saveBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final earnedIds = _badges.where((b) => b.isEarned).map((b) => b.id).toList();
    await prefs.setStringList('earned_badges', earnedIds);
  }

  Future<List<Badge>> checkReceiptBadges(int totalReceipts) async {
    List<Badge> unlocked = [];
    
    // İlk Fiş Rozeti
    if (totalReceipts >= 1) {
      final b = await _unlockBadge('first_receipt');
      if (b != null) unlocked.add(b);
    }
    
    // 5 Fiş Rozeti
    if (totalReceipts >= 5) {
      final b = await _unlockBadge('receipt_5');
      if (b != null) unlocked.add(b);
    }
    
    // 10 Fiş Rozeti
    if (totalReceipts >= 10) {
      final b = await _unlockBadge('receipt_10');
      if (b != null) unlocked.add(b);
    }
    
    // 50 Fiş Rozeti
    if (totalReceipts >= 50) {
      final b = await _unlockBadge('receipt_50');
      if (b != null) unlocked.add(b);
    }
    
    return unlocked;
  }

  // Ultimate Badge kontrolü (100 fiş + 10.000 TL)
  Future<List<Badge>> checkUltimateBadge(int totalReceipts, double totalSpending) async {
    List<Badge> unlocked = [];
    
    if (totalReceipts >= 100 && totalSpending >= 10000) {
      final b = await _unlockBadge('ultimate_master');
      if (b != null) {
        unlocked.add(b);
        // Pro hediyesi ver!
        await _grantProReward();
      }
    }
    return unlocked;
  }

  Future<List<Badge>> checkSpendingBadges(double totalAmount) async {
    List<Badge> unlocked = [];

    // Tasarrufçu Rozeti (1000 TL)
    if (totalAmount >= 1000) {
      final b = await _unlockBadge('saver');
      if (b != null) unlocked.add(b);
    }
    
    // Büyük Harcama (500 TL)
    if (totalAmount >= 500) {
      final b = await _unlockBadge('big_spender');
      if (b != null) unlocked.add(b);
    }
    
    return unlocked;
  }

  Future<List<Badge>> checkTimeBadges(DateTime receiptDate) async {
    List<Badge> unlocked = [];
    
    // Gece Kuşu (00:00 - 05:00 arası)
    if (receiptDate.hour >= 0 && receiptDate.hour < 5) {
      final b = await _unlockBadge('night_owl');
      if (b != null) unlocked.add(b);
    }
    
    // Erken Kuş (05:00 - 06:00 arası)
    if (receiptDate.hour >= 5 && receiptDate.hour < 6) {
      final b = await _unlockBadge('early_bird');
      if (b != null) unlocked.add(b);
    }
    
    // Hafta Sonu Alışverişçisi
    if (receiptDate.weekday == DateTime.saturday || receiptDate.weekday == DateTime.sunday) {
      final b = await _unlockBadge('weekend_shopper');
      if (b != null) unlocked.add(b);
    }
    
    return unlocked;
  }

  Future<List<Badge>> checkLoyaltyBadge(DateTime joinDate) async {
    List<Badge> unlocked = [];
    final days = DateTime.now().difference(joinDate).inDays;
    
    if (days >= 30) {
      final b = await _unlockBadge('loyal_user');
      if (b != null) unlocked.add(b);
    }
    return unlocked;
  }

  Future<void> _grantProReward() async {
    try {
      // 1 aylık Pro üyeliği ver
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 30));
      
      await prefs.setString('limitless_reward_expiry', expiryDate.toIso8601String());
      
      // Supabase'e de kaydet (SupabaseDatabaseService kullanarak)
      // Bu kısım SupabaseDatabaseService'e tier güncellemesi eklenirse yapılabilir
      print('🎁 1 Aylık Pro hediye edildi! Bitiş: $expiryDate');
    } catch (e) {
      print('Pro hediye hatası: $e');
    }
  }

  Future<void> checkAndUnlockBadges(BuildContext context) async {
    try {
      final db = SupabaseDatabaseService();
      final totalReceipts = await db.getTotalReceiptCount();
      final totalSpending = await db.getTotalSpending();

      final unlockedReceiptBadges = await checkReceiptBadges(totalReceipts);
      final unlockedSpendingBadges = await checkSpendingBadges(totalSpending);
      final unlockedUltimateBadges = await checkUltimateBadge(totalReceipts, totalSpending);

      final allUnlocked = [
        ...unlockedReceiptBadges,
        ...unlockedSpendingBadges,
        ...unlockedUltimateBadges
      ];

      if (allUnlocked.isNotEmpty && context.mounted) {
        for (final badge in allUnlocked) {
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => BadgeFlipDialog(badge: badge),
          );
        }
      }
    } catch (e) {
      print("Rozet kontrol hatası: $e");
    }
  }

  Future<Badge?> _unlockBadge(String badgeId) async {
    final index = _badges.indexWhere((b) => b.id == badgeId);
    if (index != -1 && !_badges[index].isEarned) {
      _badges[index] = _badges[index].copyWith(isEarned: true, earnedAt: DateTime.now());
      await _saveBadges();
      return _badges[index];
    }
    return null;
  }
}
