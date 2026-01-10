# GreenGo Cloud Functions - Test Suite

Complete testing framework for all 143 Cloud Functions across 12 microservices.

## 📊 Test Coverage Status

### Current Status
- ✅ **Test Framework**: Complete
- ✅ **Test Utilities**: Complete
- ✅ **Mock Data Generators**: Complete
- ✅ **Configuration**: Complete
- ⚠️ **Test Implementation**: Template provided (needs expansion)

### Coverage Goals
- **Unit Tests**: 143 functions (100% coverage)
- **Code Coverage**: >70% (lines, branches, functions, statements)
- **Integration Tests**: 10+ end-to-end flows
- **Performance Tests**: All scheduled functions

---

## 🚀 Quick Start

### Prerequisites
```bash
# Ensure you have Node.js 18+ installed
node --version

# Navigate to functions directory
cd "C:\Users\Software Engineering\GreenGo App\GreenGo-App-Flutter\functions"

# Install dependencies
npm install
```

### Running Tests

#### All Tests
```bash
npm test
```

#### Watch Mode (for development)
```bash
npm run test:watch
```

#### With Coverage Report
```bash
npm run test:coverage
```

#### Specific Service
```bash
# Test only media service
npm run test:service -- media

# Test only subscription service
npm run test:service -- subscription

# Test only admin service
npm run test:service -- admin
```

#### Unit Tests Only
```bash
npm run test:unit
```

#### Integration Tests Only
```bash
npm run test:integration
```

---

## 📁 Test Structure

```
__tests__/
├── setup.ts                    # Global test setup
│
├── utils/
│   ├── test-helpers.ts        # Test utilities (mocks, helpers)
│   └── mock-data.ts           # Mock data generators
│
├── unit/                      # Unit tests (one per service)
│   ├── media.test.ts          # 10 functions - Media Processing
│   ├── messaging.test.ts      # 8 functions - Messaging
│   ├── backup.test.ts         # 8 functions - Backup & Export
│   ├── subscription.test.ts   # 4 functions - Subscription ✅ COMPLETE
│   ├── coins.test.ts          # 6 functions - Coin Management
│   ├── notification.test.ts   # 9 functions - Notifications
│   ├── safety.test.ts         # 11 functions - Safety & Moderation
│   ├── gamification.test.ts   # 8 functions - Gamification
│   ├── security.test.ts       # 5 functions - Security Audits
│   ├── video.test.ts          # 21 functions - Video Calling
│   ├── admin.test.ts          # 31 functions - Admin Panel
│   └── analytics.test.ts      # 22 functions - Analytics
│
├── integration/               # Integration tests
│   ├── user-flow.test.ts      # Complete user journeys
│   ├── subscription-flow.test.ts
│   └── moderation-flow.test.ts
│
├── COMPREHENSIVE_TESTS.md     # Full test strategy documentation
└── README.md                  # This file
```

---

## 🧪 Test Utilities

### Mock Helpers (test-helpers.ts)

#### Create Authenticated Context
```typescript
import { createMockAuthContext, createMockAdminContext } from '../utils/test-helpers';

// Regular user context
const userContext = createMockAuthContext('user-123');

// Admin user context
const adminContext = createMockAdminContext();

// Unauthenticated
const noAuthContext = createMockUnauthenticatedContext();
```

#### Mock Firestore Documents
```typescript
import { createMockFirestoreDoc, createMockFirestoreQuery } from '../utils/test-helpers';

// Mock single document
const mockDoc = createMockFirestoreDoc({ userId: 'test-123', name: 'Test User' });

// Mock query results
const mockQuery = createMockFirestoreQuery([
  { userId: 'user-1', name: 'User 1' },
  { userId: 'user-2', name: 'User 2' },
]);
```

#### Mock Storage Events
```typescript
import { createMockStorageEvent } from '../utils/test-helpers';

const event = createMockStorageEvent('users/user-123/profile.jpg', 'user-photos');
```

