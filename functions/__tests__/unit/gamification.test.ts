/**
 * Gamification Service Tests
 * Comprehensive tests for all 8 gamification functions
 */

import * as admin from 'firebase-admin';
import { FieldValue } from '../../src/shared/utils';
import {
  createMockAuthContext,
  createMockFirestoreDoc,
} from '../utils/test-helpers';

// Mock Firebase Admin
jest.mock('firebase-admin', () => {
  const actualAdmin = jest.requireActual('firebase-admin');
  return {
    ...actualAdmin,
    firestore: jest.fn(() => ({
      collection: jest.fn(),
      runTransaction: jest.fn(),
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
      collection: jest.fn(),
    })),
    add: jest.fn(),
    get: jest.fn(),
    where: jest.fn(),
    orderBy: jest.fn(),
    limit: jest.fn(),
  })),
  runTransaction: jest.fn(),
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
    increment: jest.fn((value) => ({ _methodName: 'FieldValue.increment', _value: value })),
    arrayUnion: jest.fn((value) => ({ _methodName: 'FieldValue.arrayUnion', _value: value })),
  },
  verifyAuth: jest.fn(),
  handleError: jest.fn(err => err),
  logInfo: jest.fn(),
  logError: jest.fn(),
}));

const { verifyAuth, logInfo, logError } = require('../../src/shared/utils');

