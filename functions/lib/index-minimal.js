"use strict";
/**
 * GreenGoChat Cloud Functions - Minimal Entry Point
 * Only exports language learning functions for local testing
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.getLessonStats = exports.updateLesson = exports.deleteLesson = exports.seedLessons = exports.getAdminLessons = exports.getTeacherAnalytics = exports.getUserProgressReport = exports.getLearningAnalytics = exports.updateLessonProgress = exports.purchaseLesson = exports.publishLesson = exports.createLesson = exports.reviewTeacherApplication = exports.submitTeacherApplication = void 0;
// IMPORTANT: Import firebaseAdmin first to ensure initialization
require("./shared/firebaseAdmin");
// Language Learning Functions (the ones we need to test)
var languageLearningManager_1 = require("./language_learning/languageLearningManager");
Object.defineProperty(exports, "submitTeacherApplication", { enumerable: true, get: function () { return languageLearningManager_1.submitTeacherApplication; } });
Object.defineProperty(exports, "reviewTeacherApplication", { enumerable: true, get: function () { return languageLearningManager_1.reviewTeacherApplication; } });
Object.defineProperty(exports, "createLesson", { enumerable: true, get: function () { return languageLearningManager_1.createLesson; } });
Object.defineProperty(exports, "publishLesson", { enumerable: true, get: function () { return languageLearningManager_1.publishLesson; } });
Object.defineProperty(exports, "purchaseLesson", { enumerable: true, get: function () { return languageLearningManager_1.purchaseLesson; } });
Object.defineProperty(exports, "updateLessonProgress", { enumerable: true, get: function () { return languageLearningManager_1.updateLessonProgress; } });
Object.defineProperty(exports, "getLearningAnalytics", { enumerable: true, get: function () { return languageLearningManager_1.getLearningAnalytics; } });
Object.defineProperty(exports, "getUserProgressReport", { enumerable: true, get: function () { return languageLearningManager_1.getUserProgressReport; } });
Object.defineProperty(exports, "getTeacherAnalytics", { enumerable: true, get: function () { return languageLearningManager_1.getTeacherAnalytics; } });
// Admin API
Object.defineProperty(exports, "getAdminLessons", { enumerable: true, get: function () { return languageLearningManager_1.getAdminLessons; } });
Object.defineProperty(exports, "seedLessons", { enumerable: true, get: function () { return languageLearningManager_1.seedLessons; } });
Object.defineProperty(exports, "deleteLesson", { enumerable: true, get: function () { return languageLearningManager_1.deleteLesson; } });
Object.defineProperty(exports, "updateLesson", { enumerable: true, get: function () { return languageLearningManager_1.updateLesson; } });
Object.defineProperty(exports, "getLessonStats", { enumerable: true, get: function () { return languageLearningManager_1.getLessonStats; } });
//# sourceMappingURL=index-minimal.js.map