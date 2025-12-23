// lib/services/usage_guard.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'network_time_service.dart';

/// Hangi özelliği sınırlıyoruz?
enum UsageFeature {
  ocrScan, // Fiş okuma
  aiChat,  // AI Sohbet
  aiCoach, // FişMatik Koç (Analiz)
}

class UsageLimitConfig {
  /// Günlük ücretsiz fiş okuma hakkı
  static const int dailyFreeScans = 1;
  
  /// Günlük ücretsiz AI sohbet hakkı
  static const int dailyFreeChat = 10;
  
  /// Günlük ücretsiz AI Koç hakkı (Sadece Pro için anlamlı olacak)
  static const int dailyFreeCoach = 1;

  /// Limit aşılınca geçici blok süresi (dakika)
  static const int blockMinutesOnLimit = 120; // 2 saat

  /// Aynı kullanıcı için istekler arası minimum süre (ms)
  static const int minGapMs = 800;
}

class UsageGuardResult {
  final bool isAllowed;
  final String? message;

  const UsageGuardResult({
    required this.isAllowed,
    this.message,
  });
}


class UsageGuard {
  static final supa.SupabaseClient _supabase =
      supa.Supabase.instance.client;

  static const String _table = 'usage_limits';

  /// Limit ve Hedef Kullanıcı bilgisini hesaplayan yardımcı metod
  static Future<_UsageContext> _getUsageContext(UsageFeature feature, String userId) async {
    int dailyLimit = 0;
    String targetUserId = userId;

    // Varsayılan limitler (Tier verisi alınamazsa bunlar geçerli olur)
    if (feature == UsageFeature.ocrScan) {
      dailyLimit = UsageLimitConfig.dailyFreeScans;
    } else if (feature == UsageFeature.aiChat) {
      dailyLimit = UsageLimitConfig.dailyFreeChat;
    } else if (feature == UsageFeature.aiCoach) {
      dailyLimit = 0;
    }

    try {
      final tierData = await _supabase
          .from('user_roles')
          .select('tier_id')
          .eq('user_id', userId)
          .maybeSingle() as Map<String, dynamic>?;
      
      if (tierData != null) {
        final tierId = tierData['tier_id'] as String? ?? 'standart';
        
        // Aile planı kontrolü: Eğer aile üyesi ise, kotayı aile yöneticisinden düş
        if (tierId == 'limitless_family') {
          try {
            // Kullanıcının ailesini bul
            final memberData = await _supabase
                .from('household_members')
                .select('household_id')
                .eq('user_id', userId)
                .maybeSingle();
            
            if (memberData != null) {
              final householdId = memberData['household_id'];
              // Ailenin yöneticisini bul
              final householdData = await _supabase
                  .from('households')
                  .select('owner_id')
                  .eq('id', householdId)
                  .maybeSingle();
              
              if (householdData != null) {
                targetUserId = householdData['owner_id'] as String;
                if (kDebugMode) {
                  debugPrint('👨‍👩‍👧‍👦 UsageGuard: Aile planı aktif. Hedef ID: $targetUserId (Yönetici)');
                }
              }
            }
          } catch (e) {
            debugPrint('UsageGuard: Aile bilgisi alınamadı: $e');
          }
        }

        // Tier'a göre günlük limit belirle
        if (feature == UsageFeature.ocrScan) {
          switch (tierId) {
            case 'standart': dailyLimit = 1; break;
            case 'premium': dailyLimit = 10; break;
            case 'limitless': dailyLimit = 25; break;
            case 'limitless_family': dailyLimit = 35; break;
            default: dailyLimit = 1;
          }
        } else if (feature == UsageFeature.aiChat) {
           // AI Chat limitleri
           switch (tierId) {
            case 'standart': dailyLimit = 0; break;
            case 'premium': dailyLimit = 0; break;
            case 'limitless': dailyLimit = 10; break; 
            case 'limitless_family': dailyLimit = 20; break;
            default: dailyLimit = 0;
          }
        } else if (feature == UsageFeature.aiCoach) {
           // AI Koç limitleri (Sadece Limitless)
           switch (tierId) {
            case 'standart': dailyLimit = 0; break;
            case 'premium': dailyLimit = 0; break;
            case 'limitless': dailyLimit = UsageLimitConfig.dailyFreeCoach; break;
            case 'limitless_family': dailyLimit = UsageLimitConfig.dailyFreeCoach * 2; break;
            default: dailyLimit = 0;
          }
        }
      }
    } catch (e) {
      debugPrint('UsageGuard: Tier bilgisi alınamadı: $e');
      // Hata durumunda varsayılan limitler (yukarıda set edildi) kullanılır
    }

    return _UsageContext(dailyLimit, targetUserId);
  }

