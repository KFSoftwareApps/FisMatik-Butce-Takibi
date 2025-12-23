import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend kaynaklı hatalar için özel exception
class AiBackendException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  final bool isRetryable;

  AiBackendException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.isRetryable = false,
  });

  @override
  String toString() =>
      'AiBackendException(code: $code, statusCode: $statusCode, message: $message)';
}

/// AI ile fiş okuma + finans koçu tavsiyesi servisi
class AiService {
  
  // ---------------------------------------------------------------------------
  //  FİŞ PARSE (SUPABASE EDGE FUNCTION)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>?> parseReceiptText(String rawText) async {
    print('--- OCR OKUNAN METİN ---');
    print(rawText);

    final cleaned = rawText.trim();
    if (cleaned.length < 10) {
      print('HATA: OCR yeterli metin okuyamadı.');
      return null;
    }

    try {
      print("Invoking function: parse-receipt");
      
      final response = await Supabase.instance.client.functions.invoke(
        'parse-receipt',
        body: {'rawText': cleaned},
      );

      print('--- FUNCTION STATUS (parse-receipt): ${response.status} ---');
      
      final data = response.data;
      
      // Edge Function hata dönerse (ok: false)
      if (data is Map && data['ok'] == false) {
        final code = (data['code'] ?? 'UNKNOWN').toString();
        final msg = (data['message'] ?? 'Bilinmeyen hata').toString();
        
        print('FUNCTION HATA ($code): $msg');
        
        throw AiBackendException(
          code: code,
          message: msg,
          statusCode: response.status ?? 400,
          isRetryable: code == 'RATE_LIMIT',
        );
      }

      if (data is Map && data['ok'] == true && data['data'] is Map) {
         return Map<String, dynamic>.from(data['data']);
      }

      throw AiBackendException(
        code: 'INVALID_RESPONSE',
        message: 'Sunucudan geçersiz veri alındı.',
        statusCode: response.status ?? 500,
      );

    } on FunctionException catch (e) {
      print('FUNCTION EXCEPTION: ${e.details} (status: ${e.status})');
      throw AiBackendException(
        code: 'FUNCTION_ERROR',
        message: 'AI servisi çalıştırılamadı: ${e.details}',
        statusCode: e.status ?? 500,
        isRetryable: true,
      );
    } catch (e) {
      if (e is AiBackendException) rethrow;
      
      print('GENEL HATA (parse-receipt): $e');
      throw AiBackendException(
        code: 'NETWORK_ERROR',
        message: 'Bağlantı hatası. İnternetinizi kontrol edin.',
        statusCode: 0,
        isRetryable: true,
      );
    }
  }

  /// WEB İÇİN: Fotoğrafı doğrudan Gemini Vision'a gönderir
  Future<Map<String, dynamic>?> parseReceiptWithImage(String base64Image) async {
    try {
      print("Invoking function: parse-receipt with IMAGE");
      
      final response = await Supabase.instance.client.functions.invoke(
        'parse-receipt',
        body: {'image': base64Image},
      );

      print('--- FUNCTION STATUS (parse-receipt-image): ${response.status} ---');
      
      final data = response.data;
      
      if (data is Map && data['ok'] == false) {
        final code = (data['code'] ?? 'UNKNOWN').toString();
        final msg = (data['message'] ?? 'Bilinmeyen hata').toString();
        
        throw AiBackendException(
          code: code,
          message: msg,
          statusCode: response.status ?? 400,
          isRetryable: code == 'RATE_LIMIT',
        );
      }

      if (data is Map && data['ok'] == true && data['data'] is Map) {
         return Map<String, dynamic>.from(data['data']);
      }

      throw AiBackendException(
        code: 'INVALID_RESPONSE',
        message: 'Sunucudan geçersiz veri alındı.',
        statusCode: response.status ?? 500,
      );

    } on FunctionException catch (e) {
      print('FUNCTION EXCEPTION: ${e.details} (status: ${e.status})');
      throw AiBackendException(
        code: 'FUNCTION_ERROR',
        message: 'AI servisi çalıştırılamadı: ${e.details}',
        statusCode: e.status ?? 500,
        isRetryable: true,
      );
    } catch (e) {
      if (e is AiBackendException) rethrow;
      
      print('GENEL HATA (parse-receipt-image): $e');
      throw AiBackendException(
        code: 'NETWORK_ERROR',
        message: 'Bağlantı hatası. İnternetinizi kontrol edin.',
        statusCode: 0,
        isRetryable: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  //  FİNANS KOÇU TAVSİYESİ (SUPABASE EDGE FUNCTION)
  // ---------------------------------------------------------------------------
  Future<String?> getFinancialAdvice(
    double totalSpent,
    Map<String, double> categoryData,
  ) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'financial-advice',
        body: {
          'totalSpent': totalSpent,
          'categories': categoryData,
        },
      );

      final data = response.data;
      if (data is Map && data['ok'] == true) {
        return data['advice'] as String?;
      }
      return null;
    } catch (e) {
      print('GENEL HATA (financial-advice): $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  //  AI CHAT (SUPABASE EDGE FUNCTION)
  // ---------------------------------------------------------------------------
  Future<String?> chat(String message, {String? context}) async {
    try {
      String fullMessage = message;
      if (context != null && context.isNotEmpty) {
        fullMessage = """
[SİSTEM BAĞLAMI]
$context
[BAĞLAM SONU]

Kullanıcı Sorusu: $message
""";
      }

      final response = await Supabase.instance.client.functions.invoke(
        'chat',
        body: {'message': fullMessage},
      );

      final data = response.data;
      if (data is Map && data['ok'] == true) {
        return data['reply'] as String?;
      }
      return null;
    } catch (e) {
      print("Chat Exception: $e");
      return null;
    }
  }
}
