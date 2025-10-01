// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/simulation_step.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/transition.dart';
import '../../core/utils/automaton_patch.dart';

/// Web implementation of the Automaton canvas that delegates rendering and
/// interaction to the Draw2D-based JavaScript editor.
class AutomatonCanvas extends StatefulWidget {
  const AutomatonCanvas({
    super.key,
    required this.automaton,
    required this.canvasKey,
    required this.onAutomatonChanged,
    this.simulationResult,
    this.currentStepIndex,
    this.showTrace = false,
  });

  final FSA? automaton;
  final GlobalKey canvasKey;
  final ValueChanged<FSA> onAutomatonChanged;
  final SimulationResult? simulationResult;
  final int? currentStepIndex;
  final bool showTrace;

  @override
  State<AutomatonCanvas> createState() => _AutomatonCanvasWebState();
}

class _AutomatonCanvasWebState extends State<AutomatonCanvas> {
  static int _viewCounter = 0;
  static final Set<String> _registeredFactories = <String>{};

  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _messageSubscription;
  bool _isReady = false;
  bool _skipNextSync = false;
  FSA? _lastAutomaton;
  void Function(Object?)? _postMessageInterceptor;

  @override
  void initState() {
    super.initState();
    _viewType = 'draw2d-editor-${_viewCounter++}';
    _registerViewFactory();
    _messageSubscription = html.window.onMessage.listen(_handleMessage);
  }

  @override
  void didUpdateWidget(covariant AutomatonCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final automatonChanged = widget.automaton != oldWidget.automaton;
    final traceChanged = widget.simulationResult != oldWidget.simulationResult ||
        widget.currentStepIndex != oldWidget.currentStepIndex ||
        widget.showTrace != oldWidget.showTrace;

    if (automatonChanged || traceChanged) {
      if (_skipNextSync) {
        _skipNextSync = false;
        _lastAutomaton = widget.automaton;
      } else {
        _postAutomaton();
      }
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _iframe = null;
    super.dispose();
  }

  void _registerViewFactory() {
    if (_registeredFactories.contains(_viewType)) {
      return;
    }

    ui.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = html.IFrameElement()
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..src = 'assets/draw2d/editor.html'
        ..allowFullscreen = false;
      _iframe = iframe;
      return iframe;
    });

