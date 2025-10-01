// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

/// Web implementation that forwards messages to the hosting window.
class Draw2DBridgePlatform {
  const Draw2DBridgePlatform();

  void registerWebViewController(Object controller) {}

  void unregisterWebViewController(Object controller) {}

  void runJavaScript(String script) {}

  void postMessage(String type, Map<String, dynamic> payload) {
    html.window.postMessage({'type': type, 'payload': payload}, '*');
  }
}

Draw2DBridgePlatform createDraw2DBridgePlatform() {
  return const Draw2DBridgePlatform();
}
