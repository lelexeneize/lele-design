-- ============================================================
-- Lele Design — Supabase Database Schema
-- ============================================================
-- Run this in the Supabase SQL Editor after creating your project
-- Docs: https://supabase.com/dashboard/project/_/sql/new
-- ============================================================

-- ─── Profiles (syncs with Supabase Auth users) ────────────
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  email TEXT,
  picture TEXT,
  plan TEXT DEFAULT 'free',
  credits INTEGER DEFAULT 10,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Gallery works ────────────────────────────────────────
CREATE TABLE works (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  category TEXT NOT NULL DEFAULT 'IA',
  image TEXT NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Auto-create profile on signup ────────────────────────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, picture, plan, credits, role)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'name',
    NEW.email,
    NEW.raw_user_meta_data->>'picture',
    'free',
    10,
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ─── Row Level Security ───────────────────────────────────
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE works ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read all profiles, update only own
CREATE POLICY "Users can read all profiles"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Works: anyone can read, only authenticated can insert/update/delete
CREATE POLICY "Anyone can read works"
  ON works FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert works"
  ON works FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update own works"
  ON works FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own works"
  ON works FOR DELETE
  USING (auth.uid() = user_id);

-- Admin can do everything
CREATE POLICY "Admin can manage all works"
  ON works FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- ─── License keys ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS license_keys (
  key TEXT PRIMARY KEY,
  plan TEXT NOT NULL DEFAULT 'essential',
  status TEXT NOT NULL DEFAULT 'active',
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE license_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read license_keys"
  ON license_keys FOR SELECT
  USING (true);

CREATE POLICY "Allow anon inserts"
  ON license_keys FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Admins can update license_keys"
  ON license_keys FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
