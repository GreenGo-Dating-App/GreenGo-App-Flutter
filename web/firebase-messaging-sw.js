/* GreenGo — Firebase Cloud Messaging service worker (web push).
 *
 * Served at the site root so the firebase_messaging web plugin auto-registers
 * it. Handles background/closed-tab notifications (foreground toasts are handled
 * in-app by PushNotificationService). The config below is the app's PUBLIC web
 * config (same values as firebase_options.dart) — not a secret.
 */
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAnH1YB5IRRdQnVauIA5JqEi-J5atEeBbE',
  authDomain: 'greengo-chat.firebaseapp.com',
  projectId: 'greengo-chat',
  messagingSenderId: '666632803027',
  appId: '1:666632803027:web:36045de58c58a60f9aba26',
});

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
