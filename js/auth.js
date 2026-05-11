// ─── Guardar usuario en la lista de registrados ────────────────

function saveUserToRegistry(user) {
  const users = JSON.parse(localStorage.getItem('lele_users') || '[]');
  const exists = users.some(u => u.email === user.email);
  if (!exists) {
    users.push({ ...user, registeredAt: Date.now() });
    localStorage.setItem('lele_users', JSON.stringify(users));
  }
}

// ─── Google Sign-In ───────────────────────────────────────────────

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

// ─── Decodificar JWT de Google ──────────────────────────────────

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

// ─── Cerrar sesión ───────────────────────────────────────────────

function logout() {
  localStorage.removeItem('lele_user');
  window.location.href = '../index.html';
}

// ─── Verificar sesión al cargar ──────────────────────────────────

document.addEventListener('DOMContentLoaded', () => {
  const user = JSON.parse(localStorage.getItem('lele_user'));

  // Asegurar que el usuario actual esté en el registro
  if (user) {
    saveUserToRegistry(user);
  }

  // Si está en login/register y ya tiene sesión → dashboard
  const isAuthPage = window.location.pathname.includes('login.html') ||
                     window.location.pathname.includes('register.html');
  if (user && isAuthPage) {
    window.location.href = 'dashboard.html';
  }

  // Si está en dashboard y no tiene sesión → login
  const isProtected = window.location.pathname.includes('dashboard.html') ||
                       window.location.pathname.includes('generator.html');
  if (!user && isProtected) {
    window.location.href = 'login.html';
  }

  // Mostrar nombre y avatar del usuario
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
});