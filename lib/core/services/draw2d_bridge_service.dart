import 'package:flutter/foundation.dart';

/// Minimal bridge stub kept for compatibility while the Flutter canvas
/// replaces the legacy Draw2D WebView integration. All operations are no-ops
/// but debug logs are emitted so future hook-ups can observe usage.
class Draw2DBridgeService extends ChangeNotifier {
  Draw2DBridgeService._();

  factory Draw2DBridgeService() => _instance;

  static final Draw2DBridgeService _instance = Draw2DBridgeService._();

  bool _isBridgeReady = true;

  /// Whether the canvas bridge is ready to receive commands.
  bool get isBridgeReady => _isBridgeReady;

  /// Alias kept for backwards compatibility with the toolbar animation.
  bool get hasActiveBridge => _isBridgeReady;

  /// Marks the bridge as ready. With the Flutter canvas this is always true
  /// but the notifier continues to fire so existing listeners remain stable.
  void markBridgeReady() {
    _setBridgeReady(true);
  }

  /// Marks the bridge as disconnected.
  void markBridgeDisconnected() {
    _setBridgeReady(false);
  }

  /// Highlights states and transitions. Currently a no-op.
  void highlight({
    required Set<String> states,
    required Set<String> transitions,
  }) {
    debugPrint(
      '[Draw2D][Bridge] highlight(states=$states, transitions=$transitions) ignored',
    );
  }

  /// Clears any previous highlight. Currently a no-op.
  void clearHighlight() {
    debugPrint('[Draw2D][Bridge] clearHighlight ignored');
  }

  /// Zoom controls and other view commands are no-ops for the Flutter canvas
  /// until dedicated hooks are implemented.
  void zoomIn() => _logUnsupported('zoomIn');

  void zoomOut() => _logUnsupported('zoomOut');

  void fitToContent() => _logUnsupported('fitToContent');

  void resetView() => _logUnsupported('resetView');

  void addStateAtCenter() => _logUnsupported('addStateAtCenter');

  void _setBridgeReady(bool value) {
    if (_isBridgeReady == value) {
      return;
    }
    _isBridgeReady = value;
    notifyListeners();
  }

  void _logUnsupported(String method) {
    debugPrint('[Draw2D][Bridge] $method ignored (Flutter canvas)');
  }
}
