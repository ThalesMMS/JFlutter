import 'dart:convert';

/// Turing Machine data model
/// Based on JFLAP's TuringMachine implementation
class TuringMachine {
  TuringMachine({
    Set<String>? alphabet,
    List<TMState>? states,
    List<TMTransition>? transitions,
    this.initialId,
    this.nextId = 0,
    this.numTapes = 1,
    this.acceptanceMode = AcceptanceMode.finalState,
  })  : alphabet = alphabet ?? <String>{},
        states = states ?? <TMState>[],
        transitions = transitions ?? <TMTransition>[];

  Set<String> alphabet;
  List<TMState> states;
  List<TMTransition> transitions;
  String? initialId;
  int nextId;
  int numTapes;
  AcceptanceMode acceptanceMode;

  // Helpers
  Iterable<String> get stateIds => states.map((s) => s.id);
  
  TMState? getState(String id) => states.firstWhere(
        (s) => s.id == id,
        orElse: () => TMState.missing,
      ).maybe;

  List<TMTransition> getTransitionsFromState(String stateId) =>
      transitions.where((t) => t.fromState == stateId).toList();

  List<TMTransition> getTransitionsToState(String stateId) =>
      transitions.where((t) => t.toState == stateId).toList();

  TuringMachine clone() => TuringMachine.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'version': 1,
        'type': 'turing',
        'alphabet': alphabet.toList(),
        'states': states.map((s) => s.toJson()).toList(),
        'transitions': transitions.map((t) => t.toJson()).toList(),
        'nextId': nextId,
        'initialId': initialId,
        'numTapes': numTapes,
        'acceptanceMode': acceptanceMode.name,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory TuringMachine.fromJson(Map<String, dynamic> json) {
    final states = (json['states'] as List<dynamic>? ?? [])
        .map((e) => TMState.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final transitions = (json['transitions'] as List<dynamic>? ?? [])
        .map((e) => TMTransition.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    
    return TuringMachine(
      alphabet: {...(json['alphabet'] as List? ?? []).map((e) => e.toString())},
      states: states,
      transitions: transitions,
      initialId: json['initialId']?.toString(),
      nextId: (json['nextId'] is int) ? json['nextId'] as int : states.length,
      numTapes: json['numTapes'] as int? ?? 1,
      acceptanceMode: AcceptanceMode.values.firstWhere(
        (mode) => mode.name == json['acceptanceMode'],
        orElse: () => AcceptanceMode.finalState,
      ),
    );
  }

  factory TuringMachine.empty() => TuringMachine();

  // Mutation helpers (immutable-ish: return new instance)
  TuringMachine withAlphabet(Set<String> sigma) {
    final tm = clone();
    tm.alphabet = {...sigma};
    return tm;
  }

  TuringMachine withNumTapes(int tapes) {
    final tm = clone();
    tm.numTapes = tapes;
    return tm;
  }

  TuringMachine addState({bool isFinal = false}) {
    final tm = clone();
    final id = 'q${tm.nextId++}';
    final s = TMState(
      id: id, 
      name: id, 
      x: 0, 
      y: 0, 
      isInitial: tm.initialId == null, 
      isFinal: isFinal
    );
    tm.states = [...tm.states, s];
    tm.initialId ??= id;
    return tm;
  }

  TuringMachine toggleFinal(String id) {
    final tm = clone();
    tm.states = tm.states
        .map((s) => s.id == id ? s.copyWith(isFinal: !s.isFinal) : s)
        .toList();
    return tm;
  }

  TuringMachine setInitial(String id) {
    final tm = clone();
    tm.states = tm.states
        .map((s) => s.copyWith(isInitial: s.id == id))
        .toList();
    tm.initialId = id;
    return tm;
  }

  TuringMachine removeState(String id) {
    final tm = clone();
    tm.states = tm.states.where((s) => s.id != id).toList();
    tm.transitions = tm.transitions.where((t) => t.fromState != id && t.toState != id).toList();
    
    if (tm.initialId == id) {
      tm.initialId = tm.states.isEmpty ? null : tm.states.first.id;
      tm.states = tm.states
          .map((s) => s.copyWith(isInitial: s.id == tm.initialId))
          .toList();
    }
    return tm;
  }

  TuringMachine addTransition(TMTransition transition) {
    final tm = clone();
    tm.transitions = [...tm.transitions, transition];
    return tm;
  }

  TuringMachine removeTransition(TMTransition transition) {
    final tm = clone();
    tm.transitions = tm.transitions.where((t) => t != transition).toList();
    return tm;
  }

  TuringMachine setStatePosition(String id, double x, double y) {
    final tm = clone();
    tm.states = tm.states
        .map((s) => s.id == id ? s.copyWith(x: x, y: y) : s)
        .toList();
    return tm;
  }

  TuringMachine setStateName(String id, String name) {
    final tm = clone();
    tm.states = tm.states
        .map((s) => s.id == id ? s.copyWith(name: name) : s)
        .toList();
    return tm;
  }

  TuringMachine setAcceptanceMode(AcceptanceMode mode) {
    final tm = clone();
    tm.acceptanceMode = mode;
    return tm;
  }
}

/// Turing Machine State model
class TMState {
  TMState({
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

  static final TMState missing = TMState(
    id: '__missing__', 
    name: '', 
    x: 0, 
    y: 0, 
    isInitial: false, 
    isFinal: false
  );
  
  TMState? get maybe => id == '__missing__' ? null : this;

  TMState copyWith({
    String? id, 
    String? name, 
    double? x, 
    double? y, 
    bool? isInitial, 
    bool? isFinal
  }) => TMState(
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

  factory TMState.fromJson(Map<String, dynamic> json) => TMState(
        id: json['id'] as String,
        name: json['name'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        isInitial: json['isInitial'] as bool? ?? false,
        isFinal: json['isFinal'] as bool? ?? false,
      );
}

/// Turing Machine Transition model
/// Based on JFLAP's TMTransition implementation
class TMTransition {
  TMTransition({
    required this.fromState,
    required this.toState,
    required this.readSymbols,
    required this.writeSymbols,
    required this.directions,
  }) : assert(readSymbols.length == writeSymbols.length && 
              writeSymbols.length == directions.length,
              'All arrays must have the same length');

  final String fromState;
  final String toState;
  final List<String> readSymbols; // Symbols to read from each tape
  final List<String> writeSymbols; // Symbols to write to each tape
  final List<String> directions; // Directions: 'L', 'R', 'S'

  int get numTapes => readSymbols.length;

  String get description {
    final buffer = StringBuffer();
    for (int i = 0; i < numTapes; i++) {
      if (i > 0) buffer.write(' | ');
      buffer.write(readSymbols[i]);
      buffer.write(' ; ');
      buffer.write(writeSymbols[i]);
      buffer.write(' , ');
      buffer.write(directions[i]);
    }
    return buffer.toString();
  }

  TMTransition copyWith({
    String? fromState,
    String? toState,
    List<String>? readSymbols,
    List<String>? writeSymbols,
    List<String>? directions,
  }) => TMTransition(
        fromState: fromState ?? this.fromState,
        toState: toState ?? this.toState,
        readSymbols: readSymbols ?? List.from(this.readSymbols),
        writeSymbols: writeSymbols ?? List.from(this.writeSymbols),
        directions: directions ?? List.from(this.directions),
      );

  Map<String, dynamic> toJson() => {
        'fromState': fromState,
        'toState': toState,
        'readSymbols': readSymbols,
        'writeSymbols': writeSymbols,
        'directions': directions,
      };

  factory TMTransition.fromJson(Map<String, dynamic> json) => TMTransition(
        fromState: json['fromState'] as String,
        toState: json['toState'] as String,
        readSymbols: List<String>.from(json['readSymbols'] as List? ?? []),
        writeSymbols: List<String>.from(json['writeSymbols'] as List? ?? []),
        directions: List<String>.from(json['directions'] as List? ?? []),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TMTransition &&
          runtimeType == other.runtimeType &&
          fromState == other.fromState &&
          toState == other.toState &&
          _listEquals(readSymbols, other.readSymbols) &&
          _listEquals(writeSymbols, other.writeSymbols) &&
          _listEquals(directions, other.directions);

  @override
  int get hashCode =>
      fromState.hashCode ^
      toState.hashCode ^
      readSymbols.hashCode ^
      writeSymbols.hashCode ^
      directions.hashCode;

  @override
  String toString() => 'TMTransition($fromState -> $toState: $description)';

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Turing Machine Acceptance modes
enum AcceptanceMode {
  finalState,
  halting,
}

/// Turing Machine Configuration for simulation
/// Based on JFLAP's TMConfiguration implementation
class TMConfiguration {
  TMConfiguration({
    required this.state,
    required this.tapes,
    required this.acceptanceMode,
    this.parent,
    this.isHalted = false,
  });

  final String state;
  final List<Tape> tapes;
  final AcceptanceMode acceptanceMode;
  final TMConfiguration? parent;
  final bool isHalted;

  bool get isAccept {
    switch (acceptanceMode) {
      case AcceptanceMode.finalState:
        return false; // Final state check is done externally
      case AcceptanceMode.halting:
        return isHalted;
    }
  }

  TMConfiguration copyWith({
    String? state,
    List<Tape>? tapes,
    AcceptanceMode? acceptanceMode,
    TMConfiguration? parent,
    bool? isHalted,
  }) => TMConfiguration(
        state: state ?? this.state,
        tapes: tapes ?? this.tapes.map((t) => t.clone()).toList(),
        acceptanceMode: acceptanceMode ?? this.acceptanceMode,
        parent: parent ?? this.parent,
        isHalted: isHalted ?? this.isHalted,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TMConfiguration &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          _listEquals(tapes, other.tapes);

  @override
  int get hashCode => state.hashCode ^ tapes.hashCode;

  @override
  String toString() {
    final buffer = StringBuffer('TMConfig($state');
    for (int i = 0; i < tapes.length; i++) {
      buffer.write(', tape$i: ${tapes[i]}');
    }
    buffer.write(')');
    return buffer.toString();
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Tape for Turing Machine simulation
/// Based on JFLAP's Tape implementation
class Tape {
  Tape({String? initialContent}) 
      : _buffer = StringBuffer(initialContent ?? ''),
        _tapeHead = 0;

  final StringBuffer _buffer;
  int _tapeHead;

  static const String blank = '□'; // Unicode blank symbol

  int get tapeHead => _tapeHead;

  String get contents => _buffer.toString();

  String get output {
    final nextBlank = _buffer.toString().indexOf(blank, _tapeHead);
    final end = nextBlank == -1 ? _buffer.length : nextBlank;
    return _buffer.toString().substring(_tapeHead, end);
  }

  String read() {
    if (_tapeHead >= _buffer.length) return blank;
    return _buffer.toString()[_tapeHead];
  }

  void write(String symbol) {
    if (_tapeHead >= _buffer.length) {
      // Extend buffer with blanks
      while (_buffer.length <= _tapeHead) {
        _buffer.write(blank);
      }
    }
    final current = _buffer.toString();
    if (_tapeHead < current.length) {
      final newContent = current.substring(0, _tapeHead) + symbol + current.substring(_tapeHead + 1);
      _buffer.clear();
      _buffer.write(newContent);
    } else {
      _buffer.write(symbol);
    }
  }

  void moveHead(String direction) {
    switch (direction) {
      case 'L':
        _tapeHead--;
        break;
      case 'R':
        _tapeHead++;
        break;
      case 'S':
        // Stay
        break;
      default:
        throw ArgumentError('Invalid direction: $direction');
    }

    // Extend buffer if necessary
    if (_tapeHead >= _buffer.length) {
      while (_buffer.length <= _tapeHead) {
        _buffer.write(blank);
      }
    } else if (_tapeHead < 0) {
      final numToInsert = -_tapeHead;
      final current = _buffer.toString();
      _buffer.clear();
      _buffer.write(blank * numToInsert + current);
      _tapeHead = 0;
    }
  }

  Tape clone() => Tape(initialContent: _buffer.toString()).._tapeHead = _tapeHead;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tape &&
          runtimeType == other.runtimeType &&
          _buffer.toString() == other._buffer.toString() &&
          _tapeHead == other._tapeHead;

  @override
  int get hashCode => _buffer.toString().hashCode ^ _tapeHead.hashCode;

  @override
  String toString() => '[$contents] HEAD AT $_tapeHead';
}
