import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'draw2d_bridge_platform_stub.dart'
    if (dart.library.html) 'draw2d_bridge_platform_web.dart';

/// Singleton facade responsible for communicating with the Draw2D runtime.
class Draw2DBridgeService {
  Draw2DBridgeService._(this._platform);

  factory Draw2DBridgeService() => _instance;

  static final Draw2DBridgeService _instance = Draw2DBridgeService._(
    createDraw2DBridgePlatform(),
  );

  final Draw2DBridgePlatform _platform;

  bool get hasRegisteredController => _platform.hasRegisteredController;

  /// Registers the [controller] currently rendering the Draw2D canvas.
  void registerWebViewController(WebViewController controller) {
    debugPrint(
      '[Draw2D][Flutter] register controller ${identityHashCode(controller)}',
    );
    _platform.registerWebViewController(controller);
  }

  /// Removes the [controller] registration when it is no longer active.
  void unregisterWebViewController(WebViewController controller) {
    debugPrint(
      '[Draw2D][Flutter] unregister controller ${identityHashCode(controller)}',
    );
    _platform.unregisterWebViewController(controller);
  }

  void runJavaScript(String script, {String? debugLabel}) {
    if (!hasRegisteredController) {
      debugPrint(
        '[Draw2D][Flutter] Ignored JS invocation${debugLabel != null ? ' ($debugLabel)' : ''}: no controller registered',
      );
      return;
    }
    final labelSuffix = debugLabel != null ? ' ($debugLabel)' : '';
    debugPrint('[Draw2D][Flutter] Executing JS$labelSuffix');
    _platform.runJavaScript(script, debugLabel: debugLabel);
  }

  void _invokeBridgeMethod(String methodName, {String? argumentSource}) {
    final invocation = argumentSource == null
        ? 'b.$methodName();'
        : 'b.$methodName($argumentSource);';
    debugPrint('[Draw2D][Flutter] Invoking bridge method $methodName');
    final script =
        '(() => { try { const b = window.draw2dBridge; if (b && typeof b.$methodName === "function") { $invocation } } catch (error) { console.error(`[Draw2D][Flutter] $methodName failed`, error); } })();';
    runJavaScript(script, debugLabel: methodName);
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

    _invokeBridgeMethod('highlight', argumentSource: encoded);

    _platform.postMessage('highlight', payload);
  }

  /// Dispatches a request to clear all highlights.
  void clearHighlight() {
    _invokeBridgeMethod('clearHighlight');
    _platform.postMessage('clear_highlight', const {});
  }

  // View operations
  void zoomIn() {
    _invokeBridgeMethod('zoomIn');
    _platform.postMessage('zoom_in', const {});
  }

  void zoomOut() {
    _invokeBridgeMethod('zoomOut');
    _platform.postMessage('zoom_out', const {});
  }

  void fitToContent() {
    _invokeBridgeMethod('fitToContent');
    _platform.postMessage('fit_content', const {});
  }

  void resetView() {
    _invokeBridgeMethod('resetView');
    _platform.postMessage('reset_view', const {});
  }

  void addStateAtCenter() {
    _invokeBridgeMethod('addStateAtCenter');
    _platform.postMessage('add_state_center', const {});
  }
}
