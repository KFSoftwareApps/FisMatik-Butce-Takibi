/// Kullanıcı Seviyesi ve XP Modeli
class UserLevel {
  final String userId;
  final int totalXp;
  final int currentLevel;
  final int dailyStreak;
  final DateTime? lastActivityDate;
  final List<String> badgesEarned;

  UserLevel({
    required this.userId,
    this.totalXp = 0,
    this.currentLevel = 1,
    this.dailyStreak = 0,
    this.lastActivityDate,
    this.badgesEarned = const [],
  });

  /// Seviye için gerekli XP
  static int xpForLevel(int level) {
    const xpTable = {
      1: 0,
      2: 100,
      3: 250,
      4: 500,
      5: 1000,
      6: 2000,
      7: 4000,
      8: 8000,
      9: 15000,
      10: 25000,
    };
    return xpTable[level] ?? 25000;
  }

  /// Seviye adı
  static String levelName(int level) {
    const names = {
      1: 'Yeni Başlayan',
      2: 'Öğrenci',
      3: 'Pratisyen',
      4: 'Uzman',
      5: 'Usta',
      6: 'Profesyonel',
      7: 'Elit',
      8: 'Efsane',
      9: 'Titan',
      10: 'Finans Tanrısı',
    };
    return names[level] ?? 'Bilinmeyen';
  }

  /// Sonraki seviyeye kalan XP
  int get xpToNextLevel {
    if (currentLevel >= 10) return 0;
    return xpForLevel(currentLevel + 1) - totalXp;
  }

  /// Mevcut seviyedeki ilerleme (0.0 - 1.0)
  double get progressInCurrentLevel {
    if (currentLevel >= 10) return 1.0;
    final currentLevelXp = xpForLevel(currentLevel);
    final nextLevelXp = xpForLevel(currentLevel + 1);
    final xpInLevel = totalXp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  }

  factory UserLevel.fromMap(Map<String, dynamic> map) {
    return UserLevel(
      userId: map['user_id'] as String,
      totalXp: map['total_xp'] as int? ?? 0,
      currentLevel: map['current_level'] as int? ?? 1,
      dailyStreak: map['daily_streak'] as int? ?? 0,
      lastActivityDate: map['last_activity_date'] != null
          ? DateTime.parse(map['last_activity_date'] as String)
          : null,
      badgesEarned: (map['badges_earned'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'total_xp': totalXp,
      'current_level': currentLevel,
      'daily_streak': dailyStreak,
      'last_activity_date': lastActivityDate?.toIso8601String(),
      'badges_earned': badgesEarned,
    };
  }

  UserLevel copyWith({
    String? userId,
    int? totalXp,
    int? currentLevel,
    int? dailyStreak,
    DateTime? lastActivityDate,
    List<String>? badgesEarned,
  }) {
    return UserLevel(
      userId: userId ?? this.userId,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      badgesEarned: badgesEarned ?? this.badgesEarned,
    );
  }
}

/// XP Kazanma Aktiviteleri
enum XpActivity {
  scanReceipt(10, 'Fiş tarama'),
  manualEntry(5, 'Manuel fiş girişi'),
  dailyLogin(2, 'Günlük giriş'),
  setBudget(15, 'Bütçe belirleme'),
  addCategory(5, 'Kategori ekleme'),
  addSubscription(10, 'Abonelik ekleme'),
  useAiCoach(20, 'AI koç kullanma'),
  weeklyGoal(50, 'Haftalık hedef'),
  monthlyGoal(100, 'Aylık hedef'),
  earnBadge(25, 'Rozet kazanma');

  final int xp;
  final String description;

  const XpActivity(this.xp, this.description);
}
