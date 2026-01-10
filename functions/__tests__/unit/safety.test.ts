/**
 * Safety & Moderation Service Tests
 * Comprehensive tests for all 11 safety functions
 */

import * as admin from 'firebase-admin';
import { FieldValue } from '../../src/shared/utils';
import {
  createMockAuthContext,
} from '../utils/test-helpers';

// Mock Cloud Vision
const mockVisionClient = {
  safeSearchDetection: jest.fn(),
};

jest.mock('@google-cloud/vision', () => ({
  ImageAnnotatorClient: jest.fn(() => mockVisionClient),
}));

// Mock Cloud Natural Language
const mockLanguageClient = {
  analyzeSentiment: jest.fn(),
};

jest.mock('@google-cloud/language', () => ({
  LanguageServiceClient: jest.fn(() => mockLanguageClient),
}));

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  auth: jest.fn(() => ({
    updateUser: jest.fn(),
  })),
  firestore: {
    Timestamp: {
      fromDate: jest.fn((date) => date),
      now: jest.fn(() => new Date()),
    },
    FieldValue: {
      serverTimestamp: jest.fn(() => ({ _type: 'serverTimestamp' })),
      increment: jest.fn((val) => ({ _type: 'increment', value: val })),
      arrayUnion: jest.fn((val) => ({ _type: 'arrayUnion', value: val })),
      arrayRemove: jest.fn((val) => ({ _type: 'arrayRemove', value: val })),
    },
  },
}));

// Mock Firestore
const mockDb = {
  collection: jest.fn(() => ({
    doc: jest.fn(() => ({
      get: jest.fn(),
      set: jest.fn(),
      update: jest.fn(),
      ref: {},
    })),
    add: jest.fn(),
    get: jest.fn(),
    where: jest.fn(),
    orderBy: jest.fn(),
    limit: jest.fn(),
  })),
};

// Mock shared/utils
jest.mock('../../src/shared/utils', () => ({
  db: mockDb,
  FieldValue: {
    serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
    increment: jest.fn((val) => ({ _methodName: 'FieldValue.increment', _value: val })),
    arrayUnion: jest.fn((val) => ({ _methodName: 'FieldValue.arrayUnion', _value: val })),
    arrayRemove: jest.fn((val) => ({ _methodName: 'FieldValue.arrayRemove', _value: val })),
  },
  verifyAuth: jest.fn(),
  verifyAdminAuth: jest.fn(),
  handleError: jest.fn(err => err),
  logInfo: jest.fn(),
  logError: jest.fn(),
}));

const { verifyAuth, verifyAdminAuth, logInfo, logError } = require('../../src/shared/utils');

