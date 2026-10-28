import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    SecureDisplay.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "SecureDisplay")!)
  }
}

/// iOS counterpart of Android's FLAG_SECURE (see MainActivity.kt) so one-time
/// codes never leave the device as an image.
///
/// iOS has no switch that refuses a screenshot, so instead:
/// - the window is drawn inside the secure layer of a password field, which
///   iOS leaves out of screenshots, screen recordings and mirroring — the
///   capture comes out blank;
/// - while the app is not active (app switcher, Control Center) a plain cover
///   hides it, so the switcher snapshot shows no codes;
/// - while iOS reports the screen is being recorded or mirrored
///   (`UIScreen.isCaptured`), the same cover stays up with a note. This is the
///   official API and backs up the secure layer, which relies on how iOS
///   draws password fields and could change in a future release;
/// - each screenshot is reported to Dart so the app can say why it is blank.
///
/// Driven from `lib/data/secure_display.dart` over the
/// `com.sarv.otp/secure_display` channel.
final class SecureDisplay: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel
  private weak var registrar: FlutterPluginRegistrar?
  private var coverColor = UIColor.black
  private var cover: UIView?
  private var isInactive = false
  private var securedWindow: UIWindow?
  private var observers: [NSObjectProtocol] = []

  private init(channel: FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
    self.channel = channel
    self.registrar = registrar
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.sarv.otp/secure_display", binaryMessenger: registrar.messenger())
    let instance = SecureDisplay(channel: channel, registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "enable" else {
      result(FlutterMethodNotImplemented)
      return
    }
    if let argb = (call.arguments as? [String: Any])?["cover"] as? Int {
      coverColor = UIColor(argb: argb)
    }
    enable()
    result(nil)
  }

  private func enable() {
    guard observers.isEmpty else { return }
    let center = NotificationCenter.default
    observers = [
      // The window may not exist yet when Dart asks; secure it once it does.
      center.addObserver(
        forName: UIScene.didActivateNotification, object: nil, queue: .main
      ) { [weak self] _ in
        self?.secureWindowIfNeeded()
        self?.isInactive = false
        self?.updateCover()
      },
      center.addObserver(
        forName: UIScene.willDeactivateNotification, object: nil, queue: .main
      ) { [weak self] _ in
        self?.isInactive = true
        self?.updateCover()
      },
      center.addObserver(
        forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main
      ) { [weak self] _ in self?.updateCover() },
      center.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: .main
      ) { [weak self] _ in self?.channel.invokeMethod("screenshotTaken", arguments: nil) },
    ]
    secureWindowIfNeeded()
    updateCover()
  }

  private var window: UIWindow? {
    registrar?.viewController?.view.window
  }

  private func secureWindowIfNeeded() {
    guard securedWindow == nil, let window else { return }
    securedWindow = window
    window.drawInSecureLayer()
  }

  private var isCaptured: Bool {
    securedWindow?.windowScene?.screen.isCaptured ?? false
  }

  /// Shows the cover while the app is inactive or the screen is being
  /// captured, and removes it otherwise.
  private func updateCover() {
    cover?.removeFromSuperview()
    cover = nil
    guard let window = securedWindow, isInactive || isCaptured else { return }
    let view = makeCover(
      frame: window.bounds,
      note: isCaptured ? "Codes are hidden while the screen is recorded or mirrored" : nil)
    window.addSubview(view)
    cover = view
  }

  private func makeCover(frame: CGRect, note: String?) -> UIView {
    let view = UIView(frame: frame)
    view.backgroundColor = coverColor
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    guard let note else { return view }
    let label = UILabel()
    label.text = note
    label.textColor = .white
    label.font = .preferredFont(forTextStyle: .headline)
    label.numberOfLines = 0
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    return view
  }
}

private extension UIWindow {
  /// Re-parents the window's layer into a secure text field's content layer.
  /// That layer is the one iOS blanks in captures; the window keeps drawing
  /// and taking touches as before. The field's secure container is its last
  /// sublayer from iOS 17 and its first before that.
  func drawInSecureLayer() {
    let field = UITextField()
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = false
    addSubview(field)
    layer.superlayer?.addSublayer(field.layer)
    let container: CALayer?
    if #available(iOS 17.0, *) {
      container = field.layer.sublayers?.last
    } else {
      container = field.layer.sublayers?.first
    }
    container?.addSublayer(layer)
  }
}

private extension UIColor {
  convenience init(argb: Int) {
    self.init(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255)
  }
}
