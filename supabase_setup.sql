-- Premium kullanıcılar tablosu
CREATE TABLE IF NOT EXISTS premium_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  is_premium BOOLEAN DEFAULT false,
  premium_until TIMESTAMPTZ,
  free_ai_chats_remaining INTEGER DEFAULT 5,
  free_location_analysis_remaining INTEGER DEFAULT 5,
  coins INTEGER DEFAULT 5,
  subscription_type TEXT,
  premium_feature_access JSONB DEFAULT '{}',
  mogi_points INTEGER DEFAULT 0,
  usage_statistics JSONB DEFAULT '{}',
  purchase_history JSONB DEFAULT '[]',
  coin_usage_history JSONB DEFAULT '[]',
  coin_addition_history JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Kullanıcı ID'si için indeks
CREATE INDEX IF NOT EXISTS premium_users_user_id_idx ON premium_users (user_id);

-- RLS (Row Level Security) politikaları
ALTER TABLE premium_users ENABLE ROW LEVEL SECURITY;

-- Herkes kendi verilerini okuyabilir
DROP POLICY IF EXISTS "Users can read their own data" ON premium_users;
CREATE POLICY "Users can read their own data" ON premium_users
  FOR SELECT USING (auth.uid() = user_id);

-- Herkes kendi verilerini güncelleyebilir
DROP POLICY IF EXISTS "Users can update their own data" ON premium_users;
CREATE POLICY "Users can update their own data" ON premium_users
  FOR UPDATE USING (auth.uid() = user_id);

-- Kullanıcılar yeni kayıt ekleyebilir
DROP POLICY IF EXISTS "Users can insert their own data" ON premium_users;
CREATE POLICY "Users can insert their own data" ON premium_users
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Premium durumu güncelleyen fonksiyon
CREATE OR REPLACE FUNCTION check_premium_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Premium durumunu kontrol et
  IF NEW.premium_until IS NOT NULL AND NEW.premium_until > NOW() THEN
    NEW.is_premium := true;
  ELSE
    NEW.is_premium := false;
  END IF;
  
  -- Son güncelleme zamanını ayarla
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Premium durumu için trigger
DROP TRIGGER IF EXISTS trigger_check_premium_status ON premium_users;
CREATE TRIGGER trigger_check_premium_status
BEFORE INSERT OR UPDATE ON premium_users
FOR EACH ROW EXECUTE FUNCTION check_premium_status();

-- Admin rolleri için yetkilendirme fonksiyonu
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  -- Burada admin rolü kontrolü yapılabilir
  -- Şimdilik basit bir kontrol
  RETURN EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'admin'
  );
END;
$$ LANGUAGE plpgsql;

-- Güvenlik olayları tablosu
CREATE TABLE IF NOT EXISTS security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  details JSONB,
  timestamp TIMESTAMPTZ DEFAULT now(),
  ip_address TEXT,
  device_info JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Güvenlik olayları için indeksler
CREATE INDEX IF NOT EXISTS security_events_user_id_idx ON security_events (user_id);
CREATE INDEX IF NOT EXISTS security_events_event_type_idx ON security_events (event_type);
CREATE INDEX IF NOT EXISTS security_events_timestamp_idx ON security_events (timestamp);

-- Güvenlik olayları için RLS politikaları
ALTER TABLE security_events ENABLE ROW LEVEL SECURITY;

-- Sadece kendi güvenlik olaylarını okuyabilir (kullanıcılar)
DROP POLICY IF EXISTS "Users can view their own security events" ON security_events;
CREATE POLICY "Users can view their own security events" ON security_events
  FOR SELECT USING (auth.uid() = user_id);

-- Herkes kendine ait güvenlik olayı ekleyebilir
DROP POLICY IF EXISTS "Users can insert their own security events" ON security_events;
CREATE POLICY "Users can insert their own security events" ON security_events
  FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Adminlerin tüm güvenlik olaylarını görebilmesi için poliçe
DROP POLICY IF EXISTS "Admins can view all security events" ON security_events;
CREATE POLICY "Admins can view all security events" ON security_events
  FOR SELECT USING (is_admin());

-- Ödeme doğrulama tablosu
CREATE TABLE IF NOT EXISTS payment_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  payment_id TEXT NOT NULL,
  payment_provider TEXT NOT NULL,
  payment_method TEXT,
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL,
  verification_token TEXT,
  verification_timestamp TIMESTAMPTZ,
  verification_status BOOLEAN DEFAULT false,
  receipt_data TEXT,
  product_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Ödeme doğrulama için indeksler
CREATE INDEX IF NOT EXISTS payment_verifications_user_id_idx ON payment_verifications (user_id);
CREATE INDEX IF NOT EXISTS payment_verifications_payment_id_idx ON payment_verifications (payment_id);

-- Ödeme doğrulama için RLS politikaları
ALTER TABLE payment_verifications ENABLE ROW LEVEL SECURITY;

-- Sadece kendi ödeme doğrulamalarını okuyabilir
DROP POLICY IF EXISTS "Users can read only their own payment verifications" ON payment_verifications;
CREATE POLICY "Users can read only their own payment verifications" ON payment_verifications
  FOR SELECT USING (auth.uid() = user_id);

-- Kullanıcılar kendi ödeme doğrulamalarını ekleyebilir
DROP POLICY IF EXISTS "Users can insert their own payment verifications" ON payment_verifications;
CREATE POLICY "Users can insert their own payment verifications" ON payment_verifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Kullanıcılar kendi ödeme doğrulamalarını güncelleyebilir
DROP POLICY IF EXISTS "Users can update their own payment verifications" ON payment_verifications;
CREATE POLICY "Users can update their own payment verifications" ON payment_verifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Admin tüm ödeme doğrulamalarını görebilir
DROP POLICY IF EXISTS "Admins can read all payment verifications" ON payment_verifications;
CREATE POLICY "Admins can read all payment verifications" ON payment_verifications
  FOR SELECT USING (is_admin());

-- Adminlerin ödeme doğrulamalarını güncelleyebilmesi için poliçe
DROP POLICY IF EXISTS "Admins can update payment verifications" ON payment_verifications;
CREATE POLICY "Admins can update payment verifications" ON payment_verifications
  FOR UPDATE USING (is_admin()); 