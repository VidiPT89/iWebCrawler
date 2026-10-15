const api = globalThis.browser ?? globalThis.chrome;

const TEXT = {
  'pt-PT': {
    settings: 'Definições', language: 'Idioma', appearance: 'Aparência', system: 'Sistema', light: 'Claro', dark: 'Escuro',
    speed: 'Velocidade', reducedMotion: 'Reduzir movimento', developedBy: 'Desenvolvido por',
    links: ['ligação', 'ligações'], references: ['referência', 'referências'],
    explore: 'Explorar', pause: 'Pausar', resume: 'Retomar', restart: 'Recomeçar',
    ready: 'Pronto para explorar', scanning: 'A seguir o fio', paused: 'Exploração em pausa', complete: 'Exploração concluída',
    noLinks: 'Sem ligações nesta página', all: 'Tudo', copy: 'Copiar', copied: 'Copiado',
    empty: 'Carrega em Explorar: a aranha percorre esta página e cada ligação encontrada aparece aqui.',
    blocked: 'Esta página está protegida pelo browser (páginas internas e lojas de extensões). Abre um site normal para explorar.'
  },
  en: {
    settings: 'Settings', language: 'Language', appearance: 'Appearance', system: 'System', light: 'Light', dark: 'Dark',
    speed: 'Speed', reducedMotion: 'Reduce motion', developedBy: 'Developed by',
    links: ['link', 'links'], references: ['reference', 'references'],
    explore: 'Explore', pause: 'Pause', resume: 'Resume', restart: 'Explore again',
    ready: 'Ready to explore', scanning: 'Following the thread', paused: 'Exploration paused', complete: 'Exploration complete',
    noLinks: 'No links on this page', all: 'All', copy: 'Copy', copied: 'Copied',
    empty: 'Choose Explore: the spider walks through this page and every link it finds appears here.',
    blocked: 'The browser protects this page (internal pages and extension stores). Open a regular website to explore it.'
  }
};
const TYPES = ['DOI', 'PMID', 'PMC', 'ISBN', 'ISSN', 'Bibcode', 'arXiv', 'S2CID', 'OCLC', 'hdl', 'Link'];
const $ = id => document.getElementById(id);
let prefs = { language: navigator.language?.toLowerCase().startsWith('pt') ? 'pt-PT' : 'en', theme: 'system', speed: 1, reducedMotion: false };
let tab = null, state = null, filter = 'All', blocked = false;

const t = key => TEXT[prefs.language][key];
const plural = (n, key) => t(key)[n === 1 ? 0 : 1];

async function inject(func, args = []) {
  const [result] = await api.scripting.executeScript({ target: { tabId: tab.id }, func, args });
  return result?.result ?? null;
}
// Runs in the page: returns the collection, injecting the bridge and the spider on first use.
async function connect() {
  const existing = await inject(() => globalThis.__iwcSnapshot?.() ?? null);
  if (existing) return existing;
  await api.scripting.executeScript({ target: { tabId: tab.id }, files: ['bridge.js', 'spider.js'] });
  return inject(() => globalThis.__iwcSnapshot?.() ?? null);
}
function command(action, options) {
  const crawler = globalThis.__crawler, state = globalThis.__iwc;
  if (!crawler || !state) return null;
  crawler.configure(options);
  if (action === 'start') { state.phase = 'scanning'; crawler.start(); }
  if (action === 'pause') { state.phase = 'paused'; crawler.pause(); }
  return globalThis.__iwcSnapshot();
}

function applyPrefs() {
  document.documentElement.lang = prefs.language;
  if (prefs.theme === 'system') delete document.documentElement.dataset.theme;
  else document.documentElement.dataset.theme = prefs.theme;
  document.querySelectorAll('[data-text]').forEach(el => { const value = t(el.dataset.text); if (typeof value === 'string') el.textContent = value; });
  $('settings-toggle').setAttribute('aria-label', t('settings'));
  $('language').value = prefs.language; $('theme').value = prefs.theme;
  $('speed').value = String(prefs.speed); $('reduced-motion').checked = prefs.reducedMotion;
  render();
}
function options() {
  return { speed: Number(prefs.speed), reducedMotion: prefs.reducedMotion, language: prefs.language, dark: false };
}

