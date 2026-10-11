/// Detects an iPhone / iPad browser that is NOT already running GreenGo as an
/// installed home-screen web app, so we can point it to the install guide.
/// Always false outside the web build.
library;

export 'ios_install_detector_stub.dart'
    if (dart.library.js_interop) 'ios_install_detector_web.dart';
