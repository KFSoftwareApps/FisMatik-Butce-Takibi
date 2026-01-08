

class ReceiptItem {
  final String name;
  final double price;
  final int quantity;
  final String? category; // Yeni alan

  ReceiptItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price.toDouble(),
      'quantity': quantity,
      'category': category,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      category: map['category'],
    );
  }
}

class Receipt {
  final String id;
  final String userId;
  final String merchantName;
  final DateTime date;
  final double totalAmount;
  final double taxAmount;      // Vergi tutarı
  final double discountAmount; // İndirim tutarı
  final String? imageUrl;
  final String category;
  final List<ReceiptItem> items;
  final bool isManual;      // true ise manuel giriş
  final String createdBy;   // fişi ekleyen kullanıcı id
  final String? familyId;   // aile planında ortak aile id
  final String source;      // scan, manual, sms
  final String? city;
  final String? district;

  Receipt({
    required this.id,
    required this.userId,
    required this.merchantName,
    required this.date,
    required this.totalAmount,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.imageUrl,
    required this.category,
    required this.items,
    this.isManual = false,
    String? createdBy,
    this.familyId,
    this.source = 'scan',
    this.city,
    this.district,
  }) : createdBy = createdBy ?? userId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId, // Supabase column name
      'merchant_name': merchantName,
      'date': date.toIso8601String(),
      'total_amount': totalAmount.toDouble(), // Ensure it's double
      'tax_amount': taxAmount.toDouble(),
      'discount_amount': discountAmount.toDouble(),
      'image_url': imageUrl,
      'category': category,
      'items': items.map((x) => x.toMap()).toList(),
      'is_manual': isManual,
      'created_by': createdBy,
      'household_id': familyId,
      'source': source,
      'city': city,
      'district': district,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawItems = (map['items'] as List?) ?? [];

    return Receipt(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      merchantName: map['merchant_name'] ?? 'Bilinmiyor',
      date: _parseDate(map['date']),
      totalAmount: (map['total_amount'] ?? 0).toDouble(),
      taxAmount: (map['tax_amount'] ?? 0).toDouble(),
      discountAmount: (map['discount_amount'] ?? 0).toDouble(),
      imageUrl: map['image_url'],
      category: map['category'] ?? 'Diğer',
      items: rawItems
          .map((x) => ReceiptItem.fromMap(x as Map<String, dynamic>))
          .toList(),
      isManual: map['is_manual'] == true,
      createdBy: (map['created_by'] ?? map['user_id'] ?? '') as String,
      familyId: map['household_id'] as String?,
      source: map['source'] ?? (map['is_manual'] == true ? 'manual' : 'scan'),
      city: map['city'] as String?,
      district: map['district'] as String?,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
