import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/models/pda.dart';
import '../../core/services/draw2d_bridge_service.dart';
import '../mappers/draw2d_pda_mapper.dart';
import '../providers/pda_editor_provider.dart';
import 'draw2d_canvas_fallback.dart';
import 'draw2d_platform_support.dart';

/// Draw2D canvas for editing pushdown automata.
class Draw2DPdaCanvasView extends ConsumerStatefulWidget {
  const Draw2DPdaCanvasView({
    super.key,
    required this.onPdaModified,
  });

  final ValueChanged<PDA> onPdaModified;

  @override
  ConsumerState<Draw2DPdaCanvasView> createState() => _Draw2DPdaCanvasViewState();
}

class _Draw2DPdaCanvasViewState extends ConsumerState<Draw2DPdaCanvasView> {
  WebViewController? _controller;
  final Draw2DBridgeService _bridge = Draw2DBridgeService();
  ProviderSubscription<PDAEditorState>? _subscription;
  bool _isReady = false;
  Timer? _moveDebounce;
  final Map<String, _PendingMove> _pendingMoves = {};
  Future<void>? _runtimeLoadOperation;
  bool _runtimeInjected = false;

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

    _subscription = ref.listenManual<PDAEditorState>(
      pdaEditorProvider,
      (previous, next) {
        if (!_isReady) {
          return;
        }
        if (identical(previous?.pda, next.pda)) {
          return;
        }
        _pushModel(next.pda);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    _moveDebounce?.cancel();
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
      debugPrint('Failed to decode PDA bridge message: $error');
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
        _bridge.markBridgeReady();
        _pushModel(ref.read(pdaEditorProvider).pda);
        break;
      case 'runtime_request':
        unawaited(_handleRuntimeRequest());
        break;
      case 'log':
        _handleWebLog(payload);
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
        _handleTransitionUpsert(payload, requireEndpoints: true);
        break;
      case 'transition.label':
        _handleTransitionUpsert(payload, requireEndpoints: false);
        break;
      case 'transition.remove':
        _handleTransitionRemove(payload);
        break;
      default:
        debugPrint('Unhandled Draw2D PDA event: $type');
        break;
    }
  }

  void _handleWebLog(Map<String, dynamic> payload) {
    final level = payload['level'] as String? ?? 'info';
    final message = payload['message'] as String? ?? '';
    final details = payload['details'];
    final suffix = details != null ? ' ${jsonEncode(details)}' : '';
    debugPrint('[Draw2D][Web][$level] $message$suffix');
  }

  void _handleStateAdd(Map<String, dynamic> payload) {
    final notifier = ref.read(pdaEditorProvider.notifier);
    final id = payload['id'] as String? ?? _nextStateId();
    final label = payload['label'] as String? ?? id;
    final x = (payload['x'] as num?)?.toDouble();
    final y = (payload['y'] as num?)?.toDouble();
    if (x == null || y == null) {
      return;
    }

    final updated = notifier.addOrUpdateState(
      id: id,
      label: label,
      x: x,
      y: y,
    );
    if (updated != null) {
      widget.onPdaModified(updated);
    }
  }

  void _handleStateMove(Map<String, dynamic> payload) {
    final id = payload['id'] as String?;
    final x = (payload['x'] as num?)?.toDouble();
    final y = (payload['y'] as num?)?.toDouble();
    if (id == null || x == null || y == null) {
      return;
    }

    _pendingMoves[id] = _PendingMove(id: id, x: x, y: y);
    _moveDebounce ??= Timer(const Duration(milliseconds: 60), _flushMoves);
  }

  void _handleStateLabel(Map<String, dynamic> payload) {
    final id = payload['id'] as String?;
    final label = payload['label'] as String?;
    if (id == null || label == null) {
      return;
    }

    final updated =
        ref.read(pdaEditorProvider.notifier).updateStateLabel(id: id, label: label);
    if (updated != null) {
      widget.onPdaModified(updated);
    }
  }

  void _handleStateFlags(Map<String, dynamic> payload) {
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

    final updated = ref.read(pdaEditorProvider.notifier).updateStateFlags(
          id: id,
          isInitial: isInitial,
          isAccepting: isAccepting,
        );
    if (updated != null) {
      widget.onPdaModified(updated);
    }
  }

  void _handleStateRemove(Map<String, dynamic> payload) {
    final id = payload['id'] as String?;
    if (id == null) {
      return;
    }

    final updated = ref.read(pdaEditorProvider.notifier).removeState(id: id);
    if (updated != null) {
      widget.onPdaModified(updated);
    }
  }

  void _handleTransitionUpsert(
    Map<String, dynamic> payload, {
    required bool requireEndpoints,
  }) {
    final id = payload['id'] as String? ?? _nextTransitionId();
    final from = payload['fromStateId'] as String?;
    final to = payload['toStateId'] as String?;
    final label = payload['label'] as String?;

    if (requireEndpoints && (from == null || to == null)) {
      return;
    }

    final stackPayload = _parseStackPayload(payload);
    if (stackPayload == null && requireEndpoints) {
      return;
    }

    final updated = ref.read(pdaEditorProvider.notifier).upsertTransition(
          id: id,
          fromStateId: from,
          toStateId: to,
          label: label,
          readSymbol: stackPayload?.readSymbol,
          popSymbol: stackPayload?.popSymbol,
          pushSymbol: stackPayload?.pushSymbol,
          isLambdaInput: stackPayload?.isLambdaInput,
          isLambdaPop: stackPayload?.isLambdaPop,
          isLambdaPush: stackPayload?.isLambdaPush,
        );
    if (updated != null) {
      widget.onPdaModified(updated);
    }
  }