  /// Ana metod: isteği yapmadan *önce* çağır.
  static Future<UsageGuardResult> checkAndConsume(
    UsageFeature feature, {
    int cost = 1,
    bool checkOnly = false, // Yeni parametre: Sadece kontrol et, düşme
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const UsageGuardResult(
        isAllowed: false,
        message:
            'Devam etmek için giriş yapman gerekiyor. Misafir modunda fiş okuma kapalı.',
      );
    }

    final userId = user.id;
    // GÜVENLİK: Cihaz saati yerine NTP saati kullan
    // Türkiye saati (UTC+3) ile 00:00'da sıfırlanması için 3 saat ekliyoruz
    final now = (await NetworkTimeService.now).toUtc().add(const Duration(hours: 3));
    final today = DateTime.utc(now.year, now.month, now.day);

    // Limit ve hedef kullanıcıyı belirle
    final context = await _getUsageContext(feature, userId);
    final dailyLimit = context.dailyLimit;
    final targetUserId = context.targetUserId;

    Map<String, dynamic>? row;
    try {
      row = await _supabase
          .from(_table)
          .select()
          .eq('user_id', targetUserId) // Hedef ID kullanılıyor
          .eq('feature', feature.name)
          .maybeSingle() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('UsageGuard: Supabase select hatası: $e');
      return const UsageGuardResult(isAllowed: true);
    }

    int currentCount = 0;
    DateTime? storedDay;
    DateTime? blockedUntil;
    DateTime? lastRequestAt;

    if (row != null) {
      final dayStr = row['day'] as String?;
      final blockedStr = row['blocked_until'] as String?;
      final lastReqStr = row['last_request_at'] as String?;

      if (dayStr != null) {
        storedDay = DateTime.tryParse(dayStr);
      }
      if (blockedStr != null) {
        blockedUntil = DateTime.tryParse(blockedStr);
      }
      if (lastReqStr != null) {
        lastRequestAt = DateTime.tryParse(lastReqStr);
      }

      currentCount = (row['count'] as int?) ?? 0;
    }

    // Gün değişmişse sayaç sıfırla
    if (storedDay == null ||
        storedDay.year != today.year ||
        storedDay.month != today.month ||
        storedDay.day != today.day) {
      currentCount = 0;
      storedDay = today;
      blockedUntil = null;
    }

    // Geçici blok kontrolü
    if (blockedUntil != null && blockedUntil.isAfter(now)) {
      // Eğer kullanıcı şu anki limitinin altındaysa (örn: limit artırıldıysa),
      // eski bloğu yoksay ve devam et.
      if (currentCount >= dailyLimit) {
        final diffMin = blockedUntil.difference(now).inMinutes;
        String actionName = feature == UsageFeature.ocrScan ? 'fiş okuma' : 'işlem';
        return UsageGuardResult(
          isAllowed: false,
          message:
              'Çok fazla $actionName denemesi yaptın. Lütfen yaklaşık $diffMin dakika sonra tekrar dene.',
        );
      }
    }

    // Basit "spam tık" freni
    if (lastRequestAt != null) {
      final diffMs = now.difference(lastRequestAt).inMilliseconds;
      if (diffMs < UsageLimitConfig.minGapMs) {
        return const UsageGuardResult(
          isAllowed: false,
          message: 'Çok hızlı deniyorsun, lütfen bir saniye bekle.',
        );
      }
    }

    final nextCount = currentCount + cost;

    DateTime? newBlockedUntil;
    String? resultMessage;

    // Günlük limite göre kontrol et
    if (nextCount > dailyLimit) {
      newBlockedUntil =
          now.add(Duration(minutes: UsageLimitConfig.blockMinutesOnLimit));
      
      String actionName = feature == UsageFeature.ocrScan ? 'fiş okuma' : 'sohbet';
      resultMessage =
          'Günlük $actionName limitini ($dailyLimit) aştın. Yarın tekrar deneyebilirsin veya üyeliğinizi yükseltebilirsiniz.';
    }

    if (newBlockedUntil != null) {
      return UsageGuardResult(isAllowed: false, message: resultMessage);
    }

    // Eğer sadece kontrol ise, burada bitir (DB güncelleme yapma)
    if (checkOnly) {
      return const UsageGuardResult(isAllowed: true);
    }

    try {
      await _supabase.from(_table).upsert({
        'user_id': targetUserId,
        'feature': feature.name,
        'day': today.toIso8601String().substring(0, 10), // sadece tarih
        'count': nextCount,
        'blocked_until': newBlockedUntil?.toIso8601String(),
        'last_request_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }, onConflict: 'user_id,feature');
    } catch (e) {
      debugPrint('UsageGuard: Supabase upsert hatası: $e');
    }

    if (kDebugMode) {
      debugPrint(
        '✅ UsageGuard: ${feature.name} -> count=$nextCount/$dailyLimit / day=${today.toIso8601String()}',
      );
    }

    return const UsageGuardResult(isAllowed: true);
  }

  /// Sadece mevcut durumu sorgular, hak düşmez.
  static Future<Map<String, int>> getDailyUsage(UsageFeature feature) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return {'current': 0, 'limit': 0};
    }

    final userId = user.id;
    // GÜVENLİK: Cihaz saati yerine NTP saati kullan
    // Türkiye saati (UTC+3) ile 00:00'da sıfırlanması için 3 saat ekliyoruz
    final now = (await NetworkTimeService.now).toUtc().add(const Duration(hours: 3));
    final today = DateTime.utc(now.year, now.month, now.day);

    // Limit ve hedef kullanıcıyı belirle
    final context = await _getUsageContext(feature, userId);
    final dailyLimit = context.dailyLimit;
    final targetUserId = context.targetUserId;

    // 2) Mevcut kullanımı bul
    int currentCount = 0;
    try {
      final row = await _supabase
          .from(_table)
          .select()
          .eq('user_id', targetUserId) // Hedef ID kullanılıyor
          .eq('feature', feature.name)
          .maybeSingle() as Map<String, dynamic>?;

      if (row != null) {
        final dayStr = row['day'] as String?;
        DateTime? storedDay;
        if (dayStr != null) storedDay = DateTime.tryParse(dayStr);
        
        // Gün aynıysa sayacı al, değilse 0
        if (storedDay != null &&
            storedDay.year == today.year &&
            storedDay.month == today.month &&
            storedDay.day == today.day) {
          currentCount = (row['count'] as int?) ?? 0;
        }
      }
    } catch (e) {
      debugPrint('UsageGuard: Sayaç okuma hatası: $e');
    }

    return {'current': currentCount, 'limit': dailyLimit};
  }

