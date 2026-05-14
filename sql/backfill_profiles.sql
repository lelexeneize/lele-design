-- ─── Backfill: crear profiles para usuarios existentes ─────────
-- Ejecutá esto en el SQL Editor de Supabase para que aparezcan
-- todos los usuarios registrados en el panel de admin
-- ───────────────────────────────────────────────────────────────

INSERT INTO profiles (id, name, email, picture, plan, credits, role, is_google, created_at)
SELECT
  au.id,
  COALESCE(
    au.raw_user_meta_data->>'full_name',
    au.raw_user_meta_data->>'name',
    split_part(au.email, '@', 1)
  ),
  au.email,
  COALESCE(au.raw_user_meta_data->>'picture', ''),
  'free',
  10,
  'user',
  (au.raw_user_meta_data->>'provider' = 'google' OR au.app_metadata->>'provider' = 'google'),
  au.created_at
FROM auth.users au
WHERE au.id NOT IN (SELECT id FROM public.profiles)
  AND au.email IS NOT NULL;

-- Mostrar cuantos se insertaron
SELECT CONCAT('✅ Se insertaron ', COUNT(*), ' perfil(es)') FROM profiles;
