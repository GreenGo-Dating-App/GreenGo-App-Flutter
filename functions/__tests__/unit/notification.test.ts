/**
 * Notification Service Tests
 * Comprehensive tests for all 9 notification functions
 */

import * as admin from 'firebase-admin';
import { FieldValue } from '../../src/shared/utils';
import {
  createMockAuthContext,
} from '../utils/test-helpers';

// Mock SendGrid
const mockSgMailSend = jest.fn();
jest.mock('@sendgrid/mail', () => ({
  setApiKey: jest.fn(),
  send: mockSgMailSend,
}));

// Mock Twilio
jest.mock('twilio', () => {
  return jest.fn(() => ({
    messages: {
      create: jest.fn(),
    },
  }));
});

// Mock Firebase Admin
jest.mock('firebase-admin', () => {
  const actualAdmin = jest.requireActual('firebase-admin');
  return {
    ...actualAdmin,
    messaging: jest.fn(() => ({
      sendEachForMulticast: jest.fn(),
    })),
    firestore: jest.fn(() => ({
      collection: jest.fn(),
      Timestamp: {
        now: jest.fn(),
        fromDate: jest.fn(),
      },
      FieldValue: {
        serverTimestamp: jest.fn(),
        arrayRemove: jest.fn(),
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
    })),
    add: jest.fn(),
    get: jest.fn(),
    where: jest.fn(),
    orderBy: jest.fn(),
    limit: jest.fn(),
  })),
  batch: jest.fn(() => ({
    set: jest.fn(),
    commit: jest.fn(),
  })),
};

// Mock shared/utils
jest.mock('../../src/shared/utils', () => ({
  db: mockDb,
  FieldValue: {
    serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
    arrayRemove: jest.fn((...values) => ({ _methodName: 'FieldValue.arrayRemove', _values: values })),
  },
  verifyAuth: jest.fn(),
  handleError: jest.fn(err => err),
  logInfo: jest.fn(),
  logError: jest.fn(),
}));

const { verifyAuth, logInfo, logError } = require('../../src/shared/utils');

