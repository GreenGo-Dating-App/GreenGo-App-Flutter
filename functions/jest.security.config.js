// Security regression suite: runs ONLY against local emulators.
//   firebase emulators:exec --only firestore,auth --project test-project "npx jest --config jest.security.config.js"
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/__tests__/security'],
  testMatch: ['**/*.emulator.test.ts'],
  transform: { '^.+\.ts$': ['ts-jest', { tsconfig: '__tests__/tsconfig.json' }] },
  setupFilesAfterEnv: ['<rootDir>/__tests__/setup.ts'],
  testTimeout: 60000,
  maxWorkers: 1,
};
