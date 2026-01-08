import 'package:fismatik/models/receipt_model.dart';
import 'package:fismatik/models/subscription_model.dart';
import 'package:fismatik/services/supabase_database_service.dart';
import 'package:fismatik/services/gamification_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // [NEW]

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

    // Tüm birleştirilmiş harcamaları çek (Fiş + Taksit + Abonelik)
    final allReceipts = await _dbService.getUnifiedReceiptsOnce();
    final currentMonthReceipts = allReceipts.where((r) => r.date.month == now.month && r.date.year == now.year).toList();
    final limit = await _dbService.getMonthlyLimitOnce();
    
    // 1. Mevcut Harcama (Bugüne kadar olanlar)
    double currentSpent = 0;
    for (var r in currentMonthReceipts) {
      // Gelecek tarihli sabit giderleri "Şu an harcanmış" olarak sayma (UI ile tutarlı olması için)
      if (r.date.isBefore(now.add(const Duration(days: 1)))) {
        currentSpent += r.totalAmount;
      }
    }

    // 2. Tahmin Algoritması (Fixed vs Variable)
    double fixedTotal = 0;
    double variableSpentSoFar = 0;
    
    for (var r in currentMonthReceipts) {
      final isFixed = r.category == 'Sabit Gider' || r.id.startsWith('sub_') || r.id.startsWith('credit_');
      
      if (isFixed) {
        // Sabit giderlerin tamamını (gelecektekiler dahil) kesin gider olarak ekle
        fixedTotal += r.totalAmount;
      } else {
        // Değişken giderlerde sadece bugüne kadar olanları al
        if (r.date.isBefore(now.add(const Duration(days: 1)))) {
          variableSpentSoFar += r.totalAmount;
        }
      }
    }

    final passedDays = now.day;
    // Değişken giderler için günlük ortalama
    final dailyVariableAverage = passedDays > 0 ? variableSpentSoFar / passedDays : variableSpentSoFar;
    
    // Kalan günler için değişken gider tahmini
    final remainingDays = daysInMonth - passedDays;
    final predictedVariableTotal = variableSpentSoFar + (dailyVariableAverage * remainingDays);
    
    // Toplam Tahmin = Kesinleşmiş Sabit Giderler + Tahmini Değişken Giderler
    final predictedTotal = fixedTotal + predictedVariableTotal;
    
    final isExceeding = predictedTotal > limit;
    final dailyTotalAverage = passedDays > 0 ? currentSpent / passedDays : currentSpent; // Genel ortalama (gösterim için)

    return {
      'currentSpent': currentSpent,
      'limit': limit,
      'predictedTotal': predictedTotal,
      'isExceeding': isExceeding,
      'dailyAverage': dailyTotalAverage, 
      'remainingDays': remainingDays,
    };
  }

  /// Kategori bazlı harcamalara göre tasarruf ipuçları döner.
  Future<List<String>> getPersonalizedSavingTips() async {
    final now = DateTime.now();
    final allReceipts = await _dbService.getUnifiedReceiptsOnce();
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

  /// AI Sohbet Cevabı (Hybrid: Edge Function -> Fallback Local Rule-Based)
  Future<String> getChatResponse(String prompt) async {
    // 1. Önce Edge Function'ı dene (Gerçek AI)
    try {
      print("Invoking Edge Function: chat with prompt: $prompt");
      final response = await Supabase.instance.client.functions.invoke(
        'chat',
        body: {'message': prompt}, 
      );

      print("Edge Function Response Status: ${response.status}");
      final data = response.data;

      if (data != null) {
        if (data['ok'] == true) {
          return data['reply']?.toString() ?? data['data']?.toString() ?? "Boş yanıt.";
        } else {
          // Limit dolduysa veya yetki yoksa hata mesajını direkt dön
          if (data['code'] == 'CHAT_LIMIT_REACHED' || data['code'] == 'UNAUTHORIZED') {
            return "⚠️ ${data['message']}";
          }
          // Diğer hatalar için (örn: API key hatası) yerel moda geç
          print("Edge Function Hata: ${data['code']} - ${data['message']}");
        }
      }
    } catch (e) {
      print("Edge Function Call Failed (Switching to Local Loop): $e");
    }

    // 2. Fallback: Yerel Kural Tabanlı Mantık
    return _getLocalHeuristicResponse(prompt);
  }

  Future<String> _getLocalHeuristicResponse(String prompt) async {
    final lowerPrompt = prompt.toLowerCase();

    // 1. Selamlama
    if (lowerPrompt.contains('merhaba') || lowerPrompt.contains('selam') || lowerPrompt.contains('naber')) {
      return "Merhaba! Harcamalarını kontrol altına almaya hazır mısın? Bugün senin için ne yapabilirim?";
    }

    // 2. Bütçe Durumu
    if (lowerPrompt.contains('bütçe') || lowerPrompt.contains('durum') || lowerPrompt.contains('kaldı') || lowerPrompt.contains('limit')) {
      final prediction = await getBudgetPrediction();
      final double current = prediction['currentSpent'];
      final double limit = prediction['limit'];
      final double remaining = limit - current;
      final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
      
      if (remaining < 0) {
        return "Dikkat! Aylık bütçeni ${currency.format(remaining.abs())} aşmış durumdasın. 🚨 Biraz daha dikkatli olmalısın.";
      } else {
        return "Bu ay toplam ${currency.format(current)} harcama yaptın. Limite ulaşmana daha ${currency.format(remaining)} var. gayet iyi gidiyorsun! 👍";
      }
    }

    // 3. Tasarruf ve Tavsiye İpuçları
    if (lowerPrompt.contains('tasarruf') || 
        lowerPrompt.contains('öneri') || 
        lowerPrompt.contains('ipucu') || 
        lowerPrompt.contains('yardım') ||
        lowerPrompt.contains('düzelt') ||
        lowerPrompt.contains('borç') ||
        lowerPrompt.contains('kredi') ||
        (lowerPrompt.contains('çok') && lowerPrompt.contains('harcama'))) {
      
      final tips = await getPersonalizedSavingTips();
      if (tips.isNotEmpty) {
        return "Gereksiz harcamaları kısmak için buradayım! 🛡️\n\nAnalizlerime göre: ${tips.first}\n\nAyrıca sabit giderlerini ve aboneliklerini 'Abonelikler' menüsünden gözden geçirebilirsin.";
      } else {
        return "Harcamalarını düzeltmek için bütçe limiti koymanı öneririm. 'Ayarlar' menüsünden aylık limit belirleyebilirsin. Ayrıca market alışverişlerinde 'En Ucuz' özelliğimizi kullanarak tasarruf edebilirsin.";
      }
    }

    // 4. Harcama Sorgusu (Raporlama)
    if (lowerPrompt.contains('harcadım') || lowerPrompt.contains('ne kadar') || lowerPrompt.contains('toplam') || lowerPrompt.contains('ekstre')) {
      final now = DateTime.now();
      final allReceipts = await _dbService.getUnifiedReceiptsOnce();
      final currentMonthReceipts = allReceipts.where((r) => r.date.month == now.month && r.date.year == now.year).toList();
      double total = 0;
      for (var r in currentMonthReceipts) total += r.totalAmount;
      
      final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
      return "Bu ay şu ana kadar toplam ${currency.format(total)} harcama yaptın.";
    }

    // 5. Bilinmeyen
    return "Şu an yerel moddayım ve bunu tam anlayamadım. 🤖\n\nŞunları sorabilirsin:\n• 'Bütçem ne durumda?'\n• 'Bu ay ne kadar harcadım?'\n• 'Tasarruf önerisi ver' (veya 'Çok harcama yapıyorum')";
  }
}
