class Subscription {
  final String id;
  final String name;        // Örn: Netflix
  final double price;       // Örn: 199.99
  final int renewalDay;     // Örn: Her ayın 15'i
  final String colorHex;    // Logonun arka plan rengi
  final String source;      // örn: 'app', 'demo'

  Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.renewalDay,
    required this.colorHex,
    this.source = 'app',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'renewal_day': renewalDay,
      'color_hex': colorHex,
      'source': source,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Abonelik',
      price: (map['price'] ?? 0).toDouble(),
      renewalDay: map['renewal_day'] ?? 1,
      colorHex: map['color_hex'] ?? 'FF2196F3',
      source: map['source'] ?? 'app',
    );
  }
}
