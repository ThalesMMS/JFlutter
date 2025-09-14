import 'dart:convert';

/// Output function type for Mealy machines
typedef MealyOutputFunction = String Function(String state, String input);

/// Output function type for Moore machines  
typedef MooreOutputFunction = String Function(String state);

/// Mealy Machine data model
/// Based on JFLAP's MealyMachine implementation
class MealyMachine {
  MealyMachine({
    Set<String>? alphabet,
    List<MealyState>? states,
    List<MealyTransition>? transitions,
    this.initialId,
    this.nextId = 0,
  })  : alphabet = alphabet ?? <String>{},
        states = states ?? <MealyState>[],
        transitions = transitions ?? <MealyTransition>[];

  Set<String> alphabet;
  List<MealyState> states;
  List<MealyTransition> transitions;
  String? initialId;
  int nextId;

  // Helpers
  Iterable<String> get stateIds => states.map((s) => s.id);
  
  MealyState? getState(String id) => states.firstWhere(
        (s) => s.id == id,
        orElse: () => MealyState.missing,
      ).maybe;

  List<MealyTransition> getTransitionsFromState(String stateId) =>
      transitions.where((t) => t.fromState == stateId).toList();

  List<MealyTransition> getTransitionsToState(String stateId) =>
      transitions.where((t) => t.toState == stateId).toList();

  MealyMachine clone() => MealyMachine.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'version': 1,
        'type': 'mealy',
        'alphabet': alphabet.toList(),
        'states': states.map((s) => s.toJson()).toList(),
        'transitions': transitions.map((t) => t.toJson()).toList(),
        'nextId': nextId,
        'initialId': initialId,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory MealyMachine.fromJson(Map<String, dynamic> json) {
    final states = (json['states'] as List?)
        ?.map((s) => MealyState.fromJson(s))
        .toList() ?? <MealyState>[];
    
    final transitions = (json['transitions'] as List?)
        ?.map((t) => MealyTransition.fromJson(t))
        .toList() ?? <MealyTransition>[];

    return MealyMachine(
      alphabet: Set<String>.from(json['alphabet'] ?? []),
      states: states,
      transitions: transitions,
      nextId: json['nextId'] ?? 0,
      initialId: json['initialId'],
    );
  }

  factory MealyMachine.empty() => MealyMachine();
}

/// Moore Machine data model
/// Based on JFLAP's MooreMachine implementation
class MooreMachine {
  MooreMachine({
    Set<String>? alphabet,
    List<MooreState>? states,
    List<MooreTransition>? transitions,
    this.initialId,
    this.nextId = 0,
  })  : alphabet = alphabet ?? <String>{},
        states = states ?? <MooreState>[],
        transitions = transitions ?? <MooreTransition>[];

  Set<String> alphabet;
  List<MooreState> states;
  List<MooreTransition> transitions;
  String? initialId;
  int nextId;

  // Helpers
  Iterable<String> get stateIds => states.map((s) => s.id);
  
  MooreState? getState(String id) => states.firstWhere(
        (s) => s.id == id,
        orElse: () => MooreState.missing,
      ).maybe;

  List<MooreTransition> getTransitionsFromState(String stateId) =>
      transitions.where((t) => t.fromState == stateId).toList();

  List<MooreTransition> getTransitionsToState(String stateId) =>
      transitions.where((t) => t.toState == stateId).toList();

  MooreMachine clone() => MooreMachine.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'version': 1,
        'type': 'moore',
        'alphabet': alphabet.toList(),
        'states': states.map((s) => s.toJson()).toList(),
        'transitions': transitions.map((t) => t.toJson()).toList(),
        'nextId': nextId,
        'initialId': initialId,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory MooreMachine.fromJson(Map<String, dynamic> json) {
    final states = (json['states'] as List?)
        ?.map((s) => MooreState.fromJson(s))
        .toList() ?? <MooreState>[];
    
    final transitions = (json['transitions'] as List?)
        ?.map((t) => MooreTransition.fromJson(t))
        .toList() ?? <MooreTransition>[];

    return MooreMachine(
      alphabet: Set<String>.from(json['alphabet'] ?? []),
      states: states,
      transitions: transitions,
      nextId: json['nextId'] ?? 0,
      initialId: json['initialId'],
    );
  }

  factory MooreMachine.empty() => MooreMachine();
}

/// State in a Mealy machine
class MealyState {
  MealyState({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.isInitial = false,
    this.isFinal = false,
  });

  final String id;
  final String name;
  final double x;
  final double y;
  final bool isInitial;
  final bool isFinal;

  MealyState copyWith({
    String? id,
    String? name,
    double? x,
    double? y,
    bool? isInitial,
    bool? isFinal,
  }) {
    return MealyState(
      id: id ?? this.id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      isInitial: isInitial ?? this.isInitial,
      isFinal: isFinal ?? this.isFinal,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'x': x,
        'y': y,
        'isInitial': isInitial,
        'isFinal': isFinal,
      };

  factory MealyState.fromJson(Map<String, dynamic> json) {
    return MealyState(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      isInitial: json['isInitial'] ?? false,
      isFinal: json['isFinal'] ?? false,
    );
  }

  static final MealyState missing = MealyState(
    id: '',
    name: 'MISSING',
    x: 0,
    y: 0,
  );

  MealyState? get maybe => this == missing ? null : this;

  @override
  bool operator ==(Object other) =>
      other is MealyState &&
      id == other.id &&
      name == other.name &&
      x == other.x &&
      y == other.y &&
      isInitial == other.isInitial &&
      isFinal == other.isFinal;

  @override
  int get hashCode => Object.hash(id, name, x, y, isInitial, isFinal);
}

/// State in a Moore machine
class MooreState {
  MooreState({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.isInitial = false,
    this.isFinal = false,
    this.output = '',
  });

