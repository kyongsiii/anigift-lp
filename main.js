import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
gsap.registerPlugin(ScrollTrigger);

/* ===== NAV ===== */
const navbar = document.getElementById('navbar');
const hamburger = document.getElementById('hamburger');
const mobileOverlay = document.getElementById('mobileOverlay');

window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 60);
});

hamburger?.addEventListener('click', () => {
  hamburger.classList.toggle('active');
  mobileOverlay.classList.toggle('active');
  document.body.style.overflow = mobileOverlay.classList.contains('active') ? 'hidden' : '';
});

mobileOverlay?.querySelectorAll('a').forEach(a => {
  a.addEventListener('click', () => {
    hamburger.classList.remove('active');
    mobileOverlay.classList.remove('active');
    document.body.style.overflow = '';
  });
});

/* ===== PARTICLES ===== */
const canvas = document.getElementById('particles');
if (canvas) {
  const ctx = canvas.getContext('2d');
  let w, h;
  const particles = [];
  const PARTICLE_COUNT = 65;

  function resize() {
    const hero = document.getElementById('hero');
    w = canvas.width = hero.offsetWidth;
    h = canvas.height = hero.offsetHeight;
  }

  class Particle {
    constructor() { this.reset(); }
    reset() {
      this.x = Math.random() * w;
      this.y = Math.random() * h;
      this.r = Math.random() * 2 + 0.5;
      this.vx = (Math.random() - 0.5) * 0.3;
      this.vy = (Math.random() - 0.5) * 0.3 - 0.15;
      this.alpha = Math.random() * 0.4 + 0.1;
      const colors = ['255,45,120', '255,184,0', '139,92,246'];
      this.color = colors[Math.floor(Math.random() * colors.length)];
    }
    update() {
      this.x += this.vx;
      this.y += this.vy;
      if (this.x < 0 || this.x > w || this.y < 0 || this.y > h) this.reset();
    }
    draw() {
      ctx.beginPath();
      ctx.arc(this.x, this.y, this.r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(${this.color},${this.alpha})`;
      ctx.fill();
    }
  }

  function init() {
    resize();
    for (let i = 0; i < PARTICLE_COUNT; i++) particles.push(new Particle());
  }

  function animate() {
    ctx.clearRect(0, 0, w, h);
    particles.forEach(p => { p.update(); p.draw(); });
    for (let i = 0; i < particles.length; i++) {
      for (let j = i + 1; j < particles.length; j++) {
        const dx = particles[i].x - particles[j].x;
        const dy = particles[i].y - particles[j].y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 120) {
          ctx.beginPath();
          ctx.moveTo(particles[i].x, particles[i].y);
          ctx.lineTo(particles[j].x, particles[j].y);
          ctx.strokeStyle = `rgba(255,45,120,${0.04 * (1 - dist / 120)})`;
          ctx.lineWidth = 0.5;
          ctx.stroke();
        }
      }
    }
    requestAnimationFrame(animate);
  }

  init();
  animate();
  window.addEventListener('resize', resize);
}

/* ===== HERO GSAP ===== */
const heroTl = gsap.timeline({ defaults: { ease: 'power3.out' } });

heroTl
  .from('.h1-line[data-anim="1"]', { y: 60, opacity: 0, duration: 0.9, clearProps: 'all' })
  .from('.h1-line[data-anim="2"]', { y: 60, opacity: 0, duration: 0.9, clearProps: 'all' }, '-=0.5')
  .from('.hero-sub', { y: 30, opacity: 0, duration: 0.7, clearProps: 'all' }, '-=0.4')
  .from('.hero-cta', { y: 30, opacity: 0, scale: 0.9, duration: 0.6, clearProps: 'all' }, '-=0.3')
  .from('.ticker', { opacity: 0, y: 20, duration: 0.6, clearProps: 'all' }, '-=0.4')
  .from('.obj', { scale: 0, opacity: 0, duration: 0.6, stagger: 0.08, clearProps: 'all' }, '-=0.5');

/* ===== SCROLL REVEAL ===== */
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('revealed');
      revealObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.15 });

document.querySelectorAll('[data-reveal]').forEach(el => revealObserver.observe(el));

/* ===== ABOUT CARDS STAGGER ===== */
gsap.utils.toArray('.about-card').forEach((card, i) => {
  gsap.from(card, {
    scrollTrigger: {
      trigger: card,
      start: 'top 85%',
      toggleActions: 'play none none none',
    },
    y: 50,
    opacity: 0,
    scale: 0.9,
    duration: 0.7,
    delay: i * 0.15,
    ease: 'power3.out',
    clearProps: 'all',
  });
});

/* ===== GALLERY CARDS STAGGER ===== */
gsap.utils.toArray('.gallery-card').forEach((card, i) => {
  gsap.from(card, {
    scrollTrigger: {
      trigger: card,
      start: 'top 85%',
      toggleActions: 'play none none none',
    },
    y: 60,
    opacity: 0,
    duration: 0.7,
    delay: i * 0.12,
    ease: 'power3.out',
    clearProps: 'all',
  });
});

/* ===== GALLERY VIDEO LAZY LOAD (WebView compatible) ===== */
const galleryVideos = document.querySelectorAll('.gallery-video[data-src]');

function hidePlayBtn(video) {
  const btn = video.parentElement.querySelector('.gallery-play-btn');
  if (btn) btn.classList.add('hidden');
}

function loadAndPlay(video) {
  const src = video.dataset.src;
  if (src && !video.src.includes(src)) {
    video.src = src;
    video.load();
  }
  const playPromise = video.play();
  if (playPromise) {
    playPromise.then(() => hidePlayBtn(video)).catch(() => {
      // Autoplay blocked (WebView) - keep play button visible
    });
  }
}

// Lazy load via IntersectionObserver
const videoObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      loadAndPlay(entry.target);
      videoObserver.unobserve(entry.target);
    }
  });
}, { rootMargin: '200px' });

galleryVideos.forEach(v => videoObserver.observe(v));

// Play button click handler (works in WebView because it's a user gesture)
document.querySelectorAll('.gallery-play-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const video = btn.parentElement.querySelector('.gallery-video');
    if (video) {
      loadAndPlay(video);
      hidePlayBtn(video);
    }
  });
});

/* ===== VIDEO DOWNLOAD PROTECTION ===== */
document.querySelectorAll('.gallery-video').forEach(video => {
  video.setAttribute('controlsList', 'nodownload');
  video.addEventListener('contextmenu', e => e.preventDefault());
  video.addEventListener('dragstart', e => e.preventDefault());
});

/* ===== STEPS STAGGER ===== */
gsap.utils.toArray('.step').forEach((step, i) => {
  gsap.from(step, {
    scrollTrigger: {
      trigger: step,
      start: 'top 85%',
      toggleActions: 'play none none none',
    },
    y: 50,
    opacity: 0,
    scale: 0.95,
    duration: 0.6,
    delay: i * 0.1,
    ease: 'power3.out',
  });
});

/* ===== PRICING CARDS STAGGER ===== */
gsap.utils.toArray('.pricing-card').forEach((card, i) => {
  gsap.from(card, {
    scrollTrigger: {
      trigger: card,
      start: 'top 85%',
      toggleActions: 'play none none none',
    },
    y: 60,
    opacity: 0,
    scale: 0.95,
    duration: 0.7,
    delay: i * 0.1,
    ease: 'power3.out',
    clearProps: 'all',
  });
});

/* ===== PARALLAX BG TEXT ===== */
gsap.utils.toArray('.bg-text').forEach(bgText => {
  gsap.to(bgText, {
    scrollTrigger: {
      trigger: bgText.parentElement,
      start: 'top bottom',
      end: 'bottom top',
      scrub: 1,
    },
    y: -80,
    ease: 'none',
  });
});

/* ===== GLOW ORB PARALLAX ===== */
gsap.utils.toArray('.glow-orb').forEach(orb => {
  gsap.to(orb, {
    scrollTrigger: {
      trigger: orb.parentElement,
      start: 'top bottom',
      end: 'bottom top',
      scrub: 1.5,
    },
    y: -60,
    x: 30,
    ease: 'none',
  });
});

/* ===== TICKER MID ENTRANCE ===== */
gsap.utils.toArray('.ticker--mid').forEach(ticker => {
  gsap.from(ticker, {
    scrollTrigger: {
      trigger: ticker,
      start: 'top 95%',
      toggleActions: 'play none none none',
    },
    scaleX: 0.8,
    opacity: 0,
    duration: 0.8,
    ease: 'power3.out',
    clearProps: 'opacity,transform',
  });
});

/* ===== FAQ ACCORDION ===== */
document.querySelectorAll('.faq-item').forEach(item => {
  item.addEventListener('toggle', () => {
    if (item.open) {
      document.querySelectorAll('.faq-item').forEach(other => {
        if (other !== item && other.open) other.open = false;
      });
    }
  });
});

/* ===== CTA SECTION ENTRANCE ===== */
gsap.from('.aud-content', {
  scrollTrigger: {
    trigger: '#cta',
    start: 'top 60%',
    toggleActions: 'play none none none',
  },
  y: 80,
  opacity: 0,
  duration: 1,
  ease: 'power3.out',
});

gsap.from('.aud-bg-text', {
  scrollTrigger: {
    trigger: '#cta',
    start: 'top bottom',
    end: 'bottom top',
    scrub: 1,
  },
  x: -100,
  ease: 'none',
});

/* ===== CURSOR GLOW ===== */
const cursorGlow = document.createElement('div');
cursorGlow.classList.add('cursor-glow');
document.body.appendChild(cursorGlow);

let mouseX = -200, mouseY = -200;
let glowX = -200, glowY = -200;

document.addEventListener('mousemove', (e) => {
  mouseX = e.clientX;
  mouseY = e.clientY;
});

function updateGlow() {
  glowX += (mouseX - glowX) * 0.08;
  glowY += (mouseY - glowY) * 0.08;
  cursorGlow.style.transform = `translate(${glowX - 200}px, ${glowY - 200}px)`;
  requestAnimationFrame(updateGlow);
}
updateGlow();

/* ===== SCROLL PROGRESS BAR ===== */
const progressBar = document.createElement('div');
progressBar.classList.add('scroll-progress');
document.body.appendChild(progressBar);

window.addEventListener('scroll', () => {
  const scrolled = window.scrollY / (document.body.scrollHeight - window.innerHeight);
  progressBar.style.transform = `scaleX(${scrolled})`;
}, { passive: true });
