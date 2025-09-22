import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/state.dart' as automaton_state;
import '../widgets/automaton_canvas/transition_symbol_input.dart';

/// Controller responsible for managing the state of the automaton canvas.
class AutomatonCanvasController extends ChangeNotifier {
  AutomatonCanvasController({
    FSA? automaton,
    ValueChanged<FSA>? onAutomatonChanged,
  }) : _onAutomatonChanged = onAutomatonChanged {
    loadAutomaton(automaton);
  }

  static const double _stateRadius = 30;

  final List<automaton_state.State> _states = [];
  final List<FSATransition> _transitions = [];
  int _nextStateIndex = 0;

  automaton_state.State? _selectedState;
  bool _isAddingState = false;
  bool _isAddingTransition = false;
  automaton_state.State? _transitionStart;
  Offset? _transitionPreviewPosition;
  FSA? _baseAutomaton;
  ValueChanged<FSA>? _onAutomatonChanged;

  /// Current states displayed in the canvas.
  UnmodifiableListView<automaton_state.State> get states =>
      UnmodifiableListView(_states);

  /// Current transitions displayed in the canvas.
  UnmodifiableListView<FSATransition> get transitions =>
      UnmodifiableListView(_transitions);

  /// Currently selected state, if any.
  automaton_state.State? get selectedState => _selectedState;

  /// Indicates if the canvas is waiting for a state tap to add a new one.
  bool get isAddingState => _isAddingState;

  /// Indicates if the canvas is in transition creation mode.
  bool get isAddingTransition => _isAddingTransition;

  /// The state that originated the current transition creation.
  automaton_state.State? get transitionStart => _transitionStart;

  /// Current preview position for the transition being created.
  Offset? get transitionPreviewPosition => _transitionPreviewPosition;

  /// Updates the callback that should be triggered when the automaton changes.
  set onAutomatonChanged(ValueChanged<FSA>? callback) {
    _onAutomatonChanged = callback;
  }

  /// Loads the given automaton into the controller.
  void loadAutomaton(FSA? automaton) {
    _baseAutomaton = automaton;
    _states
      ..clear()
      ..addAll(automaton?.states ?? const <automaton_state.State>{});
    _transitions
      ..clear()
      ..addAll(
        automaton?.transitions.cast<FSATransition>() ?? const <FSATransition>{},
      );
    _nextStateIndex = _states.fold<int>(0, (maxIndex, state) {
      final match = RegExp(r'\d+$').firstMatch(state.id);
      if (match == null) {
        return maxIndex;
      }

      final value = int.tryParse(match.group(0)!) ?? 0;
      return math.max(maxIndex, value + 1);
    });
    _selectedState = null;
    _isAddingState = false;
    _isAddingTransition = false;
    _transitionStart = null;
    _transitionPreviewPosition = null;
    notifyListeners();
  }

  /// Enables the mode to add states by tapping the canvas.
  void enableStateAdding() {
    _isAddingState = true;
    _isAddingTransition = false;
    _selectedState = null;
    notifyListeners();
  }

  /// Enables the mode to add transitions by selecting states.
  void enableTransitionAdding() {
    _isAddingTransition = true;
    _isAddingState = false;
    _transitionPreviewPosition = null;
    _transitionStart = _selectedState;
    notifyListeners();
  }

  /// Cancels any active editing mode.
  void cancelOperations() {
    _isAddingState = false;
    _isAddingTransition = false;
    _selectedState = null;
    _transitionStart = null;
    _transitionPreviewPosition = null;
    notifyListeners();
  }

  /// Adds a new state at the provided canvas position.
  void addState(Offset position) {
    final newState = automaton_state.State(
      id: 'q$_nextStateIndex',
      label: 'q$_nextStateIndex',
      position: Vector2(position.dx, position.dy),
      isInitial: _states.isEmpty,
      isAccepting: false,
    );

    _states.add(newState);
    _nextStateIndex++;
    _isAddingState = false;
    notifyListeners();
    _emitAutomatonChanged();
  }

  /// Adds a new state at a sensible position near the center of the canvas.
  void addStateAtCenter() {
    const canvasCenter = Offset(200, 150);

    Offset position = canvasCenter;
    var attempts = 0;
    while (attempts < 10) {
      final hasConflict = _states.any((state) {
        final statePosition = Offset(state.position.x, state.position.y);
        return (statePosition - position).distance < _stateRadius * 2;
      });

      if (!hasConflict) {
        break;
      }

      position = Offset(
        canvasCenter.dx + (attempts * 30) * math.cos(attempts * 0.8),
        canvasCenter.dy + (attempts * 30) * math.sin(attempts * 0.8),
      );
      attempts++;
    }

    addState(position);
  }

  /// Selects the state at the given position, if any.
  void selectStateAt(Offset position) {
    final foundState = _findStateAt(position);
    if (foundState != _selectedState) {
      _selectedState = foundState;
      notifyListeners();
    }
  }

  /// Explicitly selects the provided state.
  void selectState(automaton_state.State? state) {
    if (_selectedState == state) {
      return;
    }
    _selectedState = state;
    notifyListeners();
  }

