import 'package:freezed_annotation/freezed_annotation.dart';
import 'configuration.dart';

part 'trace.freezed.dart';
part 'trace.g.dart';

/// Trace represents a sequence of configurations during automaton execution
@freezed
class Trace with _$Trace {
  const factory Trace({
    required List<Configuration> configurations,
    @Default(false) bool accepted,
    @Default('') String errorMessage,
    @Default(0) int maxSteps,
    @Default(0) int maxBranches,
  }) = _Trace;

  factory Trace.fromJson(Map<String, dynamic> json) => _$TraceFromJson(json);
}

/// Extension methods for Trace to provide execution trace functionality
extension TraceExtension on Trace {
  /// Validates the trace properties
  List<String> validate() {
    final errors = <String>[];
    
    if (configurations.isEmpty) {
      errors.add('Trace must have at least one configuration');
    }
    
    // Validate each configuration
    for (int i = 0; i < configurations.length; i++) {
      final config = configurations[i];
      final configErrors = config.validate();
      for (final error in configErrors) {
        errors.add('Configuration $i: $error');
      }
    }
    
    // Check step number consistency
    for (int i = 0; i < configurations.length; i++) {
      final config = configurations[i];
      if (config.stepNumber != i) {
        errors.add('Configuration $i has incorrect step number: ${config.stepNumber}');
      }
    }
    
    return errors;
  }

  /// Checks if the trace is valid
  bool get isValid => validate().isEmpty;

  /// Gets the number of steps in the trace
  int get stepCount => configurations.length;

  /// Gets the first configuration
  Configuration? get firstConfiguration => configurations.isNotEmpty ? configurations.first : null;

  /// Gets the last configuration
  Configuration? get lastConfiguration => configurations.isNotEmpty ? configurations.last : null;

  /// Gets the initial state
  String? get initialState => firstConfiguration?.stateId;

  /// Gets the final state
  String? get finalState => lastConfiguration?.stateId;

  /// Gets the input string
  String get inputString => firstConfiguration?.inputString ?? '';

  /// Gets the final input position
  int get finalInputPosition => lastConfiguration?.inputPosition ?? 0;

  /// Gets the remaining input
  String get remainingInput => lastConfiguration?.remainingInput ?? '';

  /// Gets the final stack contents (for PDA)
  String get finalStackContents => lastConfiguration?.stackContents ?? '';

  /// Gets the final tape contents (for TM)
  String get finalTapeContents => lastConfiguration?.tapeContents ?? '';

  /// Gets the final tape position (for TM)
  int get finalTapePosition => lastConfiguration?.tapePosition ?? 0;

  /// Checks if the trace is successful
  bool get isSuccessful => accepted && errorMessage.isEmpty;

  /// Checks if the trace failed
  bool get isFailed => !accepted || errorMessage.isNotEmpty;

  /// Checks if the trace timed out
  bool get isTimeout => errorMessage.contains('timeout') || errorMessage.contains('Timeout');

  /// Checks if the trace had an infinite loop
  bool get isInfiniteLoop => errorMessage.contains('infinite loop') || errorMessage.contains('Infinite loop');

  /// Gets all states visited during the trace
  Set<String> get visitedStates {
    return configurations.map((config) => config.stateId).toSet();
  }

  /// Gets the sequence of states visited
  List<String> get stateSequence {
    return configurations.map((config) => config.stateId).toList();
  }

  /// Gets the sequence of input symbols consumed
  List<String> get inputSequence {
    final sequence = <String>[];
    String remaining = inputString;
    
    for (final config in configurations) {
      if (config.remainingInput.length < remaining.length) {
        final consumed = remaining.substring(0, remaining.length - config.remainingInput.length);
        sequence.addAll(consumed.split(''));
        remaining = config.remainingInput;
      }
    }
    
    return sequence;
  }

  /// Gets the sequence of stack operations (for PDA)
  List<String> get stackSequence {
    return configurations.map((config) => config.stackContents).toList();
  }

