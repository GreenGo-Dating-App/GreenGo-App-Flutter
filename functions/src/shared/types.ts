/**
 * Shared TypeScript types for all microservices
 */

import { Timestamp } from 'firebase-admin/firestore';

// ========== USER TYPES ==========

export interface User {
  uid: string;
  email: string;
  displayName: string;
  photoURL?: string;
  phoneNumber?: string;
  emailVerified: boolean;
  disabled: boolean;
  subscriptionTier: SubscriptionTier;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export enum SubscriptionTier {
  BASIC = 'basic',
  SILVER = 'silver',
  GOLD = 'gold',
  PLATINUM = 'platinum',
}

// MVP Release Access Control
export enum ApprovalStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
}

export interface UserAccessControl {
  approvalStatus: ApprovalStatus;
  approvedAt?: Timestamp;
  approvedBy?: string;
  accessDate: Timestamp; // Date when user can access the app
  membershipTier: SubscriptionTier;
}

export interface Profile {
  userId: string;
  bio: string;
  age: number;
  gender: string;
  location: GeoPoint;
  photos: string[];
  interests: string[];
  verified: boolean;
  trustScore: number;
}

export interface GeoPoint {
  latitude: number;
  longitude: number;
}

// ========== MESSAGING TYPES ==========

export interface Message {
  id: string;
  conversationId: string;
  senderId: string;
  receiverId: string;
  content: string;
  type: MessageType;
  mediaUrl?: string;
  translations?: Record<string, string>;
  timestamp: Timestamp;
  read: boolean;
  disappearing: boolean;
}

export enum MessageType {
  TEXT = 'text',
  IMAGE = 'image',
  VIDEO = 'video',
  VOICE = 'voice',
  GIF = 'gif',
}

export interface Conversation {
  id: string;
  participants: string[];
  lastMessage?: Message;
  lastMessageTimestamp: Timestamp;
  unreadCount: Record<string, number>;
}

// ========== SUBSCRIPTION TYPES ==========

export interface Subscription {
  id: string;
  userId: string;
  tier: SubscriptionTier;
  platform: 'android' | 'ios' | 'web';
  status: SubscriptionStatus;
  currentPeriodStart: Timestamp;
  currentPeriodEnd: Timestamp;
  cancelAtPeriodEnd: boolean;
  purchaseToken?: string;
  receiptData?: string;
}

export enum SubscriptionStatus {
  ACTIVE = 'active',
  CANCELED = 'canceled',
  EXPIRED = 'expired',
  ON_HOLD = 'on_hold',
  IN_GRACE_PERIOD = 'in_grace_period',
  PAUSED = 'paused',
}

// ========== COIN TYPES ==========

export interface CoinBalance {
  userId: string;
  totalCoins: number;
  batches: CoinBatch[];
  lastUpdated: Timestamp;
}

export interface CoinBatch {
  id: string;
  amount: number;
  source: CoinSource;
  expiresAt: Timestamp;
  remainingAmount: number;
}

export enum CoinSource {
  PURCHASED = 'purchased',
  EARNED = 'earned',
  GIFTED = 'gifted',
  ALLOWANCE = 'allowance',
  REFUND = 'refund',
}

export interface CoinTransaction {
  id: string;
  userId: string;
  amount: number;
  type: 'credit' | 'debit';
  source: CoinSource;
  description: string;
  timestamp: Timestamp;
  balanceAfter: number;
}

// ========== VIDEO CALL TYPES ==========

export interface VideoCall {
  id: string;
  type: 'one_to_one' | 'group';
  participants: string[];
  initiatorId: string;
  status: CallStatus;
  startTime: Timestamp;
  endTime?: Timestamp;
  duration?: number;
  quality: VideoQuality;
  recordingUrl?: string;
  agoraChannel?: string;
}

export enum CallStatus {
  INITIATING = 'initiating',
  RINGING = 'ringing',
  ONGOING = 'ongoing',
  ENDED = 'ended',
  MISSED = 'missed',
  REJECTED = 'rejected',
  ACTIVE = 'active',
  SCHEDULED = 'scheduled',
}

export enum VideoQuality {
  HD_1080P = '1080p',
  HD_720P = '720p',
  SD_480P = '480p',
  SD_360P = '360p',
}

// ========== GAMIFICATION TYPES ==========

export interface UserXP {
  userId: string;
  totalXP: number;
  level: number;
  currentLevelXP: number;
  nextLevelXP: number;
}

export interface Achievement {
  id: string;
  name: string;
  description: string;
  iconUrl: string;
  xpReward: number;
  coinReward: number;
  unlockCriteria: any;
}

