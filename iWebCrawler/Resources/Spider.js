(() => {
  if (window.__crawler) return;
  const palette = ['#f59e0b', '#ea580c', '#fbbf24', '#c87533'];
  const canvas = document.createElement('canvas');
  canvas.setAttribute('aria-hidden', 'true');
  canvas.style.cssText = 'position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:2147483647';
  document.documentElement.appendChild(canvas);
  const ctx = canvas.getContext('2d');
  let running = false, index = 0, last = 0, x = innerWidth / 2, y = innerHeight / 2;
  let target = null, scanned = new Set(), trails = [], frameID = null, lastFrame = 0;
  let options = { speed: 1, reducedMotion: false, language: 'en', dark: false };
  const reduced = () => options.reducedMotion || matchMedia('(prefers-reduced-motion: reduce)').matches;
  const label = a => (a.textContent.trim() || a.getAttribute('aria-label') || a.getAttribute('title') || a.querySelector('img[alt]')?.alt || '').trim();
  const links = Array.from(document.querySelectorAll('a[href]')).filter(a => {
    try { return /^https?:$/.test(new URL(a.href).protocol) && a.getClientRects().length && label(a); }
    catch { return false; }
  }).slice(0, 1500);
  function post(kind, data) { window.webkit?.messageHandlers?.crawler?.postMessage({ kind, ...data }); }
  function classify(a) {
    const text = a.href + ' ' + label(a);
    if (/doi\.org|10\.\d{4,9}\//i.test(text)) return 'DOI';
    if (/pubmed|PMID/i.test(text)) return 'PMID';
    if (/isbn|booksources/i.test(text)) return 'ISBN';
    if (/bibcode|adsabs\.harvard|ui\.adsabs/i.test(text)) return 'Bibcode';
    return 'Link';
  }
  function pick() {
    if (index >= links.length) { running = false; post('complete', {}); return; }
    target = links[index++];
    target.scrollIntoView({ behavior: reduced() ? 'instant' : 'smooth', block: 'center' });
    target.style.outline = `1px solid ${palette[index % palette.length]}`;
    target.style.outlineOffset = '3px';
    target.style.borderRadius = '3px';
    target.style.backgroundColor = palette[index % palette.length] + '28';
    post('progress', { scanned: index });
    if (!scanned.has(target.href)) {
      scanned.add(target.href);
      post('link', { url: target.href, title: label(target).slice(0, 200), type: classify(target) });
    }
  }
  function frame(t) {
    frameID = null;
    const d = devicePixelRatio || 1;
    if (canvas.width !== innerWidth * d || canvas.height !== innerHeight * d) {
      canvas.width = innerWidth * d; canvas.height = innerHeight * d;
      ctx.setTransform(d, 0, 0, d, 0, 0);
    }
    ctx.clearRect(0, 0, innerWidth, innerHeight);
    if (!running) return;
    if (t - last > 1100 / options.speed) { last = t; pick(); }
    if (!running || !target) return;
    const dt = Math.min(50, Math.max(1, t - lastFrame)); lastFrame = t;
    const r = target.getBoundingClientRect();
    const tx = Math.max(35, Math.min(innerWidth - 35, r.x + r.width / 2));
    const ty = Math.max(45, Math.min(innerHeight - 45, r.y + r.height / 2));
    const blend = reduced() ? 1 : 1 - Math.exp(-dt / 190);
    x += (tx - x) * blend; y += (ty - y) * blend;
    if (!reduced()) {
      trails.push({ x, y }); if (trails.length > 55) trails.shift();
      ctx.strokeStyle = '#d9770650'; ctx.lineWidth = 1;
      ctx.beginPath(); trails.forEach((p, i) => i ? ctx.lineTo(p.x, p.y) : ctx.moveTo(p.x, p.y)); ctx.stroke();
    }
    const scale = innerWidth < 500 ? 0.75 : 1;
    for (let i = 0; i < 8; i++) {
      const side = i < 4 ? -1 : 1, leg = i % 4;
      const a = links[Math.max(0, index - 3 + leg + (side > 0 ? 2 : 0)) % links.length];
      const ar = a?.getBoundingClientRect();
      const phase = reduced() ? 0 : Math.sin(t / 150 + i * 1.8) * 7;
      const desiredX = ar ? ar.x + (side > 0 ? ar.width : 0) : x + side * 110;
      const desiredY = ar ? ar.y + ar.height / 2 : y + (leg - 1.5) * 45;
      const footX = Math.max(6, Math.min(innerWidth - 6, x + Math.max(-190, Math.min(190, desiredX - x))));
      const footY = Math.max(6, Math.min(innerHeight - 6, y + Math.max(-180, Math.min(180, desiredY - y))));
      const kneeX = x + side * (47 + leg * 9) * scale;
      const kneeY = y + ((leg - 1.5) * 32 + phase) * scale;
      ctx.strokeStyle = palette[i % palette.length]; ctx.lineWidth = 1.6 * scale;
      ctx.beginPath(); ctx.moveTo(x + side * 8 * scale, y + (leg - 1.5) * 5 * scale);
      ctx.lineTo(kneeX, kneeY); ctx.lineTo(footX, footY); ctx.stroke();
      ctx.fillStyle = palette[i % palette.length]; ctx.beginPath(); ctx.arc(footX, footY, 2.6, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#ffedd5'; ctx.beginPath(); ctx.arc(kneeX, kneeY, 1.6, 0, Math.PI * 2); ctx.fill();
    }
    ctx.save(); ctx.translate(x, y); ctx.scale(scale, scale);
    ctx.shadowColor = '#ea580c'; ctx.shadowBlur = reduced() ? 0 : 16;
    ctx.fillStyle = '#1c1510'; ctx.strokeStyle = '#f59e0b'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.ellipse(0, 7, 11, 18, 0, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
    ctx.shadowBlur = 0; ctx.strokeStyle = '#ea580c';
    ctx.beginPath(); ctx.moveTo(0, -5); ctx.lineTo(0, 21); ctx.stroke();
    ctx.fillStyle = '#f59e0b'; ctx.beginPath(); ctx.arc(0, -13, 7, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#17110d'; [-3, 3].forEach(ex => { ctx.beginPath(); ctx.arc(ex, -15, 1.6, 0, Math.PI * 2); ctx.fill(); });
    ctx.restore();
    frameID = requestAnimationFrame(frame);
  }
  window.__crawler = {
    start() {
      if (running) return;
      if (index >= links.length) { index = 0; scanned.clear(); trails = []; }
      running = true; last = 0; lastFrame = 0;
      if (frameID === null) frameID = requestAnimationFrame(frame);
    },
    pause() { running = false; if (frameID !== null) cancelAnimationFrame(frameID); frameID = null; ctx.clearRect(0, 0, innerWidth, innerHeight); },
    configure(config) {
      options = { ...options, ...config };
      options.speed = Math.max(0.5, Math.min(4, Number(options.speed) || 1));
      if (document.documentElement.dataset.crawlerDemo === 'true') {
        document.documentElement.dataset.theme = options.dark ? 'dark' : 'light';
        document.documentElement.lang = options.language;
        document.querySelectorAll('[data-pt][data-en]').forEach(el => { el.textContent = options.language === 'pt-PT' ? el.dataset.pt : el.dataset.en; });
      }
    }
  };
  post('ready', { count: links.length });
})();
