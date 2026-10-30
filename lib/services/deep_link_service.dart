import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 承接「免手动记账」的外部入口：
/// - iOS / Android：自定义 URL Scheme（qingzhang://add?...），原生侧通过 MethodChannel 转进来
/// - Web / 预览：当前页面 URL 的查询参数
class DeepLinkService {
  DeepLinkService._();

  static const MethodChannel _channel = MethodChannel('qingzhang/deeplink');
  static final StreamController<String> _controller =
      StreamController<String>.broadcast();
  static bool _listening = false;

  static Stream<String> get links => _controller.stream;

  /// App 冷启动时带来的链接（只取一次）
  static Future<String?> initialLink() async {
    if (kIsWeb) return _webLink();
    try {
      return await _channel.invokeMethod<String>('getInitialLink');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static void startListening() {
    if (_listening) return;
    _listening = true;
    if (kIsWeb) return;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onLink' && call.arguments is String) {
        _controller.add(call.arguments as String);
      }
      return null;
    });
  }

  static String? _webLink() {
    final Map<String, String> params = Uri.base.queryParameters;
    if (params.isEmpty) return null;
    if (!params.containsKey('amount') &&
        !params.containsKey('category') &&
        !params.containsKey('type')) {
      return null;
    }
    return Uri(
      scheme: 'qingzhang',
      host: 'add',
      queryParameters: params,
    ).toString();
  }
}
