/**
 * Admin Service Unit Tests
 * Tests for 31 admin dashboard, user management, and moderation functions
 */

import { describe, it, expect, jest, beforeEach, afterEach } from '@jest/globals';
import * as admin from 'firebase-admin';

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  firestore: {
    FieldValue: {
      serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
      increment: jest.fn((n) => `INCREMENT_${n}`),
    },
    Timestamp: {
      fromDate: jest.fn((date) => ({
        toMillis: () => date.getTime(),
        toDate: () => date,
      })),
    },
  },
  auth: jest.fn(() => ({
    deleteUser: jest.fn().mockResolvedValue(undefined),
    createCustomToken: jest.fn().mockResolvedValue('custom-token-123'),
  })),
}));

// Mock shared utils
const mockDb = {
  collection: jest.fn(),
  batch: jest.fn(),
};

jest.mock('../../src/shared/utils', () => ({
  verifyAdminAuth: jest.fn(),
  handleError: jest.fn((error) => error),
  logInfo: jest.fn(),
  logError: jest.fn(),
  db: mockDb,
  FieldValue: {
    serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
    increment: jest.fn((n) => `INCREMENT_${n}`),
  },
}));

// Mock shared types
jest.mock('../../src/shared/types', () => ({
  SubscriptionTier: {
    BASIC: 'basic',
    SILVER: 'silver',
    GOLD: 'gold',
  },
  UserRole: {
    USER: 'user',
    ADMIN: 'admin',
    MODERATOR: 'moderator',
  },
  ReportStatus: {
    PENDING: 'pending',
    UNDER_REVIEW: 'under_review',
    RESOLVED: 'resolved',
  },
}));

// Import after mocks
import {
  getDashboardStats,
  getUserGrowth,
  getRevenueStats,
  getActiveUsers,
  getTopMatchmakers,
  getChurnRiskUsers,
  getConversionFunnel,
  exportDashboardData,
  getSystemHealth,
  assignRole,
  revokeRole,
  getAdminUsers,
  getRoleHistory,
  createAdminInvite,
  acceptAdminInvite,
  suspendUser,
  reactivateUser,
  deleteUserAccount,
  impersonateUser,
  searchUsers,
  getUserDetails,
  updateUserProfile,
  banUser,
  unbanUser,
  getBannedUsers,
  getModerationQueue,
  processReport,
  bulkProcessReports,
  getReportDetails,
  assignModerator,
  getModeratorStats,
} from '../../src/admin';

const { verifyAdminAuth } = require('../../src/shared/utils');
const { SubscriptionTier, UserRole, ReportStatus } = require('../../src/shared/types');

