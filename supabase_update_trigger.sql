-- Premium durumu güncelleyen fonksiyonu düzenle
CREATE OR REPLACE FUNCTION check_premium_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Premium durumunu kontrol et
  IF NEW.premium_until IS NULL THEN
    -- premium_until null ise, is_premium false olmalı
    NEW.is_premium := false;
  ELSIF NEW.premium_until > NOW() THEN
    -- premium_until gelecekte bir tarih ise ve is_premium true ise, true olarak kalsın
    NEW.is_premium := true;
  ELSE
    -- premium_until geçmiş bir tarih ise, is_premium false olmalı
    NEW.is_premium := false;
  END IF;
  
  -- Son güncelleme zamanını ayarla
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Mevcut trigger'ı düşür ve yeniden oluştur
DROP TRIGGER IF EXISTS trigger_check_premium_status ON premium_users;
CREATE TRIGGER trigger_check_premium_status
BEFORE INSERT OR UPDATE ON premium_users
FOR EACH ROW EXECUTE FUNCTION check_premium_status(); 