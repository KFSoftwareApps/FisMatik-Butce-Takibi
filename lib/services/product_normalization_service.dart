import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt_model.dart';
import 'supabase_database_service.dart';

// Extension for product normalization
extension ProductNormalization on SupabaseDatabaseService {
  
  /// Normalizes a product name by removing brand names, quantities, and packaging info
  /// Examples:
  /// - "Dost Süt 1L" -> "Süt"
  /// - "Pınar Tam Yağlı Süt 500ml" -> "Süt"
  /// - "Migros Ekmek 450g" -> "Ekmek"
  String normalizeProductName(String productName) {
    String normalized = productName.trim().toLowerCase();
    
    // Common Turkish brand names to remove
    final brands = [
      'dost', 'pınar', 'migros', 'bim', 'a101', 'şok', 'carrefour',
      'kiler', 'metro', 'makro', 'ülker', 'eti', 'torku', 'tadım',
      'sütaş', 'danone', 'nestle', 'coca cola', 'pepsi', 'fanta'
    ];
    
    // Remove brand names
    for (final brand in brands) {
      normalized = normalized.replaceAll(RegExp('\\b$brand\\b', caseSensitive: false), '');
    }
    
    // Remove quantities and units
    normalized = normalized.replaceAll(RegExp(r'\d+\s*(ml|lt|l|gr|g|kg|adet|ad|cl)'), '');
    normalized = normalized.replaceAll(RegExp(r'\d+x\d+'), ''); // 2x500ml gibi
    
    // Remove common descriptors
    final descriptors = [
      'tam yağlı', 'yarım yağlı', 'yağsız', 'light', 'organik', 'doğal',
      'taze', 'günlük', 'kepekli', 'beyaz', 'esmer', 'tam buğday',
      'glutensiz', 'laktozsuz', 'şekersiz', 'tuzsuz'
    ];
    
    for (final descriptor in descriptors) {
      normalized = normalized.replaceAll(RegExp('\\b$descriptor\\b', caseSensitive: false), '');
    }
    
    // Clean up extra spaces and trim
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Capitalize first letter
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1);
    }
    
    return normalized.isEmpty ? productName : normalized;
  }
  
  /// Get user's price comparison mode preference (brand vs generic)
  Future<String> getUserPriceComparisonMode() async {
    try {
      final response = await Supabase.instance.client
          .from('user_preferences')
          .select('price_comparison_mode')
          .eq('user_id', currentUser?.id ?? '')
          .maybeSingle();
      
      if (response != null && response['price_comparison_mode'] != null) {
        return response['price_comparison_mode'] as String;
      }
    } catch (e) {
      print('Error fetching price comparison mode: $e');
    }
    
    return 'generic'; // Default to generic mode
  }
  
  /// Set user's price comparison mode preference
  Future<void> setUserPriceComparisonMode(String mode) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    
    if (mode != 'brand' && mode != 'generic') {
      throw Exception('Invalid mode. Must be "brand" or "generic"');
    }
    
    await Supabase.instance.client
        .from('user_preferences')
        .upsert(
          {
            'user_id': userId,
            'price_comparison_mode': mode,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id',
        );
  }
  
  /// Get product history grouped by normalized name (generic mode)
  Future<Map<String, List<Map<String, dynamic>>>> getProductHistoryByNormalizedName(
    List<Receipt> receipts,
  ) async {
    final Map<String, List<Map<String, dynamic>>> groupedProducts = {};
    
    for (final receipt in receipts) {
      for (final item in receipt.items) {
        final normalizedName = normalizeProductName(item.name);
        
        if (!groupedProducts.containsKey(normalizedName)) {
          groupedProducts[normalizedName] = [];
        }
        
        groupedProducts[normalizedName]!.add({
          'original_name': item.name,
          'price': item.price,
          'date': receipt.date,
          'merchant': receipt.merchantName,
          'receipt_id': receipt.id,
        });
      }
    }
    
    // Sort each group by date descending
    for (final key in groupedProducts.keys) {
      groupedProducts[key]!.sort((a, b) => 
        (b['date'] as DateTime).compareTo(a['date'] as DateTime)
      );
    }
    
    return groupedProducts;
  }
  
  /// Get product history for exact brand match (brand mode)
  Future<List<Map<String, dynamic>>> getProductHistoryByBrand(
    String exactProductName,
    List<Receipt> receipts,
  ) async {
    final List<Map<String, dynamic>> history = [];
    
    for (final receipt in receipts) {
      for (final item in receipt.items) {
        if (item.name.toLowerCase() == exactProductName.toLowerCase()) {
          history.add({
            'original_name': item.name,
            'price': item.price,
            'date': receipt.date,
            'merchant': receipt.merchantName,
            'receipt_id': receipt.id,
          });
        }
      }
    }
    
    // Sort by date descending
    history.sort((a, b) => 
      (b['date'] as DateTime).compareTo(a['date'] as DateTime)
    );
    
    return history;
  }
  
  /// Get price statistics for a normalized product
  Map<String, dynamic> getProductPriceStats(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return {
        'min_price': 0.0,
        'max_price': 0.0,
        'avg_price': 0.0,
        'brand_count': 0,
        'cheapest_market': null,
        'brands': <String>[],
      };
    }
    
    final prices = history.map((h) => (h['price'] as num).toDouble()).toList();
    final brands = history.map((h) => h['original_name'] as String).toSet().toList();
    
    // Find cheapest market from recent purchases (last 30 days)
    final recentHistory = history.where((h) {
      final date = h['date'] as DateTime;
      return DateTime.now().difference(date).inDays <= 30;
    }).toList();
    
    String? cheapestMarket;
    if (recentHistory.isNotEmpty) {
      recentHistory.sort((a, b) => 
        (a['price'] as num).compareTo(b['price'] as num)
      );
      cheapestMarket = recentHistory.first['merchant'] as String?;
    }
    
    return {
      'min_price': prices.reduce((a, b) => a < b ? a : b),
      'max_price': prices.reduce((a, b) => a > b ? a : b),
      'avg_price': prices.reduce((a, b) => a + b) / prices.length,
      'brand_count': brands.length,
      'cheapest_market': cheapestMarket,
      'brands': brands,
    };
  }
}
