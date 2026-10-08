/* GreenGo — Firebase Cloud Messaging service worker (web push).
 *
 * Served at the site root so the firebase_messaging web plugin auto-registers
 * it. Handles background/closed-tab notifications (foreground toasts are handled
 * in-app by PushNotificationService).
 *
 * The Firebase web config is NOT stored in git: `firebase-config.js` (next to
 * this file) is generated at build time from lib/firebase_options.dart by
 * tools/web/generate_firebase_config.py (run via tools/web/build_web.sh).
 */
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

importScripts('firebase-config.js'); // defines self.GREENGO_FIREBASE_CONFIG

if (!self.GREENGO_FIREBASE_CONFIG || !self.GREENGO_FIREBASE_CONFIG.apiKey) {
  // Build was made without tools/web/build_web.sh: web push cannot work.
  console.error('[GreenGo SW] firebase-config.js missing - web push disabled');
}
firebase.initializeApp(self.GREENGO_FIREBASE_CONFIG || {});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const notification = message.notification || {};
  const title = notification.title || 'GreenGo';
  self.registration.showNotification(title, {
    body: notification.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: message.data || {},
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  // Focus an existing tab if open, otherwise open a new one.
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow('/');
    }),
  );
});