describe('Admin Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (verifyAdminAuth as jest.Mock).mockResolvedValue(undefined);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  // ========== DASHBOARD FUNCTIONS ==========

  describe('getDashboardStats', () => {
    it('should fetch dashboard stats for month period', async () => {
      const mockUsersSnapshot = { size: 50, docs: [] };
      const mockAllUsersSnapshot = { size: 1000 };
      const mockActiveUsersSnapshot = { size: 600 };
      const mockSubscriptionsSnapshot = {
        size: 150,
        docs: [
          { data: () => ({ tier: SubscriptionTier.SILVER }) },
          { data: () => ({ tier: SubscriptionTier.GOLD }) },
        ],
      };
      const mockMatchesSnapshot = { size: 500 };
      const mockMessagesSnapshot = { size: 5000 };
      const mockReportsSnapshot = {
        size: 10,
        docs: [
          { data: () => ({ status: ReportStatus.PENDING }) },
          { data: () => ({ status: ReportStatus.PENDING }) },
          { data: () => ({ status: ReportStatus.RESOLVED }) },
        ],
      };

      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        get: jest.fn()
          .mockResolvedValueOnce(mockUsersSnapshot)
          .mockResolvedValueOnce(mockActiveUsersSnapshot)
          .mockResolvedValueOnce(mockSubscriptionsSnapshot)
          .mockResolvedValueOnce(mockMatchesSnapshot)
          .mockResolvedValueOnce(mockMessagesSnapshot)
          .mockResolvedValueOnce(mockReportsSnapshot),
      };

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'users') {
          return {
            ...mockQuery,
            get: jest.fn().mockResolvedValue(mockAllUsersSnapshot),
          };
        }
        return mockQuery;
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { period: 'month' },
      };

      // @ts-ignore
      const result = await getDashboardStats(request);

      expect(result.success).toBe(true);
      expect(result.stats.users.total).toBe(1000);
      expect(result.stats.users.new).toBe(50);
      expect(result.stats.users.active).toBe(600);
      expect(result.stats.revenue.activeSubscriptions).toBe(150);
      expect(result.stats.engagement.totalMatches).toBe(500);
      expect(result.stats.moderation.totalReports).toBe(10);
    });

    it('should require admin authentication', async () => {
      (verifyAdminAuth as jest.Mock).mockRejectedValue(new Error('Not admin'));

      const request = {
        auth: { uid: 'user-123' },
        data: {},
      };

      // @ts-ignore
      await expect(getDashboardStats(request)).rejects.toThrow('Not admin');
    });
  });

  describe('getUserGrowth', () => {
    it('should fetch user growth data grouped by day', async () => {
      const mockSnapshot = {
        size: 10,
        docs: [
          { data: () => ({ createdAt: { toDate: () => new Date('2024-01-15') } }) },
          { data: () => ({ createdAt: { toDate: () => new Date('2024-01-15') } }) },
          { data: () => ({ createdAt: { toDate: () => new Date('2024-01-16') } }) },
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
          interval: 'day',
        },
      };

      // @ts-ignore
      const result = await getUserGrowth(request);

      expect(result.success).toBe(true);
      expect(result.totalNewUsers).toBe(10);
      expect(result.growthData['2024-01-15']).toBe(2);
      expect(result.growthData['2024-01-16']).toBe(1);
    });
  });

  describe('getRevenueStats', () => {
    it('should calculate total revenue from subscriptions and coins', async () => {
      const mockSubscriptions = {
        docs: [
          { data: () => ({ tier: SubscriptionTier.SILVER }) },
          { data: () => ({ tier: SubscriptionTier.SILVER }) },
          { data: () => ({ tier: SubscriptionTier.GOLD }) },
        ],
      };

      const mockCoinPurchases = {
        docs: [
          { data: () => ({ amount: 4.99 }) },
          { data: () => ({ amount: 9.99 }) },
        ],
      };

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'subscriptions') {
          return {
            where: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue(mockSubscriptions),
          };
        }
        if (collName === 'coin_purchases') {
          return {
            where: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue(mockCoinPurchases),
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
      const result = await getRevenueStats(request);

      expect(result.success).toBe(true);
      expect(parseFloat(result.revenue.subscriptions)).toBeCloseTo(39.97, 2); // 2*9.99 + 19.99
      expect(parseFloat(result.revenue.coins)).toBeCloseTo(14.98, 2);
      expect(parseFloat(result.revenue.total)).toBeCloseTo(54.95, 2);
    });
  });

  describe('getActiveUsers', () => {
    it('should fetch active users for week period', async () => {
      const mockActiveSnapshot = { size: 500 };
      const mockTotalCount = { data: () => ({ count: 1000 }) };

      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockActiveSnapshot),
        count: jest.fn().mockReturnThis(),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { period: 'week' },
      };

      // @ts-ignore
      const result = await getActiveUsers(request);

      expect(result.success).toBe(true);
      expect(result.activeUsers).toBe(500);
    });
  });

  describe('getTopMatchmakers', () => {
    it('should fetch top users by match count', async () => {
      const mockSnapshot = {
        docs: [
          {
            id: 'user-1',
            data: () => ({
              displayName: 'User One',
              stats: { totalMatches: 100, totalMessages: 500 },
            }),
          },
          {
            id: 'user-2',
            data: () => ({
              displayName: 'User Two',
              stats: { totalMatches: 80, totalMessages: 400 },
            }),
          },
        ],
      };

      mockDb.collection.mockReturnValue({
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { limit: 10 },
      };

      // @ts-ignore
      const result = await getTopMatchmakers(request);

      expect(result.success).toBe(true);
      expect(result.topMatchmakers).toHaveLength(2);
      expect(result.topMatchmakers[0].totalMatches).toBe(100);
    });
  });

  describe('getChurnRiskUsers', () => {
    it('should identify users at risk of churning', async () => {
      const mockSnapshot = {
        docs: [
          {
            id: 'user-1',
            data: () => ({
              displayName: 'Inactive User',
              lastActiveAt: { toDate: () => new Date(Date.now() - 20 * 24 * 60 * 60 * 1000) },
              subscriptionTier: SubscriptionTier.GOLD,
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
        data: { limit: 50 },
      };

      // @ts-ignore
      const result = await getChurnRiskUsers(request);

      expect(result.success).toBe(true);
      expect(result.churnRiskUsers).toHaveLength(1);
      expect(result.churnRiskUsers[0].subscriptionTier).toBe(SubscriptionTier.GOLD);
    });
  });

  describe('getConversionFunnel', () => {
    it('should calculate conversion funnel metrics', async () => {
      const mockSnapshot = {
        size: 100,
        docs: [
          { data: () => ({ profileCompleteness: 100, stats: { totalMatches: 5, totalMessages: 10 }, subscriptionTier: SubscriptionTier.SILVER }) },
          { data: () => ({ profileCompleteness: 50, stats: { totalMatches: 0, totalMessages: 0 }, subscriptionTier: SubscriptionTier.BASIC }) },
          { data: () => ({ profileCompleteness: 100, stats: { totalMatches: 3, totalMessages: 8 }, subscriptionTier: SubscriptionTier.BASIC }) },
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
      const result = await getConversionFunnel(request);

      expect(result.success).toBe(true);
      expect(result.funnel.signups).toBe(100);
      expect(result.funnel.profileCompleted).toBe(2);
      expect(result.funnel.firstMatch).toBe(2);
      expect(result.funnel.subscribed).toBe(1);
    });
  });

  describe('exportDashboardData', () => {
    it('should export dashboard data', async () => {
      const request = {
        auth: { uid: 'admin-123' },
        data: {
          type: 'users',
          format: 'csv',
        },
      };

      // @ts-ignore
      const result = await exportDashboardData(request);

      expect(result.success).toBe(true);
      expect(result.exportUrl).toContain('users_');
      expect(result.exportUrl).toContain('.csv');
      expect(result.expiresAt).toBeDefined();
    });
  });

  describe('getSystemHealth', () => {
    it('should fetch system health metrics', async () => {
      mockDb.collection.mockReturnValue({
        count: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          data: () => ({ count: 1000 }),
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {},
      };

      // @ts-ignore
      const result = await getSystemHealth(request);

      expect(result.success).toBe(true);
      expect(result.health.status).toBe('healthy');
      expect(result.health.metrics).toBeDefined();
    });
  });

  // ========== ROLE MANAGEMENT ==========

  describe('assignRole', () => {
    it('should assign role to user successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ role: UserRole.USER }),
      });
      const mockAdd = jest.fn().mockResolvedValue({ id: 'log-123' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'users') {
          return {
            doc: jest.fn().mockReturnValue({
              get: mockGet,
              update: mockUpdate,
            }),
          };
        }
        if (collName === 'audit_logs') {
          return { add: mockAdd };
        }
        return {};
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          userId: 'user-456',
          role: UserRole.MODERATOR,
        },
      };

      // @ts-ignore
      const result = await assignRole(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          role: UserRole.MODERATOR,
          previousRole: UserRole.USER,
        })
      );
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'role_change',
          userId: 'user-456',
        })
      );
    });

    it('should reject if user not found', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({ exists: false }),
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          userId: 'nonexistent',
          role: UserRole.ADMIN,
        },
      };

      // @ts-ignore
      await expect(assignRole(request)).rejects.toThrow('User not found');
    });
  });

  describe('revokeRole', () => {
    it('should revoke admin role from user', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ role: UserRole.MODERATOR }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { userId: 'user-456' },
      };

      // @ts-ignore
      const result = await revokeRole(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          role: UserRole.USER,
        })
      );
    });
  });

  describe('getAdminUsers', () => {
    it('should fetch all admin users', async () => {
      const mockSnapshot = {
        docs: [
          {
            id: 'admin-1',
            data: () => ({
              email: 'admin1@example.com',
              displayName: 'Admin One',
              role: UserRole.ADMIN,
              roleChangedAt: { toDate: () => new Date() },
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
        data: { limit: 50 },
      };

      // @ts-ignore
      const result = await getAdminUsers(request);

      expect(result.success).toBe(true);
      expect(result.admins).toHaveLength(1);
      expect(result.admins[0].role).toBe(UserRole.ADMIN);
    });
  });

  describe('getRoleHistory', () => {
    it('should fetch role change history for user', async () => {
      const mockSnapshot = {
        docs: [
          { data: () => ({ type: 'role_change', previousRole: UserRole.USER, newRole: UserRole.MODERATOR }) },
        ],
      };

      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { userId: 'user-456' },
      };

      // @ts-ignore
      const result = await getRoleHistory(request);

      expect(result.success).toBe(true);
      expect(result.history).toHaveLength(1);
    });
  });

  describe('createAdminInvite', () => {
    it('should create admin invite with code', async () => {
      const mockAdd = jest.fn().mockResolvedValue({ id: 'invite-123' });

      mockDb.collection.mockReturnValue({ add: mockAdd });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          email: 'newadmin@example.com',
          role: UserRole.MODERATOR,
          expiresInDays: 7,
        },
      };

      // @ts-ignore
      const result = await createAdminInvite(request);

      expect(result.success).toBe(true);
      expect(result.inviteCode).toBeDefined();
      expect(result.expiresAt).toBeDefined();
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          email: 'newadmin@example.com',
          role: UserRole.MODERATOR,
          used: false,
        })
      );
    });
  });

  describe('acceptAdminInvite', () => {
    it('should accept valid admin invite', async () => {
      const mockInviteDoc = {
        ref: {
          update: jest.fn().mockResolvedValue(undefined),
        },
        data: () => ({
          role: UserRole.MODERATOR,
          used: false,
          expiresAt: { toMillis: () => Date.now() + 24 * 60 * 60 * 1000 },
        }),
      };

      const mockSnapshot = {
        empty: false,
        docs: [mockInviteDoc],
      };

      const mockUserUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'admin_invites') {
          return {
            where: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue(mockSnapshot),
          };
        }
        if (collName === 'users') {
          return {
            doc: jest.fn().mockReturnValue({
              update: mockUserUpdate,
            }),
          };
        }
        return {};
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { inviteCode: 'valid-code-123' },
      };

      // @ts-ignore
      const result = await acceptAdminInvite(request);

      expect(result.success).toBe(true);
      expect(mockUserUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          role: UserRole.MODERATOR,
        })
      );
    });

    it('should reject invalid invite code', async () => {
      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ empty: true }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { inviteCode: 'invalid-code' },
      };

      // @ts-ignore
      await expect(acceptAdminInvite(request)).rejects.toThrow('Invalid invite code');
    });

    it('should reject already used invite', async () => {
      const mockInviteDoc = {
        data: () => ({
          used: true,
        }),
      };

      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          empty: false,
          docs: [mockInviteDoc],
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { inviteCode: 'used-code' },
      };

      // @ts-ignore
      await expect(acceptAdminInvite(request)).rejects.toThrow('already used');
    });
  });

  // ========== USER MANAGEMENT ==========

  describe('suspendUser', () => {
    it('should suspend user with notification', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'users') {
          return {
            doc: jest.fn().mockReturnValue({
              update: mockUpdate,
            }),
          };
        }
        if (collName === 'notifications') {
          return { add: mockNotifAdd };
        }
        return {};
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          userId: 'user-456',
          reason: 'Violation of terms',
          duration: 7,
          notify: true,
        },
      };

      // @ts-ignore
      const result = await suspendUser(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          accountStatus: 'suspended',
          suspensionReason: 'Violation of terms',
        })
      );
      expect(mockNotifAdd).toHaveBeenCalled();
    });
  });

  describe('reactivateUser', () => {
    it('should reactivate suspended user', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'users') {
          return {
            doc: jest.fn().mockReturnValue({
              update: mockUpdate,
            }),
          };
        }
        if (collName === 'notifications') {
          return { add: mockNotifAdd };
        }
        return {};
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          userId: 'user-456',
          notify: true,
        },
      };

      // @ts-ignore
      const result = await reactivateUser(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          accountStatus: 'active',
        })
      );
    });
  });

  describe('deleteUserAccount', () => {
    it('should perform soft delete by default', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          userId: 'user-456',
          reason: 'User request',
          hardDelete: false,
        },
      };

      // @ts-ignore
      const result = await deleteUserAccount(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          accountStatus: 'deleted',
          deletionReason: 'User request',
        })
      );
    });

    it('should perform hard delete when specified', async () => {
      const mockAuthDelete = jest.fn().mockResolvedValue(undefined);
      const mockDocDelete = jest.fn().mockResolvedValue(undefined);

      (admin.auth as jest.Mock).mockReturnValue({
        deleteUser: mockAuthDelete,
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          delete: mockDocDelete,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          userId: 'user-456',
          reason: 'GDPR request',
          hardDelete: true,
        },
      };

      // @ts-ignore
      const result = await deleteUserAccount(request);

      expect(result.success).toBe(true);
      expect(mockAuthDelete).toHaveBeenCalledWith('user-456');
      expect(mockDocDelete).toHaveBeenCalled();
    });
  });

  describe('impersonateUser', () => {
    it('should create custom token for impersonation', async () => {
      const mockAdd = jest.fn().mockResolvedValue({ id: 'log-123' });

      mockDb.collection.mockReturnValue({ add: mockAdd });

      const mockCreateToken = jest.fn().mockResolvedValue('custom-token-abc');
      (admin.auth as jest.Mock).mockReturnValue({
        createCustomToken: mockCreateToken,
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          userId: 'user-456',
          reason: 'Support investigation',
        },
      };

      // @ts-ignore
      const result = await impersonateUser(request);

      expect(result.success).toBe(true);
      expect(result.token).toBe('custom-token-abc');
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'impersonation',
          adminId: 'admin-123',
          targetUserId: 'user-456',
        })
      );
    });
  });

  describe('searchUsers', () => {
    it('should search users with filters', async () => {
      const mockSnapshot = {
        size: 2,
        docs: [
          {
            id: 'user-1',
            data: () => ({
              displayName: 'John Doe',
              email: 'john@example.com',
              subscriptionTier: SubscriptionTier.SILVER,
            }),
          },
          {
            id: 'user-2',
            data: () => ({
              displayName: 'Jane Smith',
              email: 'jane@example.com',
              subscriptionTier: SubscriptionTier.SILVER,
            }),
          },
        ],
      };

      mockDb.collection.mockReturnValue({
        limit: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          query: 'john',
          filters: { tier: SubscriptionTier.SILVER },
          limit: 50,
        },
      };

      // @ts-ignore
      const result = await searchUsers(request);

      expect(result.success).toBe(true);
      expect(result.users.length).toBeGreaterThan(0);
    });
  });

  describe('getUserDetails', () => {
    it('should fetch detailed user information', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            id: 'user-123',
            data: () => ({
              displayName: 'Test User',
              email: 'test@example.com',
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { userId: 'user-123' },
      };

      // @ts-ignore
      const result = await getUserDetails(request);

      expect(result.success).toBe(true);
      expect(result.user.userId).toBe('user-123');
      expect(result.user.displayName).toBe('Test User');
    });
  });

  describe('updateUserProfile', () => {
    it('should update user profile fields', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          userId: 'user-456',
          updates: {
            displayName: 'New Name',
            bio: 'Updated bio',
          },
        },
      };

      // @ts-ignore
      const result = await updateUserProfile(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          displayName: 'New Name',
          bio: 'Updated bio',
        })
      );
    });
  });

  describe('banUser', () => {
    it('should ban user permanently', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          userId: 'user-456',
          reason: 'Harassment',
          permanent: true,
        },
      };

      // @ts-ignore
      const result = await banUser(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          banned: true,
          banReason: 'Harassment',
          permanentBan: true,
        })
      );
    });

    it('should ban user temporarily', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          userId: 'user-456',
          reason: 'Spam',
          permanent: false,
          banDuration: 30,
        },
      };

      // @ts-ignore
      const result = await banUser(request);

      expect(result.success).toBe(true);
    });
  });

  describe('unbanUser', () => {
    it('should unban user successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { userId: 'user-456' },
      };

      // @ts-ignore
      const result = await unbanUser(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          banned: false,
        })
      );
    });
  });

  describe('getBannedUsers', () => {
    it('should fetch list of banned users', async () => {
      const mockSnapshot = {
        size: 2,
        docs: [
          {
            id: 'user-1',
            data: () => ({
              displayName: 'Banned User 1',
              email: 'banned1@example.com',
              bannedAt: { toDate: () => new Date() },
              banReason: 'Spam',
              permanentBan: true,
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
        data: { limit: 50 },
      };

      // @ts-ignore
      const result = await getBannedUsers(request);

      expect(result.success).toBe(true);
      expect(result.bannedUsers).toHaveLength(1);
    });
  });

  // ========== MODERATION QUEUE ==========

  describe('getModerationQueue', () => {
    it('should fetch pending reports', async () => {
      const mockSnapshot = {
        size: 5,
        docs: [
          {
            id: 'report-1',
            data: () => ({
              reporterId: 'user-1',
              reportedUserId: 'user-2',
              reason: 'Inappropriate content',
              status: ReportStatus.PENDING,
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
        data: {
          status: ReportStatus.PENDING,
          limit: 50,
        },
      };

      // @ts-ignore
      const result = await getModerationQueue(request);

      expect(result.success).toBe(true);
      expect(result.reports).toHaveLength(1);
      expect(result.totalCount).toBe(5);
    });
  });

  describe('processReport', () => {
    it('should process report with warn action', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ reportedUserId: 'user-456' }),
      });
      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'reports') {
          return {
            doc: jest.fn().mockReturnValue({
              get: mockGet,
              update: mockUpdate,
            }),
          };
        }
        if (collName === 'notifications') {
          return { add: mockNotifAdd };
        }
        if (collName === 'users') {
          return {
            doc: jest.fn().mockReturnValue({
              update: jest.fn().mockResolvedValue(undefined),
            }),
          };
        }
        return {};
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          reportId: 'report-123',
          action: 'warn',
          notes: 'First warning',
        },
      };

      // @ts-ignore
      const result = await processReport(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: ReportStatus.RESOLVED,
          action: 'warn',
        })
      );
      expect(mockNotifAdd).toHaveBeenCalled();
    });

    it('should process report with ban action', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ reportedUserId: 'user-456' }),
      });
      const mockUserUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'reports') {
          return {
            doc: jest.fn().mockReturnValue({
              get: mockGet,
              update: mockUpdate,
            }),
          };
        }
        if (collName === 'users') {
          return {
            doc: jest.fn().mockReturnValue({
              update: mockUserUpdate,
            }),
          };
        }
        return {};
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          reportId: 'report-123',
          action: 'ban',
        },
      };

      // @ts-ignore
      const result = await processReport(request);

      expect(result.success).toBe(true);
      expect(mockUserUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          banned: true,
        })
      );
    });
  });

  describe('bulkProcessReports', () => {
    it('should process multiple reports in batch', async () => {
      const mockBatch = {
        update: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      mockDb.batch.mockReturnValue(mockBatch);
      mockDb.collection.mockReturnValue({
        doc: jest.fn(),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          reportIds: ['report-1', 'report-2', 'report-3'],
          action: 'dismiss',
          notes: 'Bulk dismissed',
        },
      };

      // @ts-ignore
      const result = await bulkProcessReports(request);

      expect(result.success).toBe(true);
      expect(result.processedCount).toBe(3);
      expect(mockBatch.update).toHaveBeenCalledTimes(3);
      expect(mockBatch.commit).toHaveBeenCalled();
    });
  });

  describe('getReportDetails', () => {
    it('should fetch detailed report information', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            id: 'report-123',
            data: () => ({
              reporterId: 'user-1',
              reportedUserId: 'user-2',
              reason: 'Harassment',
              status: ReportStatus.PENDING,
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: { reportId: 'report-123' },
      };

      // @ts-ignore
      const result = await getReportDetails(request);

      expect(result.success).toBe(true);
      expect(result.report.reportId).toBe('report-123');
    });
  });

  describe('assignModerator', () => {
    it('should assign moderator to report', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          reportId: 'report-123',
          moderatorId: 'mod-456',
        },
      };

      // @ts-ignore
      const result = await assignModerator(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          assignedTo: 'mod-456',
          status: ReportStatus.UNDER_REVIEW,
        })
      );
    });
  });

  describe('getModeratorStats', () => {
    it('should fetch moderator statistics', async () => {
      const mockSnapshot = {
        size: 50,
        docs: [
          { data: () => ({ action: 'dismissed' }) },
          { data: () => ({ action: 'dismissed' }) },
          { data: () => ({ action: 'warned' }) },
          { data: () => ({ action: 'suspended' }) },
          { data: () => ({ action: 'banned' }) },
        ],
      };

      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      });

      const request = {
        auth: { uid: 'admin-123' },
        data: {
          moderatorId: 'mod-456',
          period: 'month',
        },
      };

      // @ts-ignore
      const result = await getModeratorStats(request);

      expect(result.success).toBe(true);
      expect(result.stats.totalResolved).toBe(50);
      expect(result.stats.actionBreakdown.dismissed).toBe(2);
    });
  });
});
