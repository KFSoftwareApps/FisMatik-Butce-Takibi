// backend/middlewares/authCheck.js

const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.warn(
    '[authCheck] SUPABASE_URL veya SUPABASE_SERVICE_ROLE_KEY tanımlı değil. .env dosyanı kontrol et.'
  );
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

/**
 * Authorization: Bearer <access_token>
 * ile gelen Supabase oturumunu doğrular.
 *
 * Eski Firebase kodun `req.user.uid` bekliyorsa bozulmasın diye
 * Supabase user.id'yi uid alanına da koyuyorum.
 */
async function authCheck(req, res, next) {
  try {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ')
      ? authHeader.slice(7)
      : null;

    if (!token) {
      return res.status(401).json({
        ok: false,
        code: 'NO_TOKEN',
        message: 'Authorization header eksik.',
      });
    }

    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data?.user) {
      console.log('[authCheck] Supabase getUser error:', error);
      return res.status(401).json({
        ok: false,
        code: 'INVALID_TOKEN',
        message: 'Oturum geçerli değil, tekrar giriş yapman gerekiyor.',
      });
    }

    const user = data.user;

    // Firebase uyumluluğu için:
    req.user = {
      uid: user.id,
      email: user.email,
      supabaseUser: user,
    };

    req.userId = user.id;

    return next();
  } catch (err) {
    console.error('[authCheck] Genel hata:', err);
    return res.status(500).json({
      ok: false,
      code: 'AUTH_ERROR',
      message: 'Kimlik doğrulama sırasında bir sorun oluştu.',
    });
  }
}

module.exports = authCheck;
