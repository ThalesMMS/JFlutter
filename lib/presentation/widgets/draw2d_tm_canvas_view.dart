import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../core/services/draw2d_bridge_service.dart';
import '../mappers/draw2d_tm_mapper.dart';
import '../providers/tm_editor_provider.dart';
import 'draw2d_canvas_fallback.dart';
import 'draw2d_platform_support.dart';

/// Draw2D-powered canvas for editing Turing Machines using the shared
/// JavaScript editor.
class Draw2DTMCanvasView extends ConsumerStatefulWidget {
  const Draw2DTMCanvasView({
    super.key,
    required this.onTMModified,
  });

  final ValueChanged<TM> onTMModified;

  @override
  ConsumerState<Draw2DTMCanvasView> createState() => _Draw2DTMCanvasViewState();
}

class _Draw2DTMCanvasViewState extends ConsumerState<Draw2DTMCanvasView> {
  WebViewController? _controller;
  final Draw2DBridgeService _bridge = Draw2DBridgeService();
  ProviderSubscription<TMEditorState>? _subscription;
  bool _isReady = false;
  TM? _lastEmittedTM;

  @override
  void initState() {
    super.initState();

    if (!_isPlatformSupported) {
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('JFlutterBridge', onMessageReceived: _handleMessage)
      ..setNavigationDelegate(
        NavigationDelegate(),
      )
      ..loadFlutterAsset('assets/draw2d/editor.html');

    _controller = controller;

    _bridge.registerWebViewController(controller);

    _subscription = ref.listenManual<TMEditorState>(
      tmEditorProvider,
      (previous, next) {
        if (_isReady) {
          _pushModel(next);
        }
        _maybeEmitTM(next.tm);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    final controller = _controller;
    if (controller != null) {
      _bridge.unregisterWebViewController(controller);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_isPlatformSupported || controller == null) {
      return const Draw2dCanvasFallback();
    }

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: WebViewWidget(controller: controller),
    );
  }

  bool get _isPlatformSupported => isDraw2dWebViewSupported();

  void _handleMessage(JavaScriptMessage message) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (error, stackTrace) {
      debugPrint('Failed to decode Draw2D TM bridge message: $error');
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      return;
    }

    final type = decoded['type'] as String? ?? '';
    final payload =
        (decoded['payload'] as Map?)?.cast<String, dynamic>() ?? const {};

    switch (type) {
      case 'editor_ready':
        setState(() {
          _isReady = true;
        });
        _pushModel(ref.read(tmEditorProvider));
        break;
      case 'state.add':
        _handleStateAdd(payload);
        break;
      case 'state.move':
        _handleStateMove(payload);
        break;
      case 'state.label':
        _handleStateLabel(payload);
        break;
      case 'state.updateFlags':
        _handleStateFlags(payload);
        break;
      case 'state.remove':
        _handleStateRemove(payload);
        break;
      case 'transition.add':
        _handleTransitionAdd(payload);
        break;
      case 'transition.label':
        _handleTransitionUpdate(payload);
        break;
      case 'transition.remove':
        _handleTransitionRemove(payload);
        break;
      default:
        debugPrint('Unhandled Draw2D TM event: $type');
        break;
    }
  }

  void _handleStateAdd(Map<String, dynamic> payload) {
    final notifier = ref.read(tmEditorProvider.notifier);
    final id = payload['id'] as String?;
    final label = payload['label'] as String?;
    final x = (payload['x'] as num?)?.toDouble();
    final y = (payload['y'] as num?)?.toDouble();
    if (id == null || label == null || x == null || y == null) {
      return;
    }

    final tm = notifier.upsertState(id: id, label: label, x: x, y: y);
    _maybeEmitTM(tm);
  }

  void _handleStateMove(Map<String, dynamic> payload) {
    final notifier = ref.read(tmEditorProvider.notifier);
    final id = payload['id'] as String?;
    final x = (payload['x'] as num?)?.toDouble();
    final y = (payload['y'] as num?)?.toDouble();
    if (id == null || x == null || y == null) {
      return;
    }

    final tm = notifier.moveState(id: id, x: x, y: y);
    _maybeEmitTM(tm);
  }

  void _handleStateLabel(Map<String, dynamic> payload) {
    final notifier = ref.read(tmEditorProvider.notifier);
    final id = payload['id'] as String?;
    final label = payload['label'] as String?;
    if (id == null || label == null) {
      return;
    }

    final tm = notifier.updateStateLabel(id: id, label: label);
    _maybeEmitTM(tm);
  }

  void _handleStateFlags(Map<String, dynamic> payload) {
    final notifier = ref.read(tmEditorProvider.notifier);
    final id = payload['id'] as String?;
    if (id == null) {
      return;
    }

    final bool? isInitial =
        payload.containsKey('isInitial') ? payload['isInitial'] as bool? : null;
    final bool? isAccepting = payload.containsKey('isAccepting')
        ? payload['isAccepting'] as bool?
        : null;

    if (isInitial == null && isAccepting == null) {
      return;
    }

    final tm = notifier.updateStateFlags(
      id: id,
      isInitial: isInitial,
      isAccepting: isAccepting,
    );
    _maybeEmitTM(tm);
  }

  void _handleStateRemove(Map<String, dynamic> payload) {
    final notifier = ref.read(tmEditorProvider.notifier);
    final id = payload['id'] as String?;
    if (id == null) {
      return;
    }

    final tm = notifier.removeState(id: id);
    _maybeEmitTM(tm);
  }

  void _handleTransitionAdd(Map<String, dynamic> payload) {
    final notifier = ref.read(tmEditorProvider.notifier);
    final id = payload['id'] as String?;
    final from = payload['fromStateId'] as String?;
    final to = payload['toStateId'] as String?;
    if (id == null || from == null || to == null) {
      return;
    }

    final read = (payload['readSymbol'] as String?) ?? '';
    final write = (payload['writeSymbol'] as String?) ?? '';
    final direction = _parseDirection(payload['direction'] as String?);

    final tm = notifier.addOrUpdateTransition(
      id: id,
      fromStateId: from,
      toStateId: to,
      readSymbol: read,
      writeSymbol: write,
      direction: direction,
    );
    _maybeEmitTM(tm);
  }

  void _handleTransitionUpdate(Map<String, dynamic> payload) {
    final notifier = ref.read(tmEditorProvider.notifier);
    final id = payload['id'] as String?;
    if (id == null) {
      return;
    }

    final read = payload['readSymbol'] as String?;
    final write = payload['writeSymbol'] as String?;
    final direction = _parseDirection(payload['direction'] as String?);

    final tm = notifier.updateTransitionOperations(
      id: id,
      readSymbol: read,
      writeSymbol: write,
      direction: direction,
    );
    _maybeEmitTM(tm);
  }

  void _handleTransitionRemove(Map<String, dynamic> payload) {
    final notifier = ref.read(tmEditorProvider.notifier);
    final id = payload['id'] as String?;
    if (id == null) {
      return;
    }

    final tm = notifier.removeTransition(id: id);
    _maybeEmitTM(tm);
  }

  void _pushModel(TMEditorState state) {
    final payload = Draw2DTMMapper.toJson(state.tm);
    final json = jsonEncode(payload);
    final controller = _controller;
    if (controller == null) {
      return;
    }
    controller
        .runJavaScript('(() => { if (window.draw2dBridge && typeof window.draw2dBridge.loadModel === "function") { window.draw2dBridge.loadModel($json); } })();')
        .catchError((error, stackTrace) {
      debugPrint('Failed to push Draw2D TM model: $error');
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    });
  }

  void _maybeEmitTM(TM? tm) {
    if (tm == null) {
      _lastEmittedTM = null;
      return;
    }

    if (!identical(_lastEmittedTM, tm)) {
      _lastEmittedTM = tm;
      widget.onTMModified(tm);
    }
  }

  TapeDirection _parseDirection(String? value) {
    final normalised = value?.trim().toUpperCase();
    switch (normalised) {
      case 'L':
      case 'LEFT':
        return TapeDirection.left;
      case 'S':
      case 'STAY':
      case 'N':
        return TapeDirection.stay;
      case 'R':
      case 'RIGHT':
      default:
        return TapeDirection.right;
    }
  }
}
