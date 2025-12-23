// backend/services/supabase.js

const { createClient } = require('@supabase/supabase-js');
const { TIER_MONTHLY_LIMITS } = require('../config/limits');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.warn(
        '[supabaseService] SUPABASE_URL veya SUPABASE_SERVICE_ROLE_KEY tanımlı değil.'
    );
}

// Service Role Key ile admin yetkili client
const supabase = createClient(supabaseUrl, supabaseServiceKey);

/**
 * Kullanıcının tierId bilgisini döner.
 */
async function getUserTier(uid) {
    const { data, error } = await supabase
        .from('user_roles')
        .select('tier_id')
        .eq('user_id', uid)
        .maybeSingle();

    if (error) {
        console.error('getUserTier hatası:', error);
        return 'standart';
    }

    return data?.tier_id || 'standart';
}

/**
 * Bu ay kullanıcıya ait OCR fiş sayısını döner (manuel değil).
 */
async function getMonthlyReceiptCount(uid) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startStr = startOfMonth.toISOString();

    // Supabase count sorgusu
    const { count, error } = await supabase
        .from('receipts')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', uid)
        .eq('is_manual', false)
        .gte('date', startStr);

    if (error) {
        console.error('getMonthlyReceiptCount hatası:', error);
        return 0;
    }

    return count || 0;
}

/**
 * Kullanıcının bu ayki limitini döner (tier'e göre).
 */
async function getMonthlyLimitForUser(uid) {
    const tierId = await getUserTier(uid);
    const limit =
        TIER_MONTHLY_LIMITS[tierId] ?? TIER_MONTHLY_LIMITS.standart ?? 100;
    return { tierId, limit };
}

module.exports = {
    getUserTier,
    getMonthlyReceiptCount,
    getMonthlyLimitForUser,
};
