-- ==========================================
-- 1. TABLO TANIMLARI (Eksikse Oluştur)
-- ==========================================

-- Aileler Tablosu
CREATE TABLE IF NOT EXISTS households (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    owner_id uuid REFERENCES auth.users(id),
    created_at timestamptz DEFAULT now(),
    address text
);

-- Eski tablolarda 'address' kolonu yoksa ekle (Migration)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='households' AND column_name='address') THEN
        ALTER TABLE households ADD COLUMN address text;
    END IF;
END $$;

-- Aile Üyeleri Tablosu
CREATE TABLE IF NOT EXISTS household_members (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id uuid REFERENCES households(id) ON DELETE CASCADE,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    role text DEFAULT 'member', -- owner, member, child
    status text DEFAULT 'active',
    joined_at timestamptz DEFAULT now(),
    UNIQUE(user_id) -- Bir kişi tek bir ailede olabilir (basit model)
);

-- Migrasyon: Eğer id kolonu yoksa ekle (PK çakışmasını önlemek için PK'sız ekle)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='household_members' AND column_name='id') THEN
        ALTER TABLE household_members ADD COLUMN id uuid DEFAULT gen_random_uuid();
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS user_roles (
    user_id uuid REFERENCES auth.users(id) PRIMARY KEY,
    tier_id text DEFAULT 'standart',
    email text,
    expires_at timestamptz,
    update_date timestamptz DEFAULT now()
);

-- Migration: Ensure email column exists and is populated
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_roles' AND column_name='email') THEN
        ALTER TABLE user_roles ADD COLUMN email text;
    END IF;

    -- Populate missing emails from auth.users
    UPDATE user_roles ur
    SET email = u.email
    FROM auth.users u
    WHERE ur.user_id = u.id AND ur.email IS NULL;
END $$;
-- Migrasyon: Veri Paylaşımı için household_id ekle
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='receipts' AND column_name='household_id') THEN
        ALTER TABLE receipts ADD COLUMN household_id uuid REFERENCES households(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_credits' AND column_name='household_id') THEN
        ALTER TABLE user_credits ADD COLUMN household_id uuid REFERENCES households(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscriptions' AND column_name='household_id') THEN
        ALTER TABLE subscriptions ADD COLUMN household_id uuid REFERENCES households(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Davetler Tablosu (Zaten eklemiştik ama bütünlük için burda da dursun)
CREATE TABLE IF NOT EXISTS household_invitations (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  household_id uuid REFERENCES households(id) ON DELETE CASCADE,
  email text NOT NULL,
  status text DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

-- RLS Politikalarını Aktif Et
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Mevcut politikaları temizle (Hata almamak için)
DROP POLICY IF EXISTS "Users can view their own role" ON user_roles;
DROP POLICY IF EXISTS "Users can view their family" ON households;
DROP POLICY IF EXISTS "Users can view family members" ON household_members;

-- 1. User Roles Politikası: Herkes kendi rolünü görebilir
CREATE POLICY "Users can view their own role" ON user_roles
FOR SELECT USING (auth.uid() = user_id);

-- RLS Politikaları (COMPLETELY DISABLED - Direct Table Access)
ALTER TABLE household_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE households DISABLE ROW LEVEL SECURITY;
ALTER TABLE household_invitations DISABLE ROW LEVEL SECURITY;

-- Eski politikaları temizle
DROP POLICY IF EXISTS "Users can view family members" ON household_members;
DROP POLICY IF EXISTS "Users can view their own membership" ON household_members;
DROP POLICY IF EXISTS "Users can view their family" ON households;
DROP POLICY IF EXISTS "Users can view invitations" ON household_invitations;
DROP POLICY IF EXISTS "Users can insert invitations" ON household_invitations;
DROP POLICY IF EXISTS "Recipient can view invitations" ON household_invitations;

CREATE POLICY "Recipient can view invitations" ON household_invitations
FOR SELECT USING (lower(email) = lower(auth.jwt()->>'email'));

-- ==========================================
-- AİLE PAYLAŞIMI İÇİN RLS (v87)
-- ==========================================

-- 1. Receipts (Fişler)
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Family members can view receipts" ON receipts;
CREATE POLICY "Family members can view receipts" ON receipts
FOR SELECT USING (
  household_id IN (
    SELECT household_id FROM household_members WHERE user_id = auth.uid()
  ) OR user_id = auth.uid()
);

-- 2. User Credits (Manuel Giderler/Taksitler)
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Family members can view credits" ON user_credits;
CREATE POLICY "Family members can view credits" ON user_credits
FOR SELECT USING (
  household_id IN (
    SELECT household_id FROM household_members WHERE user_id = auth.uid()
  ) OR user_id = auth.uid()
);

-- 3. Subscriptions (Abonelikler)
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Family members can view subscriptions" ON subscriptions;
CREATE POLICY "Family members can view subscriptions" ON subscriptions
FOR SELECT USING (
  household_id IN (
    SELECT household_id FROM household_members WHERE user_id = auth.uid()
  ) OR user_id = auth.uid()
);


-- ==========================================
-- 2. FONKSİYONLAR (RPC)
-- ==========================================

-- Aile Durumunu Getir (REBUILT - Auth Context Fix)
DROP FUNCTION IF EXISTS get_family_status();
DROP FUNCTION IF EXISTS get_family_status() CASCADE;

CREATE OR REPLACE FUNCTION get_family_status()
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_household_id uuid;
  v_household_name text;
  v_members json;
  v_user_id uuid;
BEGIN
  -- 1. Auth context'i al
  v_user_id := auth.uid();
  
  -- 2. EĞER NULL İSE HATA VER (Bu Flutter'da görünecek)
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required: auth.uid() returned NULL. Please ensure you are logged in.';
  END IF;

  -- 3. Ailesi var mı?
  SELECT household_id INTO v_household_id
  FROM household_members
  WHERE user_id = v_user_id
  ORDER BY joined_at DESC
  LIMIT 1;

  IF v_household_id IS NULL THEN
    -- CRITICAL DEBUG: hangi user_id ile arıyoruz?
    RETURN json_build_object(
      'has_family', false,
      'debug_searched_user_id', v_user_id,
      'message', 'No family found for this user ID'
    );
  END IF;

  -- 4. Aile bilgilerini çek
  SELECT name INTO v_household_name
  FROM households
  WHERE id = v_household_id;

  IF v_household_name IS NULL THEN
     v_household_name := 'İsimsiz Aile';
  END IF;

  -- 5. Üyeleri çek (user_roles tablosundan email al)
  SELECT json_agg(
    json_build_object(
      'user_id', hm.user_id,
      'email', COALESCE(ur.email, u.email),
      'role', hm.role,
      'status', hm.status
    )
  ) INTO v_members
  FROM household_members hm
  LEFT JOIN auth.users u ON u.id = hm.user_id 
  LEFT JOIN user_roles ur ON ur.user_id = hm.user_id
  WHERE hm.household_id = v_household_id;

  -- 6. Rol bilgisini al (UI için Kritik)
  -- (Aşağıdaki RETURN içinde direkt çekiyoruz zaten)

  RETURN json_build_object(
    'has_family', true,
    'household_id', v_household_id,
    'household_name', v_household_name,
    'role', (SELECT role FROM household_members WHERE user_id = v_user_id LIMIT 1),
    'members', COALESCE(v_members, '[]'::json)
  );
END;
$$;

-- TEST FONKSİYONU: auth.uid() session problemi var mı?
CREATE OR REPLACE FUNCTION get_family_status_test(p_user_id uuid)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_household_id uuid;
  v_household_name text;
BEGIN
  SELECT household_id INTO v_household_id
  FROM household_members
  WHERE user_id = p_user_id
  LIMIT 1;

  IF v_household_id IS NULL THEN
    RETURN json_build_object('has_family', false, 'test_user_id', p_user_id);
  END IF;

  SELECT name INTO v_household_name FROM households WHERE id = v_household_id;

  RETURN json_build_object(
    'has_family', true,
    'household_id', v_household_id,
    'household_name', COALESCE(v_household_name, 'Test Aile')
  );
END;
$$;

-- Aile Oluştur
CREATE OR REPLACE FUNCTION create_family(family_name text, user_address text DEFAULT '')
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_new_id uuid;
BEGIN
  -- Zaten ailede mi?
  IF EXISTS (SELECT 1 FROM household_members WHERE user_id = auth.uid()) THEN
    RETURN json_build_object('success', false, 'message', 'Zaten bir ailedesiniz.');
  END IF;

  INSERT INTO households (name, owner_id, address)
  VALUES (family_name, auth.uid(), user_address)
  RETURNING id INTO v_new_id;

  INSERT INTO household_members (household_id, user_id, role)
  VALUES (v_new_id, auth.uid(), 'owner');

  RETURN json_build_object('success', true, 'family_id', v_new_id);
END;
$$;

-- Davet Gönder
DROP FUNCTION IF EXISTS send_family_invite(text);
DROP FUNCTION IF EXISTS send_family_invite(text, uuid);
CREATE OR REPLACE FUNCTION send_family_invite(target_email text, household_id uuid DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_household_id uuid;
BEGIN
  -- Hangi aile? (Parametre yoksa kişinin kendi ailesi)
  IF household_id IS NOT NULL THEN
     v_household_id := household_id;
  ELSE
     SELECT hm.household_id INTO v_household_id
     FROM household_members hm
     WHERE hm.user_id = auth.uid();
  END IF;

  IF v_household_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Bir aileniz yok.');
  END IF;

  -- VALIDATION: Zaten bu ailede mi?
  IF EXISTS (SELECT 1 FROM household_members WHERE household_id = v_household_id AND user_id IN (SELECT id FROM auth.users WHERE email = lower(target_email))) THEN
     RETURN json_build_object('success', false, 'message', 'Bu kullanıcı zaten ailenizde.');
  END IF;

  -- VALIDATION: Zaten başka bir ailede mi?
  IF EXISTS (SELECT 1 FROM household_members WHERE user_id IN (SELECT id FROM auth.users WHERE email = lower(target_email))) THEN
     RETURN json_build_object('success', false, 'message', 'Bu kullanıcı zaten bir aileye üye.');
  END IF;

  -- VALIDATION: Bekleyen daveti var mı?
  IF EXISTS (SELECT 1 FROM household_invitations WHERE household_id = v_household_id AND lower(email) = lower(target_email) AND status = 'pending') THEN
     RETURN json_build_object('success', false, 'message', 'Bu kullanıcıya zaten davet gönderilmiş.');
  END IF;

  -- Kayıt
  INSERT INTO household_invitations (household_id, email)
  VALUES (v_household_id, lower(target_email));

  -- Burada Notification tablosuna da ekleme yapılabilir
  -- INSERT INTO notifications ...

  RETURN json_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'message', SQLERRM);
END;
$$;

-- Daveti Kabul Et
CREATE OR REPLACE FUNCTION accept_family_invite(invite_id uuid, user_address text DEFAULT '')
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_invite record;
BEGIN
  SELECT * INTO v_invite FROM household_invitations WHERE id = invite_id;
  
  IF v_invite IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Davet bulunamadı.');
  END IF;

  -- Zaten ailede mi?
  IF EXISTS (SELECT 1 FROM household_members WHERE user_id = auth.uid()) THEN
     RETURN json_build_object('success', false, 'message', 'Zaten bir ailedesiniz.');
  END IF;

  -- Üye yap
  INSERT INTO household_members (household_id, user_id, role)
  VALUES (v_invite.household_id, auth.uid(), 'member');

  -- PAKET GÜNCELLE ve EXPIRES_AT SENKRONİZE ET
  UPDATE user_roles 
  SET 
    tier_id = 'limitless_family', 
    expires_at = (SELECT expires_at FROM user_roles WHERE user_id = (SELECT owner_id FROM households WHERE id = v_invite.household_id)),
    update_date = now()
  WHERE user_id = auth.uid();

  -- Daveti sil
  DELETE FROM household_invitations WHERE id = invite_id;

  RETURN json_build_object('success', true);
END;
$$;

-- Üye Çıkar
CREATE OR REPLACE FUNCTION remove_family_member(target_user_id uuid)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_my_role text;
  v_household_id uuid;
BEGIN
  SELECT household_id, role INTO v_household_id, v_my_role
  FROM household_members
  WHERE user_id = auth.uid();

  IF v_my_role != 'owner' AND auth.uid() != target_user_id THEN
    RETURN json_build_object('success', false, 'message', 'Yetkiniz yok.');
  END IF;

  DELETE FROM household_members
  WHERE user_id = target_user_id AND household_id = v_household_id;

  -- PAKET DÜŞÜR (Ayrılan kişi standart pakete döner)
  UPDATE user_roles 
  SET tier_id = 'standart', update_date = now()
  WHERE user_id = target_user_id;

  RETURN json_build_object('success', true);
END;
$$;

-- Aileden Ayrıl
CREATE OR REPLACE FUNCTION leave_family()
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM household_members WHERE user_id = auth.uid();
  
  -- PAKET DÜŞÜR
  UPDATE user_roles 
  SET tier_id = 'standart', update_date = now()
  WHERE user_id = auth.uid();

  RETURN json_build_object('success', true);
END;
$$;

-- Daveti Reddet
CREATE OR REPLACE FUNCTION reject_family_invite(invite_id uuid)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM household_invitations WHERE id = invite_id; -- Sadece sil
  RETURN json_build_object('success', true);
END;
$$;

-- Kullanıcı Rolü Garanti (Idempotent)
DROP FUNCTION IF EXISTS ensure_user_role();
CREATE OR REPLACE FUNCTION ensure_user_role()
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := auth.uid();
  
  -- Kayıt zaten varsa HİÇBİR ŞEY YAPMA (Mevcut veriyi koru)
  IF EXISTS (SELECT 1 FROM user_roles WHERE user_id = v_user_id) THEN
    RETURN json_build_object('success', true, 'message', 'Role already exists');
  END IF;

  -- Yoksa varsayılan (standart) oluştur
  INSERT INTO user_roles (user_id, tier_id, email)
  VALUES (v_user_id, 'standart', COALESCE(auth.jwt()->>'email', (SELECT email FROM auth.users WHERE id = v_user_id)));

  RETURN json_build_object('success', true, 'message', 'Role created');
END;
$$;


-- Süre Kontrolü (Expiration Check)
DROP FUNCTION IF EXISTS check_my_expiration();
CREATE OR REPLACE FUNCTION check_my_expiration()
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_expires_at timestamptz;
  v_tier_id text;
BEGIN
  SELECT expires_at, tier_id INTO v_expires_at, v_tier_id
  FROM user_roles
  WHERE user_id = auth.uid();

  -- Eğer süresi yoksa veya standart ise işlem yapma
  IF v_expires_at IS NULL OR v_tier_id = 'standart' THEN
    RETURN json_build_object('status', 'no_expiration');
  END IF;

  -- UTC zamanına göre kontrol (Postgres now() zaten timestamptz döner)
  IF v_expires_at < now() THEN
     -- Süre dolmuş -> Standart'a çek
     UPDATE user_roles
     SET tier_id = 'standart', expires_at = NULL, update_date = now()
     WHERE user_id = auth.uid();
     
     RETURN json_build_object('status', 'downgraded', 'previous_tier', v_tier_id);
  END IF;

  RETURN json_build_object('status', 'active', 'expires_at', v_expires_at);
END;
$$;

