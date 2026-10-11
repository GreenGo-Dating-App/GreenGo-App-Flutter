import Flutter
import UIKit
import GoogleMaps
#if canImport(DeclaredAgeRange)
// iOS 26+ framework; the app supports older iOS, so link it WEAKLY and only
// touch it behind #available (P3-1 regional age assurance).
@_weakLinked import DeclaredAgeRange
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String ?? ""
    GMSServices.provideAPIKey(mapsApiKey)
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "GreenGoAgeSignalsBridge") {
      AgeSignalsBridge.register(with: registrar)
    }
    if let registrar = self.registrar(forPlugin: "GreenGoScreenSecurity") {
      ScreenSecurityBridge.shared.register(with: registrar)
    }
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // UIKit makes the storyboard window visible AFTER this method returns, and
    // the secure layer needs the window's layer to be attached; install on the
    // next run-loop turn (Dart's `enable` call at startup retries it).
    DispatchQueue.main.async {
      ScreenSecurityBridge.shared.installIfNeeded(in: self.window)
    }
    return launched
  }
}

/// Screenshot / screen-recording protection (Dart side:
/// lib/core/security/screen_security_service.dart). Channel
/// `greengo/screen_security`.
///
/// BLOCKED (secure layer): iOS has no FLAG_SECURE. The well-known workaround
/// (also used by the screen_protector / no_screenshot plugins) relies on
/// UIKit hiding the content of a password field (`isSecureTextEntry`) from
/// screenshots, screen recordings, AirPlay/mirroring and the app-switcher
/// snapshot. We create an off-screen secure UITextField and move the WINDOW's
/// layer inside the field's internal canvas layer, so the whole app renders
/// blank in every capture while looking normal on the device. Toggling
/// `isSecureTextEntry` turns the protection on/off without re-parenting.
///
/// RISKS (verify on a device for every new iOS major version):
///  - It depends on PRIVATE UIKit layer structure. The canvas layer was the
///    FIRST sublayer of the field before iOS 17 and is the LAST one since;
///    if Apple changes it again the guard below finds no layer and we skip
///    the install (unprotected, never broken). If a future iOS renders the
///    app black on device instead, ship the remote kill-switch
///    (`app_config/feature_flags.screenProtection = false`): Dart calls
///    `disable` with `persist: true`, so the NEXT launch does not install the
///    layer at all; Info.plist `GGSecureLayerDisabled = YES` disables it in a
///    build.
///  - Layout: the window layer is re-parented, not the views; hit testing,
///    safe areas and rotation keep working in the reference implementations,
///    but rotation/split-view on iPad must be checked on device.
///  - Keyboard: the field never becomes first responder (no interaction), so
///    it does not show a keyboard or the password AutoFill bar.
///  - App Review: uses only public API (UITextField, CALayer).
///
/// DETECTED: `userDidTakeScreenshotNotification` -> Dart `onScreenshot` (the
/// image itself is blank while protected; chats post "X took a screenshot"),
/// `capturedDidChangeNotification` -> Dart `onCaptureChanged(isCaptured)`
/// (recording / mirroring / AirPlay), which shows a full-screen cover.
///
/// NOT VERIFIED: written on Windows, never compiled.
final class ScreenSecurityBridge: NSObject {
  static let shared = ScreenSecurityBridge()
  static let channelName = "greengo/screen_security"
  private static let persistedOffKey = "gg_secure_layer_off"

  private var channel: FlutterMethodChannel?
  private var secureField: UITextField?
  private var wantsSecure = true

  private var secureLayerAllowed: Bool {
    let plistOff = Bundle.main.object(forInfoDictionaryKey: "GGSecureLayerDisabled") as? Bool ?? false
    return !plistOff && !UserDefaults.standard.bool(forKey: ScreenSecurityBridge.persistedOffKey)
  }

