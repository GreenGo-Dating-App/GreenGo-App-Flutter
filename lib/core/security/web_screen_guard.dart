/// Bridge to the `window.__ggScreenGuard` shim in `web/index.html`.
///
/// The shim owns everything that must happen synchronously in the DOM
/// (CSS blur on focus loss, blocking Ctrl/Cmd+P / Ctrl/Cmd+S, clearing the
/// clipboard after PrintScreen, no context menu / drag on media, blank print
/// stylesheet). Dart only receives the events, to drive the overlay state and
/// the "Screenshots are not allowed" toast. No-op outside the web build.
library;

export 'web_screen_guard_stub.dart'
    if (dart.library.js_interop) 'web_screen_guard_web.dart';
