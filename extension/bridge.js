// Runs in the extension's isolated world before spider.js. It keeps the page's collection so the
// popup can close and reopen without losing anything, and tells an open popup about every change.
(() => {
  if (globalThis.__iwc) return;
  const api = globalThis.browser ?? globalThis.chrome;
  const seen = new Set();
  const state = { phase: 'ready', scanned: 0, total: 0, page: location.href, title: document.title, links: [] };
  const snapshot = () => ({ ...state, links: state.links.slice() });
  const notify = () => {
    try { api?.runtime?.sendMessage({ type: 'iwc-update', state: snapshot() })?.catch?.(() => {}); } catch {}
  };
  globalThis.__iwc = state;
  globalThis.__iwcSnapshot = snapshot;
  globalThis.__crawlerSend = message => {
    if (message.kind === 'ready') state.total = message.count;
    else if (message.kind === 'progress') state.scanned = message.scanned;
    else if (message.kind === 'complete') state.phase = 'complete';
    else if (message.kind === 'link' && !seen.has(message.url)) {
      seen.add(message.url);
      state.links.push({ title: message.title, url: message.url, type: message.type, page: state.page });
    }
    notify();
  };
})();
