class ShoppingItem {
  final String id;
  final String userId;
  final String name;
  final bool isChecked;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.userId,
    required this.name,
    this.isChecked = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'is_checked': isChecked,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      isChecked: map['is_checked'] ?? false,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  ShoppingItem copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isChecked,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
