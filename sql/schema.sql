-- ─── Lele Oficial — Supabase Schema ───────────────────────
-- Ejecutá esto en el SQL Editor de Supabase
-- https://supabase.com/dashboard/project/qovtekqxruusqhscacqn/sql/new
-- ──────────────────────────────────────────────────────────

-- 1. PROFILES (users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT DEFAULT '',
  email TEXT UNIQUE NOT NULL,
  picture TEXT DEFAULT '',
  plan TEXT DEFAULT 'free',
  credits INT DEFAULT 10,
  role TEXT DEFAULT 'user',
  is_google BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Todos pueden leer su propio perfil
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id OR role = 'admin');

-- Solo admin puede insertar/actualizar cualquier perfil
CREATE POLICY "Admins can insert"
  ON profiles FOR INSERT
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- 2. WORKS (gallery)
CREATE TABLE IF NOT EXISTS works (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  category TEXT NOT NULL,
  image TEXT NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE works ENABLE ROW LEVEL SECURITY;

-- Cualquiera puede leer works (galería pública)
CREATE POLICY "Anyone can read works"
  ON works FOR SELECT
  USING (TRUE);

-- Solo admin puede insertar/actualizar/eliminar
CREATE POLICY "Admins can insert works"
  ON works FOR INSERT
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admins can update works"
  ON works FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admins can delete works"
  ON works FOR DELETE
  USING (auth.jwt() ->> 'role' = 'admin');

-- 3. LICENSE KEYS
CREATE TABLE IF NOT EXISTS license_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  plan TEXT NOT NULL,
  status TEXT DEFAULT 'active',
  max_activations INT DEFAULT 3,
  activated_devices JSONB DEFAULT '[]'::jsonb,
  emailed_at TIMESTAMPTZ,
  used_at TIMESTAMPTZ,
  last_validated_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE license_keys ENABLE ROW LEVEL SECURITY;

-- Solo admin puede leer/insertar/actualizar/eliminar
CREATE POLICY "Admins can read license_keys"
  ON license_keys FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admins can insert license_keys"
  ON license_keys FOR INSERT
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- 4. RPC: validate_key (para descargar.html)
CREATE OR REPLACE FUNCTION validate_key(p_key TEXT)
RETURNS TABLE(key TEXT, plan TEXT, status TEXT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT lk.key, lk.plan, lk.status, lk.expires_at
  FROM license_keys lk
  WHERE lk.key = p_key
  LIMIT 1;
END;
$$;