  func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: ScreenSecurityBridge.channelName,
                                       binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      let persist = (call.arguments as? [String: Any])?["persist"] as? Bool ?? false
      switch call.method {
      case "enable":
        if persist { UserDefaults.standard.removeObject(forKey: ScreenSecurityBridge.persistedOffKey) }
        self.setSecure(true)
        result(true)
      case "disable":
        if persist { UserDefaults.standard.set(true, forKey: ScreenSecurityBridge.persistedOffKey) }
        self.setSecure(false)
        result(true)
      case "isCaptured":
        result(self.isCaptured)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel

    let center = NotificationCenter.default
    center.addObserver(self, selector: #selector(didTakeScreenshot),
                       name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    center.addObserver(self, selector: #selector(capturedDidChange),
                       name: UIScreen.capturedDidChangeNotification, object: nil)
  }

  @objc private func didTakeScreenshot() {
    channel?.invokeMethod("onScreenshot", arguments: nil)
  }

  @objc private func capturedDidChange() {
    channel?.invokeMethod("onCaptureChanged", arguments: isCaptured)
  }

  private var isCaptured: Bool {
    if let screen = appWindow?.windowScene?.screen {
      return screen.isCaptured
    }
    return UIScreen.main.isCaptured
  }

  private var appWindow: UIWindow? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let windows = scenes.flatMap { $0.windows }
    return windows.first { $0.isKeyWindow } ?? windows.first
  }

  private func setSecure(_ secure: Bool) {
    wantsSecure = secure
    if secure {
      installIfNeeded(in: appWindow)
    }
    secureField?.isSecureTextEntry = secure
  }

  /// Installs the secure layer once. Safe to call repeatedly; a no-op when
  /// disabled, already installed, or the window is not on screen yet.
  func installIfNeeded(in window: UIWindow?) {
    guard secureLayerAllowed, wantsSecure, secureField == nil,
          let window = window,
          let hostLayer = window.layer.superlayer else { return }

    let field = UITextField()
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = false
    window.addSubview(field)
    field.layoutIfNeeded()

    let canvas: CALayer?
    if #available(iOS 17.0, *) {
      canvas = field.layer.sublayers?.last
    } else {
      canvas = field.layer.sublayers?.first
    }
    guard let secureLayer = canvas else {
      // UIKit internals differ from what we expect: stay unprotected rather
      // than risk breaking rendering.
      field.removeFromSuperview()
      return
    }
    hostLayer.addSublayer(field.layer)
    secureLayer.addSublayer(window.layer)
    secureField = field
  }
}

/// P3-1 regional age assurance: Apple Declared Age Range (iOS 26+).
///
/// Channel `com.greengochat.greengochatapp/age_signals`, method
/// `checkAgeSignals` -> map {available, shared, ageLower, ageUpper, declaration}.
/// `declaration` is the AgeRangeDeclaration case name as a string (e.g.
/// "selfDeclared", "governmentIDChecked"), so newer cases need no code change;
/// the server (`recordStoreAgeSignal`) decides which ones are strong enough.
///
/// NOT VERIFIED: written on Windows, never compiled. Requires the
/// `com.apple.developer.declared-age-range` entitlement (capability enabled on
/// the App ID first, or signing fails); without it the call throws and the app
/// falls back to ID verification. The response is NOT signed: a modified
/// client can forge it, which is why it only counts as `store_signal`.
enum AgeSignalsBridge {
  static let channelName = "com.greengochat.greengochatapp/age_signals"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "checkAgeSignals" else {
        result(FlutterMethodNotImplemented)
        return
      }
      check(result: result)
    }
  }

  private static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let windows = scenes.flatMap { $0.windows }
    var vc = (windows.first { $0.isKeyWindow } ?? windows.first)?.rootViewController
    while let presented = vc?.presentedViewController { vc = presented }
    return vc
  }

  private static func check(result: @escaping FlutterResult) {
    #if canImport(DeclaredAgeRange)
    if #available(iOS 26.0, *) {
      guard let vc = topViewController() else {
        result(["available": false, "error": "noViewController"])
        return
      }
      Task { @MainActor in
        do {
          let response = try await AgeRangeService.shared.requestAgeRange(ageGates: 18, in: vc)
          switch response {
          case .declinedSharing:
            result(["available": true, "shared": false])
          case .sharing(let range):
            var out: [String: Any] = ["available": true, "shared": true]
            if let lower = range.lowerBound { out["ageLower"] = lower }
            if let upper = range.upperBound { out["ageUpper"] = upper }
            if let declaration = range.ageRangeDeclaration {
              out["declaration"] = String(describing: declaration)
            }
            result(out)
          @unknown default:
            result(["available": false, "error": "unknownResponse"])
          }
        } catch {
          result(["available": false, "error": String(describing: error)])
        }
      }
      return
    }
    #endif
    result(["available": false, "error": "unsupported"])
  }
}
