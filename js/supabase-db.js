// ─── Supabase Database Operations (with localStorage fallback) ───
// All functions work seamlessly whether Supabase is configured or not.
// When Supabase is set up, data persists in the cloud across devices.
// If not configured, falls back to localStorage (existing behavior).
// ──────────────────────────────────────────────────────────────────

// ─── USERS ────────────────────────────────────────────────────────

async function dbGetUsers() {
  const sb = getSupabaseClient();
  if (sb) {
    const { data, error } = await sb.from('profiles').select('*').order('created_at', { ascending: false });
    if (!error && data) return data;
    console.warn('Supabase fetch error, falling back to localStorage:', error?.message);
  }
  return JSON.parse(localStorage.getItem('lele_users') || '[]');
}

async function dbSaveUser(user) {
  const sb = getSupabaseClient();
  if (sb) {
    try {
      // Upsert: insert if not exists, update if exists (matched by email)
      const { error } = await sb.from('profiles').upsert({
        id: user.id || crypto.randomUUID(),
        name: user.name || '',
        email: user.email || '',
        picture: user.picture || '',
        plan: 'free',
        credits: 10,
        role: user.email === 'admin@leledesign.com' ? 'admin' : 'user'
      }, { onConflict: 'email', ignoreDuplicates: false });
      if (error) console.warn('Supabase upsert error:', error.message);
    } catch (e) {
      console.warn('Supabase save error, falling back:', e.message);
    }
    return;
  }
  const users = JSON.parse(localStorage.getItem('lele_users') || '[]');
  const exists = users.some(u => u.email === user.email);
  if (!exists) {
    users.push({ ...user, registeredAt: Date.now() });
    localStorage.setItem('lele_users', JSON.stringify(users));
  }
}

async function dbRemoveUser(userId) {
  const sb = getSupabaseClient();
  if (sb) {
    await sb.from('profiles').delete().eq('id', userId);
    return;
  }
  const users = JSON.parse(localStorage.getItem('lele_users') || '[]');
  const idx = users.findIndex(u => u.id === userId || u.email === userId);
  if (idx !== -1) users.splice(idx, 1);
  localStorage.setItem('lele_users', JSON.stringify(users));
}

// ─── WORKS (Gallery) ─────────────────────────────────────────────

async function dbGetWorks() {
  const sb = getSupabaseClient();
  if (sb) {
    const { data, error } = await sb.from('works').select('*').order('created_at', { ascending: false });
    if (!error && data) return data;
    console.warn('Supabase fetch error, falling back to localStorage:', error?.message);
  }
  return JSON.parse(localStorage.getItem('lele_works') || '[]');
}

async function dbAddWork(work) {
  const sb = getSupabaseClient();
  if (sb) {
    const { data: user } = await sb.auth.getUser();
    const { error } = await sb.from('works').insert({
      title: work.title,
      description: work.description || '',
      category: work.category,
      image: work.image,
      user_id: user?.user?.id || null
    });
    if (error) console.warn('Supabase insert error:', error.message);
    return;
  }
  const works = JSON.parse(localStorage.getItem('lele_works') || '[]');
  works.unshift({ ...work, createdAt: Date.now() });
  localStorage.setItem('lele_works', JSON.stringify(works));
}

async function dbDeleteWork(workId) {
  const sb = getSupabaseClient();
  if (sb) {
    await sb.from('works').delete().eq('id', workId);
    return;
  }
  const works = JSON.parse(localStorage.getItem('lele_works') || '[]');
  works.splice(workId, 1);
  localStorage.setItem('lele_works', JSON.stringify(works));
}

async function dbDeleteAllWorks() {
  const sb = getSupabaseClient();
  if (sb) {
    await sb.from('works').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    return;
  }
  localStorage.setItem('lele_works', '[]');
}

// ─── AUTH ────────────────────────────────────────────────────────

async function dbSignInWithGoogle() {
  const sb = getSupabaseClient();
  if (sb) {
    const { error } = await sb.auth.signInWithOAuth({ provider: 'google' });
    if (error) console.error('Supabase Google sign-in error:', error.message);
    return;
  }
  // If no Supabase, Google OAuth works as before via Google Identity Services
  console.warn('Supabase not configured — using legacy Google Sign-In');
}

async function dbSignOut() {
  const sb = getSupabaseClient();
  if (sb) {
    await sb.auth.signOut();
  }
  localStorage.removeItem('lele_user');
}

async function dbGetCurrentUser() {
  const sb = getSupabaseClient();
  if (sb) {
    const { data: { user } } = await sb.auth.getUser();
    if (user) {
      const { data: profile } = await sb.from('profiles').select('*').eq('id', user.id).single();
      return profile || { id: user.id, name: user.user_metadata?.name, email: user.email, picture: user.user_metadata?.picture };
    }
    return null;
  }
  return JSON.parse(localStorage.getItem('lele_user'));
}

// ─── Session listener (for Supabase) ────────────────────────────
function dbOnAuthStateChange(callback) {
  const sb = getSupabaseClient();
  if (sb) {
    sb.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_IN' && session?.user) {
        const user = {
          id: session.user.id,
          name: session.user.user_metadata?.name || session.user.email,
          email: session.user.email,
          picture: session.user.user_metadata?.picture
        };
        localStorage.setItem('lele_user', JSON.stringify(user));
        callback(user);
      } else if (event === 'SIGNED_OUT') {
        localStorage.removeItem('lele_user');
        callback(null);
      }
    });
  }
}
