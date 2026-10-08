// Security regression suite: runs ONLY against local emulators.
//   firebase emulators:exec --only firestore,auth,storage --project test-project "npx jest --config jest.security.config.js"
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/__tests__/security'],
  testMatch: ['**/*.emulator.test.ts'],
  transform: { '^.+\.ts$': ['ts-jest', { tsconfig: '__tests__/tsconfig.json' }] },
  setupFiles: ['<rootDir>/__tests__/security/emulatorEnv.capture.js'],
  setupFilesAfterEnv: ['<rootDir>/__tests__/setup.ts', '<rootDir>/__tests__/security/emulatorEnv.restore.js'],
  testTimeout: 60000,
  maxWorkers: 1,
};