  /// Gets the sequence of tape operations (for TM)
  List<String> get tapeSequence {
    return configurations.map((config) => config.tapeContents).toList();
  }

  /// Gets the sequence of tape positions (for TM)
  List<int> get tapePositionSequence {
    return configurations.map((config) => config.tapePosition).toList();
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

  /// Gets the execution time (if available in metadata)
  Duration? get executionTime {
    final lastConfig = lastConfiguration;
    if (lastConfig == null) return null;
    
    final metadata = lastConfig.metadata;
    if (metadata.containsKey('executionTime')) {
      final timeMs = metadata['executionTime'] as int?;
      if (timeMs != null) {
        return Duration(milliseconds: timeMs);
      }
    }
    
    return null;
  }

  /// Gets a summary of the trace
  String get summary {
    final buffer = StringBuffer();
    buffer.write('Trace: ${stepCount} steps');
    
    if (inputString.isNotEmpty) {
      buffer.write(', Input: $inputString');
    }
    
    buffer.write(', Accepted: $accepted');
    
    if (errorMessage.isNotEmpty) {
      buffer.write(', Error: $errorMessage');
    }
    
    return buffer.toString();
  }

  /// Gets a detailed description of the trace
  String get description {
    final buffer = StringBuffer();
    buffer.writeln('Execution Trace:');
    buffer.writeln('  Steps: $stepCount');
    buffer.writeln('  Input: $inputString');
    buffer.writeln('  Accepted: $accepted');
    
    if (errorMessage.isNotEmpty) {
      buffer.writeln('  Error: $errorMessage');
    }
    
    if (initialState != null) {
      buffer.writeln('  Initial state: $initialState');
    }
    
    if (finalState != null) {
      buffer.writeln('  Final state: $finalState');
    }
    
    buffer.writeln('  States visited: ${visitedStates.join(', ')}');
    
    if (finalStackContents.isNotEmpty) {
      buffer.writeln('  Final stack: $finalStackContents');
    }
    
    if (finalTapeContents.isNotEmpty) {
      buffer.writeln('  Final tape: $finalTapeContents');
    }
    
    return buffer.toString();
  }

  /// Creates a copy with updated acceptance status
  Trace withAccepted(bool newAccepted) {
    return copyWith(accepted: newAccepted);
  }

  /// Creates a copy with updated error message
  Trace withErrorMessage(String newErrorMessage) {
    return copyWith(errorMessage: newErrorMessage);
  }

  /// Creates a copy with updated limits
  Trace withLimits(int newMaxSteps, int newMaxBranches) {
    return copyWith(maxSteps: newMaxSteps, maxBranches: newMaxBranches);
  }

  /// Creates a copy with additional configuration
  Trace withConfiguration(Configuration configuration) {
    final newConfigurations = List<Configuration>.from(configurations);
    newConfigurations.add(configuration);
    return copyWith(configurations: newConfigurations);
  }

  /// Creates a copy with updated configurations
  Trace withConfigurations(List<Configuration> newConfigurations) {
    return copyWith(configurations: newConfigurations);
  }

  /// Gets a sub-trace from start to end (inclusive)
  Trace subTrace(int start, int end) {
    if (start < 0 || end >= configurations.length || start > end) {
      throw ArgumentError('Invalid sub-trace range: $start to $end');
    }
    
    final subConfigurations = configurations.sublist(start, end + 1);
    return copyWith(configurations: subConfigurations);
  }

  /// Gets a sub-trace from start to the end
  Trace subTraceFrom(int start) {
    if (start < 0 || start >= configurations.length) {
      throw ArgumentError('Invalid sub-trace start: $start');
    }
    
    final subConfigurations = configurations.sublist(start);
    return copyWith(configurations: subConfigurations);
  }

  /// Gets a sub-trace from the beginning to end
  Trace subTraceTo(int end) {
    if (end < 0 || end >= configurations.length) {
      throw ArgumentError('Invalid sub-trace end: $end');
    }
    
    final subConfigurations = configurations.sublist(0, end + 1);
    return copyWith(configurations: subConfigurations);
  }

  /// Finds configurations matching a predicate
  List<Configuration> findConfigurations(bool Function(Configuration) predicate) {
    return configurations.where(predicate).toList();
  }

  /// Finds the first configuration matching a predicate
  Configuration? findFirstConfiguration(bool Function(Configuration) predicate) {
    try {
      return configurations.firstWhere(predicate);
    } catch (e) {
      return null;
    }
  }

  /// Finds the last configuration matching a predicate
  Configuration? findLastConfiguration(bool Function(Configuration) predicate) {
    try {
      return configurations.lastWhere(predicate);
    } catch (e) {
      return null;
    }
  }

  /// Checks if any configuration matches a predicate
  bool anyConfiguration(bool Function(Configuration) predicate) {
    return configurations.any(predicate);
  }

  /// Checks if all configurations match a predicate
  bool allConfigurations(bool Function(Configuration) predicate) {
    return configurations.every(predicate);
  }
}

/// Factory methods for creating common trace patterns
class TraceFactory {
  /// Creates an empty trace
  static Trace empty() {
    return const Trace(configurations: []);
  }

