import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

/// Fallback implementation used on non-web platforms.
class Draw2DBridgePlatform {
  Draw2DBridgePlatform();

  WebViewController? _controller;

  void registerWebViewController(WebViewController controller) {
    _controller = controller;
  }

  void unregisterWebViewController(WebViewController controller) {
    if (identical(_controller, controller)) {
      _controller = null;
    }
  }

  void runJavaScript(String script) {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    unawaited(controller.runJavaScript(script));
  }

  void postMessage(String type, Map<String, dynamic> payload) {}
}

Draw2DBridgePlatform createDraw2DBridgePlatform() {
  return Draw2DBridgePlatform();
}
