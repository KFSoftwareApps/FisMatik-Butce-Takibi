import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt_model.dart';
import 'package:fismatik/services/supabase_database_service.dart';

class ProductMappingData {
  final String name;
  final String? category;

  ProductMappingData({required this.name, this.category});
}

// Extension for product normalization
extension ProductNormalization on SupabaseDatabaseService {
  
  // Static cache for global product mappings
  static Map<String, Map<String, dynamic>> _globalMappings = {};
  static bool _mappingsLoaded = false;

  /// Loads global product mappings from Supabase
  Future<void> loadGlobalProductMappings() async {
    final mappings = await getGlobalProductMappings();
    _globalMappings = {
      for (var m in mappings) m['raw_name'] as String: m as Map<String, dynamic>
    };
    _mappingsLoaded = true;
  }

  /// Returns both normalized name and category if mapped.
  ProductMappingData getNormalizedData(String rawName) {
    // 1. Check global mappings first
    if (_mappingsLoaded && _globalMappings.containsKey(rawName)) {
      final mapping = _globalMappings[rawName]!;
      return ProductMappingData(
        name: mapping['normalized_name'] as String,
        category: mapping['category'] as String?,
      );
    }
    
    // 2. Fallback to algorithmic normalization
    return ProductMappingData(
      name: normalizeProductName(rawName),
      category: guessCategoryFromName(rawName),
    );
  }

  /// Normalizes a product name by checking global mappings first, 
  /// then falling back to algorithmic normalization.
  String normalizeProductName(String productName) {
    // 1. Check global mappings first
    if (_mappingsLoaded && _globalMappings.containsKey(productName)) {
      return _globalMappings[productName]!['normalized_name'] as String;
    }
    
    // 2. Fallback to existing logic
    String normalized = productName.trim().toLowerCase();
    
    // Common Turkish brand names to remove
    final List<String> brandsToRemove = [
      'migros', 'carrefour', 'bim', 'a101', 'sok', 'şok', 'onur', 'fity', 'torku',
      'pınar', 'pinar', 'dost', 'sütaş', 'sütas', 'ülker', 'ulker', 'eti', 'nestle', 'banvit',
      'ipek', 'pastavilla', 'ankara', 'oba', 'sinangil', 'hekimoğlu', 'söke', 'tariş',
      'komili', 'yudum', 'orkide', 'biryağ', 'aytaç', 'şahin', 'namet', 'cumhuriyet',
      'maret', 'erşan', 'polonez', 'lezzet', 'osmanoğlu', 'fiskobirlik', 'marmarabirlik',
      'pınar', 'tat', 'tamek', 'tukaş', 'kent', 'dr.oetker', 'knorr', 'maggi', 'londra',
      'lipton', 'doğuş', 'caykur', 'çaykur', 'mehmet efendi', 'kurukahveci', 'jacobs',
      'nescafe', 'kızılay', 'freşa', 'avşar', 'beypazarı', 'erikli', 'hayat', 'pınar su',
      'damla', 'sırma', 'fusetea', 'lipton ice tea', 'coca cola', 'pepsi', 'fanta',
      'yedigün', 'firuze', 'sprite', 'fruko', 'mavi kart'
    ];

    for (final brand in brandsToRemove) {
      // Use case-insensitive regex with word boundaries
      normalized = normalized.replaceAll(RegExp('\\b$brand\\b', caseSensitive: false, unicode: true), '');
    }

    // Common packaging and quantity suffixes to remove
    final List<String> patternsToRemove = [
      r'\b\d+[,.]?\d*\s*(kg|gr|g|ml|l|lt|adet|li|lı|lu|lü|pk|paket|cl|cc|x\d+)\b',
      r'\b\d+\s*x\s*\d+\s*(ml|l|gr|g|kg|adet)?\b',
      r'\b\d+x\d+\b', 
    ];

    for (final pattern in patternsToRemove) {
      normalized = normalized.replaceAll(RegExp(pattern, caseSensitive: false, unicode: true), '');
    }

    // Cleanup extra spaces and special chars
    normalized = normalized
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\sğüşıöçĞÜŞİÖÇ]'), '')
        .trim();

    if (normalized.isEmpty) return productName;
    
