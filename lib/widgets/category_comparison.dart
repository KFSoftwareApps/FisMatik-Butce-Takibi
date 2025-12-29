import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import '../services/supabase_database_service.dart';
import '../utils/currency_formatter.dart';

/// Kategori Karşılaştırma Widget'ı
/// Analiz ekranında kullanılmak üzere
class CategoryComparisonWidget extends StatelessWidget {
  final List<Receipt> currentReceipts;
  final String period; // 'month' veya 'year'

  const CategoryComparisonWidget({
    super.key,
    required this.currentReceipts,
    this.period = 'month',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, ComparisonData>>(
      future: _calculateComparison(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                period == 'month' ? 'Geçen Aya Göre' : 'Geçen Yıla Göre',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...data.entries.map((entry) => _buildComparisonCard(entry.key, entry.value)),
          ],
        );
      },
    );
  }

  Future<Map<String, ComparisonData>> _calculateComparison() async {
    final now = DateTime.now();
    final databaseService = SupabaseDatabaseService();

    // Geçmiş dönem fişlerini al
    final allReceipts = await databaseService.getAllReceiptsOnce();
    
    DateTime startDate, endDate;
    if (period == 'month') {
      // Geçen ay
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 0);
    } else {
      // Geçen yıl aynı ay
      startDate = DateTime(now.year - 1, now.month, 1);
      endDate = DateTime(now.year - 1, now.month + 1, 0);
    }

    final previousReceipts = allReceipts.where((r) {
      return r.date.isAfter(startDate) && r.date.isBefore(endDate);
    }).toList();

    // Kategori bazlı toplamları hesapla
    final currentTotals = _groupByCategory(currentReceipts);
    final previousTotals = _groupByCategory(previousReceipts);

    final result = <String, ComparisonData>{};
    
    // Tüm kategorileri dahil et
    final allCategories = {...currentTotals.keys, ...previousTotals.keys};
    
    for (var category in allCategories) {
      final current = currentTotals[category] ?? 0;
      final previous = previousTotals[category] ?? 0;
      
      double changePercent = 0;
      if (previous > 0) {
        changePercent = ((current - previous) / previous) * 100;
      } else if (current > 0) {
        changePercent = 100; // Yeni kategori
      }

      result[category] = ComparisonData(
        current: current,
        previous: previous,
        changePercent: changePercent,
      );
    }

    return result;
  }

  Map<String, double> _groupByCategory(List<Receipt> receipts) {
    final result = <String, double>{};
    for (var receipt in receipts) {
      result[receipt.category] = (result[receipt.category] ?? 0) + receipt.totalAmount;
    }
    return result;
  }

  Widget _buildComparisonCard(String category, ComparisonData data) {
    // Using CurrencyFormatter
    final isIncrease = data.changePercent > 0;
    final isDecrease = data.changePercent < 0;
    
    Color changeColor = Colors.grey;
    IconData changeIcon = Icons.remove;
    
    if (isIncrease) {
      changeColor = Colors.red;
      changeIcon = Icons.trending_up;
    } else if (isDecrease) {
      changeColor = Colors.green;
      changeIcon = Icons.trending_down;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Kategori ikonu
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          
          // Kategori adı ve tutarlar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(data.current),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    if (data.previous > 0) ...[
                      const Text(' ← ', style: TextStyle(color: Colors.grey)),
                      Text(
                        CurrencyFormatter.format(data.previous),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Değişim yüzdesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(changeIcon, size: 16, color: changeColor),
                const SizedBox(width: 4),
                Text(
                  '${data.changePercent.abs().toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Market':
        return Icons.shopping_cart;
      case 'Akaryakıt':
        return Icons.local_gas_station;
      case 'Yeme-İçme':
        return Icons.restaurant;
      case 'Giyim':
        return Icons.checkroom;
      case 'Teknoloji':
        return Icons.computer;
      default:
        return Icons.category;
    }
  }
}

class ComparisonData {
  final double current;
  final double previous;
  final double changePercent;

  ComparisonData({
    required this.current,
    required this.previous,
    required this.changePercent,
  });
}
