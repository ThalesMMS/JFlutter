import 'dart:convert';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../../core/models/fsa.dart';
import '../../core/models/state.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/result.dart';
import '../../core/models/automaton.dart' as core_models;

/// Service for automaton CRUD operations
class AutomatonService {
  final List<FSA> _automata = [];
  int _nextId = 1;

  FSA _buildAutomatonFromRequest(
    CreateAutomatonRequest request, {
    required String id,
    DateTime? created,
    DateTime? modified,
  }) {
    if (request.name.isEmpty) {
      throw ArgumentError('Automaton name cannot be empty');
    }

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

    final stateById = {for (final state in states) state.id: state};

    final transitions = <FSATransition>{};
    var transitionIndex = 0;
    for (final transitionData in request.transitions) {
      final fromState = stateById[transitionData.fromStateId];
      final toState = stateById[transitionData.toStateId];
      if (fromState == null || toState == null) {
        throw StateError(
            'Transition references unknown state: ${transitionData.fromStateId} -> ${transitionData.toStateId}');
      }

      final symbol = transitionData.symbol;
      final isLambda = symbol == 'λ' || symbol == 'ε' || symbol.toLowerCase() == 'lambda';

      transitions.add(FSATransition(
        id: 't${id}_$transitionIndex',
        fromState: fromState,
        toState: toState,
        label: symbol,
        inputSymbols: isLambda ? <String>{} : {symbol},
        lambdaSymbol: isLambda ? symbol : null,
      ));
      transitionIndex++;
    }

    State? initialState;
    try {
      initialState = states.firstWhere((s) => s.isInitial);
    } catch (_) {
      initialState = null;
    }

    final acceptingStates = states.where((s) => s.isAccepting).toSet();

    final bounds = math.Rectangle(
      request.bounds.left,
      request.bounds.top,
      request.bounds.right - request.bounds.left,
      request.bounds.bottom - request.bounds.top,
    );

    return FSA(
      id: id,
      name: request.name,
      description: request.description ?? '',
      states: states.toSet(),
      transitions: transitions,
      alphabet: request.alphabet.toSet(),
      initialState: initialState,
      acceptingStates: acceptingStates,
      created: created ?? DateTime.now(),
      modified: modified ?? DateTime.now(),
      bounds: bounds,
    );
  }

  /// Creates a new automaton
  Result<FSA> createAutomaton(CreateAutomatonRequest request) {
    try {
      final id = (_nextId++).toString();
      final automaton = _buildAutomatonFromRequest(
        request,
        id: id,
        created: DateTime.now(),
        modified: DateTime.now(),
      );

      _automata.add(automaton);

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

      final existing = _automata[index];
      final updatedAutomaton = _buildAutomatonFromRequest(
        request,
        id: id,
        created: existing.created,
        modified: DateTime.now(),
      );

      _automata[index] = updatedAutomaton;
      return ResultFactory.success(updatedAutomaton);
    } catch (e) {
      return ResultFactory.failure('Error updating automaton: $e');
    }
  }

  /// Saves an automaton using a specific ID (creates or updates)
  Result<FSA> saveAutomaton(String id, CreateAutomatonRequest request) {
    try {
      final index = _automata.indexWhere((a) => a.id == id);
      final created = index == -1 ? DateTime.now() : _automata[index].created;

      final automaton = _buildAutomatonFromRequest(
        request,
        id: id,
        created: created,
        modified: DateTime.now(),
      );

      if (index == -1) {
        _automata.add(automaton);
      } else {
        _automata[index] = automaton;
      }

      return ResultFactory.success(automaton);
    } catch (e) {
      return ResultFactory.failure('Error saving automaton: $e');
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

  /// Exports an automaton to JSON
  Result<String> exportAutomaton(FSA automaton) {
    try {
      final jsonString = jsonEncode(automaton.toJson());
      return ResultFactory.success(jsonString);
    } catch (e) {
      return ResultFactory.failure('Error exporting automaton: $e');
    }
  }

  /// Imports an automaton from JSON
  Result<FSA> importAutomaton(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return ResultFactory.failure('Invalid automaton JSON format');
      }

      final automaton = core_models.Automaton.fromJson(decoded);
      if (automaton is! FSA) {
        return ResultFactory.failure('Unsupported automaton type for import');
      }

      final index = _automata.indexWhere((a) => a.id == automaton.id);
      if (index == -1) {
        _automata.add(automaton);
      } else {
        _automata[index] = automaton;
      }

      return ResultFactory.success(automaton);
    } catch (e) {
      return ResultFactory.failure('Error importing automaton: $e');
    }
  }

  /// Validates an automaton
  Result<bool> validateAutomaton(FSA automaton) {
    try {
      final errors = automaton.validate();
      if (errors.isEmpty) {
        return ResultFactory.success(true);
      }
      return ResultFactory.failure('Validation failed: ${errors.join(', ')}');
    } catch (e) {
      return ResultFactory.failure('Error validating automaton: $e');
    }
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
