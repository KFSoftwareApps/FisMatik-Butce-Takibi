import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_level.dart';
import '../models/achievement.dart';
import '../models/receipt_model.dart';
import '../services/notification_service.dart';

/// Gamification Servisi
/// XP, seviye ve rozet yönetimi
class GamificationService {
  GamificationService._internal();
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;

  final _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  /// Kullanıcının mevcut seviyesini al
  Future<UserLevel?> getUserLevel() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('user_gamification')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // İlk kez, varsayılan oluştur
        return await _createDefaultLevel(user.id);
      }

      return UserLevel.fromMap(response);
    } catch (e) {
      print('Get user level error: $e');
      return null;
    }
  }

  /// Varsayılan seviye oluştur
  Future<UserLevel> _createDefaultLevel(String userId) async {
    final level = UserLevel(userId: userId);
    
    await _supabase.from('user_gamification').insert(level.toMap());
    
    return level;
  }

  /// XP ekle ve seviye kontrolü yap
  Future<void> addXp(XpActivity activity, {int? customXp}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final xpToAdd = customXp ?? activity.xp;
    final currentLevel = await getUserLevel();
    if (currentLevel == null) return;

    final newTotalXp = currentLevel.totalXp + xpToAdd;
    final newLevel = _calculateLevel(newTotalXp);

    // Seviye atladı mı?
    final leveledUp = newLevel > currentLevel.currentLevel;

    // Güncelle
    await _supabase
        .from('user_gamification')
        .update({
          'total_xp': newTotalXp,
          'current_level': newLevel,
        })
        .eq('user_id', user.id);

    // Seviye atlama bildirimi
    if (leveledUp) {
      await _notificationService.showInstantNotification(
        title: '🎉 Seviye Atladın!',
        body: 'Tebrikler! Seviye $newLevel\'e ulaştın: ${UserLevel.levelName(newLevel)}',
      );
    }
  }

  /// XP'den seviye hesapla
  int _calculateLevel(int xp) {
    for (int level = 10; level >= 1; level--) {
      if (xp >= UserLevel.xpForLevel(level)) {
        return level;
      }
    }
    return 1;
  }

  /// Günlük streak güncelle
  Future<void> updateDailyStreak() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final currentLevel = await getUserLevel();
    if (currentLevel == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActivity = currentLevel.lastActivityDate;

    int newStreak = currentLevel.dailyStreak;

    if (lastActivity == null) {
      // İlk aktivite
      newStreak = 1;
    } else {
      final lastDate = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
      final daysDiff = today.difference(lastDate).inDays;

      if (daysDiff == 0) {
        // Bugün zaten aktivite var
        return;
      } else if (daysDiff == 1) {
        // Ardışık gün
        newStreak++;
      } else {
        // Seri kırıldı
        newStreak = 1;
      }
    }

    await _supabase
        .from('user_gamification')
        .update({
          'daily_streak': newStreak,
          'last_activity_date': today.toIso8601String(),
        })
        .eq('user_id', user.id);

    // Streak rozetlerini kontrol et
    await _checkStreakAchievements(newStreak);

    // Günlük giriş XP
    await addXp(XpActivity.dailyLogin);
  }

  /// Fiyat keşfi sayısını artır ve rozet kontrolü yap (Phase 7)
  Future<void> incrementPriceDiscoveries() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt('price_discoveries') ?? 0;
    count++;
    await prefs.setInt('price_discoveries', count);

    if (count >= 3) {
      await unlockAchievement('price_detective');
    }
  }

  /// Sosyal başarımları kontrol et (Phase 7)
  Future<void> checkSocialAchievements(int totalReceipts) async {
    // 50 fiş tarayarak topluluğa katkı sağlama
    if (totalReceipts >= 50) {
      await unlockAchievement('community_pillar');
    }
  }

  /// Rozet kazandır
  Future<void> unlockAchievement(String achievementId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final currentLevel = await getUserLevel();
    if (currentLevel == null) return;

    // Zaten kazanılmış mı?
    if (currentLevel.badgesEarned.contains(achievementId)) return;

    final achievement = Achievements.findById(achievementId);
    if (achievement == null) return;

    // Rozeti ekle
    final newBadges = [...currentLevel.badgesEarned, achievementId];
    
    await _supabase
        .from('user_gamification')
        .update({'badges_earned': newBadges})
        .eq('user_id', user.id);

    // XP ver
    await addXp(XpActivity.earnBadge, customXp: achievement.xpReward);

    // Bildirim gönder
    await _notificationService.showInstantNotification(
      title: '🏆 Yeni Rozet!',
      body: '${achievement.name} rozetini kazandın! +${achievement.xpReward} XP',
    );
  }

  /// Fiş sayısı rozetlerini kontrol et
  Future<void> checkReceiptAchievements(int totalReceipts) async {
    if (totalReceipts >= 1) await unlockAchievement('first_receipt');
    if (totalReceipts >= 100) await unlockAchievement('receipt_100');
    if (totalReceipts >= 500) await unlockAchievement('receipt_500');
    if (totalReceipts >= 1000) await unlockAchievement('receipt_1000');
  }

  /// Kategori rozetlerini kontrol et
  Future<void> checkCategoryAchievements(List<Receipt> receipts) async {
    final categoryCount = <String, int>{};
    
    for (var receipt in receipts) {
      categoryCount[receipt.category] = (categoryCount[receipt.category] ?? 0) + 1;
    }

    if ((categoryCount['Market'] ?? 0) >= 50) {
      await unlockAchievement('market_master');
    }
    if ((categoryCount['Akaryakıt'] ?? 0) >= 30) {
      await unlockAchievement('fuel_tracker');
    }
    if ((categoryCount['Yeme-İçme'] ?? 0) >= 50) {
      await unlockAchievement('gourmet');
    }
  }

  /// Streak rozetlerini kontrol et
  Future<void> _checkStreakAchievements(int streak) async {
    if (streak >= 7) await unlockAchievement('streak_7');
    if (streak >= 30) await unlockAchievement('streak_30');
    if (streak >= 365) await unlockAchievement('streak_365');
  }

  /// Harcama rozetlerini kontrol et
  Future<void> checkSpendingAchievements(double totalAmount) async {
    if (totalAmount >= 500) await unlockAchievement('big_spender');
    if (totalAmount >= 1000) await unlockAchievement('saver');
  }

  /// Zaman bazlı rozetleri kontrol et
  Future<void> checkTimeAchievements(DateTime date) async {
    // Gece Kuşu (00:00 - 05:00 arası)
    if (date.hour >= 0 && date.hour < 5) {
      await unlockAchievement('night_owl');
    }
    
    // Erken Kuş (05:00 - 06:00 arası)
    if (date.hour >= 5 && date.hour < 6) {
      await unlockAchievement('early_bird');
    }
    
    // Hafta Sonu Alışverişçisi
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      await unlockAchievement('weekend_shopper');
    }
  }

  /// Sadakat rozetini kontrol et
  Future<void> checkLoyaltyAchievement(DateTime joinDate) async {
    final days = DateTime.now().difference(joinDate).inDays;
    if (days >= 30) {
      await unlockAchievement('loyal_user');
    }
  }

  /// Ultimate rozetini kontrol et
  Future<void> checkUltimateAchievement(int totalReceipts, double totalSpending) async {
    if (totalReceipts >= 100 && totalSpending >= 10000) {
      await unlockAchievement('ultimate_master');
      // Limitless ödülü burada verilebilir veya unlockAchievement içinde handle edilebilir
    }
  }

  /// Tüm başarımları kontrol et (Wrapper)
  Future<void> checkAllAchievements({
    required int totalReceipts,
    required double totalSpending,
    required DateTime transactionDate,
    required DateTime? joinDate,
  }) async {
    await checkReceiptAchievements(totalReceipts);
    await checkSpendingAchievements(totalSpending);
    await checkTimeAchievements(transactionDate);
    if (joinDate != null) {
      await checkLoyaltyAchievement(joinDate);
    }
    await checkSocialAchievements(totalReceipts);
    await checkUltimateAchievement(totalReceipts, totalSpending);
  }
}
