class Credit {
  final String id;
  final String userId;
  final String title;
  final double totalAmount;
  final double monthlyAmount;
  final int totalInstallments;
  final int remainingInstallments;
  final int paymentDay;
  final DateTime createdAt;

  Credit({
    required this.id,
    required this.userId,
    required this.title,
    required this.totalAmount,
    required this.monthlyAmount,
    required this.totalInstallments,
    required this.remainingInstallments,
    required this.paymentDay,
    required this.createdAt,
  });

  factory Credit.fromMap(Map<String, dynamic> map) {
    return Credit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      monthlyAmount: (map['monthly_amount'] as num).toDouble(),
      totalInstallments: map['total_installments'] as int,
      remainingInstallments: map['remaining_installments'] as int,
      paymentDay: map['payment_day'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
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
      // 'created_at' is usually handled by DB default
    };
  }
}