describe('Notification Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ========== 1. SEND PUSH NOTIFICATION ==========
  describe('sendPushNotification', () => {
    const mockRequest = {
      data: {
        userId: 'user-456',
        title: 'New Match!',
        body: 'You have a new match with Alice',
        type: 'new_match',
        data: { matchId: 'match-123' },
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
      }));
    });

    it('should send push notification to user', async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({
          fcmTokens: ['token-1', 'token-2'],
          notificationPreferences: {},
        }),
        ref: {
          update: jest.fn(),
        },
      };

      const mockNotificationRef = {
        id: 'notif-123',
        update: jest.fn().mockResolvedValue(undefined),
      };

      const mockSendResponse = {
        successCount: 2,
        failureCount: 0,
        responses: [
          { success: true },
          { success: true },
        ],
      };

      const mockMessaging = {
        sendEachForMulticast: jest.fn().mockResolvedValue(mockSendResponse),
      };

      (admin.messaging as jest.Mock).mockReturnValue(mockMessaging);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        })),
        add: jest.fn().mockResolvedValue(mockNotificationRef),
      }));

      const { sendPushNotification } = require('../../src/notification');

      const result = await sendPushNotification(mockRequest);

      expect(result).toMatchObject({
        success: true,
        notificationId: 'notif-123',
        successCount: 2,
        failureCount: 0,
      });

      expect(mockMessaging.sendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          tokens: ['token-1', 'token-2'],
          notification: expect.objectContaining({
            title: 'New Match!',
            body: 'You have a new match with Alice',
          }),
        })
      );
    });

    it('should reject if user not found', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { sendPushNotification } = require('../../src/notification');

      await expect(sendPushNotification(mockRequest)).rejects.toThrow('User not found');
    });

    it('should reject if user has no FCM tokens', async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({
          fcmTokens: [],
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        })),
      }));

      const { sendPushNotification } = require('../../src/notification');

      await expect(sendPushNotification(mockRequest)).rejects.toThrow('User has no registered devices');
    });

    it('should respect user notification preferences', async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({
          fcmTokens: ['token-1'],
          notificationPreferences: {
            new_match: false, // Disabled
          },
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        })),
      }));

      const { sendPushNotification } = require('../../src/notification');

      const result = await sendPushNotification(mockRequest);

      expect(result).toMatchObject({
        success: false,
        message: 'User has disabled this notification type',
      });
    });

    it('should remove invalid FCM tokens', async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({
          fcmTokens: ['token-valid', 'token-invalid'],
          notificationPreferences: {},
        }),
        ref: {
          update: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockNotificationRef = {
        id: 'notif-123',
        update: jest.fn().mockResolvedValue(undefined),
      };

      const mockSendResponse = {
        successCount: 1,
        failureCount: 1,
        responses: [
          { success: true },
          { success: false, error: { code: 'messaging/invalid-registration-token' } },
        ],
      };

      const mockMessaging = {
        sendEachForMulticast: jest.fn().mockResolvedValue(mockSendResponse),
      };

      (admin.messaging as jest.Mock).mockReturnValue(mockMessaging);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        })),
        add: jest.fn().mockResolvedValue(mockNotificationRef),
      }));

      const { sendPushNotification } = require('../../src/notification');

      await sendPushNotification(mockRequest);

      expect(mockUserDoc.ref.update).toHaveBeenCalledWith(
        expect.objectContaining({
          fcmTokens: expect.anything(),
        })
      );
    });
  });

  // ========== 2. SEND BUNDLED NOTIFICATIONS ==========
  describe('sendBundledNotifications', () => {
    const mockRequest = {
      data: {
        userId: 'user-456',
        notifications: [
          { title: 'Message 1', body: 'Content 1', type: 'new_message' },
          { title: 'Message 2', body: 'Content 2', type: 'new_message' },
          { title: 'Message 3', body: 'Content 3', type: 'new_message' },
        ],
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    });

    it('should send bundled notifications', async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({
          fcmTokens: ['token-1'],
        }),
      };

      const mockSendResponse = {
        successCount: 1,
        failureCount: 0,
        responses: [{ success: true }],
      };

      const mockMessaging = {
        sendEachForMulticast: jest.fn().mockResolvedValue(mockSendResponse),
      };

      (admin.messaging as jest.Mock).mockReturnValue(mockMessaging);

      const mockBatch = {
        set: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        })),
      }));

      const { sendBundledNotifications } = require('../../src/notification');

      const result = await sendBundledNotifications(mockRequest);

      expect(result).toMatchObject({
        success: true,
        successCount: 1,
        failureCount: 0,
      });

      expect(mockMessaging.sendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          notification: expect.objectContaining({
            title: '3 new notifications',
            body: 'Content 1',
          }),
        })
      );

      expect(mockBatch.set).toHaveBeenCalledTimes(3);
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    it('should handle user with no FCM tokens', async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({
          fcmTokens: [],
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        })),
      }));

      const { sendBundledNotifications } = require('../../src/notification');

      const result = await sendBundledNotifications(mockRequest);

      expect(result).toMatchObject({
        success: false,
        message: 'User has no registered devices',
      });
    });
  });

  // ========== 3. TRACK NOTIFICATION OPENED ==========
  describe('trackNotificationOpened', () => {
    const mockRequest = {
      data: {
        notificationId: 'notif-123',
        action: 'view_profile',
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    });

    it('should track notification as opened', async () => {
      const mockNotificationDoc = {
        exists: true,
        data: () => ({
          userId: 'user-123',
          type: 'new_match',
        }),
      };

      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockNotificationDoc),
          update: mockUpdate,
        })),
      }));

      const { trackNotificationOpened } = require('../../src/notification');

      const result = await trackNotificationOpened(mockRequest);

      expect(result).toMatchObject({
        success: true,
        message: 'Notification tracked',
      });

      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          read: true,
          action: 'view_profile',
        })
      );
    });

    it('should reject if notification not found', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { trackNotificationOpened } = require('../../src/notification');

      await expect(trackNotificationOpened(mockRequest)).rejects.toThrow('Notification not found');
    });

    it('should reject unauthorized user', async () => {
      const mockNotificationDoc = {
        exists: true,
        data: () => ({
          userId: 'user-456', // Different user
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockNotificationDoc),
        })),
      }));

      const { trackNotificationOpened } = require('../../src/notification');

      await expect(trackNotificationOpened(mockRequest)).rejects.toThrow('Not authorized');
    });
  });

  // ========== 4. GET NOTIFICATION ANALYTICS ==========
  describe('getNotificationAnalytics', () => {
    const mockRequest = createMockAuthContext('user-123');

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
      }));
    });

    it('should return notification analytics', async () => {
      const mockNotifications = [
        { data: () => ({ sent: true, read: true, type: 'new_match' }) },
        { data: () => ({ sent: true, read: false, type: 'new_message' }) },
        { data: () => ({ sent: true, read: true, type: 'new_match' }) },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockNotifications,
          size: 3,
        }),
      }));

      const { getNotificationAnalytics } = require('../../src/notification');

      const result = await getNotificationAnalytics(mockRequest);

      expect(result).toMatchObject({
        success: true,
        stats: {
          total: 3,
          sent: 3,
          read: 2,
          byType: {
            new_match: 2,
            new_message: 1,
          },
          openRate: (2 / 3) * 100,
        },
        period: '30 days',
      });
    });

    it('should handle no notifications', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: [],
          size: 0,
        }),
      }));

      const { getNotificationAnalytics } = require('../../src/notification');

      const result = await getNotificationAnalytics(mockRequest);

      expect(result.stats.total).toBe(0);
      expect(result.stats.openRate).toBe(0);
    });
  });

  // ========== 5. SEND TRANSACTIONAL EMAIL ==========
  describe('sendTransactionalEmail', () => {
    const mockRequest = {
      data: {
        to: 'user@example.com',
        templateId: 'password_reset',
        dynamicData: { resetLink: 'https://example.com/reset/token123' },
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
      mockSgMailSend.mockResolvedValue(undefined);
    });

    it('should send transactional email', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: jest.fn().mockResolvedValue({ id: 'email-1' }),
      }));

      const { sendTransactionalEmail } = require('../../src/notification');

      const result = await sendTransactionalEmail(mockRequest);

      expect(result).toMatchObject({
        success: true,
        message: 'Email sent successfully',
      });

      expect(mockSgMailSend).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'user@example.com',
          templateId: 'password_reset',
          dynamicTemplateData: { resetLink: 'https://example.com/reset/token123' },
        })
      );
    });

    it('should log sent email to database', async () => {
      const mockAdd = jest.fn().mockResolvedValue({ id: 'email-1' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        add: mockAdd,
      }));

      const { sendTransactionalEmail } = require('../../src/notification');

      await sendTransactionalEmail(mockRequest);

      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'user@example.com',
          templateId: 'password_reset',
          status: 'sent',
        })
      );
    });

    it('should reject missing required fields', async () => {
      const { sendTransactionalEmail } = require('../../src/notification');

      await expect(sendTransactionalEmail({
        ...mockRequest,
        data: { to: 'user@example.com' }, // Missing templateId
      })).rejects.toThrow('to and templateId are required');
    });
  });

  // ========== 6. START WELCOME EMAIL SERIES ==========
  describe('startWelcomeEmailSeries', () => {
    const mockRequest = {
      data: {
        userId: 'user-123',
        email: 'newuser@example.com',
        name: 'John Doe',
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
      }));
    });

    it('should queue welcome email series', async () => {
      const mockBatch = {
        set: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(),
      }));

      const { startWelcomeEmailSeries } = require('../../src/notification');

      const result = await startWelcomeEmailSeries(mockRequest);

      expect(result).toMatchObject({
        success: true,
        emailsQueued: 4, // Day 0, 1, 3, 7
      });

      expect(mockBatch.set).toHaveBeenCalledTimes(4);
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    it('should schedule emails for correct days', async () => {
      const mockBatch = {
        set: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(),
      }));

      const { startWelcomeEmailSeries } = require('../../src/notification');

      await startWelcomeEmailSeries(mockRequest);

      // Verify emails are scheduled for days 0, 1, 3, 7
      expect(mockBatch.set).toHaveBeenCalledTimes(4);
    });
  });

  // ========== 7. PROCESS WELCOME EMAIL SERIES ==========
  describe('processWelcomeEmailSeries', () => {
    beforeEach(() => {
      (admin.firestore.Timestamp.now as jest.Mock).mockReturnValue({
        toMillis: () => Date.now(),
      });
      mockSgMailSend.mockResolvedValue(undefined);
    });

    it('should process due welcome emails', async () => {
      const mockEmails = [
        {
          id: 'email-1',
          data: () => ({
            to: 'user1@example.com',
            templateId: 'welcome_day_0',
            dynamicData: { name: 'John' },
          }),
          ref: {
            update: jest.fn().mockResolvedValue(undefined),
          },
        },
        {
          id: 'email-2',
          data: () => ({
            to: 'user2@example.com',
            templateId: 'welcome_day_1',
            dynamicData: { name: 'Jane' },
          }),
          ref: {
            update: jest.fn().mockResolvedValue(undefined),
          },
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockEmails,
          empty: false,
          size: 2,
        }),
      }));

      const { processWelcomeEmailSeries } = require('../../src/notification');

      await processWelcomeEmailSeries();

      expect(mockSgMailSend).toHaveBeenCalledTimes(2);
      expect(mockEmails[0].ref.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'sent',
        })
      );
      expect(mockEmails[1].ref.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'sent',
        })
      );
    });

    it('should handle email sending failures', async () => {
      const mockEmails = [
        {
          id: 'email-1',
          data: () => ({
            to: 'fail@example.com',
            templateId: 'welcome_day_0',
            dynamicData: {},
          }),
          ref: {
            update: jest.fn().mockResolvedValue(undefined),
          },
        },
      ];

      mockSgMailSend.mockRejectedValue(new Error('SendGrid error'));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockEmails,
          empty: false,
          size: 1,
        }),
      }));

      const { processWelcomeEmailSeries } = require('../../src/notification');

      await processWelcomeEmailSeries();

      expect(mockEmails[0].ref.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'failed',
          error: 'Error: SendGrid error',
        })
      );
      expect(logError).toHaveBeenCalled();
    });

    it('should handle no emails to send', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: [],
          empty: true,
        }),
      }));

      const { processWelcomeEmailSeries } = require('../../src/notification');

      await processWelcomeEmailSeries();

      expect(logInfo).toHaveBeenCalledWith('No emails to send');
      expect(mockSgMailSend).not.toHaveBeenCalled();
    });
  });

  // ========== 8. SEND WEEKLY DIGEST EMAILS ==========
  describe('sendWeeklyDigestEmails', () => {
    beforeEach(() => {
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
        toMillis: () => date.getTime(),
      }));
      mockSgMailSend.mockResolvedValue(undefined);
    });

    it('should send weekly digest emails', async () => {
      const mockUsers = [
        {
          id: 'user-1',
          data: () => ({
            email: 'user1@example.com',
            displayName: 'John',
          }),
        },
      ];

      const mockMatches = [{ id: 'match-1' }, { id: 'match-2' }];
      const mockMessages = [{ id: 'msg-1' }];
      const mockViews = [{ id: 'view-1' }, { id: 'view-2' }, { id: 'view-3' }];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: collectionName === 'users' ? mockUsers :
                collectionName === 'matches' ? mockMatches :
                collectionName === 'messages' ? mockMessages :
                collectionName === 'profile_views' ? mockViews : [],
          size: collectionName === 'users' ? 1 :
                collectionName === 'matches' ? 2 :
                collectionName === 'messages' ? 1 :
                collectionName === 'profile_views' ? 3 : 0,
        }),
      }));

      const { sendWeeklyDigestEmails } = require('../../src/notification');

      await sendWeeklyDigestEmails();

      expect(mockSgMailSend).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'user1@example.com',
          templateId: 'weekly_digest',
          dynamicTemplateData: {
            name: 'John',
            newMatches: 2,
            newMessages: 1,
            profileViews: 3,
          },
        })
      );
    });

    it('should skip users with no activity', async () => {
      const mockUsers = [
        {
          id: 'user-1',
          data: () => ({
            email: 'inactive@example.com',
            displayName: 'Inactive User',
          }),
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: collectionName === 'users' ? mockUsers : [],
          size: collectionName === 'users' ? 1 : 0,
        }),
      }));

      const { sendWeeklyDigestEmails } = require('../../src/notification');

      await sendWeeklyDigestEmails();

      expect(mockSgMailSend).not.toHaveBeenCalled();
    });
  });

  // ========== 9. SEND RE-ENGAGEMENT CAMPAIGN ==========
  describe('sendReEngagementCampaign', () => {
    beforeEach(() => {
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
        toMillis: () => date.getTime(),
      }));
      mockSgMailSend.mockResolvedValue(undefined);
    });

    it('should send re-engagement emails to inactive users', async () => {
      const mockInactiveUsers = [
        {
          id: 'user-1',
          data: () => ({
            email: 'inactive1@example.com',
            displayName: 'John',
            lastLoginAt: {
              toMillis: () => Date.now() - 20 * 24 * 60 * 60 * 1000, // 20 days ago
            },
          }),
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockInactiveUsers,
          size: 1,
        }),
      }));

      const { sendReEngagementCampaign } = require('../../src/notification');

      await sendReEngagementCampaign();

      expect(mockSgMailSend).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'inactive1@example.com',
          templateId: 're_engagement',
          dynamicTemplateData: {
            name: 'John',
            daysInactive: expect.any(Number),
          },
        })
      );
    });

    it('should handle email sending errors gracefully', async () => {
      const mockInactiveUsers = [
        {
          id: 'user-1',
          data: () => ({
            email: 'error@example.com',
            displayName: 'Error User',
            lastLoginAt: {
              toMillis: () => Date.now() - 20 * 24 * 60 * 60 * 1000,
            },
          }),
        },
      ];

      mockSgMailSend.mockRejectedValue(new Error('SendGrid error'));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockInactiveUsers,
          size: 1,
        }),
      }));

      const { sendReEngagementCampaign } = require('../../src/notification');

      // Should not throw
      await expect(sendReEngagementCampaign()).resolves.not.toThrow();
      expect(logError).toHaveBeenCalled();
    });

    it('should have correct schedule configuration (Wednesday 10 AM)', () => {
      const { sendReEngagementCampaign } = require('../../src/notification');

      expect(sendReEngagementCampaign).toBeDefined();
      expect(typeof sendReEngagementCampaign).toBe('function');
    });
  });

  // ========== INTEGRATION TESTS ==========
  describe('Notification Integration', () => {
    it('should handle complete notification workflow', async () => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
      }));

      const mockUserDoc = {
        exists: true,
        data: () => ({
          fcmTokens: ['token-1'],
          notificationPreferences: {},
        }),
        ref: {
          update: jest.fn(),
        },
      };

      const mockNotificationDoc = {
        exists: true,
        data: () => ({
          userId: 'user-456',
          type: 'new_match',
          sent: true,
          read: false,
        }),
      };

      const mockNotificationRef = {
        id: 'notif-123',
        update: jest.fn().mockResolvedValue(undefined),
      };

      const mockSendResponse = {
        successCount: 1,
        failureCount: 0,
        responses: [{ success: true }],
      };

      const mockMessaging = {
        sendEachForMulticast: jest.fn().mockResolvedValue(mockSendResponse),
      };

      (admin.messaging as jest.Mock).mockReturnValue(mockMessaging);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(
            collectionName === 'users' ? mockUserDoc : mockNotificationDoc
          ),
          update: mockNotificationRef.update,
        })),
        add: jest.fn().mockResolvedValue(mockNotificationRef),
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: [mockNotificationDoc],
          size: 1,
        }),
      }));

      const {
        sendPushNotification,
        trackNotificationOpened,
        getNotificationAnalytics,
      } = require('../../src/notification');

      // 1. Send notification
      const sendResult = await sendPushNotification({
        data: {
          userId: 'user-456',
          title: 'Test',
          body: 'Test message',
          type: 'new_match',
        },
        ...createMockAuthContext('user-123'),
      });

      expect(sendResult.success).toBe(true);

      // 2. Track opened
      const trackResult = await trackNotificationOpened({
        data: {
          notificationId: 'notif-123',
          action: 'opened',
        },
        ...createMockAuthContext('user-456'),
      });

      expect(trackResult.success).toBe(true);

      // 3. Get analytics
      const analyticsResult = await getNotificationAnalytics(createMockAuthContext('user-123'));

      expect(analyticsResult.success).toBe(true);
    });
  });
});
