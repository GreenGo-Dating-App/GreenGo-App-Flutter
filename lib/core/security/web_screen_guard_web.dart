import 'dart:js_interop';
import 'dart:js_interop_unsafe';

JSObject? _guard() {
  try {
    final g = globalContext.getProperty<JSAny?>('__ggScreenGuard'.toJS);
    return g is JSObject ? g : null;
  } catch (_) {
    return null;
  }
}

/// Registers [onEvent] with the shim. Returns false when the shim is missing
/// (e.g. an index.html without it), in which case only Dart-side protection
/// (overlay + watermarks) applies.
bool attachWebScreenGuard(void Function(String event) onEvent) {
  final guard = _guard();
  if (guard == null) return false;
  try {
    guard.callMethod<JSAny?>(
      'attach'.toJS,
      ((JSString event) => onEvent(event.toDart)).toJS,
    );
    return true;
  } catch (_) {
    return false;
  }
}

/// Remote kill-switch: stops the shim's CSS blur and shortcut blocking.
void setWebScreenGuardEnabled(bool enabled) {
  final guard = _guard();
  if (guard == null) return;
  try {
    guard.callMethod<JSAny?>('setEnabled'.toJS, enabled.toJS);
  } catch (_) {}
}
