import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final int colorValue; // Rengi veritabanında sayı olarak tutacağız
  final int iconCode;   // İkonu sayı olarak tutacağız
  final double budgetLimit; // Aylık Bütçe Hedefi (0 = Limit Yok)

  Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCode,
    this.budgetLimit = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'iconCode': iconCode,
      'budgetLimit': budgetLimit,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Genel',
      colorValue: map['colorValue'] ?? 0xFF2196F3, // Varsayılan Mavi
      iconCode: map['iconCode'] ?? 0xe145, // Varsayılan Etiket İkonu
      budgetLimit: (map['budgetLimit'] ?? 0).toDouble(),
    );
  }

  // Varsayılan Kategoriler Listesi
  static List<Category> defaultCategories = [
    Category(id: '1', name: 'Market', colorValue: 0xFF4CAF50, iconCode: 0xe59c), // shopping_cart
    Category(id: '2', name: 'Yeme-İçme', colorValue: 0xFFFF9800, iconCode: 0xe532), // restaurant
    Category(id: '3', name: 'Akaryakıt', colorValue: 0xFFF44336, iconCode: 0xe3e7), // local_gas_station
    Category(id: '4', name: 'Giyim', colorValue: 0xFF9C27B0, iconCode: 0xe15f), // checkroom
    Category(id: '5', name: 'Teknoloji', colorValue: 0xFF2196F3, iconCode: 0xe1b8), // computer
    Category(id: '6', name: 'Sağlık', colorValue: 0xFFE91E63, iconCode: 0xe357), // local_hospital
    Category(id: '8', name: 'Ev Eşyası', colorValue: 0xFF009688, iconCode: 0xeb47), // kitchen
    Category(id: '7', name: 'Diğer', colorValue: 0xFF9E9E9E, iconCode: 0xe145), // category
  ];
}
