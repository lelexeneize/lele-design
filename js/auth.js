// ─── Auth Supabase + legacy fallback ─────────────────────────

function saveUserToRegistry(user) {
  dbSaveUser(user);
}

function handleGoogleLogin(response) {
  const payload = decodeJwtResponse(response.credential);
  const user = {
    name: payload.name,
    email: payload.email,
    picture: payload.picture,
    isGoogle: true
  };
  localStorage.setItem('lele_user', JSON.stringify(user));
  saveUserToRegistry(user);
  window.location.href = 'dashboard.html';
}

function handleGoogleRegister(response) {
  const payload = decodeJwtResponse(response.credential);
  const user = {
    name: payload.name,
    email: payload.email,
    picture: payload.picture,
    isGoogle: true
  };
  localStorage.setItem('lele_user', JSON.stringify(user));
  saveUserToRegistry(user);
  window.location.href = 'dashboard.html';
}

function decodeJwtResponse(token) {
  const base64Url = token.split('.')[1];
  const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
  const jsonPayload = decodeURIComponent(
    atob(base64).split('').map(c =>
      '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)
    ).join('')
  );
  return JSON.parse(jsonPayload);
}

function updateNavbarAuth() {
  const navLogin = document.getElementById('navLoginBtn');
  const navRegister = document.getElementById('navRegisterBtn');
  const navUser = document.getElementById('authNavUser');
  const navSection = document.getElementById('authNavSection');
  const navAvatar = document.getElementById('navAvatar');

  const user = JSON.parse(localStorage.getItem('lele_user'));
  if (user && navSection && navUser) {
    navSection.classList.add('hidden');
    navSection.classList.remove('flex');
    navUser.classList.remove('hidden');
    navUser.classList.add('flex');
    if (navAvatar) {
      if (user.picture) {
        navAvatar.innerHTML = `<img src="${user.picture}" alt="avatar" class="w-full h-full rounded-full object-cover">`;
      } else {
        navAvatar.textContent = (user.name || 'U').charAt(0).toUpperCase();
      }
    }
  } else if (navSection && navUser) {
    navSection.classList.remove('hidden');
    navSection.classList.add('flex');
    navUser.classList.add('hidden');
    navUser.classList.remove('flex');
  }
}

function logout() {
  dbSignOut().then(() => {
    window.location.href = '../index.html';
  }).catch(() => {
    localStorage.removeItem('lele_user');
    window.location.href = '../index.html';
  });
}

async function checkAdminAndRedirect() {
  const user = JSON.parse(localStorage.getItem('lele_user'));
  if (!user?.email) return;
  try {
    const sb = await getSupabaseClient();
    if (sb) {
      const { data: profile } = await sb.from('profiles').select('role').eq('email', user.email).single();
      if (profile?.role === 'admin') {
        window.location.href = 'admin.html';
      }
    }
  } catch (_) {}
}

async function getSupabaseToken() {
  const sb = await getSupabaseClient();
  if (!sb) return null;
  try {
    const { data: { session } } = await sb.auth.getSession();
    return session?.access_token || null;
  } catch { return null; }
}

document.addEventListener('DOMContentLoaded', () => {
  const user = JSON.parse(localStorage.getItem('lele_user'));

  if (user) {
    saveUserToRegistry(user);
  }

  const isAuthPage = window.location.pathname.includes('login.html') ||
                     window.location.pathname.includes('register.html');
  if (user && isAuthPage) {
    window.location.href = 'dashboard.html';
  }

  const isAdminLoginPage = window.location.pathname.includes('admin-login.html');
  if (user && isAdminLoginPage) {
    checkAdminAndRedirect();
  }

  const isProtected = window.location.pathname.includes('dashboard.html') ||
                      window.location.pathname.includes('generator.html') ||
                      window.location.pathname.includes('admin.html') ||
                      window.location.pathname.includes('admin-works.html') ||
                      window.location.pathname.includes('admin-licenses.html');
  if (!user && isProtected) {
    window.location.href = 'login.html';
  }

  updateNavbarAuth();

  if (user) {
    const nameEl = document.getElementById('userGreeting');
    const avatarEl = document.getElementById('userAvatar');
    if (nameEl) nameEl.textContent = user.name || 'Usuario';
    if (avatarEl) {
      if (user.picture) {
        avatarEl.innerHTML = `<img src="${user.picture}" alt="avatar" class="w-full h-full rounded-full object-cover">`;
      } else {
        avatarEl.textContent = (user.name || 'U').charAt(0).toUpperCase();
      }
    }
  }

  // Listen for Supabase auth changes
  dbOnAuthStateChange((supaUser) => {
    if (supaUser) {
      const nameEl = document.getElementById('userGreeting');
      const avatarEl = document.getElementById('userAvatar');
      if (nameEl) nameEl.textContent = supaUser.name || 'Usuario';
      if (avatarEl) {
        if (supaUser.picture) {
          avatarEl.innerHTML = `<img src="${supaUser.picture}" alt="avatar" class="w-full h-full rounded-full object-cover">`;
        } else {
          avatarEl.textContent = (supaUser.name || 'U').charAt(0).toUpperCase();
        }
      }
    }
  });
});
