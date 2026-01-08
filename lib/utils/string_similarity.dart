// lib/utils/string_similarity.dart

class StringSimilarity {
  /// İki metin arasındaki benzerliği 0.0 ile 1.0 arasında döndürür.
  /// Dice Coefficient (Sørensen–Dice index) kullanır.
  /// Bu yöntem OCR hatalarına karşı Levenshtein'dan daha toleranslı olabilir
  /// ve uzun metinlerde daha hızlıdır.
  static double compare(String? s1, String? s2) {
    if (s1 == null || s2 == null) return 0.0;
    if (s1 == s2) return 1.0;
    
    // Boşlukları ve noktalama işaretlerini temizle, küçük harfe çevir
    final str1 = _clean(s1);
    final str2 = _clean(s2);

    if (str1.isEmpty && str2.isEmpty) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    // Bigramları oluştur
    final bigrams1 = _getBigrams(str1);
    final bigrams2 = _getBigrams(str2);

    // Kesişimi bul
    int intersection = 0;
    for (final bigram in bigrams1) {
      if (bigrams2.contains(bigram)) {
        intersection++;
        // Eşleşen bigramı listeden çıkar ki tekrar sayılmasın (isteğe bağlı, ama daha doğru)
        bigrams2.remove(bigram); 
      }
    }

    // Dice katsayısı: 2 * |X ∩ Y| / (|X| + |Y|)
    return (2.0 * intersection) / (bigrams1.length + _getBigrams(str2).length);
  }

  static String _clean(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^\w]'), '');
  }

  static List<String> _getBigrams(String s) {
    final List<String> bigrams = [];
    for (int i = 0; i < s.length - 1; i++) {
      bigrams.add(s.substring(i, i + 2));
    }
    return bigrams;
  }
}