#### Mock External APIs
```typescript
import {
  createMockBigQueryClient,
  createMockVisionClient,
  createMockLanguageClient,
  createMockTranslationClient,
  createMockSpeechClient,
} from '../utils/test-helpers';

// Mock BigQuery
const bigquery = createMockBigQueryClient();

// Mock Cloud Vision
const vision = createMockVisionClient();

// Mock Natural Language API
const language = createMockLanguageClient();

// Mock Translation API
const translate = createMockTranslationClient();

// Mock Speech-to-Text
const speech = createMockSpeechClient();
```

### Mock Data Generators (mock-data.ts)

#### Generate Mock Objects
```typescript
import { mockData } from '../utils/mock-data';

// Create mock user
const user = mockData.user({ displayName: 'Custom Name' });

// Create mock subscription
const subscription = mockData.subscription({ tier: 'gold' });

// Create mock message
const message = mockData.message({ content: 'Hello!' });

// Create mock call
const call = mockData.call({ callType: 'video' });

// ... and many more (see mock-data.ts for full list)
```

#### Generate Arrays
```typescript
import { generateMockArray, generateMockUser } from '../utils/mock-data';

// Generate 10 users
const users = generateMockArray(generateMockUser, 10);

// Generate 50 messages
const messages = generateMockArray((i) => mockData.message({ id: `msg-${i}` }), 50);
```

---

## ✍️ Writing Tests

### Basic Test Structure

```typescript
import { createMockAuthContext } from '../utils/test-helpers';
import { mockData } from '../utils/mock-data';

describe('ServiceName', () => {
  let mockDb: any;
  let mockUtils: any;

  beforeEach(() => {
    jest.clearAllMocks();
    // Setup mocks
  });

  describe('functionName', () => {
    it('should do something successfully', async () => {
      // Arrange
      const request = {
        data: { /* input data */ },
        ...createMockAuthContext('user-123'),
      };

      // Act
      // const result = await functionName(request);

      // Assert
      // expect(result).toMatchObject({ success: true });
    });

    it('should handle errors', async () => {
      // Test error cases
    });

    it('should validate authentication', async () => {
      // Test auth requirements
    });
  });
});
```

### Testing HTTP Callable Functions

```typescript
describe('compressImage', () => {
  it('should compress image successfully', async () => {
    // Arrange
    const mockRequest = {
      data: {
        imageUrl: 'https://example.com/image.jpg',
        quality: 85,
      },
      auth: {
        uid: 'test-user-123',
        token: { role: 'user' },
      },
    };

    // Mock external services
    sharp.mockReturnValue({
      resize: jest.fn().mockReturnThis(),
      jpeg: jest.fn().mockReturnThis(),
      toBuffer: jest.fn().mockResolvedValue(Buffer.from('compressed')),
    });

    // Act
    // const result = await compressImage(mockRequest);

    // Assert
    // expect(result).toMatchObject({
    //   success: true,
    //   compressedUrl: expect.stringContaining('https://'),
    // });
  });
});
```

### Testing Firestore Triggers

```typescript
describe('autoTranslateMessage', () => {
  it('should auto-translate when preferences set', async () => {
    // Arrange
    const messageData = mockData.message({
      content: 'Hello',
      senderId: 'user-1',
      recipientId: 'user-2',
    });

    const event = createMockFirestoreEvent(messageData, 'messages/msg-123');

    // Mock recipient with Spanish preference
    mockDb.get.mockResolvedValue(
      createMockFirestoreDoc({ preferredLanguage: 'es' })
    );

    // Act
    // await autoTranslateMessage(event);

    // Assert
    // expect(mockTranslationClient.translateText).toHaveBeenCalledWith({
    //   contents: ['Hello'],
    //   targetLanguageCode: 'es',
    // });
  });
});
```

### Testing Storage Triggers

