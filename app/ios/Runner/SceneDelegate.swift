import Flutter
import UIKit
import receive_sharing_intent

// We also use app_links for invite-link Universal Links — this override is receive_sharing_intent's
// own documented work-around so the two don't compete over the same incoming-URL delegate hooks
// (the ShareMedia-<bundle id>:// scheme it redirects through after the Share Extension hands off).
class SceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        _ = ReceiveSharingIntentPlugin.instance.scene(scene, willConnectTo: session, options: connectionOptions)
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if ReceiveSharingIntentPlugin.instance.scene(scene, openURLContexts: URLContexts) {
            return
        }
        super.scene(scene, openURLContexts: URLContexts)
    }
}
