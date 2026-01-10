/**
 * Video Calling Service Unit Tests
 * Tests for 21 video calling functions with Agora.io integration
 */

import { describe, it, expect, jest, beforeEach, afterEach } from '@jest/globals';
import * as admin from 'firebase-admin';

// Mock Agora Token Builder
const mockRtcTokenBuilder = {
  buildTokenWithUid: jest.fn(),
};

const RtcRole = {
  PUBLISHER: 1,
  SUBSCRIBER: 2,
};

jest.mock('agora-access-token', () => ({
  RtcTokenBuilder: mockRtcTokenBuilder,
  RtcRole,
}));

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  firestore: {
    FieldValue: {
      serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
      increment: jest.fn((n) => `INCREMENT_${n}`),
      arrayUnion: jest.fn((...items) => ({ arrayUnion: items })),
    },
    Timestamp: {
      fromDate: jest.fn((date) => ({ toMillis: () => date.getTime(), toDate: () => date })),
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
  handleError: jest.fn((error) => error),
  logInfo: jest.fn(),
  logError: jest.fn(),
  db: mockDb,
  FieldValue: {
    serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
    increment: jest.fn((n) => `INCREMENT_${n}`),
    arrayUnion: jest.fn((...items) => ({ arrayUnion: items })),
  },
}));

// Mock shared types
jest.mock('../../src/shared/types', () => ({
  CallStatus: {
    RINGING: 'ringing',
    ACTIVE: 'active',
    ENDED: 'ended',
    REJECTED: 'rejected',
    MISSED: 'missed',
    SCHEDULED: 'scheduled',
  },
  CallType: {
    VOICE: 'voice',
    VIDEO: 'video',
    GROUP: 'group',
  },
}));

// Set environment variables
process.env.AGORA_APP_ID = 'test-app-id';
process.env.AGORA_APP_CERTIFICATE = 'test-certificate';

// Import after mocks
import {
  generateAgoraToken,
  initiateCall,
  answerCall,
  rejectCall,
  endCall,
  startCallRecording,
  muteParticipant,
  toggleVideo,
  shareScreen,
  sendCallReaction,
  createGroupCall,
  joinGroupCall,
  inviteToGroupCall,
  removeFromGroupCall,
  getCallHistory,
  getCallAnalytics,
  onCallStarted,
  onCallEnded,
  cleanupMissedCalls,
  cleanupAbandonedCalls,
  archiveOldCallRecords,
} from '../../src/video';

const { verifyAuth } = require('../../src/shared/utils');
const { CallStatus, CallType } = require('../../src/shared/types');

