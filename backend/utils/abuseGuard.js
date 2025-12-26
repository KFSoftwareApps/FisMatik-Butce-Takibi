const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// userId -> [{ hash, ts }]
const recentByUser = new Map();

// Aynı içerik 5 saniye içinde 4+ kez gelirse şüpheli say.
const WINDOW_MS = 5_000;
const MAX_DUPLICATES = 4; // 4. denemede blokla

/**
 * @param {string} uid
 * @param {string} rawText
 * @returns {Promise<{ allowed: boolean, reason?: string }>}
 */
async function checkAbuse(uid, rawText) {
  const now = Date.now();
  if (!uid || !rawText) {
    return { allowed: true };
  }

  // Basit hash: ilk 200 karakter + length
  const hash =
    rawText.substring(0, 200).replace(/\s+/g, ' ').trim() +
    `::len=${rawText.length}`;

  let list = recentByUser.get(uid);
  if (!list) {
    list = [];
    recentByUser.set(uid, list);
  }

  // Eski kayıtları temizle
  const filtered = list.filter((e) => now - e.ts <= WINDOW_MS);
  filtered.push({ hash, ts: now });
  recentByUser.set(uid, filtered);

  const sameCount = filtered.filter((e) => e.hash === hash).length;

  if (sameCount >= MAX_DUPLICATES) {
    // Kullanıcıyı blokla
    console.warn(`[AbuseGuard] User ${uid} blocked due to spamming.`);

    await supabase
      .from('user_roles')
      .update({ is_blocked: true })
      .eq('user_id', uid);

    return {
      allowed: false,
      reason:
        'Aynı fişi çok kısa sürede defalarca tarattığın için hesabın geçici olarak bloke edildi.',
    };
  }

  return { allowed: true };
}

module.exports = {
  checkAbuse,
};
