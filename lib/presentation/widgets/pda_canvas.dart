import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../../core/models/pda.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/pda_transition.dart';
import '../../core/models/transition.dart';
import '../providers/pda_editor_provider.dart';
import 'touch_gesture_handler.dart';
import 'transition_geometry.dart';
import '../../core/algorithms/common/throttling.dart';

/// Interactive canvas for drawing and editing Pushdown Automata
class PDACanvas extends ConsumerStatefulWidget {
  final GlobalKey canvasKey;
  final ValueChanged<PDA> onPDAModified;

  const PDACanvas({
    super.key,
    required this.canvasKey,
    required this.onPDAModified,
  });

  @override
  ConsumerState<PDACanvas> createState() => _PDACanvasState();
}

class _PDACanvasState extends ConsumerState<PDACanvas> {
  final List<automaton_state.State> _states = [];
  final List<PDATransition> _transitions = [];
  automaton_state.State? _selectedState;
  bool _isAddingState = false;
  bool _isAddingTransition = false;
  automaton_state.State? _transitionStart;
  Offset? _transitionPreviewPosition;
  final FrameThrottler _moveThrottler = FrameThrottler();

  CanvasInteractionMode get _interactionMode {
    if (_isAddingTransition) {
      return CanvasInteractionMode.addTransition;
    }
    if (_isAddingState) {
      return CanvasInteractionMode.addState;
    }
    return CanvasInteractionMode.none;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyEditor());
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(pdaEditorProvider);

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
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
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
                  onTransitionAdded: _addTransitionFromHandler,
                  onStateEdited: _editState,
                  onStateDeleted: _deleteState,
                  onTransitionDeleted: _deleteTransition,
                  onTransitionEdited: _editTransition,
                  stateRadius: 25,
                  selfLoopBaseRadius: 36,
                  selfLoopSpacing: 10,
                  interactionMode: _interactionMode,
                  onTransitionPreview: _handleTransitionPreview,
                  onInteractionModeHandled: _handleInteractionModeHandled,
                  child: CustomPaint(
                    key: widget.canvasKey,
                    painter: _PDACanvasPainter(
                      states: _states,
                      transitions: _transitions,
                      selectedState: _selectedState,
                      transitionStart: _transitionStart,
                      transitionPreviewPosition: _transitionPreviewPosition,
                      nondeterministicTransitionIds:
                          editorState.nondeterministicTransitionIds,
                      lambdaTransitionIds: editorState.lambdaTransitionIds,
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
    final editorState = ref.watch(pdaEditorProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PDA Canvas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  _transitionStart = null;
                  _transitionPreviewPosition = null;
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
                  _transitionStart = null;
                  _transitionPreviewPosition = null;
                }),
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
                onPressed: _clearCanvas,
              ),
              IconButton(
                icon: const Icon(Icons.auto_fix_high),
                tooltip: 'Auto layout',
                onPressed: _autoLayoutStates,
              ),
            ],
          ),
          if (editorState.nondeterministicTransitionIds.isNotEmpty ||
              editorState.lambdaTransitionIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (editorState.nondeterministicTransitionIds.isNotEmpty)
                    Chip(
                      avatar: const Icon(
                        Icons.report,
                        color: Colors.white,
                        size: 18,
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      label: Text(
                        '${editorState.nondeterministicTransitionIds.length} nondeterministic',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  if (editorState.lambdaTransitionIds.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.blur_on, size: 18),
                      label: Text(
                        '${editorState.lambdaTransitionIds.length} λ-transition',
                      ),
                    ),
                ],
              ),
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
    _moveThrottler.schedule(() {
      if (!mounted) return;
      setState(() {
        final index = _states.indexWhere((s) => s.id == state.id);
        if (index != -1) {
          _states[index] = state;
          _syncTransitionsForState(state);
        }
      });
      _notifyEditor();
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
    _notifyEditor();
  }

  void _addTransitionFromHandler(Transition transition) async {
    final config = await _showTransitionEditDialog(
      context,
      fromState: transition.fromState,
      toState: transition.toState,
    );

    if (config == null) {
      return;
    }

    final labelInput = config.isLambdaInput ? 'λ' : config.inputSymbol;
    final labelPop = config.isLambdaPop ? 'λ' : config.popSymbol;
    final labelPush = config.isLambdaPush ? 'λ' : config.pushSymbol;

    final pdaTransition = PDATransition(
      id: 't${_transitions.length + 1}',
      fromState: config.fromState,
      toState: config.toState,
      label: '$labelInput, $labelPop/$labelPush',
      inputSymbol: config.inputSymbol,
      popSymbol: config.popSymbol,
      pushSymbol: config.pushSymbol,
      isLambdaInput: config.isLambdaInput,
      isLambdaPop: config.isLambdaPop,
      isLambdaPush: config.isLambdaPush,
    );

    setState(() {
      _transitions.add(pdaTransition);
      _isAddingTransition = false;
      _transitionStart = null;
      _transitionPreviewPosition = null;
    });
    _notifyEditor();
  }

  void _handleTransitionPreview(TransitionDragPreview? preview) {
    if (preview == null) {
      if (_transitionStart != null || _transitionPreviewPosition != null) {
        setState(() {
          _transitionStart = null;
          _transitionPreviewPosition = null;
        });
      }
      return;
    }

    setState(() {
      _transitionStart = preview.fromState;
      _transitionPreviewPosition = preview.currentPosition;
    });
  }

  void _handleInteractionModeHandled() {
    if (!_isAddingState &&
        !_isAddingTransition &&
        _transitionStart == null &&
        _transitionPreviewPosition == null) {
      return;
    }

    setState(() {
      _isAddingState = false;
      _isAddingTransition = false;
      _transitionStart = null;
      _transitionPreviewPosition = null;
    });
  }

  void _editState(automaton_state.State state) {
    _showStateEditDialog(state);
  }

  void _deleteState(automaton_state.State state) {
    setState(() {
      _states.removeWhere((s) => s.id == state.id);
      _transitions.removeWhere(
        (t) => t.fromState.id == state.id || t.toState.id == state.id,
      );
      if (_selectedState?.id == state.id) {
        _selectedState = null;
      }
    });
    _notifyEditor();
  }

  void _deleteTransition(Transition transition) {
    setState(() {
      _transitions.removeWhere((t) => t.id == transition.id);
    });
    _notifyEditor();
  }

  void _editTransition(Transition transition) async {
    if (transition is! PDATransition) return;

    final config = await _showTransitionEditDialog(
      context,
      fromState: transition.fromState,
      toState: transition.toState,
      existing: transition,
    );

    if (config == null) return;

    setState(() {
      final index = _transitions.indexWhere((t) => t.id == transition.id);
      if (index != -1) {
        final labelInput = config.isLambdaInput ? 'λ' : config.inputSymbol;
        final labelPop = config.isLambdaPop ? 'λ' : config.popSymbol;
        final labelPush = config.isLambdaPush ? 'λ' : config.pushSymbol;

        _transitions[index] = PDATransition(
          id: transition.id,
          fromState: config.fromState,
          toState: config.toState,
          label: '$labelInput, $labelPop/$labelPush',
          inputSymbol: config.inputSymbol,
          popSymbol: config.popSymbol,
          pushSymbol: config.pushSymbol,
          isLambdaInput: config.isLambdaInput,
          isLambdaPop: config.isLambdaPop,
          isLambdaPush: config.isLambdaPush,
        );
      }
    });
    _notifyEditor();
  }

  void _clearCanvas() {
    setState(() {
      _states.clear();
      _transitions.clear();
      _selectedState = null;
      _isAddingState = false;
      _isAddingTransition = false;
      _transitionStart = null;
      _transitionPreviewPosition = null;
    });
    _notifyEditor();
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
              _syncTransitionsForState(updatedState);
            }
          });
          _notifyEditor();
        },
      ),
    );
  }

  void _autoLayoutStates() {
    if (_states.isEmpty) {
      return;
    }

    final renderBox =
        widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(600, 400);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(100, math.min(size.width, size.height) / 2 - 60);

    setState(() {
      for (var i = 0; i < _states.length; i++) {
        final angle = (2 * math.pi * i) / _states.length;
        final position = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        final updated = _states[i].copyWith(
          position: Vector2(position.dx, position.dy),
        );
        _states[i] = updated;
        _syncTransitionsForState(updated);
      }
    });
    _notifyEditor();
  }

  void _notifyEditor() {
    _moveThrottler.schedule(() {
      ref
          .read(pdaEditorProvider.notifier)
          .updateFromCanvas(states: _states, transitions: _transitions);
      final currentPda = ref.read(pdaEditorProvider).pda;
      if (currentPda != null) {
        widget.onPDAModified(currentPda);
      }
    });
  }

  void _syncTransitionsForState(automaton_state.State state) {
    for (var i = 0; i < _transitions.length; i++) {
      final transition = _transitions[i];
      if (transition.fromState.id == state.id ||
          transition.toState.id == state.id) {
        _transitions[i] = transition.copyWith(
          fromState: transition.fromState.id == state.id
              ? state
              : transition.fromState,
          toState: transition.toState.id == state.id
              ? state
              : transition.toState,
        );
      }
    }
  }

  Future<_PDATransitionConfig?> _showTransitionEditDialog(
    BuildContext context, {
    required automaton_state.State fromState,
    required automaton_state.State toState,
    PDATransition? existing,
  }) {
    final inputController = TextEditingController(
      text: existing?.inputSymbol ?? '',
    );
    final popController = TextEditingController(
      text: existing?.popSymbol ?? 'Z',
    );
    final pushController = TextEditingController(
      text: existing?.pushSymbol ?? '',
    );

    return showDialog<_PDATransitionConfig?>(
      context: context,
      builder: (context) {
        bool lambdaInput = existing?.isLambdaInput ?? false;
        bool lambdaPop = existing?.isLambdaPop ?? false;
        bool lambdaPush = existing?.isLambdaPush ?? false;
        String? inputError;
        String? popError;
        String? pushError;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? 'Configure PDA Transition'
                    : 'Edit PDA Transition',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From ${fromState.label} to ${toState.label}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: inputController,
                            enabled: !lambdaInput,
                            decoration: InputDecoration(
                              labelText: 'Input symbol',
                              hintText: 'e.g. a',
                              errorText: inputError,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: lambdaInput,
                          onChanged: (value) {
                            setState(() {
                              lambdaInput = value ?? false;
                              inputError = null;
                            });
                          },
                        ),
                        const Text('λ'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: popController,
                            enabled: !lambdaPop,
                            decoration: InputDecoration(
                              labelText: 'Pop symbol',
                              hintText: 'e.g. Z',
                              errorText: popError,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: lambdaPop,
                          onChanged: (value) {
                            setState(() {
                              lambdaPop = value ?? false;
                              popError = null;
                            });
                          },
                        ),
                        const Text('λ'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pushController,
                            enabled: !lambdaPush,
                            decoration: InputDecoration(
                              labelText: 'Push symbol',
                              hintText: 'Leave empty for λ',
                              errorText: pushError,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: lambdaPush,
                          onChanged: (value) {
                            setState(() {
                              lambdaPush = value ?? false;
                              pushError = null;
                            });
                          },
                        ),
                        const Text('λ'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final trimmedInput = inputController.text.trim();
                    final trimmedPop = popController.text.trim();
                    final trimmedPush = pushController.text.trim();

                    bool hasError = false;
                    if (!lambdaInput && trimmedInput.isEmpty) {
                      setState(() {
                        inputError = 'Required';
                      });
                      hasError = true;
                    }
                    if (!lambdaPop && trimmedPop.isEmpty) {
                      setState(() {
                        popError = 'Required';
                      });
                      hasError = true;
                    }
                    if (!lambdaPush && trimmedPush.isEmpty) {
                      setState(() {
                        pushError = 'Required';
                      });
                      hasError = true;
                    }

                    if (hasError) {
                      return;
                    }

                    Navigator.of(context).pop(
                      _PDATransitionConfig(
                        fromState: fromState,
                        toState: toState,
                        inputSymbol: lambdaInput ? '' : trimmedInput,
                        popSymbol: lambdaPop ? '' : trimmedPop,
                        pushSymbol: lambdaPush ? '' : trimmedPush,
                        isLambdaInput: lambdaInput,
                        isLambdaPop: lambdaPop,
                        isLambdaPush: lambdaPush,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PDATransitionConfig {
  final automaton_state.State fromState;
  final automaton_state.State toState;
  final String inputSymbol;
  final String popSymbol;
  final String pushSymbol;
  final bool isLambdaInput;
  final bool isLambdaPop;
  final bool isLambdaPush;

  const _PDATransitionConfig({
    required this.fromState,
    required this.toState,
    required this.inputSymbol,
    required this.popSymbol,
    required this.pushSymbol,
    required this.isLambdaInput,
    required this.isLambdaPop,
    required this.isLambdaPush,
  });
}

/// Custom painter for PDA canvas
class _PDACanvasPainter extends CustomPainter {
  final List<automaton_state.State> states;
  final List<PDATransition> transitions;
  final automaton_state.State? selectedState;
  final automaton_state.State? transitionStart;
  final Offset? transitionPreviewPosition;
  final Set<String> nondeterministicTransitionIds;
  final Set<String> lambdaTransitionIds;

  _PDACanvasPainter({
    required this.states,
    required this.transitions,
    required this.selectedState,
    required this.transitionStart,
    required this.transitionPreviewPosition,
    required this.nondeterministicTransitionIds,
    required this.lambdaTransitionIds,
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

    if (transitionStart != null) {
      _drawTransitionPreview(canvas, transitionStart!);
    }
  }

  void _drawState(Canvas canvas, automaton_state.State state) {
    final paint = Paint()
      ..color = state == selectedState
          ? Colors.blue.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.2)
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

  void _drawTransitionPreview(
    Canvas canvas,
    automaton_state.State start,
  ) {
    if (transitionPreviewPosition == null) {
      return;
    }

    final previewPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withValues(alpha: 0.4);

    final startCenter = Offset(start.position.x, start.position.y);
    final pointer = transitionPreviewPosition!;
    final delta = pointer - startCenter;

    if (delta.distance < 1) {
      return;
    }

    const stateRadius = 25.0;
    if (delta.distance < stateRadius * 0.8) {
      final previewTransition = PDATransition(
        id: '__preview__',
        fromState: start,
        toState: start,
        label: '',
        inputSymbol: '',
        popSymbol: '',
        pushSymbol: '',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );
      _drawSelfLoop(canvas, previewTransition, previewPaint);
      return;
    }

    final unit = Offset(delta.dx / delta.distance, delta.dy / delta.distance);
    final startPoint = startCenter + unit * stateRadius;
    final endPoint = pointer;
    final midPoint = Offset(
      (startPoint.dx + endPoint.dx) / 2,
      (startPoint.dy + endPoint.dy) / 2,
    );
    final normal = Offset(-unit.dy, unit.dx);
    final curvatureScale = math.min(1.0, 120 / delta.distance);
    final control = midPoint + normal * 40 * curvatureScale;

    final path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..quadraticBezierTo(control.dx, control.dy, endPoint.dx, endPoint.dy);
    canvas.drawPath(path, previewPaint);

    const arrowLength = 10.0;
    const arrowAngle = 0.5;
    final derivative = (endPoint - control) * 2;
    final angle = math.atan2(derivative.dy, derivative.dx);
    final arrow1 = Offset(
      endPoint.dx - arrowLength * math.cos(angle - arrowAngle),
      endPoint.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    final arrow2 = Offset(
      endPoint.dx - arrowLength * math.cos(angle + arrowAngle),
      endPoint.dy - arrowLength * math.sin(angle + arrowAngle),
    );

    canvas.drawLine(endPoint, arrow1, previewPaint);
    canvas.drawLine(endPoint, arrow2, previewPaint);
  }

  void _drawTransition(Canvas canvas, PDATransition transition) {
    Color transitionColor = Colors.black;
    if (nondeterministicTransitionIds.contains(transition.id)) {
      transitionColor = Colors.redAccent;
    } else if (lambdaTransitionIds.contains(transition.id)) {
      transitionColor = Colors.deepPurple;
    }

    final paint = Paint()
      ..color = transitionColor
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
      transitionColor,
    );
  }

  void _drawArrow(Canvas canvas, Offset position, double angle, Paint paint) {
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
    final angle = math.atan2(
      arrowEnd.dy - arrowStart.dy,
      arrowEnd.dx - arrowStart.dx,
    );
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
        .where(
          (t) =>
              t.fromState.id == transition.fromState.id &&
              t.fromState == t.toState,
        )
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

    const endAngle = startAngle + sweepAngle;
    final arrowPoint = Offset(
      rect.center.dx + rect.width / 2 * math.cos(endAngle),
      rect.center.dy + rect.height / 2 * math.sin(endAngle),
    );
    _drawArrow(canvas, arrowPoint, endAngle + math.pi / 2, paint);

    final labelPosition = Offset(rect.center.dx, rect.top - 12);
    _drawLabel(
      canvas,
      labelPosition,
      _formatTransitionLabel(transition),
      paint.color,
    );
  }

  void _drawLabel(Canvas canvas, Offset position, String text, Color color) {
    final labelBackground = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final rect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      labelBackground,
    );

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  String _formatTransitionLabel(PDATransition transition) {
    final input = transition.isLambdaInput ? 'λ' : transition.inputSymbol;
    final pop = transition.isLambdaPop ? 'λ' : transition.popSymbol;
    final push = transition.isLambdaPush ? 'λ' : transition.pushSymbol;
    return '$input, $pop/$push';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Dialog for editing state properties
class _StateEditDialog extends StatefulWidget {
  final automaton_state.State state;
  final ValueChanged<automaton_state.State> onStateUpdated;

  const _StateEditDialog({required this.state, required this.onStateUpdated});

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
        ElevatedButton(onPressed: _saveState, child: const Text('Save')),
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