  /// Creates a trace with a single configuration
  static Trace single(Configuration configuration) {
    return Trace(configurations: [configuration]);
  }

  /// Creates a successful trace
  static Trace success({
    required List<Configuration> configurations,
    int maxSteps = 0,
    int maxBranches = 0,
  }) {
    return Trace(
      configurations: configurations,
      accepted: true,
      maxSteps: maxSteps,
      maxBranches: maxBranches,
    );
  }

  /// Creates a failed trace
  static Trace failure({
    required List<Configuration> configurations,
    required String errorMessage,
    int maxSteps = 0,
    int maxBranches = 0,
  }) {
    return Trace(
      configurations: configurations,
      accepted: false,
      errorMessage: errorMessage,
      maxSteps: maxSteps,
      maxBranches: maxBranches,
    );
  }

  /// Creates a timeout trace
  static Trace timeout({
    required List<Configuration> configurations,
    required Duration timeout,
    int maxSteps = 0,
    int maxBranches = 0,
  }) {
    return Trace(
      configurations: configurations,
      accepted: false,
      errorMessage: 'Simulation timed out after ${timeout.inSeconds} seconds',
      maxSteps: maxSteps,
      maxBranches: maxBranches,
    );
  }

  /// Creates an infinite loop trace
  static Trace infiniteLoop({
    required List<Configuration> configurations,
    int maxSteps = 0,
    int maxBranches = 0,
  }) {
    return Trace(
      configurations: configurations,
      accepted: false,
      errorMessage: 'Infinite loop detected',
      maxSteps: maxSteps,
      maxBranches: maxBranches,
    );
  }

  /// Creates a trace from a simulation result
  static Trace fromSimulationResult({
    required String inputString,
    required List<Configuration> configurations,
    required bool accepted,
    String errorMessage = '',
    Duration? executionTime,
    int maxSteps = 0,
    int maxBranches = 0,
  }) {
    final trace = Trace(
      configurations: configurations,
      accepted: accepted,
      errorMessage: errorMessage,
      maxSteps: maxSteps,
      maxBranches: maxBranches,
    );

    // Add execution time to metadata if provided
    if (executionTime != null && configurations.isNotEmpty) {
      final lastConfig = configurations.last;
      final updatedConfig = lastConfig.withAdditionalMetadata('executionTime', executionTime.inMilliseconds);
      final updatedConfigurations = List<Configuration>.from(configurations);
      updatedConfigurations[updatedConfigurations.length - 1] = updatedConfig;
      return trace.copyWith(configurations: updatedConfigurations);
    }

    return trace;
  }
}
