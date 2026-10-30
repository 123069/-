package com.qingzhang.qingzhang

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 接收 qingzhang://add?... 链接，转交给 Dart 侧的「自动记账」。
 */
class MainActivity : FlutterActivity() {
    private var pendingLink: String? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qingzhang/deeplink")
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "getInitialLink") {
                result.success(pendingLink ?: intent?.dataString)
                pendingLink = null
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val data = intent.dataString ?: return
        val ch = channel
        if (ch != null) {
            ch.invokeMethod("onLink", data)
        } else {
            pendingLink = data
        }
    }
}
