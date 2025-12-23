import 'dart:math';

class ProductMerger {
  static List<Map<String, dynamic>> calculateStats(List<Map<String, dynamic>> rawItems) {
    // rawItems: list of {name, quantity, price, category}
    
    final Map<String, Map<String, dynamic>> stats = {}; // key -> stat object
    
    for (final item in rawItems) {
      final String originalName = item['name'];
      final double quantity = (item['quantity'] as num).toDouble();
      final double price = (item['price'] as num).toDouble();
      final double total = quantity * price;
      
      // 1. Aggressive Normalization
      String normalized = _normalize(originalName);
      
      // 2. Fuzzy Matching Check against existing keys
      String? bestMatchKey;
      
      if (stats.containsKey(normalized)) {
        bestMatchKey = normalized;
      } else {
        // Try to find a similar key in existing stats
        // To be fast, maybe only check keys with same first letter or length similarity?
        // Let's iterate all keys for now (assuming < 200 unique products usually)
        // If list is huge, we might need bucketing.
        
        int bestDist = 100;
        
        for (final existingKey in stats.keys) {
          // Optimization: Length check first
          if ((existingKey.length - normalized.length).abs() > 3) continue;
          
          // Optimization: First char check (optional, but good for speed)
          if (existingKey.isNotEmpty && normalized.isNotEmpty && existingKey[0] != normalized[0]) continue;

          final dist = _levenshtein(existingKey, normalized);
          
          // Threshold: 3 edits or 20% of length?
          // For "Sürahi Cam" (10 chars), 3 edits is a lot. 
          // "Sürahi Cam" vs "Sürahi Cam DI" -> dist approx 3.
          
          if (dist < 4 && dist < bestDist) {
             bestDist = dist;
             bestMatchKey = existingKey;
          }
           
           // Also check specifically for "Containment"
           // "Sürahi Cam" is contained in "Sürahi Cam DI"
           if (existingKey.startsWith(normalized) || normalized.startsWith(existingKey)) {
              // Prefer the shorter one as key usually?
              bestMatchKey = existingKey; // Merge into existing
              bestDist = 0; // Force match
              break; 
           }
        }
      }
      
      final targetKey = bestMatchKey ?? normalized;
      
      if (stats.containsKey(targetKey)) {
        final existing = stats[targetKey]!;
        existing['count'] = (existing['count'] as num) + quantity;
        existing['totalAmount'] = (existing['totalAmount'] as num) + total;
      } else {
        stats[targetKey] = {
          'name': originalName, // Use the first one found as display name
          'count': quantity,
          'totalAmount': total,
          'category': item['category'], // We'll handle category guessing outside or pass it in
        };
      }
    }
    
    return stats.values.toList();
  }

  static String _normalize(String input) {
    return input.toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[\s\u00A0\u200B]+'), ' ') // Convert all spacing to single space
        .replaceAll(RegExp(r'\sDI$'), '') // Remove specific suffix logic if needed? maybe risky.
        .trim();
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) v0[i] = i;

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j < t.length + 1; j++) v0[j] = v1[j];
    }

    return v1[t.length];
  }
}
