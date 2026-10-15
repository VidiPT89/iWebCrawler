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
  // The app listens through WebKit; the browser extension installs its own receiver first.
  const send = window.__crawlerSend || (message => window.webkit?.messageHandlers?.crawler?.postMessage(message));
  function post(kind, data) { send({ kind, ...data }); }
  // Order matters: PubMed Central before PubMed, DOI before everything that may quote one.
  const RULES = [
    ['DOI', /doi\.org\/|\bdoi:|10\.\d{4,9}\//i],
    ['PMC', /\/pmc\/|pmc\.ncbi|\bPMC\s?\d{4,}/i],
    ['PMID', /pubmed|\bPMID\b/i],
    ['arXiv', /arxiv\.org|\barXiv:/i],
    ['Bibcode', /bibcode|adsabs\.harvard/i],
    ['ISBN', /\bisbn\b|booksources/i],
    ['ISSN', /\bissn\b/i],
    ['S2CID', /semanticscholar\.org|\bS2CID\b/i],
    ['OCLC', /worldcat\.org\/(?:oclc|title)|\bOCLC\b/i],
    ['hdl', /hdl\.handle\.net|\bhdl:/i]
  ];
  function classify(a) {
    const text = a.href + ' ' + label(a);
    return RULES.find(([, pattern]) => pattern.test(text))?.[0] ?? 'Link';
  }

  // The highlight effect: identifiers jump off the page in bright colours and mixed typefaces,
  // some inside solid blocks or turned on their side, with a wide beam from the spider.
  const inks = ['#ff2bd6', '#3ee0ff', '#ffc83d', '#ff7a1a', '#8f7bff', '#4dff9a'];
  const faces = ['"Courier New", ui-monospace, monospace', 'Georgia, "Times New Roman", serif', '"Helvetica Neue", Arial, sans-serif'];
  const any = list => list[Math.floor(Math.random() * list.length)];
  let layer = null;
  function overlay() {
    if (layer?.isConnected) return layer;
    layer = document.createElement('div');
    layer.setAttribute('aria-hidden', 'true');
    layer.style.cssText = 'position:absolute;left:0;top:0;width:0;height:0;overflow:visible;pointer-events:none;z-index:2147483646';
    document.documentElement.appendChild(layer);
    return layer;
  }
  function highlight(a, type, tone) {
    const reference = type !== 'Link', ink = reference ? any(inks) : tone;
    a.style.outline = `${reference ? 2 : 1}px solid ${ink}`;
    a.style.outlineOffset = '3px';
    a.style.borderRadius = '3px';
    a.style.backgroundColor = ink + (reference ? '33' : '28');
    if (reference) { a.style.color = ink; a.style.fontFamily = any(faces); }
    if (reduced() || (!reference && Math.random() > 0.4)) return;
    const r = a.getBoundingClientRect(), left = r.left + (window.scrollX || 0), top = r.top + (window.scrollY || 0);
    const face = any(faces), block = reference && Math.random() < 0.35;
    const size = reference ? 18 + Math.random() * 24 : 14 + Math.random() * 12;
    const turn = reference && Math.random() < 0.2 ? any([-90, 90]) : Math.random() * 8 - 4;
    const word = document.createElement('span');
    const text = label(a), tagged = reference && !text.toLowerCase().includes(type.toLowerCase());
    word.textContent = (tagged ? `${type} ${text}` : text).slice(0, 36);
    word.style.cssText = `position:absolute;left:${left + (Math.random() * 40 - 10)}px;top:${top - size * 1.1 - Math.random() * 8}px;white-space:nowrap;font:600 ${size}px ${face};` +
      `color:${block ? '#111' : ink};background:${block ? ink : 'transparent'};padding:${block ? '1px 10px' : '0'};` +
      `text-shadow:${block ? 'none' : `0 0 14px ${ink}aa`};transform-origin:left center;transform:rotate(${turn}deg);opacity:0`;
    const layerNow = overlay();
    layerNow.appendChild(word);
    while (layerNow.childElementCount > 18) layerNow.firstElementChild.remove();
    const spin = `rotate(${turn}deg)`;
    word.animate([
      { opacity: 0, transform: `${spin} scale(.25)` },
      { opacity: 1, transform: `${spin} scale(1.18)`, offset: 0.2 },
      { opacity: 1, transform: `${spin} scale(1)`, offset: 0.35 },
      { opacity: 0.9, transform: `${spin} translateY(-6px) scale(1)`, offset: 0.8 },
      { opacity: 0, transform: `${spin} translateY(-10px) scale(.96)` }
    ], { duration: reference ? 5200 : 3200, easing: 'cubic-bezier(.2,.8,.2,1)', fill: 'forwards' }).onfinish = () => word.remove();
    if (!reference) return;
    // A wide translucent beam from the spider to the identifier.
    const fromX = x + (window.scrollX || 0), fromY = y + (window.scrollY || 0), toX = left + r.width / 2, toY = top + r.height / 2;
    const length = Math.hypot(toX - fromX, toY - fromY), angle = Math.atan2(toY - fromY, toX - fromX) * 180 / Math.PI;
    const beam = document.createElement('div');
    beam.style.cssText = `position:absolute;left:${fromX}px;top:${fromY - 11}px;width:${Math.max(40, length)}px;height:22px;` +
      `background:linear-gradient(90deg, ${ink}00, ${ink}cc 30%, ${ink}aa);transform-origin:left center;transform:rotate(${angle}deg);mix-blend-mode:screen;opacity:0`;
    layerNow.appendChild(beam);
    beam.animate([{ opacity: 0, transform: `rotate(${angle}deg) scaleX(.1)` }, { opacity: 0.85, transform: `rotate(${angle}deg) scaleX(1)`, offset: 0.25 }, { opacity: 0, transform: `rotate(${angle}deg) scaleX(1)` }],
      { duration: 1100, easing: 'ease-out', fill: 'forwards' }).onfinish = () => beam.remove();
  }
  function pick() {
    if (index >= links.length) { running = false; post('complete', {}); return; }
    target = links[index++];
    target.scrollIntoView({ behavior: reduced() ? 'instant' : 'smooth', block: 'center' });
    const type = classify(target);
    post('progress', { scanned: index });
    if (!scanned.has(target.href)) {
      scanned.add(target.href);
      post('link', { url: target.href, title: label(target).slice(0, 200), type });
    }
    try { highlight(target, type, palette[index % palette.length]); } catch {}
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
