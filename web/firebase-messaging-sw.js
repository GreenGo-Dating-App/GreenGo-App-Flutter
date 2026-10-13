/* GreenGo — Firebase Cloud Messaging service worker (web push).
 *
 * Served at the site root so the firebase_messaging web plugin auto-registers
 * it (scope /firebase-cloud-messaging-push-scope). Foreground pushes are also
 * forwarded to open windows, where PushNotificationService plays the in-app
 * sound.
 *
 * The Firebase web config is NOT stored in git: `firebase-config.js` (next to
 * this file) is generated at build time from lib/firebase_options.dart by
 * tools/web/generate_firebase_config.py (run via tools/web/build_web.sh).
 *
 * WHY THIS FILE HANDLES `push` ITSELF (iPhone / iPad / Safari web push):
 *
 *   The Firebase SDK's own push handler shows NOTHING when any app window is
 *   "visible": it only postMessage()s the payload to the page. Safari
 *   (iOS/iPadOS home-screen apps and macOS) does not allow silent web push.
 *   Every push event must show a notification, and after a few pushes that
 *   do not, Safari REVOKES the push subscription. FCM then reports the token
 *   as "registration-token-not-registered", the server clears users/{uid}.
 *   fcmToken, and the PWA gets no more notifications. Chatting with the PWA
 *   open (messages arriving while the window is visible) set this off, so
 *   iOS push "worked, then stopped".
 *
 *   The SDK also showed a notification for `notification` payloads AND called
 *   onBackgroundMessage, which showed a second one (duplicate notifications).
 *
 *   This listener is registered BEFORE firebase.messaging() adds the SDK's,
 *   and stops the SDK listener from running (stopImmediatePropagation), so
 *   exactly one notification is shown per push:
 *     - Apple WebKit: ALWAYS shown, even with the app open (required to keep
 *       the subscription), and the payload is still forwarded to open windows.
 *     - Other browsers: unchanged behaviour. With a visible window the payload
 *       goes to the page only (Chrome/Firefox permit that). Otherwise one
 *       notification is shown.
 *   See firebase/firebase-js-sdk#8010 and WebKit's userVisibleOnly rule.
 */
'use strict';

// -- pure helpers (exported on self.GreenGoPushSw for tools/web tests) -----

/** Safari / any iOS-iPadOS browser: silent push revokes the subscription. */
function ggIsAppleWebKit(userAgent) {
  var ua = String(userAgent || '');
  if (!/(iPhone|iPad|iPod|Macintosh)/.test(ua)) return false;
  // Desktop Chrome/Edge/Firefox/Opera on a Mac are not WebKit push.
  // (On iOS every browser is WebKit, and their tokens like CriOS/FxiOS differ.)
  return !/(Chrome|Chromium|Firefox|Edg|OPR)\//.test(ua);
}

/** Parses the FCM push body (JSON) or returns null. */
function ggParsePayload(event) {
  if (!event || !event.data) return null;
  try {
    return event.data.json();
  } catch (e) {
    return null;
  }
}

/** Title/options for showNotification() from an FCM payload. */
function ggNotificationFor(payload) {
  var p = payload || {};
  var n = p.notification || {};
  var data = p.data || {};
  var title = n.title || data.title || data.senderName || 'GreenGo';
  var body = n.body || data.body || data.message || '';
  var tag = data.conversationId || p.collapse_key || p.collapseKey || undefined;
  var options = {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: { gg: true, data: data, link: (p.fcmOptions && p.fcmOptions.link) || '/' },
  };
  if (n.image) options.image = n.image;
  if (tag) {
    // One entry per conversation, but still alert for every new message.
    options.tag = String(tag);
    options.renotify = true;
  }
  return { title: title, options: options };
}

/** Message the Firebase window SDK turns into FirebaseMessaging.onMessage. */
function ggWindowMessage(payload) {
  var msg = Object.assign({}, payload || {});
  msg.isFirebaseMessaging = true;
  msg.messageType = 'push-received';
  return msg;
}

function ggHasVisibleWindow(clientList) {
  return (clientList || []).some(function (c) {
    return c && c.visibilityState === 'visible' &&
      !String(c.url || '').startsWith('chrome-extension://');
  });
}

/**
 * Decides and performs what one push does. Returns a promise that
 * resolves once the notification is shown and/or the windows are told.
 */
function ggHandlePush(scope, payload) {
  return scope.clients
    .matchAll({ type: 'window', includeUncontrolled: true })
    .then(function (clientList) {
      var visible = ggHasVisibleWindow(clientList);
      var apple = ggIsAppleWebKit(scope.navigator && scope.navigator.userAgent);
      if (visible) {
        var msg = ggWindowMessage(payload);
        clientList.forEach(function (c) {
          try { c.postMessage(msg); } catch (e) {}
        });
        if (!apple) return undefined; // the page handles it (in-app sound)
      }
      var n = ggNotificationFor(payload);
      return scope.registration.showNotification(n.title, n.options);
    });
}

self.GreenGoPushSw = {
  isAppleWebKit: ggIsAppleWebKit,
  notificationFor: ggNotificationFor,
  windowMessage: ggWindowMessage,
  hasVisibleWindow: ggHasVisibleWindow,
  handlePush: ggHandlePush,
};

// -- push: registered FIRST so it runs before (and instead of) the SDK's ----
self.addEventListener('push', function (event) {
  var payload = ggParsePayload(event);
  if (!payload) return; // not an FCM push: leave it to other listeners
  event.stopImmediatePropagation();
  event.waitUntil(
    ggHandlePush(self, payload).catch(function (e) {
      // Last resort: Safari still needs a visible notification.
      console.error('[GreenGo SW] push handling failed', e);
      return self.registration.showNotification('GreenGo', {
        icon: '/icons/Icon-192.png',
      });
    }),
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var d = event.notification.data || {};
  var link = (d && d.link) || '/';
  // Focus an existing app window if one is open, otherwise open the app.
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
      for (var i = 0; i < clientList.length; i++) {
        if ('focus' in clientList[i]) return clientList[i].focus();
      }
      if (clients.openWindow) return clients.openWindow(link);
      return undefined;
    }),
  );
});

// -- Firebase SDK: kept for token lifecycle (pushsubscriptionchange) --------
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

importScripts('firebase-config.js'); // defines self.GREENGO_FIREBASE_CONFIG

if (!self.GREENGO_FIREBASE_CONFIG || !self.GREENGO_FIREBASE_CONFIG.apiKey) {
  // Build was made without tools/web/build_web.sh: web push cannot work.
  console.error('[GreenGo SW] firebase-config.js missing - web push disabled');
}
firebase.initializeApp(self.GREENGO_FIREBASE_CONFIG || {});

// Registers the SDK's push / notificationclick / pushsubscriptionchange
// listeners. Its push listener never runs for FCM pushes (see above), and its
// notificationclick ignores notifications it did not create. No
// onBackgroundMessage handler: that is what produced the duplicate.
firebase.messaging();
