// ============================================================
// sw.js — Service Worker for ENSTP Campus Navigator
//
// Caches the core application shell + map data + room data so the
// app continues to work offline. Cache-busting is achieved by
// bumping CACHE_VERSION below (we use a date-based version string).
//
// Strategy:
//   - For navigation (HTML): network-first, fall back to cache.
//   - For static assets (CSS/JS/JSON/JPG/PNG/SVG): cache-first,
//     with a background update (stale-while-revalidate).
// ============================================================

const CACHE_VERSION = 'enstp-nav-v1.0.1-searchfix';
const CORE_ASSETS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './assets/css/styles.css',
  './assets/js/app.js',
  './assets/js/i18n.js',
  './assets/js/search.js',
  './assets/js/router.js',
  './assets/js/map.js',
  './assets/img/campus-map.jpg',
  './assets/img/icon-192.png',
  './assets/img/icon-512.png',
  './assets/img/favicon.svg',
  './data/map-graph.json',
  './data/rooms-data.json',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then(async (cache) => {
      // Use addAll — but ignore failure of individual assets so that
      // one missing file (e.g. a font fetch from Google) doesn't break the install.
      const results = await Promise.allSettled(CORE_ASSETS.map(u => cache.add(u)));
      const failed = results.filter(r => r.status === 'rejected');
      if (failed.length) {
        console.warn('[SW] Some assets failed to cache on install:', failed.map(f => f.reason && f.reason.message));
      }
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_VERSION).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // Only handle same-origin requests; let cross-origin (e.g. Google Fonts) go to network.
  if (url.origin !== self.location.origin) return;

  // Skip non-GET cross-origin requests
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return;

  // Navigation: network-first
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req).catch(() =>
        caches.match(req).then(r => r || caches.match('./index.html'))
      )
    );
    return;
  }

  // Static assets: stale-while-revalidate
  event.respondWith(
    caches.match(req).then(cached => {
      const fetchPromise = fetch(req).then(resp => {
        // only cache valid basic responses
        if (resp && resp.status === 200 && resp.type === 'basic') {
          const clone = resp.clone();
          caches.open(CACHE_VERSION).then(c => c.put(req, clone));
        }
        return resp;
      }).catch(() => cached);
      return cached || fetchPromise;
    })
  );
});
