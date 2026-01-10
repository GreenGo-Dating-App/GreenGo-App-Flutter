/**
 * GreenGoChat Cloud Functions - Minimal Entry Point
 * Only exports language learning functions for local testing
 */

// IMPORTANT: Import firebaseAdmin first to ensure initialization
import './shared/firebaseAdmin';

// Language Learning Functions (the ones we need to test)
export {
  submitTeacherApplication,
  reviewTeacherApplication,
  createLesson,
  publishLesson,
  purchaseLesson,
  updateLessonProgress,
  getLearningAnalytics,
  getUserProgressReport,
  getTeacherAnalytics,
  // Admin API
  getAdminLessons,
  seedLessons,
  deleteLesson,
  updateLesson,
  getLessonStats,
} from './language_learning/languageLearningManager';
