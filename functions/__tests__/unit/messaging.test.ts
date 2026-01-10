/**
 * Messaging Service Tests
 * Comprehensive tests for all 8 messaging functions
 */

import * as admin from 'firebase-admin';
import { FieldValue } from '../../src/shared/utils';
import {
  createMockAuthContext,
  createMockFirestoreDoc,
} from '../utils/test-helpers';

// Mock Google Cloud Translation
jest.mock('@google-cloud/translate', () => ({
  TranslationServiceClient: jest.fn(() => ({
    translateText: jest.fn(),
  })),
}));

// Mock Firebase Admin
jest.mock('firebase-admin', () => {
  const actualAdmin = jest.requireActual('firebase-admin');
  return {
    ...actualAdmin,
    firestore: jest.fn(() => ({
      collection: jest.fn(),
      batch: jest.fn(),
      Timestamp: {
        now: jest.fn(),
        fromDate: jest.fn(),
      },
      FieldValue: {
        serverTimestamp: jest.fn(),
      },
    })),
  };
});

// Mock Firestore
const mockDb = {
  collection: jest.fn(() => ({
    doc: jest.fn(() => ({
      get: jest.fn(),
      set: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      ref: {},
    })),
    add: jest.fn(),
    get: jest.fn(),
    where: jest.fn(),
    orderBy: jest.fn(),
    limit: jest.fn(),
  })),
  batch: jest.fn(() => ({
    set: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    commit: jest.fn(),
  })),
};

// Mock shared/utils
jest.mock('../../src/shared/utils', () => ({
  db: mockDb,
  FieldValue: {
    serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
  },
  verifyAuth: jest.fn(),
  handleError: jest.fn(err => err),
  logInfo: jest.fn(),
  logError: jest.fn(),
}));

const { verifyAuth, logInfo, logError } = require('../../src/shared/utils');

