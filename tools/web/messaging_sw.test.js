// Tests for web/firebase-messaging-sw.js push handling.
// Run: node --test tools/web/messaging_sw.test.js
//
// Loads the real service worker in a sandbox with fake `self`, `clients`,
// `registration` and Firebase SDK, then dispatches push events. Guards the
// iOS/Safari rule: every FCM push must show a notification there (a silent
// push gets the subscription revoked), exactly one notification per push, and
// the Firebase SDK's own push listener never runs.
'use strict';

const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const SW = fs.readFileSync(path.join(__dirname, '..', '..', 'web', 'firebase-messaging-sw.js'), 'utf8');

const IPHONE_PWA =
  'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148';
const MAC_SAFARI =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15';
const MAC_CHROME =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36';
const ANDROID_CHROME =
  'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Mobile Safari/537.36';

function loadSw({ userAgent, windows = [] }) {
  const listeners = {};
  const shown = [];
  const posted = [];
  let sdkPushCalls = 0;
  const clientList = windows.map((w) => ({
    visibilityState: w.visible ? 'visible' : 'hidden',
    url: 'https://greengo-chat.web.app/',
    postMessage: (m) => posted.push(m),
    focus: () => Promise.resolve(),
  }));
  const clients = {
    matchAll: () => Promise.resolve(clientList),
    openWindow: () => Promise.resolve(),
  };
  const self = {
    navigator: { userAgent },
    clients,
    registration: {
      showNotification: (title, options) => {
        shown.push({ title, options });
        return Promise.resolve();
      },
    },
    addEventListener: (type, fn) => {
      (listeners[type] = listeners[type] || []).push(fn);
    },
  };
  const sandbox = {
    self,
    clients,
    console,
    importScripts: (url) => {
      if (url === 'firebase-config.js') self.GREENGO_FIREBASE_CONFIG = { apiKey: 'fake-test-key' };
    },
    firebase: {
      initializeApp: () => {},
      // Mimics the SDK: messaging() registers its own push listener, which
      // would show nothing while a window is visible.
      messaging: () => {
        self.addEventListener('push', () => {
          sdkPushCalls++;
        });
        return {};
      },
    },
  };
  vm.createContext(sandbox);
  vm.runInContext(SW, sandbox);

  async function push(payload) {
    const waits = [];
    let stopped = false;
    const event = {
      data: { json: () => payload },
      waitUntil: (p) => waits.push(p),
      stopImmediatePropagation: () => {
        stopped = true;
      },
    };
    for (const fn of listeners.push || []) {
      if (stopped) break;
      fn(event);
    }
    await Promise.all(waits);
  }

  return { push, shown, posted, sdkPushCalls: () => sdkPushCalls, api: self.GreenGoPushSw };
}

const CHAT_PUSH = {
  notification: { title: 'Maria', body: 'Ciao!' },
  data: { type: 'newMessage', conversationId: 'conv1' },
  from: '666632803027',
  fcmMessageId: 'abc',
};

test('iPhone PWA, app open: still shows a notification (no silent push) and tells the page', async () => {
  const sw = loadSw({ userAgent: IPHONE_PWA, windows: [{ visible: true }] });
  await sw.push(CHAT_PUSH);
  assert.strictEqual(sw.shown.length, 1);
  assert.strictEqual(sw.shown[0].title, 'Maria');
  assert.strictEqual(sw.shown[0].options.body, 'Ciao!');
  assert.strictEqual(sw.shown[0].options.tag, 'conv1');
  assert.strictEqual(sw.posted.length, 1);
  assert.strictEqual(sw.posted[0].isFirebaseMessaging, true);
  assert.strictEqual(sw.posted[0].messageType, 'push-received');
  assert.strictEqual(sw.sdkPushCalls(), 0);
});

test('iPhone PWA, app closed: exactly one notification', async () => {
  const sw = loadSw({ userAgent: IPHONE_PWA, windows: [] });
  await sw.push(CHAT_PUSH);
  assert.strictEqual(sw.shown.length, 1);
  assert.strictEqual(sw.sdkPushCalls(), 0);
});

test('macOS Safari, tab visible: shows a notification', async () => {
  const sw = loadSw({ userAgent: MAC_SAFARI, windows: [{ visible: true }] });
  await sw.push(CHAT_PUSH);
  assert.strictEqual(sw.shown.length, 1);
});

test('Chrome, tab visible: page only, no OS notification (unchanged behaviour)', async () => {
  for (const ua of [MAC_CHROME, ANDROID_CHROME]) {
    const sw = loadSw({ userAgent: ua, windows: [{ visible: true }] });
    await sw.push(CHAT_PUSH);
    assert.strictEqual(sw.shown.length, 0, ua);
    assert.strictEqual(sw.posted.length, 1, ua);
  }
});

test('Chrome, app in background: exactly one notification (no duplicate)', async () => {
  const sw = loadSw({ userAgent: ANDROID_CHROME, windows: [{ visible: false }] });
  await sw.push(CHAT_PUSH);
  assert.strictEqual(sw.shown.length, 1);
  assert.strictEqual(sw.posted.length, 0);
  assert.strictEqual(sw.sdkPushCalls(), 0);
});

test('data-only push still produces a visible notification on iPhone', async () => {
  const sw = loadSw({ userAgent: IPHONE_PWA, windows: [] });
  await sw.push({ data: { type: 'newMessage', senderName: 'Luca', body: 'hey' } });
  assert.strictEqual(sw.shown.length, 1);
  assert.strictEqual(sw.shown[0].title, 'Luca');
  assert.strictEqual(sw.shown[0].options.body, 'hey');
});

test('isAppleWebKit', () => {
  const { api } = loadSw({ userAgent: IPHONE_PWA });
  assert.strictEqual(api.isAppleWebKit(IPHONE_PWA), true);
  assert.strictEqual(api.isAppleWebKit(MAC_SAFARI), true);
  assert.strictEqual(api.isAppleWebKit(MAC_CHROME), false);
  assert.strictEqual(api.isAppleWebKit(ANDROID_CHROME), false);
  assert.strictEqual(api.isAppleWebKit(''), false);
});
