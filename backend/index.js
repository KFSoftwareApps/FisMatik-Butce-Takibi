// backend/index.js

require('dotenv').config();

const express = require('express');
const cors = require('cors');

// Firebase Admin Init İPTAL EDİLDİ (Supabase'e geçildi)

const rateLimit = require('./middlewares/rateLimit');
const authCheck = require('./middlewares/authCheck');
const { checkAbuse } = require('./utils/abuseGuard');
const {
  getMonthlyReceiptCount,
  getMonthlyLimitForUser,
} = require('./services/supabase'); // Firestore -> Supabase
const { TIER_MONTHLY_LIMITS } = require('./config/limits');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '2mb' }));
// app.use(rateLimit); // Global limit yerine endpoint bazlı kullanıyoruz

// ---------------------------------------------------------------------------
// Healthcheck
// ---------------------------------------------------------------------------
app.get('/health', (req, res) => {
  res.json({ ok: true, message: 'Fismatik backend çalışıyor.' });
});

// Ortak: Gemini URL + key helper
function getGeminiUrl() {
  const apiKey = process.env.GOOGLE_API_KEY;
  if (!apiKey) {
    throw new Error('GOOGLE_API_KEY tanımlı değil (.env)!');
  }
  return (
    'https://generativelanguage.googleapis.com/v1beta/models/' +
    'gemini-2.0-flash:generateContent?key=' +
    apiKey
  );
}

// ---------------------------------------------------------------------------
// 1) Fiş Parse Endpoint'i
// ---------------------------------------------------------------------------
/**
 * POST /api/parse-receipt
 * Body: { rawText: string }
 * Header: Authorization: Bearer <firebase_id_token>
 */