function render() {
  const links = state?.links ?? [];
  const refs = links.filter(link => link.type !== 'Link').length;
  $('links-count').textContent = links.length; $('links-label').textContent = plural(links.length, 'links');
  $('refs-count').textContent = refs; $('refs-label').textContent = plural(refs, 'references');
  const phase = state?.phase ?? 'ready', total = state?.total ?? 0, scanned = state?.scanned ?? 0;
  $('status').textContent = blocked ? '' : phase === 'ready' && state && total === 0 ? t('noLinks') : t(phase);
  $('progress-text').textContent = `${scanned} / ${total}`;
  const percent = total ? Math.round(Math.min(1, scanned / total) * 100) : 0;
  $('bar').style.width = percent + '%'; $('bar').parentElement.setAttribute('aria-valuenow', percent);
  const toggle = $('toggle');
  toggle.disabled = blocked || !state || total === 0;
  $('toggle-label').textContent = phase === 'scanning' ? t('pause') : phase === 'paused' ? t('resume') : phase === 'complete' ? t('restart') : t('explore');
  $('notice').hidden = !blocked; $('notice').textContent = blocked ? t('blocked') : '';

  const present = ['All', ...TYPES.filter(type => links.some(link => link.type === type))];
  if (!present.includes(filter)) filter = 'All';
  $('filters').replaceChildren(...(links.length ? present : []).map(type => {
    const button = document.createElement('button');
    button.type = 'button'; button.textContent = type === 'All' ? t('all') : type;
    button.setAttribute('aria-pressed', String(type === filter));
    button.addEventListener('click', () => { filter = type; render(); });
    return button;
  }));
  const visible = links.filter(link => filter === 'All' || link.type === filter).slice(-150).reverse();
  $('list').replaceChildren(...visible.map(link => {
    const item = document.createElement('li'), anchor = document.createElement('a');
    anchor.href = link.url; anchor.target = '_blank'; anchor.rel = 'noopener';
    const type = document.createElement('span'); type.className = 'type'; type.textContent = link.type.toUpperCase();
    const title = document.createElement('span'); title.className = 'title'; title.textContent = link.title;
    const host = document.createElement('span'); host.className = 'host';
    try { host.textContent = new URL(link.url).host; } catch { host.textContent = link.url; }
    anchor.append(type, title, host); item.append(anchor); return item;
  }));
  $('empty').hidden = links.length > 0 || blocked;
  for (const id of ['export-json', 'export-csv', 'copy']) $(id).disabled = links.length === 0;
}

function exportData(kind) {
  const links = state?.links ?? [];
  if (kind === 'json') return JSON.stringify(links, null, 2);
  const field = value => '"' + String(value).replaceAll('"', '""') + '"';
  return ['title,url,type,page', ...links.map(l => [l.title, l.url, l.type, l.page].map(field).join(','))].join('\r\n') + '\r\n';
}
function download(kind) {
  const stamp = new Date().toISOString().replaceAll(':', '-').slice(0, 19);
  const blob = new Blob([exportData(kind)], { type: kind === 'json' ? 'application/json' : 'text/csv' });
  const anchor = Object.assign(document.createElement('a'), { href: URL.createObjectURL(blob), download: `iWebCrawler-${stamp}.${kind}` });
  document.body.append(anchor); anchor.click(); anchor.remove();
  setTimeout(() => URL.revokeObjectURL(anchor.href), 1000);
}

async function savePrefs(change) {
  prefs = { ...prefs, ...change };
  await api.storage.local.set({ prefs });
  applyPrefs();
  if (state && !blocked) state = await inject(command, ['configure', options()]) ?? state;
}

async function init() {
  const stored = await api.storage.local.get('prefs');
  prefs = { ...prefs, ...(stored?.prefs ?? {}) };
  // `?tab=<id>` opens the popup as a page for a given tab, which helps debugging and automated tests.
  const forced = Number(new URLSearchParams(location.search).get('tab'));
  tab = forced ? await api.tabs.get(forced) : (await api.tabs.query({ active: true, currentWindow: true }))[0];
  try { $('host').textContent = new URL(tab.url).host || tab.title || '—'; } catch { $('host').textContent = tab?.title ?? '—'; }
  try { state = await connect(); } catch { blocked = true; }
  applyPrefs();
  if (state) state = await inject(command, ['configure', options()]) ?? state;
  render();

  $('toggle').addEventListener('click', async () => {
    const action = state?.phase === 'scanning' ? 'pause' : 'start';
    state = await inject(command, [action, options()]) ?? state; render();
  });
  $('settings-toggle').addEventListener('click', () => {
    const panel = $('settings'); panel.hidden = !panel.hidden;
    $('settings-toggle').setAttribute('aria-expanded', String(!panel.hidden));
  });
  $('language').addEventListener('change', event => savePrefs({ language: event.target.value }));
  $('theme').addEventListener('change', event => savePrefs({ theme: event.target.value }));
  $('speed').addEventListener('change', event => savePrefs({ speed: Number(event.target.value) }));
  $('reduced-motion').addEventListener('change', event => savePrefs({ reducedMotion: event.target.checked }));
  $('export-json').addEventListener('click', () => download('json'));
  $('export-csv').addEventListener('click', () => download('csv'));
  $('copy').addEventListener('click', async () => {
    await navigator.clipboard.writeText(exportData('json'));
    $('copy').textContent = t('copied'); setTimeout(() => { $('copy').textContent = t('copy'); }, 1500);
  });
  api.runtime.onMessage.addListener((message, sender) => {
    if (message?.type === 'iwc-update' && sender.tab?.id === tab.id) { state = message.state; render(); }
  });
  // Some browsers deliver page messages to the popup unreliably, so it also asks while the spider walks.
  setInterval(async () => {
    if (state?.phase !== 'scanning' || blocked) return;
    try { state = await inject(() => globalThis.__iwcSnapshot?.() ?? null) ?? state; render(); } catch {}
  }, 1000);
}

if (typeof module !== 'undefined') module.exports = { TEXT, command };
else init();
