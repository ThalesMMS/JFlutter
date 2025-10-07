//
//  turing_machine_dto.dart
//  JFlutter
//
//  Estruturas de transporte que descrevem máquinas de Turing completas,
//  incluindo alfabetos, estados, transições aninhadas e símbolos especiais para
//  serialização confiável em JSON ou formatos derivados do JFLAP.
//  Utiliza coleções imutáveis, igualdade profunda e fábricas de conversão para
//  garantir consistência durante importações, exportações e persistência local.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:collection/collection.dart';

class TuringMachineDto {
  const TuringMachineDto({
    required this.id,
    required this.name,
    required this.type,
    required this.inputAlphabet,
    required this.tapeAlphabet,
    required this.states,
    required this.initialState,
    required this.finalStates,
    required this.blankSymbol,
    required this.transitions,
  });

  factory TuringMachineDto.fromJson(Map<String, dynamic> json) {
    final transitionsJson = Map<String, dynamic>.from(
      json['transitions'] as Map,
    );
    final transitions = transitionsJson.map((state, value) {
      final stateTransitions = Map<String, dynamic>.from(value as Map);
      return MapEntry(
        state,
        stateTransitions.map(
          (symbol, transitionJson) => MapEntry(
            symbol,
            TuringTransitionDto.fromJson(
              Map<String, dynamic>.from(transitionJson as Map),
            ),
          ),
        ),
      );
    });

    return TuringMachineDto(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      inputAlphabet: (json['inputAlphabet'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tapeAlphabet: (json['tapeAlphabet'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      states: (json['states'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      initialState: json['initialState'] as String,
      finalStates: (json['finalStates'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      blankSymbol: json['blankSymbol'] as String,
      transitions: transitions,
    );
  }

  final String id;
  final String name;
  final String type;
  final List<String> inputAlphabet;
  final List<String> tapeAlphabet;
  final List<String> states;
  final String initialState;
  final List<String> finalStates;
  final String blankSymbol;
  final Map<String, Map<String, TuringTransitionDto>> transitions;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'type': type,
    'inputAlphabet': inputAlphabet,
    'tapeAlphabet': tapeAlphabet,
    'states': states,
    'initialState': initialState,
    'finalStates': finalStates,
    'blankSymbol': blankSymbol,
    'transitions': transitions.map(
      (state, transitionMap) => MapEntry(
        state,
        transitionMap.map(
          (symbol, transition) => MapEntry(symbol, transition.toJson()),
        ),
      ),
    ),
  };

  static const DeepCollectionEquality _deepCollectionEquality =
      DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TuringMachineDto) return false;
    return other.id == id &&
        other.name == name &&
        other.type == type &&
        _deepCollectionEquality.equals(other.inputAlphabet, inputAlphabet) &&
        _deepCollectionEquality.equals(other.tapeAlphabet, tapeAlphabet) &&
        _deepCollectionEquality.equals(other.states, states) &&
        other.initialState == initialState &&
        _deepCollectionEquality.equals(other.finalStates, finalStates) &&
        other.blankSymbol == blankSymbol &&
        _deepCollectionEquality.equals(other.transitions, transitions);
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    type,
    _deepCollectionEquality.hash(inputAlphabet),
    _deepCollectionEquality.hash(tapeAlphabet),
    _deepCollectionEquality.hash(states),
    initialState,
    _deepCollectionEquality.hash(finalStates),
    blankSymbol,
    _deepCollectionEquality.hash(transitions),
  ]);

  @override
  String toString() {
    return 'TuringMachineDto(id: $id, name: $name, type: $type, '
        'inputAlphabet: $inputAlphabet, tapeAlphabet: $tapeAlphabet, '
        'states: $states, initialState: $initialState, '
        'finalStates: $finalStates, blankSymbol: $blankSymbol, '
        'transitions: $transitions)';
  }
}

/// DTO for Turing machine transition
class TuringTransitionDto {
  const TuringTransitionDto({
    required this.newState,
    required this.writeSymbol,
    required this.direction,
  });

  factory TuringTransitionDto.fromJson(Map<String, dynamic> json) {
    return TuringTransitionDto(
      newState: json['newState'] as String,
      writeSymbol: json['writeSymbol'] as String,
      direction: json['direction'] as String,
    );
  }

  final String newState;
  final String writeSymbol;
  final String direction;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'newState': newState,
    'writeSymbol': writeSymbol,
    'direction': direction,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TuringTransitionDto) return false;
    return other.newState == newState &&
        other.writeSymbol == writeSymbol &&
        other.direction == direction;
  }

  @override
  int get hashCode => Object.hash(newState, writeSymbol, direction);

  @override
  String toString() {
    return 'TuringTransitionDto(newState: $newState, writeSymbol: '
        '$writeSymbol, direction: $direction)';
  }
}

/// DTO for JFLAP Turing machine structure
class JflapTuringMachineDto {
  const JflapTuringMachineDto({required this.type, required this.structure});

  factory JflapTuringMachineDto.fromJson(Map<String, dynamic> json) {
    return JflapTuringMachineDto(
      type: json['type'] as String,
      structure: JflapTuringStructureDto.fromJson(
        Map<String, dynamic>.from(json['structure'] as Map),
      ),
    );
  }

  final String type;
  final JflapTuringStructureDto structure;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'structure': structure.toJson(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JflapTuringMachineDto) return false;
    return other.type == type && other.structure == structure;
  }

  @override
  int get hashCode => Object.hash(type, structure);

  @override
  String toString() {
    return 'JflapTuringMachineDto(type: $type, structure: $structure)';
  }
}

/// DTO for JFLAP Turing machine structure
class JflapTuringStructureDto {
  const JflapTuringStructureDto({
    required this.states,
    required this.inputAlphabet,
    required this.tapeAlphabet,
    required this.initialState,
    required this.finalStates,
    required this.blankSymbol,
    required this.transitions,
  });