app.post('/api/parse-receipt', authCheck, rateLimit, async (req, res) => {
  const user = req.user; // { uid, tierId, supabaseUser }
  const { rawText } = req.body || {};

  if (!rawText || typeof rawText !== 'string' || rawText.trim().length < 10) {
    return res.status(400).json({
      ok: false,
      code: 'INVALID_INPUT',
      message: 'Geçerli bir fiş metni göndermelisin.',
    });
  }

  try {
    // 0) Block Check (Veritabanından güncel durumu al)
    // authCheck içinde user.supabaseUser var ama is_blocked rol tablosunda olabilir.
    // Hızlıca user_roles tablosuna bakalım.
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

    const { data: roleData } = await supabase
      .from('user_roles')
      .select('is_blocked')
      .eq('user_id', user.uid)
      .single();

    if (roleData?.is_blocked) {
      return res.status(403).json({
        ok: false,
        code: 'ACCOUNT_BLOCKED',
        message: 'Hesabınız güvenlik nedeniyle bloke edilmiştir. Yönetici ile iletişime geçin.',
      });
    }

    // 1) Abuse guard: aynı içeriği spam'leme
    const abuseCheck = await checkAbuse(user.uid, rawText);
    if (!abuseCheck.allowed) {
      return res.status(403).json({
        ok: false,
        code: 'ABUSE_DETECTED',
        message: abuseCheck.reason,
      });
    }

    // 2) Aylık limit kontrolü
    const [monthlyCount, limitInfo] = await Promise.all([
      getMonthlyReceiptCount(user.uid),
      getMonthlyLimitForUser(user.uid),
    ]);

    const { tierId, limit } = limitInfo;

    if (limit && monthlyCount >= limit) {
      return res.status(429).json({
        ok: false,
        code: 'SCAN_LIMIT_REACHED',
        message: `Aylık fiş sınırına ulaştın. (${tierId} için limit: ${limit})`,
        tierId,
        usedThisMonth: monthlyCount,
        maxPerMonth: limit,
      });
    }

    // 3) Gemini çağrısı
    const url = getGeminiUrl();

    const prompt = `
Sen uzman bir finans asistanısın. Aşağıdaki fiş metnini analiz et.
SADECE saf JSON formatında yanıt ver. Markdown (\`\`\`json) kullanma.

ÖNEMLİ GÖREV 1: Fişin genel "category" alanını şu listeden en uygun olanıyla doldur:
["Market", "Yeme-İçme", "Akaryakıt", "Giyim", "Teknoloji", "Sağlık", "Diğer"]

ÖNEMLİ GÖREV 2: "items" listesindeki HER BİR ÜRÜN için de bir "category" belirle.
Ürün kategorileri şunlar olabilir:
["Gıda", "Et & Tavuk", "İçecek", "Baharat & Çeşni", "Meyve & Sebze", "Atıştırmalık", 
 "Temizlik & Bakım", "Sigara", "Alkol", "Akaryakıt", "Kişisel Bakım", "Ev Eşyası", 
 "Giyim", "Elektronik", "Hizmet", "Diğer"]

ÖNEMLİ KURALLAR:
1. "İndirim", "KDV", "Vergi", "İskonto" gibi kelimeler ASLA kategori olarak kullanılmamalı
2. "İndirim" kelimesi içeren satırlar → discountAmount alanına eklenmelidir, items listesine eklenmemelidir
3. Her ürün mutlaka bir kategori almalıdır (varsayılan: "Diğer")
4. Marka ve ürün isimlerine göre kategorileme yap:
   - "Banvit", "Piliç", "Tavuk", "Et", "Sucuk", "Salam", "Sosis" → "Et & Tavuk"
   - "Kahve Dünyası", "Red Bull", "Coca Cola", "Pepsi", "Fanta", "Sprite", "Su", "Çay", "Kahve", "Ayran", "Meyve Suyu" → "İçecek"
   - "Sumak", "Baharat", "Kimyon", "Karabiber", "Tuz", "Şeker", "Sos", "Ketçap", "Mayonez" → "Baharat & Çeşni"
   - "Cips", "Çikolata", "Bisküvi", "Gofret", "Kuruyemiş" → "Atıştırmalık"
   - "Domates", "Salatalık", "Elma", "Muz", "Portakal", "Meyve", "Sebze" → "Meyve & Sebze"
   - "Ekmek", "Süt", "Yumurta", "Peynir", "Yoğurt", "Tereyağ", "Zeytin", "Reçel", "Bal" → "Gıda"

Ayrıca fişteki "KDV", "Vergi" veya "%" oranlarına bakarak toplam vergi tutarını (taxAmount) ve varsa indirim tutarını (discountAmount) çıkar.

İstenen JSON Formatı:
{
  "merchantName": "Mağaza Adı (Bulamazsan 'Bilinmiyor' yaz)",
  "date": "YYYY-MM-DD (Bulamazsan bugünün tarihi)",
  "totalAmount": 0.0,
  "taxAmount": 0.0,
  "discountAmount": 0.0,
  "category": "Genel Fiş Kategorisi",
  "items": [
    {"name": "Ürün Adı", "price": 0.0, "category": "Ürün Kategorisi"}
  ]
}

Metin:
${rawText}
`;

    const body = {
      contents: [
        {
          parts: [{ text: prompt }],
        },
      ],
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    const json = await response.json();

    if (!response.ok) {
      console.error('Gemini hata:', json);
      return res.status(response.status).json({
        ok: false,
        code: 'AI_ERROR',
        message: 'AI servisi hata döndürdü.',
        details: json,
      });
    }

    // --- TOKEN TRACKING ---
    // Gemini response içinde usageMetadata varsa kullanalım, yoksa tahmini.
    // Gemini API genellikle usageMetadata döner.
    let totalTokens = 0;
    if (json.usageMetadata) {
      totalTokens = json.usageMetadata.totalTokenCount || 0;
    } else {
      // Fallback: karakter sayısı / 4
      totalTokens = Math.ceil(prompt.length / 4);
    }

    // Token kullanımını kaydet (Async, cevabı beklemeye gerek yok)
    supabase.rpc('increment_token_usage', {
      p_user_id: user.uid,
      p_amount: totalTokens
    }).then(({ error }) => {
      if (error) {
        // RPC yoksa manuel update deneyelim (daha yavaş ama çalışır)
        // Veya şimdilik sadece loglayalım, çünkü RPC oluşturmadık henüz.
        // Planımızda tablo oluşturmak vardı.
        console.log(`[TokenTrack] User ${user.uid} used ${totalTokens} tokens.`);
        // Basit insert/upsert
        supabase.from('user_token_usage').upsert({
          user_id: user.uid,
          total_tokens: totalTokens, // Bu sadece son kullanımı yazar, artırmaz!
          last_updated: new Date().toISOString()
        }).then(() => { });
        // NOT: Doğrusu RPC ile artırmak veya önce okuyup sonra yazmak.
        // Şimdilik basitçe logluyoruz, SQL kısmında RPC eklemeliyiz.
      }
    });


    let text =
      json?.candidates?.[0]?.content?.parts?.[0]?.text?.toString() ?? '';

    if (!text) {
      return res.status(500).json({
        ok: false,
        code: 'AI_EMPTY',
        message: 'AI geçerli bir cevap üretmedi.',
      });
    }

    // Markdown kılıflarını temizle
    text = text.replace(/```json/gi, '').replace(/```/g, '').trim();

    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch (e) {
      console.error('AI cevabı JSON parse edilemedi:', text);
      return res.status(500).json({
        ok: false,
        code: 'AI_PARSE_ERROR',
        message: 'AI cevabı JSON formatında değil.',
      });
    }

    const remaining =
      limit && typeof limit === 'number'
        ? Math.max(limit - (monthlyCount + 1), 0)
        : null;

    return res.json({
      ok: true,
      data: parsed,
      meta: {
        tierId,
        usedThisMonth: monthlyCount + 1,
        maxPerMonth: limit ?? null,
        remainingMonthlyScans: remaining,
        tierLimits: TIER_MONTHLY_LIMITS,
      },
    });
  } catch (err) {
    console.error('parse-receipt genel hata:', err);
    return res.status(500).json({
      ok: false,
      code: 'INTERNAL_ERROR',
      message: 'Sunucu beklenmeyen bir hata verdi.',
    });
  }
});

// ---------------------------------------------------------------------------
// 2) Finans Koçu Tavsiye Endpoint'i
// ---------------------------------------------------------------------------
/**
 * POST /api/financial-advice
 * Body: { totalSpent: number, categories: { [name]: number } }
 * Header: Authorization: Bearer <firebase_id_token>
 */
app.post('/api/financial-advice', authCheck, async (req, res) => {
  const { totalSpent, categories } = req.body || {};

  if (typeof totalSpent !== 'number' || totalSpent < 0) {
    return res.status(400).json({
      ok: false,
      code: 'INVALID_INPUT',
      message: 'totalSpent sayısal ve 0\'dan büyük olmalı.',
    });
  }

  if (categories == null || typeof categories !== 'object') {
    return res.status(400).json({
      ok: false,
      code: 'INVALID_INPUT',
      message: 'categories nesnesi göndermen gerekiyor.',
    });
  }

  try {
    const url = getGeminiUrl();

    let summary = `Toplam Harcama: ${totalSpent} TL.\nKategoriler:\n`;
    for (const [name, value] of Object.entries(categories)) {
      summary += `- ${name}: ${value} TL\n`;
    }

    const prompt = `
Sen esprili, samimi ve zeki bir finans koçusun. Aşağıdaki harcama özetine bakarak kullanıcıya
kısa, yararlı ve hafif esprili bir tavsiye veya yorum yap.

Kurallar:
1. Çok resmi olma, samimi ol (emojiler kullan, ama abartma).
2. En çok harcama yapılan kategoriyi fark et ve ona odaklan.
3. 3-5 cümleyi geçme.
4. Sadece düz metin ver, JSON / markdown verme.
5. Türkçe cevap ver.

Kullanıcı Verileri:
${summary}
`;

    const body = {
      contents: [
        {
          parts: [{ text: prompt }],
        },
      ],
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    const json = await response.json();

    if (!response.ok) {
      console.error('Gemini hata (financial-advice):', json);
      return res.status(response.status).json({
        ok: false,
        code: 'AI_ERROR',
        message: 'AI servisi hata döndürdü.',
        details: json,
      });
    }

    const advice =
      json?.candidates?.[0]?.content?.parts?.[0]?.text?.toString().trim() ??
      '';

    if (!advice) {
      return res.status(500).json({
        ok: false,
        code: 'AI_EMPTY',
        message: 'AI geçerli bir tavsiye üretmedi.',
      });
    }

    return res.json({
      ok: true,
      advice,
    });
  } catch (err) {
    console.error('financial-advice genel hata:', err);
    return res.status(500).json({
      ok: false,
      code: 'INTERNAL_ERROR',
      message: 'Sunucu beklenmeyen bir hata verdi.',
    });
  }
});

// ---------------------------------------------------------------------------
// 3) AI Chat Endpoint (Genel Sohbet)
// ---------------------------------------------------------------------------
/**
 * POST /api/chat
 * Body: { message: string }
 * Header: Authorization: Bearer <firebase_id_token>
 */
app.post('/api/chat', authCheck, async (req, res) => {
  const { message } = req.body || {};

  if (!message || typeof message !== 'string') {
    return res.status(400).json({
      ok: false,
      code: 'INVALID_INPUT',
      message: 'Geçerli bir mesaj göndermelisin.',
    });
  }

  try {
    const url = getGeminiUrl();

    const prompt = `
Sen FişMatik uygulamasının akıllı finans asistanısın. Kullanıcı sana finansal sorular soruyor.
Samimi, yardımsever ve bilgili bir dille cevap ver.
Kullanıcının sorusu: "${message}"

Cevabın sadece düz metin olsun. Markdown kullanabilirsin ama JSON döndürme.
`;

    const body = {
      contents: [
        {
          parts: [{ text: prompt }],
        },
      ],
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    const json = await response.json();

    if (!response.ok) {
      console.error('Gemini hata (chat):', json);
      return res.status(response.status).json({
        ok: false,
        code: 'AI_ERROR',
        message: 'AI servisi hata döndürdü.',
        details: json,
      });
    }

    const reply =
      json?.candidates?.[0]?.content?.parts?.[0]?.text?.toString().trim() ??
      '';

    if (!reply) {
      return res.status(500).json({
        ok: false,
        code: 'AI_EMPTY',
        message: 'AI geçerli bir cevap üretmedi.',
      });
    }

    return res.json({
      ok: true,
      reply,
    });
  } catch (err) {
    console.error('chat genel hata:', err);
    return res.status(500).json({
      ok: false,
      code: 'INTERNAL_ERROR',
      message: 'Sunucu beklenmeyen bir hata verdi.',
    });
  }
});

// ---------------------------------------------------------------------------
// Sunucu
// ---------------------------------------------------------------------------
app.listen(PORT, () => {
  console.log(`🚀 Fismatik backend ${PORT} portunda dinliyor.`);
});
