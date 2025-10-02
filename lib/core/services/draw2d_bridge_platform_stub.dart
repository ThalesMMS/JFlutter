import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Fallback implementation used on non-web platforms.
class Draw2DBridgePlatform {
  Draw2DBridgePlatform();

  final List<WebViewController> _controllerStack = <WebViewController>[];

  WebViewController? get _activeController =>
      _controllerStack.isEmpty ? null : _controllerStack.last;

  void registerWebViewController(WebViewController controller) {
    final existingIndex = _controllerStack.indexOf(controller);
    if (existingIndex != -1) {
      _controllerStack.removeAt(existingIndex);
    }
    _controllerStack.add(controller);
  }

  void unregisterWebViewController(WebViewController controller) {
    final index = _controllerStack.indexOf(controller);
    if (index == -1) {
      return;
    }
    _controllerStack.removeAt(index);
  }

  bool get hasRegisteredController => _activeController != null;

  void runJavaScript(String script, {String? debugLabel}) {
    final controller = _activeController;
    if (controller == null) {
      return;
    }
    unawaited(
      controller.runJavaScript(script).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          '[Draw2D][Flutter] runJavaScript${debugLabel != null ? ' ($debugLabel)' : ''} failed: $error',
        );
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      }),
    );
  }

  void postMessage(String type, Map<String, dynamic> payload) {}
}

Draw2DBridgePlatform createDraw2DBridgePlatform() {
  return Draw2DBridgePlatform();
}