  void _handleTransitionRemove(Map<String, dynamic> payload) {
    final id = payload['id'] as String?;
    if (id == null) {
      return;
    }

    final updated = ref.read(pdaEditorProvider.notifier).removeTransition(id: id);
    if (updated != null) {
      widget.onPdaModified(updated);
    }
  }

  Future<void> _handleRuntimeRequest() async {
    if (_runtimeInjected) {
      return;
    }

    final controller = _controller;
    if (controller == null) {
      return;
    }

    _runtimeLoadOperation ??= _injectRuntime(controller);
    try {
      await _runtimeLoadOperation;
    } finally {
      _runtimeLoadOperation = null;
    }
  }

  Future<void> _injectRuntime(WebViewController controller) async {
    try {
      final source = await rootBundle.loadString('assets/draw2d/vendor/draw2d.js');
      final scriptLiteral = jsonEncode(source);
      await controller.runJavaScript(
        '(() => { const source = $scriptLiteral; if (window.draw2dBridge && typeof window.draw2dBridge.loadRuntimeFromFlutter === "function") { window.draw2dBridge.loadRuntimeFromFlutter(source); } })();',
      );
      _runtimeInjected = true;
    } catch (error, stackTrace) {
      _runtimeInjected = false;
      debugPrint('Failed to inject Draw2D runtime for PDA editor: $error');
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
  }

  void _flushMoves() {
    final notifier = ref.read(pdaEditorProvider.notifier);
    for (final move in _pendingMoves.values) {
      notifier.moveState(id: move.id, x: move.x, y: move.y);
    }
    _pendingMoves.clear();
    _moveDebounce?.cancel();
    _moveDebounce = null;
    final pda = ref.read(pdaEditorProvider).pda;
    if (pda != null) {
      widget.onPdaModified(pda);
    }
  }

  Future<void> _pushModel(PDA? pda) async {
    final payload = Draw2DPdaMapper.toJson(pda);
    final json = _escapeForJsLiteral(jsonEncode(payload));
    final controller = _controller;
    if (controller == null) {
      return;
    }
    try {
      await controller.runJavaScript('(() => { if (window.draw2dBridge && typeof window.draw2dBridge.loadModel === "function") { window.draw2dBridge.loadModel($json); } })();');
    } catch (error, stackTrace) {
      debugPrint('Failed to push PDA model to Draw2D: $error');
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
  }

  String _escapeForJsLiteral(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  }

  _TransitionStackPayload? _parseStackPayload(Map<String, dynamic> payload) {
    final readSymbol = payload['readSymbol'] as String?;
    final popSymbol = payload['popSymbol'] as String?;
    final pushSymbol = payload['pushSymbol'] as String?;
    final isLambdaInput = payload['isLambdaInput'] as bool?;
    final isLambdaPop = payload['isLambdaPop'] as bool?;
    final isLambdaPush = payload['isLambdaPush'] as bool?;

    if (readSymbol == null &&
        popSymbol == null &&
        pushSymbol == null &&
        isLambdaInput == null &&
        isLambdaPop == null &&
        isLambdaPush == null) {
      return null;
    }

    return _TransitionStackPayload(
      readSymbol: readSymbol ?? '',
      popSymbol: popSymbol ?? '',
      pushSymbol: pushSymbol ?? '',
      isLambdaInput: isLambdaInput ?? false,
      isLambdaPop: isLambdaPop ?? false,
      isLambdaPush: isLambdaPush ?? false,
    );
  }

  String _nextStateId() {
    final pda = ref.read(pdaEditorProvider).pda;
    if (pda == null) {
      return 'q0';
    }
    final existing = pda.states.map((state) => state.id).toSet();
    var index = existing.length;
    var candidate = 'q$index';
    while (existing.contains(candidate)) {
      index++;
      candidate = 'q$index';
    }
    return candidate;
  }

  String _nextTransitionId() {
    final pda = ref.read(pdaEditorProvider).pda;
    if (pda == null) {
      return 't0';
    }
    final existing = pda.pdaTransitions.map((transition) => transition.id).toSet();
    var index = existing.length;
    var candidate = 't$index';
    while (existing.contains(candidate)) {
      index++;
      candidate = 't$index';
    }
    return candidate;
  }
}

class _PendingMove {
  const _PendingMove({
    required this.id,
    required this.x,
    required this.y,
  });

  final String id;
  final double x;
  final double y;
}

class _TransitionStackPayload {
  const _TransitionStackPayload({
    required this.readSymbol,
    required this.popSymbol,
    required this.pushSymbol,
    required this.isLambdaInput,
    required this.isLambdaPop,
    required this.isLambdaPush,
  });

  final String readSymbol;
  final String popSymbol;
  final String pushSymbol;
  final bool isLambdaInput;
  final bool isLambdaPop;
  final bool isLambdaPush;
}
