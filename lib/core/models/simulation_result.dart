//
//  simulation_result.dart
//  JFlutter
//
//  Modela o resultado das simulações de autômatos, armazenando entrada,
//  aceitação, passos detalhados, mensagens de erro e métricas de execução.
//  Oferece fábricas para diferentes cenários (sucesso, falha, timeout ou laço)
//  além de utilidades de serialização e análises auxiliares usadas em painéis.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'simulation_step.dart';

class SimulationResult {
  final String inputString;
  final bool accepted;
  bool get isAccepted => accepted;
  final List<SimulationStep> steps;
  final String errorMessage;
  final Duration executionTime;

  SimulationResult._({
    required this.inputString,
    required this.accepted,
    required List<SimulationStep> steps,
    this.errorMessage = '',
    required this.executionTime,
  }) : steps = List<SimulationStep>.unmodifiable(steps);

  factory SimulationResult.success({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: true,
      steps: steps,
      executionTime: executionTime,
    );
  }

  factory SimulationResult.failure({
    required String inputString,
    required List<SimulationStep> steps,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  factory SimulationResult.timeout({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage:
          'Simulation timed out after ${executionTime.inSeconds} seconds',
      executionTime: executionTime,
    );
  }

  factory SimulationResult.infiniteLoop({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: 'Infinite loop detected after ${steps.length} steps',
      executionTime: executionTime,
    );
  }

  /// Creates a copy of this simulation result with updated properties
  SimulationResult copyWith({
    String? inputString,
    bool? accepted,
    List<SimulationStep>? steps,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return SimulationResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      steps: steps ?? this.steps,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }

  /// Converts the simulation result to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'inputString': inputString,
      'accepted': accepted,
      'steps': steps.map((s) => s.toJson()).toList(),
      'errorMessage': errorMessage,
      'executionTime': executionTime.inMilliseconds,
    };
  }

  /// Creates a simulation result from a JSON representation
  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult._(
      inputString: json['inputString'] as String,
      accepted: json['accepted'] as bool,
      steps: (json['steps'] as List)
          .map((s) => SimulationStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String? ?? '',
      executionTime: Duration(milliseconds: json['executionTime'] as int),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimulationResult &&
        other.inputString == inputString &&
        other.accepted == accepted &&
        other.steps == steps &&
        other.errorMessage == errorMessage &&
        other.executionTime == executionTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      inputString,
      accepted,
      steps,
      errorMessage,
      executionTime,
    );
  }

  @override
  String toString() {
    return 'SimulationResult(inputString: $inputString, accepted: $accepted, steps: ${steps.length}, executionTime: $executionTime)';
  }

  /// Gets the number of steps in the simulation
  int get stepCount => steps.length;

  /// Gets the first step of the simulation
  SimulationStep? get firstStep => steps.isNotEmpty ? steps.first : null;

  /// Gets the last step of the simulation
  SimulationStep? get lastStep => steps.isNotEmpty ? steps.last : null;

  /// Gets the final state of the simulation
  String? get finalState => lastStep?.currentState;

  /// Gets the remaining input after simulation
  String get remainingInput => lastStep?.remainingInput ?? '';

  /// Checks if the simulation was successful
  bool get isSuccessful => accepted && errorMessage.isEmpty;

  /// Checks if the simulation failed
  bool get isFailed => !accepted || errorMessage.isNotEmpty;

  /// Checks if the simulation timed out
  bool get isTimeout =>
      errorMessage.contains('timeout') || errorMessage.contains('Timeout');

  /// Checks if the simulation had an infinite loop
  bool get isInfiniteLoop =>
      errorMessage.contains('infinite loop') ||
      errorMessage.contains('Infinite loop');

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;

  /// Gets all states visited during the simulation
  Set<String> get visitedStates {
    return steps.map((step) => step.currentState).toSet();
  }

  /// Gets all transitions used during the simulation
  Set<String> get usedTransitions {
    return steps
        .where((step) => step.usedTransition != null)
        .map((step) => step.usedTransition!)
        .toSet();
  }

  /// Gets the path taken during the simulation
  List<String> get path {
    return steps.map((step) => step.currentState).toList();
  }

  /// Gets the sequence of transitions used
  List<String> get transitionSequence {
    return steps
        .where((step) => step.usedTransition != null)
        .map((step) => step.usedTransition!)
        .toList();
  }

  /// Gets the sequence of input symbols consumed
  List<String> get inputSequence {
    final sequence = <String>[];
    String remaining = inputString;

    for (final step in steps) {
      if (step.remainingInput.length < remaining.length) {
        final consumed = remaining.substring(
          0,
          remaining.length - step.remainingInput.length,
        );
        sequence.addAll(consumed.split(''));
        remaining = step.remainingInput;
      }
    }

    return sequence;
  }

  /// Gets the number of input symbols consumed
  int get inputSymbolsConsumed {
    return inputString.length - remainingInput.length;
  }

  /// Gets the number of input symbols remaining
  int get inputSymbolsRemaining {
    return remainingInput.length;
  }

  /// Checks if all input was consumed
  bool get allInputConsumed => remainingInput.isEmpty;

  /// Gets the stack contents at the end of simulation (for PDA)
  String get finalStackContents => lastStep?.stackContents ?? '';

  /// Gets the tape contents at the end of simulation (for TM)
  String get finalTapeContents => lastStep?.tapeContents ?? '';

  /// Creates an error simulation result
  factory SimulationResult.error({
    required String inputString,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: [],
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }
}
