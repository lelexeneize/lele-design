// ─── Theme management ────────────────────────────────────────

(function() {
  const KEY = 'lele_theme';

  function getTheme() {
    return localStorage.getItem(KEY) || 'dark';
  }

  function setTheme(theme) {
    document.documentElement.classList.toggle('light', theme === 'light');
    document.documentElement.classList.toggle('dark', theme !== 'light');
    localStorage.setItem(KEY, theme);
  }

  function toggleTheme() {
    setTheme(getTheme() === 'dark' ? 'light' : 'dark');
  }

  function applySavedTheme() {
    setTheme(getTheme());
  }

  // ─── Botón toggle ──────────────────────────────────────────

  function createToggle() {
    const btn = document.createElement('button');
    btn.className = 'theme-toggle';
    btn.id = 'themeToggleBtn';
    btn.title = 'Cambiar tema';
    btn.innerHTML = getTheme() === 'dark' ? '☀️' : '🌙';
    btn.addEventListener('click', () => {
      toggleTheme();
      btn.innerHTML = getTheme() === 'dark' ? '☀️' : '🌙';
    });
    return btn;
  }

  // ─── Exponer globalmente ──────────────────────────────────

  window.leleTheme = { getTheme, setTheme, toggleTheme, applySavedTheme, createToggle };
})();