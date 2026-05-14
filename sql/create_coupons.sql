-- ─── Coupons / Gift Codes — Lele Oficial ──────────────────────
-- Ejecutá esto en el SQL Editor de Supabase
-- https://supabase.com/dashboard/project/qovtekqxruusqhscacqn/sql/new
-- ───────────────────────────────────────────────────────────────

-- 1. COUPONS TABLE
CREATE TABLE IF NOT EXISTS coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('credits', 'license')),
  value INTEGER NOT NULL DEFAULT 1,
  detail TEXT DEFAULT '',
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'used', 'disabled')),
  used_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  used_at TIMESTAMPTZ,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;

-- Admins can read all coupons
CREATE POLICY "Admins can read coupons"
  ON coupons FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- Admins can insert coupons
CREATE POLICY "Admins can insert coupons"
  ON coupons FOR INSERT
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- Admins can update coupons
CREATE POLICY "Admins can update coupons"
  ON coupons FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin');

-- Users can only read coupons they used
CREATE POLICY "Users can read own used coupons"
  ON coupons FOR SELECT
  USING (used_by = auth.uid());

-- 2. ADD user_id TO license_keys (for assigned licenses)
ALTER TABLE license_keys ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

-- 3. RPC: redeem_coupon (SECURITY DEFINER — runs as admin)
CREATE OR REPLACE FUNCTION redeem_coupon(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_coupon coupons%ROWTYPE;
  v_user_id UUID := auth.uid();
  v_license_key TEXT;
  v_prefix TEXT;
  v_seg TEXT;
BEGIN
  -- Must be authenticated
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'No autenticado');
  END IF;

  -- Lock coupon row to prevent double redemption
  SELECT * INTO v_coupon FROM coupons WHERE code = p_code FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Código inválido');
  END IF;

  IF v_coupon.status != 'active' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Este código ya fue utilizado');
  END IF;

  IF v_coupon.expires_at IS NOT NULL AND v_coupon.expires_at < NOW() THEN
    RETURN jsonb_build_object('success', false, 'error', 'Este código ha expirado');
  END IF;

  -- Process by type
  IF v_coupon.type = 'credits' THEN
    UPDATE profiles
    SET credits = COALESCE(credits, 0) + v_coupon.value
    WHERE id = v_user_id;

  ELSIF v_coupon.type = 'license' THEN
    v_prefix := CASE v_coupon.detail
      WHEN 'essential' THEN 'ES'
      WHEN 'pro' THEN 'PR'
      WHEN 'elite' THEN 'EL'
      ELSE 'ES'
    END;

    v_license_key := v_prefix || '-' ||
      upper(substr(md5(gen_random_uuid()::text), 1, 6)) || '-' ||
      upper(substr(md5(gen_random_uuid()::text), 1, 6)) || '-' ||
      upper(substr(md5(gen_random_uuid()::text), 1, 6)) || '-' ||
      upper(substr(md5(gen_random_uuid()::text), 1, 6));

    INSERT INTO license_keys (key, plan, status, user_id)
    VALUES (v_license_key, v_coupon.detail, 'active', v_user_id);
  END IF;

  -- Mark coupon as used
  UPDATE coupons
  SET status = 'used', used_by = v_user_id, used_at = NOW()
  WHERE id = v_coupon.id;

  RETURN jsonb_build_object(
    'success', true,
    'type', v_coupon.type,
    'value', v_coupon.value,
    'detail', v_coupon.detail,
    'license_key', v_license_key
  );
END;
$$;
