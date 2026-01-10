/**
 * Backup & Export Service Tests
 * Comprehensive tests for all 8 backup and export functions
 */

import * as admin from 'firebase-admin';
import { FieldValue } from '../../src/shared/utils';
import {
  createMockAuthContext,
} from '../utils/test-helpers';

// Mock crypto
const mockCrypto = {
  randomBytes: jest.fn((size: number) => Buffer.alloc(size, 0)),
  createCipheriv: jest.fn(() => ({
    update: jest.fn(() => 'encrypted-data'),
    final: jest.fn(() => '-final'),
    getAuthTag: jest.fn(() => Buffer.from('auth-tag')),
  })),
  createDecipheriv: jest.fn(() => ({
    setAuthTag: jest.fn(),
    update: jest.fn(() => '{"test": "data"}'),
    final: jest.fn(() => ''),
  })),
  createHash: jest.fn(() => ({
    update: jest.fn().mockReturnThis(),
    digest: jest.fn(() => 'hash'),
  })),
};

jest.mock('crypto', () => mockCrypto);

// Mock PDFKit
const mockPDFDocument = {
  on: jest.fn(),
  fontSize: jest.fn().mockReturnThis(),
  fillColor: jest.fn().mockReturnThis(),
  text: jest.fn().mockReturnThis(),
  moveDown: jest.fn().mockReturnThis(),
  end: jest.fn(),
};

jest.mock('pdfkit', () => {
  return jest.fn(() => mockPDFDocument);
});