  /// Updates the stored data for the provided state.
  void updateState(automaton_state.State updatedState) {
    final index = _states.indexWhere((state) => state.id == updatedState.id);
    if (index == -1) {
      return;
    }

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

    notifyListeners();
    _emitAutomatonChanged();
  }

  /// Updates the stored position for a state after a drag gesture.
  void updateStatePosition(automaton_state.State updatedState) {
    final index = _states.indexWhere((state) => state.id == updatedState.id);
    if (index == -1) {
      return;
    }

    _states[index] = updatedState;
    notifyListeners();
    _emitAutomatonChanged();
  }

  /// Removes the provided state and all of its transitions.
  void deleteState(automaton_state.State state) {
    _states.removeWhere((s) => s.id == state.id);
    _transitions.removeWhere(
      (transition) =>
          transition.fromState.id == state.id ||
          transition.toState.id == state.id,
    );

    if (_selectedState?.id == state.id) {
      _selectedState = null;
    }

    notifyListeners();
    _emitAutomatonChanged();
  }

  /// Handles the preview origin for transition creation drags.
  void updateTransitionOrigin(automaton_state.State? state) {
    if (!_isAddingTransition) {
      return;
    }

    if (state == null) {
      if (_transitionStart != null || _transitionPreviewPosition != null) {
        _transitionStart = null;
        _transitionPreviewPosition = null;
        notifyListeners();
      }
      return;
    }

    if (_transitionStart != state) {
      _transitionStart = state;
      notifyListeners();
    }
  }

  /// Updates the preview position for a transition being drawn.
  void updateTransitionPreview(Offset? position) {
    if (!_isAddingTransition) {
      return;
    }

    if (_transitionStart == null && position == null) {
      return;
    }

    if (_transitionPreviewPosition != position) {
      _transitionPreviewPosition = position;
      notifyListeners();
    }
  }

  /// Processes a tap during transition creation and returns the target state
  /// if a transition should be created.
  automaton_state.State? prepareTransitionTarget(Offset position) {
    if (!_isAddingTransition) {
      return null;
    }

    final tappedState = _findStateAt(position);
    if (tappedState == null) {
      updateTransitionPreview(position);
      return null;
    }

    if (_transitionStart == null) {
      _transitionStart = tappedState;
      _transitionPreviewPosition = position;
      notifyListeners();
      return null;
    }

    return tappedState;
  }

  /// Resets the controller state after a transition creation attempt.
  void completeTransitionAddition() {
    final shouldNotify = _isAddingTransition ||
        _transitionStart != null ||
        _transitionPreviewPosition != null;

    _isAddingTransition = false;
    _transitionStart = null;
    _transitionPreviewPosition = null;

    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// Adds a new transition between two states.
  void addTransition(
    automaton_state.State from,
    automaton_state.State to,
    TransitionSymbolInput input,
  ) {
    final transition = FSATransition(
      id: 't${_transitions.length + 1}',
      fromState: from,
      toState: to,
      label: input.label,
      inputSymbols: input.inputSymbols,
      lambdaSymbol: input.lambdaSymbol,
    );

    _transitions.add(transition);
    notifyListeners();
    _emitAutomatonChanged();
  }

  /// Updates an existing transition with new data.
  void updateTransition(
    FSATransition transition,
    TransitionSymbolInput input,
  ) {
    final index = _transitions.indexWhere((t) => t.id == transition.id);
    if (index == -1) {
      return;
    }

    _transitions[index] = transition.copyWith(
      label: input.label,
      inputSymbols: input.inputSymbols,
      lambdaSymbol: input.lambdaSymbol,
    );

    notifyListeners();
    _emitAutomatonChanged();
  }

  /// Removes the provided transition from the canvas.
  void deleteTransition(FSATransition transition) {
    final initialLength = _transitions.length;
    _transitions.removeWhere((t) => t.id == transition.id);
    if (initialLength == _transitions.length) {
      return;
    }

    notifyListeners();
    _emitAutomatonChanged();
  }

  automaton_state.State? _findStateAt(Offset position) {
    for (final state in _states.reversed) {
      if (_isPointInState(position, state)) {
        return state;
      }
    }
    return null;
  }

  bool _isPointInState(Offset point, automaton_state.State state) {
    final stateCenter = Offset(state.position.x, state.position.y);
    final distance = (point - stateCenter).distance;
    return distance <= _stateRadius;
  }

  void _emitAutomatonChanged() {
    final automaton = _baseAutomaton;
    final callback = _onAutomatonChanged;
    if (automaton == null || callback == null) {
      return;
    }

    automaton_state.State? initialState;
    for (final state in _states) {
      if (state.isInitial) {
        initialState = state;
        break;
      }
    }

    final acceptingStates =
        _states.where((state) => state.isAccepting).toSet();

    final updatedAutomaton = automaton.copyWith(
      states: _states.toSet(),
      transitions: _transitions.toSet(),
      initialState: initialState,
      acceptingStates: acceptingStates,
    );

    _baseAutomaton = updatedAutomaton;
    callback(updatedAutomaton);
  }
}
