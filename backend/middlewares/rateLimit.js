// backend/middlewares/rateLimit.js

const rateLimit = require('express-rate-limit');

// 2 dakikada maksimum 3 istek
const limiter = rateLimit({
  windowMs: 2 * 60 * 1000, // 2 dakika
  max: 3, // Limit each IP to 3 requests per windowMs
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: {
    ok: false,
    code: 'RATE_LIMIT',
    message: 'Çok sık işlem yaptın. Lütfen 2 dakika bekleyip tekrar dene.',
  },
});

module.exports = limiter;