  factory JflapTuringStructureDto.fromJson(Map<String, dynamic> json) {
    return JflapTuringStructureDto(
      states: (json['states'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      inputAlphabet: (json['inputAlphabet'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tapeAlphabet: (json['tapeAlphabet'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      initialState: json['initialState'] as String,
      finalStates: (json['finalStates'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      blankSymbol: json['blankSymbol'] as String,
      transitions: (json['transitions'] as List<dynamic>)
          .map(
            (e) => JflapTuringTransitionDto.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  final List<String> states;
  final List<String> inputAlphabet;
  final List<String> tapeAlphabet;
  final String initialState;
  final List<String> finalStates;
  final String blankSymbol;
  final List<JflapTuringTransitionDto> transitions;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'states': states,
    'inputAlphabet': inputAlphabet,
    'tapeAlphabet': tapeAlphabet,
    'initialState': initialState,
    'finalStates': finalStates,
    'blankSymbol': blankSymbol,
    'transitions': transitions.map((e) => e.toJson()).toList(),
  };

  static const DeepCollectionEquality _deepCollectionEquality =
      DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JflapTuringStructureDto) return false;
    return _deepCollectionEquality.equals(other.states, states) &&
        _deepCollectionEquality.equals(other.inputAlphabet, inputAlphabet) &&
        _deepCollectionEquality.equals(other.tapeAlphabet, tapeAlphabet) &&
        other.initialState == initialState &&
        _deepCollectionEquality.equals(other.finalStates, finalStates) &&
        other.blankSymbol == blankSymbol &&
        _deepCollectionEquality.equals(other.transitions, transitions);
  }

  @override
  int get hashCode => Object.hashAll([
    _deepCollectionEquality.hash(states),
    _deepCollectionEquality.hash(inputAlphabet),
    _deepCollectionEquality.hash(tapeAlphabet),
    initialState,
    _deepCollectionEquality.hash(finalStates),
    blankSymbol,
    _deepCollectionEquality.hash(transitions),
  ]);

  @override
  String toString() {
    return 'JflapTuringStructureDto(states: $states, inputAlphabet: '
        '$inputAlphabet, tapeAlphabet: $tapeAlphabet, initialState: '
        '$initialState, finalStates: $finalStates, blankSymbol: '
        '$blankSymbol, transitions: $transitions)';
  }
}

/// DTO for JFLAP Turing machine transition
class JflapTuringTransitionDto {
  const JflapTuringTransitionDto({
    required this.from,
    required this.to,
    required this.read,
    required this.write,
    required this.direction,
  });

  factory JflapTuringTransitionDto.fromJson(Map<String, dynamic> json) {
    return JflapTuringTransitionDto(
      from: json['from'] as String,
      to: json['to'] as String,
      read: json['read'] as String,
      write: json['write'] as String,
      direction: json['direction'] as String,
    );
  }

  final String from;
  final String to;
  final String read;
  final String write;
  final String direction;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'from': from,
    'to': to,
    'read': read,
    'write': write,
    'direction': direction,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JflapTuringTransitionDto) return false;
    return other.from == from &&
        other.to == to &&
        other.read == read &&
        other.write == write &&
        other.direction == direction;
  }

  @override
  int get hashCode => Object.hash(from, to, read, write, direction);

  @override
  String toString() {
    return 'JflapTuringTransitionDto(from: $from, to: $to, read: '
        '$read, write: $write, direction: $direction)';
  }
}
