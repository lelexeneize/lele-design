document.addEventListener('DOMContentLoaded', () => {

  // Smooth scroll para anchors
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      const href = this.getAttribute('href');
      if (href === "#") return;
      e.preventDefault();
      const target = document.querySelector(href);
      if (target) {
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });

  // Navbar transparente → sólido al hacer scroll
  const nav = document.querySelector('nav');
  let lastScroll = 0;

  window.addEventListener('scroll', () => {
    const currentScroll = window.pageYOffset;
    if (currentScroll > 100) {
      nav.classList.add('shadow-lg', 'shadow-violet-900/10');
    } else {
      nav.classList.remove('shadow-lg', 'shadow-violet-900/10');
    }
    lastScroll = currentScroll;
  });

  // Animación de aparición al hacer scroll (Intersection Observer)
  const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('animate-fade-in-up');
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  document.querySelectorAll('section > div > .grid > div, section > div > div > .grid > div').forEach(el => {
    el.style.opacity = '0';
    observer.observe(el);
  });

});