    _registeredFactories.add(_viewType);
  }

  void _handleMessage(html.MessageEvent event) {
    final data = _coerceMap(event.data);
    final dynamic typeValue = data?['type'];
    final String? messageType = typeValue is String ? typeValue : null;

    if (messageType == 'highlight' || messageType == 'clear_highlight') {
      _postMessage(event.data);
      return;
    }

    if (event.source != _iframe?.contentWindow) {
      return;
    }

    if (data == null) {
      return;
    }

    switch (messageType) {
      case 'editor_ready':
        if (!_isReady) {
          setState(() {
            _isReady = true;
          });
        }
        _postAutomaton(force: true);
        break;
      case 'patch':
        final payload = _coerceMap(data['payload']);
        if (payload != null) {
          _applyPatchFromWeb(payload);
        }
        break;
      case 'viewport_patch':
        final payload = _coerceMap(data['payload']);
        if (payload != null) {
          _applyPatchFromWeb({'viewport': payload});
        }
        break;
      case 'request_automaton':
        _postAutomaton(force: true);
        break;
      case 'label_edited':
        final payload = _coerceMap(data['payload']);
        if (payload != null) {
          debugPrint('[Draw2D] label edited: $payload');
        }
        break;
      case 'log':
        final message = data['payload']?.toString();
        if (message != null && message.isNotEmpty) {
          debugPrint('[Draw2D] $message');
        }
        break;
    }
  }

  Map<String, dynamic>? _coerceMap(dynamic value) {
    if (value is Map) {
      return value.map((key, dynamic entry) => MapEntry(key.toString(), entry));
    }
    return null;
  }

  void _applyPatchFromWeb(Map<String, dynamic> payload) {
    final base = widget.automaton ?? _lastAutomaton;
    if (base == null) {
      return;
    }

    try {
      final updated = applyAutomatonPatchToFsa(base, payload);
      _lastAutomaton = updated;
      _skipNextSync = true;
      widget.onAutomatonChanged(updated);
    } catch (error, stackTrace) {
      debugPrint('Failed to apply automaton patch: $error');
      debugPrint('$stackTrace');
    }
  }

  void _postAutomaton({bool force = false}) {
    if (!_isReady) {
      return;
    }

    final automaton = widget.automaton;
    if (!_skipNextSync && !force && identical(automaton, _lastAutomaton)) {
      return;
    }

    if (_skipNextSync && !force) {
      _skipNextSync = false;
      _lastAutomaton = automaton;
      return;
    }

    if (automaton == null) {
      _postMessage({'type': 'clear_automaton'});
      _lastAutomaton = null;
      return;
    }

    final payload = _encodeAutomaton(automaton);
    _postMessage({'type': 'load_automaton', 'payload': payload});
    _lastAutomaton = automaton;
  }

  void _postMessage(Object? message) {
    _postMessageInterceptor?.call(message);
    final target = _iframe?.contentWindow;
    if (target == null) {
      return;
    }
    target.postMessage(message, '*');
  }

  @visibleForTesting
  void debugInterceptPostMessage(void Function(Object?)? interceptor) {
    _postMessageInterceptor = interceptor;
  }

  Map<String, dynamic> _encodeAutomaton(FSA automaton) {
    final states = automaton.states.map((state) {
      return {
        'id': state.id,
        'label': state.label,
        'x': state.position.x,
        'y': state.position.y,
        'isInitial': state.isInitial,
        'isAccepting': state.isAccepting,
      };
    }).toList();

    final transitions = automaton.transitions
        .whereType<FSATransition>()
        .map((transition) {
      return {
        'id': transition.id,
        'from': transition.fromState.id,
        'to': transition.toState.id,
        'symbols': transition.inputSymbols.toList(),
        if (transition.lambdaSymbol != null)
          'lambdaSymbol': transition.lambdaSymbol,
        'label': transition.label,
        'controlPoint': {
          'x': transition.controlPoint.x,
          'y': transition.controlPoint.y,
        },
      };
    }).toList();

    final payload = <String, dynamic>{
      'id': automaton.id,
      'name': automaton.name,
      'states': states,
      'transitions': transitions,
      'alphabet': automaton.alphabet.toList(),
      'initialId': automaton.initialState?.id,
      'acceptingIds':
          automaton.acceptingStates.map((state) => state.id).toList(),
      'viewport': {
        'pan': {
          'x': automaton.panOffset.x,
          'y': automaton.panOffset.y,
        },
        'zoom': automaton.zoomLevel,
      },
      'timestamp': automaton.modified.toIso8601String(),
    };

    if (widget.showTrace && widget.simulationResult != null) {
      payload['trace'] = _encodeTrace(
        widget.simulationResult!,
        widget.currentStepIndex,
      );
    }

    return payload;
  }

  Map<String, dynamic> _encodeTrace(
    SimulationResult result,
    int? activeStepIndex,
  ) {
    final steps = <Map<String, dynamic>>[];
    for (var i = 0; i < result.steps.length; i++) {
      final SimulationStep step = result.steps[i];
      steps.add({
        'index': i,
        'state': step.currentState,
        'usedTransition': step.usedTransition,
        'isActive': activeStepIndex != null
            ? activeStepIndex == i
            : i == result.steps.length - 1,
      });
    }

    return {
      'accepted': result.accepted,
      'steps': steps,
      'currentIndex':
          activeStepIndex ?? (result.steps.isEmpty ? 0 : result.steps.length - 1),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: widget.canvasKey,
      children: [
        Positioned.fill(
          child: HtmlElementView(viewType: _viewType),
        ),
        if (!_isReady)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.transparent,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// Stub painter used for API compatibility with the mobile/desktop canvas.
class AutomatonPainter extends CustomPainter {
  AutomatonPainter({
    required this.states,
    required this.transitions,
    this.selectedState,
    this.transitionStart,
    this.transitionPreviewPosition,
    this.simulationResult,
    this.currentStepIndex,
    this.showTrace = false,
    this.surfaceColor,
  });

  final List<automaton_state.State> states;
  final List<Transition> transitions;
  final automaton_state.State? selectedState;
  final automaton_state.State? transitionStart;
  final Offset? transitionPreviewPosition;
  final SimulationResult? simulationResult;
  final int? currentStepIndex;
  final bool showTrace;
  final Color? surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Rendering handled by the embedded HTML editor.
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
