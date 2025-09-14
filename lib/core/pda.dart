import 'dart:convert';

/// Pushdown Automaton (PDA) data model
/// Based on JFLAP's PushdownAutomaton implementation
class PushdownAutomaton {
  PushdownAutomaton({
    Set<String>? alphabet,
    Set<String>? stackAlphabet,
    List<PDAState>? states,
    List<PDATransition>? transitions,
    this.initialId,
    this.nextId = 0,
    this.acceptanceMode = AcceptanceMode.finalState,
    this.singleInputPDA = false,
  })  : alphabet = alphabet ?? <String>{},
        stackAlphabet = stackAlphabet ?? <String>{},
        states = states ?? <PDAState>[],
        transitions = transitions ?? <PDATransition>[];

  Set<String> alphabet;
  Set<String> stackAlphabet;
  List<PDAState> states;
  List<PDATransition> transitions;
  String? initialId;
  int nextId;
  AcceptanceMode acceptanceMode;
  bool singleInputPDA;

  // Helpers
  Iterable<String> get stateIds => states.map((s) => s.id);
  
  PDAState? getState(String id) => states.firstWhere(
        (s) => s.id == id,
        orElse: () => PDAState.missing,
      ).maybe;

  List<PDATransition> getTransitionsFromState(String stateId) =>
      transitions.where((t) => t.fromState == stateId).toList();

  List<PDATransition> getTransitionsToState(String stateId) =>
      transitions.where((t) => t.toState == stateId).toList();

