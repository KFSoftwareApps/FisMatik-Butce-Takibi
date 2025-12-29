-- 1. Tabloyu oluştur (Eğer yoksa)
CREATE TABLE IF NOT EXISTS household_invitations (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  household_id uuid REFERENCES households(id) ON DELETE CASCADE,
  email text NOT NULL,
  status text DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

-- 2. Tablo üzerindeki RLS'i aktif et
ALTER TABLE household_invitations ENABLE ROW LEVEL SECURITY;

-- 3. Mevcut politikaları temizle (Çakışma olmaması için)
DROP POLICY IF EXISTS "Aile üyeleri gönderilen davetleri görebilir" ON household_invitations;
DROP POLICY IF EXISTS "Aile yöneticisi daveti iptal edebilir" ON household_invitations;

-- 4. OKUMA Politikası: Bir kullanıcı, kendi ailesine ait (household_id) davetleri görebilmeli
CREATE POLICY "Aile üyeleri gönderilen davetleri görebilir"
ON household_invitations
FOR SELECT
USING (
  exists (
    select 1 from household_members
    where household_members.household_id = household_invitations.household_id
    and household_members.user_id = auth.uid()
  )
);

-- 5. SİLME Politikası: Bir kullanıcı (genelde owner veya admin), kendi ailesine ait daveti silebilir
CREATE POLICY "Aile yöneticisi daveti iptal edebilir"
ON household_invitations
FOR DELETE
USING (
  exists (
    select 1 from household_members
    where household_members.household_id = household_invitations.household_id
    and household_members.user_id = auth.uid()
    and household_members.role in ('owner', 'admin')
  )
);
