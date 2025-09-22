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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyEditor());
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(pdaEditorProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
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
              child: CustomPaint(
                key: widget.canvasKey,
                painter: _PDACanvasPainter(
                  states: _states,
                  transitions: _transitions,
                  selectedState: _selectedState,
                  nondeterministicTransitionIds:
                      editorState.nondeterministicTransitionIds,
                  lambdaTransitionIds: editorState.lambdaTransitionIds,
                ),
                size: Size.infinite,
              ),
              stateRadius: 25,
              selfLoopBaseRadius: 36,
              selfLoopSpacing: 10,
              isAddingTransition: _isAddingTransition,
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: _buildToolbar(context, editorState),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, PDAEditorState editorState) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                      avatar: const Icon(Icons.report, color: Colors.white, size: 18),
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
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
    setState(() {
      final index = _states.indexWhere((s) => s.id == state.id);
      if (index != -1) {
        _states[index] = state;
        _syncTransitionsForState(state);
      }
    });
    _notifyEditor();
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

  void _addTransitionFromHandler(
    automaton_state.State from,
    automaton_state.State to,
  ) async {
    final config = await _showTransitionEditDialog(
      context,
      fromState: from,
      toState: to,
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
    });
    _notifyEditor();
  }

  void _editState(automaton_state.State state) {
    _showStateEditDialog(state);
  }

  void _deleteState(automaton_state.State state) {
    setState(() {
      _states.removeWhere((s) => s.id == state.id);
      _transitions.removeWhere(
          (t) => t.fromState.id == state.id || t.toState.id == state.id);
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

    final renderBox = widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
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
    ref.read(pdaEditorProvider.notifier).updateFromCanvas(
          states: _states,
          transitions: _transitions,
        );
    final currentPda = ref.read(pdaEditorProvider).pda;
    if (currentPda != null) {
      widget.onPDAModified(currentPda);
    }
  }

  void _syncTransitionsForState(automaton_state.State state) {
    for (var i = 0; i < _transitions.length; i++) {
      final transition = _transitions[i];
      if (transition.fromState.id == state.id ||
          transition.toState.id == state.id) {
        _transitions[i] = transition.copyWith(
          fromState:
              transition.fromState.id == state.id ? state : transition.fromState,
          toState:
              transition.toState.id == state.id ? state : transition.toState,
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
      text: existing != null && !existing.isLambdaInput
          ? existing.inputSymbol
          : '',
    );
    final popController = TextEditingController(
      text:
          existing != null && !existing.isLambdaPop ? existing.popSymbol : '',
    );
    final pushController = TextEditingController(
      text: existing != null && !existing.isLambdaPush
          ? existing.pushSymbol
          : '',
    );

    automaton_state.State selectedFrom = existing?.fromState ?? fromState;
    automaton_state.State selectedTo = existing?.toState ?? toState;

    bool isLambdaInput = existing?.isLambdaInput ?? false;
    bool isLambdaPop = existing?.isLambdaPop ?? false;
    bool isLambdaPush = existing?.isLambdaPush ?? false;
    String? errorMessage;

    Future<_PDATransitionConfig?> result = showDialog<_PDATransitionConfig>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void setError(String? message) {
              setDialogState(() {
                errorMessage = message;
              });
            }

            void handleSubmit() {
              final inputSymbol = inputController.text.trim();
              final popSymbol = popController.text.trim();
              final pushSymbol = pushController.text.trim();

              if (!isLambdaInput && inputSymbol.isEmpty) {
                setError('Input symbol cannot be empty unless λ is selected.');
                return;
              }

              if (!isLambdaPop && popSymbol.isEmpty) {
                setError('Pop symbol cannot be empty unless λ is selected.');
                return;
              }

              if (!isLambdaPush && pushSymbol.isEmpty) {
                setError('Push symbol cannot be empty unless λ is selected.');
                return;
              }

              setError(null);
              Navigator.of(context).pop(
                _PDATransitionConfig(
                  fromState: selectedFrom,
                  toState: selectedTo,
                  inputSymbol: inputSymbol,
                  popSymbol: popSymbol,
                  pushSymbol: pushSymbol,
                  isLambdaInput: isLambdaInput,
                  isLambdaPop: isLambdaPop,
                  isLambdaPush: isLambdaPush,
                ),
              );
            }

            return AlertDialog(
              title: Text(existing == null ? 'Create Transition' : 'Edit Transition'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<automaton_state.State>(
                      value: selectedFrom,
                      decoration: const InputDecoration(
                        labelText: 'From state',
                        border: OutlineInputBorder(),
                      ),
                      items: _states
                          .map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(state.label.isEmpty ? state.id : state.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedFrom = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<automaton_state.State>(
                      value: selectedTo,
                      decoration: const InputDecoration(
                        labelText: 'To state',
                        border: OutlineInputBorder(),
                      ),
                      items: _states
                          .map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(state.label.isEmpty ? state.id : state.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedTo = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _TransitionSymbolField(
                      controller: inputController,
                      label: 'Input symbol',
                      helperText: 'Use λ to consume no input.',
                      isLambdaSelected: isLambdaInput,
                      onLambdaChanged: (value) => setDialogState(() {
                        isLambdaInput = value;
                        if (value) inputController.clear();
                      }),
                    ),
                    const SizedBox(height: 12),
                    _TransitionSymbolField(
                      controller: popController,
                      label: 'Pop symbol',
                      helperText: 'Use λ to avoid popping a symbol.',
                      isLambdaSelected: isLambdaPop,
                      onLambdaChanged: (value) => setDialogState(() {
                        isLambdaPop = value;
                        if (value) popController.clear();
                      }),
                    ),
                    const SizedBox(height: 12),
                    _TransitionSymbolField(
                      controller: pushController,
                      label: 'Push symbol',
                      helperText: 'Use λ to avoid pushing to the stack.',
                      isLambdaSelected: isLambdaPush,
                      onLambdaChanged: (value) => setDialogState(() {
                        isLambdaPush = value;
                        if (value) pushController.clear();
                      }),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: handleSubmit,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    return result.whenComplete(() {
      inputController.dispose();
      popController.dispose();
      pushController.dispose();
    });
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

  factory _PDATransitionConfig.fromTransition(PDATransition transition) {
    return _PDATransitionConfig(
      fromState: transition.fromState,
      toState: transition.toState,
      inputSymbol: transition.inputSymbol,
      popSymbol: transition.popSymbol,
      pushSymbol: transition.pushSymbol,
      isLambdaInput: transition.isLambdaInput,
      isLambdaPop: transition.isLambdaPop,
      isLambdaPush: transition.isLambdaPush,
    );
  }

  String get inputLabel => isLambdaInput ? 'λ' : inputSymbol;

  String get popLabel => isLambdaPop ? 'λ' : popSymbol;

  String get pushLabel => isLambdaPush ? 'λ' : pushSymbol;
}

class _PDACanvasPainter extends CustomPainter {
  static const double _stateRadius = 25.0;
  final List<automaton_state.State> states;
  final List<PDATransition> transitions;
  final automaton_state.State? selectedState;
  final Set<String> nondeterministicTransitionIds;
  final Set<String> lambdaTransitionIds;

  const _PDACanvasPainter({
    required this.states,
    required this.transitions,
    required this.selectedState,
    this.nondeterministicTransitionIds = const {},
    this.lambdaTransitionIds = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final transition in transitions) {
      _drawTransition(canvas, transition);
    }

    for (final state in states) {
      _drawState(canvas, state);
    }
  }

  void _drawState(Canvas canvas, automaton_state.State state) {
    final center = Offset(state.position.x, state.position.y);

    final fillPaint = Paint()
      ..color = state == selectedState
          ? Colors.blue.withOpacity(0.25)
          : Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final borderColor = state.isInitial
        ? Colors.green
        : state.isAccepting
            ? Colors.red
            : Colors.black;

    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, _stateRadius, fillPaint);
    canvas.drawCircle(center, _stateRadius, strokePaint);

    if (state.isAccepting) {
      canvas.drawCircle(center, _stateRadius - 5, strokePaint);
    }

    if (state.isInitial) {
      _drawInitialIndicator(canvas, center, borderColor);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: state.label.isEmpty ? state.id : state.label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _stateRadius * 2);

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawTransition(Canvas canvas, PDATransition transition) {
    final isSelfLoop = transition.fromState.id == transition.toState.id;
    final isNondeterministic =
        nondeterministicTransitionIds.contains(transition.id);
    final isLambda = lambdaTransitionIds.contains(transition.id);

    Color strokeColor = Colors.black;
    if (isNondeterministic && isLambda) {
      strokeColor = Colors.deepPurple;
    } else if (isNondeterministic) {
      strokeColor = Colors.orange[700] ?? Colors.orange;
    } else if (isLambda) {
      strokeColor = Colors.indigo;
    }

    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isNondeterministic || isLambda ? 3.0 : 2.0;

    if (isSelfLoop) {
      _drawSelfLoop(canvas, transition, paint, isLambda, isNondeterministic);
      return;
    }

    final curve = TransitionCurve.compute(
      transitions,
      transition,
      stateRadius: _stateRadius,
      curvatureStrength: 45,
      labelOffset: 18,
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

    final derivative = TransitionCurve.derivativeAt(
      curve.start,
      curve.control,
      curve.end,
      1.0,
    );

    final angle = math.atan2(derivative.dy, derivative.dx);
    _drawArrowHead(canvas, curve.end, angle, strokeColor);

    _drawTransitionLabel(
      canvas,
      curve.labelPosition,
      transition.label,
      strokeColor,
      isLambda: isLambda,
      isNondeterministic: isNondeterministic,
    );
  }

  void _drawSelfLoop(
    Canvas canvas,
    PDATransition transition,
    Paint paint,
    bool isLambda,
    bool isNondeterministic,
  ) {
    final center = Offset(
      transition.fromState.position.x,
      transition.fromState.position.y,
    );

    const double loopRadius = 40;
    final start = Offset(center.dx, center.dy - _stateRadius);
    final controlLeft = Offset(center.dx - loopRadius, center.dy - loopRadius);
    final controlRight = Offset(center.dx + loopRadius, center.dy - loopRadius);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        controlLeft.dx,
        controlLeft.dy,
        controlRight.dx,
        controlRight.dy,
        start.dx,
        start.dy,
      );

    canvas.drawPath(path, paint);

    _drawArrowHead(canvas, start, -math.pi / 2, paint.color);

    final labelPosition = Offset(center.dx, center.dy - loopRadius - 16);
    _drawTransitionLabel(
      canvas,
      labelPosition,
      transition.label,
      paint.color,
      isLambda: isLambda,
      isNondeterministic: isNondeterministic,
    );
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double angle, Color color) {
    const double arrowLength = 12;
    const double arrowAngle = math.pi / 6;

    final path = Path()
      ..moveTo(
        tip.dx - arrowLength * math.cos(angle - arrowAngle),
        tip.dy - arrowLength * math.sin(angle - arrowAngle),
      )
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowLength * math.cos(angle + arrowAngle),
        tip.dy - arrowLength * math.sin(angle + arrowAngle),
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawTransitionLabel(
    Canvas canvas,
    Offset position,
    String text,
    Color accentColor, {
    required bool isLambda,
    required bool isNondeterministic,
  }) {
    if (text.isEmpty) return;

    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
      fontStyle: isLambda ? FontStyle.italic : FontStyle.normal,
      fontWeight: isNondeterministic ? FontWeight.bold : FontWeight.w500,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 160);

    final padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    final rect = Rect.fromCenter(
      center: position,
      width: textPainter.width + padding.horizontal,
      height: textPainter.height + padding.vertical,
    );

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      backgroundPaint,
    );

    if (isNondeterministic || isLambda) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..color = accentColor.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    textPainter.paint(
      canvas,
      Offset(
        rect.left + padding.left,
        rect.top + padding.top,
      ),
    );
  }

  void _drawInitialIndicator(Canvas canvas, Offset center, Color color) {
    final start = Offset(center.dx - 40, center.dy);
    final end = Offset(center.dx - _stateRadius, center.dy);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawLine(start, end, paint);
    _drawArrowHead(canvas, end, 0, color);
  }

  @override
  bool shouldRepaint(covariant _PDACanvasPainter oldDelegate) {
    return oldDelegate.states != states ||
        oldDelegate.transitions != transitions ||
        oldDelegate.selectedState != selectedState ||
        oldDelegate.nondeterministicTransitionIds !=
            nondeterministicTransitionIds ||
        oldDelegate.lambdaTransitionIds != lambdaTransitionIds;
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'State label',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Initial state'),
            value: _isInitial,
            onChanged: (value) => setState(() {
              _isInitial = value ?? false;
            }),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Accepting state'),
            value: _isAccepting,
            onChanged: (value) => setState(() {
              _isAccepting = value ?? false;
            }),
          ),
        ],
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
    final updatedState = widget.state.copyWith(
      label: _nameController.text.trim().isEmpty
          ? widget.state.id
          : _nameController.text.trim(),
      isInitial: _isInitial,
      isAccepting: _isAccepting,
    );

    widget.onStateUpdated(updatedState);
    Navigator.of(context).pop();
  }
}

class _TransitionSymbolField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String helperText;
  final bool isLambdaSelected;
  final ValueChanged<bool> onLambdaChanged;

  const _TransitionSymbolField({
    required this.controller,
    required this.label,
    required this.helperText,
    required this.isLambdaSelected,
    required this.onLambdaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLambdaSelected,
                decoration: InputDecoration(
                  labelText: label,
                  helperText: helperText,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isLambdaSelected,
                  onChanged: (value) => onLambdaChanged(value),
                ),
                const Text('λ'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