```typescript
describe('compressUploadedImage', () => {
  it('should compress when image uploaded', async () => {
    // Arrange
    const event = createMockStorageEvent(
      'users/user-123/profile.jpg',
      'user-photos'
    );

    // Act
    // await compressUploadedImage(event);

    // Assert
    // expect(sharp).toHaveBeenCalled();
  });
});
```

### Testing Scheduled Functions

```typescript
describe('cleanupExpiredCoins', () => {
  it('should delete expired coin batches', async () => {
    // Arrange
    const expiredBatch = mockData.coinBatch({
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 1000) // Expired 1 second ago
      ),
    });

    mockDb.get.mockResolvedValue(createMockFirestoreQuery([expiredBatch]));

    // Act
    // await cleanupExpiredCoins();

    // Assert
    // expect(mockDb.delete).toHaveBeenCalled();
  });
});
```

### Testing Webhook Handlers

```typescript
describe('handlePlayStoreWebhook', () => {
  it('should process subscription renewal', async () => {
    // Arrange
    const req = {
      headers: { 'x-goog-signature': 'valid-sig' },
      body: {
        message: {
          data: Buffer.from(JSON.stringify({
            subscriptionNotification: {
              notificationType: 2, // RENEWED
              purchaseToken: 'test-token',
            },
          })).toString('base64'),
        },
      },
    };

    const mockRes = {
      status: jest.fn().mockReturnThis(),
      send: jest.fn(),
    };

    // Act
    // await handlePlayStoreWebhook(req, mockRes);

    // Assert
    // expect(mockRes.status).toHaveBeenCalledWith(200);
  });
});
```

---

## 🎯 Test Patterns by Service

### Media Processing (10 functions)
- Mock Sharp for image compression
- Mock FFmpeg for video processing
- Mock Speech-to-Text API
- Test file upload/download
- Test scheduled cleanup jobs

### Messaging (8 functions)
- Mock Translation API
- Test Firestore triggers
- Test message scheduling
- Test batch operations

### Backup & Export (8 functions)
- Test AES-256-GCM encryption/decryption
- Mock PDFKit
- Test Cloud Storage operations
- Test expiration logic

### Subscription (4 functions) ✅
- Test webhook signatures
- Test all notification types (10+ for Play Store)
- Test grace period handling
- Test tier downgrades

### Coins (6 functions)
- Test IAP verification
- Test FIFO spending
- Test expiration warnings
- Test batch operations

### Notification (9 functions)
- Mock FCM
- Mock SendGrid
- Test email templates
- Test notification bundling

### Safety & Moderation (11 functions)
- Mock Cloud Vision API
- Mock Natural Language API
- Test profanity filters
- Test spam detection algorithms

### Gamification (8 functions)
- Test XP calculations
- Test level-up logic
- Test achievement unlocks
- Test leaderboard updates

### Security (5 functions)
- Test all 7 audit types
- Test finding severity levels
- Test alert generation

### Video Calling (21 functions)
- Mock Agora token generation
- Test call lifecycle
- Test group calls (50 participants)
- Test recording logic

### Admin (31 functions)
- Test role verification
- Test dashboard calculations
- Test moderation workflows
- Test user management

### Analytics (22 functions)
- Mock BigQuery
- Test cohort analysis
- Test churn prediction
- Test A/B testing

---

## 📈 Coverage Reports

### Generate Coverage Report
```bash
npm run test:coverage
```

### View HTML Report
```bash
# Open in browser
open coverage/index.html  # Mac
start coverage/index.html  # Windows
```

### Coverage Output
```
----------|---------|----------|---------|---------|
File      | % Stmts | % Branch | % Funcs | % Lines |
----------|---------|----------|---------|---------|
All files |   70.5  |   68.2   |   72.1  |   71.3  |
----------|---------|----------|---------|---------|
```

---

## 🔧 Debugging Tests

### Run Single Test
```bash
# Run specific test file
npm test -- subscription.test.ts

# Run specific test suite
npm test -- --testNamePattern="handlePlayStoreWebhook"

# Run specific test case
npm test -- --testNamePattern="should handle SUBSCRIPTION_RENEWED"
```

