import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    for context in connectionOptions.urlContexts where context.url.scheme == "qingzhang" {
      DeepLinkStore.shared.deliver(context.url.absoluteString)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts where context.url.scheme == "qingzhang" {
      DeepLinkStore.shared.deliver(context.url.absoluteString)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
