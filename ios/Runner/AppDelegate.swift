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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
