class MembershipTier {
  final String id;
  final String name;
  final String price;
  final int receiptLimit;        // Fiş kotası (kamera/galeri ile)
  final int dailyReceiptLimit;   // Günlük fiş tarama limiti
  final int subscriptionLimit;   // Sabit gider kotası
  final int manualEntryLimit;    // Manuel harcama kotası
  final bool canManageCategories;
  final bool canAccessAICoach;
  final int aiMessageLimit;      // AI Mesaj hakkı (Aylık)

  const MembershipTier({
    required this.id,
    required this.name,
    required this.price,
    required this.receiptLimit,
    required this.dailyReceiptLimit,
    required this.subscriptionLimit,
    required this.manualEntryLimit,
    required this.canManageCategories,
    required this.canAccessAICoach,
    required this.aiMessageLimit,
  });

  // Üyelik seviyeleri
  static const Map<String, MembershipTier> Tiers = {
    'standart': MembershipTier(
      id: 'standart',
      name: 'Ücretsiz',
      price: '0 TL',
      receiptLimit: 999999,      // Aylık sınırsız (Reklamlı)
      dailyReceiptLimit: 1,     // Günlük 1 fiş
      subscriptionLimit: 999999,      // Sınırsız sabit gider
      manualEntryLimit: 20,      // 20 manuel giriş
      canManageCategories: false,
      canAccessAICoach: false,
      aiMessageLimit: 0,
    ),
    'premium': MembershipTier(
      id: 'premium',
      name: 'Standart',
      price: '49.99 TL / Ay',
      receiptLimit: 999999,         // Aylık sınırsız
      dailyReceiptLimit: 10,     // Günlük 10 fiş
      subscriptionLimit: 999999,     // Sınırsız sabit gider
      manualEntryLimit: 50,      // 50 manuel giriş
      canManageCategories: true,
      canAccessAICoach: false,
      aiMessageLimit: 0,
    ),
    'limitless': MembershipTier(
      id: 'limitless',
      name: 'Premium',
      price: '79.99 TL / Ay',
      receiptLimit: 999999,        // Aylık sınırsız
      dailyReceiptLimit: 25,      // Günlük 25 fiş
      subscriptionLimit: 999999,   // Sınırsız
      manualEntryLimit: 100,    // 100 manuel giriş
      canManageCategories: true,
      canAccessAICoach: true, 
      aiMessageLimit: 20, // 20 hak
    ),
    'limitless_family': MembershipTier(
      id: 'limitless_family',
      name: 'Aile Ekonomisi',
      price: '99.99 TL / Ay',
      receiptLimit: 999999,        // Aylık sınırsız
      dailyReceiptLimit: 35,      // Günlük 35 fiş (aile için)
      subscriptionLimit: 999999,
      manualEntryLimit: 200,
      canManageCategories: true,
      canAccessAICoach: true, 
      aiMessageLimit: 50, // 50 hak
    ),
  };
}
