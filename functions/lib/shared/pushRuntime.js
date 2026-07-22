"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PUSH_MEMORY = void 0;
/**
 * Runtime options shared by the push-sending functions.
 *
 * WHY 512MiB: every Cloud Functions instance loads the whole `lib/index.js`
 * module graph — 274 exported functions, ~200MB RSS before a single handler
 * runs. At the 256MiB default the container was OOM-killed during startup
 * ("Memory limit of 256 MiB exceeded with 258-304 MiB used"), and because the
 * Firestore triggers are RETRY_POLICY_DO_NOT_RETRY the event was dropped —
 * the in-app notification doc was written but the phone never got a push.
 *
 * Keep every push sender on this constant so the headroom stays uniform. The
 * real fix is splitting the bundle so an instance only loads what it needs;
 * until then this is the floor that keeps pushes delivering.
 */
exports.PUSH_MEMORY = '512MiB';
//# sourceMappingURL=pushRuntime.js.map