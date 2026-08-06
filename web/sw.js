/* Service Worker des Telegram Monitor Companion.
 *
 * Grundregel: Die Hülle (Seite, Symbole, Manifest) darf aus dem Zwischenspeicher
 * kommen, damit die App auch ohne laufenden Server startet und etwas Sinnvolles
 * zeigt. Alles unter /api/ kommt IMMER frisch vom Server — Statusdaten aus dem
 * Zwischenspeicher wären schlimmer als gar keine.
 */

const CACHE = 'tmc-v1';
const SHELL = [
  '/',
  '/manifest.webmanifest',
  '/icons/monitor-192.png',
  '/icons/monitor-512.png'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(SHELL))
      .catch(() => {})          // einzelne fehlende Datei darf die Installation nicht kippen
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET' || url.origin !== location.origin) return;

  // Statusdaten niemals aus dem Zwischenspeicher.
  if (url.pathname.startsWith('/api/')) return;

  // Hülle: erst Netz, sonst Zwischenspeicher (so bleibt sie aktuell).
  e.respondWith(
    fetch(e.request)
      .then(r => {
        const copy = r.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
        return r;
      })
      .catch(() => caches.match(e.request).then(r => r || caches.match('/')))
  );
});

/* Meldung beim Livegang: die Seite schickt sie herüber, der Worker zeigt sie
   an — so erscheint sie auch, wenn das Fenster nicht im Vordergrund ist. */
self.addEventListener('message', e => {
  const d = e.data;
  if (!d || d.type !== 'live') return;
  self.registration.showNotification(d.title || 'Livegang', {
    body: d.body || '',
    icon: '/icons/monitor-192.png',
    badge: '/icons/monitor-192.png',
    tag: d.tag || 'tmc-live',
    data: { url: d.url || '/' }
  });
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  const target = (e.notification.data && e.notification.data.url) || '/';
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      for (const c of list) if ('focus' in c) return c.focus();
      return clients.openWindow(target);
    })
  );
});
