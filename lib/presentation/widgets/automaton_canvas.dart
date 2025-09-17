import 'package:flutter/material.dart';
import '../../core/models/fsa.dart';
import '../../core/models/state.dart';
import '../../core/models/fsa_transition.dart';

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
  final List<State> _states = [];
  final List<FSATransition> _transitions = [];
  State? _selectedState;
  bool _isAddingState = false;
  bool _isAddingTransition = false;
  State? _transitionStart;

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
        _transitions.addAll(widget.automaton!.transitions);
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

  void _enableTransitionAdding() {
    setState(() {
      _isAddingTransition = true;
      _isAddingState = false;
      _selectedState = null;
    });
  }

  void _addState(Offset position) {
    final newState = State(
      id: 'q${_states.length}',
      name: 'q${_states.length}',
      position: position,
      isInitial: _states.isEmpty,
      isAccepting: false,
    );
    
    setState(() {
      _states.add(newState);
      _isAddingState = false;
    });
    
    _notifyAutomatonChanged();
  }

  void _selectStateAt(Offset position) {
    State? foundState;
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

  void _addTransition(State from, State to) {
    final symbol = _showSymbolDialog();
    if (symbol != null) {
      final transition = FSATransition(
        fromState: from,
        toState: to,
        symbol: symbol,
      );
      
      setState(() {
        _transitions.add(transition);
      });
      
      _notifyAutomatonChanged();
    }
  }

  String? _showSymbolDialog() {
    // For now, return a default symbol
    // TODO: Implement proper symbol input dialog
    return 'a';
  }

  bool _isPointInState(Offset point, State state) {
    final distance = (point - state.position).distance;
    return distance <= 30; // State radius
  }

  void _notifyAutomatonChanged() {
    if (widget.automaton != null) {
      final updatedAutomaton = widget.automaton!.copyWith(
        states: _states.toSet(),
        transitions: _transitions,
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
          GestureDetector(
            onTapDown: _onCanvasTap,
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
            onPressed: _enableStateAdding,
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
  final List<State> states;
  final List<FSATransition> transitions;
  final State? selectedState;
  final State? transitionStart;

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
      _drawState(canvas, state, paint);
    }

    // Draw transition preview if in progress
    if (transitionStart != null) {
      _drawTransitionPreview(canvas, transitionStart!, paint);
    }
  }

  void _drawState(Canvas canvas, State state, Paint paint) {
    final center = state.position;
    final radius = 30.0;
    
    // State circle
    paint.color = state == selectedState ? Colors.blue : Colors.black;
    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paint);
    
    // Fill for accepting states
    if (state.isAccepting) {
      paint.color = Colors.green.withOpacity(0.3);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(center, radius - 2, paint);
    }
    
    // Initial state arrow
    if (state.isInitial) {
      _drawInitialArrow(canvas, center, paint);
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
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawTransition(Canvas canvas, FSATransition transition, Paint paint) {
    final from = transition.fromState.position;
    final to = transition.toState.position;
    
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    
    // Draw arrow
    final angle = (to - from).direction;
    final arrowLength = 15.0;
    final arrowAngle = 0.5;
    
    final arrowEnd = Offset(
      to.dx - 30 * math.cos(angle),
      to.dy - 30 * math.sin(angle),
    );
    
    canvas.drawLine(from, arrowEnd, paint);
    
    // Draw arrowhead
    final arrow1 = Offset(
      arrowEnd.dx - arrowLength * math.cos(angle - arrowAngle),
      arrowEnd.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    final arrow2 = Offset(
      arrowEnd.dx - arrowLength * math.cos(angle + arrowAngle),
      arrowEnd.dy - arrowLength * math.sin(angle + arrowAngle),
    );
    
    canvas.drawLine(arrowEnd, arrow1, paint);
    canvas.drawLine(arrowEnd, arrow2, paint);
    
    // Draw transition label
    final midPoint = Offset(
      (from.dx + arrowEnd.dx) / 2,
      (from.dy + arrowEnd.dy) / 2,
    );
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: transition.symbol,
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
        midPoint.dx - textPainter.width / 2,
        midPoint.dy - textPainter.height / 2,
      ),
    );
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

  void _drawTransitionPreview(Canvas canvas, State start, Paint paint) {
    // TODO: Implement transition preview
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

// Import for math functions
import 'dart:math' as math;
