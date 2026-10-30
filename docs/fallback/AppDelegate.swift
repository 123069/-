import Flutter
import UIKit

/// 这是「原版模板」AppDelegate：如果自定义的深链代码在 Xcode 里编译报错，
/// 用这个文件覆盖 ios/Runner/AppDelegate.swift 即可，App 其余功能不受影响，
/// 只是 qingzhang:// 自动入账暂时用不了。
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
  }
}
