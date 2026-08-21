// Minimal service worker for PWA installability.
//
// Flutter's generated `flutter_service_worker.js` is now a stub whose only job
// is to call `self.registration.unregister()` — it ships no fetch handler, so
// after its first activation the site has no service worker at all and Chrome
// will not offer to install the app. This one is registered separately (its own
// registration, unaffected by Flutter's self-unregister) purely to satisfy that
// requirement.
//
// It deliberately does NOT cache app code. Caching `main.dart.js` /
// `flutter_bootstrap.js` here is what produces "the web app is stale" bugs; the
// network is the source of truth and the hosting cache headers do the rest.

const OFFLINE_MESSAGE =
  '<!doctype html><meta charset="utf-8">' +
  '<title>GreenGo — offline</title>' +
  '<body style="margin:0;display:grid;place-items:center;height:100vh;' +
  'background:#0A0A0A;color:#fff;font:16px system-ui,sans-serif">' +
  '<p>You are offline. Reconnect to continue.</p>';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

// Network-first, no cache writes. Navigations fall back to a tiny inline page
// when the network is unreachable so the app shell never shows a browser error.
self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request).catch(
        () =>
          new Response(OFFLINE_MESSAGE, {
            headers: { 'Content-Type': 'text/html; charset=utf-8' },
          }),
      ),
    );
    return;
  }

  event.respondWith(fetch(request));
});
