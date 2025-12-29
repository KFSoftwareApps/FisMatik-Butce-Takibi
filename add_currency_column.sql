-- user_profiles tablosuna para birimi sütununu ekler
-- Bu kodu Supabase SQL Editor'de çalıştırın.

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'TRY';

-- Mevcut satırlar için varsayılan değeri 'TRY' olarak ayarla (opsiyonel ama önerilir)
UPDATE user_profiles SET currency = 'TRY' WHERE currency IS NULL;
