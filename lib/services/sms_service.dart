import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

/// SMS ile harcama tespiti servisi (Phase 8)
class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final Telephony telephony = Telephony.instance;
  
  // Banka ve E-ticaret Regex tanımları
  static final List<RegExp> _expensePatterns = [
    // Standart banka harcama formatı (örn: ... işyerinden 150.50 TL harcama ...)
    RegExp(r'(\d+[\.,]\d{2})\s?TL.*?(?:harcama|işlem)', caseSensitive: false),
    // Trendyol/Hepsiburada formatı (örn: Trendyol: 250.00 TL tutarındaki siparişiniz onaylandı)
    RegExp(r'(?:Trendyol|Hepsiburada|Amazon).*?(\d+[\.,]\d{2})\s?TL', caseSensitive: false),
    // Provizyon formatı
    RegExp(r'(\d+[\.,]\d{2})\s?TL.*?provizyonda', caseSensitive: false),
  ];

  /// Servisi başlat ve dinlemeye başla
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    bool isEnabled = prefs.getBool('sms_tracking_enabled') ?? false;
    
    if (!isEnabled) return;

    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted == true) {
      telephony.listenIncomingSms(
        onNewMessage: _onMessageReceived,
        onBackgroundMessage: _backgrounMessageHandler,
      );
    }
  }

  /// Yeni mesaj geldiğinde çalışır
  void _onMessageReceived(SmsMessage message) {
    _processMessage(message);
  }

  // Statik metodlar (Arka plan servisi için erişilebilir olmalı)
  
  static Future<void> processMessageStatic(SmsMessage message) async {
    final String body = message.body ?? '';
    final String sender = message.address ?? 'Bilinmiyor';
    
    double? amount;
    String? merchant;

    // Harcama miktarını bul
    for (var pattern in _expensePatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        String amountStr = match.group(1)!.replaceAll(',', '.');
        amount = double.tryParse(amountStr);
        break;
      }
    }

    if (amount != null) {
      // Satıcıyı tahmin et
      merchant = _guessMerchantStatic(body, sender);
      
      // Tespit edilen harcamayı yerel olarak kaydet
      await _saveDetectedExpenseStatic(amount, merchant, sender);
      
      print("SMS (Arka Plan) Harcaması Tespit Edildi: $amount TL - $merchant");
    }
  }

  static String _guessMerchantStatic(String body, String sender) {
    if (body.contains('Trendyol') || sender.contains('TRENDYOL')) return 'Trendyol';
    if (body.contains('Hepsiburada') || sender.contains('HEPSIBUR')) return 'Hepsiburada';
    if (body.contains('Amazon') || sender.contains('AMAZON')) return 'Amazon';
    
    // Banka mesajlarında genellikle "işyerinden" öncesi satıcıdır
    final merchantMatch = RegExp(r'([A-Z\s]+)\sişyerinden', caseSensitive: false).firstMatch(body);
    if (merchantMatch != null) {
      return merchantMatch.group(1)!.trim();
    }

    return sender; // En kötü ihtimalle gönderen adı
  }

  static Future<void> _saveDetectedExpenseStatic(double amount, String merchant, String sender) async {
    try {
      // Not: Android background isolate'da SharedPreferences bazen initialize gerektirebilir.
      // Ancak genellikle doğrudan çağrılması çalışır.
      final prefs = await SharedPreferences.getInstance();
      
      // Önce mevcut listeyi al (varsa) - Dikkat: reload() gerekebilir
      await prefs.reload();
      final List<String> pendingList = prefs.getStringList('pending_sms_expenses') ?? [];
      
      final expense = {
        'id': const Uuid().v4(),
        'amount': amount,
        'merchant': merchant,
        'date': DateTime.now().toIso8601String(),
        'sender': sender,
      };
      
      pendingList.add(jsonEncode(expense));
      await prefs.setStringList('pending_sms_expenses', pendingList);
    } catch (e) {
      print("Arka planda SMS kaydetme hatası: $e");
    }
  }

  // Instance metodları artık statik metodları çağırıyor
  void _processMessage(SmsMessage message) {
    processMessageStatic(message);
  }

  // Diğer instance metodları (init vs.) aynı kalabilir...
  // Ancak _guessMerchant ve _saveDetectedExpense artık kullanılmıyor, silinebilir veya statik olanları çağırabilir.
  
  // Instance metodları (geriye dönük uyumluluk veya clean-up için tutulabilir, ancak statik kullanmak daha iyi)
  // Clean-up için aşağıda sadece instance metodlarını siliyorum ve yukarıya taşıyorum.

  /// Bekleyen harcamaları getir
  Future<List<Map<String, dynamic>>> getPendingExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    // Verilerin güncel olduğundan emin ol
    await prefs.reload();
    final List<String> pendingList = prefs.getStringList('pending_sms_expenses') ?? [];
    return pendingList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// Harcamayı temizle (eklendikten veya reddedildikten sonra)
  Future<void> removePendingExpense(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final List<String> pendingList = prefs.getStringList('pending_sms_expenses') ?? [];
    
    pendingList.removeWhere((e) {
      final data = jsonDecode(e);
      return data['id'] == id;
    });
    
    await prefs.setStringList('pending_sms_expenses', pendingList);
  }
}

/// Arka plan mesaj işleyici (Statik veya Top-level olmalı)
@pragma('vm:entry-point')
void _backgrounMessageHandler(SmsMessage message) async {
  print("Background SMS received: ${message.body}");
  // Flutter binding'i başlat (background isolate için gerekli olabilir)
  // Ancak telephony paketi bunu genellikle halleder. Yine de emin olmak için:
  // WidgetsFlutterBinding.ensureInitialized(); // Bazen hata verebilir, gerekirse eklenir.

  // Statik işleme metodunu çağır
  await SmsService.processMessageStatic(message);
}
