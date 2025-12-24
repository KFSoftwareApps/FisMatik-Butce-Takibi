import 'package:fismatik/models/receipt_model.dart';
import 'package:fismatik/models/subscription_model.dart';
import 'package:fismatik/services/supabase_database_service.dart';
import 'package:fismatik/services/gamification_service.dart';
import 'package:intl/intl.dart';

class IntelligenceService {
  final SupabaseDatabaseService _dbService = SupabaseDatabaseService();

  /// Son 3 aya ait fişlerden olası abonelikleri tespit eder.
  Future<List<Map<String, dynamic>>> detectPotentialSubscriptions() async {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    
    // Tüm fişleri çek
    final receipts = await _dbService.getReceiptsOnce();
    final relevantReceipts = receipts.where((r) => r.date.isAfter(threeMonthsAgo)).toList();

    // Satıcıya göre grupla
    final Map<String, List<Receipt>> groupedByMerchant = {};
    for (var r in relevantReceipts) {
      if (r.merchantName == 'Bilinmiyor') continue;
      groupedByMerchant.putIfAbsent(r.merchantName, () => []).add(r);
    }

    final List<Map<String, dynamic>> potentialSubs = [];

    groupedByMerchant.forEach((merchant, merchantReceipts) {
      if (merchantReceipts.length >= 2) {
        // En az 2 kez gelmiş. Tarih ve fiyat tutarlılığına bak.
        merchantReceipts.sort((a, b) => a.date.compareTo(b.date));
        
        for (int i = 0; i < merchantReceipts.length - 1; i++) {
          final r1 = merchantReceipts[i];
          final r2 = merchantReceipts[i+1];
          
          final dayDiff = r2.date.difference(r1.date).inDays;
          final priceDiffPercent = ((r1.totalAmount - r2.totalAmount).abs() / r1.totalAmount) * 100;

          // Yaklaşık 1 ay (25-35 gün) ve benzer fiyat (%10 tolerans)
          if (dayDiff >= 25 && dayDiff <= 35 && priceDiffPercent <= 10) {
            potentialSubs.add({
              'merchant': merchant,
              'price': r2.totalAmount,
              'renewalDay': r2.date.day,
              'lastDate': r2.date,
              'confidence': 'high',
            });
            break; // Bir satıcı için bir tane bulmak yeterli (şimdilik)
          }
        }
      }
    });

    return potentialSubs;
  }

  /// Mevcut bütçe kullanımına göre ay sonu tahmini yapar.
  Future<Map<String, dynamic>> getBudgetPrediction() async {
    final now = DateTime.now();
    final daysInMonthArray = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    int daysInMonth = daysInMonthArray[now.month];
    if (now.month == 2 && now.year % 4 == 0) daysInMonth = 29;

    final allReceipts = await _dbService.getReceiptsOnce();
    final currentMonthReceipts = allReceipts.where((r) => r.date.month == now.month && r.date.year == now.year).toList();
    final limit = await _dbService.getMonthlyLimitOnce();
    
    double totalSpent = 0;
    for (var r in currentMonthReceipts) {
      totalSpent += r.totalAmount;
    }

    final passedDays = now.day;
    final dailyAverage = passedDays > 0 ? totalSpent / passedDays : totalSpent;
    final predictedTotal = dailyAverage * daysInMonth;
    final isExceeding = predictedTotal > limit;

    return {
      'currentSpent': totalSpent,
      'limit': limit,
      'predictedTotal': predictedTotal,
      'isExceeding': isExceeding,
      'dailyAverage': dailyAverage,
      'remainingDays': daysInMonth - passedDays,
    };
  }

  /// Kategori bazlı harcamalara göre tasarruf ipuçları döner.
  Future<List<String>> getPersonalizedSavingTips() async {
    final now = DateTime.now();
    final allReceipts = await _dbService.getReceiptsOnce();
    final currentMonthReceipts = allReceipts.where((r) => r.date.month == now.month && r.date.year == now.year).toList();
    
    final Map<String, double> categorySpent = {};
    for (var r in currentMonthReceipts) {
      categorySpent[r.category] = (categorySpent[r.category] ?? 0) + r.totalAmount;
    }

    if (categorySpent.isEmpty) return ["Henüz yeterli harcama verisi yok. Fişlerinizi taratarak tasarruf ipuçları alabilirsiniz!"];

    final sortedCategories = categorySpent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategory = sortedCategories.first;
    final List<String> tips = [];

    if (topCategory.key == 'Market') {
      tips.add("Market harcamaların önde gidiyor. FişMatik Akıllı Fiyat Rehberi'ni kullanarak ürünleri en ucuz marketten almaya çalışabilirsin.");
    } else if (topCategory.key == 'Yeme-İçme') {
      tips.add("Dışarıda yemek yemek bütçeni zorluyor olabilir. Bu hafta evde yemek hazırlayarak tasarruf yapmayı deneyebilirsin.");
    } else if (topCategory.key == 'Ulaşım') {
      tips.add("Akaryakıt veya ulaşım giderlerin artmış. Mümkünse toplu taşıma araçlarını değerlendirebilirsin.");
    } else {
      tips.add("${topCategory.key} kategorisinde bu ay yoğun harcama yaptın. Bu kategorideki harcamalarını bir sonraki aya kaydırabilirsin.");
    }

    return tips;
  }

  /// Fiyat keşfi sayısını artırır (Phase 7)
  Future<void> incrementPriceDiscoveries() async {
    await GamificationService().incrementPriceDiscoveries();
  }
}