describe('Video Calling Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (verifyAuth as jest.Mock).mockResolvedValue('user-123');
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  // ========== 1. GENERATE AGORA TOKEN ==========

  describe('generateAgoraToken', () => {
    it('should generate Agora token successfully', async () => {
      mockRtcTokenBuilder.buildTokenWithUid.mockReturnValue('test-agora-token');

      const request = {
        auth: { uid: 'user-123' },
        data: {
          channelName: 'call_channel_123',
          uid: 123456,
          role: 'publisher',
        },
      };

      // @ts-ignore
      const result = await generateAgoraToken(request);

      expect(mockRtcTokenBuilder.buildTokenWithUid).toHaveBeenCalledWith(
        'test-app-id',
        'test-certificate',
        'call_channel_123',
        123456,
        RtcRole.PUBLISHER,
        expect.any(Number)
      );

      expect(result.success).toBe(true);
      expect(result.token).toBe('test-agora-token');
      expect(result.appId).toBe('test-app-id');
      expect(result.channelName).toBe('call_channel_123');
      expect(result.uid).toBe(123456);
      expect(result.expiresAt).toBeGreaterThan(Date.now() / 1000);
    });

    it('should use subscriber role when specified', async () => {
      mockRtcTokenBuilder.buildTokenWithUid.mockReturnValue('test-token');

      const request = {
        auth: { uid: 'user-123' },
        data: {
          channelName: 'channel_456',
          uid: 456789,
          role: 'subscriber',
        },
      };

      // @ts-ignore
      await generateAgoraToken(request);

      expect(mockRtcTokenBuilder.buildTokenWithUid).toHaveBeenCalledWith(
        expect.any(String),
        expect.any(String),
        expect.any(String),
        expect.any(Number),
        RtcRole.SUBSCRIBER,
        expect.any(Number)
      );
    });

    it('should require authentication', async () => {
      (verifyAuth as jest.Mock).mockRejectedValue(new Error('Unauthorized'));

      const request = {
        auth: null,
        data: {
          channelName: 'channel',
          uid: 123,
        },
      };

      // @ts-ignore
      await expect(generateAgoraToken(request)).rejects.toThrow('Unauthorized');
    });
  });

  // ========== 2. INITIATE CALL ==========

  describe('initiateCall', () => {
    it('should initiate a call successfully', async () => {
      const mockRecipientGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ name: 'Recipient User' }),
      });

      const mockBlocksGet = jest.fn().mockResolvedValue({
        empty: true,
      });

      const mockCallAdd = jest.fn().mockResolvedValue({ id: 'call-123' });
      const mockNotificationAdd = jest.fn().mockResolvedValue({ id: 'notif-123' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'users') {
          return {
            doc: jest.fn().mockReturnValue({
              get: mockRecipientGet,
            }),
          };
        }
        if (collName === 'blocks') {
          return {
            where: jest.fn().mockReturnThis(),
            get: mockBlocksGet,
          };
        }
        if (collName === 'calls') {
          return { add: mockCallAdd };
        }
        if (collName === 'notifications') {
          return { add: mockNotificationAdd };
        }
        return {};
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          recipientId: 'user-456',
          callType: CallType.VIDEO,
          videoEnabled: true,
        },
      };

      // @ts-ignore
      const result = await initiateCall(request);

      expect(result.success).toBe(true);
      expect(result.callId).toBe('call-123');
      expect(result.channelName).toContain('call_user-123_user-456');
      expect(mockCallAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          callerId: 'user-123',
          recipientId: 'user-456',
          callType: CallType.VIDEO,
          status: CallStatus.RINGING,
        })
      );
      expect(mockNotificationAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-456',
          type: 'incoming_call',
        })
      );
    });

    it('should reject if recipient not found', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({ exists: false }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          recipientId: 'nonexistent',
          callType: CallType.VIDEO,
        },
      };

      // @ts-ignore
      await expect(initiateCall(request)).rejects.toThrow('Recipient not found');
    });

    it('should reject if users are blocked', async () => {
      const mockRecipientGet = jest.fn().mockResolvedValue({
        exists: true,
      });

      const mockBlocksGet = jest.fn().mockResolvedValue({
        empty: false,
        docs: [{ id: 'block-1' }],
      });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'users') {
          return {
            doc: jest.fn().mockReturnValue({ get: mockRecipientGet }),
          };
        }
        if (collName === 'blocks') {
          return {
            where: jest.fn().mockReturnThis(),
            get: mockBlocksGet,
          };
        }
        return {};
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          recipientId: 'user-456',
          callType: CallType.VIDEO,
        },
      };

      // @ts-ignore
      await expect(initiateCall(request)).rejects.toThrow('Cannot call this user');
    });
  });

  // ========== 3. ANSWER CALL ==========

  describe('answerCall', () => {
    it('should answer a call successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          recipientId: 'user-123',
          status: CallStatus.RINGING,
          channelName: 'call_channel',
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      const result = await answerCall(request);

      expect(result.success).toBe(true);
      expect(result.callId).toBe('call-123');
      expect(result.channelName).toBe('call_channel');
      expect(result.agoraUid).toBeDefined();
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: CallStatus.ACTIVE,
          startedAt: 'SERVER_TIMESTAMP',
        })
      );
    });

    it('should reject if call not found', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({ exists: false }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'nonexistent' },
      };

      // @ts-ignore
      await expect(answerCall(request)).rejects.toThrow('Call not found');
    });

    it('should reject if not authorized', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              recipientId: 'other-user',
              status: CallStatus.RINGING,
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      await expect(answerCall(request)).rejects.toThrow('Not authorized');
    });

    it('should reject if call not in ringing state', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              recipientId: 'user-123',
              status: CallStatus.ACTIVE,
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      await expect(answerCall(request)).rejects.toThrow('not in ringing state');
    });
  });

  // ========== 4. REJECT CALL ==========

  describe('rejectCall', () => {
    it('should reject a call successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          recipientId: 'user-123',
          callerId: 'user-456',
        }),
      });
      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'calls') {
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
        return {};
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      const result = await rejectCall(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: CallStatus.REJECTED,
          endedAt: 'SERVER_TIMESTAMP',
        })
      );
      expect(mockNotifAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-456',
          type: 'call_rejected',
        })
      );
    });
  });

  // ========== 5. END CALL ==========

  describe('endCall', () => {
    it('should end a call successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          participants: [
            { userId: 'user-123', leftAt: null },
            { userId: 'user-456', leftAt: 'TIMESTAMP' },
          ],
          startedAt: { toMillis: () => Date.now() - 60000 },
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      const result = await endCall(request);

      expect(result.success).toBe(true);
      expect(result.allEnded).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: CallStatus.ENDED,
          duration: expect.any(Number),
        })
      );
    });

    it('should not end call if other participants still active', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          participants: [
            { userId: 'user-123', leftAt: null },
            { userId: 'user-456', leftAt: null },
          ],
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      const result = await endCall(request);

      expect(result.success).toBe(true);
      expect(result.allEnded).toBe(false);
    });
  });

  // ========== 6. START CALL RECORDING ==========

  describe('startCallRecording', () => {
    it('should start recording successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          participants: [{ userId: 'user-123' }],
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          enabled: true,
        },
      };

      // @ts-ignore
      const result = await startCallRecording(request);

      expect(result.success).toBe(true);
      expect(result.recording).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          recordingEnabled: true,
          recordingStartedBy: 'user-123',
        })
      );
    });

    it('should stop recording successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          participants: [{ userId: 'user-123' }],
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          enabled: false,
        },
      };

      // @ts-ignore
      const result = await startCallRecording(request);

      expect(result.recording).toBe(false);
    });

    it('should reject if not a participant', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              participants: [{ userId: 'other-user' }],
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          enabled: true,
        },
      };

      // @ts-ignore
      await expect(startCallRecording(request)).rejects.toThrow('Not authorized');
    });
  });

  // ========== 7. MUTE PARTICIPANT ==========

  describe('muteParticipant', () => {
    it('should mute own audio successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          participants: [{ userId: 'user-123', muted: false }],
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          participantId: 'user-123',
          muted: true,
        },
      };

      // @ts-ignore
      const result = await muteParticipant(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalled();
    });

    it('should allow host to mute other participants', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          hostId: 'user-123',
          participants: [
            { userId: 'user-123' },
            { userId: 'user-456', muted: false },
          ],
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          participantId: 'user-456',
          muted: true,
        },
      };

      // @ts-ignore
      const result = await muteParticipant(request);

      expect(result.success).toBe(true);
    });

    it('should reject if not host trying to mute others', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              hostId: 'other-user',
              participants: [
                { userId: 'user-123' },
                { userId: 'user-456' },
              ],
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          participantId: 'user-456',
          muted: true,
        },
      };

      // @ts-ignore
      await expect(muteParticipant(request)).rejects.toThrow('Not authorized');
    });
  });

  // ========== 8. TOGGLE VIDEO ==========

  describe('toggleVideo', () => {
    it('should toggle video on successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          participants: [{ userId: 'user-123', videoEnabled: false }],
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          enabled: true,
        },
      };

      // @ts-ignore
      const result = await toggleVideo(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalled();
    });

    it('should toggle video off successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          participants: [{ userId: 'user-123', videoEnabled: true }],
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          enabled: false,
        },
      };

      // @ts-ignore
      const result = await toggleVideo(request);

      expect(result.success).toBe(true);
    });
  });

  // ========== 9. SHARE SCREEN ==========

  describe('shareScreen', () => {
    it('should start screen sharing successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({}),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          enabled: true,
        },
      };

      // @ts-ignore
      const result = await shareScreen(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          screenSharing: true,
          screenSharingBy: 'user-123',
        })
      );
    });

    it('should stop screen sharing successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({}),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          enabled: false,
        },
      };

      // @ts-ignore
      const result = await shareScreen(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          screenSharing: false,
          screenSharingBy: null,
        })
      );
    });
  });

  // ========== 10. SEND CALL REACTION ==========

  describe('sendCallReaction', () => {
    it('should send call reaction successfully', async () => {
      const mockReactionAdd = jest.fn().mockResolvedValue({ id: 'reaction-1' });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          collection: jest.fn().mockReturnValue({
            add: mockReactionAdd,
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          reaction: '👍',
        },
      };

      // @ts-ignore
      const result = await sendCallReaction(request);

      expect(result.success).toBe(true);
      expect(mockReactionAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-123',
          reaction: '👍',
        })
      );
    });
  });

  // ========== 11. CREATE GROUP CALL ==========

  describe('createGroupCall', () => {
    it('should create a group call successfully', async () => {
      const mockCallAdd = jest.fn().mockResolvedValue({ id: 'group-call-123' });
      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'calls') {
          return { add: mockCallAdd };
        }
        if (collName === 'notifications') {
          return { add: mockNotifAdd };
        }
        return {};
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          participantIds: ['user-456', 'user-789'],
          title: 'Team Meeting',
        },
      };

      // @ts-ignore
      const result = await createGroupCall(request);

      expect(result.success).toBe(true);
      expect(result.callId).toBe('group-call-123');
      expect(result.channelName).toContain('group_user-123');
      expect(mockCallAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          hostId: 'user-123',
          callType: CallType.GROUP,
          title: 'Team Meeting',
          invitedParticipants: ['user-456', 'user-789'],
        })
      );
      expect(mockNotifAdd).toHaveBeenCalledTimes(2);
    });

    it('should reject if participant limit exceeded', async () => {
      const tooManyParticipants = Array(51).fill('user-id');

      const request = {
        auth: { uid: 'user-123' },
        data: {
          participantIds: tooManyParticipants,
        },
      };

      // @ts-ignore
      await expect(createGroupCall(request)).rejects.toThrow('Maximum');
    });

    it('should create scheduled group call', async () => {
      const mockCallAdd = jest.fn().mockResolvedValue({ id: 'scheduled-call' });
      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'calls') {
          return { add: mockCallAdd };
        }
        if (collName === 'notifications') {
          return { add: mockNotifAdd };
        }
        return {};
      });

      const futureDate = new Date(Date.now() + 3600000).toISOString();

      const request = {
        auth: { uid: 'user-123' },
        data: {
          participantIds: ['user-456'],
          scheduledFor: futureDate,
        },
      };

      // @ts-ignore
      const result = await createGroupCall(request);

      expect(result.success).toBe(true);
      expect(mockCallAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          status: CallStatus.SCHEDULED,
        })
      );
    });
  });

  // ========== 12. JOIN GROUP CALL ==========

  describe('joinGroupCall', () => {
    it('should join group call successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          channelName: 'group_channel',
          invitedParticipants: ['user-123'],
          hostId: 'user-456',
          participants: [{ userId: 'user-456', leftAt: null }],
          maxParticipants: 50,
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      const result = await joinGroupCall(request);

      expect(result.success).toBe(true);
      expect(result.channelName).toBe('group_channel');
      expect(result.agoraUid).toBeDefined();
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: CallStatus.ACTIVE,
        })
      );
    });

    it('should reject if not invited', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              invitedParticipants: ['other-user'],
              hostId: 'host-user',
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      await expect(joinGroupCall(request)).rejects.toThrow('Not invited');
    });

    it('should reject if call is full', async () => {
      const fullParticipants = Array(50).fill({ userId: 'user', leftAt: null });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              invitedParticipants: ['user-123'],
              hostId: 'host',
              participants: fullParticipants,
              maxParticipants: 50,
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      await expect(joinGroupCall(request)).rejects.toThrow('Call is full');
    });
  });

  // ========== 13. INVITE TO GROUP CALL ==========

  describe('inviteToGroupCall', () => {
    it('should invite participants successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          hostId: 'user-123',
          title: 'Team Call',
        }),
      });
      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'calls') {
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
        return {};
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          participantIds: ['user-456', 'user-789'],
        },
      };

      // @ts-ignore
      const result = await inviteToGroupCall(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalled();
      expect(mockNotifAdd).toHaveBeenCalledTimes(2);
    });

    it('should reject if not host', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              hostId: 'other-user',
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          participantIds: ['user-456'],
        },
      };

      // @ts-ignore
      await expect(inviteToGroupCall(request)).rejects.toThrow('Only host');
    });
  });

  // ========== 14. REMOVE FROM GROUP CALL ==========

  describe('removeFromGroupCall', () => {
    it('should remove participant successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          hostId: 'user-123',
          participants: [
            { userId: 'user-123', leftAt: null },
            { userId: 'user-456', leftAt: null },
          ],
        }),
      });
      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'calls') {
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
        return {};
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          participantId: 'user-456',
        },
      };

      // @ts-ignore
      const result = await removeFromGroupCall(request);

      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalled();
      expect(mockNotifAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-456',
          type: 'removed_from_call',
        })
      );
    });

    it('should reject if not host', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              hostId: 'other-user',
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          callId: 'call-123',
          participantId: 'user-456',
        },
      };

      // @ts-ignore
      await expect(removeFromGroupCall(request)).rejects.toThrow('Only host');
    });
  });

  // ========== 15. GET CALL HISTORY ==========

  describe('getCallHistory', () => {
    it('should fetch call history successfully', async () => {
      const mockSnapshot = {
        size: 3,
        docs: [
          { id: 'call-1', data: () => ({ duration: 120 }) },
          { id: 'call-2', data: () => ({ duration: 300 }) },
          { id: 'call-3', data: () => ({ duration: 60 }) },
        ],
      };

      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      };

      mockDb.collection.mockReturnValue(mockQuery);

      const request = {
        auth: { uid: 'user-123' },
        data: { limit: 50 },
      };

      // @ts-ignore
      const result = await getCallHistory(request);

      expect(result.success).toBe(true);
      expect(result.calls).toHaveLength(3);
      expect(result.hasMore).toBe(false);
    });

    it('should support pagination with startAfter', async () => {
      const mockStartDoc = {
        exists: true,
      };

      const mockSnapshot = {
        size: 50,
        docs: Array(50).fill({ id: 'call', data: () => ({}) }),
      };

      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        startAfter: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      };

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'calls') {
          return {
            ...mockQuery,
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(mockStartDoc),
            }),
          };
        }
        return mockQuery;
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          limit: 50,
          startAfter: 'call-50',
        },
      };

      // @ts-ignore
      const result = await getCallHistory(request);

      expect(result.hasMore).toBe(true);
    });
  });

  // ========== 16. GET CALL ANALYTICS ==========

  describe('getCallAnalytics', () => {
    it('should fetch call analytics successfully', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              duration: 600,
              callType: CallType.VIDEO,
              status: CallStatus.ENDED,
              recordingEnabled: false,
              participants: [
                {
                  userId: 'user-123',
                  joinedAt: { toMillis: () => 1000000 },
                  leftAt: { toMillis: () => 1600000 },
                },
                {
                  userId: 'user-456',
                  joinedAt: { toMillis: () => 1000000 },
                  leftAt: { toMillis: () => 1300000 },
                },
              ],
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      const result = await getCallAnalytics(request);

      expect(result.success).toBe(true);
      expect(result.analytics).toEqual(
        expect.objectContaining({
          callId: 'call-123',
          duration: 600,
          participantCount: 2,
          callType: CallType.VIDEO,
        })
      );
    });

    it('should reject if not a participant', async () => {
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              participants: [{ userId: 'other-user' }],
            }),
          }),
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { callId: 'call-123' },
      };

      // @ts-ignore
      await expect(getCallAnalytics(request)).rejects.toThrow('Not authorized');
    });
  });

  // ========== 17. ON CALL STARTED (Trigger) ==========

  describe('onCallStarted', () => {
    it('should process call started event', async () => {
      const event = {
        params: { callId: 'call-123' },
        data: {
          before: {
            data: () => ({
              status: CallStatus.RINGING,
            }),
          },
          after: {
            data: () => ({
              status: CallStatus.ACTIVE,
              participants: [{ userId: 'user-123' }],
            }),
          },
        },
      };

      // @ts-ignore
      await onCallStarted(event);

      // Should log the call start
      // XP would be granted in production
    });

    it('should skip if status did not change to active', async () => {
      const event = {
        params: { callId: 'call-123' },
        data: {
          before: {
            data: () => ({
              status: CallStatus.ACTIVE,
            }),
          },
          after: {
            data: () => ({
              status: CallStatus.ACTIVE,
            }),
          },
        },
      };

      // @ts-ignore
      await onCallStarted(event);

      // Should not process
    });
  });

  // ========== 18. ON CALL ENDED (Trigger) ==========

  describe('onCallEnded', () => {
    it('should process call ended event and update stats', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockUpdate,
        }),
      });

      const event = {
        params: { callId: 'call-123' },
        data: {
          before: {
            data: () => ({
              status: CallStatus.ACTIVE,
            }),
          },
          after: {
            data: () => ({
              status: CallStatus.ENDED,
              duration: 300,
              recordingEnabled: false,
              participants: [
                {
                  userId: 'user-123',
                  joinedAt: {},
                  leftAt: {},
                },
              ],
            }),
          },
        },
      };

      // @ts-ignore
      await onCallEnded(event);

      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          'stats.totalCalls': 'INCREMENT_1',
          'stats.totalCallMinutes': 'INCREMENT_5',
        })
      );
    });
  });

  // ========== 19. CLEANUP MISSED CALLS ==========

  describe('cleanupMissedCalls', () => {
    it('should cleanup missed calls older than 60 seconds', async () => {
      const mockSnapshot = {
        empty: false,
        size: 3,
        docs: [
          {
            ref: { id: 'call-1' },
            id: 'call-1',
            data: () => ({ callerId: 'user-123' }),
          },
          {
            ref: { id: 'call-2' },
            id: 'call-2',
            data: () => ({ callerId: 'user-456' }),
          },
          {
            ref: { id: 'call-3' },
            id: 'call-3',
            data: () => ({ callerId: 'user-789' }),
          },
        ],
      };

      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      };

      const mockBatch = {
        update: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'notifications') {
          return { add: mockNotifAdd };
        }
        return mockQuery;
      });
      mockDb.batch.mockReturnValue(mockBatch);

      // @ts-ignore
      await cleanupMissedCalls({});

      expect(mockBatch.update).toHaveBeenCalledTimes(3);
      expect(mockNotifAdd).toHaveBeenCalledTimes(3);
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    it('should handle no missed calls', async () => {
      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ empty: true }),
      };

      mockDb.collection.mockReturnValue(mockQuery);

      // @ts-ignore
      await cleanupMissedCalls({});

      // Should return early
    });
  });

  // ========== 20. CLEANUP ABANDONED CALLS ==========

  describe('cleanupAbandonedCalls', () => {
    it('should cleanup abandoned calls older than 4 hours', async () => {
      const mockSnapshot = {
        empty: false,
        size: 2,
        docs: [
          {
            ref: { id: 'call-1' },
            data: () => ({
              startedAt: { toMillis: () => Date.now() - 5 * 3600 * 1000 },
            }),
          },
          {
            ref: { id: 'call-2' },
            data: () => ({
              startedAt: { toMillis: () => Date.now() - 6 * 3600 * 1000 },
            }),
          },
        ],
      };

      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      };

      const mockBatch = {
        update: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };

      mockDb.collection.mockReturnValue(mockQuery);
      mockDb.batch.mockReturnValue(mockBatch);

      // @ts-ignore
      await cleanupAbandonedCalls({});

      expect(mockBatch.update).toHaveBeenCalledTimes(2);
      expect(mockBatch.update).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          status: CallStatus.ENDED,
          abandoned: true,
        })
      );
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    it('should handle no abandoned calls', async () => {
      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ empty: true }),
      };

      mockDb.collection.mockReturnValue(mockQuery);

      // @ts-ignore
      await cleanupAbandonedCalls({});

      // Should return early
    });
  });

  // ========== 21. ARCHIVE OLD CALL RECORDS ==========

  describe('archiveOldCallRecords', () => {
    it('should archive calls older than 90 days', async () => {
      const mockSnapshot = {
        empty: false,
        docs: [
          {
            ref: { delete: jest.fn().mockResolvedValue(undefined) },
            id: 'call-1',
            data: () => ({ duration: 120, callerId: 'user-123' }),
          },
          {
            ref: { delete: jest.fn().mockResolvedValue(undefined) },
            id: 'call-2',
            data: () => ({ duration: 300, callerId: 'user-456' }),
          },
        ],
      };

      const mockArchiveSet = jest.fn().mockResolvedValue(undefined);

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'call_archives') {
          return {
            doc: jest.fn().mockReturnValue({
              set: mockArchiveSet,
            }),
          };
        }
        if (collName === 'calls') {
          return {
            where: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue(mockSnapshot),
          };
        }
        return {};
      });

      // @ts-ignore
      await archiveOldCallRecords({});

      expect(mockArchiveSet).toHaveBeenCalledTimes(2);
      expect(mockArchiveSet).toHaveBeenCalledWith(
        expect.objectContaining({
          archivedAt: 'SERVER_TIMESTAMP',
        })
      );
      expect(mockSnapshot.docs[0].ref.delete).toHaveBeenCalled();
      expect(mockSnapshot.docs[1].ref.delete).toHaveBeenCalled();
    });

    it('should handle no old calls to archive', async () => {
      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ empty: true }),
      });

      // @ts-ignore
      await archiveOldCallRecords({});

      // Should return early
    });
  });

  // ========== INTEGRATION TESTS ==========

  describe('Integration Tests', () => {
    it('should handle complete 1-on-1 call flow', async () => {
      // 1. Initiate call
      const mockRecipientGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ name: 'Recipient' }),
      });
      const mockBlocksGet = jest.fn().mockResolvedValue({ empty: true });
      const mockCallAdd = jest.fn().mockResolvedValue({ id: 'call-123' });
      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'users') {
          return {
            doc: jest.fn().mockReturnValue({ get: mockRecipientGet }),
          };
        }
        if (collName === 'blocks') {
          return {
            where: jest.fn().mockReturnThis(),
            get: mockBlocksGet,
          };
        }
        if (collName === 'calls') {
          return { add: mockCallAdd };
        }
        if (collName === 'notifications') {
          return { add: mockNotifAdd };
        }
        return {};
      });

      const initiateRequest = {
        auth: { uid: 'user-123' },
        data: {
          recipientId: 'user-456',
          callType: CallType.VIDEO,
        },
      };

      // @ts-ignore
      const initiateResult = await initiateCall(initiateRequest);
      expect(initiateResult.success).toBe(true);

      // 2. Answer call
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          recipientId: 'user-456',
          status: CallStatus.RINGING,
          channelName: initiateResult.channelName,
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const answerRequest = {
        auth: { uid: 'user-456' },
        data: { callId: initiateResult.callId },
      };

      // @ts-ignore
      const answerResult = await answerCall(answerRequest);
      expect(answerResult.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: CallStatus.ACTIVE,
        })
      );
    });

    it('should handle complete group call flow', async () => {
      // 1. Create group call
      const mockCallAdd = jest.fn().mockResolvedValue({ id: 'group-call-123' });
      const mockNotifAdd = jest.fn().mockResolvedValue({ id: 'notif-1' });

      mockDb.collection.mockImplementation((collName: string) => {
        if (collName === 'calls') {
          return { add: mockCallAdd };
        }
        if (collName === 'notifications') {
          return { add: mockNotifAdd };
        }
        return {};
      });

      const createRequest = {
        auth: { uid: 'user-123' },
        data: {
          participantIds: ['user-456', 'user-789'],
          title: 'Team Sync',
        },
      };

      // @ts-ignore
      const createResult = await createGroupCall(createRequest);
      expect(createResult.success).toBe(true);

      // 2. Join group call
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          channelName: createResult.channelName,
          invitedParticipants: ['user-456'],
          hostId: 'user-123',
          participants: [{ userId: 'user-123', leftAt: null }],
          maxParticipants: 50,
        }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const joinRequest = {
        auth: { uid: 'user-456' },
        data: { callId: createResult.callId },
      };

      // @ts-ignore
      const joinResult = await joinGroupCall(joinRequest);
      expect(joinResult.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: CallStatus.ACTIVE,
        })
      );
    });
  });
});
