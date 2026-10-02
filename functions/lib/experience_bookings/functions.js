"use strict";
/**
 * Experience bookings — Cloud Function bindings (thin wrappers; the logic is in
 * ./service.ts and ./reviews.ts, the model in ./model.ts).
 *
 * 512MiB everywhere: the functions bundle needs ~200MB RSS just to load;
 * 256MiB instances are OOM-killed on cold start and trigger events dropped.
 * No secrets: the check-in HMAC key lives in server_secrets/booking_checkin.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onBookableExperienceDeleted = exports.onPendingExperienceReviewCreated = exports.onGuestReviewWritten = exports.revealBlindReviews = exports.completeBookings = exports.expireBookingRequests = exports.sendBookingReminders = exports.resolveBookingDispute = exports.openBookingDispute = exports.confirmCashReceived = exports.markBookingPaid = exports.markBookingNoShow = exports.checkInBooking = exports.getBookingCheckInCode = exports.cancelExperienceSlot = exports.cancelBooking = exports.respondToBookingRequest = exports.createBooking = void 0;
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firestore_1 = require("firebase-functions/v2/firestore");
const svc = __importStar(require("./service"));
const reviews_1 = require("./reviews");
const CALL_OPTS = { memory: '512MiB', timeoutSeconds: 60 };
const JOB_OPTS = { memory: '512MiB', timeoutSeconds: 300, timeZone: 'UTC' };
const TRIGGER_OPTS = { memory: '512MiB', timeoutSeconds: 120 };
function callable(impl) {
    return (0, https_1.onCall)(CALL_OPTS, async (req) => {
        var _a, _b;
        const uid = (_a = req.auth) === null || _a === void 0 ? void 0 : _a.uid;
        if (!uid)
            throw new https_1.HttpsError('unauthenticated', 'Sign in required.', { code: 'unauthenticated' });
        try {
            return await impl(uid, (_b = req.data) !== null && _b !== void 0 ? _b : {});
        }
        catch (e) {
            if (e instanceof https_1.HttpsError)
                throw e;
            console.error('[bookings] callable failed:', e);
            throw new https_1.HttpsError('internal', 'booking_internal_error', { code: 'internal' });
        }
    });
}
// Callables
exports.createBooking = callable(svc.createBooking);
exports.respondToBookingRequest = callable(svc.respondToBookingRequest);
exports.cancelBooking = callable(svc.cancelBooking);
exports.cancelExperienceSlot = callable(svc.cancelSlot);
exports.getBookingCheckInCode = callable(svc.getBookingCheckInCode);
exports.checkInBooking = callable(svc.checkInBooking);
exports.markBookingNoShow = callable(svc.markNoShow);
exports.markBookingPaid = callable((uid, data) => svc.markBookingPaid(uid, data));
exports.confirmCashReceived = callable(svc.confirmCashReceived);
exports.openBookingDispute = callable(svc.openBookingDispute);
exports.resolveBookingDispute = callable(svc.resolveBookingDispute);
// Schedules
exports.sendBookingReminders = (0, scheduler_1.onSchedule)(Object.assign({ schedule: 'every 30 minutes' }, JOB_OPTS), async () => {
    await svc.sendDueReminders();
});
exports.expireBookingRequests = (0, scheduler_1.onSchedule)(Object.assign({ schedule: 'every 30 minutes' }, JOB_OPTS), async () => {
    await svc.expireDueRequests();
});
exports.completeBookings = (0, scheduler_1.onSchedule)(Object.assign({ schedule: 'every 60 minutes' }, JOB_OPTS), async () => {
    await svc.completeDueBookings();
});
exports.revealBlindReviews = (0, scheduler_1.onSchedule)(Object.assign({ schedule: 'every 60 minutes' }, JOB_OPTS), async () => {
    await (0, reviews_1.revealDueReviews)();
});
// Triggers
exports.onGuestReviewWritten = (0, firestore_1.onDocumentWritten)(Object.assign({ document: 'guest_reviews/{bookingId}' }, TRIGGER_OPTS), async (event) => {
    var _a, _b, _c, _d, _e, _f;
    try {
        await (0, reviews_1.handleGuestReviewWrite)(event.id, event.params.bookingId, (_c = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.data()) !== null && _c !== void 0 ? _c : null, (_f = (_e = (_d = event.data) === null || _d === void 0 ? void 0 : _d.after) === null || _e === void 0 ? void 0 : _e.data()) !== null && _f !== void 0 ? _f : null);
    }
    catch (e) {
        console.error(`[bookings] guest review ${event.params.bookingId} failed:`, e);
    }
});
exports.onPendingExperienceReviewCreated = (0, firestore_1.onDocumentCreated)(Object.assign({ document: 'user_experiences/{experienceId}/pending_reviews/{reviewerId}' }, TRIGGER_OPTS), async (event) => {
    var _a;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    try {
        await (0, reviews_1.handlePendingReviewCreated)(event.params.experienceId, event.params.reviewerId, data);
    }
    catch (e) {
        console.error(`[bookings] pending review ${event.params.experienceId}/${event.params.reviewerId} failed:`, e);
    }
});
exports.onBookableExperienceDeleted = (0, firestore_1.onDocumentDeleted)(Object.assign(Object.assign({ document: 'user_experiences/{experienceId}' }, TRIGGER_OPTS), { timeoutSeconds: 300 }), async (event) => {
    var _a, _b, _c;
    try {
        const hostId = (_c = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data()) === null || _b === void 0 ? void 0 : _b.hostId) !== null && _c !== void 0 ? _c : null;
        await svc.onExperienceDeleted(event.params.experienceId, hostId);
    }
    catch (e) {
        console.error(`[bookings] experience ${event.params.experienceId} delete cleanup failed:`, e);
    }
});
//# sourceMappingURL=functions.js.map