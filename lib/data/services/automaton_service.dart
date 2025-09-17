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
        return Result.failure('Automaton name cannot be empty');
      }

      // Create states
      final states = <State>[];
      for (final stateData in request.states) {
        final state = State(
          id: stateData.id,
          name: stateData.name,
          position: stateData.position,
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
          fromState: fromState,
          toState: toState,
          symbol: transitionData.symbol,
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
        transitions: transitions,
        bounds: request.bounds,
        created: DateTime.now(),
        modified: DateTime.now(),
      );

      _automata.add(automaton);
      _nextId++;

      return Result.success(automaton);
    } catch (e) {
      return Result.failure('Error creating automaton: $e');
    }
  }

  /// Gets an automaton by ID
  Result<FSA> getAutomaton(String id) {
    try {
      final automaton = _automata.firstWhere((a) => a.id == id);
      return Result.success(automaton);
    } catch (e) {
      return Result.failure('Automaton not found: $id');
    }
  }

  /// Updates an automaton
  Result<FSA> updateAutomaton(String id, CreateAutomatonRequest request) {
    try {
      final index = _automata.indexWhere((a) => a.id == id);
      if (index == -1) {
        return Result.failure('Automaton not found: $id');
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
      return Result.success(updatedAutomaton);
    } catch (e) {
      return Result.failure('Error updating automaton: $e');
    }
  }

  /// Deletes an automaton
  Result<void> deleteAutomaton(String id) {
    try {
      final index = _automata.indexWhere((a) => a.id == id);
      if (index == -1) {
        return Result.failure('Automaton not found: $id');
      }

      _automata.removeAt(index);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Error deleting automaton: $e');
    }
  }

  /// Lists all automata
  Result<List<FSA>> listAutomata() {
    return Result.success(List.from(_automata));
  }

  /// Clears all automata
  Result<void> clearAutomata() {
    _automata.clear();
    _nextId = 1;
    return Result.success(null);
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
