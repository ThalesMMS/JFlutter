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
                child: TouchGestureHandler<PDATransition>(
                  states: _states,
                  transitions: _transitions,
                  selectedState: _selectedState,
                  onStateSelected: _selectState,
                  onStateMoved: _moveState,
                  onStateAdded: _addState,
                  onTransitionAdded: _addTransition,
                  onStateEdited: _editState,
                  onStateDeleted: _deleteState,
                  onTransitionDeleted: _deleteTransition,
                  onTransitionEdited: _editTransition,
                  child: CustomPaint(
                    key: widget.canvasKey,
                    painter: _PDACanvasPainter(
                      states: _states,
                      transitions: _transitions,
                      selectedState: _selectedState,
                    ),
                    size: Size.infinite,
                  ),
                  stateRadius: 25,
                  selfLoopBaseRadius: 36,
                  selfLoopSpacing: 10,
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
      final index = _states.indexWhere((s) => s.id == state.id);
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

  Future<void> _addTransition(FSATransition transition) async {
    final result = await _showTransitionDialog(
      from: transition.fromState,
      to: transition.toState,
    );
    if (result == null) return;

    setState(() {
      _transitions.add(result);
      _isAddingTransition = false;
    });
  }

  void _editState(automaton_state.State state) {
    _showStateEditDialog(state);
  }

  void _deleteState(automaton_state.State state) {
    setState(() {
      _states.removeWhere((s) => s.id == state.id);
      _transitions.removeWhere((t) =>
          t.fromState == state || t.toState == state);
      if (_selectedState == state) {
        _selectedState = null;
      }
    });
  }

  void _deleteTransition(PDATransition transition) {
    setState(() {
      _transitions.removeWhere((t) => t.id == transition.id);
    });
  }

  Future<void> _editTransition(PDATransition transition) async {
    final result = await _showTransitionDialog(
      from: transition.fromState,
      to: transition.toState,
      existing: transition,
    );
    if (result == null) return;

    setState(() {
      final index = _transitions.indexWhere((t) => t.id == transition.id);
      if (index != -1) {
        _transitions[index] = result.copyWith(id: transition.id);
      }
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
            final index = _states.indexWhere((s) => s.id == state.id);
            if (index != -1) {
              _states[index] = updatedState;
            }
          });
        },
      ),
    );
  }

  Future<PDATransition?> _showTransitionDialog({
    required automaton_state.State from,
    required automaton_state.State to,
    PDATransition? existing,
  }) async {
    final inputController = TextEditingController(text: existing?.inputSymbol ?? '');
    final popController = TextEditingController(text: existing?.popSymbol ?? '');
    final pushController = TextEditingController(text: existing?.pushSymbol ?? '');

    final result = await showDialog<PDATransition>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Transition' : 'Edit Transition'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(
                controller: inputController,
                label: 'Input Symbol (ε for lambda)',
              ),
              const SizedBox(height: 12),
              _buildDialogField(
                controller: popController,
                label: 'Pop Symbol (ε for lambda)',
              ),
              const SizedBox(height: 12),
              _buildDialogField(
                controller: pushController,
                label: 'Push Symbol (ε for lambda)',
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
                final transition = _buildTransition(
                  from: from,
                  to: to,
                  id: existing?.id ?? 't${_transitions.length + 1}',
                  input: inputController.text.trim(),
                  pop: popController.text.trim(),
                  push: pushController.text.trim(),
                );
                Navigator.of(context).pop(transition);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    inputController.dispose();
    popController.dispose();
    pushController.dispose();
    return result;
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  PDATransition _buildTransition({
    required automaton_state.State from,
    required automaton_state.State to,
    required String id,
    required String input,
    required String pop,
    required String push,
  }) {
    final isLambdaInput = input.isEmpty || input == 'ε';
    final isLambdaPop = pop.isEmpty || pop == 'ε';
    final isLambdaPush = push.isEmpty || push == 'ε';

    final displayInput = isLambdaInput ? 'ε' : input;
    final displayPop = isLambdaPop ? 'ε' : pop;
    final displayPush = isLambdaPush ? 'ε' : push;

    return PDATransition(
      id: id,
      fromState: from,
      toState: to,
      label: '$displayInput, $displayPop/$displayPush',
      inputSymbol: isLambdaInput ? '' : input,
      popSymbol: isLambdaPop ? '' : pop,
      pushSymbol: isLambdaPush ? '' : push,
      isLambdaInput: isLambdaInput,
      isLambdaPop: isLambdaPop,
      isLambdaPush: isLambdaPush,
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
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (transition.fromState == transition.toState) {
      _drawSelfLoop(canvas, transition, paint);
      return;
    }

    final curve = TransitionCurve.compute(
      transitions,
      transition,
      stateRadius: 25,
      curvatureStrength: 38,
      labelOffset: 14,
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

    _drawArrow(canvas, curve.end, curve.tangentAngle, paint);
    _drawLabel(
      canvas,
      curve.labelPosition,
      _formatTransitionLabel(transition),
    );
  }

  void _drawArrow(
    Canvas canvas,
    Offset position,
    double angle,
    Paint paint,
  ) {
    const arrowLength = 15.0;
    const arrowAngle = math.pi / 6;

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

  void _drawInitialArrow(Canvas canvas, Offset center) {
    final arrowStart = Offset(center.dx - 40, center.dy);
    final arrowEnd = Offset(center.dx - 25, center.dy);

    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(arrowStart, arrowEnd, paint);
    final angle = math.atan2(arrowEnd.dy - arrowStart.dy, arrowEnd.dx - arrowStart.dx);
    _drawArrow(canvas, arrowEnd, angle, paint);
  }

  void _drawSelfLoop(Canvas canvas, PDATransition transition, Paint paint) {
    final center = Offset(
      transition.fromState.position.x,
      transition.fromState.position.y,
    );

    const baseRadius = 36.0;
    const spacing = 10.0;

    final loops = transitions
        .where((t) => t.fromState.id == transition.fromState.id && t.fromState == t.toState)
        .toList();
    final index = loops.indexOf(transition);
    final radius = baseRadius + index * spacing;

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
    _drawArrow(canvas, arrowPoint, endAngle + math.pi / 2, paint);

    final labelPosition = Offset(
      rect.center.dx,
      rect.top - 12,
    );
    _drawLabel(
      canvas,
      labelPosition,
      _formatTransitionLabel(transition),
    );
  }

  void _drawLabel(Canvas canvas, Offset position, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
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
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  String _formatTransitionLabel(PDATransition transition) {
    final input = transition.isLambdaInput ? 'ε' : transition.inputSymbol;
    final pop = transition.isLambdaPop ? 'ε' : transition.popSymbol;
    final push = transition.isLambdaPush ? 'ε' : transition.pushSymbol;
    return '$input, $pop/$push';
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
