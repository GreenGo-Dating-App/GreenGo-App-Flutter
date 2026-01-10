/**
 * Mock Data Generators
 * Functions to generate realistic mock data for testing
 */

import * as admin from 'firebase-admin';

export const mockData = {
  // User mock data
  user: (overrides?: Partial<any>) => ({
    uid: 'test-user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    photoURL: 'https://example.com/photo.jpg',
    subscriptionTier: 'basic',
    role: 'user',
    verified: false,
    accountStatus: 'active',
    banned: false,
    profileCompleteness: 80,
    stats: {
      totalMatches: 10,
      totalMessages: 100,
      totalCalls: 5,
      profileViews: 50,
      likes: 25,
      superLikes: 3,
    },
    coins: {
      balance: 100,
    },
    createdAt: admin.firestore.Timestamp.now(),
    lastActiveAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Subscription mock data
  subscription: (overrides?: Partial<any>) => ({
    userId: 'test-user-123',
    tier: 'silver',
    status: 'active',
    platform: 'android',
    purchaseToken: 'test-purchase-token-123',
    receiptData: null,
    currentPeriodStart: admin.firestore.Timestamp.now(),
    currentPeriodEnd: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    ),
    cancelAtPeriodEnd: false,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Message mock data
  message: (overrides?: Partial<any>) => ({
    id: 'msg-123',
    conversationId: 'conv-123',
    senderId: 'user-1',
    recipientId: 'user-2',
    content: 'Hello, how are you?',
    type: 'text',
    status: 'sent',
    read: false,
    readAt: null,
    deleted: false,
    mediaUrl: null,
    translation: null,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Conversation mock data
  conversation: (overrides?: Partial<any>) => ({
    id: 'conv-123',
    participants: ['user-1', 'user-2'],
    lastMessage: 'Hello, how are you?',
    lastMessageAt: admin.firestore.Timestamp.now(),
    unreadCount: { 'user-1': 0, 'user-2': 1 },
    archived: false,
    muted: false,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Match mock data
  match: (overrides?: Partial<any>) => ({
    id: 'match-123',
    user1Id: 'user-1',
    user2Id: 'user-2',
    conversationId: 'conv-123',
    matchedAt: admin.firestore.Timestamp.now(),
    createdAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Call mock data
  call: (overrides?: Partial<any>) => ({
    id: 'call-123',
    channelName: 'call_123_456',
    callerId: 'user-1',
    recipientId: 'user-2',
    callType: 'video',
    status: 'ringing',
    videoEnabled: true,
    recordingEnabled: false,
    participants: [
      {
        userId: 'user-1',
        agoraUid: 123456,
        role: 'caller',
        joinedAt: null,
        leftAt: null,
      },
    ],
    startedAt: null,
    endedAt: null,
    duration: 0,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Coin batch mock data
  coinBatch: (overrides?: Partial<any>) => ({
    id: 'batch-123',
    userId: 'test-user-123',
    amount: 100,
    remainingAmount: 100,
    source: 'purchase',
    purchaseId: 'purchase-123',
    warned: false,
    expiresAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
    ),
    createdAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Report mock data
  report: (overrides?: Partial<any>) => ({
    id: 'report-123',
    reporterId: 'user-1',
    reportedUserId: 'user-2',
    reportedContentId: 'msg-123',
    reportedContentType: 'message',
    reason: 'inappropriate_content',
    description: 'This message contains inappropriate content',
    status: 'pending',
    priority: 'medium',
    assignedTo: null,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Achievement mock data
  achievement: (overrides?: Partial<any>) => ({
    userId: 'test-user-123',
    achievementId: 'first_match',
    progress: 1,
    target: 1,
    unlocked: true,
    unlockedAt: admin.firestore.Timestamp.now(),
    claimed: false,
    claimedAt: null,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Challenge mock data
  challenge: (overrides?: Partial<any>) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStr = today.toISOString().split('T')[0];

    return {
      userId: 'test-user-123',
      challengeId: 'send_5_messages',
      date: todayStr,
      progress: 3,
      target: 5,
      completed: false,
      completedAt: null,
      claimed: false,
      claimedAt: null,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
      ...overrides,
    };
  },

  // Gamification data
  gamification: (overrides?: Partial<any>) => ({
    userId: 'test-user-123',
    currentXP: 500,
    totalXP: 1500,
    level: 3,
    claimedLevelRewards: [1, 2],
    lastXPGained: {
      action: 'first_message',
      amount: 25,
      timestamp: admin.firestore.Timestamp.now(),
    },
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Notification mock data
  notification: (overrides?: Partial<any>) => ({
    id: 'notif-123',
    userId: 'test-user-123',
    type: 'new_message',
    title: 'New Message',
    body: 'You have a new message from Test User',
    data: {
      messageId: 'msg-123',
      conversationId: 'conv-123',
    },
    read: false,
    sent: false,
    sentAt: null,
    createdAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Backup mock data
  backup: (overrides?: Partial<any>) => ({
    userId: 'test-user-123',
    conversationId: 'conv-123',
    encryptionKey: 'encrypted-key-123',
    iv: 'iv-123',
    authTag: 'authtag-123',
    storageUrl: 'gs://backups/backup-123.enc',
    size: 1024,
    messageCount: 50,
    expiresAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)
    ),
    createdAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // PDF export mock data
  pdfExport: (overrides?: Partial<any>) => ({
    userId: 'test-user-123',
    conversationId: 'conv-123',
    fileName: 'conversation-123.pdf',
    storageUrl: 'gs://exports/conversation-123.pdf',
    downloadUrl: 'https://storage.example.com/exports/conversation-123.pdf',
    size: 2048,
    messageCount: 50,
    expiresAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    ),
    createdAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // Security audit mock data
  securityAudit: (overrides?: Partial<any>) => ({
    auditType: 'full_audit',
    startDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)),
    endDate: admin.firestore.Timestamp.now(),
    findings: [
      {
        type: 'suspicious_activity',
        severity: 'medium',
        description: 'User has 5 reports',
        affectedUsers: ['user-2'],
        timestamp: admin.firestore.Timestamp.now(),
      },
    ],
    totalFindings: 1,
    severityCounts: {
      info: 0,
      low: 0,
      medium: 1,
      high: 0,
      critical: 0,
    },
    auditDuration: 1500,
    runBy: 'admin-1',
    createdAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // A/B test mock data
  abTest: (overrides?: Partial<any>) => ({
    name: 'Test Feature A vs B',
    description: 'Testing new feature variants',
    variants: [
      { name: 'control', weight: 50 },
      { name: 'variant_a', weight: 50 },
    ],
    startDate: admin.firestore.Timestamp.now(),
    endDate: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    ),
    status: 'active',
    createdBy: 'admin-1',
    createdAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),

  // User segment mock data
  userSegment: (overrides?: Partial<any>) => ({
    name: 'Active Premium Users',
    description: 'Users with premium subscription who are active',
    criteria: {
      subscriptionTier: 'gold',
      minMatches: 10,
    },
    createdBy: 'admin-1',
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    ...overrides,
  }),
};

// Generate multiple mock items
export function generateMockArray<T>(
  generator: (index: number) => T,
  count: number
): T[] {
  return Array.from({ length: count }, (_, index) => generator(index));
}

// Generate mock user with variations
export function generateMockUser(index: number) {
  return mockData.user({
    uid: `user-${index}`,
    email: `user${index}@example.com`,
    displayName: `User ${index}`,
    stats: {
      totalMatches: Math.floor(Math.random() * 50),
      totalMessages: Math.floor(Math.random() * 200),
      totalCalls: Math.floor(Math.random() * 10),
    },
  });
}

// Generate mock message with variations
export function generateMockMessage(index: number, conversationId: string = 'conv-123') {
  return mockData.message({
    id: `msg-${index}`,
    conversationId,
    content: `Message ${index}`,
    senderId: index % 2 === 0 ? 'user-1' : 'user-2',
    recipientId: index % 2 === 0 ? 'user-2' : 'user-1',
  });
}
