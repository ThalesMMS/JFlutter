import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import 'draw2d_bridge_platform_stub.dart'
    if (dart.library.html) 'draw2d_bridge_platform_web.dart';

/// Singleton facade responsible for communicating with the Draw2D runtime.
class Draw2DBridgeService {
  Draw2DBridgeService._(this._platform);

  factory Draw2DBridgeService() => _instance;

  static final Draw2DBridgeService _instance =
      Draw2DBridgeService._(createDraw2DBridgePlatform());

  final Draw2DBridgePlatform _platform;

  /// Registers the [controller] currently rendering the Draw2D canvas.
  void registerWebViewController(WebViewController controller) {
    _platform.registerWebViewController(controller);
  }

  /// Removes the [controller] registration when it is no longer active.
  void unregisterWebViewController(WebViewController controller) {
    _platform.unregisterWebViewController(controller);
  }

  /// Dispatches a highlight event to the Draw2D runtime.
  void highlight({
    required Set<String> states,
    required Set<String> transitions,
  }) {
    final payload = <String, dynamic>{
      'states': states.toList(),
      'transitions': transitions.toList(),
    };

    final encoded = jsonEncode(payload);

    _platform.runJavaScript('window.draw2dBridge?.highlight($encoded);');

    _platform.postMessage('highlight', payload);
  }

  /// Dispatches a request to clear all highlights.
  void clearHighlight() {
    _platform.runJavaScript('window.draw2dBridge?.clearHighlight();');
    _platform.postMessage('clear_highlight', const {});
  }
}