  PushdownAutomaton clone() => PushdownAutomaton.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'version': 1,
        'type': 'pda',
        'alphabet': alphabet.toList(),
        'stackAlphabet': stackAlphabet.toList(),
        'states': states.map((s) => s.toJson()).toList(),
        'transitions': transitions.map((t) => t.toJson()).toList(),
        'nextId': nextId,
        'initialId': initialId,
        'acceptanceMode': acceptanceMode.name,
        'singleInputPDA': singleInputPDA,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory PushdownAutomaton.fromJson(Map<String, dynamic> json) {
    final states = (json['states'] as List<dynamic>? ?? [])
        .map((e) => PDAState.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final transitions = (json['transitions'] as List<dynamic>? ?? [])
        .map((e) => PDATransition.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    
    return PushdownAutomaton(
      alphabet: {...(json['alphabet'] as List? ?? []).map((e) => e.toString())},
      stackAlphabet: {...(json['stackAlphabet'] as List? ?? []).map((e) => e.toString())},
      states: states,
      transitions: transitions,
      initialId: json['initialId']?.toString(),
      nextId: (json['nextId'] is int) ? json['nextId'] as int : states.length,
      acceptanceMode: AcceptanceMode.values.firstWhere(
        (mode) => mode.name == json['acceptanceMode'],
        orElse: () => AcceptanceMode.finalState,
      ),
      singleInputPDA: json['singleInputPDA'] as bool? ?? false,
    );
  }

  factory PushdownAutomaton.empty() => PushdownAutomaton();

  // Mutation helpers (immutable-ish: return new instance)
  PushdownAutomaton withAlphabet(Set<String> sigma) {
    final pda = clone();
    pda.alphabet = {...sigma};
    return pda;
  }

  PushdownAutomaton withStackAlphabet(Set<String> stackSigma) {
    final pda = clone();
    pda.stackAlphabet = {...stackSigma};
    return pda;
  }

  PushdownAutomaton addState({bool isFinal = false}) {
    final pda = clone();
    final id = 'q${pda.nextId++}';
    final s = PDAState(
      id: id, 
      name: id, 
      x: 0, 
      y: 0, 
      isInitial: pda.initialId == null, 
      isFinal: isFinal
    );
    pda.states = [...pda.states, s];
    pda.initialId ??= id;
    return pda;
  }

  PushdownAutomaton toggleFinal(String id) {
    final pda = clone();
    pda.states = pda.states
        .map((s) => s.id == id ? s.copyWith(isFinal: !s.isFinal) : s)
        .toList();
    return pda;
  }

  PushdownAutomaton setInitial(String id) {
    final pda = clone();
    pda.states = pda.states
        .map((s) => s.copyWith(isInitial: s.id == id))
        .toList();
    pda.initialId = id;
    return pda;
  }

  PushdownAutomaton removeState(String id) {
    final pda = clone();
    pda.states = pda.states.where((s) => s.id != id).toList();
    pda.transitions = pda.transitions.where((t) => t.fromState != id && t.toState != id).toList();
    
    if (pda.initialId == id) {
      pda.initialId = pda.states.isEmpty ? null : pda.states.first.id;
      pda.states = pda.states
          .map((s) => s.copyWith(isInitial: s.id == pda.initialId))
          .toList();
    }
    return pda;
  }

  PushdownAutomaton addTransition(PDATransition transition) {
    final pda = clone();
    pda.transitions = [...pda.transitions, transition];
    return pda;
  }

  PushdownAutomaton removeTransition(PDATransition transition) {
    final pda = clone();
    pda.transitions = pda.transitions.where((t) => t != transition).toList();
    return pda;
  }

  PushdownAutomaton setStatePosition(String id, double x, double y) {
    final pda = clone();
    pda.states = pda.states
        .map((s) => s.id == id ? s.copyWith(x: x, y: y) : s)
        .toList();
    return pda;
  }

  PushdownAutomaton setStateName(String id, String name) {
    final pda = clone();
    pda.states = pda.states
        .map((s) => s.id == id ? s.copyWith(name: name) : s)
        .toList();
    return pda;
  }

  PushdownAutomaton setAcceptanceMode(AcceptanceMode mode) {
    final pda = clone();
    pda.acceptanceMode = mode;
    return pda;
  }
}

/// PDA State model
class PDAState {
  PDAState({
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

  static final PDAState missing = PDAState(
    id: '__missing__', 
    name: '', 
    x: 0, 
    y: 0, 
    isInitial: false, 
    isFinal: false
  );
  
  PDAState? get maybe => id == '__missing__' ? null : this;

  PDAState copyWith({
    String? id, 
    String? name, 
    double? x, 
    double? y, 
    bool? isInitial, 
    bool? isFinal
  }) => PDAState(
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

  factory PDAState.fromJson(Map<String, dynamic> json) => PDAState(
        id: json['id'] as String,
        name: json['name'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        isInitial: json['isInitial'] as bool? ?? false,
        isFinal: json['isFinal'] as bool? ?? false,
      );
}

/// PDA Transition model
/// Based on JFLAP's PDATransition implementation
class PDATransition {
  PDATransition({
    required this.fromState,
    required this.toState,
    required this.inputToRead,
    required this.stringToPop,
    required this.stringToPush,
  });

  final String fromState;
  final String toState;
  final String inputToRead; // Input symbol to read (can be empty for lambda)
  final String stringToPop; // String to pop from stack (can be empty)
  final String stringToPush; // String to push to stack (can be empty)

  String get description {
    final input = inputToRead.isEmpty ? 'λ' : inputToRead;
    final pop = stringToPop.isEmpty ? 'λ' : stringToPop;
    final push = stringToPush.isEmpty ? 'λ' : stringToPush;
    return '$input, $pop; $push';
  }

  PDATransition copyWith({
    String? fromState,
    String? toState,
    String? inputToRead,
    String? stringToPop,
    String? stringToPush,
  }) => PDATransition(
        fromState: fromState ?? this.fromState,
        toState: toState ?? this.toState,
        inputToRead: inputToRead ?? this.inputToRead,
        stringToPop: stringToPop ?? this.stringToPop,
        stringToPush: stringToPush ?? this.stringToPush,
      );

  Map<String, dynamic> toJson() => {
        'fromState': fromState,
        'toState': toState,
        'inputToRead': inputToRead,
        'stringToPop': stringToPop,
        'stringToPush': stringToPush,
      };

  factory PDATransition.fromJson(Map<String, dynamic> json) => PDATransition(
        fromState: json['fromState'] as String,
        toState: json['toState'] as String,
        inputToRead: json['inputToRead'] as String? ?? '',
        stringToPop: json['stringToPop'] as String? ?? '',
        stringToPush: json['stringToPush'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDATransition &&
          runtimeType == other.runtimeType &&
          fromState == other.fromState &&
          toState == other.toState &&
          inputToRead == other.inputToRead &&
          stringToPop == other.stringToPop &&
          stringToPush == other.stringToPush;

  @override
  int get hashCode =>
      fromState.hashCode ^
      toState.hashCode ^
      inputToRead.hashCode ^
      stringToPop.hashCode ^
      stringToPush.hashCode;

  @override
  String toString() => 'PDATransition($fromState -> $toState: $description)';
}

/// PDA Acceptance modes
enum AcceptanceMode {
  finalState,
  emptyStack,
}

/// PDA Configuration for simulation
/// Based on JFLAP's PDAConfiguration implementation
class PDAConfiguration {
  PDAConfiguration({
    required this.state,
    required this.input,
    required this.unprocessedInput,
    required this.stack,
    required this.acceptanceMode,
    this.parent,
  });

  final String state;
  final String input;
  final String unprocessedInput;
  final CharacterStack stack;
  final AcceptanceMode acceptanceMode;
  final PDAConfiguration? parent;

  bool get isAccept {
    switch (acceptanceMode) {
      case AcceptanceMode.finalState:
        return unprocessedInput.isEmpty; // Final state check is done externally
      case AcceptanceMode.emptyStack:
        return unprocessedInput.isEmpty && stack.isEmpty;
    }
  }

  PDAConfiguration copyWith({
    String? state,
    String? input,
    String? unprocessedInput,
    CharacterStack? stack,
    AcceptanceMode? acceptanceMode,
    PDAConfiguration? parent,
  }) => PDAConfiguration(
        state: state ?? this.state,
        input: input ?? this.input,
        unprocessedInput: unprocessedInput ?? this.unprocessedInput,
        stack: stack ?? this.stack.clone(),
        acceptanceMode: acceptanceMode ?? this.acceptanceMode,
        parent: parent ?? this.parent,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDAConfiguration &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          unprocessedInput == other.unprocessedInput &&
          stack == other.stack;

  @override
  int get hashCode => state.hashCode ^ unprocessedInput.hashCode ^ stack.hashCode;

  @override
  String toString() => 'PDAConfig($state, input: $unprocessedInput, stack: $stack)';
}

/// Character Stack for PDA simulation
/// Based on JFLAP's CharacterStack implementation
class CharacterStack {
  CharacterStack({String? initialContent}) 
      : _buffer = StringBuffer(initialContent ?? '');

  final StringBuffer _buffer;

  void push(String string) {
    final current = _buffer.toString();
    _buffer.clear();
    _buffer.write(string + current);
  }

  void pushChar(String char) {
    if (char.isNotEmpty) {
      final current = _buffer.toString();
      _buffer.clear();
      _buffer.write(char + current);
    }
  }

  String pop() {
    if (_buffer.isEmpty) return '';
    final current = _buffer.toString();
    final char = current[0];
    _buffer.clear();
    _buffer.write(current.substring(1));
    return char;
  }

  String popString(int length) {
    if (_buffer.length < length) return '';
    final current = _buffer.toString();
    final result = current.substring(0, length);
    _buffer.clear();
    _buffer.write(current.substring(length));
    return result;
  }

  String get top => _buffer.isEmpty ? '' : _buffer.toString()[0];

  bool get isEmpty => _buffer.isEmpty;

  int get height => _buffer.length;

  void clear() {
    _buffer.clear();
  }

  CharacterStack clone() => CharacterStack(initialContent: _buffer.toString());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterStack &&
          runtimeType == other.runtimeType &&
          _buffer.toString() == other._buffer.toString();

  @override
  int get hashCode => _buffer.toString().hashCode;

  @override
  String toString() => _buffer.toString();
}
