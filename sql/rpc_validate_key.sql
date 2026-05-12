-- ─── RPC: validate a license key ──────────────────────────
-- Run this in Supabase SQL Editor
-- Returns: { key, plan, status } or empty
-- Usage: SELECT * FROM validate_key('ES-XXXXXX-...');
-- ─────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.validate_key(p_key TEXT)
RETURNS TABLE(key TEXT, plan TEXT, status TEXT)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY SELECT l.key, l.plan, l.status
  FROM public.license_keys l
  WHERE l.key = p_key;
END;
$$;

-- Allow the anon role (public) to call this function
GRANT EXECUTE ON FUNCTION public.validate_key TO anon;
