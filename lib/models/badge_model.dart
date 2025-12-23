import 'package:flutter/material.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final String backMessage; // Rozet arkasındaki motivasyon mesajı
  final String iconCode; // Material icon code point
  final int colorValue;
  final bool isEarned;
  final DateTime? earnedAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.backMessage,
    required this.iconCode,
    required this.colorValue,
    this.isEarned = false,
    this.earnedAt,
  });

  // Sabit Rozet Listesi
  static List<Badge> get allBadges => [
    Badge(
      id: 'first_receipt',
      name: 'İlk Adım',
      description: 'İlk fişini tarattın!',
      backMessage: '🎉 Harika bir başlangıç! Her büyük yolculuk bir adımla başlar.',
      iconCode: 'e8f8', // camera_alt
      colorValue: 0xFF4CAF50, // Green
    ),
    Badge(
      id: 'receipt_5',
      name: 'Düzenli Kullanıcı',
      description: '5 fiş ekledin.',
      backMessage: '💪 Harikasın! Düzenli takip başarının anahtarı.',
      iconCode: 'e8ef', // receipt_long
      colorValue: 0xFF2196F3, // Blue
    ),
    Badge(
      id: 'receipt_10',
      name: 'Profesyonel',
      description: '10 fiş ekledin.',
      backMessage: '🌟 İnanılmazsın! Artık bir profesyonelsin!',
      iconCode: 'e838', // workspace_premium
      colorValue: 0xFFFF9800, // Orange
    ),
    Badge(
      id: 'receipt_50',
      name: 'Uzman',
      description: '50 fiş ekledin.',
      backMessage: '🏆 Efsanesin! Bu seviyeye çok az kişi ulaşır.',
      iconCode: 'e8f5', // military_tech
      colorValue: 0xFFFFD700, // Gold
    ),
    Badge(
      id: 'saver',
      name: 'Tasarrufçu',
      description: 'Toplam 1000 TL harcama kaydettin.',
      backMessage: '💰 Harika! Harcamalarını takip etmek zenginliğin ilk adımı.',
      iconCode: 'e263', // monetization_on
      colorValue: 0xFFFFC107, // Amber
    ),
    Badge(
      id: 'big_spender',
      name: 'Büyük Harcama',
      description: 'Tek seferde 500 TL üzeri harcama yaptın.',
      backMessage: '💳 Büyük harcamalar büyük sorumluluklar getirir!',
      iconCode: 'e8e1', // shopping_bag
      colorValue: 0xFFE91E63, // Pink
    ),
    Badge(
      id: 'budget_master',
      name: 'Bütçe Ustası',
      description: 'Bir ay boyunca bütçeni aşmadın.',
      backMessage: '🎯 Mükemmel! Disiplin başarının temelidir.',
      iconCode: 'f091', // savings
      colorValue: 0xFF2196F3, // Blue
    ),
    Badge(
      id: 'night_owl',
      name: 'Gece Kuşu',
      description: 'Gece yarısından sonra fiş ekledin.',
      backMessage: '🌙 Gece gece ne yapıyorsun sen? Ama helal olsun!',
      iconCode: 'ef49', // dark_mode
      colorValue: 0xFF673AB7, // Deep Purple
    ),
    Badge(
      id: 'early_bird',
      name: 'Erken Kuş',
      description: 'Sabah 6\'dan önce fiş ekledin.',
      backMessage: '🌅 Erken kalkan yol alır! Sen de yoldasın.',
      iconCode: 'e518', // wb_sunny
      colorValue: 0xFFFF5722, // Deep Orange
    ),
    Badge(
      id: 'weekend_shopper',
      name: 'Hafta Sonu Alışverişçisi',
      description: 'Hafta sonu alışveriş yaptın.',
      backMessage: '🛍️ Hafta sonları alışverişin tadı bir başka!',
      iconCode: 'e8cc', // weekend
      colorValue: 0xFF9C27B0, // Purple
    ),
    Badge(
      id: 'loyal_user',
      name: 'Sadık Üye',
      description: 'Uygulamayı 30 gün boyunca kullandın.',
      backMessage: '❤️ Seninle olmak harika! Teşekkürler!',
      iconCode: 'e87d', // favorite
      colorValue: 0xFFE91E63, // Pink
    ),
    Badge(
      id: 'category_master',
      name: 'Kategori Uzmanı',
      description: '5 farklı kategoride harcama yaptın.',
      backMessage: '📊 Çeşitlilik güzeldir! Harcamalarını iyi dağıtıyorsun.',
      iconCode: 'e574', // category
      colorValue: 0xFF00BCD4, // Cyan
    ),
    Badge(
      id: 'ultimate_master',
      name: 'Nihai Usta (Sürpriz Hediye)',
      description: '100 fiş ekle ve 10.000 TL harcama kaydet.',
      backMessage: '👑 EFSANE! Sen gerçek bir ustasın! 1 ay Pro hediyemiz seninle!',
      iconCode: 'e8e8', // emoji_events (trophy)
      colorValue: 0xFFFFD700, // Gold
    ),
  ];

  Badge copyWith({bool? isEarned, DateTime? earnedAt}) {
    return Badge(
      id: id,
      name: name,
      description: description,
      backMessage: backMessage,
      iconCode: iconCode,
      colorValue: colorValue,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }
}
