class Credit {
  final String id;
  final String userId;
  final String title;
  final double totalAmount;
  final double monthlyAmount;
  final int totalInstallments;
  final int paymentDay;
  final DateTime createdAt;
  final String source;      // örn: 'app', 'demo'

  Credit({
    required this.id,
    required this.userId,
    required this.title,
    required this.totalAmount,
    required this.monthlyAmount,
    required this.totalInstallments,
    required this.paymentDay,
    required this.createdAt,
    this.source = 'app',
  });

  factory Credit.fromMap(Map<String, dynamic> map) {
    return Credit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      monthlyAmount: (map['monthly_amount'] as num).toDouble(),
      totalInstallments: map['total_installments'] as int,
      paymentDay: map['payment_day'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      source: map['source'] ?? 'app',
    );
  }

  /// Kaçıncı taksitte olduğumuzu hesaplar (1'den başlar)
  int get currentInstallment {
    if (totalInstallments == 999) return 1; // Kredi kartı için

    final now = DateTime.now();
    // Yıl/Ay farkını hesapla
    final monthsPassed = (now.year - createdAt.year) * 12 + (now.month - createdAt.month);
    
    // Eğer ödeme günü henüz gelmediyse (bu ayın) taksit sayısını artırma
    // Ancak genellikle o ayın taksiti "aktif" sayılır.
    // Kullanıcı mantığına göre: İlk ay 1. taksit.
    // monthsPassed = 0 -> 1. Taksit.
    int current = monthsPassed + 1;

    if (current < 1) current = 1;
    if (current > totalInstallments) current = totalInstallments;
    
    return current;
  }

  /// Kalan taksit sayısını hesaplar
  int get remainingInstallments {
    if (totalInstallments == 999) return 999;
    
    final remaining = totalInstallments - currentInstallment + 1;
    // Not: currentInstallment o an ödenmekte olanı gösterir.
    // Eğer "Kalan" demek "Ödenmemiş" demekse, ve bu ayınki ödenmediyse dahil edilmeli.
    // Kullanıcı 1/4 (1. taksit) görmek istiyor.
    
    return remaining < 0 ? 0 : remaining;
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'total_amount': totalAmount,
      'monthly_amount': monthlyAmount,
      'total_installments': totalInstallments,
      'remaining_installments': remainingInstallments,
      'payment_day': paymentDay,
      'source': source,
      // 'created_at' is usually handled by DB default or insert
    };
  }
}