export interface UserAchievement {
  userId: string;
  achievementId: string;
  unlockedAt: Timestamp;
  claimed: boolean;
}

// ========== MODERATION TYPES ==========

export interface ModerationResult {
  id: string;
  targetType: 'photo' | 'text' | 'profile';
  targetId: string;
  userId: string;
  flagged: boolean;
  categories: ModerationCategory[];
  scores: Record<string, number>;
  action: ModerationAction;
  reviewedBy?: string;
  reviewedAt?: Timestamp;
}

export enum ModerationCategory {
  ADULT = 'adult',
  VIOLENCE = 'violence',
  SPAM = 'spam',
  HATE_SPEECH = 'hate_speech',
  SCAM = 'scam',
  FAKE_PROFILE = 'fake_profile',
}

export enum ModerationAction {
  APPROVED = 'approved',
  REJECTED = 'rejected',
  PENDING_REVIEW = 'pending_review',
  AUTO_APPROVED = 'auto_approved',
  AUTO_REJECTED = 'auto_rejected',
}

export interface Report {
  id: string;
  reporterId: string;
  reportedUserId: string;
  reportedContentId?: string;
  reason: ReportReason;
  description: string;
  status: ReportStatus;
  createdAt: Timestamp;
  resolvedAt?: Timestamp;
  resolvedBy?: string;
}

export enum ReportReason {
  INAPPROPRIATE_CONTENT = 'inappropriate_content',
  HARASSMENT = 'harassment',
  SPAM = 'spam',
  FAKE_PROFILE = 'fake_profile',
  SCAM = 'scam',
  UNDERAGE = 'underage',
  OTHER = 'other',
}

export enum ReportStatus {
  PENDING = 'pending',
  UNDER_REVIEW = 'under_review',
  RESOLVED = 'resolved',
  DISMISSED = 'dismissed',
}

// ========== ANALYTICS TYPES ==========

export interface RevenueEvent {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  source: 'subscription' | 'coin_purchase';
  timestamp: Timestamp;
  metadata: Record<string, any>;
}

export interface UserCohort {
  cohortId: string;
  name: string;
  signupPeriodStart: Timestamp;
  signupPeriodEnd: Timestamp;
  userCount: number;
  criteria: Record<string, any>;
}

export interface ChurnPrediction {
  userId: string;
  churnProbability: number;
  riskLevel: 'low' | 'medium' | 'high';
  predictedAt: Timestamp;
  factors: string[];
}

// ========== NOTIFICATION TYPES ==========

export interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, any>;
  imageUrl?: string;
  read: boolean;
  sent: boolean;
  sentAt?: Timestamp;
  createdAt: Timestamp;
}

export enum NotificationType {
  NEW_MATCH = 'new_match',
  NEW_MESSAGE = 'new_message',
  PROFILE_VIEW = 'profile_view',
  SUPER_LIKE = 'super_like',
  VIDEO_CALL = 'video_call',
  SUBSCRIPTION_EXPIRING = 'subscription_expiring',
  COINS_EXPIRING = 'coins_expiring',
  ACHIEVEMENT_UNLOCKED = 'achievement_unlocked',
}

// ========== API RESPONSE TYPES ==========

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: ApiError;
  message?: string;
}

export interface ApiError {
  code: string;
  message: string;
  details?: any;
}

// ========== PAGINATION TYPES ==========

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
  nextPageToken?: string;
}

export interface PaginationParams {
  page?: number;
  pageSize?: number;
  nextPageToken?: string;
}

// ========== ADMIN TYPES ==========

export enum UserRole {
  USER = 'user',
  MODERATOR = 'moderator',
  ADMIN = 'admin',
  SUPER_ADMIN = 'super_admin',
}

// ========== ADDITIONAL CALL TYPES ==========

export enum CallType {
  ONE_TO_ONE = 'one_to_one',
  GROUP = 'group',
  SCHEDULED = 'scheduled',
}

// Add missing call statuses
export const CallStatusExtended = {
  ...CallStatus,
  ACTIVE: 'active' as const,
  SCHEDULED: 'scheduled' as const,
};

// ========== GAMIFICATION ADDITIONAL TYPES ==========

export enum AchievementType {
  MESSAGES_SENT = 'messages_sent',
  MATCHES_MADE = 'matches_made',
  PROFILE_COMPLETE = 'profile_complete',
  VERIFICATION_COMPLETE = 'verification_complete',
  STREAKS = 'streaks',
  COINS_EARNED = 'coins_earned',
  LESSONS_COMPLETE = 'lessons_complete',
}

export enum ChallengeType {
  DAILY = 'daily',
  WEEKLY = 'weekly',
  MONTHLY = 'monthly',
  SPECIAL = 'special',
}
