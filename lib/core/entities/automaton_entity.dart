import '../result.dart';

/// Core domain entity representing an automaton
/// This is the central business entity that all other layers depend on
class AutomatonEntity {
  final String id;
  final String name;
  final Set<String> alphabet;
  final List<StateEntity> states;
  final Map<String, List<String>> transitions;
  final String? initialId;
  final int nextId;
  final AutomatonType type;

  const AutomatonEntity({
    required this.id,
    required this.name,
    required this.alphabet,
    required this.states,
    required this.transitions,
    this.initialId,
    required this.nextId,
    required this.type,
  });

  AutomatonEntity copyWith({
    String? id,
    String? name,
    Set<String>? alphabet,
    List<StateEntity>? states,
    Map<String, List<String>>? transitions,
    String? initialId,
    int? nextId,
    AutomatonType? type,
  }) {
    return AutomatonEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      alphabet: alphabet ?? this.alphabet,
      states: states ?? this.states,
      transitions: transitions ?? this.transitions,
      initialId: initialId ?? this.initialId,
      nextId: nextId ?? this.nextId,
      type: type ?? this.type,
    );
  }

  /// Checks if the automaton has lambda transitions
  bool get hasLambda =>
      alphabet.contains('λ') ||
      transitions.keys.any((key) => key.endsWith('|λ'));

  /// Gets a state by its ID
  StateEntity? getState(String stateId) {
    try {
      return states.firstWhere((s) => s.id == stateId);
    } catch (_) {
      return null;
    }
  }

  /// Gets all state IDs
  List<String> get stateIds => states.map((s) => s.id).toList();

  /// Gets final states
  List<StateEntity> get finalStates => states.where((s) => s.isFinal).toList();

  /// Gets initial state
  StateEntity? get initialState => getState(initialId ?? '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutomatonEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AutomatonEntity(id: $id, name: $name, type: $type)';
}

/// Represents a state in an automaton
class StateEntity {
  final String id;
  final String name;
  final double x;
  final double y;
  final bool isInitial;
  final bool isFinal;

  const StateEntity({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.isInitial,
    required this.isFinal,
  });

  StateEntity copyWith({
    String? id,
    String? name,
    double? x,
    double? y,
    bool? isInitial,
    bool? isFinal,
  }) {
    return StateEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      isInitial: isInitial ?? this.isInitial,
      isFinal: isFinal ?? this.isFinal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'StateEntity(id: $id, name: $name)';
}

/// Types of automata
enum AutomatonType {
  dfa('DFA'),
  nfa('NFA'),
  nfaLambda('NFA-λ'),
  grammar('Grammar'),
  regex('Regex');

  const AutomatonType(this.displayName);
  final String displayName;
}
