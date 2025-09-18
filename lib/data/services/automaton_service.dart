import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../../core/models/fsa.dart';
import '../../core/models/state.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/result.dart';

/// Service for automaton CRUD operations
class AutomatonService {
  final List<FSA> _automata = [];
  int _nextId = 1;

  /// Creates a new automaton
  Result<FSA> createAutomaton(CreateAutomatonRequest request) {
    try {
      // Validate request
      if (request.name.isEmpty) {
            return ResultFactory.failure('Automaton name cannot be empty');
      }

      // Create states
      final states = <State>[];
      for (final stateData in request.states) {
        final state = State(
          id: stateData.id,
          label: stateData.name,
          position: Vector2(stateData.position.x, stateData.position.y),
          isInitial: stateData.isInitial,
          isAccepting: stateData.isAccepting,
        );
        states.add(state);
      }

      // Create transitions
      final transitions = <FSATransition>[];
      for (final transitionData in request.transitions) {
        final fromState = states.firstWhere((s) => s.id == transitionData.fromStateId);
        final toState = states.firstWhere((s) => s.id == transitionData.toStateId);
        
        final transition = FSATransition(
          id: 't${_nextId++}',
          fromState: fromState,
          toState: toState,
          label: transitionData.symbol,
          inputSymbols: {transitionData.symbol},
        );
        transitions.add(transition);
      }

      // Create automaton
      final automaton = FSA(
        id: _nextId.toString(),
        name: request.name,
        description: request.description ?? '',
        states: states.toSet(),
        alphabet: request.alphabet.toSet(),
        initialState: states.firstWhere((s) => s.isInitial),
        acceptingStates: states.where((s) => s.isAccepting).toSet(),
        transitions: transitions.toSet(),
        bounds: math.Rectangle(
          request.bounds.left,
          request.bounds.top,
          request.bounds.right - request.bounds.left,
          request.bounds.bottom - request.bounds.top,
        ),
        created: DateTime.now(),
        modified: DateTime.now(),
      );

      _automata.add(automaton);
      _nextId++;

      return ResultFactory.success(automaton);
    } catch (e) {
          return ResultFactory.failure('Error creating automaton: $e');
    }
  }

  /// Gets an automaton by ID
  Result<FSA> getAutomaton(String id) {
    try {
      final automaton = _automata.firstWhere((a) => a.id == id);
      return ResultFactory.success(automaton);
    } catch (e) {
      return ResultFactory.failure('Automaton not found: $id');
    }
  }

  /// Updates an automaton
  Result<FSA> updateAutomaton(String id, CreateAutomatonRequest request) {
    try {
      final index = _automata.indexWhere((a) => a.id == id);
      if (index == -1) {
        return ResultFactory.failure('Automaton not found: $id');
      }

      // Create updated automaton (similar to createAutomaton)
      final result = createAutomaton(request);
      if (!result.isSuccess) {
        return result;
      }

      final updatedAutomaton = result.data!.copyWith(
        id: id,
        modified: DateTime.now(),
      );

      _automata[index] = updatedAutomaton;
          return ResultFactory.success(updatedAutomaton);
    } catch (e) {
          return ResultFactory.failure('Error updating automaton: $e');
    }
  }

  /// Deletes an automaton
  Result<void> deleteAutomaton(String id) {
    try {
      final index = _automata.indexWhere((a) => a.id == id);
      if (index == -1) {
        return ResultFactory.failure('Automaton not found: $id');
      }

      _automata.removeAt(index);
      return ResultFactory.success(null);
    } catch (e) {
          return ResultFactory.failure('Error deleting automaton: $e');
    }
  }

  /// Lists all automata
  Result<List<FSA>> listAutomata() {
        return ResultFactory.success(List.from(_automata));
  }

  /// Clears all automata
  Result<void> clearAutomata() {
    _automata.clear();
    _nextId = 1;
    return ResultFactory.success(null);
  }
}

/// Request for creating an automaton
class CreateAutomatonRequest {
  final String name;
  final String? description;
  final List<StateData> states;
  final List<TransitionData> transitions;
  final List<String> alphabet;
  final Rect bounds;

  const CreateAutomatonRequest({
    required this.name,
    this.description,
    required this.states,
    required this.transitions,
    required this.alphabet,
    required this.bounds,
  });
}

/// Data for a state
class StateData {
  final String id;
  final String name;
  final Point position;
  final bool isInitial;
  final bool isAccepting;

  const StateData({
    required this.id,
    required this.name,
    required this.position,
    required this.isInitial,
    required this.isAccepting,
  });
}

/// Data for a transition
class TransitionData {
  final String fromStateId;
  final String toStateId;
  final String symbol;

  const TransitionData({
    required this.fromStateId,
    required this.toStateId,
    required this.symbol,
  });
}

/// Simple Point class
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);
}

/// Simple Rect class
class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const Rect(this.left, this.top, this.right, this.bottom);
}