    // Capitalize first letter of each word
    return normalized.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String guessCategoryFromName(String name) {
    final lowerName = name.toLowerCase().trim();

    // Hariç Tutulacaklar (Kategori olarak sayılmayacaklar)
    if (lowerName.contains('indirim') ||
        lowerName.contains('kdv') ||
        lowerName.contains('vergi') ||
        lowerName.contains('iskonto') ||
        lowerName.contains('toplam') ||
        lowerName.contains('ara toplam')) {
      return 'Diğer'; 
    }

    // --- EV EŞYASI & ZÜCCACİYE ---
    if (lowerName.contains('sürahi') ||
        lowerName.contains('cam') ||
        lowerName.contains('bardak') ||
        lowerName.contains('tabak') ||
        lowerName.contains('kaşık') ||
        lowerName.contains('çatal') ||
        lowerName.contains('bıçak') ||
        lowerName.contains('tencere') ||
        lowerName.contains('tava') ||
        lowerName.contains('kase') ||
        lowerName.contains('fincan') ||
        lowerName.contains('kavanoz') ||
        lowerName.contains('plastik') ||
        lowerName.contains('mutfak') ||
        lowerName.contains('züccaciye')) {
      return 'Ev Eşyası';
    }

    // --- MARKET & GIDA ---
    
    // Temel Gıda & Kahvaltılık
    if (lowerName.contains('ekmek') ||
        lowerName.contains('yumurta') ||
        lowerName.contains('peynir') ||
        lowerName.contains('kasar') || lowerName.contains('kaşar') ||
        lowerName.contains('labne') ||
        lowerName.contains('yogurt') || lowerName.contains('yoğurt') ||
        lowerName.contains('süt') || 
        lowerName.contains('kaymak') ||
        lowerName.contains('tereyag') || lowerName.contains('tereyağ') ||
        lowerName.contains('margarin') ||
        lowerName.contains('zeytin') ||
        lowerName.contains('reçel') || lowerName.contains('recel') ||
        lowerName.contains('bal') ||
        lowerName.contains('helva') ||
        lowerName.contains('un') ||
        lowerName.contains('seker') || lowerName.contains('şeker') ||
        lowerName.contains('tuz') ||
        lowerName.contains('makarna') ||
        lowerName.contains('pirinç') || lowerName.contains('pirinc') ||
        lowerName.contains('bulgur') ||
        lowerName.contains('mercimek') ||
        lowerName.contains('nohut') ||
        lowerName.contains('fasulye') ||
        lowerName.contains('salça') || lowerName.contains('salca') ||
        lowerName.contains('yağ') || lowerName.contains('yağ')) {
      return 'Market';
    }

    if (lowerName.contains('kıyma') || lowerName.contains('kiyma') ||
        lowerName.contains('kuşbaşı') || lowerName.contains('kusbasi') ||
        lowerName.contains('biftek') ||
        lowerName.contains('antrikot') ||
        lowerName.contains('bonfile') ||
        lowerName.contains('köfte') || lowerName.contains('kofte') ||
        lowerName.contains('tavuk') ||
        lowerName.contains('piliç') || lowerName.contains('pilic') ||
        lowerName.contains('kanat') ||
        lowerName.contains('baget') ||
        lowerName.contains('bütün tavuk') ||
        lowerName.contains('balık') || lowerName.contains('balik') ||
        lowerName.contains('hamsi') ||
        lowerName.contains('somon') ||
        lowerName.contains('ton balığı') ||
        lowerName.contains('sucuk') ||
        lowerName.contains('salam') ||
        lowerName.contains('sosis') ||
        lowerName.contains('pastırma')) {
      return 'Market'; 
    }

    if (lowerName.contains('domates') ||
        lowerName.contains('biber') ||
        lowerName.contains('patlıcan') ||
        lowerName.contains('salatalık') ||
        lowerName.contains('kabak') ||
        lowerName.contains('soğan') || lowerName.contains('sogan') ||
        lowerName.contains('patates') ||
        lowerName.contains('havuç') ||
        lowerName.contains('marul') ||
        lowerName.contains('maydanoz') ||
        lowerName.contains('dereotu') ||
        lowerName.contains('elma') ||
        lowerName.contains('muz') ||
        lowerName.contains('portakal') ||
        lowerName.contains('mandalina') ||
        lowerName.contains('limon') ||
        lowerName.contains('karpuz') ||
        lowerName.contains('kavun') ||
        lowerName.contains('çilek') ||
        lowerName.contains('üzüm')) {
      return 'Market';
    }

    if (lowerName.contains('su ') || lowerName == 'su' ||
        lowerName.contains('maden suyu') ||
        lowerName.contains('soda') ||
        lowerName.contains('kola') ||
        lowerName.contains('cola') ||
        lowerName.contains('pepsi') ||
        lowerName.contains('fanta') ||
        lowerName.contains('sprite') ||
        lowerName.contains('gazoz') ||
        lowerName.contains('soğuk çay') || lowerName.contains('ice tea') ||
        lowerName.contains('limonata') ||
        lowerName.contains('meyve suyu') ||
        lowerName.contains('ayran') ||
        lowerName.contains('kefir') ||
        lowerName.contains('bira') ||
        lowerName.contains('rakı') ||
        lowerName.contains('şarap') ||
        lowerName.contains('votka') ||
        lowerName.contains('viski') || 
        lowerName.contains('kahve') ||
        lowerName.contains('çay') || lowerName.contains('cay') ||
        lowerName.contains('sahlep')) {
      return 'Market'; 
    }

    if (lowerName.contains('çikolata') || lowerName.contains('cikolata') ||
        lowerName.contains('gofret') ||
        lowerName.contains('bisküvi') || lowerName.contains('biskuvi') ||
        lowerName.contains('kraker') ||
        lowerName.contains('cips') ||
        lowerName.contains('kuruyemiş') ||
        lowerName.contains('fıstık') ||
        lowerName.contains('fındık') ||
        lowerName.contains('ceviz') ||
        lowerName.contains('sakız') ||
        lowerName.contains('dondurma') ||
        lowerName.contains('kek')) {
      return 'Atıştırmalık';
    }

    if (lowerName.contains('sigara') ||
        lowerName.contains('marlboro') ||
        lowerName.contains('parliament') ||
        lowerName.contains('winston') ||
        lowerName.contains('camel') ||
        lowerName.contains('kent') ||
        lowerName.contains('muratti') ||
        lowerName.contains('davidoff')) {
      return 'Diğer'; 
    }

    if (lowerName.contains('benzin') ||
        lowerName.contains('motorin') ||
        lowerName.contains('lpg') ||
        lowerName.contains('dizel') ||
        lowerName.contains('yakıt')) {
      return 'Akaryakıt';
    }

    return 'Diğer';
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
