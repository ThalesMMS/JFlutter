import 'dart:math' as math;
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
      _selectedState = null;
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
    if (_transitionStart == null) {
      // Start transition
      for (final state in _states.reversed) {
        if (_isPointInState(position, state)) {
          setState(() {
            _transitionStart = state;
          });
          break;
        }
      }
    } else {
      // End transition
      for (final state in _states.reversed) {
        if (_isPointInState(position, state) && state != _transitionStart) {
          _addTransition(_transitionStart!, state);
          break;
        }
      }
      setState(() {
        _transitionStart = null;
        _isAddingTransition = false;
      });
    }
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

  Future<_TransitionSymbolInput?> _showSymbolDialog({FSATransition? transition}) {
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
      final updatedAutomaton = widget.automaton!.copyWith(
        states: _states.toSet(),
        transitions: _transitions.toSet(),
      );
      widget.onAutomatonChanged(updatedAutomaton);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          TouchGestureHandler<FSATransition>(
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
            onTransitionAdded: (transition) {
              setState(() {
                _transitions.add(transition);
              });
              _notifyAutomatonChanged();
            },
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
            child: CustomPaint(
              painter: AutomatonPainter(
                states: _states,
                transitions: _transitions,
                selectedState: _selectedState,
                transitionStart: _transitionStart,
              ),
              size: Size.infinite,
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

/// Custom painter for drawing automata
class AutomatonPainter extends CustomPainter {
  final List<automaton_state.State> states;
  final List<FSATransition> transitions;
  final automaton_state.State? selectedState;
  final automaton_state.State? transitionStart;

  AutomatonPainter({
    required this.states,
    required this.transitions,
    this.selectedState,
    this.transitionStart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw transitions
    for (final transition in transitions) {
      _drawTransition(canvas, transition, paint);
    }

    // Draw states
    for (final state in states) {
      _drawState(canvas, state as automaton_state.State, paint);
    }

    // Draw transition preview if in progress
    if (transitionStart != null) {
      _drawTransitionPreview(canvas, transitionStart! as automaton_state.State, paint);
    }
  }

  void _drawState(Canvas canvas, automaton_state.State state, Paint paint) {
    final center = state.position;
    final radius = 30.0;
    
    // State circle
    paint.color = state == selectedState ? Colors.blue : Colors.black;
    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(center.x, center.y), radius, paint);
    
    // Fill for accepting states
    if (state.isAccepting) {
      paint.color = Colors.green.withOpacity(0.3);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.x, center.y), radius - 2, paint);
    }
    
    // Initial state arrow
    if (state.isInitial) {
      _drawInitialArrow(canvas, Offset(center.x, center.y), paint);
    }
    
    // State label
    final textPainter = TextPainter(
      text: TextSpan(
        text: state.name,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.x - textPainter.width / 2,
        center.y - textPainter.height / 2,
      ),
    );
  }

  void _drawTransition(Canvas canvas, FSATransition transition, Paint paint) {
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;

    if (transition.fromState == transition.toState) {
      _drawSelfLoop(canvas, transition, paint);
      return;
    }

    final curve = TransitionCurve.compute(
      transitions,
      transition,
      stateRadius: 30,
    );

    final path = Path()
      ..moveTo(curve.start.dx, curve.start.dy)
      ..quadraticBezierTo(
        curve.control.dx,
        curve.control.dy,
        curve.end.dx,
        curve.end.dy,
      );
    canvas.drawPath(path, paint);

    _drawArrowhead(canvas, curve.end, curve.tangentAngle, paint);
    _drawTransitionLabel(canvas, curve.labelPosition, transition.label);
  }

  void _drawInitialArrow(Canvas canvas, Offset center, Paint paint) {
    final arrowStart = Offset(center.dx - 50, center.dy);
    final arrowEnd = Offset(center.dx - 30, center.dy);
    
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    
    canvas.drawLine(arrowStart, arrowEnd, paint);
    
    // Arrowhead
    final arrow1 = Offset(arrowEnd.dx - 10, arrowEnd.dy - 5);
    final arrow2 = Offset(arrowEnd.dx - 10, arrowEnd.dy + 5);
    
    canvas.drawLine(arrowEnd, arrow1, paint);
    canvas.drawLine(arrowEnd, arrow2, paint);
  }

  void _drawTransitionPreview(Canvas canvas, automaton_state.State start, Paint paint) {
    // TODO: Implement transition preview
  }

  void _drawSelfLoop(Canvas canvas, FSATransition transition, Paint paint) {
    final center = Offset(
      transition.fromState.position.x,
      transition.fromState.position.y,
    );
    const baseRadius = 40.0;

    final loopsForState = transitions
        .where((t) => t.fromState.id == transition.fromState.id && t.fromState == t.toState)
        .toList();
    final index = loopsForState.indexOf(transition);
    final radius = baseRadius + index * 12.0;

    final rect = Rect.fromCircle(
      center: Offset(center.dx, center.dy - radius),
      radius: radius,
    );

    const startAngle = 1.1 * math.pi;
    const sweepAngle = 1.6 * math.pi;
    final path = Path()..addArc(rect, startAngle, sweepAngle);
    canvas.drawPath(path, paint);

    final endAngle = startAngle + sweepAngle;
    final arrowPoint = Offset(
      rect.center.dx + rect.width / 2 * math.cos(endAngle),
      rect.center.dy + rect.height / 2 * math.sin(endAngle),
    );
    _drawArrowhead(canvas, arrowPoint, endAngle + math.pi / 2, paint);

    final labelPosition = Offset(
      rect.center.dx,
      rect.top - 14,
    );
    _drawTransitionLabel(canvas, labelPosition, transition.label);
  }

  void _drawArrowhead(
    Canvas canvas,
    Offset position,
    double angle,
    Paint paint,
  ) {
    const arrowLength = 12.0;
    const arrowAngle = 0.45;

    final arrow1 = Offset(
      position.dx - arrowLength * math.cos(angle - arrowAngle),
      position.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    final arrow2 = Offset(
      position.dx - arrowLength * math.cos(angle + arrowAngle),
      position.dy - arrowLength * math.sin(angle + arrowAngle),
    );

    canvas.drawLine(position, arrow1, paint);
    canvas.drawLine(position, arrow2, paint);
  }

  void _drawTransitionLabel(Canvas canvas, Offset position, String label) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is AutomatonPainter &&
        (oldDelegate.states != states ||
            oldDelegate.transitions != transitions ||
            oldDelegate.selectedState != selectedState ||
            oldDelegate.transitionStart != transitionStart);
  }
}

/// Dialog for editing state properties
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
  late TextEditingController _labelController;
  late bool _isInitial;
  late bool _isAccepting;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.state.label);
    _isInitial = widget.state.isInitial;
    _isAccepting = widget.state.isAccepting;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit State'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'State Label',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Initial State'),
            value: _isInitial,
            onChanged: (value) {
              setState(() {
                _isInitial = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Accepting State'),
            value: _isAccepting,
            onChanged: (value) {
              setState(() {
                _isAccepting = value ?? false;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedState = widget.state.copyWith(
              label: _labelController.text,
              isInitial: _isInitial,
              isAccepting: _isAccepting,
            );
            widget.onStateUpdated(updatedState);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _TransitionSymbolInput {
  final Set<String> inputSymbols;
  final String? lambdaSymbol;
  final String label;

  const _TransitionSymbolInput({
    required this.inputSymbols,
    required this.lambdaSymbol,
    required this.label,
  });

  static _TransitionSymbolInput? parse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parts = trimmed
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return null;
    }

    if (parts.length == 1 &&
        (parts.first == 'ε' || parts.first.toLowerCase() == 'epsilon' || parts.first.toLowerCase() == 'lambda')) {
      return _TransitionSymbolInput(
        inputSymbols: {},
        lambdaSymbol: 'ε',
        label: 'ε',
      );
    }

    final symbols = parts.toSet();
    return _TransitionSymbolInput(
      inputSymbols: symbols,
      lambdaSymbol: null,
      label: symbols.join(', '),
    );
  }
}

