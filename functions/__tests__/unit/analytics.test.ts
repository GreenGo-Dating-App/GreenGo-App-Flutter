/**
 * Analytics Service Unit Tests
 * Tests for 22 analytics, metrics, and business intelligence functions
 */

import { describe, it, expect, jest, beforeEach, afterEach } from '@jest/globals';
import * as admin from 'firebase-admin';

// Mock BigQuery
const mockBigQuery = {
  dataset: jest.fn().mockReturnThis(),
  table: jest.fn().mockReturnThis(),
  insert: jest.fn().mockResolvedValue(undefined),
  query: jest.fn().mockResolvedValue([[]]),
};

jest.mock('@google-cloud/bigquery', () => ({
  BigQuery: jest.fn(() => mockBigQuery),
}));

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  firestore: {
    FieldValue: {
      serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
    },
    Timestamp: {
      fromDate: jest.fn((date) => ({
        toMillis: () => date.getTime(),
        toDate: () => date,
      })),
    },
  },
}));

// Mock shared utils
const mockDb = {
  collection: jest.fn(),
  batch: jest.fn(),
};

jest.mock('../../src/shared/utils', () => ({
  verifyAuth: jest.fn(),
  verifyAdminAuth: jest.fn(),
  handleError: jest.fn((error) => error),
  logInfo: jest.fn(),
  logError: jest.fn(),
  db: mockDb,
  FieldValue: {
    serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
  },
}));

// Import after mocks
import {
  trackEvent,
  autoTrackUserEvent,
  getRevenueDashboard,
  getMRRTrends,
  getCohortAnalysis,
  getRetentionRates,
  predictChurn,
  getChurnRiskSegment,
  scheduledChurnPrediction,
  createABTest,
  assignABTestVariant,
  getABTestResults,
  endABTest,
  getUserMetrics,
  getEngagementMetrics,
  getConversionMetrics,
  getMatchQualityMetrics,
  createUserSegment,
  getUserSegments,
  getUsersInSegment,
  updateSegmentCriteria,
  deleteUserSegment,
} from '../../src/analytics';

const { verifyAuth, verifyAdminAuth } = require('../../src/shared/utils');

