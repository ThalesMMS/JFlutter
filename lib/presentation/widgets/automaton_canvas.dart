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

// Rest of the file: AutomatonPainter, _StateEditDialog, and _TransitionSymbolInput classes
// [These remain unchanged from the original file]