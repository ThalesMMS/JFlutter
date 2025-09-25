import 'package:freezed_annotation/freezed_annotation.dart';
import 'trace.dart';
import 'configuration.dart';

part 'execution_report.freezed.dart';
part 'execution_report.g.dart';

/// Types of execution results
enum ExecutionResultType {
  success,
  failure,
  timeout,
  infiniteLoop,
  error,
}

/// ExecutionReport represents the complete result of an automaton execution
@freezed
class ExecutionReport with _$ExecutionReport {
  const factory ExecutionReport({
    required String automatonId,
    required String automatonName,
    required String inputString,
    required ExecutionResultType resultType,
    required bool accepted,
    required List<Trace> traces,
    required Duration executionTime,
    @Default('') String errorMessage,
    @Default(0) int maxSteps,
    @Default(0) int maxBranches,
    @Default(0) int maxVisitedConfigurations,
    @Default({}) Map<String, dynamic> metadata,
  }) = _ExecutionReport;

  factory ExecutionReport.fromJson(Map<String, dynamic> json) => _$ExecutionReportFromJson(json);
}

/// Extension methods for ExecutionReport to provide execution analysis functionality
extension ExecutionReportExtension on ExecutionReport {
  /// Validates the execution report properties
  List<String> validate() {
    final errors = <String>[];
    
    if (automatonId.isEmpty) {
      errors.add('Automaton ID cannot be empty');
    }
    
    if (automatonName.isEmpty) {
      errors.add('Automaton name cannot be empty');
    }
    
    if (traces.isEmpty) {
      errors.add('Execution report must have at least one trace');
    }
    
    // Validate each trace
    for (int i = 0; i < traces.length; i++) {
      final trace = traces[i];
      final traceErrors = trace.validate();
      for (final error in traceErrors) {
        errors.add('Trace $i: $error');
      }
    }
    
    // Check result type consistency
    if (resultType == ExecutionResultType.success && !accepted) {
      errors.add('Success result type requires accepted to be true');
    }
    
    if (resultType == ExecutionResultType.failure && accepted) {
      errors.add('Failure result type requires accepted to be false');
    }
    
    if (resultType == ExecutionResultType.error && errorMessage.isEmpty) {
      errors.add('Error result type requires non-empty error message');
    }
    
    return errors;
  }

  /// Checks if the execution report is valid
  bool get isValid => validate().isEmpty;

  /// Gets the number of traces
  int get traceCount => traces.length;

  /// Gets the first trace
  Trace? get firstTrace => traces.isNotEmpty ? traces.first : null;

  /// Gets the last trace
  Trace? get lastTrace => traces.isNotEmpty ? traces.last : null;

  /// Gets the total number of steps across all traces
  int get totalSteps {
    return traces.fold(0, (sum, trace) => sum + trace.stepCount);
  }

  /// Gets the maximum number of steps in any trace
  int get maxStepsInTraces {
    if (traces.isEmpty) return 0;
    return traces.map((trace) => trace.stepCount).reduce((a, b) => a > b ? a : b);
  }

  /// Gets the minimum number of steps in any trace
  int get minStepsInTraces {
    if (traces.isEmpty) return 0;
    return traces.map((trace) => trace.stepCount).reduce((a, b) => a < b ? a : b);
  }

  /// Gets the average number of steps across all traces
  double get averageSteps {
    if (traces.isEmpty) return 0.0;
    return totalSteps / traces.length;
  }

  /// Gets all successful traces
  List<Trace> get successfulTraces {
    return traces.where((trace) => trace.isSuccessful).toList();
  }

  /// Gets all failed traces
  List<Trace> get failedTraces {
    return traces.where((trace) => trace.isFailed).toList();
  }

  /// Gets all timeout traces
  List<Trace> get timeoutTraces {
    return traces.where((trace) => trace.isTimeout).toList();
  }

  /// Gets all infinite loop traces
  List<Trace> get infiniteLoopTraces {
    return traces.where((trace) => trace.isInfiniteLoop).toList();
  }

  /// Gets the number of successful traces
  int get successfulTraceCount => successfulTraces.length;

  /// Gets the number of failed traces
  int get failedTraceCount => failedTraces.length;

  /// Gets the number of timeout traces
  int get timeoutTraceCount => timeoutTraces.length;

  /// Gets the number of infinite loop traces
  int get infiniteLoopTraceCount => infiniteLoopTraces.length;

  /// Checks if the execution was successful
  bool get isSuccessful => resultType == ExecutionResultType.success && accepted;

  /// Checks if the execution failed
  bool get isFailed => resultType == ExecutionResultType.failure && !accepted;

  /// Checks if the execution timed out
  bool get isTimeout => resultType == ExecutionResultType.timeout;

  /// Checks if the execution had an infinite loop
  bool get isInfiniteLoop => resultType == ExecutionResultType.infiniteLoop;

  /// Checks if the execution had an error
  bool get isError => resultType == ExecutionResultType.error;

