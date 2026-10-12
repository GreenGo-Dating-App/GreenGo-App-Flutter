import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// True on iPhone / iPad / iPod, in a browser or as an installed home-screen
/// web app.
bool isIosWebDevice() {
  try {
    final nav = globalContext.getProperty<JSObject>('navigator'.toJS);
    final ua = (nav.getProperty<JSAny?>('userAgent'.toJS) as JSString?)?.toDart ?? '';
    final platform = (nav.getProperty<JSAny?>('platform'.toJS) as JSString?)?.toDart ?? '';
    final touch = (nav.getProperty<JSAny?>('maxTouchPoints'.toJS) as JSNumber?)?.toDartInt ?? 0;
    return RegExp(r'iPhone|iPad|iPod').hasMatch(ua) ||
        // iPadOS 13+ reports itself as a Mac; a Mac has no touch screen.
        (platform == 'MacIntel' && touch > 1);
  } catch (_) {
    return false;
  }
}

/// True on iPhone / iPad / iPod browsers (Safari or an in-app browser) when
/// GreenGo is not already opened as an installed home-screen web app.
bool isIosBrowserNotInstalled() {
  try {
    if (!isIosWebDevice()) return false;
    final nav = globalContext.getProperty<JSObject>('navigator'.toJS);

    final legacyStandalone = nav.getProperty<JSAny?>('standalone'.toJS);
    if (legacyStandalone is JSBoolean && legacyStandalone.toDart) return false;
    final mq = globalContext.callMethod<JSObject>(
        'matchMedia'.toJS, '(display-mode: standalone)'.toJS);
    final standalone = (mq.getProperty<JSAny?>('matches'.toJS) as JSBoolean?)?.toDart ?? false;
    return !standalone;
  } catch (_) {
    return false;
  }
}