### Debug with VSCode
Add to `.vscode/launch.json`:
```json
{
  "type": "node",
  "request": "launch",
  "name": "Jest Debug",
  "program": "${workspaceFolder}/functions/node_modules/.bin/jest",
  "args": ["--runInBand", "--no-cache"],
  "console": "integratedTerminal",
  "internalConsoleOptions": "neverOpen"
}
```

### Verbose Output
```bash
npm test -- --verbose
```

---

## 🚨 Common Issues

### Issue: Tests timeout
```bash
# Increase timeout in jest.config.js
testTimeout: 30000  // 30 seconds
```

### Issue: Mocks not working
```bash
# Clear Jest cache
npm test -- --clearCache
```

### Issue: Firebase Admin errors
```bash
# Ensure GCLOUD_PROJECT is set
# Check __tests__/setup.ts
```

### Issue: Import errors
```bash
# Rebuild TypeScript
npm run build
```

---

## 📊 Test Metrics (Target)

Once all tests are implemented:

| Metric | Target | Current |
|--------|--------|---------|
| Total Tests | 500+ | 50+ (template) |
| Services Covered | 12/12 | 12/12 |
| Functions Covered | 143/143 | ~20 (examples) |
| Code Coverage | >70% | TBD |
| Integration Tests | 10+ | 3 (template) |
| Execution Time | <5 min | <1 min |

---

## 🎓 Best Practices

1. **Always Mock External Services**
   - Never make real API calls in tests
   - Use mock helpers provided

2. **Test One Thing Per Test**
   - Each `it()` should test one behavior
   - Keep tests focused and simple

3. **Use Descriptive Test Names**
   - `it('should X when Y')`
   - Names should explain what's being tested

4. **Follow AAA Pattern**
   - Arrange: Set up test data
   - Act: Call function under test
   - Assert: Verify results

5. **Clean Up Between Tests**
   - Use `beforeEach()` to reset mocks
   - Avoid test interdependencies

6. **Test Edge Cases**
   - Empty arrays
   - Null/undefined values
   - Boundary conditions
   - Error cases

7. **Verify Side Effects**
   - Check database updates
   - Verify notifications sent
   - Confirm logs written

---

## 📚 Resources

### Documentation
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Firebase Functions Test SDK](https://firebase.google.com/docs/functions/unit-testing)
- [Testing Best Practices](https://testingjavascript.com/)

### Examples
- `__tests__/unit/subscription.test.ts` - Complete example
- `__tests__/unit/media.test.ts` - Template example
- `__tests__/COMPREHENSIVE_TESTS.md` - Full strategy

---

## 🎯 Next Steps

### To Complete Test Suite:

1. **Implement remaining unit tests**
   - Use `subscription.test.ts` as template
   - Follow patterns in `COMPREHENSIVE_TESTS.md`
   - Aim for 70%+ coverage per service

2. **Add integration tests**
   - User onboarding flow
   - Subscription lifecycle
   - Content moderation workflow
   - Payment processing

3. **Performance tests**
   - Load test scheduled functions
   - Stress test webhook handlers
   - Memory profiling

4. **Set up CI/CD**
   - GitHub Actions workflow
   - Automated test runs on PR
   - Coverage reports

---

## ✅ Test Checklist

For each function, ensure tests cover:

- [ ] Success cases
- [ ] Error handling
- [ ] Authentication/Authorization
- [ ] Input validation
- [ ] Edge cases (null, empty, boundary values)
- [ ] External service errors
- [ ] Database operations
- [ ] Side effects (notifications, logs)
- [ ] Scheduled job timing
- [ ] Webhook signatures (if applicable)

---

**Status**: Framework complete, ready for full test implementation
**Coverage Goal**: 70%+ across all 143 functions
**Execution Target**: <5 minutes for full suite