  /// Gets all states visited across all traces
  Set<String> get allVisitedStates {
    final states = <String>{};
    for (final trace in traces) {
      states.addAll(trace.visitedStates);
    }
    return states;
  }

  /// Gets all unique state sequences across all traces
  List<List<String>> get allStateSequences {
    return traces.map((trace) => trace.stateSequence).toList();
  }

  /// Gets the shortest accepting trace (if any)
  Trace? get shortestAcceptingTrace {
    final acceptingTraces = traces.where((trace) => trace.accepted).toList();
    if (acceptingTraces.isEmpty) return null;
    
    return acceptingTraces.reduce((a, b) => a.stepCount < b.stepCount ? a : b);
  }

  /// Gets the longest accepting trace (if any)
  Trace? get longestAcceptingTrace {
    final acceptingTraces = traces.where((trace) => trace.accepted).toList();
    if (acceptingTraces.isEmpty) return null;
    
    return acceptingTraces.reduce((a, b) => a.stepCount > b.stepCount ? a : b);
  }

  /// Gets the shortest rejecting trace (if any)
  Trace? get shortestRejectingTrace {
    final rejectingTraces = traces.where((trace) => !trace.accepted).toList();
    if (rejectingTraces.isEmpty) return null;
    
    return rejectingTraces.reduce((a, b) => a.stepCount < b.stepCount ? a : b);
  }

  /// Gets the longest rejecting trace (if any)
  Trace? get longestRejectingTrace {
    final rejectingTraces = traces.where((trace) => !trace.accepted).toList();
    if (rejectingTraces.isEmpty) return null;
    
    return rejectingTraces.reduce((a, b) => a.stepCount > b.stepCount ? a : b);
  }

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;

  /// Gets the execution time in microseconds
  int get executionTimeUs => executionTime.inMicroseconds;

  /// Gets a summary of the execution report
  String get summary {
    final buffer = StringBuffer();
    buffer.write('Execution Report: $automatonName');
    buffer.write(' (${automatonId})');
    buffer.write(', Input: $inputString');
    buffer.write(', Result: ${resultType.name}');
    buffer.write(', Accepted: $accepted');
    buffer.write(', Traces: $traceCount');
    buffer.write(', Steps: $totalSteps');
    buffer.write(', Time: ${executionTimeMs}ms');
    
    if (errorMessage.isNotEmpty) {
      buffer.write(', Error: $errorMessage');
    }
    
    return buffer.toString();
  }

  /// Gets a detailed description of the execution report
  String get description {
    final buffer = StringBuffer();
    buffer.writeln('Execution Report:');
    buffer.writeln('  Automaton: $automatonName ($automatonId)');
    buffer.writeln('  Input: $inputString');
    buffer.writeln('  Result: ${resultType.name}');
    buffer.writeln('  Accepted: $accepted');
    buffer.writeln('  Traces: $traceCount');
    buffer.writeln('  Total steps: $totalSteps');
    buffer.writeln('  Execution time: ${executionTimeMs}ms');
    
    if (errorMessage.isNotEmpty) {
      buffer.writeln('  Error: $errorMessage');
    }
    
    buffer.writeln('  Successful traces: $successfulTraceCount');
    buffer.writeln('  Failed traces: $failedTraceCount');
    buffer.writeln('  Timeout traces: $timeoutTraceCount');
    buffer.writeln('  Infinite loop traces: $infiniteLoopTraceCount');
    
    buffer.writeln('  States visited: ${allVisitedStates.length}');
    buffer.writeln('  Max steps per trace: $maxStepsInTraces');
    buffer.writeln('  Min steps per trace: $minStepsInTraces');
    buffer.writeln('  Average steps per trace: ${averageSteps.toStringAsFixed(2)}');
    
    return buffer.toString();
  }

  /// Creates a copy with updated result type
  ExecutionReport withResultType(ExecutionResultType newResultType) {
    return copyWith(resultType: newResultType);
  }

  /// Creates a copy with updated acceptance status
  ExecutionReport withAccepted(bool newAccepted) {
    return copyWith(accepted: newAccepted);
  }

  /// Creates a copy with updated error message
  ExecutionReport withErrorMessage(String newErrorMessage) {
    return copyWith(errorMessage: newErrorMessage);
  }

  /// Creates a copy with updated traces
  ExecutionReport withTraces(List<Trace> newTraces) {
    return copyWith(traces: newTraces);
  }

  /// Creates a copy with additional trace
  ExecutionReport withTrace(Trace trace) {
    final newTraces = List<Trace>.from(traces);
    newTraces.add(trace);
    return copyWith(traces: newTraces);
  }

  /// Creates a copy with updated limits
  ExecutionReport withLimits(int newMaxSteps, int newMaxBranches, int newMaxVisitedConfigurations) {
    return copyWith(
      maxSteps: newMaxSteps,
      maxBranches: newMaxBranches,
      maxVisitedConfigurations: newMaxVisitedConfigurations,
    );
  }

