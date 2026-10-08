/**
 * Global defaults for every v2 function (security Phase 1, M-27).
 *
 * This project's index.js loads ~300 functions and needs ~200MB RSS before a
 * handler runs, so a function left at the 256MiB default is OOM-killed on cold
 * start and its event is dropped silently. Raise the v2 default to 512MiB.
 * Explicit per-function `memory` options still override this.
 *
 * Must be imported by index.ts BEFORE any module that defines a function.
 * (v1 functions are unaffected; they set `runWith({ memory })` themselves.)
 */
import { setGlobalOptions } from 'firebase-functions/v2';

setGlobalOptions({ memory: '512MiB' });
