import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef Draw2DEventHandler = void Function(Map<String, dynamic> payload);
typedef Draw2DBridgeErrorHandler = void Function(
  Object error,
  StackTrace stackTrace, {
  String? rawMessage,
  Map<String, dynamic>? envelope,
});

/// Handles two-way communication between Flutter and the Draw2D WebView.
class Draw2DBridgeService {
  Draw2DBridgeService({
    required WebViewController controller,
    Draw2DEventHandler? onNodeAdded,
    Draw2DEventHandler? onNodeMoved,
    Draw2DEventHandler? onEdgeAdded,
    Draw2DEventHandler? onLabelEdited,
    Draw2DBridgeErrorHandler? onError,
  })  : _controller = controller,
        _onError = onError {
    updateHandlers(
      onNodeAdded: onNodeAdded,
      onNodeMoved: onNodeMoved,
      onEdgeAdded: onEdgeAdded,
      onLabelEdited: onLabelEdited,
    );
    _controller.addJavaScriptChannel(
      _channelName,
      onMessageReceived: (JavaScriptMessage message) {
        _handleInboundMessage(message.message);
      },
    );
  }

  static const _supportedVersion = 1;
  static const _channelName = 'Draw2DBridge';
  final WebViewController _controller;
  final Draw2DBridgeErrorHandler? _onError;
  final _random = Random();

  Draw2DEventHandler? _onNodeAdded;
  Draw2DEventHandler? _onNodeMoved;
  Draw2DEventHandler? _onEdgeAdded;
  Draw2DEventHandler? _onLabelEdited;

  /// Updates callbacks without recreating the bridge.
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

  /// Sends a full model to the WebView.
  Future<void> loadModel(Map<String, dynamic> model) {
    return _sendCommand('load_model', {'model': model});
  }

  /// Highlights an element in the WebView.
  Future<void> highlight(String elementId, {Map<String, dynamic>? style}) {
    return _sendCommand('highlight', {
      'elementId': elementId,
      if (style != null) 'style': style,
    });
  }

  /// Clears an existing highlight in the WebView.
  Future<void> clearHighlight() {
    return _sendCommand('clear_highlight', const {});
  }

  /// Applies a JSON patch to the current model.
  Future<void> patch(List<Map<String, dynamic>> operations) {
    return _sendCommand('patch', {'operations': operations});
  }

  /// Invokes JavaScript debug helpers to emit sample events back to Flutter.
  Future<void> triggerDebugEvents() async {
    try {
      await _controller.runJavaScript(
        'window.Draw2DTest && window.Draw2DTest.triggerSamples && window.Draw2DTest.triggerSamples();',
      );
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    }
  }

  /// Sends the standard set of debug commands to the WebView console.
  Future<void> sendDebugCommands() async {
    try {
      await loadModel({
        'id': 'debug-model',
        'nodes': [
          {
            'id': 'n1',
            'label': 'q0',
            'position': {'x': 120, 'y': 80},
          },
          {
            'id': 'n2',
            'label': 'q1',
            'position': {'x': 220, 'y': 180},
          },
        ],
        'edges': [
          {
            'id': 'e1',
            'from': 'n1',
            'to': 'n2',
            'label': 'a',
          }
        ],
      });
      await highlight('n1');
      await patch([
        {
          'op': 'replace',
          'path': '/nodes/1/label',
          'value': 'q2',
        }
      ]);
      await clearHighlight();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    }
  }

  void _handleInboundMessage(String rawMessage) {
    Map<String, dynamic>? envelope;
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Inbound message is not an object: $decoded');
      }
      envelope = decoded;
      final type = envelope['type'];
      final version = envelope['version'];
      final payload = envelope['payload'];
      if (type is! String) {
        throw FormatException('Inbound message missing type: $envelope');
      }
      if (version is! num) {
        throw FormatException('Inbound message missing version: $envelope');
      }
      if (version > _supportedVersion) {
        debugPrint(
          '[Draw2D][Flutter] Ignoring $type with unsupported version $version',
        );
        return;
      }
      if (payload is! Map) {
        throw FormatException('Inbound message payload must be an object: $envelope');
      }
      final castPayload = Map<String, dynamic>.from(payload as Map);
      debugPrint('[Draw2D][Flutter] ⇐ $type ${jsonEncode(castPayload)}');
      switch (type) {
        case 'node_added':
          _onNodeAdded?.call(castPayload);
          break;
        case 'node_moved':
          _onNodeMoved?.call(castPayload);
          break;
        case 'edge_added':
          _onEdgeAdded?.call(castPayload);
          break;
        case 'label_edited':
          _onLabelEdited?.call(castPayload);
          break;
        default:
          debugPrint('[Draw2D][Flutter] Unhandled inbound message: $envelope');
      }
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, rawMessage: rawMessage, envelope: envelope);
    }
  }

  Future<void> _sendCommand(String type, Map<String, dynamic> payload) async {
    final envelope = _buildEnvelope(type, payload);
    final script =
        'window.Draw2DHost && window.Draw2DHost.receiveMessage && window.Draw2DHost.receiveMessage(${jsonEncode(envelope)});';
    debugPrint('[Draw2D][Flutter] ⇒ $type ${jsonEncode(payload)}');
    try {
      await _controller.runJavaScript(script);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, envelope: envelope);
    }
  }

  Map<String, dynamic> _buildEnvelope(String type, Map<String, dynamic> payload) {
    return {
      'type': type,
      'version': _supportedVersion,
      'payload': payload,
      'id': _generateEnvelopeId(),
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  String _generateEnvelopeId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'flutter-$millis-$random';
  }

  void _reportError(
    Object error,
    StackTrace stackTrace, {
    String? rawMessage,
    Map<String, dynamic>? envelope,
  }) {
    debugPrint('[Draw2D][Flutter] Bridge error: $error');
    _onError?.call(
      error,
      stackTrace,
      rawMessage: rawMessage,
      envelope: envelope,
    );
  }
}