  /// Creates a copy with updated metadata
  ExecutionReport withMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(metadata: newMetadata);
  }

  /// Creates a copy with additional metadata
  ExecutionReport withAdditionalMetadata(String key, dynamic value) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata[key] = value;
    return copyWith(metadata: newMetadata);
  }

  /// Gets traces matching a predicate
  List<Trace> findTraces(bool Function(Trace) predicate) {
    return traces.where(predicate).toList();
  }

  /// Finds the first trace matching a predicate
  Trace? findFirstTrace(bool Function(Trace) predicate) {
    try {
      return traces.firstWhere(predicate);
    } catch (e) {
      return null;
    }
  }

  /// Finds the last trace matching a predicate
  Trace? findLastTrace(bool Function(Trace) predicate) {
    try {
      return traces.lastWhere(predicate);
    } catch (e) {
      return null;
    }
  }

  /// Checks if any trace matches a predicate
  bool anyTrace(bool Function(Trace) predicate) {
    return traces.any(predicate);
  }

  /// Checks if all traces match a predicate
  bool allTraces(bool Function(Trace) predicate) {
    return traces.every(predicate);
  }
}

/// Factory methods for creating common execution report patterns
class ExecutionReportFactory {
  /// Creates a successful execution report
  static ExecutionReport success({
    required String automatonId,
    required String automatonName,
    required String inputString,
    required List<Trace> traces,
    required Duration executionTime,
    int maxSteps = 0,
    int maxBranches = 0,
    int maxVisitedConfigurations = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return ExecutionReport(
      automatonId: automatonId,
      automatonName: automatonName,
      inputString: inputString,
      resultType: ExecutionResultType.success,
      accepted: true,
      traces: traces,
      executionTime: executionTime,
      maxSteps: maxSteps,
      maxBranches: maxBranches,
      maxVisitedConfigurations: maxVisitedConfigurations,
      metadata: metadata,
    );
  }

  /// Creates a failed execution report
  static ExecutionReport failure({
    required String automatonId,
    required String automatonName,
    required String inputString,
    required List<Trace> traces,
    required Duration executionTime,
    required String errorMessage,
    int maxSteps = 0,
    int maxBranches = 0,
    int maxVisitedConfigurations = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return ExecutionReport(
      automatonId: automatonId,
      automatonName: automatonName,
      inputString: inputString,
      resultType: ExecutionResultType.failure,
      accepted: false,
      traces: traces,
      executionTime: executionTime,
      errorMessage: errorMessage,
      maxSteps: maxSteps,
      maxBranches: maxBranches,
      maxVisitedConfigurations: maxVisitedConfigurations,
      metadata: metadata,
    );
  }

  /// Creates a timeout execution report
  static ExecutionReport timeout({
    required String automatonId,
    required String automatonName,
    required String inputString,
    required List<Trace> traces,
    required Duration executionTime,
    required Duration timeout,
    int maxSteps = 0,
    int maxBranches = 0,
    int maxVisitedConfigurations = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return ExecutionReport(
      automatonId: automatonId,
      automatonName: automatonName,
      inputString: inputString,
      resultType: ExecutionResultType.timeout,
      accepted: false,
      traces: traces,
      executionTime: executionTime,
      errorMessage: 'Simulation timed out after ${timeout.inSeconds} seconds',
      maxSteps: maxSteps,
      maxBranches: maxBranches,
      maxVisitedConfigurations: maxVisitedConfigurations,
      metadata: metadata,
    );
  }

  /// Creates an infinite loop execution report
  static ExecutionReport infiniteLoop({
    required String automatonId,
    required String automatonName,
    required String inputString,
    required List<Trace> traces,
    required Duration executionTime,
    int maxSteps = 0,
    int maxBranches = 0,
    int maxVisitedConfigurations = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return ExecutionReport(
      automatonId: automatonId,
      automatonName: automatonName,
      inputString: inputString,
      resultType: ExecutionResultType.infiniteLoop,
      accepted: false,
      traces: traces,
      executionTime: executionTime,
      errorMessage: 'Infinite loop detected',
      maxSteps: maxSteps,
      maxBranches: maxBranches,
      maxVisitedConfigurations: maxVisitedConfigurations,
      metadata: metadata,
    );
  }

  /// Creates an error execution report
  static ExecutionReport error({
    required String automatonId,
    required String automatonName,
    required String inputString,
    required String errorMessage,
    required Duration executionTime,
    List<Trace> traces = const [],
    int maxSteps = 0,
    int maxBranches = 0,
    int maxVisitedConfigurations = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return ExecutionReport(
      automatonId: automatonId,
      automatonName: automatonName,
      inputString: inputString,
      resultType: ExecutionResultType.error,
      accepted: false,
      traces: traces,
      executionTime: executionTime,
      errorMessage: errorMessage,
      maxSteps: maxSteps,
      maxBranches: maxBranches,
      maxVisitedConfigurations: maxVisitedConfigurations,
      metadata: metadata,
    );
  }
}
