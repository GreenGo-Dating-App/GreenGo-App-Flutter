// Runs BEFORE __tests__/setup.ts (jest `setupFiles`). setup.ts hard-codes the
// default emulator ports; when `firebase emulators:exec` has already exported
// the real hosts (e.g. a non-default port config), remember them so
// emulatorEnv.restore.js can put them back. No-op when nothing is exported.
for (const k of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST', 'FIREBASE_STORAGE_EMULATOR_HOST']) {
  if (process.env[k] && !process.env[`GG_ORIG_${k}`]) process.env[`GG_ORIG_${k}`] = process.env[k];
}
