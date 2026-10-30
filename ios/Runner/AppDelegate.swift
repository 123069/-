import Flutter
import UIKit

/// 保存外部链接（qingzhang://...），在 Dart 侧准备好之后转交过去。
/// 放在 AppDelegate 文件里，SceneDelegate 可以直接使用，不需要改 Xcode 工程文件。
final class DeepLinkStore {
  static let shared = DeepLinkStore()

  private var pending: String?
  private var channel: FlutterMethodChannel?

  func attach(channel: FlutterMethodChannel) {
    self.channel = channel
    if let link = pending {
      channel.invokeMethod("onLink", arguments: link)
      pending = nil
    }
  }

  func deliver(_ link: String) {
    if let channel = channel {
      channel.invokeMethod("onLink", arguments: link)
    } else {
      pending = link
    }
  }

  func takePending() -> String? {
    let value = pending
    pending = nil
    return value
  }
}

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

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "QingzhangDeepLink")
    else { return }

    let channel = FlutterMethodChannel(
      name: "qingzhang/deeplink",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getInitialLink" {
        result(DeepLinkStore.shared.takePending())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    DeepLinkStore.shared.attach(channel: channel)
  }
}