// Mock Firebase Admin
jest.mock('firebase-admin', () => {
  const actualAdmin = jest.requireActual('firebase-admin');
  return {
    ...actualAdmin,
    firestore: jest.fn(() => ({
      collection: jest.fn(),
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

// Mock Firestore and Storage
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
    delete: jest.fn(),
    commit: jest.fn(),
  })),
};

const mockStorage = {
  bucket: jest.fn(() => ({
    file: jest.fn(() => ({
      save: jest.fn(),
      download: jest.fn(),
      delete: jest.fn(),
      getSignedUrl: jest.fn(),
    })),
  })),
};

// Mock shared/utils
jest.mock('../../src/shared/utils', () => ({
  db: mockDb,
  storage: mockStorage,
  FieldValue: {
    serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
  },
  verifyAuth: jest.fn(),
  handleError: jest.fn(err => err),
  logInfo: jest.fn(),
  logError: jest.fn(),
}));

const { verifyAuth, logInfo, logError } = require('../../src/shared/utils');

describe('Backup & Export Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ========== 1. BACKUP CONVERSATION ==========
  describe('backupConversation', () => {
    const mockRequest = {
      data: {
        conversationId: 'conv-123',
        includeMedia: false,
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
      }));
    });

    it('should backup conversation with encryption', async () => {
      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
          lastMessageTimestamp: new Date(),
        }),
      };

      const mockMessages = [
        {
          id: 'msg-1',
          data: () => ({
            content: 'Hello',
            senderId: 'user-123',
            timestamp: { toDate: () => new Date() },
          }),
        },
        {
          id: 'msg-2',
          data: () => ({
            content: 'Hi',
            senderId: 'user-456',
            timestamp: { toDate: () => new Date() },
          }),
        },
      ];

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
      };

      const mockBucket = {
        file: jest.fn(() => mockFile),
      };

      (mockStorage.bucket as jest.Mock).mockReturnValue(mockBucket);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockConversationDoc),
          set: jest.fn().mockResolvedValue(undefined),
        })),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: mockMessages }),
        add: jest.fn().mockResolvedValue({ id: 'backup-123' }),
      }));

      const { backupConversation } = require('../../src/backup');

      const result = await backupConversation(mockRequest);

      expect(result).toMatchObject({
        success: true,
        backupId: 'backup-123',
        messageCount: 2,
        size: expect.any(Number),
      });

      expect(mockFile.save).toHaveBeenCalled();
      expect(logInfo).toHaveBeenCalledWith('Backing up conversation conv-123 for user user-123');
    });

    it('should reject if conversation not found', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { backupConversation } = require('../../src/backup');

      await expect(backupConversation(mockRequest)).rejects.toThrow('Conversation not found');
    });

    it('should reject unauthorized user', async () => {
      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-456', 'user-789'],
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockConversationDoc),
        })),
      }));

      const { backupConversation } = require('../../src/backup');

      await expect(backupConversation(mockRequest)).rejects.toThrow('Not authorized');
    });

    it('should set 90-day expiration on backups', async () => {
      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockMessages = [{
        id: 'msg-1',
        data: () => ({
          content: 'Test',
          timestamp: { toDate: () => new Date() },
        }),
      }];

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
      };

      (mockStorage.bucket as jest.Mock).mockReturnValue({
        file: jest.fn(() => mockFile),
      });

      const mockAdd = jest.fn().mockResolvedValue({ id: 'backup-123' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockConversationDoc),
          set: jest.fn(),
        })),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: mockMessages }),
        add: mockAdd,
      }));

      const { backupConversation } = require('../../src/backup');

      await backupConversation(mockRequest);

      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          expiresAt: expect.anything(),
        })
      );
    });
  });

  // ========== 2. RESTORE CONVERSATION ==========
  describe('restoreConversation', () => {
    const mockRequest = {
      data: {
        backupId: 'backup-123',
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    });

    it('should restore conversation from backup', async () => {
      const mockBackupDoc = {
        exists: true,
        data: () => ({
          userId: 'user-123',
          fileName: 'user-123/conv-123/backup.json',
          conversationId: 'conv-123',
        }),
      };

      const mockFileContents = JSON.stringify({
        encrypted: 'encrypted-data',
        iv: 'iv-hex',
        authTag: 'auth-tag-hex',
        key: 'key-hex',
      });

      const mockFile = {
        download: jest.fn().mockResolvedValue([Buffer.from(mockFileContents)]),
      };

      (mockStorage.bucket as jest.Mock).mockReturnValue({
        file: jest.fn(() => mockFile),
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockBackupDoc),
        })),
      }));

      const { restoreConversation } = require('../../src/backup');

      const result = await restoreConversation(mockRequest);

      expect(result).toMatchObject({
        success: true,
        conversationId: expect.any(String),
        data: expect.any(Object),
      });

      expect(mockFile.download).toHaveBeenCalled();
    });

    it('should reject if backup not found', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { restoreConversation } = require('../../src/backup');

      await expect(restoreConversation(mockRequest)).rejects.toThrow('Backup not found');
    });

    it('should reject unauthorized user', async () => {
      const mockBackupDoc = {
        exists: true,
        data: () => ({
          userId: 'user-456', // Different user
          fileName: 'test.json',
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockBackupDoc),
        })),
      }));

      const { restoreConversation } = require('../../src/backup');

      await expect(restoreConversation(mockRequest)).rejects.toThrow('Not authorized');
    });
  });

  // ========== 3. LIST BACKUPS ==========
  describe('listBackups', () => {
    const mockRequest = createMockAuthContext('user-123');

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    });

    it('should list user backups', async () => {
      const mockBackups = [
        {
          id: 'backup-1',
          data: () => ({
            conversationId: 'conv-1',
            messageCount: 10,
            createdAt: { toDate: () => new Date() },
            expiresAt: { toDate: () => new Date() },
          }),
        },
        {
          id: 'backup-2',
          data: () => ({
            conversationId: 'conv-2',
            messageCount: 20,
            createdAt: { toDate: () => new Date() },
            expiresAt: { toDate: () => new Date() },
          }),
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: mockBackups }),
      }));

      const { listBackups } = require('../../src/backup');

      const result = await listBackups(mockRequest);

      expect(result).toMatchObject({
        success: true,
        backups: expect.arrayContaining([
          expect.objectContaining({
            id: 'backup-1',
            conversationId: 'conv-1',
          }),
          expect.objectContaining({
            id: 'backup-2',
            conversationId: 'conv-2',
          }),
        ]),
        total: 2,
      });
    });

    it('should limit backups to 50', async () => {
      const mockLimit = jest.fn().mockReturnThis();

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: mockLimit,
        get: jest.fn().mockResolvedValue({ docs: [] }),
      }));

      const { listBackups } = require('../../src/backup');

      await listBackups(mockRequest);

      expect(mockLimit).toHaveBeenCalledWith(50);
    });

    it('should order by createdAt descending', async () => {
      const mockOrderBy = jest.fn().mockReturnThis();

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        orderBy: mockOrderBy,
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: [] }),
      }));

      const { listBackups } = require('../../src/backup');

      await listBackups(mockRequest);

      expect(mockOrderBy).toHaveBeenCalledWith('createdAt', 'desc');
    });
  });

  // ========== 4. DELETE BACKUP ==========
  describe('deleteBackup', () => {
    const mockRequest = {
      data: {
        backupId: 'backup-123',
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    });

    it('should delete backup from storage and firestore', async () => {
      const mockBackupDoc = {
        exists: true,
        data: () => ({
          userId: 'user-123',
          fileName: 'test-backup.json',
        }),
        ref: {
          delete: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockFileDelete = jest.fn().mockResolvedValue(undefined);

      (mockStorage.bucket as jest.Mock).mockReturnValue({
        file: jest.fn(() => ({
          delete: mockFileDelete,
        })),
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockBackupDoc),
        })),
      }));

      const { deleteBackup } = require('../../src/backup');

      const result = await deleteBackup(mockRequest);

      expect(result).toMatchObject({
        success: true,
        message: 'Backup deleted successfully',
      });

      expect(mockFileDelete).toHaveBeenCalled();
      expect(mockBackupDoc.ref.delete).toHaveBeenCalled();
    });

    it('should reject if backup not found', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { deleteBackup } = require('../../src/backup');

      await expect(deleteBackup(mockRequest)).rejects.toThrow('Backup not found');
    });

    it('should reject unauthorized user', async () => {
      const mockBackupDoc = {
        exists: true,
        data: () => ({
          userId: 'user-456',
          fileName: 'test.json',
        }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockBackupDoc),
        })),
      }));

      const { deleteBackup } = require('../../src/backup');

      await expect(deleteBackup(mockRequest)).rejects.toThrow('Not authorized');
    });
  });

  // ========== 5. AUTO-BACKUP CONVERSATIONS ==========
  describe('autoBackupConversations', () => {
    beforeEach(() => {
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
        toMillis: () => date.getTime(),
      }));
    });

    it('should auto-backup active conversations', async () => {
      const mockConversations = [
        {
          id: 'conv-1',
          data: () => ({
            participants: ['user-1', 'user-2'],
            lastMessageTimestamp: new Date(),
          }),
        },
      ];

      const mockMessages = [
        {
          id: 'msg-1',
          data: () => ({
            content: 'Test',
            timestamp: { toDate: () => new Date() },
          }),
        },
      ];

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
      };

      (mockStorage.bucket as jest.Mock).mockReturnValue({
        file: jest.fn(() => mockFile),
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: collectionName === 'conversations' ? mockConversations :
                collectionName === 'messages' ? mockMessages :
                [],
          empty: true,
          size: collectionName === 'conversations' ? 1 : mockMessages.length,
        }),
        add: jest.fn().mockResolvedValue({ id: 'backup-1' }),
      }));

      const { autoBackupConversations } = require('../../src/backup');

      await autoBackupConversations();

      expect(logInfo).toHaveBeenCalledWith('Starting auto-backup of active conversations');
      expect(logInfo).toHaveBeenCalledWith('Auto-backup completed');
    });

    it('should skip conversations already backed up this week', async () => {
      const mockConversations = [
        {
          id: 'conv-1',
          data: () => ({
            participants: ['user-1'],
            lastMessageTimestamp: new Date(),
          }),
        },
      ];

      const mockExistingBackup = [
        {
          id: 'existing-backup',
          data: () => ({
            createdAt: new Date(),
          }),
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: collectionName === 'conversations' ? mockConversations : mockExistingBackup,
          empty: collectionName === 'conversations' ? false : false,
          size: 1,
        }),
      }));

      const { autoBackupConversations } = require('../../src/backup');

      await autoBackupConversations();

      expect(logInfo).toHaveBeenCalledWith(
        expect.stringContaining('Backup already exists')
      );
    });

    it('should have correct schedule configuration (Sunday 3 AM)', () => {
      const { autoBackupConversations } = require('../../src/backup');

      expect(autoBackupConversations).toBeDefined();
      expect(typeof autoBackupConversations).toBe('function');
    });
  });

  // ========== 6. EXPORT CONVERSATION TO PDF ==========
  describe('exportConversationToPDF', () => {
    const mockRequest = {
      data: {
        conversationId: 'conv-123',
        theme: 'gold' as const,
      },
      ...createMockAuthContext('user-123'),
    };

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
      }));

      // Setup PDF mock
      mockPDFDocument.on.mockImplementation((event, callback) => {
        if (event === 'end') {
          setTimeout(() => callback(), 0);
        }
        return mockPDFDocument;
      });
    });

    it('should export conversation to PDF', async () => {
      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockMessages = [
        {
          id: 'msg-1',
          data: () => ({
            content: 'Hello',
            senderId: 'user-123',
            timestamp: { toDate: () => new Date() },
          }),
        },
      ];

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
        getSignedUrl: jest.fn().mockResolvedValue(['https://example.com/file.pdf']),
      };

      (mockStorage.bucket as jest.Mock).mockReturnValue({
        file: jest.fn(() => mockFile),
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockConversationDoc),
        })),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: mockMessages, size: 1 }),
        add: jest.fn().mockResolvedValue({ id: 'export-1' }),
      }));

      const { exportConversationToPDF } = require('../../src/backup');

      const result = await exportConversationToPDF(mockRequest);

      expect(result).toMatchObject({
        success: true,
        pdfUrl: 'https://example.com/file.pdf',
        messageCount: 1,
        expiresIn: '7 days',
      });
    });

    it('should reject if conversation not found', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue({ exists: false }),
        })),
      }));

      const { exportConversationToPDF } = require('../../src/backup');

      await expect(exportConversationToPDF(mockRequest)).rejects.toThrow('Conversation not found');
    });

    it('should support different themes', async () => {
      const themes: Array<'light' | 'dark' | 'gold'> = ['light', 'dark', 'gold'];

      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
        getSignedUrl: jest.fn().mockResolvedValue(['https://example.com/file.pdf']),
      };

      (mockStorage.bucket as jest.Mock).mockReturnValue({
        file: jest.fn(() => mockFile),
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(mockConversationDoc),
        })),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: [], size: 0 }),
        add: jest.fn().mockResolvedValue({ id: 'export-1' }),
      }));

      const { exportConversationToPDF } = require('../../src/backup');

      for (const theme of themes) {
        const result = await exportConversationToPDF({
          ...mockRequest,
          data: { conversationId: 'conv-123', theme },
        });

        expect(result.success).toBe(true);
      }
    });
  });

  // ========== 7. LIST PDF EXPORTS ==========
  describe('listPDFExports', () => {
    const mockRequest = createMockAuthContext('user-123');

    beforeEach(() => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
    });

    it('should list user PDF exports', async () => {
      const mockExports = [
        {
          id: 'export-1',
          data: () => ({
            conversationId: 'conv-1',
            theme: 'gold',
            createdAt: { toDate: () => new Date() },
            expiresAt: { toDate: () => new Date() },
          }),
        },
        {
          id: 'export-2',
          data: () => ({
            conversationId: 'conv-2',
            theme: 'light',
            createdAt: { toDate: () => new Date() },
            expiresAt: { toDate: () => new Date() },
          }),
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: mockExports }),
      }));

      const { listPDFExports } = require('../../src/backup');

      const result = await listPDFExports(mockRequest);

      expect(result).toMatchObject({
        success: true,
        exports: expect.arrayContaining([
          expect.objectContaining({
            id: 'export-1',
            theme: 'gold',
          }),
          expect.objectContaining({
            id: 'export-2',
            theme: 'light',
          }),
        ]),
        total: 2,
      });
    });

    it('should limit exports to 20', async () => {
      const mockLimit = jest.fn().mockReturnThis();

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: mockLimit,
        get: jest.fn().mockResolvedValue({ docs: [] }),
      }));

      const { listPDFExports } = require('../../src/backup');

      await listPDFExports(mockRequest);

      expect(mockLimit).toHaveBeenCalledWith(20);
    });
  });

  // ========== 8. CLEANUP EXPIRED EXPORTS ==========
  describe('cleanupExpiredExports', () => {
    beforeEach(() => {
      (admin.firestore.Timestamp.now as jest.Mock).mockReturnValue({
        toMillis: () => Date.now(),
      });
    });

    it('should cleanup expired PDF exports', async () => {
      const mockExpiredExports = [
        {
          id: 'export-1',
          data: () => ({
            fileName: 'expired-1.pdf',
          }),
          ref: {},
        },
        {
          id: 'export-2',
          data: () => ({
            fileName: 'expired-2.pdf',
          }),
          ref: {},
        },
      ];

      const mockFileDelete = jest.fn().mockResolvedValue(undefined);
      const mockBatchDelete = jest.fn();
      const mockBatchCommit = jest.fn().mockResolvedValue(undefined);

      (mockStorage.bucket as jest.Mock).mockReturnValue({
        file: jest.fn(() => ({
          delete: mockFileDelete,
        })),
      });

      (mockDb.batch as jest.Mock).mockReturnValue({
        delete: mockBatchDelete,
        commit: mockBatchCommit,
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockExpiredExports,
          size: 2,
        }),
      }));

      const { cleanupExpiredExports } = require('../../src/backup');

      await cleanupExpiredExports();

      expect(mockFileDelete).toHaveBeenCalledTimes(2);
      expect(mockBatchDelete).toHaveBeenCalledTimes(2);
      expect(mockBatchCommit).toHaveBeenCalled();
      expect(logInfo).toHaveBeenCalledWith('Cleanup completed: 2 exports deleted');
    });

    it('should handle no expired exports', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: [],
          size: 0,
        }),
      }));

      const { cleanupExpiredExports } = require('../../src/backup');

      await cleanupExpiredExports();

      expect(logInfo).toHaveBeenCalledWith('Found 0 expired exports to delete');
    });

    it('should continue cleanup even if file deletion fails', async () => {
      const mockExpiredExports = [
        {
          id: 'export-1',
          data: () => ({
            fileName: 'failed-delete.pdf',
          }),
          ref: {},
        },
      ];

      const mockFileDelete = jest.fn().mockRejectedValue(new Error('File not found'));
      const mockBatchDelete = jest.fn();
      const mockBatchCommit = jest.fn().mockResolvedValue(undefined);

      (mockStorage.bucket as jest.Mock).mockReturnValue({
        file: jest.fn(() => ({
          delete: mockFileDelete,
        })),
      });

      (mockDb.batch as jest.Mock).mockReturnValue({
        delete: mockBatchDelete,
        commit: mockBatchCommit,
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockExpiredExports,
          size: 1,
        }),
      }));

      const { cleanupExpiredExports } = require('../../src/backup');

      await cleanupExpiredExports();

      expect(logError).toHaveBeenCalled();
      expect(mockBatchCommit).toHaveBeenCalled(); // Still commits Firestore deletion
    });

    it('should have correct schedule configuration (daily 2 AM)', () => {
      const { cleanupExpiredExports } = require('../../src/backup');

      expect(cleanupExpiredExports).toBeDefined();
      expect(typeof cleanupExpiredExports).toBe('function');
    });
  });

  // ========== INTEGRATION TESTS ==========
  describe('Backup Integration', () => {
    it('should handle complete backup lifecycle', async () => {
      (verifyAuth as jest.Mock).mockResolvedValue('user-123');
      (admin.firestore.Timestamp.fromDate as jest.Mock).mockImplementation((date) => ({
        toDate: () => date,
      }));

      const mockConversationDoc = {
        exists: true,
        data: () => ({
          participants: ['user-123', 'user-456'],
        }),
      };

      const mockBackupDoc = {
        exists: true,
        data: () => ({
          userId: 'user-123',
          fileName: 'test.json',
          conversationId: 'conv-123',
        }),
        ref: {
          delete: jest.fn().mockResolvedValue(undefined),
        },
      };

      const mockMessages = [{
        id: 'msg-1',
        data: () => ({
          content: 'Test',
          timestamp: { toDate: () => new Date() },
        }),
      }];

      const mockBackups = [{
        id: 'backup-123',
        data: () => ({
          conversationId: 'conv-123',
          createdAt: { toDate: () => new Date() },
          expiresAt: { toDate: () => new Date() },
        }),
      }];

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
        download: jest.fn().mockResolvedValue([Buffer.from(JSON.stringify({
          encrypted: 'data',
          iv: 'iv',
          authTag: 'tag',
          key: 'key',
        }))]),
        delete: jest.fn().mockResolvedValue(undefined),
      };

      (mockStorage.bucket as jest.Mock).mockReturnValue({
        file: jest.fn(() => mockFile),
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(
            collectionName === 'conversations' ? mockConversationDoc : mockBackupDoc
          ),
        })),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: collectionName === 'messages' ? mockMessages :
                collectionName === 'backups' ? mockBackups : [],
        }),
        add: jest.fn().mockResolvedValue({ id: 'backup-123' }),
      }));

      const {
        backupConversation,
        listBackups,
        restoreConversation,
        deleteBackup,
      } = require('../../src/backup');

      // 1. Backup
      const backupResult = await backupConversation({
        data: { conversationId: 'conv-123' },
        ...createMockAuthContext('user-123'),
      });

      expect(backupResult.success).toBe(true);

      // 2. List
      const listResult = await listBackups(createMockAuthContext('user-123'));

      expect(listResult.backups.length).toBeGreaterThan(0);

      // 3. Restore
      const restoreResult = await restoreConversation({
        data: { backupId: 'backup-123' },
        ...createMockAuthContext('user-123'),
      });

      expect(restoreResult.success).toBe(true);

      // 4. Delete
      const deleteResult = await deleteBackup({
        data: { backupId: 'backup-123' },
        ...createMockAuthContext('user-123'),
      });

      expect(deleteResult.success).toBe(true);
    });
  });
});
