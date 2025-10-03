import 'package:flutter/foundation.dart';

typedef Draw2DEventHandler = void Function(Map<String, dynamic> payload);
typedef Draw2DBridgeErrorHandler = void Function(
  Object error,
  StackTrace stackTrace, {
  String? rawMessage,
  Map<String, dynamic>? envelope,
});

/// Stub implementation kept for API compatibility while the project migrates
/// away from the legacy Draw2D WebView bridge. All commands are ignored.
class Draw2DBridgeService {
  Draw2DBridgeService({
    Draw2DEventHandler? onNodeAdded,
    Draw2DEventHandler? onNodeMoved,
    Draw2DEventHandler? onEdgeAdded,
    Draw2DEventHandler? onLabelEdited,
    Draw2DBridgeErrorHandler? onError,
  }) : _onError = onError {
    updateHandlers(
      onNodeAdded: onNodeAdded,
      onNodeMoved: onNodeMoved,
      onEdgeAdded: onEdgeAdded,
      onLabelEdited: onLabelEdited,
    );
  }

  final Draw2DBridgeErrorHandler? _onError;

  Draw2DEventHandler? _onNodeAdded;
  Draw2DEventHandler? _onNodeMoved;
  Draw2DEventHandler? _onEdgeAdded;
  Draw2DEventHandler? _onLabelEdited;

  void updateHandlers({
    Draw2DEventHandler? onNodeAdded,
    Draw2DEventHandler? onNodeMoved,
    Draw2DEventHandler? onEdgeAdded,
    Draw2DEventHandler? onLabelEdited,
  }) {
    _onNodeAdded = onNodeAdded;
    _onNodeMoved = onNodeMoved;
    _onEdgeAdded = onEdgeAdded;
    _onLabelEdited = onLabelEdited;
  }

  Future<void> loadModel(Map<String, dynamic> model) async {
    _logIgnored('loadModel', {'model': model});
  }

  Future<void> highlight(String elementId, {Map<String, dynamic>? style}) async {
    _logIgnored('highlight', {'elementId': elementId, if (style != null) 'style': style});
  }

  Future<void> clearHighlight() async {
    _logIgnored('clearHighlight');
  }

  Future<void> patch(List<Map<String, dynamic>> operations) async {
    _logIgnored('patch', {'operations': operations});
  }

  Future<void> triggerDebugEvents() async {
    _logIgnored('triggerDebugEvents');
  }

  Future<void> sendDebugCommands() async {
    _logIgnored('sendDebugCommands');
  }

  void handleInboundMessage(Map<String, dynamic> envelope) {
    _logIgnored('handleInboundMessage', envelope);
  }

  void _logIgnored(String method, [Map<String, dynamic>? payload]) {
    debugPrint('[Draw2D][BridgeStub] $method ignored with payload: $payload');
  }

  void reportError(Object error, StackTrace stackTrace, {String? rawMessage, Map<String, dynamic>? envelope}) {
    _onError?.call(error, stackTrace, rawMessage: rawMessage, envelope: envelope);
  }
}
