/**
 * Test Helper Utilities
 * Common utilities and helpers for testing Cloud Functions
 */

import * as admin from 'firebase-admin';
// import functionsTest from 'firebase-functions-test';

// Initialize Firebase Functions Test SDK
// export const testEnv = functionsTest();

// Mock Firestore data - function to avoid calling Timestamp.now() at module load time
export function getMockFirestoreData() {
  const now = new Date();
  return {
    users: {
      'user-1': {
        uid: 'user-1',
        email: 'test@example.com',
        displayName: 'Test User',
        subscriptionTier: 'basic',
        role: 'user',
        createdAt: now,
        lastActiveAt: now,
        stats: {
          totalMatches: 5,
          totalMessages: 50,
          totalCalls: 2,
        },
        coins: {
          balance: 100,
        },
      },
      'admin-1': {
        uid: 'admin-1',
        email: 'admin@example.com',
        displayName: 'Admin User',
        subscriptionTier: 'gold',
        role: 'admin',
        createdAt: now,
        lastActiveAt: now,
      },
    },
    subscriptions: {
      'sub-1': {
        userId: 'user-1',
        tier: 'silver',
        status: 'active',
        platform: 'android',
        purchaseToken: 'test-token',
        currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        createdAt: now,
      },
    },
    messages: {
      'msg-1': {
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        recipientId: 'user-2',
        content: 'Hello!',
        type: 'text',
        createdAt: now,
      },
    },
    calls: {
      'call-1': {
        id: 'call-1',
        channelName: 'test-channel',
        callerId: 'user-1',
        recipientId: 'user-2',
        status: 'active',
        callType: 'video',
        participants: [],
        createdAt: now,
      },
    },
  };
}

// Legacy export for backwards compatibility
export const mockFirestoreData = getMockFirestoreData();

// Create mock authenticated context
export function createMockAuthContext(uid: string, role: string = 'user') {
  return {
    auth: {
      uid,
      token: {
        role,
        email: `${uid}@example.com`,
      },
    },
  };
}

// Create mock admin context
export function createMockAdminContext() {
  return createMockAuthContext('admin-1', 'admin');
}

// Create mock unauthenticated context
export function createMockUnauthenticatedContext() {
  return {
    auth: undefined,
  };
}

// Mock Firestore document
export function createMockFirestoreDoc(data: any) {
  return {
    exists: true,
    id: 'test-doc-id',
    data: () => data,
    ref: {
      update: jest.fn().mockResolvedValue(undefined),
      delete: jest.fn().mockResolvedValue(undefined),
      set: jest.fn().mockResolvedValue(undefined),
    },
  };
}

// Mock Firestore collection query
export function createMockFirestoreQuery(docs: any[]) {
  return {
    empty: docs.length === 0,
    size: docs.length,
    docs: docs.map((data, index) => ({
      exists: true,
      id: `doc-${index}`,
      data: () => data,
      ref: {
        update: jest.fn().mockResolvedValue(undefined),
        delete: jest.fn().mockResolvedValue(undefined),
      },
    })),
  };
}

// Mock Cloud Storage file
export function createMockStorageFile(name: string, bucket: string = 'test-bucket') {
  return {
    name,
    bucket,
    metadata: {
      contentType: 'image/jpeg',
      size: 1024,
    },
    download: jest.fn().mockResolvedValue([Buffer.from('test-data')]),
    save: jest.fn().mockResolvedValue(undefined),
    delete: jest.fn().mockResolvedValue(undefined),
    getSignedUrl: jest.fn().mockResolvedValue(['https://storage.example.com/test.jpg']),
  };
}

// Mock Storage event
// export function createMockStorageEvent(filePath: string, bucket: string = 'test-bucket') {
//   return testEnv.makeCloudEvent({
//     type: 'google.cloud.storage.object.v1.finalized',
//     source: `//storage.googleapis.com/projects/_/buckets/${bucket}`,
//     subject: `objects/${filePath}`,
//     data: {
//       name: filePath,
//       bucket,
//       contentType: 'image/jpeg',
//       size: '1024',
//       timeCreated: new Date().toISOString(),
//       updated: new Date().toISOString(),
//     },
//   });
// }

// Mock Firestore event
// export function createMockFirestoreEvent(data: any, documentPath: string) {
//   return testEnv.makeDocumentSnapshot(data, documentPath);
// }

// Generate random test ID
export function generateTestId(prefix: string = 'test'): string {
  return `${prefix}-${Math.random().toString(36).substring(7)}`;
}

// Wait for async operations
export async function waitFor(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Assert function throws with specific error
export async function expectToThrow(
  fn: () => Promise<any>,
  expectedError?: string
): Promise<void> {
  try {
    await fn();
    throw new Error('Expected function to throw');
  } catch (error: any) {
    if (expectedError && !error.message.includes(expectedError)) {
      throw new Error(
        `Expected error to include "${expectedError}", but got: ${error.message}`
      );
    }
  }
}

// Mock BigQuery client
export function createMockBigQueryClient() {
  return {
    dataset: jest.fn().mockReturnValue({
      table: jest.fn().mockReturnValue({
        insert: jest.fn().mockResolvedValue(undefined),
        load: jest.fn().mockResolvedValue(undefined),
      }),
    }),
    query: jest.fn().mockResolvedValue([[]]),
  };
}

// Mock Cloud Vision client
export function createMockVisionClient() {
  return {
    safeSearchDetection: jest.fn().mockResolvedValue([
      {
        safeSearchAnnotation: {
          adult: 'VERY_UNLIKELY',
          violence: 'UNLIKELY',
          racy: 'POSSIBLE',
        },
      },
    ]),
    labelDetection: jest.fn().mockResolvedValue([
      {
        labelAnnotations: [
          { description: 'Person', score: 0.95 },
          { description: 'Smile', score: 0.88 },
        ],
      },
    ]),
  };
}

// Mock Natural Language client
export function createMockLanguageClient() {
  return {
    analyzeSentiment: jest.fn().mockResolvedValue([
      {
        documentSentiment: {
          score: 0.5,
          magnitude: 0.8,
        },
      },
    ]),
    moderateText: jest.fn().mockResolvedValue([
      {
        moderationCategories: [],
      },
    ]),
  };
}

// Mock Translation client
export function createMockTranslationClient() {
  return {
    translateText: jest.fn().mockResolvedValue([
      {
        translations: [{ translatedText: 'Hola!' }],
      },
    ]),
    getSupportedLanguages: jest.fn().mockResolvedValue([
      {
        languages: [
          { languageCode: 'en', displayName: 'English' },
          { languageCode: 'es', displayName: 'Spanish' },
        ],
      },
    ]),
  };
}

// Mock Speech-to-Text client
export function createMockSpeechClient() {
  return {
    recognize: jest.fn().mockResolvedValue([
      {
        results: [
          {
            alternatives: [
              { transcript: 'Hello, this is a test message.', confidence: 0.95 },
            ],
          },
        ],
      },
    ]),
  };
}

// Cleanup test environment
// export function cleanupTestEnv() {
//   testEnv.cleanup();
// }
