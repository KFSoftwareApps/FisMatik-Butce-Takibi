
// Updated Mocking logic to match latest ProductNormalizationService
String normalizeProductName(String productName) {
    String normalized = productName.trim().toLowerCase();
    
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
      normalized = normalized.replaceAll(RegExp('\\b$brand\\b', caseSensitive: false, unicode: true), '');
    }

    final List<String> patternsToRemove = [
      r'\b\d+[,.]?\d*\s*(kg|gr|g|ml|l|lt|adet|li|lı|lu|lü|pk|paket|cl|cc|x\d+)\b',
      r'\b\d+\s*x\s*\d+\s*(ml|l|gr|g|kg|adet)?\b',
      r'\b\d+x\d+\b', 
    ];

    for (final pattern in patternsToRemove) {
      normalized = normalized.replaceAll(RegExp(pattern, caseSensitive: false, unicode: true), '');
    }

    normalized = normalized
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\sğüşıöçĞÜŞİÖÇ]'), '')
        .trim();

    if (normalized.isEmpty) return productName;
    
    return normalized.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
}

void main() {
    final tests = {
        'MIGROS SUT': 'Sut',
        'BIM YUMURTA 30LU': 'Yumurta',
        'SUTAS TAM YAGLI SUT 1LT': 'Tam Yagli Sut',
        'KIZILAY SADE MADEN SUYU 6X200ML': 'Sade Maden Suyu',
        'ELMA AMASYA 1 KG': 'Elma Amasya',
        'COCA COLA 2.5 L': 'Coca Cola',
        '   PEYNIR !!!  ': 'Peynir',
        '101 GOFRETI': '101 Gofreti',
    };

    bool allPassed = true;
    tests.forEach((input, expected) {
        final result = normalizeProductName(input);
        if (result != expected) {
            print('FAILED: "$input" -> "$result" (Expected: "$expected")');
            allPassed = false;
        } else {
            print('PASSED: "$input" -> "$result"');
        }
    });

    if (allPassed) {
        print('\nALL NORMALIZATION LOGIC TESTS PASSED!');
    } else {
        print('\nSOME TESTS FAILED!');
    }
}