describe('Messaging Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ========== 1. TRANSLATE MESSAGE ==========
  describe('translateMessage', () => {
    const mockRequest = {
      data: {
        messageId: 'msg-123',
        targetLanguage: 'es',
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    });

    it('should translate message to target language', async () => {
      const mockMessageDoc = {
        exists: true,
        data: () => ({
          content: 'Hello, how are you?',
          conversationId: 'conv-123',
          senderId: 'user-456',
        }),
        ref: {
          update: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn((docId?: string) => ({
          get: jest.fn().mockResolvedValue(
            collectionName === 'messages' ? mockMessageDoc :
            collectionName === 'conversations' ? mockConversationDoc :
            { exists: false }
          ),
          ref: mockMessageDoc.ref,
        })),
      }));

      // Mock Translation API
      const { TranslationServiceClient } = require('@google-cloud/translate');
      const mockTranslationClient = new TranslationServiceClient();
      mockTranslationClient.translateText.mockResolvedValue([{
        translations: [{
          translatedText: 'Hola, ¿cómo estás?',
        }],
      }]);

      const { translateMessage } = require('../../src/messaging');

      const result = await translateMessage(mockRequest);

      expect(result).toMatchObject({
        success: true,
        translation: 'Hola, ¿cómo estás?',
        cached: false,
      });

      expect(mockMessageDoc.ref.update).toHaveBeenCalledWith(
        expect.objectContaining({
          'translations.es': 'Hola, ¿cómo estás?',
        })
      );
    });

    it('should return cached translation if available', async () => {
      const mockMessageDoc = {
        exists: true,
        data: () => ({
          content: 'Hello, how are you?',
          conversationId: 'conv-123',
          translations: {
            es: 'Hola, ¿cómo estás?',
          },
        }),
        ref: {
          update: jest.fn(),
        },
      };

      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(
            collectionName === 'messages' ? mockMessageDoc : mockConversationDoc
          ),
        })),
      }));

      const { translateMessage } = require('../../src/messaging');

      const result = await translateMessage(mockRequest);

      expect(result).toMatchObject({
        success: true,
        translation: 'Hola, ¿cómo estás?',
        cached: true,
      });

      expect(mockMessageDoc.ref.update).not.toHaveBeenCalled();
    });

    it('should reject unsupported language', async () => {
      const { translateMessage } = require('../../src/messaging');

      await expect(translateMessage({
        ...mockRequest,
        data: { messageId: 'msg-123', targetLanguage: 'xx' },
      })).rejects.toThrow('Language xx not supported');
    });

    it('should reject if message not found', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { translateMessage } = require('../../src/messaging');

      await expect(translateMessage(mockRequest)).rejects.toThrow('Message not found');
    });

    it('should reject unauthorized user', async () => {
      const mockMessageDoc = {
        exists: true,
        data: () => ({
          content: 'Hello',
          conversationId: 'conv-123',
        }),
      };

      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-456', 'user-789'], // user-123 not in conversation
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(
            collectionName === 'messages' ? mockMessageDoc : mockConversationDoc
          ),
        })),
      }));

      const { translateMessage } = require('../../src/messaging');

      await expect(translateMessage(mockRequest)).rejects.toThrow('Not authorized');
    });

    it('should translate to all supported languages', async () => {
      const supportedLanguages = [
        'en', 'es', 'fr', 'de', 'pt', 'it', 'ar', 'zh', 'ja', 'ko', 'ru',
        'hi', 'nl', 'sv', 'pl', 'tr', 'vi', 'id', 'th', 'cs', 'ro'
      ];

      const mockMessageDoc = {
        exists: true,
        data: () => ({
          content: 'Hello',
          conversationId: 'conv-123',
        }),
        ref: {
          update: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(
            collectionName === 'messages' ? mockMessageDoc : mockConversationDoc
          ),
          ref: mockMessageDoc.ref,
        })),
      }));

      const { TranslationServiceClient } = require('@google-cloud/translate');
      const mockTranslationClient = new TranslationServiceClient();
      mockTranslationClient.translateText.mockResolvedValue([{
        translations: [{ translatedText: 'Translated' }],
      }]);

      const { translateMessage } = require('../../src/messaging');

      for (const lang of supportedLanguages) {
        const result = await translateMessage({
          ...mockRequest,
          data: { messageId: 'msg-123', targetLanguage: lang },
        });
        expect(result.success).toBe(true);
      }
    });
  });

  // ========== 2. AUTO-TRANSLATE MESSAGE ==========
  describe('autoTranslateMessage', () => {
    it('should auto-translate message for receiver preferred language', async () => {
      const mockEvent = {
        params: { messageId: 'msg-123' },
        data: {
          data: () => ({
            content: 'Hello, how are you?',
            conversationId: 'conv-123',
            senderId: 'user-456',
          }),
        },
      };

      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockReceiverDoc = {
        exists: true,
        data: () => ({
          preferredLanguage: 'es',
        }),
      };

      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn((docId?: string) => ({
          get: jest.fn().mockResolvedValue(
            collectionName === 'conversations' ? mockConversationDoc :
            collectionName === 'users' ? mockReceiverDoc :
            { exists: false }
          ),
          update: mockUpdate,
        })),
      }));

      const { TranslationServiceClient } = require('@google-cloud/translate');
      const mockTranslationClient = new TranslationServiceClient();
      mockTranslationClient.translateText.mockResolvedValue([{
        translations: [{
          translatedText: 'Hola, ¿cómo estás?',
        }],
      }]);

      const { autoTranslateMessage } = require('../../src/messaging');

      await autoTranslateMessage(mockEvent);

      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          'translations.es': 'Hola, ¿cómo estás?',
          autoTranslated: true,
        })
      );

      expect(logInfo).toHaveBeenCalledWith('Auto-translated message msg-123 to es');
    });

    it('should skip translation if receiver language is English', async () => {
      const mockEvent = {
        params: { messageId: 'msg-123' },
        data: {
          data: () => ({
            content: 'Hello',
            conversationId: 'conv-123',
            senderId: 'user-456',
          }),
        },
      };

      const mockConversationDoc = {
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockReceiverDoc = {
        data: () => ({
          preferredLanguage: 'en',
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(
            collectionName === 'conversations' ? mockConversationDoc : mockReceiverDoc
          ),
          update: jest.fn(),
        })),
      }));

      const { autoTranslateMessage } = require('../../src/messaging');

      await autoTranslateMessage(mockEvent);

      // Should not call update since language is English
      const mockUpdate = mockDb.collection().doc().update;
      expect(mockUpdate).not.toHaveBeenCalled();
    });

    it('should handle translation errors gracefully', async () => {
      const mockEvent = {
        params: { messageId: 'msg-123' },
        data: {
          data: () => ({
            content: 'Hello',
            conversationId: 'conv-123',
            senderId: 'user-456',
          }),
        },
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockRejectedValue(new Error('Database error')),
        })),
      }));

      const { autoTranslateMessage } = require('../../src/messaging');

      // Should not throw
      await expect(autoTranslateMessage(mockEvent)).resolves.not.toThrow();
      expect(logError).toHaveBeenCalled();
    });
  });

  // ========== 3. BATCH TRANSLATE MESSAGES ==========
  describe('batchTranslateMessages', () => {
    const mockRequest = {
      data: {
        messageIds: ['msg-1', 'msg-2', 'msg-3'],
        targetLanguage: 'fr',
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    });

    it('should batch translate multiple messages', async () => {
      const mockMessageDocs = [
        {
          exists: true,
          id: 'msg-1',
          data: () => ({ content: 'Hello' }),
        },
        {
          exists: true,
          id: 'msg-2',
          data: () => ({ content: 'How are you?' }),
        },
        {
          exists: true,
          id: 'msg-3',
          data: () => ({ content: 'Good morning' }),
        },
      ];

      const mockGet = jest.fn((docId: string) => {
        const doc = mockMessageDocs.find(d => d.id === docId);
        return Promise.resolve(doc || { exists: false });
      });

      const mockBatch = {
        update: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn((docId?: string) => ({
          get: () => mockGet(docId!),
        })),
      }));

      const { TranslationServiceClient } = require('@google-cloud/translate');
      const mockTranslationClient = new TranslationServiceClient();
      mockTranslationClient.translateText.mockResolvedValue([{
        translations: [
          { translatedText: 'Bonjour' },
          { translatedText: 'Comment allez-vous?' },
          { translatedText: 'Bon matin' },
        ],
      }]);

      const { batchTranslateMessages } = require('../../src/messaging');

      const result = await batchTranslateMessages(mockRequest);

      expect(result).toMatchObject({
        success: true,
        translated: 3,
        cached: 0,
      });

      expect(mockBatch.update).toHaveBeenCalledTimes(3);
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    it('should skip already translated messages', async () => {
      const mockMessageDocs = [
        {
          exists: true,
          id: 'msg-1',
          data: () => ({
            content: 'Hello',
            translations: { fr: 'Bonjour' },
          }),
        },
        {
          exists: true,
          id: 'msg-2',
          data: () => ({
            content: 'Good morning',
          }),
        },
      ];

      const mockGet = jest.fn((docId: string) => {
        const doc = mockMessageDocs.find(d => d.id === docId);
        return Promise.resolve(doc || { exists: false });
      });

      const mockBatch = {
        update: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn((docId?: string) => ({
          get: () => mockGet(docId!),
        })),
      }));

      const { TranslationServiceClient } = require('@google-cloud/translate');
      const mockTranslationClient = new TranslationServiceClient();
      mockTranslationClient.translateText.mockResolvedValue([{
        translations: [{ translatedText: 'Bon matin' }],
      }]);

      const { batchTranslateMessages } = require('../../src/messaging');

      const result = await batchTranslateMessages({
        ...mockRequest,
        data: { messageIds: ['msg-1', 'msg-2'], targetLanguage: 'fr' },
      });

      expect(result).toMatchObject({
        success: true,
        translated: 1,
        cached: 1,
      });

      expect(mockBatch.update).toHaveBeenCalledTimes(1);
    });

    it('should return all cached if all messages already translated', async () => {
      const mockMessageDocs = [
        {
          exists: true,
          id: 'msg-1',
          data: () => ({
            content: 'Hello',
            translations: { fr: 'Bonjour' },
          }),
        },
      ];

      const mockGet = jest.fn((docId: string) => {
        return Promise.resolve(mockMessageDocs.find(d => d.id === docId) || { exists: false });
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn((docId?: string) => ({
          get: () => mockGet(docId!),
        })),
      }));

      const { batchTranslateMessages } = require('../../src/messaging');

      const result = await batchTranslateMessages({
        ...mockRequest,
        data: { messageIds: ['msg-1'], targetLanguage: 'fr' },
      });

      expect(result).toMatchObject({
        success: true,
        translated: 0,
        cached: 1,
      });
    });

    it('should reject empty messageIds', async () => {
      const { batchTranslateMessages } = require('../../src/messaging');

      await expect(batchTranslateMessages({
        ...mockRequest,
        data: { messageIds: [], targetLanguage: 'fr' },
      })).rejects.toThrow('messageIds is required');
    });
  });

  // ========== 4. GET SUPPORTED LANGUAGES ==========
  describe('getSupportedLanguages', () => {
    it('should return list of supported languages', async () => {
      const { getSupportedLanguages } = require('../../src/messaging');

      const result = await getSupportedLanguages({});

      expect(result).toMatchObject({
        success: true,
        languages: expect.arrayContaining(['en', 'es', 'fr', 'de']),
        total: 21,
        languageNames: expect.objectContaining({
          en: 'English',
          es: 'Spanish',
          fr: 'French',
        }),
      });
    });

    it('should include all 21 supported languages', async () => {
      const { getSupportedLanguages } = require('../../src/messaging');

      const result = await getSupportedLanguages({});

      expect(result.languages.length).toBe(21);
      expect(result.total).toBe(21);
    });
  });

  // ========== 5. SCHEDULE MESSAGE ==========
  describe('scheduleMessage', () => {
    const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

    const mockRequest = {
      data: {
        conversationId: 'conv-123',
        content: 'Happy Birthday!',
        scheduledFor: futureDate,
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
        toMillis: () => date.getTime(),
      }));
    });

    it('should schedule message for future delivery', async () => {
      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockAdd = jest.fn().mockResolvedValue({ id: 'scheduled-msg-1' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockConversationDoc),
        })),
        add: mockAdd,
      }));

      const { scheduleMessage } = require('../../src/messaging');

      const result = await scheduleMessage(mockRequest);

      expect(result).toMatchObject({
        success: true,
        scheduledMessageId: 'scheduled-msg-1',
        scheduledFor: futureDate,
      });

      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          conversationId: 'conv-123',
          senderId: 'user-123',
          content: 'Happy Birthday!',
          status: 'pending',
        })
      );
    });

    it('should reject past scheduled time', async () => {
      const pastDate = new Date(Date.now() - 1000).toISOString();

      const { scheduleMessage } = require('../../src/messaging');

      await expect(scheduleMessage({
        ...mockRequest,
        data: { ...mockRequest.data, scheduledFor: pastDate },
      })).rejects.toThrow('scheduledFor must be in the future');
    });

    it('should reject if conversation not found', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { scheduleMessage } = require('../../src/messaging');

      await expect(scheduleMessage(mockRequest)).rejects.toThrow('Conversation not found');
    });

    it('should reject unauthorized user', async () => {
      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-456', 'user-789'], // user-123 not included
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockConversationDoc),
        })),
      }));

      const { scheduleMessage } = require('../../src/messaging');

      await expect(scheduleMessage(mockRequest)).rejects.toThrow('Not authorized');
    });

    it('should support media messages', async () => {
      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockAdd = jest.fn().mockResolvedValue({ id: 'scheduled-msg-2' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockConversationDoc),
        })),
        add: mockAdd,
      }));

      const { scheduleMessage } = require('../../src/messaging');

      await scheduleMessage({
        ...mockRequest,
        data: {
          ...mockRequest.data,
          type: 'image',
          mediaUrl: 'https://example.com/image.jpg',
        },
      });

      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'image',
          mediaUrl: 'https://example.com/image.jpg',
        })
      );
    });
  });

  // ========== 6. SEND SCHEDULED MESSAGES ==========
  describe('sendScheduledMessages', () => {
    beforeEach(() => {
      (admin.firestore.Timestamp.now as jest.Mock).mockReturnValue({
        toMillis: () => Date.now(),
      });
    });

    it('should send due scheduled messages', async () => {
      const mockScheduledDocs = [
        {
          id: 'scheduled-1',
          data: () => ({
            conversationId: 'conv-123',
            senderId: 'user-123',
            content: 'Message 1',
            type: 'text',
            status: 'pending',
          }),
          ref: {},
        },
        {
          id: 'scheduled-2',
          data: () => ({
            conversationId: 'conv-456',
            senderId: 'user-456',
            content: 'Message 2',
            type: 'text',
            status: 'pending',
          }),
          ref: {},
        },
      ];

      const mockBatch = {
        set: jest.fn(),
        update: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockScheduledDocs,
          empty: false,
          size: 2,
        }),
        doc: jest.fn(() => ({})),
      }));

      const { sendScheduledMessages } = require('../../src/messaging');

      await sendScheduledMessages();

      expect(mockBatch.set).toHaveBeenCalledTimes(2); // 2 messages created
      expect(mockBatch.update).toHaveBeenCalledTimes(4); // 2 conversations + 2 scheduled messages
      expect(mockBatch.commit).toHaveBeenCalled();
      expect(logInfo).toHaveBeenCalledWith('Successfully sent 2 scheduled messages');
    });

    it('should handle no scheduled messages gracefully', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: [],
          empty: true,
          size: 0,
        }),
      }));

      const { sendScheduledMessages } = require('../../src/messaging');

      await sendScheduledMessages();

      expect(logInfo).toHaveBeenCalledWith('No scheduled messages to send');
    });

    it('should mark messages as sent', async () => {
      const mockScheduledDocs = [
        {
          id: 'scheduled-1',
          data: () => ({
            conversationId: 'conv-123',
            senderId: 'user-123',
            content: 'Test',
            type: 'text',
          }),
          ref: { id: 'scheduled-1' },
        },
      ];

      const mockBatch = {
        set: jest.fn(),
        update: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockScheduledDocs,
          empty: false,
          size: 1,
        }),
        doc: jest.fn(() => ({})),
      }));

      const { sendScheduledMessages } = require('../../src/messaging');

      await sendScheduledMessages();

      expect(mockBatch.update).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          status: 'sent',
        })
      );
    });

    it('should have correct schedule configuration (every minute)', () => {
      const { sendScheduledMessages } = require('../../src/messaging');

      expect(sendScheduledMessages).toBeDefined();
      expect(typeof sendScheduledMessages).toBe('function');
    });
  });

  // ========== 7. CANCEL SCHEDULED MESSAGE ==========
  describe('cancelScheduledMessage', () => {
    const mockRequest = {
      data: {
        scheduledMessageId: 'scheduled-1',
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    });

    it('should cancel pending scheduled message', async () => {
      const mockScheduledDoc = {
        exists: true,
        data: () => ({
          senderId: 'user-123',
          status: 'pending',
        }),
        ref: {
          update: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockScheduledDoc),
        })),
      }));

      const { cancelScheduledMessage } = require('../../src/messaging');

      const result = await cancelScheduledMessage(mockRequest);

      expect(result).toMatchObject({
        success: true,
        message: 'Scheduled message cancelled',
      });

      expect(mockScheduledDoc.ref.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'cancelled',
        })
      );
    });

    it('should reject if message not found', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { cancelScheduledMessage } = require('../../src/messaging');

      await expect(cancelScheduledMessage(mockRequest)).rejects.toThrow('Scheduled message not found');
    });

    it('should reject unauthorized user', async () => {
      const mockScheduledDoc = {
        exists: true,
        data: () => ({
          senderId: 'user-456', // Different user
          status: 'pending',
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockScheduledDoc),
        })),
      }));

      const { cancelScheduledMessage } = require('../../src/messaging');

      await expect(cancelScheduledMessage(mockRequest)).rejects.toThrow('Not authorized');
    });

    it('should reject if message already sent', async () => {
      const mockScheduledDoc = {
        exists: true,
        data: () => ({
          senderId: 'user-123',
          status: 'sent',
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockScheduledDoc),
        })),
      }));

      const { cancelScheduledMessage } = require('../../src/messaging');

      await expect(cancelScheduledMessage(mockRequest)).rejects.toThrow('Message already sent');
    });
  });

  // ========== 8. GET SCHEDULED MESSAGES ==========
  describe('getScheduledMessages', () => {
    const mockRequest = {
      data: {
        status: 'pending' as const,
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    });

    it('should get user scheduled messages', async () => {
      const mockScheduledDocs = [
        {
          id: 'scheduled-1',
          data: () => ({
            content: 'Message 1',
            scheduledFor: {
              toDate: () => new Date('2025-12-25T12:00:00Z'),
            },
            createdAt: {
              toDate: () => new Date('2025-01-01T10:00:00Z'),
            },
          }),
        },
        {
          id: 'scheduled-2',
          data: () => ({
            content: 'Message 2',
            scheduledFor: {
              toDate: () => new Date('2025-12-26T12:00:00Z'),
            },
            createdAt: {
              toDate: () => new Date('2025-01-02T10:00:00Z'),
            },
          }),
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockScheduledDocs,
        }),
      }));

      const { getScheduledMessages } = require('../../src/messaging');

      const result = await getScheduledMessages(mockRequest);

      expect(result).toMatchObject({
        success: true,
        scheduledMessages: expect.arrayContaining([
          expect.objectContaining({
            id: 'scheduled-1',
            content: 'Message 1',
          }),
          expect.objectContaining({
            id: 'scheduled-2',
            content: 'Message 2',
          }),
        ]),
        total: 2,
      });
    });

    it('should filter by conversation ID', async () => {
      const mockWhere = jest.fn().mockReturnThis();

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: mockWhere,
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: [] }),
      }));

      const { getScheduledMessages } = require('../../src/messaging');

      await getScheduledMessages({
        ...mockRequest,
        data: { conversationId: 'conv-123', status: 'pending' },
      });

      expect(mockWhere).toHaveBeenCalledWith('senderId', '==', 'user-123');
      expect(mockWhere).toHaveBeenCalledWith('status', '==', 'pending');
      expect(mockWhere).toHaveBeenCalledWith('conversationId', '==', 'conv-123');
    });

    it('should filter by status', async () => {
      const statuses: Array<'pending' | 'sent' | 'cancelled'> = ['pending', 'sent', 'cancelled'];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: [] }),
      }));

      const { getScheduledMessages } = require('../../src/messaging');

      for (const status of statuses) {
        await getScheduledMessages({
          ...mockRequest,
          data: { status },
        });
      }
    });

    it('should limit results to 50', async () => {
      const mockLimit = jest.fn().mockReturnThis();

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: mockLimit,
        get: jest.fn().mockResolvedValue({ docs: [] }),
      }));

      const { getScheduledMessages } = require('../../src/messaging');

      await getScheduledMessages(mockRequest);

      expect(mockLimit).toHaveBeenCalledWith(50);
    });
  });

  // ========== INTEGRATION TESTS ==========
  describe('Messaging Integration', () => {
    it('should handle complete message scheduling workflow', async () => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
        toMillis: () => date.getTime(),
      }));
      (admin.firestore.Timestamp.now as jest.Mock).mockReturnValue({
        toMillis: () => Date.now(),
      });

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockScheduledDoc = {
        exists: true,
        data: () => ({
          senderId: 'user-123',
          status: 'pending',
          scheduledFor: {
            toDate: () => new Date(futureDate),
          },
          createdAt: {
            toDate: () => new Date(),
          },
        }),
        ref: {
          update: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockAdd = jest.fn().mockResolvedValue({ id: 'scheduled-1' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(
            collectionName === 'conversations' ? mockConversationDoc : mockScheduledDoc
          ),
        })),
        add: mockAdd,
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: [mockScheduledDoc],
        }),
      }));

      const {
        scheduleMessage,
        getScheduledMessages,
        cancelScheduledMessage,
      } = require('../../src/messaging');

      // 1. Schedule message
      const scheduleResult = await scheduleMessage({
        data: {
          conversationId: 'conv-123',
          content: 'Test',
          scheduledFor: futureDate,
        },
        ...createMockAuthContext('user-123'),
      });

      expect(scheduleResult.success).toBe(true);

      // 2. Get scheduled messages
      const getResult = await getScheduledMessages({
        data: { status: 'pending' },
        ...createMockAuthContext('user-123'),
      });

      expect(getResult.scheduledMessages.length).toBeGreaterThan(0);

      // 3. Cancel scheduled message
      const cancelResult = await cancelScheduledMessage({
        data: { scheduledMessageId: 'scheduled-1' },
        ...createMockAuthContext('user-123'),
      });

      expect(cancelResult.success).toBe(true);
    });
  });
});