  /// Kullanılan hakkı iade eder (Smart Retry için)
  static Future<void> refund(UsageFeature feature) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final userId = user.id;
    // GÜVENLİK: Cihaz saati yerine NTP saati kullan
    // Türkiye saati (UTC+3) ile 00:00'da sıfırlanması için 3 saat ekliyoruz
    final now = (await NetworkTimeService.now).toUtc().add(const Duration(hours: 3));
    final today = DateTime.utc(now.year, now.month, now.day);

    try {
      // Hedef kullanıcıyı belirle
      final context = await _getUsageContext(feature, userId);
      final targetUserId = context.targetUserId;

      // Mevcut sayacı al
      final row = await _supabase
          .from(_table)
          .select()
          .eq('user_id', targetUserId) // Hedef ID
          .eq('feature', feature.name)
          .maybeSingle() as Map<String, dynamic>?;

      if (row != null) {
        final dayStr = row['day'] as String?;
        DateTime? storedDay;
        if (dayStr != null) storedDay = DateTime.tryParse(dayStr);

        // Eğer gün aynıysa ve sayaç > 0 ise azalt
        if (storedDay != null &&
            storedDay.year == today.year &&
            storedDay.month == today.month &&
            storedDay.day == today.day) {
          
          final currentCount = (row['count'] as int?) ?? 0;
          if (currentCount > 0) {
            await _supabase.from(_table).update({
              'count': currentCount - 1,
              'updated_at': now.toIso8601String(),
            }).eq('id', row['id']); // ID ile güncellemek daha güvenli
            
            if (kDebugMode) {
              debugPrint('↩️ UsageGuard: Refunded 1 credit for ${feature.name}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('UsageGuard: Refund hatası: $e');
    }
  }
}

class _UsageContext {
  final int dailyLimit;
  final String targetUserId;
  _UsageContext(this.dailyLimit, this.targetUserId);
}
