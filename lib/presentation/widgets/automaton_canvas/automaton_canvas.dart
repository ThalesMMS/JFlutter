import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/models/fsa.dart';
import '../../../core/models/fsa_transition.dart';
import '../../../core/models/state.dart' as automaton_state;
import '../../providers/automaton_canvas_controller.dart';
import '../touch_gesture_handler.dart';
import 'automaton_painter.dart';
import 'state_edit_dialog.dart';
import 'transition_symbol_input.dart';

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
  late final AutomatonCanvasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AutomatonCanvasController(
      automaton: widget.automaton,
      onAutomatonChanged: widget.onAutomatonChanged,
    );
  }

  @override
  void didUpdateWidget(covariant AutomatonCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.automaton != widget.automaton) {
      _controller.loadAutomaton(widget.automaton);
    }
    if (oldWidget.onAutomatonChanged != widget.onAutomatonChanged) {
      _controller.onAutomatonChanged = widget.onAutomatonChanged;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCanvasTap(TapDownDetails details) {
    final position = details.localPosition;

    if (_controller.isAddingState) {
      _controller.addState(position);
      return;
    }

    if (_controller.isAddingTransition) {
      final start = _controller.transitionStart;
      final target = _controller.prepareTransitionTarget(position);
      if (start != null && target != null) {
        unawaited(_handleTransitionCreation(start, target));
      }
      return;
    }

    _controller.selectStateAt(position);
  }

  void _handleStateDeleted(automaton_state.State state) {
    _controller.deleteState(state);
  }

  void _handleTransitionOriginChanged(automaton_state.State? state) {
    _controller.updateTransitionOrigin(state);
  }

  void _handleTransitionPreviewChanged(Offset? position) {
    _controller.updateTransitionPreview(position);
  }

  void _handleTransitionGestureAdded(
    automaton_state.State from,
    automaton_state.State to,
  ) {
    if (!_controller.isAddingTransition) {
      return;
    }
    unawaited(_handleTransitionCreation(from, to));
  }

  Future<void> _handleTransitionCreation(
    automaton_state.State from,
    automaton_state.State to,
  ) async {
    final input = await _showSymbolDialog();
    if (input != null) {
      _controller.addTransition(from, to, input);
    }
    _controller.completeTransitionAddition();
  }

  Future<void> _editState(automaton_state.State state) async {
    await showDialog<void>(
      context: context,
      builder: (context) => StateEditDialog(
        state: state,
        onStateUpdated: _controller.updateState,
      ),
    );
  }

  Future<void> _editTransition(FSATransition transition) async {
    final input = await _showSymbolDialog(transition: transition);
    if (input == null) {
      return;
    }
    _controller.updateTransition(transition, input);
  }

  @visibleForTesting
  Future<TransitionSymbolInput?> showTransitionSymbolDialogForTest({
    FSATransition? transition,
  }) {
    return _showSymbolDialog(transition: transition);
  }

  Future<TransitionSymbolInput?> _showSymbolDialog({
    FSATransition? transition,
  }) async {
    final existingSymbols = transition?.lambdaSymbol != null
        ? 'ε'
        : transition?.inputSymbols.join(', ') ?? '';
    final controller = TextEditingController(text: existingSymbols);
    String? errorText;
    final result = await showDialog<TransitionSymbolInput>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                transition == null ? 'Transition Symbols' : 'Edit Transition',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter symbols separated by commas or ε for epsilon',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Symbols',
                      errorText: errorText,
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
                    final parsed = TransitionSymbolInput.parse(controller.text);
                    if (parsed == null) {
                      setState(() {
                        errorText = 'Please enter at least one symbol or ε.';
                      });
                      return;
                    }
                    setState(() {
                      errorText = null;
                    });
                    Navigator.of(context).pop(parsed);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final states = _controller.states;
        final transitions = _controller.transitions;

        return Container(
          key: widget.canvasKey,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: borderRadius,
          ),
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onTapDown: (_controller.isAddingState || _controller.isAddingTransition)
                    ? _handleCanvasTap
                    : null,
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: TouchGestureHandler<FSATransition>(
                    states: states,
                    transitions: transitions,
                    selectedState: _controller.selectedState,
                    onStateSelected: _controller.selectState,
                    onStateMoved: _controller.updateStatePosition,
                    onStateAdded: _controller.addState,
                    onTransitionAdded: _handleTransitionGestureAdded,
                    onStateEdited: (state) => _editState(state),
                    onStateDeleted: _handleStateDeleted,
                    onTransitionDeleted: _controller.deleteTransition,
                    onTransitionEdited: (transition) => _editTransition(transition),
                    isAddingTransition: _controller.isAddingTransition,
                    onTransitionOriginChanged: _handleTransitionOriginChanged,
                    onTransitionPreviewChanged: _handleTransitionPreviewChanged,
                    child: MouseRegion(
                      onExit: (_) => _controller.updateTransitionPreview(null),
                      child: Listener(
                        onPointerHover: (event) =>
                            _controller.updateTransitionPreview(event.localPosition),
                        onPointerMove: (event) =>
                            _controller.updateTransitionPreview(event.localPosition),
                        onPointerDown: (event) =>
                            _controller.updateTransitionPreview(event.localPosition),
                        onPointerUp: (_) => _controller.updateTransitionPreview(null),
                        onPointerCancel: (_) => _controller.updateTransitionPreview(null),
                        child: CustomPaint(
                          painter: AutomatonPainter(
                            states: states,
                            transitions: transitions,
                            selectedState: _controller.selectedState,
                            transitionStart: _controller.transitionStart,
                            transitionPreviewPosition:
                                _controller.transitionPreviewPosition,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _buildCanvasControls(context),
              ),
              if (states.isEmpty)
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
      },
    );
  }

  Widget _buildCanvasControls(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
            onPressed: _controller.addStateAtCenter,
            icon: const Icon(Icons.add_circle),
            tooltip: 'Add State',
            color:
                _controller.isAddingState ? theme.colorScheme.primary : null,
          ),
          IconButton(
            onPressed: _controller.enableTransitionAdding,
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Add Transition',
            color: _controller.isAddingTransition
                ? theme.colorScheme.primary
                : null,
          ),
          IconButton(
            onPressed: _controller.cancelOperations,
            icon: const Icon(Icons.cancel),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }
}
