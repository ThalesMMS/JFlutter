// <<<<<<< codex/document-bridge-envelope-and-message-schemas
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:jflutter/data/services/draw2d_bridge_service.dart';

/// Wraps the Draw2D editor inside a WebView and surfaces bridge callbacks.
class Draw2DCanvasView extends StatefulWidget {
  const Draw2DCanvasView({
    super.key,
    this.onNodeAdded,
    this.onNodeMoved,
    this.onEdgeAdded,
    this.onLabelEdited,
    this.onBridgeReady,
    this.onControllerReady,
    this.onBridgeError,
    this.onPageLoaded,
    BorderRadius? borderRadius,
    bool? enableDebugLogging,
  })  : borderRadius = borderRadius ?? BorderRadius.zero,
        enableDebugLogging = enableDebugLogging ?? kDebugMode;

  final Draw2DEventHandler? onNodeAdded;
  final Draw2DEventHandler? onNodeMoved;
  final Draw2DEventHandler? onEdgeAdded;
  final Draw2DEventHandler? onLabelEdited;
  final ValueChanged<Draw2DBridgeService>? onBridgeReady;
  final ValueChanged<WebViewController>? onControllerReady;
  final Draw2DBridgeErrorHandler? onBridgeError;
  final ValueChanged<String>? onPageLoaded;
  final BorderRadius borderRadius;
  final bool enableDebugLogging;

  @override
  State<Draw2DCanvasView> createState() => _Draw2DCanvasViewState();
}

class _Draw2DCanvasViewState extends State<Draw2DCanvasView> {
  late final WebViewController _controller;
  Draw2DBridgeService? _bridgeService;
  bool _pageLoaded = false;
  bool _debugTriggered = false;
// =======
import 'dart:async';
// <<<<<<< codex/add-draw2d-mapping-and-event-handling
import 'dart:convert';
// =======
import 'dart:developer' as developer;

// >>>>>>> 003-ui-improvement-taskforce
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
// <<<<<<< codex/add-draw2d-mapping-and-event-handling
import '../mappers/draw2d_automaton_mapper.dart';
import '../providers/automaton_provider.dart';

// =======

/// Temporary Draw2D prototype embedded through a WebView.
// >>>>>>> 003-ui-improvement-taskforce
class Draw2DCanvasView extends ConsumerStatefulWidget {
  const Draw2DCanvasView({super.key});

  @override
  ConsumerState<Draw2DCanvasView> createState() => _Draw2DCanvasViewState();
}

class _Draw2DCanvasViewState extends ConsumerState<Draw2DCanvasView> {
  late final WebViewController _controller;
// <<<<<<< codex/add-draw2d-mapping-and-event-handling
  ProviderSubscription<AutomatonState>? _subscription;
  bool _isReady = false;
  Timer? _moveDebounce;
  final Map<String, _PendingMove> _pendingMoves = {};
// =======
  bool _isReady = false;
// >>>>>>> 003-ui-improvement-taskforce
// >>>>>>> 003-ui-improvement-taskforce

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
// <<<<<<< codex/document-bridge-envelope-and-message-schemas
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _handlePageFinished,
        ),
      )
      ..loadFlutterAsset('assets/draw2d/index.html');

    _bridgeService = Draw2DBridgeService(
      controller: _controller,
      onNodeAdded: widget.onNodeAdded,
      onNodeMoved: widget.onNodeMoved,
      onEdgeAdded: widget.onEdgeAdded,
      onLabelEdited: widget.onLabelEdited,
      onError: widget.onBridgeError,
    );

    widget.onBridgeReady?.call(_bridgeService!);
    widget.onControllerReady?.call(_controller);
  }

  @override
  void didUpdateWidget(covariant Draw2DCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bridgeService?.updateHandlers(
      onNodeAdded: widget.onNodeAdded,
      onNodeMoved: widget.onNodeMoved,
      onEdgeAdded: widget.onEdgeAdded,
      onLabelEdited: widget.onLabelEdited,
    );

    if (widget.enableDebugLogging && !_debugTriggered && _pageLoaded) {
      _triggerDebug();
    }
  }

  Future<void> _handlePageFinished(String url) async {
    _pageLoaded = true;
    widget.onPageLoaded?.call(url);

    if (widget.enableDebugLogging && !_debugTriggered) {
      await _triggerDebug();
    }
  }

  Future<void> _triggerDebug() async {
    _debugTriggered = true;
    await _bridgeService?.sendDebugCommands();
    await _bridgeService?.triggerDebugEvents();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: WebViewWidget(controller: _controller),
    );
  }
// =======
// <<<<<<< codex/add-draw2d-mapping-and-event-handling
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
// =======
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            developer.log(
              'Draw2D asset finished loading: $url',
              name: 'Draw2DCanvasView',
            );
          },
          onWebResourceError: (error) {
            developer.log(
              'Draw2D asset failed to load',
              name: 'Draw2DCanvasView',
              error: error,
            );
          },
        ),
      )
      ..addJavaScriptChannel(
        'Draw2dReadyChannel',
        onMessageReceived: (message) {
          developer.log(
            'Draw2D ready message: ${message.message}',
            name: 'Draw2DCanvasView',
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _isReady = true;
          });
        },
      )
      ..loadFlutterAsset('assets/draw2d/index.html');
// >>>>>>> 003-ui-improvement-taskforce
  }

  @override
  void dispose() {
// <<<<<<< codex/add-draw2d-mapping-and-event-handling
    _subscription?.close();
    _moveDebounce?.cancel();
// =======
    if (!kIsWeb) {
      unawaited(_controller.clearCache());
    }
// >>>>>>> 003-ui-improvement-taskforce
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
// <<<<<<< codex/add-draw2d-mapping-and-event-handling
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
// =======
    final theme = Theme.of(context);
    final outlineColor = theme.colorScheme.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor.withOpacity(0.6)),
        color: theme.colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _isReady ? 0 : 1,
              child: Container(
                color: theme.colorScheme.surface,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
// >>>>>>> 003-ui-improvement-taskforce
// >>>>>>> 003-ui-improvement-taskforce
}
