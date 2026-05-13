// ─── Supabase Configuration ──────────────────────────────
// 1. Create a free project at https://supabase.com
// 2. Go to Project Settings → API
// 3. Copy your Project URL and anon/public key below
// 4. Run sql/schema.sql in the Supabase SQL Editor
// ─────────────────────────────────────────────────────────

const SUPABASE_CONFIG = {
  url: 'https://qovtekqxruusqhscacqn.supabase.co',
  anonKey: 'sb_publishable_iZ9oKQoxTU0ui2kAUhCcLg_CrXpI1S2'
};

// ─── Supabase client singleton ───────────────────────────
let _supabaseClient = null;

async function getSupabaseClient() {
  if (_supabaseClient) return _supabaseClient;
  if (!SUPABASE_CONFIG.url || !SUPABASE_CONFIG.anonKey) {
    console.warn('Supabase not configured. Using localStorage fallback.');
    return null;
  }
  if (typeof supabase === 'undefined') {
    await _sdkPromise;
  }
  if (typeof supabase === 'undefined') {
    console.warn('Supabase JS SDK failed to load. Using localStorage fallback.');
    return null;
  }
  _supabaseClient = supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);
  return _supabaseClient;
}

// ─── Load Supabase SDK if not present ────────────────────
(function ensureSupabaseSDK() {
  if (typeof supabase !== 'undefined') return;
  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js';
  script.onload = () => {
    console.log('Supabase SDK loaded');
    document.dispatchEvent(new Event('supabase:sdk:ready'));
  };
  script.onerror = () => console.warn('Failed to load Supabase SDK');
  document.head.appendChild(script);
})();

let _sdkLoadResolve = null;
const _sdkPromise = new Promise((resolve) => {
  if (typeof supabase !== 'undefined') return resolve();
  _sdkLoadResolve = resolve;
  document.addEventListener('supabase:sdk:ready', resolve, { once: true });
  setTimeout(resolve, 5000);
});
