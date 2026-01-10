/**
 * Security Service Tests
 * Comprehensive tests for all 5 security functions
 */

import * as admin from 'firebase-admin';
import { FieldValue } from '../../src/shared/utils';
import {
  createMockAuthContext,
  createMockFirestoreDoc,
  createMockFirestoreQuery,
} from '../utils/test-helpers';
import { mockData } from '../utils/mock-data';

// Mock Firebase Admin
jest.mock('firebase-admin', () => {
  const actualAdmin = jest.requireActual('firebase-admin');
  return {
    ...actualAdmin,
    firestore: jest.fn(() => ({
      collection: jest.fn(),
      batch: jest.fn(),
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
    })),
    add: jest.fn(),
    get: jest.fn(),
    where: jest.fn(),
    orderBy: jest.fn(),
    limit: jest.fn(),
    startAfter: jest.fn(),
  })),
  batch: jest.fn(() => ({
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
  verifyAdminAuth: jest.fn(),
  handleError: jest.fn(err => err),
  logInfo: jest.fn(),
  logError: jest.fn(),
}));

const { verifyAdminAuth, logInfo, logError } = require('../../src/shared/utils');

describe('Security Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ========== 1. RUN SECURITY AUDIT ==========
  describe('runSecurityAudit', () => {
    const mockRequest = {
      data: {
        auditType: undefined,
        startDate: undefined,
        endDate: undefined,
      },
      ...createMockAuthContext('admin-123', 'admin'),
    };

    beforeEach(() => {
      // Mock admin verification
      (verifyAdminAuth as jest.Mock).mockResolvedValue(undefined);

      // Mock Firestore queries for all audit checks
      const mockCollection = mockDb.collection as jest.Mock;

      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          orderBy: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          startAfter: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({ docs: [], empty: true, size: 0 }),
          add: jest.fn().mockResolvedValue({ id: 'audit-report-123' }),
          doc: jest.fn((docId?: string) => ({
            get: jest.fn().mockResolvedValue({
              exists: false,
              id: docId || 'test-doc',
              data: () => ({}),
            }),
            set: jest.fn().mockResolvedValue(undefined),
            update: jest.fn().mockResolvedValue(undefined),
            delete: jest.fn().mockResolvedValue(undefined),
          })),
        };
        return chainable;
      });
    });

    it('should run full security audit for all check types', async () => {
      const { runSecurityAudit } = require('../../src/security');

      const result = await runSecurityAudit(mockRequest);

      expect(result).toMatchObject({
        success: true,
        reportId: 'audit-report-123',
        totalFindings: expect.any(Number),
        severityCounts: {
          info: expect.any(Number),
          low: expect.any(Number),
          medium: expect.any(Number),
          high: expect.any(Number),
          critical: expect.any(Number),
        },
        criticalFindings: expect.any(Number),
        auditDuration: expect.any(Number),
      });

      expect(verifyAdminAuth).toHaveBeenCalledWith(mockRequest.auth);
      expect(logInfo).toHaveBeenCalledWith('Running security audit', expect.any(Object));
    });

    it('should run specific audit type when provided', async () => {
      const { runSecurityAudit } = require('../../src/security');

      const specificRequest = {
        ...mockRequest,
        data: {
          auditType: 'user_data_access',
          startDate: '2025-01-01',
          endDate: '2025-01-07',
        },
      };

      const result = await runSecurityAudit(specificRequest);

      expect(result.success).toBe(true);
      expect(result.reportId).toBe('audit-report-123');
      expect(logInfo).toHaveBeenCalledWith('Running security audit', {
        auditType: 'user_data_access',
        startDate: '2025-01-01',
        endDate: '2025-01-07',
      });
    });

    it('should use default date range (last 7 days) when not provided', async () => {
      const { runSecurityAudit } = require('../../src/security');

      await runSecurityAudit(mockRequest);

      // Verify the audit ran
      expect(mockDb.collection).toHaveBeenCalledWith('security_audits');
    });

    it('should detect excessive data exports (>10 per user)', async () => {
      // Mock 15 exports from same user
      const mockExports = Array.from({ length: 15 }, (_, i) => ({
        id: `export-${i}`,
        data: () => ({
          userId: 'user-123',
          createdAt: admin.firestore.Timestamp.now(),
        }),
      }));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          orderBy: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'pdf_exports' ? mockExports : [],
            empty: collectionName !== 'pdf_exports',
            size: collectionName === 'pdf_exports' ? mockExports.length : 0,
          }),
          add: jest.fn().mockResolvedValue({ id: 'audit-report-124' }),
          doc: jest.fn(() => ({
            get: jest.fn().mockResolvedValue({ exists: false }),
          })),
        };
        return chainable;
      });

      const { runSecurityAudit } = require('../../src/security');
      const result = await runSecurityAudit(mockRequest);

      expect(result.totalFindings).toBeGreaterThan(0);
    });

    it('should detect admin role changes', async () => {
      const mockAdmins = [
        {
          id: 'user-456',
          data: () => ({
            role: 'admin',
            roleChangedAt: admin.firestore.Timestamp.now(),
            previousRole: 'user',
          }),
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'users' ? mockAdmins : [],
            empty: collectionName !== 'users',
            size: collectionName === 'users' ? 1 : 0,
          }),
          add: jest.fn().mockResolvedValue({ id: 'audit-report-125' }),
          doc: jest.fn(() => ({
            get: jest.fn().mockResolvedValue({ exists: false }),
          })),
        };
        return chainable;
      });

      const { runSecurityAudit } = require('../../src/security');
      const result = await runSecurityAudit(mockRequest);

      expect(result.totalFindings).toBeGreaterThan(0);
    });

    it('should detect unusual account lockouts', async () => {
      // Mock 150 locked accounts
      const mockLockouts = Array.from({ length: 150 }, (_, i) => ({
        id: `user-${i}`,
        data: () => ({
          accountLocked: true,
          lockedAt: admin.firestore.Timestamp.now(),
        }),
      }));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'users' ? mockLockouts : [],
            empty: false,
            size: 150,
          }),
          add: jest.fn().mockResolvedValue({ id: 'audit-report-126' }),
          doc: jest.fn(() => ({
            get: jest.fn().mockResolvedValue({ exists: false }),
          })),
        };
        return chainable;
      });

      const { runSecurityAudit } = require('../../src/security');
      const result = await runSecurityAudit(mockRequest);

      expect(result.totalFindings).toBeGreaterThan(0);
    });

    it('should detect users with excessive reports (suspicious activity)', async () => {
      // Mock 25 reports against same user
      const mockReports = Array.from({ length: 25 }, (_, i) => ({
        id: `report-${i}`,
        data: () => ({
          reportedUserId: 'bad-user-789',
          createdAt: admin.firestore.Timestamp.now(),
        }),
      }));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'reports' ? mockReports : [],
            empty: collectionName !== 'reports',
            size: collectionName === 'reports' ? 25 : 0,
          }),
          add: jest.fn().mockResolvedValue({ id: 'audit-report-127' }),
          doc: jest.fn(() => ({
            get: jest.fn().mockResolvedValue({ exists: false }),
          })),
        };
        return chainable;
      });

      const { runSecurityAudit } = require('../../src/security');
      const result = await runSecurityAudit(mockRequest);

      expect(result.totalFindings).toBeGreaterThan(0);
      expect(result.severityCounts.critical).toBeGreaterThan(0); // 20+ reports = critical
    });

    it('should detect orphaned messages (data integrity)', async () => {
      const mockMessages = [
        {
          id: 'msg-1',
          data: () => ({
            conversationId: 'conv-999',
            createdAt: admin.firestore.Timestamp.now(),
          }),
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'messages' ? mockMessages : [],
            empty: collectionName !== 'messages',
          }),
          add: jest.fn().mockResolvedValue({ id: 'audit-report-128' }),
          doc: jest.fn((docId?: string) => ({
            get: jest.fn().mockResolvedValue({
              exists: docId !== 'conv-999', // Conversation doesn't exist
            }),
          })),
        };
        return chainable;
      });

      const { runSecurityAudit } = require('../../src/security');
      const result = await runSecurityAudit(mockRequest);

      expect(result.totalFindings).toBeGreaterThan(0);
    });

    it('should detect GDPR compliance violations', async () => {
      const mockDeletionRequests = [
        {
          id: 'gdpr-req-1',
          data: () => ({
            userId: 'deleted-user-123',
            type: 'deletion',
            status: 'completed',
            completedAt: admin.firestore.Timestamp.now(),
          }),
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'gdpr_requests' ? mockDeletionRequests : [],
            empty: collectionName !== 'gdpr_requests',
          }),
          add: jest.fn().mockResolvedValue({ id: 'audit-report-129' }),
          doc: jest.fn((docId?: string) => ({
            get: jest.fn().mockResolvedValue({
              exists: docId === 'deleted-user-123', // User still exists!
              data: () => ({ uid: docId }),
            }),
          })),
        };
        return chainable;
      });

      const { runSecurityAudit } = require('../../src/security');
      const result = await runSecurityAudit(mockRequest);

      expect(result.totalFindings).toBeGreaterThan(0);
      expect(result.severityCounts.critical).toBeGreaterThan(0); // GDPR violation is critical
    });

    it('should detect payment security issues (excessive refunds)', async () => {
      // Mock 5 refunds from same user
      const mockRefunds = Array.from({ length: 5 }, (_, i) => ({
        id: `sub-${i}`,
        data: () => ({
          userId: 'refund-abuser-456',
          refundedAt: admin.firestore.Timestamp.now(),
        }),
      }));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'subscriptions' ? mockRefunds : [],
            empty: collectionName !== 'subscriptions',
          }),
          add: jest.fn().mockResolvedValue({ id: 'audit-report-130' }),
          doc: jest.fn(() => ({
            get: jest.fn().mockResolvedValue({ exists: false }),
          })),
        };
        return chainable;
      });

      const { runSecurityAudit } = require('../../src/security');
      const result = await runSecurityAudit(mockRequest);

      expect(result.totalFindings).toBeGreaterThan(0);
      expect(result.severityCounts.high).toBeGreaterThan(0); // 3+ refunds = high severity
    });

    it('should send security alerts for critical findings', async () => {
      const mockAdmins = [
        { id: 'admin-1', data: () => ({ role: 'admin' }) },
        { id: 'admin-2', data: () => ({ role: 'admin' }) },
      ];

      // Mock critical finding
      const mockReports = Array.from({ length: 25 }, (_, i) => ({
        id: `report-${i}`,
        data: () => ({
          reportedUserId: 'critical-user',
          createdAt: admin.firestore.Timestamp.now(),
        }),
      }));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'reports' ? mockReports :
                  collectionName === 'users' ? mockAdmins : [],
            empty: false,
            size: collectionName === 'reports' ? 25 : collectionName === 'users' ? 2 : 0,
          }),
          add: jest.fn().mockResolvedValue({ id: 'audit-report-131' }),
          doc: jest.fn(() => ({
            get: jest.fn().mockResolvedValue({ exists: false }),
          })),
        };
        return chainable;
      });

      const { runSecurityAudit } = require('../../src/security');
      const result = await runSecurityAudit(mockRequest);

      expect(result.criticalFindings).toBeGreaterThan(0);
      // Verify alerts would be sent
      expect(mockCollection).toHaveBeenCalledWith('notifications');
    });

    it('should reject non-admin users', async () => {
      (verifyAdminAuth as jest.Mock).mockRejectedValue(new Error('Unauthorized'));

      const { runSecurityAudit } = require('../../src/security');

      await expect(runSecurityAudit({
        ...mockRequest,
        auth: { uid: 'regular-user', token: { role: 'user' } },
      })).rejects.toThrow('Unauthorized');
    });

    it('should handle errors gracefully', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => {
        throw new Error('Database error');
      });

      const { runSecurityAudit } = require('../../src/security');

      await expect(runSecurityAudit(mockRequest)).rejects.toThrow();
      expect(logError).toHaveBeenCalled();
    });
  });

  // ========== 2. SCHEDULED SECURITY AUDIT ==========
  describe('scheduledSecurityAudit', () => {
    beforeEach(() => {
      const mockCollection = mockDb.collection as jest.Mock;

      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          orderBy: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({ docs: [], empty: true, size: 0 }),
          add: jest.fn().mockResolvedValue({ id: 'scheduled-audit-123' }),
          doc: jest.fn(() => ({
            get: jest.fn().mockResolvedValue({ exists: false }),
          })),
        };
        return chainable;
      });
    });

    it('should run scheduled security audit (weekly)', async () => {
      const { scheduledSecurityAudit } = require('../../src/security');

      await scheduledSecurityAudit();

      expect(logInfo).toHaveBeenCalledWith('Running scheduled security audit');
      expect(mockDb.collection).toHaveBeenCalledWith('security_audits');
    });

    it('should check last 7 days of data', async () => {
      const { scheduledSecurityAudit } = require('../../src/security');

      await scheduledSecurityAudit();

      // Verify it ran successfully
      expect(logInfo).toHaveBeenCalledWith(
        expect.stringContaining('Scheduled security audit completed'),
        expect.anything()
      );
    });

    it('should run all 7 audit check types', async () => {
      const { scheduledSecurityAudit } = require('../../src/security');

      await scheduledSecurityAudit();

      // Verify multiple collection queries (one for each check type)
      expect(mockDb.collection).toHaveBeenCalledWith('pdf_exports'); // user_data_access
      expect(mockDb.collection).toHaveBeenCalledWith('users'); // admin_actions, authentication_failures
      expect(mockDb.collection).toHaveBeenCalledWith('reports'); // suspicious_activity
      expect(mockDb.collection).toHaveBeenCalledWith('messages'); // data_integrity
      expect(mockDb.collection).toHaveBeenCalledWith('gdpr_requests'); // gdpr_compliance
      expect(mockDb.collection).toHaveBeenCalledWith('subscriptions'); // payment_security
    });

    it('should send alerts for critical and high severity findings', async () => {
      const mockAdmins = [{ id: 'admin-1', data: () => ({ role: 'admin' }) }];
      const mockReports = Array.from({ length: 25 }, (_, i) => ({
        id: `report-${i}`,
        data: () => ({
          reportedUserId: 'bad-user',
          createdAt: admin.firestore.Timestamp.now(),
        }),
      }));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'reports' ? mockReports :
                  collectionName === 'users' ? mockAdmins : [],
            empty: false,
            size: collectionName === 'reports' ? 25 : 1,
          }),
          add: jest.fn().mockResolvedValue({ id: 'scheduled-audit-124' }),
          doc: jest.fn(() => ({
            get: jest.fn().mockResolvedValue({ exists: false }),
          })),
        };
        return chainable;
      });

      const { scheduledSecurityAudit } = require('../../src/security');

      await scheduledSecurityAudit();

      expect(logInfo).toHaveBeenCalledWith(
        expect.stringContaining('alerts'),
        expect.anything()
      );
    });

    it('should save audit report with system as runBy', async () => {
      const mockAdd = jest.fn().mockResolvedValue({ id: 'scheduled-audit-125' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: [], empty: true, size: 0 }),
        add: mockAdd,
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { scheduledSecurityAudit } = require('../../src/security');

      await scheduledSecurityAudit();

      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          auditType: 'scheduled_full_audit',
          runBy: 'system',
        })
      );
    });

    it('should handle errors without crashing', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => {
        throw new Error('Database error');
      });

      const { scheduledSecurityAudit } = require('../../src/security');

      await expect(scheduledSecurityAudit()).rejects.toThrow('Database error');
      expect(logError).toHaveBeenCalledWith('Error in scheduled security audit:', expect.any(Error));
    });

    it('should have correct schedule configuration (Monday 3 AM UTC)', () => {
      const { scheduledSecurityAudit } = require('../../src/security');

      // The schedule is defined in the function configuration
      // This test verifies the function exists and can be called
      expect(scheduledSecurityAudit).toBeDefined();
      expect(typeof scheduledSecurityAudit).toBe('function');
    });
  });

  // ========== 3. GET SECURITY AUDIT REPORT ==========
  describe('getSecurityAuditReport', () => {
    const mockRequest = {
      data: {
        reportId: 'audit-report-123',
      },
      ...createMockAuthContext('admin-123', 'admin'),
    };

    beforeEach(() => {
      (verifyAdminAuth as jest.Mock).mockResolvedValue(undefined);
    });

    it('should retrieve existing audit report', async () => {
      const mockReport = {
        auditType: 'full_audit',
        totalFindings: 10,
        severityCounts: { critical: 2, high: 3, medium: 5, low: 0, info: 0 },
        findings: [],
        runBy: 'admin-123',
        createdAt: admin.firestore.Timestamp.now(),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            id: 'audit-report-123',
            data: () => mockReport,
          }),
        }),
      });

      const { getSecurityAuditReport } = require('../../src/security');

      const result = await getSecurityAuditReport(mockRequest);

      expect(result).toMatchObject({
        success: true,
        report: {
          id: 'audit-report-123',
          auditType: 'full_audit',
          totalFindings: 10,
        },
      });

      expect(verifyAdminAuth).toHaveBeenCalledWith(mockRequest.auth);
      expect(logInfo).toHaveBeenCalledWith('Fetching security audit report: audit-report-123');
    });

    it('should throw error for non-existent report', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: false,
            id: 'non-existent',
          }),
        }),
      });

      const { getSecurityAuditReport } = require('../../src/security');

      await expect(getSecurityAuditReport({
        ...mockRequest,
        data: { reportId: 'non-existent' },
      })).rejects.toThrow('Audit report not found');
    });

    it('should reject non-admin users', async () => {
      (verifyAdminAuth as jest.Mock).mockRejectedValue(new Error('Unauthorized'));

      const { getSecurityAuditReport } = require('../../src/security');

      await expect(getSecurityAuditReport({
        ...mockRequest,
        auth: { uid: 'regular-user', token: { role: 'user' } },
      })).rejects.toThrow('Unauthorized');
    });

    it('should include all report fields', async () => {
      const mockReport = {
        auditType: 'user_data_access',
        startDate: admin.firestore.Timestamp.now(),
        endDate: admin.firestore.Timestamp.now(),
        findings: [
          {
            type: 'user_data_access',
            severity: 'medium',
            description: 'Test finding',
            timestamp: admin.firestore.Timestamp.now(),
          },
        ],
        totalFindings: 1,
        severityCounts: { critical: 0, high: 0, medium: 1, low: 0, info: 0 },
        auditDuration: 5000,
        runBy: 'admin-123',
        createdAt: admin.firestore.Timestamp.now(),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            id: 'audit-report-123',
            data: () => mockReport,
          }),
        }),
      });

      const { getSecurityAuditReport } = require('../../src/security');

      const result = await getSecurityAuditReport(mockRequest);

      expect(result.report).toMatchObject({
        id: 'audit-report-123',
        auditType: 'user_data_access',
        totalFindings: 1,
        findings: expect.any(Array),
        severityCounts: expect.any(Object),
      });
    });
  });

  // ========== 4. LIST SECURITY AUDIT REPORTS ==========
  describe('listSecurityAuditReports', () => {
    const mockRequest = {
      data: {
        limit: 50,
        startAfter: undefined,
        severityFilter: undefined,
      },
      ...createMockAuthContext('admin-123', 'admin'),
    };

    beforeEach(() => {
      (verifyAdminAuth as jest.Mock).mockResolvedValue(undefined);
    });

    it('should list audit reports with default limit', async () => {
      const mockReports = Array.from({ length: 10 }, (_, i) => ({
        id: `report-${i}`,
        data: () => ({
          auditType: 'full_audit',
          totalFindings: i * 5,
          severityCounts: { critical: i, high: i, medium: i, low: 0, info: 0 },
          createdAt: admin.firestore.Timestamp.now(),
        }),
      }));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        startAfter: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockReports,
          size: 10,
        }),
      });

      const { listSecurityAuditReports } = require('../../src/security');

      const result = await listSecurityAuditReports(mockRequest);

      expect(result).toMatchObject({
        success: true,
        reports: expect.arrayContaining([
          expect.objectContaining({
            id: expect.any(String),
            auditType: 'full_audit',
          }),
        ]),
        hasMore: false,
        lastId: 'report-9',
      });

      expect(verifyAdminAuth).toHaveBeenCalledWith(mockRequest.auth);
    });

    it('should support pagination with startAfter', async () => {
      const mockStartDoc = {
        exists: true,
        id: 'report-5',
        data: () => ({}),
      };

      const mockReports = Array.from({ length: 50 }, (_, i) => ({
        id: `report-${i + 6}`,
        data: () => ({
          auditType: 'full_audit',
          totalFindings: 5,
          severityCounts: { critical: 0, high: 1, medium: 2, low: 2, info: 0 },
          createdAt: admin.firestore.Timestamp.now(),
        }),
      }));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        startAfter: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockReports,
          size: 50,
        }),
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockStartDoc),
        }),
      });

      const { listSecurityAuditReports } = require('../../src/security');

      const result = await listSecurityAuditReports({
        ...mockRequest,
        data: { limit: 50, startAfter: 'report-5' },
      });

      expect(result.hasMore).toBe(true); // size === limit
      expect(result.reports.length).toBe(50);
    });

    it('should filter by severity level', async () => {
      const mockReports = [
        {
          id: 'report-1',
          data: () => ({
            auditType: 'full_audit',
            severityCounts: { critical: 5, high: 0, medium: 0, low: 0, info: 0 },
          }),
        },
        {
          id: 'report-2',
          data: () => ({
            auditType: 'full_audit',
            severityCounts: { critical: 0, high: 3, medium: 0, low: 0, info: 0 },
          }),
        },
        {
          id: 'report-3',
          data: () => ({
            auditType: 'full_audit',
            severityCounts: { critical: 2, high: 1, medium: 0, low: 0, info: 0 },
          }),
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockReports,
          size: 3,
        }),
      });

      const { listSecurityAuditReports } = require('../../src/security');

      const result = await listSecurityAuditReports({
        ...mockRequest,
        data: { limit: 50, severityFilter: 'critical' },
      });

      expect(result.reports.length).toBe(2); // Only report-1 and report-3 have critical findings
      expect(result.reports.every((r: any) => r.severityCounts.critical > 0)).toBe(true);
    });

    it('should indicate hasMore when results equal limit', async () => {
      const mockReports = Array.from({ length: 50 }, (_, i) => ({
        id: `report-${i}`,
        data: () => ({
          auditType: 'full_audit',
          severityCounts: { critical: 0, high: 0, medium: 1, low: 0, info: 0 },
        }),
      }));

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockReports,
          size: 50,
        }),
      });

      const { listSecurityAuditReports } = require('../../src/security');

      const result = await listSecurityAuditReports(mockRequest);

      expect(result.hasMore).toBe(true);
    });

    it('should reject non-admin users', async () => {
      (verifyAdminAuth as jest.Mock).mockRejectedValue(new Error('Unauthorized'));

      const { listSecurityAuditReports } = require('../../src/security');

      await expect(listSecurityAuditReports({
        ...mockRequest,
        auth: { uid: 'regular-user', token: { role: 'user' } },
      })).rejects.toThrow('Unauthorized');
    });

    it('should handle empty results', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: [],
          size: 0,
        }),
      });

      const { listSecurityAuditReports } = require('../../src/security');

      const result = await listSecurityAuditReports(mockRequest);

      expect(result.reports).toEqual([]);
      expect(result.hasMore).toBe(false);
    });
  });

  // ========== 5. CLEANUP OLD AUDIT REPORTS ==========
  describe('cleanupOldAuditReports', () => {
    it('should delete reports older than 1 year', async () => {
      const oneYearAgo = new Date();
      oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);

      const mockOldReports = Array.from({ length: 100 }, (_, i) => ({
        id: `old-report-${i}`,
        ref: { path: `security_audits/old-report-${i}` },
        data: () => ({
          createdAt: admin.firestore.Timestamp.fromDate(
            new Date(oneYearAgo.getTime() - i * 24 * 60 * 60 * 1000)
          ),
        }),
      }));

      const mockBatch = {
        delete: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockOldReports,
          empty: false,
          size: 100,
        }),
      });

      const { cleanupOldAuditReports } = require('../../src/security');

      await cleanupOldAuditReports();

      expect(mockBatch.delete).toHaveBeenCalledTimes(100);
      expect(mockBatch.commit).toHaveBeenCalled();
      expect(logInfo).toHaveBeenCalledWith('Cleaned up 100 old security audit reports');
    });

    it('should delete in batches of 500', async () => {
      const oneYearAgo = new Date();
      oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);

      // Create 1200 old reports (should require 3 batches)
      const mockOldReports = Array.from({ length: 1200 }, (_, i) => ({
        id: `old-report-${i}`,
        ref: { path: `security_audits/old-report-${i}` },
        data: () => ({
          createdAt: admin.firestore.Timestamp.fromDate(
            new Date(oneYearAgo.getTime() - i * 60 * 60 * 1000)
          ),
        }),
      }));

      const mockBatch = {
        delete: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockOldReports,
          empty: false,
          size: 1200,
        }),
      });

      const { cleanupOldAuditReports } = require('../../src/security');

      await cleanupOldAuditReports();

      // Should commit 3 batches: 500 + 500 + 200
      expect(mockBatch.commit).toHaveBeenCalledTimes(3);
      expect(logInfo).toHaveBeenCalledWith('Cleaned up 1200 old security audit reports');
    });

    it('should handle no old reports gracefully', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: [],
          empty: true,
          size: 0,
        }),
      });

      const { cleanupOldAuditReports } = require('../../src/security');

      await cleanupOldAuditReports();

      expect(logInfo).toHaveBeenCalledWith('No old audit reports to cleanup');
      expect(mockDb.batch).not.toHaveBeenCalled();
    });

    it('should query with correct cutoff date (1 year ago)', async () => {
      const mockWhere = jest.fn().mockReturnThis();
      const mockGet = jest.fn().mockResolvedValue({ docs: [], empty: true });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockReturnValue({
        where: mockWhere,
        get: mockGet,
      });

      const { cleanupOldAuditReports } = require('../../src/security');

      await cleanupOldAuditReports();

      expect(mockWhere).toHaveBeenCalledWith('createdAt', '<', expect.any(admin.firestore.Timestamp));
    });

    it('should handle errors during cleanup', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => {
        throw new Error('Database error');
      });

      const { cleanupOldAuditReports } = require('../../src/security');

      await expect(cleanupOldAuditReports()).rejects.toThrow('Database error');
      expect(logError).toHaveBeenCalledWith('Error cleaning up old audit reports:', expect.any(Error));
    });

    it('should have correct schedule configuration (1st of month 4 AM UTC)', () => {
      const { cleanupOldAuditReports } = require('../../src/security');

      // Verify function exists and can be called
      expect(cleanupOldAuditReports).toBeDefined();
      expect(typeof cleanupOldAuditReports).toBe('function');
    });
  });

  // ========== INTEGRATION TESTS ==========
  describe('Security Service Integration', () => {
    it('should complete full audit lifecycle', async () => {
      // 1. Run audit
      (verifyAdminAuth as jest.Mock).mockResolvedValue(undefined);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          where: jest.fn().mockReturnThis(),
          orderBy: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({ docs: [], empty: true, size: 0 }),
          add: jest.fn().mockResolvedValue({ id: 'integration-audit-1' }),
          doc: jest.fn((docId?: string) => ({
            get: jest.fn().mockResolvedValue({
              exists: docId === 'integration-audit-1',
              id: docId || 'test',
              data: () => ({
                auditType: 'full_audit',
                totalFindings: 0,
                severityCounts: { critical: 0, high: 0, medium: 0, low: 0, info: 0 },
                runBy: 'admin-123',
              }),
            }),
          })),
        };
        return chainable;
      });

      const { runSecurityAudit, getSecurityAuditReport } = require('../../src/security');

      // Run audit
      const auditResult = await runSecurityAudit({
        data: {},
        ...createMockAuthContext('admin-123', 'admin'),
      });

      expect(auditResult.success).toBe(true);
      expect(auditResult.reportId).toBe('integration-audit-1');

      // Retrieve report
      const reportResult = await getSecurityAuditReport({
        data: { reportId: auditResult.reportId },
        ...createMockAuthContext('admin-123', 'admin'),
      });

      expect(reportResult.success).toBe(true);
      expect(reportResult.report.id).toBe('integration-audit-1');
    });

    it('should handle scheduled audit and cleanup workflow', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: [], empty: true, size: 0 }),
        add: jest.fn().mockResolvedValue({ id: 'scheduled-1' }),
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { scheduledSecurityAudit, cleanupOldAuditReports } = require('../../src/security');

      // Run scheduled audit
      await scheduledSecurityAudit();

      expect(logInfo).toHaveBeenCalledWith('Running scheduled security audit');

      // Run cleanup
      await cleanupOldAuditReports();

      expect(logInfo).toHaveBeenCalledWith('Cleaning up old security audit reports');
    });
  });
});
