import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/services/draw2d_bridge_service.dart';
import '../mappers/draw2d_automaton_mapper.dart';
import '../providers/automaton_provider.dart';
import 'draw2d_canvas_fallback.dart';
import 'draw2d_platform_support.dart';

/// Draw2D canvas embedded through a WebView that synchronises with the
/// Riverpod automaton state and forwards user interactions back to Flutter.
class Draw2DCanvasView extends ConsumerStatefulWidget {
  const Draw2DCanvasView({super.key});

  @override
  ConsumerState<Draw2DCanvasView> createState() => _Draw2DCanvasViewState();
}

class _Draw2DCanvasViewState extends ConsumerState<Draw2DCanvasView> {
  WebViewController? _controller;
  final Draw2DBridgeService _bridge = Draw2DBridgeService();
  ProviderSubscription<AutomatonState>? _subscription;
  bool _isReady = false;
  Timer? _moveDebounce;
  final Map<String, _PendingMove> _pendingMoves = {};

  @override
  void initState() {
    super.initState();
    if (!_isPlatformSupported) {
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000)) // Use transparent color without Colors.transparent
      ..enableZoom(false)
      ..addJavaScriptChannel(
        'JFlutterBridge',
        onMessageReceived: _handleMessage,
      )
      ..addJavaScriptChannel(
        'Alert',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('[Draw2D][Alert] ${message.message}');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(),
      )
        ..loadFlutterAsset('assets/draw2d/editor.html');

    _controller = controller;

    _bridge.registerWebViewController(controller);

    _subscription = ref.listenManual<AutomatonState>(automatonProvider, (
      previous,
      next,
    ) {
      if (!_isReady) {
        return;
      }
      if (previous?.currentAutomaton == next.currentAutomaton) {
        return;
      }
      _pushModel(next);
    });
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
      debugPrint('Failed to decode bridge message: $error');
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
        _pushModel(ref.read(automatonProvider));
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
        _handleTransitionLabel(payload);
        break;
      case 'transition.remove':
        _handleTransitionRemove(payload);
        break;
      case 'log':
        _handleWebLog(payload);
        break;
      default:
        debugPrint('Unhandled Draw2D event: $type');
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
    final notifier = ref.read(automatonProvider.notifier);
    final id = payload['id'] as String? ?? _nextStateId();
    final label = payload['label'] as String? ?? id;
    final x = (payload['x'] as num?)?.toDouble();
    final y = (payload['y'] as num?)?.toDouble();
    if (x == null || y == null) {
      return;
    }
    notifier.addState(id: id, label: label, x: x, y: y);
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
    ref.read(automatonProvider.notifier).updateStateLabel(id: id, label: label);
  }

  void _handleStateFlags(Map<String, dynamic> payload) {
    final id = payload['id'] as String?;
    if (id == null) {
      return;
    }

    final bool? isInitial = payload.containsKey('isInitial')
        ? payload['isInitial'] as bool?
        : null;
    final bool? isAccepting = payload.containsKey('isAccepting')
        ? payload['isAccepting'] as bool?
        : null;

    if (isInitial == null && isAccepting == null) {
      return;
    }

    ref
        .read(automatonProvider.notifier)
        .updateStateFlags(
          id: id,
          isInitial: isInitial,
          isAccepting: isAccepting,
        );
  }

  void _handleStateRemove(Map<String, dynamic> payload) {
    final id = payload['id'] as String?;
    if (id == null) {
      return;
    }
    ref.read(automatonProvider.notifier).removeState(id: id);
  }

  void _handleTransitionAdd(Map<String, dynamic> payload) {
    final id = payload['id'] as String? ?? _nextTransitionId();
    final from = payload['fromStateId'] as String?;
    final to = payload['toStateId'] as String?;
    final label = payload['label'] as String? ?? '';
    if (from == null || to == null) {
      return;
    }
    ref
        .read(automatonProvider.notifier)
        .addOrUpdateTransition(
          id: id,
          fromStateId: from,
          toStateId: to,
          label: label,
        );
  }

  void _handleTransitionLabel(Map<String, dynamic> payload) {
    final id = payload['id'] as String?;
    final label = payload['label'] as String?;
    if (id == null || label == null) {
      return;
    }
    ref
        .read(automatonProvider.notifier)
        .updateTransitionLabel(id: id, label: label);
  }

  void _handleTransitionRemove(Map<String, dynamic> payload) {
    final id = payload['id'] as String?;
    if (id == null) {
      return;
    }
    ref.read(automatonProvider.notifier).removeTransition(id: id);
  }

  void _flushMoves() {
    final notifier = ref.read(automatonProvider.notifier);
    for (final move in _pendingMoves.values) {
      notifier.moveState(id: move.id, x: move.x, y: move.y);
    }
    _pendingMoves.clear();
    _moveDebounce?.cancel();
    _moveDebounce = null;
  }

  Future<void> _pushModel(AutomatonState state) async {
    final payload = Draw2DAutomatonMapper.toJson(state.currentAutomaton);
    final json = _escapeForJsLiteral(jsonEncode(payload));
    final controller = _controller;
    if (controller == null) {
      return;
    }
    try {
      await controller.runJavaScript(
        '(() => { if (window.draw2dBridge && typeof window.draw2dBridge.loadModel === "function") { window.draw2dBridge.loadModel($json); } })();',
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to push Draw2D model: $error');
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
  }

  String _escapeForJsLiteral(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  }

  String _nextStateId() {
    final automaton = ref.read(automatonProvider).currentAutomaton;
    if (automaton == null) {
      return 'q0';
    }
    final existing = automaton.states.map((state) => state.id).toSet();
    var index = existing.length;
    String candidate = 'q$index';
    while (existing.contains(candidate)) {
      index++;
      candidate = 'q$index';
    }
    return candidate;
  }

  String _nextTransitionId() {
    final automaton = ref.read(automatonProvider).currentAutomaton;
    if (automaton == null) {
      return 't0';
    }
    final existing = automaton.transitions
        .map((transition) => transition.id)
        .toSet();
    var index = existing.length;
    String candidate = 't$index';
    while (existing.contains(candidate)) {
      index++;
      candidate = 't$index';
    }
    return candidate;
  }
}

class _PendingMove {
  const _PendingMove({required this.id, required this.x, required this.y});

  final String id;
  final double x;
  final double y;
}
