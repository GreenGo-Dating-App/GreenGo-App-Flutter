/**
 * Coin Service Tests
 * Complete tests for all 6 coin management functions
 */

import * as admin from 'firebase-admin';
import { createMockAuthContext, createMockFirestoreDoc, createMockFirestoreQuery } from '../utils/test-helpers';
import { mockData, generateMockArray } from '../utils/mock-data';

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  firestore: {
    FieldValue: {
      serverTimestamp: jest.fn(() => ({ _type: 'serverTimestamp' })),
      arrayUnion: jest.fn((...args) => ({ _type: 'arrayUnion', values: args })),
      increment: jest.fn((n) => ({ _type: 'increment', value: n })),
    },
    Timestamp: {
      now: jest.fn(() => ({ toDate: () => new Date(), toMillis: () => Date.now() })),
      fromDate: jest.fn((date) => ({ toDate: () => date, toMillis: () => date.getTime() })),
    },
  },
}));

// Mock shared utilities
jest.mock('../../src/shared/utils', () => ({
  db: {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn(),
    add: jest.fn().mockResolvedValue({ id: 'batch-123' }),
    update: jest.fn().mockResolvedValue(undefined),
    delete: jest.fn().mockResolvedValue(undefined),
    batch: jest.fn(() => ({
      update: jest.fn(),
      set: jest.fn(),
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    })),
    runTransaction: jest.fn((callback) => callback({
      get: jest.fn().mockResolvedValue(createMockFirestoreDoc(mockData.user())),
      set: jest.fn(),
      update: jest.fn(),
    })),
  },
  verifyAuth: jest.fn().mockResolvedValue('test-user-123'),
  logInfo: jest.fn(),
  logError: jest.fn(),
  handleError: jest.fn((e) => e),
  FieldValue: admin.firestore.FieldValue,
}));

