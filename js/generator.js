document.addEventListener('DOMContentLoaded', () => {

  const promptInput = document.getElementById('promptInput');
  const generateBtn = document.getElementById('generateBtn');
  const btnIcon = document.getElementById('btnIcon');
  const btnText = document.getElementById('btnText');
  const loader = document.getElementById('loader');
  const gallery = document.getElementById('gallery');
  const galleryGrid = document.getElementById('galleryGrid');
  const clearBtn = document.getElementById('clearGallery');
  const creditInfo = document.getElementById('creditInfo');

  let selectedStyle = 'realista';
  let credits = 147;

  // ─── Estilos ──────────────────────────────────────────────

  document.querySelectorAll('.style-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.style-btn').forEach(b => {
        b.classList.remove('bg-violet-600/20', 'border-violet-500/50', 'text-white');
        b.classList.add('bg-white/[0.05]', 'border-white/[0.08]', 'text-white/60');
      });
      btn.classList.remove('bg-white/[0.05]', 'border-white/[0.08]', 'text-white/60');
      btn.classList.add('bg-violet-600/20', 'border-violet-500/50', 'text-white');
      selectedStyle = btn.dataset.style;
    });
  });

  // Seleccionar realista por defecto
  document.querySelector('.style-btn[data-style="realista"]').click();

  // ─── Generar ──────────────────────────────────────────────

  generateBtn.addEventListener('click', async () => {
    const prompt = promptInput.value.trim();
    if (!prompt) {
      promptInput.focus();
      promptInput.classList.add('border-red-500/50');
      setTimeout(() => promptInput.classList.remove('border-red-500/50'), 2000);
      return;
    }

    if (credits <= 0) {
      alert('¡Te quedaste sin créditos! Actualizá tu plan.');
      return;
    }

    // Loading state
    generateBtn.disabled = true;
    btnIcon.textContent = '⏳';
    btnText.textContent = 'Generando...';
    loader.classList.remove('hidden');
    gallery.classList.remove('hidden');

    // Simular llamada a API
    const imageUrl = await simulateGeneration(prompt, selectedStyle);

    // Restaurar
    generateBtn.disabled = false;
    btnIcon.textContent = '✨';
    btnText.textContent = 'Generar';
    loader.classList.add('hidden');

    credits--;
    creditInfo.textContent = `Te quedan ${credits} créditos`;

    addImageToGallery(imageUrl, prompt, selectedStyle);
  });

  // ─── Simulación de IA ────────────────────────────────────

  async function simulateGeneration(prompt, style) {
    // Simular delay de generación (2-3 segundos)
    const delay = 2000 + Math.random() * 1000;
    await new Promise(r => setTimeout(r, delay));

    // Generar imagen placeholder con gradiente único basado en el prompt
    const seed = prompt.length + Math.floor(Math.random() * 10000);
    const hue1 = (seed * 37) % 360;
    const hue2 = (hue1 + 120 + (seed * 7) % 120) % 360;
    const hue3 = (hue2 + 90 + (seed * 13) % 90) % 360;

    const gradient = `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='400' height='300'%3E%3Cdefs%3E%3ClinearGradient id='g' x1='0%25' y1='0%25' x2='100%25' y2='100%25'%3E%3Cstop offset='0%25' stop-color='hsl(${hue1},70%25,50%25)'/%3E%3Cstop offset='50%25' stop-color='hsl(${hue2},70%25,40%25)'/%3E%3Cstop offset='100%25' stop-color='hsl(${hue3},70%25,30%25)'/%3E%3C/linearGradient%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.02' numOctaves='4'/%3E%3CfeColorMatrix type='saturate' values='0'/%3E%3C/filter%3E%3C/defs%3E%3Crect width='400' height='300' fill='url(%23g)'/%3E%3Crect width='400' height='300' fill='url(%23g)' opacity='0.9'/%3E%3Crect width='400' height='300' fill='black' filter='url(%23n)' opacity='0.3'/%3E%3Ctext x='200' y='160' text-anchor='middle' fill='white' font-size='14' font-family='Inter' opacity='0.6'%3E${escapeXml(prompt.slice(0, 40))}%3C/text%3E%3C/svg%3E")`;

    return gradient;
  }

  function escapeXml(str) {
    return str.replace(/&/g, '%26').replace(/</g, '%3C').replace(/>/g, '%3E').replace(/"/g, '%22').replace(/'/g, '%27');
  }

  // ─── Renderizar imagen en galería ────────────────────────

  function addImageToGallery(imageUrl, prompt, style) {
    const labels = {
      realista: 'Realista',
      arte: 'Arte digital',
      animacion: 'Animación',
      vaporwave: 'Vaporwave',
      cyberpunk: 'Cyberpunk',
      minimalista: 'Minimalista'
    };

    const card = document.createElement('div');
    card.className = 'group relative rounded-2xl overflow-hidden border border-white/[0.06] bg-white/[0.02] animate-fade-in-up';
    card.style.animation = 'fadeInUp 0.4s ease-out forwards';

    card.innerHTML = `
      <div class="aspect-[4/3] w-full" style="background: ${imageUrl}; background-size: cover; background-position: center;"></div>
      <div class="absolute inset-0 bg-gradient-to-t from-[#0a0a0f] via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-all duration-300">
        <div class="absolute bottom-0 left-0 right-0 p-4">
          <span class="text-xs px-2 py-1 rounded-full bg-violet-500/20 text-violet-300 font-medium">${labels[style] || style}</span>
          <p class="text-sm text-white/70 mt-2 line-clamp-2">${prompt}</p>
        </div>
      </div>
      <button class="absolute top-3 right-3 w-8 h-8 rounded-full bg-white/[0.08] hover:bg-white/[0.15] flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all text-xs" title="Descargar">
        ⬇
      </button>
    `;

    galleryGrid.prepend(card);

    // Scroll suave a la imagen nueva
    setTimeout(() => card.scrollIntoView({ behavior: 'smooth', block: 'nearest' }), 100);
  }

  // ─── Limpiar galería ─────────────────────────────────────

  clearBtn?.addEventListener('click', () => {
    galleryGrid.innerHTML = '';
    gallery.classList.add('hidden');
  });

  // ─── Enter para generar ──────────────────────────────────

  promptInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      generateBtn.click();
    }
  });

});