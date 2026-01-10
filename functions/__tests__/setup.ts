/**
 * Jest Test Setup
 * Configures the testing environment for all tests
 */

// Set test environment variables
process.env.GCLOUD_PROJECT = 'test-project';
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = 'localhost:9199';
process.env.PUBSUB_EMULATOR_HOST = 'localhost:8085';

// Agora test credentials
process.env.AGORA_APP_ID = 'test-agora-app-id';
process.env.AGORA_APP_CERTIFICATE = 'test-agora-certificate';

// SendGrid test credentials
process.env.SENDGRID_API_KEY = 'test-sendgrid-key';

// Extend Jest timeout for integration tests
jest.setTimeout(30000);

// Mock console methods to reduce noise in tests
global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};

// Clean up after all tests
afterAll(async () => {
  // Add any global cleanup here
});