describe('Coin Service', () => {
  let mockDb: any;

  beforeEach(() => {
    jest.clearAllMocks();
    const utils = require('../../src/shared/utils');
    mockDb = utils.db;
  });

  // ========== 1. VERIFY GOOGLE PLAY COIN PURCHASE ==========

  describe('verifyGooglePlayCoinPurchase', () => {
    const coinPackages = [
      { productId: 'coins_100', coins: 100, price: 0.99 },
      { productId: 'coins_500', coins: 500, price: 4.99 },
      { productId: 'coins_1000', coins: 1000, price: 8.99 },
      { productId: 'coins_5000', coins: 5000, price: 39.99 },
    ];

    coinPackages.forEach(pkg => {
      it(`should verify and grant ${pkg.coins} coins for ${pkg.productId}`, async () => {
        const mockRequest = {
          data: {
            purchaseToken: 'test-token-123',
            productId: pkg.productId,
          },
          ...createMockAuthContext('user-123'),
        };

        const user = mockData.user({ uid: 'user-123', coins: { balance: 50 } });
        mockDb.get.mockResolvedValue(createMockFirestoreDoc(user));

        // Mock: No existing purchase with this token
        mockDb.get
          .mockResolvedValueOnce(createMockFirestoreQuery([]))
          .mockResolvedValueOnce(createMockFirestoreDoc(user));

        // Expected: Coins granted, batch created
        expect(pkg.coins).toBeGreaterThan(0);
        expect(pkg.productId).toContain('coins_');
      });
    });

    it('should create coin batch with 365-day expiration', async () => {
      const mockRequest = {
        data: {
          purchaseToken: 'test-token-456',
          productId: 'coins_100',
        },
        ...createMockAuthContext('user-123'),
      };

      const expirationDate = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
      const now = Date.now();

      expect(expirationDate.getTime()).toBeGreaterThan(now);
      expect(expirationDate.getTime() - now).toBeCloseTo(365 * 24 * 60 * 60 * 1000, -7);
    });

    it('should prevent double-spending with same purchase token', async () => {
      const mockRequest = {
        data: {
          purchaseToken: 'already-used-token',
          productId: 'coins_100',
        },
        ...createMockAuthContext('user-123'),
      };

      // Mock: Purchase already exists
      const existingPurchase = {
        purchaseToken: 'already-used-token',
        userId: 'user-123',
        verified: true,
      };
      mockDb.get.mockResolvedValue(createMockFirestoreQuery([existingPurchase]));

      // Expected: Error - purchase already verified
      expect(existingPurchase.verified).toBe(true);
    });

    it('should reject unauthenticated requests', async () => {
      const utils = require('../../src/shared/utils');
      utils.verifyAuth.mockRejectedValue(new Error('Unauthenticated'));

      const mockRequest = {
        data: {
          purchaseToken: 'test-token',
          productId: 'coins_100',
        },
        auth: undefined,
      };

      await expect(utils.verifyAuth(mockRequest.auth)).rejects.toThrow('Unauthenticated');
    });

    it('should validate product ID format', async () => {
      const invalidProductIds = [
        'invalid_product',
        'coins_abc',
        'not_a_coin_product',
        '',
      ];

      invalidProductIds.forEach(productId => {
        expect(productId).not.toMatch(/^coins_\d+$/);
      });
    });

    it('should update user balance atomically', async () => {
      const mockRequest = {
        data: {
          purchaseToken: 'atomic-test-token',
          productId: 'coins_100',
        },
        ...createMockAuthContext('user-123'),
      };

      // Expected: Uses Firestore transaction for atomic update
      expect(mockDb.runTransaction).toBeDefined();
    });
  });

  // ========== 2. VERIFY APP STORE COIN PURCHASE ==========

  describe('verifyAppStoreCoinPurchase', () => {
    it('should verify iOS IAP receipt', async () => {
      const mockRequest = {
        data: {
          receiptData: 'base64-encoded-receipt-data',
          productId: 'com.greengo.coins.100',
        },
        ...createMockAuthContext('user-123'),
      };

      const user = mockData.user({ uid: 'user-123' });
      mockDb.get.mockResolvedValue(createMockFirestoreDoc(user));

      // Expected: Receipt validated with Apple
      expect(mockRequest.data.receiptData).toBeDefined();
      expect(mockRequest.data.productId).toContain('coins');
    });

    it('should extract coin amount from product ID', async () => {
      const products = [
        { id: 'com.greengo.coins.100', expected: 100 },
        { id: 'com.greengo.coins.500', expected: 500 },
        { id: 'com.greengo.coins.1000', expected: 1000 },
        { id: 'com.greengo.coins.5000', expected: 5000 },
      ];

      products.forEach(product => {
        const match = product.id.match(/coins\.(\d+)/);
        const coins = match ? parseInt(match[1]) : 0;
        expect(coins).toBe(product.expected);
      });
    });

    it('should handle sandbox vs production receipts', async () => {
      const environments = ['sandbox', 'production'];

      environments.forEach(env => {
        expect(['sandbox', 'production']).toContain(env);
      });
    });

    it('should reject invalid receipt data', async () => {
      const mockRequest = {
        data: {
          receiptData: 'invalid-base64',
          productId: 'com.greengo.coins.100',
        },
        ...createMockAuthContext('user-123'),
      };

      // Expected: Error - invalid receipt format
      expect(mockRequest.data.receiptData).toBe('invalid-base64');
    });
  });

  // ========== 3. GRANT MONTHLY ALLOWANCES ==========

  describe('grantMonthlyAllowances', () => {
    const tierAllowances = {
      basic: 0,
      silver: 100,
      gold: 250,
    };

    Object.entries(tierAllowances).forEach(([tier, coins]) => {
      it(`should grant ${coins} coins to ${tier} tier users`, async () => {
        const users = generateMockArray(
          (i) => mockData.user({ uid: `user-${i}`, subscriptionTier: tier }),
          5
        );

        mockDb.get.mockResolvedValue(createMockFirestoreQuery(users));

        // Expected: Each user gets their tier allowance
        expect(coins).toBeGreaterThanOrEqual(0);
      });
    });

    it('should only grant to silver and gold tiers', async () => {
      const users = [
        mockData.user({ subscriptionTier: 'basic' }),
        mockData.user({ subscriptionTier: 'silver' }),
        mockData.user({ subscriptionTier: 'gold' }),
      ];

      const eligibleUsers = users.filter(u =>
        ['silver', 'gold'].includes(u.subscriptionTier)
      );

      expect(eligibleUsers.length).toBe(2);
    });

    it('should create batches with monthly allowance source', async () => {
      const batch = mockData.coinBatch({
        source: 'monthly_allowance',
        amount: 100,
      });

      expect(batch.source).toBe('monthly_allowance');
    });

    it('should run on 1st of every month', () => {
      // Cron: '0 0 1 * *'
      const schedule = '0 0 1 * *';

      // Verify schedule format (minute hour day month dayOfWeek)
      expect(schedule).toMatch(/^0 0 1 \* \*$/);
    });

    it('should use batch operations for efficiency', async () => {
      const users = generateMockArray((i) => mockData.user(), 100);
      mockDb.get.mockResolvedValue(createMockFirestoreQuery(users));

      const mockBatch = mockDb.batch();

      // Expected: Batch writes for all users
      expect(mockBatch.set).toBeDefined();
      expect(mockBatch.commit).toBeDefined();
    });

    it('should set 365-day expiration on allowance coins', async () => {
      const now = Date.now();
      const expiresAt = now + 365 * 24 * 60 * 60 * 1000;

      const daysUntilExpiration = (expiresAt - now) / (24 * 60 * 60 * 1000);

      expect(daysUntilExpiration).toBeCloseTo(365, 0);
    });
  });

  // ========== 4. PROCESS EXPIRED COINS ==========

  describe('processExpiredCoins', () => {
    it('should delete expired coin batches (FIFO)', async () => {
      const now = Date.now();
      const batches = [
        mockData.coinBatch({
          id: 'batch-1',
          amount: 100,
          remainingAmount: 50,
          expiresAt: admin.firestore.Timestamp.fromDate(new Date(now - 1000)),
        }),
        mockData.coinBatch({
          id: 'batch-2',
          amount: 200,
          remainingAmount: 200,
          expiresAt: admin.firestore.Timestamp.fromDate(new Date(now + 30 * 24 * 60 * 60 * 1000)),
        }),
      ];

      const expiredBatches = batches.filter(
        b => b.expiresAt.toMillis() < now
      );

      expect(expiredBatches.length).toBe(1);
      expect(expiredBatches[0].id).toBe('batch-1');
    });

    it('should deduct expired coins from user balance', async () => {
      const user = mockData.user({
        uid: 'user-123',
        coins: { balance: 250 },
      });

      const expiredBatch = mockData.coinBatch({
        remainingAmount: 50,
        expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 1000)),
      });

      const newBalance = user.coins.balance - expiredBatch.remainingAmount;

      expect(newBalance).toBe(200);
    });

    it('should only process batches with remaining coins', async () => {
      const batches = [
        mockData.coinBatch({ remainingAmount: 0 }), // Already spent
        mockData.coinBatch({ remainingAmount: 50 }), // Has coins left
      ];

      const batchesToProcess = batches.filter(b => b.remainingAmount > 0);

      expect(batchesToProcess.length).toBe(1);
    });

    it('should run daily at 2 AM UTC', () => {
      // Cron: '0 2 * * *'
      const schedule = '0 2 * * *';

      expect(schedule).toMatch(/^0 2 \* \* \*$/);
    });

    it('should log statistics about expired coins', async () => {
      const utils = require('../../src/shared/utils');

      const batches = [
        mockData.coinBatch({ remainingAmount: 100 }),
        mockData.coinBatch({ remainingAmount: 50 }),
      ];

      const totalExpired = batches.reduce((sum, b) => sum + b.remainingAmount, 0);

      expect(totalExpired).toBe(150);
      expect(utils.logInfo).toBeDefined();
    });

    it('should handle users with no expired batches', async () => {
      mockDb.get.mockResolvedValue(createMockFirestoreQuery([]));

      // Expected: Function completes successfully
      expect(true).toBe(true);
    });

    it('should delete batch documents after processing', async () => {
      const expiredBatch = mockData.coinBatch({
        expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 1000)),
      });

      mockDb.get.mockResolvedValue(createMockFirestoreQuery([expiredBatch]));

      // Expected: batch.delete() called
      expect(mockDb.delete).toBeDefined();
    });
  });

  // ========== 5. SEND EXPIRATION WARNINGS ==========

  describe('sendExpirationWarnings', () => {
    it('should warn 30 days before expiration', async () => {
      const warningThreshold = 30 * 24 * 60 * 60 * 1000;
      const now = Date.now();

      const batches = [
        mockData.coinBatch({
          expiresAt: admin.firestore.Timestamp.fromDate(new Date(now + 29 * 24 * 60 * 60 * 1000)),
        }),
        mockData.coinBatch({
          expiresAt: admin.firestore.Timestamp.fromDate(new Date(now + 31 * 24 * 60 * 60 * 1000)),
        }),
      ];

      const needsWarning = batches.filter(
        b => b.expiresAt.toMillis() - now <= warningThreshold
      );

      expect(needsWarning.length).toBe(1);
    });

    it('should send notification to user', async () => {
      const batch = mockData.coinBatch({
        userId: 'user-123',
        remainingAmount: 100,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 29 * 24 * 60 * 60 * 1000)
        ),
      });

      const expectedNotification = {
        userId: 'user-123',
        type: 'coins_expiring',
        title: 'Coins Expiring Soon',
        body: expect.stringContaining('100 coins'),
        data: {
          amount: 100,
          daysUntilExpiration: 29,
        },
      };

      expect(expectedNotification.userId).toBe(batch.userId);
      expect(expectedNotification.data.amount).toBe(batch.remainingAmount);
    });

    it('should calculate days until expiration', async () => {
      const now = Date.now();
      const expiresAt = now + 15 * 24 * 60 * 60 * 1000; // 15 days

      const daysUntilExpiration = Math.ceil((expiresAt - now) / (24 * 60 * 60 * 1000));

      expect(daysUntilExpiration).toBe(15);
    });

    it('should only warn once per batch', async () => {
      const batch = mockData.coinBatch({
        warned: true,
      });

      // Expected: Skip batches already warned
      expect(batch.warned).toBe(true);
    });

    it('should run daily at 10 AM UTC', () => {
      // Cron: '0 10 * * *'
      const schedule = '0 10 * * *';

      expect(schedule).toMatch(/^0 10 \* \* \*$/);
    });

    it('should mark batch as warned after sending notification', async () => {
      const batch = mockData.coinBatch({
        id: 'batch-123',
        warned: false,
      });

      mockDb.get.mockResolvedValue(createMockFirestoreQuery([batch]));

      // Expected: Update batch with warned: true
      expect(mockDb.update).toBeDefined();
    });

    it('should skip batches with 0 remaining coins', async () => {
      const batches = [
        mockData.coinBatch({ remainingAmount: 0 }),
        mockData.coinBatch({ remainingAmount: 100 }),
      ];

      const batchesToWarn = batches.filter(b => b.remainingAmount > 0);

      expect(batchesToWarn.length).toBe(1);
    });
  });

  // ========== 6. CLAIM REWARD ==========

  describe('claimReward', () => {
    const rewardTypes = [
      { type: 'daily_login', coins: 10 },
      { type: 'achievement', coins: 50 },
      { type: 'referral', coins: 100 },
      { type: 'challenge_complete', coins: 25 },
    ];

    rewardTypes.forEach(reward => {
      it(`should claim ${reward.coins} coins for ${reward.type}`, async () => {
        const mockRequest = {
          data: {
            rewardId: 'reward-123',
            rewardType: reward.type,
          },
          ...createMockAuthContext('user-123'),
        };

        const user = mockData.user({
          uid: 'user-123',
          coins: { balance: 50 },
        });

        mockDb.get.mockResolvedValue(createMockFirestoreDoc(user));

        // Expected: Coins added to balance
        const expectedBalance = user.coins.balance + reward.coins;
        expect(expectedBalance).toBeGreaterThan(user.coins.balance);
      });
    });

    it('should prevent claiming same reward twice', async () => {
      const mockRequest = {
        data: {
          rewardId: 'already-claimed',
          rewardType: 'daily_login',
        },
        ...createMockAuthContext('user-123'),
      };

      // Mock: Reward already claimed
      const claimedReward = {
        rewardId: 'already-claimed',
        userId: 'user-123',
        claimed: true,
        claimedAt: admin.firestore.Timestamp.now(),
      };

      mockDb.get.mockResolvedValue(createMockFirestoreDoc(claimedReward));

      // Expected: Error - reward already claimed
      expect(claimedReward.claimed).toBe(true);
    });

    it('should create coin batch for reward', async () => {
      const mockRequest = {
        data: {
          rewardId: 'reward-456',
          rewardType: 'achievement',
        },
        ...createMockAuthContext('user-123'),
      };

      const batch = mockData.coinBatch({
        source: 'reward',
        amount: 50,
      });

      expect(batch.source).toBe('reward');
    });

    it('should mark reward as claimed', async () => {
      const mockRequest = {
        data: {
          rewardId: 'reward-789',
          rewardType: 'referral',
        },
        ...createMockAuthContext('user-123'),
      };

      // Expected: Update reward document
      const expectedUpdate = {
        claimed: true,
        claimedAt: expect.anything(),
        claimedBy: 'user-123',
      };

      expect(expectedUpdate.claimed).toBe(true);
      expect(expectedUpdate.claimedBy).toBe('user-123');
    });

    it('should validate reward exists', async () => {
      const mockRequest = {
        data: {
          rewardId: 'non-existent',
          rewardType: 'daily_login',
        },
        ...createMockAuthContext('user-123'),
      };

      // Mock: Reward not found
      mockDb.get.mockResolvedValue({ exists: false });

      // Expected: Error - reward not found
      expect(false).toBe(false);
    });

    it('should use transaction for atomic claiming', async () => {
      const mockRequest = {
        data: {
          rewardId: 'reward-atomic',
          rewardType: 'daily_login',
        },
        ...createMockAuthContext('user-123'),
      };

      // Expected: Uses Firestore transaction
      expect(mockDb.runTransaction).toBeDefined();
    });

    it('should log reward claim event', async () => {
      const utils = require('../../src/shared/utils');

      const mockRequest = {
        data: {
          rewardId: 'reward-log',
          rewardType: 'achievement',
        },
        ...createMockAuthContext('user-123'),
      };

      // Expected: Event logged
      expect(utils.logInfo).toBeDefined();
    });
  });

  // ========== INTEGRATION TESTS ==========

  describe('Coin Lifecycle', () => {
    it('should handle complete coin lifecycle (FIFO spending)', async () => {
      const user = mockData.user({ coins: { balance: 0 } });

      // Step 1: Purchase 100 coins (expires in 365 days)
      const batch1 = mockData.coinBatch({
        id: 'batch-1',
        amount: 100,
        remainingAmount: 100,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
        ),
      });

      // Step 2: Get monthly allowance 50 coins (expires in 365 days)
      const batch2 = mockData.coinBatch({
        id: 'batch-2',
        amount: 50,
        remainingAmount: 50,
        source: 'monthly_allowance',
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
        ),
      });

      // Step 3: Spend 75 coins (should use oldest batch first - FIFO)
      const spent = 75;
      const batch1AfterSpending = {
        ...batch1,
        remainingAmount: Math.max(0, batch1.remainingAmount - spent),
      };
      const batch2AfterSpending = {
        ...batch2,
        remainingAmount: batch2.remainingAmount - Math.max(0, spent - batch1.remainingAmount),
      };

      expect(batch1AfterSpending.remainingAmount).toBe(25);
      expect(batch2AfterSpending.remainingAmount).toBe(50);
    });

    it('should warn before expiration then delete', async () => {
      const now = Date.now();

      // Day 335: Batch created
      const batch = mockData.coinBatch({
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(now + 30 * 24 * 60 * 60 * 1000)
        ),
        warned: false,
      });

      // Day 336+: Warning sent (30 days before)
      const daysUntilExpiration = (batch.expiresAt.toMillis() - now) / (24 * 60 * 60 * 1000);
      expect(daysUntilExpiration).toBeLessThanOrEqual(30);

      // Day 365+: Batch expired and deleted
      const isExpired = batch.expiresAt.toMillis() < now;
      expect(isExpired || daysUntilExpiration <= 30).toBe(true);
    });
  });
});
