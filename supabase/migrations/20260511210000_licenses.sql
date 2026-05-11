-- License keys table
CREATE TABLE IF NOT EXISTS license_keys (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  plan TEXT NOT NULL CHECK (plan IN ('essential', 'pro', 'elite')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'used', 'disabled')),
  activated_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE license_keys ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage licenses"
  ON license_keys FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );
CREATE POLICY "Anyone can validate licenses"
  ON license_keys FOR SELECT
  USING (true);

-- Orders table for payments
CREATE TABLE IF NOT EXISTS orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  plan TEXT NOT NULL,
  amount DECIMAL NOT NULL,
  currency TEXT DEFAULT 'ARS',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  mp_preference_id TEXT,
  mp_payment_id TEXT,
  license_key_id UUID REFERENCES license_keys(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own orders"
  ON orders FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage orders"
  ON orders FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );
