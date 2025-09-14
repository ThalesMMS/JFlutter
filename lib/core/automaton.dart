import 'dart:convert';

/// Minimal data model for Automata, compatible with the web snapshot format.
class Automaton {
  Automaton({
    Set<String>? alphabet,
    List<StateNode>? states,
    Map<String, List<String>>? transitions,
    this.initialId,
    this.nextId = 0,
  })  : alphabet = alphabet ?? <String>{},
        states = states ?? <StateNode>[],
        transitions = transitions ?? <String, List<String>>{};

  Set<String> alphabet;
  List<StateNode> states;
  Map<String, List<String>> transitions; // key: 'src|sym' -> [destIds]
  String? initialId;
  int nextId;

  // Helpers
  Iterable<String> get stateIds => states.map((s) => s.id);
  /// Returns true if the automaton is a valid DFA.
  /// A valid DFA has exactly one transition for each symbol in the alphabet
  /// from each state, and no lambda transitions.
  bool get isDfa {
    if (hasLambda) return false;
    
    for (final state in states) {
      for (final sym in alphabet) {
        final key = '${state.id}|$sym';
        final dests = transitions[key] ?? [];
        if (dests.length != 1) {
          return false;
        }
      }
    }
    
    return true;
  }

  bool get hasLambda => transitions.keys.any((k) => k.contains('|λ'));

  StateNode? getState(String id) => states.firstWhere(
        (s) => s.id == id,
        orElse: () => StateNode.missing,
      ).maybe;

  Automaton clone() => Automaton.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'version': 3,
        'alphabet': alphabet.toList(),
        'states': states.map((s) => s.toJson()).toList(),
        'nextId': nextId,
        'transitions': transitions.entries.map((e) => [e.key, e.value]).toList(),
        'initialId': initialId,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory Automaton.fromJson(Map<String, dynamic> json) {
    final states = (json['states'] as List<dynamic>? ?? [])
        .map((e) => StateNode.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final transitions = <String, List<String>>{};
    for (final pair in (json['transitions'] as List<dynamic>? ?? [])) {
      final list = pair as List;
      final key = list[0] as String;
      final values = (list[1] as List).map((e) => e.toString()).toList();
      transitions[key] = values;
    }
    return Automaton(
      alphabet: {...(json['alphabet'] as List? ?? []).map((e) => e.toString())},
      states: states,
      transitions: transitions,
      initialId: json['initialId']?.toString(),
      nextId: (json['nextId'] is int) ? json['nextId'] as int : states.length,
    );
  }

  factory Automaton.empty() => Automaton();

  factory Automaton.sampleDfa() {
    final s0 = StateNode(id: 'q0', name: 'q0', x: 180, y: 200, isInitial: true, isFinal: false);
    final s1 = StateNode(id: 'q1', name: 'q1', x: 380, y: 200, isInitial: false, isFinal: true);
    return Automaton(
      alphabet: {'A', 'B'},
      states: [s0, s1],
      transitions: {
        '${s0.id}|A': [s1.id],
        '${s1.id}|B': [s0.id],
      },
      initialId: s0.id,
      nextId: 2,
    );
  }

  // Mutation helpers (immutable-ish: return new instance)
  Automaton withAlphabet(Set<String> sigma) {
    final a = clone();
    a.alphabet = {...sigma};
    return a;
  }

  Automaton addState({bool isFinal = false}) {
    final a = clone();
    final id = 'q${a.nextId++}';
    final s = StateNode(id: id, name: id, x: 0, y: 0, isInitial: a.initialId == null, isFinal: isFinal);
    a.states = [...a.states, s];
    a.initialId ??= id;
    return a;
  }

  Automaton toggleFinal(String id) {
    final a = clone();
    a.states = a.states
        .map((s) => s.id == id ? s.copyWith(isFinal: !s.isFinal) : s)
        .toList();
    return a;
  }

  Automaton setInitial(String id) {
    final a = clone();
    a.states = a.states
        .map((s) => s.copyWith(isInitial: s.id == id))
        .toList();
    a.initialId = id;
    return a;
  }

  Automaton removeState(String id) {
    final a = clone();
    a.states = a.states.where((s) => s.id != id).toList();
    a.transitions.removeWhere((k, v) => k.startsWith('$id|'));
    for (final k in a.transitions.keys.toList()) {
      a.transitions[k] = a.transitions[k]!.where((d) => d != id).toList();
      if (a.transitions[k]!.isEmpty) a.transitions.remove(k);
    }
    if (a.initialId == id) {
      a.initialId = a.states.isEmpty ? null : a.states.first.id;
      a.states = a.states
          .map((s) => s.copyWith(isInitial: s.id == a.initialId))
          .toList();
    }
    return a;
  }

  Automaton setTransition(String src, String sym, List<String> dests) {
    final a = clone();
    a.transitions['$src|$sym'] = [...dests];
    return a;
  }

  Automaton removeTransition(String src, String sym) {
    final a = clone();
    a.transitions.remove('$src|$sym');
    return a;
  }

  Automaton setStatePosition(String id, double x, double y) {
    final a = clone();
    a.states = a.states
        .map((s) => s.id == id ? s.copyWith(x: x, y: y) : s)
        .toList();
    return a;
  }

  Automaton setStateName(String id, String name) {
    final a = clone();
    a.states = a.states
        .map((s) => s.id == id ? s.copyWith(name: name) : s)
        .toList();
    return a;
  }
}

class StateNode {
  StateNode({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.isInitial,
    required this.isFinal,
  });

  final String id;
  final String name;
  final double x;
  final double y;
  final bool isInitial;
  final bool isFinal;

  static final StateNode missing = StateNode(id: '__missing__', name: '', x: 0, y: 0, isInitial: false, isFinal: false);
  StateNode? get maybe => id == '__missing__' ? null : this;

  StateNode copyWith({String? id, String? name, double? x, double? y, bool? isInitial, bool? isFinal}) => StateNode(
        id: id ?? this.id,
        name: name ?? this.name,
        x: x ?? this.x,
        y: y ?? this.y,
        isInitial: isInitial ?? this.isInitial,
        isFinal: isFinal ?? this.isFinal,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'x': x,
        'y': y,
        'isInitial': isInitial,
        'isFinal': isFinal,
      };

  factory StateNode.fromJson(Map<String, dynamic> json) => StateNode(
        id: json['id'] as String,
        name: json['name'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        isInitial: json['isInitial'] as bool? ?? false,
        isFinal: json['isFinal'] as bool? ?? false,
      );
}