describe('Analytics Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    (verifyAdminAuth as jest.Mock).mockResolvedValue(undefined);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  // ========== EVENT TRACKING ==========

  describe('trackEvent', () => {
    it('should track custom event in Firestore and BigQuery', async () => {
      const mockAdd = jest.fn().mockResolvedValue({ id: 'event-123' });

      mockDb.collection.mockReturnValue({ add: mockAdd });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          eventName: 'profile_viewed',
          eventData: { viewedUserId: 'user-456' },
        },
      };

      // @ts-ignore
      const result = await trackEvent(request);

      expect(result.success).toBe(true);
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-123',
          eventName: 'profile_viewed',
          eventData: { viewedUserId: 'user-456' },
        })
      );
      expect(mockBigQuery.insert).toHaveBeenCalled();
    });

    it('should track event without event data', async () => {
      const mockAdd = jest.fn().mockResolvedValue({ id: 'event-123' });

      mockDb.collection.mockReturnValue({ add: mockAdd });

      const request = {
        auth: { uid: 'user-123' },
        data: { eventName: 'app_opened' },
      };

      // @ts-ignore
      const result = await trackEvent(request);

      expect(result.success).toBe(true);
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          eventData: {},
        })
      );
    });
  });

  describe('autoTrackUserEvent', () => {
    it('should auto-track user signup event', async () => {
      const event = {
        params: { userId: 'user-123' },
        data: {
          data: () => ({
            email: 'user@example.com',
            subscriptionTier: 'basic',
          }),
        },
      };

      // @ts-ignore
      await autoTrackUserEvent(event);

      expect(mockBigQuery.insert).toHaveBeenCalledWith([
        expect.objectContaining({
          user_id: 'user-123',
          event_name: 'user_signup',
        }),
      ]);
    });
  });

  // ========== REVENUE ANALYTICS ==========

  describe('getRevenueDashboard', () => {
    it('should fetch revenue dashboard with BigQuery', async () => {
      const mockRows = [
        {
          date: '2024-01-15',
          subscription_revenue: 100,
          coin_revenue: 50,
          new_subscribers: 5,
          coin_purchasers: 10,
        },
        {
          date: '2024-01-16',
          subscription_revenue: 150,
          coin_revenue: 75,
          new_subscribers: 7,
          coin_purchasers: 15,
        },
      ];

      mockBigQuery.query.mockResolvedValue([mockRows]);

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          startDate: '2024-01-01',
          endDate: '2024-01-31',
        },
      };

      // @ts-ignore
      const result = await getRevenueDashboard(request);

      expect(result.success).toBe(true);
      expect(parseFloat(result.dashboard.totalRevenue)).toBeCloseTo(375, 2);
      expect(parseFloat(result.dashboard.subscriptionRevenue)).toBeCloseTo(250, 2);
      expect(parseFloat(result.dashboard.coinRevenue)).toBeCloseTo(125, 2);
      expect(result.dashboard.dailyBreakdown).toHaveLength(2);
    });

    it('should require admin authentication', async () => {
      (verifyAdminAuth as jest.Mock).mockRejectedValue(new Error('Not admin'));

      const request = {
        auth: { uid: 'user-123' },
        data: { startDate: '2024-01-01', endDate: '2024-01-31' },
      };

      // @ts-ignore
      await expect(getRevenueDashboard(request)).rejects.toThrow('Not admin');
    });
  });

  describe('getMRRTrends', () => {
    it('should calculate MRR trends by month', async () => {
      const mockSnapshot = {
        docs: [
          {
            data: () => ({
              tier: 'silver',
              createdAt: { toDate: () => new Date('2024-01-15') },
            }),
          },
          {
            data: () => ({
              tier: 'gold',
              createdAt: { toDate: () => new Date('2024-01-20') },
            }),
          },
          {
            data: () => ({
              tier: 'silver',
              createdAt: { toDate: () => new Date('2024-02-05') },
            }),
          },
        ],
      };

      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          startDate: '2024-01-01',
          endDate: '2024-02-28',
        },
      };

      // @ts-ignore
      const result = await getMRRTrends(request);

      expect(result.success).toBe(true);
      expect(result.trends['2024-01'].mrr).toBeCloseTo(29.98, 2); // 9.99 + 19.99
      expect(result.trends['2024-01'].subscribers).toBe(2);
      expect(result.trends['2024-02'].mrr).toBeCloseTo(9.99, 2);
    });
  });

  // ========== COHORT ANALYSIS ==========

  describe('getCohortAnalysis', () => {
    it('should fetch cohort analysis from BigQuery', async () => {
      const mockRows = [
        { cohort_date: '2024-01-01', activity_date: '2024-01-01', users: 100 },
        { cohort_date: '2024-01-01', activity_date: '2024-01-08', users: 80 },
      ];

      mockBigQuery.query.mockResolvedValue([mockRows]);

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          cohortType: 'weekly',
          startDate: '2024-01-01',
          endDate: '2024-01-31',
        },
      };

      // @ts-ignore
      const result = await getCohortAnalysis(request);

      expect(result.success).toBe(true);
      expect(result.cohorts).toHaveLength(2);
    });
  });

  describe('getRetentionRates', () => {
    it('should calculate retention rates for cohort', async () => {
      const mockCohortSnapshot = { size: 100 };
      const mockActiveSnapshot = { size: 80 };

      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        get: jest.fn()
          .mockResolvedValueOnce(mockCohortSnapshot)
          .mockResolvedValue(mockActiveSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          cohortDate: '2024-01-01',
          weeks: 4,
        },
      };

      // @ts-ignore
      const result = await getRetentionRates(request);

      expect(result.success).toBe(true);
      expect(result.cohortSize).toBe(100);
      expect(Object.keys(result.retentionByWeek)).toHaveLength(4);
    });
  });

  // ========== CHURN PREDICTION ==========

  describe('predictChurn', () => {
    it('should predict churn for specific user', async () => {
      const mockUserDoc = {
        exists: true,
        id: 'user-123',
        data: () => ({
          lastActiveAt: { toMillis: () => Date.now() - 20 * 24 * 60 * 60 * 1000 },
          stats: {
            totalMessages: 10,
            matchesLast30Days: 0,
          },
          subscriptionCancelled: false,
        }),
      };

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { userId: 'user-123' },
      };

      // @ts-ignore
      const result = await predictChurn(request);

      expect(result.success).toBe(true);
      expect(result.predictions).toHaveLength(1);
      expect(result.predictions[0].churnRisk).toBeGreaterThan(0);
      expect(result.predictions[0].factors).toContain('inactive_14_days');
    });

    it('should predict churn for batch of users', async () => {
      const mockSnapshot = {
        docs: [
          {
            id: 'user-1',
            data: () => ({
              lastActiveAt: { toMillis: () => Date.now() - 40 * 24 * 60 * 60 * 1000 },
              stats: {},
            }),
          },
          {
            id: 'user-2',
            data: () => ({
              lastActiveAt: { toMillis: () => Date.now() - 2 * 24 * 60 * 60 * 1000 },
              stats: { totalMessages: 100 },
            }),
          },
        ],
      };

      mockDb.collection.mockReturnValue({
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { batchSize: 10 },
      };

      // @ts-ignore
      const result = await predictChurn(request);

      expect(result.success).toBe(true);
      expect(result.predictions).toHaveLength(2);
      expect(result.predictions[0].churnRisk).toBeGreaterThan(result.predictions[1].churnRisk);
    });
  });

  describe('getChurnRiskSegment', () => {
    it('should fetch users at churn risk', async () => {
      const mockSnapshot = {
        docs: [
          {
            id: 'user-1',
            data: () => ({
              displayName: 'Inactive User',
              lastActiveAt: { toDate: () => new Date(Date.now() - 20 * 24 * 60 * 60 * 1000) },
              subscriptionTier: 'gold',
            }),
          },
        ],
      };

      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { threshold: 50, limit: 100 },
      };

      // @ts-ignore
      const result = await getChurnRiskSegment(request);

      expect(result.success).toBe(true);
      expect(result.churnRiskUsers).toHaveLength(1);
      expect(result.count).toBe(1);
    });
  });

  describe('scheduledChurnPrediction', () => {
    it('should run scheduled churn prediction', async () => {
      const mockSnapshot = {
        docs: [
          {
            id: 'user-1',
            data: () => ({
              lastActiveAt: { toMillis: () => Date.now() - 40 * 24 * 60 * 60 * 1000 },
            }),
          },
          {
            id: 'user-2',
            data: () => ({
              lastActiveAt: { toMillis: () => Date.now() - 20 * 24 * 60 * 60 * 1000 },
            }),
          },
        ],
      };

      const mockBatch = {
        set: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'users') {
          return {
            where: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue(mockSnapshot),
          };
        }
        if (collName === 'churn_predictions') {
          return {
            doc: jest.fn().mockReturnValue({}),
          };
        }
        return {};
      });

      mockDb.batch.mockReturnValue(mockBatch);

      // @ts-ignore
      await scheduledChurnPrediction({});

      expect(mockBatch.set).toHaveBeenCalled();
      expect(mockBatch.commit).toHaveBeenCalled();
    });
  });

  // ========== A/B TESTING ==========

  describe('createABTest', () => {
    it('should create A/B test successfully', async () => {
      const mockAdd = jest.fn().mockResolvedValue({ id: 'test-123' });

      mockDb.collection.mockReturnValue({ add: mockAdd });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          name: 'New Button Color Test',
          description: 'Testing green vs blue button',
          variants: [
            { name: 'control', weight: 50 },
            { name: 'variant_a', weight: 50 },
          ],
          startDate: '2024-01-01',
          endDate: '2024-01-31',
        },
      };

      // @ts-ignore
      const result = await createABTest(request);

      expect(result.success).toBe(true);
      expect(result.testId).toBe('test-123');
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'New Button Color Test',
          status: 'active',
        })
      );
    });
  });

  describe('assignABTestVariant', () => {
    it('should assign variant to new user', async () => {
      const mockExistingSnapshot = { empty: true };
      const mockTestDoc = {
        exists: true,
        data: () => ({
          variants: [
            { name: 'control', weight: 50 },
            { name: 'variant_a', weight: 50 },
          ],
        }),
      };
      const mockAdd = jest.fn().mockResolvedValue({ id: 'assignment-123' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'ab_test_assignments') {
          return {
            where: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue(mockExistingSnapshot),
            add: mockAdd,
          };
        }
        if (collName === 'ab_tests') {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(mockTestDoc),
            }),
          };
        }
        return {};
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { testId: 'test-456' },
      };

      // @ts-ignore
      const result = await assignABTestVariant(request);

      expect(result.success).toBe(true);
      expect(result.variant).toBeDefined();
      expect(['control', 'variant_a']).toContain(result.variant);
      expect(mockAdd).toHaveBeenCalled();
    });

    it('should return existing variant for user', async () => {
      const mockExistingSnapshot = {
        empty: false,
        docs: [
          { data: () => ({ variant: 'control' }) },
        ],
      };

      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockExistingSnapshot),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { testId: 'test-456' },
      };

      // @ts-ignore
      const result = await assignABTestVariant(request);

      expect(result.success).toBe(true);
      expect(result.variant).toBe('control');
    });
  });

  describe('getABTestResults', () => {
    it('should fetch A/B test results', async () => {
      const mockSnapshot = {
        size: 100,
        docs: [
          { data: () => ({ variant: 'control' }) },
          { data: () => ({ variant: 'control' }) },
          { data: () => ({ variant: 'variant_a' }) },
        ],
      };

      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { testId: 'test-123' },
      };

      // @ts-ignore
      const result = await getABTestResults(request);

      expect(result.success).toBe(true);
      expect(result.results.totalAssignments).toBe(100);
      expect(result.results.variantCounts.control).toBe(2);
      expect(result.results.variantCounts.variant_a).toBe(1);
    });
  });

  describe('endABTest', () => {
    it('should end A/B test', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { testId: 'test-123' },
      };

      // @ts-ignore
      const result = await endABTest(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'ended',
        })
      );
    });
  });

  // ========== METRICS ==========

  describe('getUserMetrics', () => {
    it('should fetch metrics for user', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              stats: {
                totalMatches: 50,
                totalMessages: 500,
                totalCalls: 10,
                profileViews: 200,
                likes: 75,
                superLikes: 5,
              },
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { userId: 'user-123' },
      };

      // @ts-ignore
      const result = await getUserMetrics(request);

      expect(result.success).toBe(true);
      expect(result.metrics.totalMatches).toBe(50);
      expect(result.metrics.totalMessages).toBe(500);
    });
  });

  describe('getEngagementMetrics', () => {
    it('should fetch platform engagement metrics', async () => {
      const mockMatchesSnapshot = { size: 1000 };
      const mockMessagesSnapshot = { size: 10000 };
      const mockCallsSnapshot = { size: 500 };

      mockDb.collection.mockImplementation((collName: string) => {
        return {
          where: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue(
            collName === 'matches' ? mockMatchesSnapshot :
            collName === 'messages' ? mockMessagesSnapshot :
            mockCallsSnapshot
          ),
        };
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          startDate: '2024-01-01',
          endDate: '2024-01-31',
        },
      };

      // @ts-ignore
      const result = await getEngagementMetrics(request);

      expect(result.success).toBe(true);
      expect(result.metrics.totalMatches).toBe(1000);
      expect(result.metrics.totalMessages).toBe(10000);
      expect(result.metrics.totalCalls).toBe(500);
    });
  });

  describe('getConversionMetrics', () => {
    it('should calculate conversion rates', async () => {
      const mockSnapshot = {
        size: 100,
        docs: [
          { data: () => ({ subscriptionTier: 'silver' }) },
          { data: () => ({ subscriptionTier: 'gold' }) },
          { data: () => ({ subscriptionTier: 'basic' }) },
          { data: () => ({ subscriptionTier: 'basic' }) },
        ],
      };

      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          startDate: '2024-01-01',
          endDate: '2024-01-31',
        },
      };

      // @ts-ignore
      const result = await getConversionMetrics(request);

      expect(result.success).toBe(true);
      expect(result.metrics.totalSignups).toBe(100);
      expect(result.metrics.convertedToSubscriber).toBe(2);
      expect(result.metrics.conversionRate).toBe('2.00%');
    });
  });

  describe('getMatchQualityMetrics', () => {
    it('should calculate match quality metrics', async () => {
      const mockMatchesSnapshot = {
        size: 100,
        docs: [
          { data: () => ({ conversationId: 'conv-1' }) },
          { data: () => ({ conversationId: 'conv-2' }) },
        ],
      };

      const mockMessagesSnapshot = { empty: false };
      const mockCallsSnapshot = { empty: true };

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'matches') {
          return {
            where: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue(mockMatchesSnapshot),
          };
        }
        if (collName === 'messages') {
          return {
            where: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue(mockMessagesSnapshot),
          };
        }
        if (collName === 'calls') {
          return {
            where: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue(mockCallsSnapshot),
          };
        }
        return {};
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          startDate: '2024-01-01',
          endDate: '2024-01-31',
        },
      };

      // @ts-ignore
      const result = await getMatchQualityMetrics(request);

      expect(result.success).toBe(true);
      expect(result.metrics.totalMatches).toBe(100);
    });
  });

  // ========== SEGMENTATION ==========

  describe('createUserSegment', () => {
    it('should create user segment successfully', async () => {
      const mockAdd = jest.fn().mockResolvedValue({ id: 'segment-123' });

      mockDb.collection.mockReturnValue({ add: mockAdd });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          name: 'High Value Users',
          description: 'Gold tier with 50+ matches',
          criteria: {
            subscriptionTier: 'gold',
            minMatches: 50,
          },
        },
      };

      // @ts-ignore
      const result = await createUserSegment(request);

      expect(result.success).toBe(true);
      expect(result.segmentId).toBe('segment-123');
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'High Value Users',
          criteria: {
            subscriptionTier: 'gold',
            minMatches: 50,
          },
        })
      );
    });
  });

  describe('getUserSegments', () => {
    it('should fetch all user segments', async () => {
      const mockSnapshot = {
        docs: [
          {
            id: 'segment-1',
            data: () => ({
              name: 'Premium Users',
              criteria: { subscriptionTier: 'gold' },
            }),
          },
          {
            id: 'segment-2',
            data: () => ({
              name: 'Active Users',
              criteria: { minMatches: 10 },
            }),
          },
        ],
      };

      mockDb.collection.mockReturnValue({
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { limit: 50 },
      };

      // @ts-ignore
      const result = await getUserSegments(request);

      expect(result.success).toBe(true);
      expect(result.segments).toHaveLength(2);
      expect(result.segments[0].name).toBe('Premium Users');
    });
  });

  describe('getUsersInSegment', () => {
    it('should fetch users matching segment criteria', async () => {
      const mockSegmentDoc = {
        exists: true,
        data: () => ({
          criteria: {
            subscriptionTier: 'gold',
            minMatches: 20,
          },
        }),
      };

      const mockUsersSnapshot = {
        docs: [
          {
            id: 'user-1',
            data: () => ({
              displayName: 'Premium User',
              email: 'premium@example.com',
              subscriptionTier: 'gold',
            }),
          },
        ],
      };

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'user_segments') {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(mockSegmentDoc),
            }),
          };
        }
        if (collName === 'users') {
          return {
            where: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue(mockUsersSnapshot),
          };
        }
        return {};
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          segmentId: 'segment-123',
          limit: 100,
        },
      };

      // @ts-ignore
      const result = await getUsersInSegment(request);

      expect(result.success).toBe(true);
      expect(result.users).toHaveLength(1);
      expect(result.count).toBe(1);
    });

    it('should reject if segment not found', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({ exists: false }),
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { segmentId: 'nonexistent' },
      };

      // @ts-ignore
      await expect(getUsersInSegment(request)).rejects.toThrow('Segment not found');
    });
  });

  describe('updateSegmentCriteria', () => {
    it('should update segment criteria', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          segmentId: 'segment-123',
          criteria: {
            subscriptionTier: 'silver',
            minMatches: 30,
          },
        },
      };

      // @ts-ignore
      const result = await updateSegmentCriteria(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          criteria: {
            subscriptionTier: 'silver',
            minMatches: 30,
          },
        })
      );
    });
  });

  describe('deleteUserSegment', () => {
    it('should delete user segment', async () => {
      const mockDelete = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          delete: mockDelete,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { segmentId: 'segment-123' },
      };

      // @ts-ignore
      const result = await deleteUserSegment(request);

      expect(result.success).toBe(true);
      expect(mockDelete).toHaveBeenCalled();
    });
  });
});