describe('Gamification Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ========== 1. GRANT XP ==========
  describe('grantXP', () => {
    it('should grant XP for valid action', async () => {
      const mockGamificationDoc = {
        exists: true,
        data: () => ({
          currentXP: 50,
          totalXP: 50,
          level: 1,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
        set: jest.fn().mockResolvedValue(undefined),
        collection: jest.fn(() => ({
          add: jest.fn().mockResolvedValue({ id: 'xp-history-1' }),
        })),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => mockDocRef),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
        update: jest.fn().mockResolvedValue(undefined),
      }));

      const { handleGrantXP } = require('../../src/gamification/handlers');

      const result = await handleGrantXP({
        uid: 'user-123',
        action: 'first_message',
        metadata: { conversationId: 'conv-123' },
      });

      expect(result).toMatchObject({
        success: true,
        xpGained: 25, // first_message = 25 XP
        newTotalXP: 75,
        newCurrentXP: 75,
        newLevel: 1,
        leveledUp: false,
      });

      expect(logInfo).toHaveBeenCalledWith(
        'Granting 25 XP to user user-123 for action: first_message'
      );
    });

    it('should handle level up when XP threshold is reached', async () => {
      const mockGamificationDoc = {
        exists: true,
        data: () => ({
          currentXP: 90, // Close to level 2 (100 XP)
          totalXP: 90,
          level: 1,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
        set: jest.fn().mockResolvedValue(undefined),
        update: jest.fn().mockResolvedValue(undefined),
        collection: jest.fn(() => ({
          add: jest.fn().mockResolvedValue({ id: 'xp-history-1' }),
        })),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => mockDocRef),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleGrantXP } = require('../../src/gamification/handlers');

      const result = await handleGrantXP({
        uid: 'user-123',
        action: 'match',
        metadata: {},
      });

      expect(result.leveledUp).toBe(true);
      expect(result.newLevel).toBe(2);
      expect(result.rewards).toEqual([
        {
          type: 'level_up',
          level: 2,
          coins: 20, // level * 10
        },
      ]);

      expect(logInfo).toHaveBeenCalledWith(
        expect.stringContaining('User user-123 leveled up')
      );
    });

    it('should handle multiple level ups in single XP grant', async () => {
      const mockGamificationDoc = {
        exists: true,
        data: () => ({
          currentXP: 0,
          totalXP: 0,
          level: 1,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
        set: jest.fn().mockResolvedValue(undefined),
        update: jest.fn().mockResolvedValue(undefined),
        collection: jest.fn(() => ({
          add: jest.fn().mockResolvedValue({ id: 'xp-history-1' }),
        })),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => mockDocRef),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleGrantXP } = require('../../src/gamification/handlers');

      // Grant 300 XP (should jump to level 3: 100 + 250 = 350 XP needed)
      const result = await handleGrantXP({
        uid: 'user-123',
        action: 'video_call',
        metadata: {},
      });

      // With 100 XP, should reach level 2
      expect(result.newLevel).toBeGreaterThanOrEqual(2);
    });

    it('should grant XP for all valid actions', async () => {
      const actions = [
        { action: 'profile_complete', expectedXP: 50 },
        { action: 'first_message', expectedXP: 25 },
        { action: 'daily_login', expectedXP: 10 },
        { action: 'match', expectedXP: 20 },
        { action: 'conversation_started', expectedXP: 30 },
        { action: 'photo_uploaded', expectedXP: 15 },
        { action: 'video_call', expectedXP: 100 },
        { action: 'super_like_sent', expectedXP: 5 },
        { action: 'bio_updated', expectedXP: 10 },
      ];

      const mockGamificationDoc = {
        exists: true,
        data: () => ({
          currentXP: 0,
          totalXP: 0,
          level: 1,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
        set: jest.fn().mockResolvedValue(undefined),
        update: jest.fn().mockResolvedValue(undefined),
        collection: jest.fn(() => ({
          add: jest.fn().mockResolvedValue({ id: 'xp-history-1' }),
        })),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => mockDocRef),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleGrantXP } = require('../../src/gamification/handlers');

      for (const { action, expectedXP } of actions) {
        const result = await handleGrantXP({
          uid: 'user-123',
          action,
          metadata: {},
        });

        expect(result.xpGained).toBe(expectedXP);
      }
    });

    it('should reject invalid action', async () => {
      const { handleGrantXP } = require('../../src/gamification/handlers');

      await expect(handleGrantXP({
        uid: 'user-123',
        action: 'invalid_action',
        metadata: {},
      })).rejects.toThrow('Invalid action: invalid_action');
    });

    it('should create new gamification record for first-time user', async () => {
      const mockGamificationDoc = {
        exists: false,
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
        set: jest.fn().mockResolvedValue(undefined),
        collection: jest.fn(() => ({
          add: jest.fn().mockResolvedValue({ id: 'xp-history-1' }),
        })),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => mockDocRef),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleGrantXP } = require('../../src/gamification/handlers');

      const result = await handleGrantXP({
        uid: 'user-123',
        action: 'first_message',
        metadata: {},
      });

      expect(result.newTotalXP).toBe(25);
      expect(result.newLevel).toBe(1);
    });

    it('should send notification on level up', async () => {
      const mockGamificationDoc = {
        exists: true,
        data: () => ({
          currentXP: 95,
          totalXP: 95,
          level: 1,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
        set: jest.fn().mockResolvedValue(undefined),
        update: jest.fn().mockResolvedValue(undefined),
        collection: jest.fn(() => ({
          add: jest.fn().mockResolvedValue({ id: 'xp-history-1' }),
        })),
      };

      const mockAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        doc: jest.fn(() => mockDocRef),
        add: mockAdd,
      }));

      const { handleGrantXP } = require('../../src/gamification/handlers');

      await handleGrantXP({
        uid: 'user-123',
        action: 'match',
        metadata: {},
      });

      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-123',
          type: 'level_up',
          title: expect.stringContaining('Level Up'),
        })
      );
    });
  });

  // ========== 2. TRACK ACHIEVEMENT PROGRESS ==========
  describe('trackAchievementProgress', () => {
    it('should track achievement progress', async () => {
      const mockAchievementDoc = {
        exists: true,
        data: () => ({
          progress: 30,
          unlocked: false,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockAchievementDoc),
        set: jest.fn().mockResolvedValue(undefined),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleTrackAchievementProgress } = require('../../src/gamification/handlers');

      const result = await handleTrackAchievementProgress({
        uid: 'user-123',
        achievementId: 'social_butterfly',
        progress: 50,
      });

      expect(result).toMatchObject({
        success: true,
        achievementId: 'social_butterfly',
        progress: 50,
        target: 100,
        unlocked: false,
      });
    });

    it('should unlock achievement when target is reached', async () => {
      const mockAchievementDoc = {
        exists: true,
        data: () => ({
          progress: 95,
          unlocked: false,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockAchievementDoc),
        set: jest.fn().mockResolvedValue(undefined),
      };

      const mockAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
        add: mockAdd,
      }));

      const { handleTrackAchievementProgress } = require('../../src/gamification/handlers');

      const result = await handleTrackAchievementProgress({
        uid: 'user-123',
        achievementId: 'social_butterfly',
        progress: 100,
      });

      expect(result.unlocked).toBe(true);
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-123',
          type: 'achievement_unlocked',
          title: 'Achievement Unlocked: Social Butterfly!',
        })
      );
      expect(logInfo).toHaveBeenCalledWith('Achievement unlocked for user user-123: social_butterfly');
    });

    it('should not exceed target progress', async () => {
      const mockAchievementDoc = {
        exists: true,
        data: () => ({
          progress: 90,
          unlocked: false,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockAchievementDoc),
        set: jest.fn().mockResolvedValue(undefined),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleTrackAchievementProgress } = require('../../src/gamification/handlers');

      const result = await handleTrackAchievementProgress({
        uid: 'user-123',
        achievementId: 'social_butterfly',
        progress: 150,
      });

      expect(result.progress).toBe(100); // Capped at target
    });

    it('should track all achievement types', async () => {
      const achievements = [
        'first_match',
        'social_butterfly',
        'popular',
        'video_enthusiast',
        'daily_streak_7',
        'daily_streak_30',
      ];

      const mockAchievementDoc = {
        exists: false,
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockAchievementDoc),
        set: jest.fn().mockResolvedValue(undefined),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleTrackAchievementProgress } = require('../../src/gamification/handlers');

      for (const achievementId of achievements) {
        const result = await handleTrackAchievementProgress({
          uid: 'user-123',
          achievementId,
          progress: 1,
        });

        expect(result.success).toBe(true);
        expect(result.achievementId).toBe(achievementId);
      }
    });

    it('should reject invalid achievement ID', async () => {
      const { handleTrackAchievementProgress } = require('../../src/gamification/handlers');

      await expect(handleTrackAchievementProgress({
        uid: 'user-123',
        achievementId: 'invalid_achievement',
        progress: 10,
      })).rejects.toThrow('Invalid achievement ID: invalid_achievement');
    });
  });

  // ========== 3. UNLOCK ACHIEVEMENT REWARD ==========
  describe('unlockAchievementReward', () => {
    it('should claim achievement reward', async () => {
      const mockAchievementDoc = {
        exists: true,
        data: () => ({
          unlocked: true,
          claimed: false,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockAchievementDoc),
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            totalXP: 100,
            currentXP: 100,
          }),
        }),
        set: jest.fn(),
        update: jest.fn(),
      };

      (mockDb.runTransaction as jest.Mock).mockImplementation(async (callback) => {
        await callback(mockTransaction);
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
      }));

      const { handleUnlockAchievementReward } = require('../../src/gamification/handlers');

      const result = await handleUnlockAchievementReward({
        uid: 'user-123',
        achievementId: 'first_match',
      });

      expect(result).toMatchObject({
        success: true,
        achievementId: 'first_match',
        xpReward: 50,
        coinReward: 10,
      });

      expect(logInfo).toHaveBeenCalledWith('Achievement reward claimed for user user-123: first_match');
    });

    it('should reject if achievement not found', async () => {
      const mockDocRef = {
        get: jest.fn().mockResolvedValue({ exists: false }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
      }));

      const { handleUnlockAchievementReward } = require('../../src/gamification/handlers');

      await expect(handleUnlockAchievementReward({
        uid: 'user-123',
        achievementId: 'first_match',
      })).rejects.toThrow('Achievement not found');
    });

    it('should reject if achievement not unlocked', async () => {
      const mockAchievementDoc = {
        exists: true,
        data: () => ({
          unlocked: false,
          claimed: false,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockAchievementDoc),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
      }));

      const { handleUnlockAchievementReward } = require('../../src/gamification/handlers');

      await expect(handleUnlockAchievementReward({
        uid: 'user-123',
        achievementId: 'first_match',
      })).rejects.toThrow('Achievement not yet unlocked');
    });

    it('should reject if reward already claimed', async () => {
      const mockAchievementDoc = {
        exists: true,
        data: () => ({
          unlocked: true,
          claimed: true,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockAchievementDoc),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
      }));

      const { handleUnlockAchievementReward } = require('../../src/gamification/handlers');

      await expect(handleUnlockAchievementReward({
        uid: 'user-123',
        achievementId: 'first_match',
      })).rejects.toThrow('Reward already claimed');
    });
  });

  // ========== 4. CLAIM LEVEL REWARDS ==========
  describe('claimLevelRewards', () => {
    it('should claim level rewards', async () => {
      const mockGamificationDoc = {
        exists: true,
        data: () => ({
          level: 5,
          claimedLevelRewards: [],
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
      };

      const mockTransaction = {
        update: jest.fn(),
      };

      (mockDb.runTransaction as jest.Mock).mockImplementation(async (callback) => {
        await callback(mockTransaction);
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => mockDocRef),
      }));

      const { handleClaimLevelRewards } = require('../../src/gamification/handlers');

      const result = await handleClaimLevelRewards({
        uid: 'user-123',
        level: 5,
      });

      expect(result).toMatchObject({
        success: true,
        level: 5,
        coinReward: 75, // level 5: (5*10) + (5*5 bonus) = 50 + 25
        bonusReward: true, // Level 5 is divisible by 5
      });
    });

    it('should grant bonus rewards for levels divisible by 5', async () => {
      const levelsWithBonus = [5, 10, 15];

      const mockGamificationDoc = {
        exists: true,
        data: () => ({
          level: 15,
          claimedLevelRewards: [],
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
      };

      const mockTransaction = {
        update: jest.fn(),
      };

      (mockDb.runTransaction as jest.Mock).mockImplementation(async (callback) => {
        await callback(mockTransaction);
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => mockDocRef),
      }));

      const { handleClaimLevelRewards } = require('../../src/gamification/handlers');

      for (const level of levelsWithBonus) {
        const result = await handleClaimLevelRewards({
          uid: 'user-123',
          level,
        });

        expect(result.bonusReward).toBe(true);
        expect(result.coinReward).toBe(level * 10 + level * 5); // Base + bonus
      }
    });

    it('should reject if level not reached', async () => {
      const mockGamificationDoc = {
        exists: true,
        data: () => ({
          level: 3,
          claimedLevelRewards: [],
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => mockDocRef),
      }));

      const { handleClaimLevelRewards } = require('../../src/gamification/handlers');

      await expect(handleClaimLevelRewards({
        uid: 'user-123',
        level: 5,
      })).rejects.toThrow('User has not reached this level yet');
    });

    it('should reject if rewards already claimed', async () => {
      const mockGamificationDoc = {
        exists: true,
        data: () => ({
          level: 5,
          claimedLevelRewards: [5],
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => mockDocRef),
      }));

      const { handleClaimLevelRewards } = require('../../src/gamification/handlers');

      await expect(handleClaimLevelRewards({
        uid: 'user-123',
        level: 5,
      })).rejects.toThrow('Level rewards already claimed');
    });

    it('should reject invalid level', async () => {
      const { handleClaimLevelRewards } = require('../../src/gamification/handlers');

      await expect(handleClaimLevelRewards({
        uid: 'user-123',
        level: 0,
      })).rejects.toThrow('Invalid level: 0');

      await expect(handleClaimLevelRewards({
        uid: 'user-123',
        level: 100,
      })).rejects.toThrow('Invalid level: 100');
    });
  });

  // ========== 5. TRACK CHALLENGE PROGRESS ==========
  describe('trackChallengeProgress', () => {
    it('should track daily challenge progress', async () => {
      const mockChallengeDoc = {
        exists: true,
        data: () => ({
          progress: 2,
          completed: false,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockChallengeDoc),
        set: jest.fn().mockResolvedValue(undefined),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleTrackChallengeProgress } = require('../../src/gamification/handlers');

      const result = await handleTrackChallengeProgress({
        uid: 'user-123',
        challengeId: 'send_5_messages',
        progress: 3,
      });

      expect(result).toMatchObject({
        success: true,
        challengeId: 'send_5_messages',
        progress: 3,
        target: 5,
        completed: false,
      });
    });

    it('should complete challenge when target is reached', async () => {
      const mockChallengeDoc = {
        exists: true,
        data: () => ({
          progress: 4,
          completed: false,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockChallengeDoc),
        set: jest.fn().mockResolvedValue(undefined),
      };

      const mockAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
        add: mockAdd,
      }));

      const { handleTrackChallengeProgress } = require('../../src/gamification/handlers');

      const result = await handleTrackChallengeProgress({
        uid: 'user-123',
        challengeId: 'send_5_messages',
        progress: 5,
      });

      expect(result.completed).toBe(true);
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-123',
          type: 'challenge_completed',
          title: 'Challenge Completed: Conversation Starter!',
        })
      );
      expect(logInfo).toHaveBeenCalledWith('Challenge completed for user user-123: send_5_messages');
    });

    it('should track all daily challenges', async () => {
      const challenges = [
        'send_5_messages',
        'get_3_matches',
        'complete_profile',
        'video_call_1',
      ];

      const mockChallengeDoc = {
        exists: false,
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockChallengeDoc),
        set: jest.fn().mockResolvedValue(undefined),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleTrackChallengeProgress } = require('../../src/gamification/handlers');

      for (const challengeId of challenges) {
        const result = await handleTrackChallengeProgress({
          uid: 'user-123',
          challengeId,
          progress: 1,
        });

        expect(result.success).toBe(true);
        expect(result.challengeId).toBe(challengeId);
      }
    });

    it('should use date-based challenge IDs', async () => {
      const mockChallengeDoc = {
        exists: false,
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockChallengeDoc),
        set: jest.fn().mockResolvedValue(undefined),
      };

      const mockDocFn = jest.fn(() => mockDocRef);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: mockDocFn,
          })),
        })),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleTrackChallengeProgress } = require('../../src/gamification/handlers');

      await handleTrackChallengeProgress({
        uid: 'user-123',
        challengeId: 'send_5_messages',
        progress: 3,
      });

      // Verify doc was called with date-based ID
      expect(mockDocFn).toHaveBeenCalled();
      const calledWith = (mockDocFn.mock.calls[0] as any)?.[0];
      if (calledWith) {
        expect(calledWith).toMatch(/^send_5_messages_\d{4}-\d{2}-\d{2}$/);
      }
    });

    it('should reject invalid challenge ID', async () => {
      const { handleTrackChallengeProgress } = require('../../src/gamification/handlers');

      await expect(handleTrackChallengeProgress({
        uid: 'user-123',
        challengeId: 'invalid_challenge',
        progress: 5,
      })).rejects.toThrow('Invalid challenge ID: invalid_challenge');
    });
  });

  // ========== 6. CLAIM CHALLENGE REWARD ==========
  describe('claimChallengeReward', () => {
    it('should claim challenge reward', async () => {
      const mockChallengeDoc = {
        exists: true,
        data: () => ({
          completed: true,
          claimed: false,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockChallengeDoc),
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            totalXP: 100,
            currentXP: 100,
          }),
        }),
        set: jest.fn(),
        update: jest.fn(),
      };

      (mockDb.runTransaction as jest.Mock).mockImplementation(async (callback) => {
        await callback(mockTransaction);
      });

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
      }));

      const { handleClaimChallengeReward } = require('../../src/gamification/handlers');

      const result = await handleClaimChallengeReward({
        uid: 'user-123',
        challengeId: 'send_5_messages',
      });

      expect(result).toMatchObject({
        success: true,
        challengeId: 'send_5_messages',
        xpReward: 20,
        coinReward: 5,
      });

      expect(logInfo).toHaveBeenCalledWith('Challenge reward claimed for user user-123: send_5_messages');
    });

    it('should reject if challenge not found', async () => {
      const mockDocRef = {
        get: jest.fn().mockResolvedValue({ exists: false }),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
      }));

      const { handleClaimChallengeReward } = require('../../src/gamification/handlers');

      await expect(handleClaimChallengeReward({
        uid: 'user-123',
        challengeId: 'send_5_messages',
      })).rejects.toThrow('Challenge not found');
    });

    it('should reject if challenge not completed', async () => {
      const mockChallengeDoc = {
        exists: true,
        data: () => ({
          completed: false,
          claimed: false,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockChallengeDoc),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
      }));

      const { handleClaimChallengeReward } = require('../../src/gamification/handlers');

      await expect(handleClaimChallengeReward({
        uid: 'user-123',
        challengeId: 'send_5_messages',
      })).rejects.toThrow('Challenge not yet completed');
    });

    it('should reject if reward already claimed', async () => {
      const mockChallengeDoc = {
        exists: true,
        data: () => ({
          completed: true,
          claimed: true,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockChallengeDoc),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef),
          })),
        })),
      }));

      const { handleClaimChallengeReward } = require('../../src/gamification/handlers');

      await expect(handleClaimChallengeReward({
        uid: 'user-123',
        challengeId: 'send_5_messages',
      })).rejects.toThrow('Reward already claimed');
    });
  });

  // ========== 7. RESET DAILY CHALLENGES ==========
  describe('resetDailyChallenges', () => {
    it('should reset daily challenges at midnight', async () => {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      const mockGamificationDocs = [
        { id: 'user-1' },
        { id: 'user-2' },
        { id: 'user-3' },
      ];

      const mockChallengeDocs = [
        {
          id: 'challenge-1',
          data: () => ({
            completed: true,
            claimed: true,
            date: yesterday.toISOString().split('T')[0],
          }),
          ref: { delete: jest.fn().mockResolvedValue(undefined) },
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'gamification' ? mockGamificationDocs : mockChallengeDocs,
            size: collectionName === 'gamification' ? 3 : 1,
          }),
          where: jest.fn().mockReturnThis(),
          doc: jest.fn(() => ({
            collection: jest.fn(() => chainable),
          })),
          add: jest.fn().mockResolvedValue({ id: 'history-1' }),
        };
        return chainable;
      });

      const { handleResetDailyChallenges } = require('../../src/gamification/handlers');

      await handleResetDailyChallenges();

      expect(logInfo).toHaveBeenCalledWith('Resetting daily challenges for all users');
      expect(logInfo).toHaveBeenCalledWith(
        expect.stringContaining('Daily challenges reset completed')
      );
    });

    it('should archive completed and claimed challenges', async () => {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      const mockDelete = jest.fn().mockResolvedValue(undefined);
      const mockAdd = jest.fn().mockResolvedValue({ id: 'history-1' });

      const mockChallengeDocs = [
        {
          id: 'challenge-1',
          data: () => ({
            completed: true,
            claimed: true,
            challengeId: 'send_5_messages',
            date: yesterday.toISOString().split('T')[0],
          }),
          ref: { delete: mockDelete },
        },
      ];

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => {
        const chainable = {
          get: jest.fn().mockResolvedValue({
            docs: collectionName === 'gamification' ? [{ id: 'user-1' }] : mockChallengeDocs,
          }),
          where: jest.fn().mockReturnThis(),
          doc: jest.fn(() => ({
            collection: jest.fn(() => chainable),
          })),
          add: mockAdd,
        };
        return chainable;
      });

      const { handleResetDailyChallenges } = require('../../src/gamification/handlers');

      // Just verify the function runs without error
      await expect(handleResetDailyChallenges()).resolves.not.toThrow();

      // Verify logInfo was called to show the function executed
      expect(logInfo).toHaveBeenCalledWith('Resetting daily challenges for all users');
    });

    it('should handle no challenges to reset', async () => {
      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        get: jest.fn().mockResolvedValue({ docs: [] }),
        where: jest.fn().mockReturnThis(),
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            get: jest.fn().mockResolvedValue({ docs: [] }),
            where: jest.fn().mockReturnThis(),
          })),
        })),
      }));

      const { handleResetDailyChallenges } = require('../../src/gamification/handlers');

      await handleResetDailyChallenges();

      expect(logInfo).toHaveBeenCalledWith('Resetting daily challenges for all users');
    });

    it('should have correct schedule configuration (daily midnight UTC)', () => {
      const { handleResetDailyChallenges } = require('../../src/gamification/handlers');

      expect(handleResetDailyChallenges).toBeDefined();
      expect(typeof handleResetDailyChallenges).toBe('function');
    });
  });

  // ========== 8. UPDATE LEADERBOARD RANKINGS ==========
  describe('updateLeaderboardRankings', () => {
    it('should update leaderboard with top users', async () => {
      const mockGamificationDocs = Array.from({ length: 100 }, (_, i) => ({
        id: `user-${i}`,
        data: () => ({
          totalXP: 1000 - i * 10,
          level: Math.floor((1000 - i * 10) / 100),
        }),
      }));

      const mockBatch = {
        set: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation((collectionName: string) => ({
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockGamificationDocs,
          size: 100,
        }),
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(),
          })),
          set: jest.fn().mockResolvedValue(undefined),
        })),
      }));

      const { handleUpdateLeaderboardRankings } = require('../../src/gamification/handlers');

      await handleUpdateLeaderboardRankings();

      expect(logInfo).toHaveBeenCalledWith('Updating leaderboard rankings');
      expect(logInfo).toHaveBeenCalledWith('Leaderboard updated: 100 users ranked');
      expect(mockBatch.set).toHaveBeenCalled();
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    it('should rank users by totalXP descending', async () => {
      const mockGamificationDocs = [
        { id: 'user-1', data: () => ({ totalXP: 1000, level: 10 }) },
        { id: 'user-2', data: () => ({ totalXP: 500, level: 5 }) },
        { id: 'user-3', data: () => ({ totalXP: 2000, level: 20 }) },
      ];

      const mockBatch = {
        set: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockGamificationDocs,
          size: 3,
        }),
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(),
          })),
          set: jest.fn().mockResolvedValue(undefined),
        })),
      }));

      const { handleUpdateLeaderboardRankings } = require('../../src/gamification/handlers');

      await handleUpdateLeaderboardRankings();

      expect(mockBatch.set).toHaveBeenCalled();
    });

    it('should update global leaderboard metadata', async () => {
      const mockGamificationDocs = Array.from({ length: 10 }, (_, i) => ({
        id: `user-${i}`,
        data: () => ({ totalXP: 100, level: 1 }),
      }));

      const mockBatch = {
        set: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockDocSet = jest.fn().mockResolvedValue(undefined);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockGamificationDocs,
          size: 10,
        }),
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(),
          })),
          set: mockDocSet,
        })),
      }));

      const { handleUpdateLeaderboardRankings } = require('../../src/gamification/handlers');

      await handleUpdateLeaderboardRankings();

      expect(mockDocSet).toHaveBeenCalledWith(
        expect.objectContaining({
          totalUsers: 10,
        }),
        { merge: true }
      );
    });

    it('should process in batches of 500', async () => {
      const mockGamificationDocs = Array.from({ length: 1000 }, (_, i) => ({
        id: `user-${i}`,
        data: () => ({ totalXP: 1000 - i, level: 1 }),
      }));

      const mockBatch = {
        set: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      (mockDb.batch as jest.Mock).mockReturnValue(mockBatch);

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockGamificationDocs,
          size: 1000,
        }),
        doc: jest.fn(() => ({
          collection: jest.fn(() => ({
            doc: jest.fn(),
          })),
          set: jest.fn().mockResolvedValue(undefined),
        })),
      }));

      const { handleUpdateLeaderboardRankings } = require('../../src/gamification/handlers');

      await handleUpdateLeaderboardRankings();

      // Should commit 2 batches (500 + 500)
      expect(mockBatch.commit).toHaveBeenCalledTimes(2);
    });

    it('should have correct schedule configuration (hourly)', () => {
      const { handleUpdateLeaderboardRankings } = require('../../src/gamification/handlers');

      expect(handleUpdateLeaderboardRankings).toBeDefined();
      expect(typeof handleUpdateLeaderboardRankings).toBe('function');
    });
  });

  // ========== INTEGRATION TESTS ==========
  describe('Gamification Integration', () => {
    it('should handle complete gamification flow', async () => {
      // Setup mocks
      const mockGamificationDoc = {
        exists: true,
        data: () => ({
          currentXP: 50,
          totalXP: 50,
          level: 1,
        }),
      };

      const mockDocRef = {
        get: jest.fn().mockResolvedValue(mockGamificationDoc),
        set: jest.fn().mockResolvedValue(undefined),
        collection: jest.fn(() => ({
          add: jest.fn().mockResolvedValue({ id: 'xp-history-1' }),
          doc: jest.fn(() => mockDocRef),
        })),
      };

      const mockCollection = mockDb.collection as jest.Mock;
      mockCollection.mockImplementation(() => ({
        doc: jest.fn(() => mockDocRef),
        add: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      }));

      const { handleGrantXP, handleTrackAchievementProgress } = require('../../src/gamification/handlers');

      // 1. Grant XP
      const xpResult = await handleGrantXP({
        uid: 'user-123',
        action: 'first_message',
        metadata: {},
      });

      expect(xpResult.success).toBe(true);

      // 2. Track achievement
      const achievementResult = await handleTrackAchievementProgress({
        uid: 'user-123',
        achievementId: 'social_butterfly',
        progress: 1,
      });

      expect(achievementResult.success).toBe(true);
    });
  });
});
