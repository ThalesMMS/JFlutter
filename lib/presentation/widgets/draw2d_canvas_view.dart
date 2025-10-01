import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../mappers/draw2d_automaton_mapper.dart';
import '../providers/automaton_provider.dart';

class Draw2DCanvasView extends ConsumerStatefulWidget {
  const Draw2DCanvasView({super.key});

  @override
  ConsumerState<Draw2DCanvasView> createState() => _Draw2DCanvasViewState();
}

class _Draw2DCanvasViewState extends ConsumerState<Draw2DCanvasView> {
  late final WebViewController _controller;
  ProviderSubscription<AutomatonState>? _subscription;
  bool _isReady = false;
  Timer? _moveDebounce;
  final Map<String, _PendingMove> _pendingMoves = {};

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('JFlutterBridge', onMessageReceived: _handleMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _isReady = true;
            });
            _pushModel(ref.read(automatonProvider));
          },
        ),
      )
      ..loadFlutterAsset('assets/draw2d/editor.html');

    _subscription = ref.listenManual<AutomatonState>(
      automatonProvider,
      (previous, next) {
        if (!_isReady) {
          return;
        }
        if (previous?.currentAutomaton == next.currentAutomaton) {
          return;
        }
        _pushModel(next);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    _moveDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: WebViewWidget(controller: _controller),
    );
  }

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
      case 'state.add':
        _handleStateAdd(payload);
        break;
      case 'state.move':
        _handleStateMove(payload);
        break;
      case 'state.label':
        _handleStateLabel(payload);
        break;
      case 'transition.add':
        _handleTransitionAdd(payload);
        break;
      case 'transition.label':
        _handleTransitionLabel(payload);
        break;
      default:
        debugPrint('Unhandled Draw2D event: $type');
        break;
    }
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

  void _handleTransitionAdd(Map<String, dynamic> payload) {
    final id = payload['id'] as String? ?? _nextTransitionId();
    final from = payload['fromStateId'] as String?;
    final to = payload['toStateId'] as String?;
    final label = payload['label'] as String? ?? '';
    if (from == null || to == null) {
      return;
    }
    ref.read(automatonProvider.notifier).addOrUpdateTransition(
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
    final json = jsonEncode(payload);
    try {
      await _controller.runJavaScript('window.draw2dBridge?.loadModel($json);');
    } catch (error, stackTrace) {
      debugPrint('Failed to push Draw2D model: $error');
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
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
    final existing = automaton.transitions.map((transition) => transition.id).toSet();
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
  const _PendingMove({
    required this.id,
    required this.x,
    required this.y,
  });

  final String id;
  final double x;
  final double y;
}
