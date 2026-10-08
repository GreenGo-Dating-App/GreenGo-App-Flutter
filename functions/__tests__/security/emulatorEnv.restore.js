// Runs AFTER __tests__/setup.ts (jest `setupFilesAfterEnv`): restores the
// emulator hosts captured by emulatorEnv.capture.js, so the suites talk to the
// emulators `emulators:exec` actually started. No-op otherwise.
for (const k of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST', 'FIREBASE_STORAGE_EMULATOR_HOST']) {
  if (process.env[`GG_ORIG_${k}`]) process.env[k] = process.env[`GG_ORIG_${k}`];
}