  final String id;
  final String name;
  final double x;
  final double y;
  final bool isInitial;
  final bool isFinal;
  final String output; // Output associated with this state

  MooreState copyWith({
    String? id,
    String? name,
    double? x,
    double? y,
    bool? isInitial,
    bool? isFinal,
    String? output,
  }) {
    return MooreState(
      id: id ?? this.id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      isInitial: isInitial ?? this.isInitial,
      isFinal: isFinal ?? this.isFinal,
      output: output ?? this.output,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'x': x,
        'y': y,
        'isInitial': isInitial,
        'isFinal': isFinal,
        'output': output,
      };

  factory MooreState.fromJson(Map<String, dynamic> json) {
    return MooreState(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      isInitial: json['isInitial'] ?? false,
      isFinal: json['isFinal'] ?? false,
      output: json['output'] ?? '',
    );
  }

  static final MooreState missing = MooreState(
    id: '',
    name: 'MISSING',
    x: 0,
    y: 0,
  );

  MooreState? get maybe => this == missing ? null : this;

  @override
  bool operator ==(Object other) =>
      other is MooreState &&
      id == other.id &&
      name == other.name &&
      x == other.x &&
      y == other.y &&
      isInitial == other.isInitial &&
      isFinal == other.isFinal &&
      output == other.output;

  @override
  int get hashCode => Object.hash(id, name, x, y, isInitial, isFinal, output);
}

/// Transition in a Mealy machine
class MealyTransition {
  MealyTransition({
    required this.fromState,
    required this.toState,
    required this.input,
    required this.output,
  });

  final String fromState;
  final String toState;
  final String input;
  final String output; // Output produced by this transition

  Map<String, dynamic> toJson() => {
        'fromState': fromState,
        'toState': toState,
        'input': input,
        'output': output,
      };

  factory MealyTransition.fromJson(Map<String, dynamic> json) {
    return MealyTransition(
      fromState: json['fromState'] ?? '',
      toState: json['toState'] ?? '',
      input: json['input'] ?? '',
      output: json['output'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MealyTransition &&
      fromState == other.fromState &&
      toState == other.toState &&
      input == other.input &&
      output == other.output;

  @override
  int get hashCode => Object.hash(fromState, toState, input, output);
}

/// Transition in a Moore machine
class MooreTransition {
  MooreTransition({
    required this.fromState,
    required this.toState,
    required this.input,
  });

  final String fromState;
  final String toState;
  final String input;

  Map<String, dynamic> toJson() => {
        'fromState': fromState,
        'toState': toState,
        'input': input,
      };

  factory MooreTransition.fromJson(Map<String, dynamic> json) {
    return MooreTransition(
      fromState: json['fromState'] ?? '',
      toState: json['toState'] ?? '',
      input: json['input'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MooreTransition &&
      fromState == other.fromState &&
      toState == other.toState &&
      input == other.input;

  @override
  int get hashCode => Object.hash(fromState, toState, input);
}

/// Configuration for Mealy machine simulation
class MealyConfiguration {
  MealyConfiguration({
    required this.state,
    required this.input,
    required this.unprocessedInput,
    required this.output,
  });

  final String state;
  final String input;
  final String unprocessedInput;
  final String output; // Output produced so far

  MealyConfiguration copyWith({
    String? state,
    String? input,
    String? unprocessedInput,
    String? output,
  }) {
    return MealyConfiguration(
      state: state ?? this.state,
      input: input ?? this.input,
      unprocessedInput: unprocessedInput ?? this.unprocessedInput,
      output: output ?? this.output,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MealyConfiguration &&
      state == other.state &&
      input == other.input &&
      unprocessedInput == other.unprocessedInput &&
      output == other.output;

  @override
  int get hashCode => Object.hash(state, input, unprocessedInput, output);
}

/// Configuration for Moore machine simulation
class MooreConfiguration {
  MooreConfiguration({
    required this.state,
    required this.input,
    required this.unprocessedInput,
    required this.output,
  });

  final String state;
  final String input;
  final String unprocessedInput;
  final String output; // Output produced so far

  MooreConfiguration copyWith({
    String? state,
    String? input,
    String? unprocessedInput,
    String? output,
  }) {
    return MooreConfiguration(
      state: state ?? this.state,
      input: input ?? this.input,
      unprocessedInput: unprocessedInput ?? this.unprocessedInput,
      output: output ?? this.output,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MooreConfiguration &&
      state == other.state &&
      input == other.input &&
      unprocessedInput == other.unprocessedInput &&
      output == other.output;

  @override
  int get hashCode => Object.hash(state, input, unprocessedInput, output);
}
