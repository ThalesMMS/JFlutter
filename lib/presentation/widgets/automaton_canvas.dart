import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../../core/models/fsa.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/fsa_transition.dart';
import 'touch_gesture_handler.dart';
import 'mobile_automaton_controls.dart';
import 'transition_geometry.dart';

/// Interactive canvas for drawing and editing automata
class AutomatonCanvas extends StatefulWidget {
  final FSA? automaton;
  final GlobalKey canvasKey;
  final ValueChanged<FSA> onAutomatonChanged;

  const AutomatonCanvas({
    super.key,
    required this.automaton,
    required this.canvasKey,
    required this.onAutomatonChanged,
  });

  @override
  State<AutomatonCanvas> createState() => _AutomatonCanvasState();
}

class _AutomatonCanvasState extends State<AutomatonCanvas> {
  final List<automaton_state.State> _states = [];
  final List<FSATransition> _transitions = [];
  automaton_state.State? _selectedState;
  bool _isAddingState = false;
  bool _isAddingTransition = false;
  automaton_state.State? _transitionStart;
  Offset? _transitionPreviewPosition;

  @override
  void initState() {
    super.initState();
    _loadAutomaton();
  }

  @override
  void didUpdateWidget(AutomatonCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.automaton != widget.automaton) {
      _loadAutomaton();
    }
  }

  void _loadAutomaton() {
    if (widget.automaton != null) {
      setState(() {
        _states.clear();
        _transitions.clear();
        _states.addAll(widget.automaton!.states);
        _transitions.addAll(widget.automaton!.transitions.cast<FSATransition>());
      });
    } else {
      setState(() {
        _states.clear();
        _transitions.clear();
      });
    }
  }

  void _onCanvasTap(TapDownDetails details) {
    final position = details.localPosition;
    
    if (_isAddingState) {
      _addState(position);
    } else if (_isAddingTransition) {
      _handleTransitionTap(position);
    } else {
      _selectStateAt(position);
    }
  }

  void _enableStateAdding() {
    setState(() {
      _isAddingState = true;
      _isAddingTransition = false;
      _selectedState = null;
    });
  }

  void _addStateAtCenter() {
    // Add state at a reasonable position in the canvas
    // Use a fixed center position that works for most screen sizes
    final canvasCenter = const Offset(200, 150);

    // Check if there's already a state at this position and offset if needed
    Offset position = canvasCenter;
    int attempts = 0;
    while (attempts < 10) {
      bool hasConflict = false;
      for (final state in _states) {
        if ((Offset(state.position.x, state.position.y) - position).distance < 60) {
          hasConflict = true;
          break;
        }
      }

      if (!hasConflict) break;

      // Offset position in a spiral pattern
      position = Offset(
        canvasCenter.dx + (attempts * 30) * math.cos(attempts * 0.8),
        canvasCenter.dy + (attempts * 30) * math.sin(attempts * 0.8),
      );
      attempts++;
    }

    _addState(position);
  }

  void _enableTransitionAdding() {
    setState(() {
      _isAddingTransition = true;
      _isAddingState = false;
      _transitionPreviewPosition = null;
      _transitionStart = _selectedState;
    });
  }

  void _addState(Offset position) {
    final newState = automaton_state.State(
      id: 'q${_states.length}',
      label: 'q${_states.length}',
      position: Vector2(position.dx, position.dy),
      isInitial: _states.isEmpty,
      isAccepting: false,
    );
    
    setState(() {
      _states.add(newState);
      _isAddingState = false;
    });
    
    _notifyAutomatonChanged();
  }

  void _editState(automaton_state.State state) {
    showDialog(
      context: context,
      builder: (context) => _StateEditDialog(
        state: state,
        onStateUpdated: (updatedState) {
          setState(() {
            final index = _states.indexWhere((s) => s.id == state.id);
            if (index != -1) {
              _states[index] = updatedState;
              if (updatedState.isInitial) {
                for (var i = 0; i < _states.length; i++) {
                  if (i == index) continue;
                  final current = _states[i];
                  if (current.isInitial) {
                    _states[i] = current.copyWith(isInitial: false);
                  }
                }
              }
            }
          });
          _notifyAutomatonChanged();
        },
      ),
    );
  }

  void _selectStateAt(Offset position) {
    automaton_state.State? foundState;
    for (final state in _states.reversed) {
      if (_isPointInState(position, state)) {
        foundState = state;
        break;
      }
    }
    
    setState(() {
      _selectedState = foundState;
    });
  }

  void _handleTransitionTap(Offset position) {
    automaton_state.State? tappedState;
    for (final state in _states.reversed) {
      if (_isPointInState(position, state)) {
        tappedState = state;
        break;
      }
    }

    if (tappedState == null) {
      if (_transitionStart != null) {
        _updateTransitionPreview(position);
      }
      return;
    }

    if (_transitionStart == null) {
      setState(() {
        _transitionStart = tappedState;
        _transitionPreviewPosition = position;
      });
      return;
    }

    unawaited(_completeTransitionAddition(_transitionStart!, tappedState));
  }

  void _updateTransitionPreview(Offset? position) {
    if (_transitionStart == null) {
      if (_transitionPreviewPosition != null) {
        setState(() {
          _transitionPreviewPosition = null;
        });
      }
      return;
    }

    if (_transitionPreviewPosition != position) {
      setState(() {
        _transitionPreviewPosition = position;
      });
    }
  }

  Future<void> _completeTransitionAddition(
    automaton_state.State from,
    automaton_state.State to,
  ) async {
    await _addTransition(from, to);
    setState(() {
      _transitionStart = null;
      _transitionPreviewPosition = null;
      _isAddingTransition = false;
    });
  }

  void _handleTransitionDragOriginChanged(automaton_state.State? state) {
    if (!_isAddingTransition) {
      return;
    }

    if (state == null) {
      if (_transitionStart != null || _transitionPreviewPosition != null) {
        setState(() {
          _transitionStart = null;
          _transitionPreviewPosition = null;
        });
      }
      return;
    }

    if (_transitionStart != state) {
      setState(() {
        _transitionStart = state;
      });
    }
  }

  void _handleTransitionDragPreviewChanged(Offset? position) {
    if (!_isAddingTransition) {
      return;
    }
    _updateTransitionPreview(position);
  }

  void _handleTransitionGestureAdded(
    automaton_state.State from,
    automaton_state.State to,
  ) {
    if (!_isAddingTransition) {
      return;
    }
    unawaited(_completeTransitionAddition(from, to));
  }

  Future<void> _addTransition(
    automaton_state.State from,
    automaton_state.State to,
  ) async {
    final symbolInput = await _showSymbolDialog();
    if (symbolInput == null) {
      return;
    }

    final transition = FSATransition(
      id: 't${_transitions.length + 1}',
      fromState: from,
      toState: to,
      label: symbolInput.label,
      inputSymbols: symbolInput.inputSymbols,
      lambdaSymbol: symbolInput.lambdaSymbol,
    );

    setState(() {
      _transitions.add(transition);
    });

    _notifyAutomatonChanged();
  }

  Future<_TransitionSymbolInput?> _showSymbolDialog({FSATransition? transition}) async {
    final existingSymbols = transition?.lambdaSymbol != null
        ? 'ε'
        : transition?.inputSymbols.join(', ') ?? '';
    final controller = TextEditingController(text: existingSymbols);
    final result = await showDialog<_TransitionSymbolInput>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(transition == null ? 'Transition Symbols' : 'Edit Transition'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter symbols separated by commas or ε for epsilon'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Symbols',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = _TransitionSymbolInput.parse(controller.text);
                if (parsed == null) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _editTransition(FSATransition transition) async {
    final symbolInput = await _showSymbolDialog(transition: transition);
    if (symbolInput == null) {
      return;
    }

    setState(() {
      final index = _transitions.indexWhere((t) => t.id == transition.id);
      if (index != -1) {
        _transitions[index] = transition.copyWith(
          label: symbolInput.label,
          inputSymbols: symbolInput.inputSymbols,
          lambdaSymbol: symbolInput.lambdaSymbol,
        );
      }
    });

    _notifyAutomatonChanged();
  }

  bool _isPointInState(Offset point, automaton_state.State state) {
    final distance = (point - Offset(state.position.x, state.position.y)).distance;
    return distance <= 30; // State radius
  }

  void _notifyAutomatonChanged() {
    if (widget.automaton != null) {
      automaton_state.State? initialState;
      for (final state in _states) {
        if (state.isInitial) {
          initialState = state;
          break;
        }
      }
      final acceptingStates =
          _states.where((state) => state.isAccepting).toSet();
      final updatedAutomaton = widget.automaton!.copyWith(
        states: _states.toSet(),
        transitions: _transitions.toSet(),
        initialState: initialState,
        acceptingStates: acceptingStates,
      );
      widget.onAutomatonChanged(updatedAutomaton);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: borderRadius,
      ),
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTapDown: (_isAddingState || _isAddingTransition)
                ? _onCanvasTap
                : null,
            child: ClipRRect(
              borderRadius: borderRadius,
              child: TouchGestureHandler<FSATransition>(
                states: _states,
                transitions: _transitions,
                selectedState: _selectedState,
                onStateSelected: (state) {
                  setState(() {
                    _selectedState = state;
                  });
                },
                onStateMoved: (state) {
                  setState(() {
                    final index = _states.indexWhere((s) => s.id == state.id);
                    if (index != -1) {
                      _states[index] = state;
                    }
                  });
                  _notifyAutomatonChanged();
                },
                onStateAdded: (position) {
                  _addState(position);
                },
                onTransitionAdded: _handleTransitionGestureAdded,
                onStateEdited: (state) {
                  _editState(state);
                },
                onStateDeleted: (state) {
                  setState(() {
                    _states.removeWhere((s) => s.id == state.id);
                    _transitions.removeWhere((t) =>
                        t.fromState.id == state.id || t.toState.id == state.id);
                    if (_selectedState?.id == state.id) {
                      _selectedState = null;
                    }
                  });
                  _notifyAutomatonChanged();
                },
                onTransitionDeleted: (transition) {
                  setState(() {
                    _transitions.removeWhere((t) => t.id == transition.id);
                  });
                  _notifyAutomatonChanged();
                },
                onTransitionEdited: (transition) {
                  _editTransition(transition);
                },
                isAddingTransition: _isAddingTransition,
                onTransitionOriginChanged: _handleTransitionDragOriginChanged,
                onTransitionPreviewChanged: _handleTransitionDragPreviewChanged,
                child: MouseRegion(
                  onExit: (_) {
                    _updateTransitionPreview(null);
                  },
                  child: Listener(
                    onPointerHover: (event) =>
                        _updateTransitionPreview(event.localPosition),
                    onPointerMove: (event) =>
                        _updateTransitionPreview(event.localPosition),
                    onPointerDown: (event) =>
                        _updateTransitionPreview(event.localPosition),
                    onPointerUp: (_) => _updateTransitionPreview(null),
                    onPointerCancel: (_) => _updateTransitionPreview(null),
                    child: CustomPaint(
                      painter: AutomatonPainter(
                        states: _states,
                        transitions: _transitions,
                        selectedState: _selectedState,
                        transitionStart: _transitionStart,
                        transitionPreviewPosition: _transitionPreviewPosition,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Canvas controls
          Positioned(
            top: 8,
            right: 8,
            child: _buildCanvasControls(context),
          ),
          // Empty state message
          if (_states.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_tree,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Empty Canvas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add State" to create your first state',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCanvasControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _addStateAtCenter,
            icon: const Icon(Icons.add_circle),
            tooltip: 'Add State',
            color: _isAddingState ? Theme.of(context).colorScheme.primary : null,
          ),
          IconButton(
            onPressed: _enableTransitionAdding,
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Add Transition',
            color: _isAddingTransition ? Theme.of(context).colorScheme.primary : null,
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isAddingState = false;
                _isAddingTransition = false;
                _selectedState = null;
                _transitionStart = null;
              });
            },
            icon: const Icon(Icons.cancel),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }
}

class AutomatonPainter extends CustomPainter {
  final List<automaton_state.State> states;
  final List<FSATransition> transitions;
  final automaton_state.State? selectedState;
  final automaton_state.State? transitionStart;
  final Offset? transitionPreviewPosition;
  final double stateRadius;

  AutomatonPainter({
    required this.states,
    required this.transitions,
    required this.selectedState,
    required this.transitionStart,
    required this.transitionPreviewPosition,
    this.stateRadius = 30,
  });

  static const double _selfLoopBaseRadius = 40;
  static const double _selfLoopSpacing = 12;

  @override
  void paint(Canvas canvas, Size size) {
    _drawTransitions(canvas);
    _drawInitialArrows(canvas);
    _drawTransitionPreview(canvas);
    _drawStates(canvas);
  }

  void _drawTransitions(Canvas canvas) {
    for (final transition in transitions) {
      if (transition.fromState.id == transition.toState.id) {
        _drawSelfLoop(canvas, transition);
      } else {
        _drawDirectedTransition(canvas, transition);
      }
    }
  }

  void _drawDirectedTransition(Canvas canvas, FSATransition transition) {
    final geometry = TransitionCurve.compute(
      transitions,
      transition,
      stateRadius: stateRadius,
    );

    final path = Path()
      ..moveTo(geometry.start.dx, geometry.start.dy)
      ..quadraticBezierTo(
        geometry.control.dx,
        geometry.control.dy,
        geometry.end.dx,
        geometry.end.dy,
      );

    final paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
    _drawArrowhead(canvas, geometry.end, geometry.tangentAngle, paint.color);
    _drawTransitionLabel(canvas, transition, geometry.labelPosition);
  }

  void _drawSelfLoop(Canvas canvas, FSATransition transition) {
    final center = Offset(
      transition.fromState.position.x,
      transition.fromState.position.y,
    );

    final selfLoops = transitions
        .where((t) =>
            t.fromState.id == transition.fromState.id &&
            t.toState.id == transition.toState.id)
        .toList();
    final loopIndex = selfLoops.indexOf(transition);
    final loopRadius =
        _selfLoopBaseRadius + loopIndex * _selfLoopSpacing;

    const startAngle = -3 * math.pi / 4; // Start near top-left
    const sweepAngle = 1.5 * math.pi; // 270 degrees sweep
    final loopCenter = center + Offset(0, -loopRadius);
    final rect = Rect.fromCircle(center: loopCenter, radius: loopRadius);

    final paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final path = Path()..addArc(rect, startAngle, sweepAngle);
    canvas.drawPath(path, paint);

    final endAngle = startAngle + sweepAngle;
    final endPoint = Offset(
      loopCenter.dx + loopRadius * math.cos(endAngle),
      loopCenter.dy + loopRadius * math.sin(endAngle),
    );

    // For a circle, tangent angle is perpendicular to radius.
    final tangentAngle = endAngle + math.pi / 2;
    _drawArrowhead(canvas, endPoint, tangentAngle, paint.color);

    final labelAngle = startAngle + sweepAngle / 2;
    final labelPoint = Offset(
      loopCenter.dx + loopRadius * math.cos(labelAngle),
      loopCenter.dy + loopRadius * math.sin(labelAngle),
    );
    final offsetDirection = Offset(
      math.cos(labelAngle),
      math.sin(labelAngle),
    );
    final labelPosition = labelPoint + offsetDirection * 16;
    _drawTransitionLabel(canvas, transition, labelPosition);
  }

  void _drawTransitionLabel(
    Canvas canvas,
    FSATransition transition,
    Offset position,
  ) {
    final label = _formatTransitionLabel(transition);
    if (label.isEmpty) {
      return;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )
      ..layout();

    final offset = position - Offset(textPainter.width / 2, textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  String _formatTransitionLabel(FSATransition transition) {
    if (transition.lambdaSymbol != null) {
      return transition.lambdaSymbol!;
    }

    if (transition.label.isNotEmpty) {
      return transition.label;
    }

    if (transition.inputSymbols.isNotEmpty) {
      return transition.inputSymbols.join(', ');
    }

    return '';
  }

  void _drawArrowhead(
    Canvas canvas,
    Offset tip,
    double angle,
    Color color,
  ) {
    const double arrowLength = 12;
    const double arrowAngle = math.pi / 7;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowLength * math.cos(angle - arrowAngle),
        tip.dy - arrowLength * math.sin(angle - arrowAngle),
      )
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowLength * math.cos(angle + arrowAngle),
        tip.dy - arrowLength * math.sin(angle + arrowAngle),
      );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  void _drawInitialArrows(Canvas canvas) {
    for (final state in states.where((s) => s.isInitial)) {
      final center = Offset(state.position.x, state.position.y);
      final start = center - Offset(stateRadius + 30, 0);
      final end = center - Offset(stateRadius, 0);

      final paint = Paint()
        ..color = Colors.blueGrey
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawLine(start, end, paint);
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      _drawArrowhead(canvas, end, angle, paint.color);
    }
  }

  void _drawTransitionPreview(Canvas canvas) {
    if (transitionStart == null || transitionPreviewPosition == null) {
      return;
    }

    final startCenter = Offset(
      transitionStart!.position.x,
      transitionStart!.position.y,
    );
    final preview = transitionPreviewPosition!;
    final direction = preview - startCenter;
    if (direction.distance <= 1) {
      return;
    }

    final unit = Offset(
      direction.dx / direction.distance,
      direction.dy / direction.distance,
    );
    final start = startCenter + unit * stateRadius;
    final end = preview;

    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);
    final angle = math.atan2(direction.dy, direction.dx);
    _drawArrowhead(canvas, end, angle, paint.color);
  }

  void _drawStates(Canvas canvas) {
    for (final state in states) {
      final center = Offset(state.position.x, state.position.y);

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center + const Offset(2, 2), stateRadius, shadowPaint);

      final fillPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final borderPaint = Paint()
        ..color = selectedState?.id == state.id
            ? Colors.blueAccent
            : Colors.grey[800]!
        ..strokeWidth = selectedState?.id == state.id ? 3 : 2
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawCircle(center, stateRadius, fillPaint);
      canvas.drawCircle(center, stateRadius, borderPaint);

      if (state.isAccepting) {
        final acceptingPaint = Paint()
          ..color = borderPaint.color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;
        canvas.drawCircle(center, stateRadius - 6, acceptingPaint);
      }

      final label = state.label.isNotEmpty ? state.label : state.id;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: 2,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: stateRadius * 1.8);

      final textOffset = center -
          Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant AutomatonPainter oldDelegate) {
    return !listEquals(oldDelegate.states, states) ||
        !listEquals(oldDelegate.transitions, transitions) ||
        oldDelegate.selectedState?.id != selectedState?.id ||
        oldDelegate.transitionStart?.id != transitionStart?.id ||
        oldDelegate.transitionPreviewPosition != transitionPreviewPosition ||
        oldDelegate.stateRadius != stateRadius;
  }
}

class _StateEditDialog extends StatefulWidget {
  final automaton_state.State state;
  final ValueChanged<automaton_state.State> onStateUpdated;

  const _StateEditDialog({
    required this.state,
    required this.onStateUpdated,
  });

  @override
  State<_StateEditDialog> createState() => _StateEditDialogState();
}

class _StateEditDialogState extends State<_StateEditDialog> {
  late TextEditingController _nameController;
  late bool _isInitial;
  late bool _isAccepting;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.label);
    _isInitial = widget.state.isInitial;
    _isAccepting = widget.state.isAccepting;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit State'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'State name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Initial state'),
              value: _isInitial,
              onChanged: (value) =>
                  setState(() => _isInitial = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Accepting state'),
              value: _isAccepting,
              onChanged: (value) =>
                  setState(() => _isAccepting = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveState,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveState() {
    final updated = widget.state.copyWith(
      label: _nameController.text.trim().isEmpty
          ? widget.state.id
          : _nameController.text.trim(),
      isInitial: _isInitial,
      isAccepting: _isAccepting,
    );

    widget.onStateUpdated(updated);
    Navigator.of(context).pop();
  }
}

class _TransitionSymbolInput {
  final String label;
  final Set<String> inputSymbols;
  final String? lambdaSymbol;

  const _TransitionSymbolInput({
    required this.label,
    required this.inputSymbols,
    required this.lambdaSymbol,
  });

  static _TransitionSymbolInput? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return null;
    }

    final tokens = text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return null;
    }

    bool containsEpsilon = false;
    final orderedSymbols = <String>[];

    for (final token in tokens) {
      if (_isEpsilonToken(token)) {
        containsEpsilon = true;
      } else {
        orderedSymbols.add(token);
      }
    }

    if (containsEpsilon && orderedSymbols.isEmpty) {
      return const _TransitionSymbolInput(
        label: 'ε',
        inputSymbols: {},
        lambdaSymbol: 'ε',
      );
    }

    if (orderedSymbols.isEmpty) {
      return null;
    }

    final uniqueSymbols = <String>{};
    final preservedOrder = <String>[];
    for (final symbol in orderedSymbols) {
      if (uniqueSymbols.add(symbol)) {
        preservedOrder.add(symbol);
      }
    }

    final label = preservedOrder.join(', ');
    return _TransitionSymbolInput(
      label: label,
      inputSymbols: uniqueSymbols,
      lambdaSymbol: null,
    );
  }

  static bool _isEpsilonToken(String token) {
    final normalized = token.toLowerCase();
    return normalized == 'ε' ||
        normalized == 'epsilon' ||
        normalized == 'eps' ||
        normalized == 'lambda';
  }
}
