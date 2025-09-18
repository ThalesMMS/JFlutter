import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../../core/models/pda.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/pda_transition.dart';
import '../../core/models/fsa_transition.dart';
import 'touch_gesture_handler.dart';

/// Interactive canvas for drawing and editing Pushdown Automata
class PDACanvas extends StatefulWidget {
  final GlobalKey canvasKey;
  final ValueChanged<PDA> onPDAModified;

  const PDACanvas({
    super.key,
    required this.canvasKey,
    required this.onPDAModified,
  });

  @override
  State<PDACanvas> createState() => _PDACanvasState();
}

class _PDACanvasState extends State<PDACanvas> {
  final List<automaton_state.State> _states = [];
  final List<PDATransition> _transitions = [];
  automaton_state.State? _selectedState;
  bool _isAddingState = false;
  bool _isAddingTransition = false;
  automaton_state.State? _transitionStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildToolbar(context),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TouchGestureHandler(
                  states: _states,
                  transitions: _transitions.cast(),
                  selectedState: _selectedState,
                  onStateSelected: _selectState,
                  onStateMoved: _moveState,
                  onStateAdded: _addState,
                  onTransitionAdded: _addTransition,
                  onStateEdited: _editState,
                  onStateDeleted: _deleteState,
                  onTransitionDeleted: _deleteTransition,
                  child: CustomPaint(
                    key: widget.canvasKey,
                    painter: _PDACanvasPainter(
                      states: _states,
                      transitions: _transitions,
                      selectedState: _selectedState,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PDA Canvas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToolButton(
                context,
                icon: Icons.add_circle,
                label: 'Add State',
                isSelected: _isAddingState,
                onPressed: () => setState(() {
                  _isAddingState = !_isAddingState;
                  _isAddingTransition = false;
                }),
              ),
              _buildToolButton(
                context,
                icon: Icons.arrow_forward,
                label: 'Add Transition',
                isSelected: _isAddingTransition,
                onPressed: () => setState(() {
                  _isAddingTransition = !_isAddingTransition;
                  _isAddingState = false;
                }),
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
                onPressed: _clearCanvas,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isSelected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected ? colorScheme.primary : colorScheme.onSurface;
    final backgroundColor = isSelected 
        ? colorScheme.primaryContainer 
        : colorScheme.surface;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: color,
        elevation: isSelected ? 4 : 1,
      ),
    );
  }

  void _selectState(automaton_state.State? state) {
    setState(() {
      _selectedState = state;
    });
  }

  void _moveState(automaton_state.State state) {
    setState(() {
      final index = _states.indexOf(state);
      if (index != -1) {
        _states[index] = state;
      }
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
  }

  void _addTransition(FSATransition transition) {
    // Convert FSA transition to PDA transition
    final pdaTransition = PDATransition(
      id: transition.id,
      fromState: transition.fromState,
      toState: transition.toState,
      label: transition.label,
      inputSymbol: transition.label,
      popSymbol: 'Z', // Default stack symbol
      pushSymbol: 'Z', // Default stack symbol
    );

    setState(() {
      _transitions.add(pdaTransition);
    });
  }

  void _editState(automaton_state.State state) {
    _showStateEditDialog(state);
  }

  void _deleteState(automaton_state.State state) {
    setState(() {
      _states.remove(state);
      _transitions.removeWhere((t) => 
          t.fromState == state || t.toState == state);
      if (_selectedState == state) {
        _selectedState = null;
      }
    });
  }

  void _deleteTransition(FSATransition transition) {
    setState(() {
      _transitions.remove(transition);
    });
  }

  void _clearCanvas() {
    setState(() {
      _states.clear();
      _transitions.clear();
      _selectedState = null;
      _isAddingState = false;
      _isAddingTransition = false;
    });
  }

  void _showStateEditDialog(automaton_state.State state) {
    showDialog(
      context: context,
      builder: (context) => _StateEditDialog(
        state: state,
        onStateUpdated: (updatedState) {
          setState(() {
            final index = _states.indexOf(state);
            if (index != -1) {
              _states[index] = updatedState;
            }
          });
        },
      ),
    );
  }
}

/// Custom painter for PDA canvas
class _PDACanvasPainter extends CustomPainter {
  final List<automaton_state.State> states;
  final List<PDATransition> transitions;
  final automaton_state.State? selectedState;

  _PDACanvasPainter({
    required this.states,
    required this.transitions,
    required this.selectedState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw transitions first (so they appear behind states)
    for (final transition in transitions) {
      _drawTransition(canvas, transition);
    }

    // Draw states
    for (final state in states) {
      _drawState(canvas, state);
    }
  }

  void _drawState(Canvas canvas, automaton_state.State state) {
    final paint = Paint()
      ..color = state == selectedState 
          ? Colors.blue.withOpacity(0.3)
          : Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = state.isInitial 
          ? Colors.green 
          : state.isAccepting 
              ? Colors.red 
              : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(state.position.x, state.position.y);
    const radius = 25.0;

    // Draw state circle
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, strokePaint);

    // Draw state name
    final textPainter = TextPainter(
      text: TextSpan(
        text: state.name,
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
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Draw initial state arrow
    if (state.isInitial) {
      _drawInitialArrow(canvas, center);
    }

    // Draw accepting state double circle
    if (state.isAccepting) {
      canvas.drawCircle(center, radius - 5, strokePaint);
    }
  }

  void _drawTransition(Canvas canvas, PDATransition transition) {
    final fromPos = Offset(transition.fromState.position.x, transition.fromState.position.y);
    final toPos = Offset(transition.toState.position.x, transition.toState.position.y);

    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw transition line
    canvas.drawLine(fromPos, toPos, paint);

    // Draw arrow
    _drawArrow(canvas, fromPos, toPos);

    // Draw transition label
    final midPoint = Offset(
      (fromPos.dx + toPos.dx) / 2,
      (fromPos.dy + toPos.dy) / 2 - 20,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${transition.inputSymbol}, ${transition.stackPop}/${transition.stackPush}',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
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

  void _drawArrow(Canvas canvas, Offset from, Offset to) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowLength = 15.0;
    const arrowAngle = math.pi / 6;

    final arrow1 = Offset(
      to.dx - arrowLength * math.cos(angle - arrowAngle),
      to.dy - arrowLength * math.sin(angle - arrowAngle),
    );

    final arrow2 = Offset(
      to.dx - arrowLength * math.cos(angle + arrowAngle),
      to.dy - arrowLength * math.sin(angle + arrowAngle),
    );

    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(to, arrow1, paint);
    canvas.drawLine(to, arrow2, paint);
  }

  void _drawInitialArrow(Canvas canvas, Offset center) {
    final arrowStart = Offset(center.dx - 40, center.dy);
    final arrowEnd = Offset(center.dx - 25, center.dy);

    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(arrowStart, arrowEnd, paint);
    _drawArrow(canvas, arrowStart, arrowEnd);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
  late TextEditingController _nameController;
  late bool _isInitial;
  late bool _isAccepting;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.name);
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'State Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Initial State'),
            value: _isInitial,
            onChanged: (value) => setState(() => _isInitial = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('Accepting State'),
            value: _isAccepting,
            onChanged: (value) => setState(() => _isAccepting = value ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveState,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveState() {
    final updatedState = widget.state.copyWith(
      label: _nameController.text.trim(),
      isInitial: _isInitial,
      isAccepting: _isAccepting,
    );

    widget.onStateUpdated(updatedState);
    Navigator.of(context).pop();
  }
}