describe('Safety & Moderation Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ========== 1. MODERATE PHOTO ==========
  describe('moderatePhoto', () => {
    it('should auto-approve safe photo', async () => {
      mockVisionClient.safeSearchDetection.mockResolvedValue([{
        safeSearchAnnotation: {
          adult: 'VERY_UNLIKELY',
          violence: 'UNLIKELY',
          racy: 'POSSIBLE',
          medical: 'VERY_UNLIKELY',
        },
      }]);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'moderation-123' }),
      }));

      const { handleModeratePhoto } = require('../../src/safety/handlers');

      const result = await handleModeratePhoto({
        photoUrl: 'https://example.com/photo.jpg',
        userId: 'user-123',
        requestingUid: 'user-123',
        context: 'profile',
      });

      expect(result).toMatchObject({
        success: true,
        moderationId: 'moderation-123',
        flagged: false,
        action: 'auto_approved',
        categories: [],
      });
    });

    it('should flag photo with adult content', async () => {
      mockVisionClient.safeSearchDetection.mockResolvedValue([{
        safeSearchAnnotation: {
          adult: 'LIKELY',
          violence: 'UNLIKELY',
          racy: 'POSSIBLE',
          medical: 'UNLIKELY',
        },
      }]);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'moderation-124' }),
      }));

      const { handleModeratePhoto } = require('../../src/safety/handlers');

      const result = await handleModeratePhoto({
        photoUrl: 'https://example.com/photo.jpg',
        userId: 'user-123',
        requestingUid: 'user-123',
        context: 'profile',
      });

      expect(result).toMatchObject({
        success: true,
        flagged: true,
        action: 'pending_review',
        categories: expect.arrayContaining(['adult']),
      });
    });

    it('should auto-reject highly inappropriate photo', async () => {
      mockVisionClient.safeSearchDetection.mockResolvedValue([{
        safeSearchAnnotation: {
          adult: 'VERY_LIKELY',
          violence: 'VERY_LIKELY',
          racy: 'VERY_LIKELY',
          medical: 'UNLIKELY',
        },
      }]);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'moderation-125' }),
      }));

      const { handleModeratePhoto } = require('../../src/safety/handlers');

      const result = await handleModeratePhoto({
        photoUrl: 'https://example.com/photo.jpg',
        userId: 'user-123',
        requestingUid: 'user-123',
        context: 'profile',
      });

      expect(result).toMatchObject({
        flagged: true,
        action: 'auto_rejected',
      });
    });

    it('should allow admin to moderate any photo', async () => {
      mockVisionClient.safeSearchDetection.mockResolvedValue([{
        safeSearchAnnotation: {
          adult: 'UNLIKELY',
          violence: 'UNLIKELY',
          racy: 'UNLIKELY',
          medical: 'UNLIKELY',
        },
      }]);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'moderation-126' }),
      }));

      const { handleModeratePhoto } = require('../../src/safety/handlers');

      await handleModeratePhoto({
        photoUrl: 'https://example.com/photo.jpg',
        userId: 'different-user',
        requestingUid: 'admin-user',
        context: 'profile',
      });

      expect(logInfo).toHaveBeenCalledWith(
        expect.stringContaining('Admin admin-user moderating photo')
      );
    });
  });

  // ========== 2. MODERATE TEXT ==========
  describe('moderateText', () => {
    it('should auto-approve clean text', async () => {
      mockLanguageClient.analyzeSentiment.mockResolvedValue([{
        documentSentiment: { score: 0.5 },
      }]);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'moderation-200' }),
      }));

      const { handleModerateText } = require('../../src/safety/handlers');

      const result = await handleModerateText({
        text: 'This is a clean message',
        userId: 'user-123',
        requestingUid: 'user-123',
        context: 'message',
      });

      expect(result).toMatchObject({
        success: true,
        flagged: false,
        action: 'auto_approved',
      });
    });

    it('should flag text with profanity', async () => {
      mockLanguageClient.analyzeSentiment.mockResolvedValue([{
        documentSentiment: { score: -0.3 },
      }]);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'moderation-201' }),
      }));

      const { handleModerateText } = require('../../src/safety/handlers');

      const result = await handleModerateText({
        text: 'You are a fucking idiot',
        userId: 'user-123',
        requestingUid: 'user-123',
        context: 'message',
      });

      expect(result).toMatchObject({
        success: true,
        flagged: true,
        categories: expect.arrayContaining(['hate_speech']),
      });
    });

    it('should handle sentiment analysis errors gracefully', async () => {
      mockLanguageClient.analyzeSentiment.mockRejectedValue(new Error('API error'));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'moderation-202' }),
      }));

      const { handleModerateText } = require('../../src/safety/handlers');

      // Should not throw
      await expect(handleModerateText({
        text: 'This is a clean message',
        userId: 'user-123',
        requestingUid: 'user-123',
        context: 'message',
      })).resolves.toBeDefined();
    });
  });

  // ========== 3. DETECT SPAM ==========
  describe('detectSpam', () => {
    it('should not detect spam in normal content', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'spam-check-1' }),
      }));

      const { handleDetectSpam } = require('../../src/safety/handlers');

      const result = await handleDetectSpam({
        content: 'Normal message content',
        userId: 'user-123',
        type: 'message',
      });

      expect(result).toMatchObject({
        success: true,
        isSpam: false,
        spamScore: 0,
        indicators: [],
      });
    });

    it('should detect spam with excessive links', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'spam-check-2' }),
      }));

      const { handleDetectSpam } = require('../../src/safety/handlers');

      const result = await handleDetectSpam({
        content: 'Check out https://site1.com and https://site2.com and https://site3.com',
        userId: 'user-123',
        type: 'message',
      });

      expect(result).toMatchObject({
        success: true,
        isSpam: false, // Score 0.4, below threshold
        indicators: expect.arrayContaining(['excessive_links']),
      });
    });

    it('should detect promotional spam', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'spam-check-3' }),
      }));

      const { handleDetectSpam } = require('../../src/safety/handlers');

      const result = await handleDetectSpam({
        content: 'Buy now! Limited offer! Click here to subscribe and follow me!',
        userId: 'user-123',
        type: 'message',
      });

      expect(result).toMatchObject({
        success: true,
        isSpam: true,
        indicators: expect.arrayContaining([
          expect.stringContaining('promo_keyword'),
        ]),
      });
    });

    it('should detect ALL CAPS spam', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'spam-check-4' }),
      }));

      const { handleDetectSpam } = require('../../src/safety/handlers');

      const result = await handleDetectSpam({
        content: 'THIS IS A VERY IMPORTANT MESSAGE THAT YOU MUST READ NOW',
        userId: 'user-123',
        type: 'message',
      });

      expect(result.indicators).toContain('excessive_caps');
    });
  });

  // ========== 4. DETECT FAKE PROFILE ==========
  describe('detectFakeProfile', () => {
    it('should detect suspicious new profile', async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({
          bio: 'Hi',
          photos: ['photo1.jpg'],
          createdAt: { toMillis: () => Date.now() - 12 * 60 * 60 * 1000 }, // 12 hours ago
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        })),
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: [], size: 0 }),
        add: jest.fn().mockResolvedValue({ id: 'fake-detection-1' }),
      }));

      const { handleDetectFakeProfile } = require('../../src/safety/handlers');

      const result = await handleDetectFakeProfile({
        userId: 'user-suspect',
      });

      expect(result).toMatchObject({
        success: true,
        isFake: true,
        indicators: expect.arrayContaining([
          'incomplete_bio',
          'few_photos',
          'new_account',
        ]),
      });
    });

    it('should not flag complete active profiles', async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({
          bio: 'This is a complete bio with more than 20 characters describing myself',
          photos: ['photo1.jpg', 'photo2.jpg', 'photo3.jpg'],
          createdAt: { toMillis: () => Date.now() - 30 * 24 * 60 * 60 * 1000 }, // 30 days ago
        }),
      };

      const mockMessages = Array.from({ length: 5 }, (_, i) => ({ id: `msg-${i}` }));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        })),
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: mockMessages, size: 5 }),
        add: jest.fn().mockResolvedValue({ id: 'fake-detection-2' }),
      }));

      const { handleDetectFakeProfile } = require('../../src/safety/handlers');

      const result = await handleDetectFakeProfile({
        userId: 'user-suspect',
      });

      expect(result.isFake).toBe(false);
      expect(result.suspicionScore).toBeLessThan(0.6);
    });
  });

  // ========== 5. DETECT SCAM ==========
  describe('detectScam', () => {
    it('should not detect scam in normal message', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'scam-check-1' }),
      }));

      const { handleDetectScam } = require('../../src/safety/handlers');

      const result = await handleDetectScam({
        conversationId: 'conv-123',
        messageContent: 'Looking forward to meeting you!',
      });

      expect(result).toMatchObject({
        success: true,
        isScam: false,
        scamScore: 0,
        indicators: [],
      });
    });

    it('should detect money request scam', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'scam-check-2' }),
      }));

      const { handleDetectScam } = require('../../src/safety/handlers');

      const result = await handleDetectScam({
        conversationId: 'conv-123',
        messageContent: 'I have an emergency and need you to send me money urgently!',
      });

      expect(result).toMatchObject({
        success: true,
        isScam: true,
        indicators: expect.arrayContaining(['money_request', 'urgency_language']),
      });
    });

    it('should detect external communication requests', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'scam-check-3' }),
      }));

      const { handleDetectScam } = require('../../src/safety/handlers');

      const result = await handleDetectScam({
        conversationId: 'conv-123',
        messageContent: 'Text me at 555-1234 or message me on WhatsApp',
      });

      expect(result.indicators).toContain('external_communication');
    });
  });

  // ========== 6. SUBMIT REPORT ==========
  describe('submitReport', () => {
    it('should submit user report', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'report-123' }),
      }));

      const { handleSubmitReport } = require('../../src/safety/handlers');

      const result = await handleSubmitReport({
        reporterId: 'user-123',
        reportedUserId: 'bad-user',
        reason: 'harassment',
        description: 'This user is harassing me',
        reportedContentId: 'msg-123',
      });

      expect(result).toMatchObject({
        success: true,
        reportId: 'report-123',
        message: 'Report submitted successfully',
      });
    });

    it('should add report to moderation queue', async () => {
      const mockAdd = jest.fn()
        .mockResolvedValueOnce({ id: 'report-124' })
        .mockResolvedValueOnce({ id: 'queue-1' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: mockAdd,
      }));

      const { handleSubmitReport } = require('../../src/safety/handlers');

      await handleSubmitReport({
        reporterId: 'user-123',
        reportedUserId: 'bad-user',
        reason: 'harassment',
        description: 'This user is harassing me',
        reportedContentId: 'msg-123',
      });

      expect(mockAdd).toHaveBeenCalledTimes(2);
    });

    it('should prioritize critical reports', async () => {
      const mockAdd = jest.fn()
        .mockResolvedValueOnce({ id: 'report-125' })
        .mockResolvedValueOnce({ id: 'queue-2' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: mockAdd,
      }));

      const { handleSubmitReport } = require('../../src/safety/handlers');

      await handleSubmitReport({
        reporterId: 'user-123',
        reportedUserId: 'bad-user',
        reason: 'scam',
        description: 'This user is harassing me',
        reportedContentId: 'msg-123',
      });

      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          priority: 'critical',
        })
      );
    });
  });

  // ========== 7. REVIEW REPORT ==========
  describe('reviewReport', () => {
    it('should review and warn reported user', async () => {
      const mockReportDoc = {
        exists: true,
        data: () => ({
          reportedUserId: 'bad-user',
          reason: 'harassment',
        }),
        ref: {
          update: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockUserUpdate = jest.fn().mockResolvedValue(undefined);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockReportDoc),
          update: collectionName === 'users' ? mockUserUpdate : mockReportDoc.ref.update,
        })),
        add: jest.fn().mockResolvedValue({ id: 'audit-log-1' }),
      }));

      const { handleReviewReport } = require('../../src/safety/handlers');

      const result = await handleReviewReport({
        adminUid: 'admin-123',
        reportId: 'report-123',
        action: 'warn',
        notes: 'First warning issued',
      });

      expect(result).toMatchObject({
        success: true,
        message: 'Report warned successfully',
      });

      expect(mockUserUpdate).toHaveBeenCalled();
    });

    it('should suspend reported user', async () => {
      const mockReportDoc = {
        exists: true,
        data: () => ({
          reportedUserId: 'bad-user',
          reason: 'spam',
        }),
        ref: {
          update: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockUserUpdate = jest.fn().mockResolvedValue(undefined);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockReportDoc),
          update: mockUserUpdate,
        })),
        add: jest.fn().mockResolvedValue({ id: 'audit-log-2' }),
      }));

      const { handleReviewReport } = require('../../src/safety/handlers');

      await handleReviewReport({
        adminUid: 'admin-123',
        reportId: 'report-123',
        action: 'suspend',
        notes: 'First warning issued',
      });

      expect(mockUserUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          suspended: true,
          suspendedUntil: expect.anything(),
        })
      );
    });

    it('should ban and disable auth for reported user', async () => {
      const mockReportDoc = {
        exists: true,
        data: () => ({
          reportedUserId: 'very-bad-user',
          reason: 'underage',
        }),
        ref: {
          update: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockUpdateUser = jest.fn().mockResolvedValue(undefined);
      (admin.auth as jest.Mock).mockReturnValue({
        updateUser: mockUpdateUser,
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockReportDoc),
          update: jest.fn().mockResolvedValue(undefined),
        })),
        add: jest.fn().mockResolvedValue({ id: 'audit-log-3' }),
      }));

      const { handleReviewReport } = require('../../src/safety/handlers');

      await handleReviewReport({
        adminUid: 'admin-123',
        reportId: 'report-123',
        action: 'ban',
        notes: 'First warning issued',
      });

      expect(mockUpdateUser).toHaveBeenCalledWith('very-bad-user', { disabled: true });
    });
  });

  // ========== 8. SUBMIT APPEAL ==========
  describe('submitAppeal', () => {
    it('should submit appeal', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'appeal-123' }),
      }));

      const { handleSubmitAppeal } = require('../../src/safety/handlers');

      const result = await handleSubmitAppeal({
        userId: 'user-123',
        reportId: 'report-123',
        appealText: 'I believe this was a misunderstanding...',
      });

      expect(result).toMatchObject({
        success: true,
        appealId: 'appeal-123',
        message: 'Appeal submitted for review',
      });
    });

    it('should reject appeal without text', async () => {
      const { handleSubmitAppeal } = require('../../src/safety/handlers');

      await expect(handleSubmitAppeal({
        userId: 'user-123',
        reportId: 'report-123',
        appealText: '',
      })).rejects.toThrow('appealText is required');
    });
  });

  // ========== 9. BLOCK USER ==========
  describe('blockUser', () => {
    it('should block user', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          update: mockUpdate,
        })),
      }));

      const { handleBlockUser } = require('../../src/safety/handlers');

      const result = await handleBlockUser({
        userId: 'user-123',
        blockedUserId: 'annoying-user',
      });

      expect(result).toMatchObject({
        success: true,
        message: 'User blocked successfully',
      });

      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          blockedUsers: expect.anything(),
        })
      );
    });
  });

  // ========== 10. UNBLOCK USER ==========
  describe('unblockUser', () => {
    it('should unblock user', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          update: mockUpdate,
        })),
      }));

      const { handleUnblockUser } = require('../../src/safety/handlers');

      const result = await handleUnblockUser({
        userId: 'user-123',
        blockedUserId: 'previously-blocked-user',
      });

      expect(result).toMatchObject({
        success: true,
        message: 'User unblocked successfully',
      });

      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          blockedUsers: expect.anything(),
        })
      );
    });
  });

  // ========== 11. GET BLOCK LIST ==========
  describe('getBlockList', () => {
    it('should get user block list', async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({
          blockedUsers: ['user-1', 'user-2', 'user-3'],
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        })),
      }));

      const { handleGetBlockList } = require('../../src/safety/handlers');

      const result = await handleGetBlockList({
        userId: 'user-123',
      });

      expect(result).toMatchObject({
        success: true,
        blockedUsers: ['user-1', 'user-2', 'user-3'],
        total: 3,
      });
    });

    it('should return empty list if no blocks', async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({}),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        })),
      }));

      const { handleGetBlockList } = require('../../src/safety/handlers');

      const result = await handleGetBlockList({
        userId: 'user-123',
      });

      expect(result.blockedUsers).toEqual([]);
      expect(result.total).toBe(0);
    });
  });

  // ========== INTEGRATION TESTS ==========
  describe('Safety Integration', () => {
    it('should handle complete moderation workflow', async () => {
      // Setup mocks
      mockVisionClient.safeSearchDetection.mockResolvedValue([{
        safeSearchAnnotation: {
          adult: 'LIKELY',
          violence: 'UNLIKELY',
          racy: 'POSSIBLE',
          medical: 'UNLIKELY',
        },
      }]);

      const mockReportDoc = {
        exists: true,
        data: () => ({
          reportedUserId: 'bad-user',
          reason: 'inappropriate_content',
        }),
        ref: {
          update: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn()
          .mockResolvedValueOnce({ id: 'moderation-999' })
          .mockResolvedValueOnce({ id: 'queue-1' })
          .mockResolvedValueOnce({ id: 'report-999' })
          .mockResolvedValueOnce({ id: 'queue-2' })
          .mockResolvedValueOnce({ id: 'audit-log-999' }),
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockReportDoc),
          update: jest.fn().mockResolvedValue(undefined),
        })),
      }));

      const {
        handleModeratePhoto,
        handleSubmitReport,
        handleReviewReport,
      } = require('../../src/safety/handlers');

      // 1. Moderate photo (flagged)
      const moderationResult = await handleModeratePhoto({
        photoUrl: 'https://example.com/bad-photo.jpg',
        userId: 'bad-user',
        requestingUid: 'bad-user',
      });

      expect(moderationResult.flagged).toBe(true);

      // 2. Submit report
      const reportResult = await handleSubmitReport({
        reporterId: 'reporter-user',
        reportedUserId: 'bad-user',
        reason: 'inappropriate_content',
        description: 'Inappropriate photo',
      });

      expect(reportResult.success).toBe(true);

      // 3. Admin reviews report
      const reviewResult = await handleReviewReport({
        adminUid: 'admin-123',
        reportId: 'report-999',
        action: 'warn',
      });

      expect(reviewResult.success).toBe(true);
    });
  });
});
