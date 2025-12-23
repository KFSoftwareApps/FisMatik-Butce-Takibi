import 'package:flutter/material.dart' hide Badge;

/// Başarı/Rozet Tanımı
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementCategory category;
  final int xpReward;
  final AchievementCriteria criteria;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    this.xpReward = 25,
    required this.criteria,
  });
}

/// Rozet Kategorileri
enum AchievementCategory {
  savings('Tasarruf'),
  consistency('Tutarlılık'),
  milestone('Kilometre Taşı'),
  categoryExpert('Kategori Uzmanı'),
  special('Özel');

  final String displayName;
  const AchievementCategory(this.displayName);
}

/// Rozet Kriterleri
class AchievementCriteria {
  final AchievementType type;
  final int? targetValue;
  final String? category;
  final DateTime? specificDate;

  const AchievementCriteria({
    required this.type,
    this.targetValue,
    this.category,
    this.specificDate,
  });
}

enum AchievementType {
  receiptCount,        // Fiş sayısı
  categoryReceiptCount, // Kategori bazlı fiş sayısı
  dailyStreak,         // Günlük seri
  budgetSaving,        // Bütçe tasarrufu
  monthlyGoal,         // Aylık hedef
  scanAtTime,          // Belirli saatte tarama
  scanOnDate,          // Belirli tarihte tarama
  earlyUser,           // Erken kullanıcı
}

/// Tüm Rozetler
class Achievements {
  static const List<Achievement> all = [
    // Kilometre Taşları
    Achievement(
      id: 'first_receipt',
      name: 'İlk Fiş',
      description: 'İlk fişini taradın!',
      icon: Icons.stars,
      color: Colors.amber,
      category: AchievementCategory.milestone,
      xpReward: 10,
      criteria: AchievementCriteria(
        type: AchievementType.receiptCount,
        targetValue: 1,
      ),
    ),
    Achievement(
      id: 'receipt_100',
      name: '100 Fiş',
      description: '100 fiş taradın!',
      icon: Icons.emoji_events,
      color: Colors.orange,
      category: AchievementCategory.milestone,
      xpReward: 50,
      criteria: AchievementCriteria(
        type: AchievementType.receiptCount,
        targetValue: 100,
      ),
    ),
    Achievement(
      id: 'receipt_500',
      name: '500 Fiş',
      description: '500 fiş taradın!',
      icon: Icons.military_tech,
      color: Colors.deepOrange,
      category: AchievementCategory.milestone,
      xpReward: 100,
      criteria: AchievementCriteria(
        type: AchievementType.receiptCount,
        targetValue: 500,
      ),
    ),
    Achievement(
      id: 'receipt_1000',
      name: '1000 Fiş',
      description: '1000 fiş taradın! İnanılmaz!',
      icon: Icons.workspace_premium,
      color: Colors.purple,
      category: AchievementCategory.milestone,
      xpReward: 200,
      criteria: AchievementCriteria(
        type: AchievementType.receiptCount,
        targetValue: 1000,
      ),
    ),

    // Tutarlılık
    Achievement(
      id: 'streak_7',
      name: '7 Günlük Seri',
      description: '7 gün üst üste fiş taradın!',
      icon: Icons.local_fire_department,
      color: Colors.red,
      category: AchievementCategory.consistency,
      xpReward: 50,
      criteria: AchievementCriteria(
        type: AchievementType.dailyStreak,
        targetValue: 7,
      ),
    ),
    Achievement(
      id: 'streak_30',
      name: '30 Günlük Seri',
      description: '30 gün üst üste fiş taradın!',
      icon: Icons.whatshot,
      color: Colors.deepOrange,
      category: AchievementCategory.consistency,
      xpReward: 150,
      criteria: AchievementCriteria(
        type: AchievementType.dailyStreak,
        targetValue: 30,
      ),
    ),
    Achievement(
      id: 'streak_365',
      name: 'Yıllık Şampiyon',
      description: '365 gün aktif kullanım!',
      icon: Icons.celebration,
      color: Color(0xFFFFD700), // Gold color
      category: AchievementCategory.consistency,
      xpReward: 500,
      criteria: AchievementCriteria(
        type: AchievementType.dailyStreak,
        targetValue: 365,
      ),
    ),

    // Tasarruf
    Achievement(
      id: 'saver_master',
      name: 'Tasarruf Ustası',
      description: 'Bütçenin %20\'sini biriktirdin!',
      icon: Icons.savings,
      color: Colors.green,
      category: AchievementCategory.savings,
      xpReward: 100,
      criteria: AchievementCriteria(
        type: AchievementType.budgetSaving,
        targetValue: 20,
      ),
    ),
    Achievement(
      id: 'goal_hunter',
      name: 'Hedef Avcısı',
      description: 'Aylık hedefini 3 ay üst üste tuttun!',
      icon: Icons.track_changes,
      color: Colors.teal,
      category: AchievementCategory.savings,
      xpReward: 150,
      criteria: AchievementCriteria(
        type: AchievementType.monthlyGoal,
        targetValue: 3,
      ),
    ),

    // Kategori Uzmanları
    Achievement(
      id: 'market_master',
      name: 'Market Ustası',
      description: 'Market kategorisinde 50 fiş!',
      icon: Icons.shopping_cart,
      color: Colors.blue,
      category: AchievementCategory.categoryExpert,
      xpReward: 75,
      criteria: AchievementCriteria(
        type: AchievementType.categoryReceiptCount,
        targetValue: 50,
        category: 'Market',
      ),
    ),
    Achievement(
      id: 'fuel_tracker',
      name: 'Yakıt Takipçisi',
      description: 'Akaryakıt kategorisinde 30 fiş!',
      icon: Icons.local_gas_station,
      color: Colors.orange,
      category: AchievementCategory.categoryExpert,
      xpReward: 75,
      criteria: AchievementCriteria(
        type: AchievementType.categoryReceiptCount,
        targetValue: 30,
        category: 'Akaryakıt',
      ),
    ),
    Achievement(
      id: 'gourmet',
      name: 'Gurme',
      description: 'Yeme-İçme kategorisinde 50 fiş!',
      icon: Icons.restaurant,
      color: Colors.pink,
      category: AchievementCategory.categoryExpert,
      xpReward: 75,
      criteria: AchievementCriteria(
        type: AchievementType.categoryReceiptCount,
        targetValue: 50,
        category: 'Yeme-İçme',
      ),
    ),

    // Özel Rozetler
    Achievement(
      id: 'night_owl',
      name: 'Gece Kuşu',
      description: 'Gece 00:00-05:00 arası fiş taradın!',
      icon: Icons.nightlight_round,
      color: Colors.indigo,
      category: AchievementCategory.special,
      xpReward: 50,
      criteria: AchievementCriteria(
        type: AchievementType.scanAtTime,
      ),
    ),
    Achievement(
      id: 'early_bird',
      name: 'Erken Kuş',
      description: 'İlk 1000 kullanıcıdan birisin!',
      icon: Icons.verified,
      color: Colors.cyan,
      category: AchievementCategory.special,
      xpReward: 100,
      criteria: AchievementCriteria(
        type: AchievementType.earlyUser,
      ),
    ),
  ];

  /// ID'ye göre rozet bul
  static Achievement? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Colors extension for gold color
extension ColorsExtension on Colors {
  static const Color gold = Color(0xFFFFD700);
}
