import 'package:freezed_annotation/freezed_annotation.dart';
import 'execution_report.dart';

part 'algorithm_result.freezed.dart';
part 'algorithm_result.g.dart';

/// Types of algorithm operations
enum AlgorithmType {
  // Finite Automata algorithms
  nfaToDfa,
  dfaMinimization,
  regexToNfa,
  faToRegex,
  
  // Pushdown Automata algorithms
  cfgToPda,
  pdaToCfg,
  
  // Turing Machine algorithms
  tmSimulation,
  tmAnalysis,
  
  // Property checking algorithms
  emptinessCheck,
  universalityCheck,
  equivalenceCheck,
  inclusionCheck,
  
  // Pumping lemma algorithms
  pumpingLemmaProof,
  pumpingLemmaGame,
  
  // Language operations
  union,
  intersection,
  concatenation,
  kleeneStar,
  complement,
  
  // Other algorithms
  determinization,
  minimization,
  complementation,
  product,
  projection,
}

/// Types of algorithm results
enum AlgorithmResultType {
  success,
  failure,
  timeout,
  error,
  notApplicable,
}

/// AlgorithmResult represents the result of an algorithm execution
@freezed
class AlgorithmResult with _$AlgorithmResult {
  const factory AlgorithmResult({
    required String algorithmId,
    required String algorithmName,
    required AlgorithmType algorithmType,
    required AlgorithmResultType resultType,
    required bool success,
    required Duration executionTime,
    @Default('') String errorMessage,
    @Default({}) Map<String, dynamic> inputData,
    @Default({}) Map<String, dynamic> outputData,
    @Default({}) Map<String, dynamic> metadata,
    @Default(0) int inputSize,
    @Default(0) int outputSize,
    @Default(0) int stepsExecuted,
    @Default(0) int memoryUsed,
  }) = _AlgorithmResult;

  factory AlgorithmResult.fromJson(Map<String, dynamic> json) => _$AlgorithmResultFromJson(json);
}

/// Extension methods for AlgorithmResult to provide algorithm analysis functionality
extension AlgorithmResultExtension on AlgorithmResult {
  /// Validates the algorithm result properties
  List<String> validate() {
    final errors = <String>[];
    
    if (algorithmId.isEmpty) {
      errors.add('Algorithm ID cannot be empty');
    }
    
    if (algorithmName.isEmpty) {
      errors.add('Algorithm name cannot be empty');
    }
    
    // Check result type consistency
    if (resultType == AlgorithmResultType.success && !success) {
      errors.add('Success result type requires success to be true');
    }
    
    if (resultType == AlgorithmResultType.failure && success) {
      errors.add('Failure result type requires success to be false');
    }
    
    if (resultType == AlgorithmResultType.error && errorMessage.isEmpty) {
      errors.add('Error result type requires non-empty error message');
    }
    
    if (inputSize < 0) {
      errors.add('Input size cannot be negative');
    }
    
    if (outputSize < 0) {
      errors.add('Output size cannot be negative');
    }
    
    if (stepsExecuted < 0) {
      errors.add('Steps executed cannot be negative');
    }
    
    if (memoryUsed < 0) {
      errors.add('Memory used cannot be negative');
    }
    
    return errors;
  }

  /// Checks if the algorithm result is valid
  bool get isValid => validate().isEmpty;

  /// Checks if the algorithm was successful
  bool get isSuccessful => resultType == AlgorithmResultType.success && success;

  /// Checks if the algorithm failed
  bool get isFailed => resultType == AlgorithmResultType.failure && !success;

  /// Checks if the algorithm timed out
  bool get isTimeout => resultType == AlgorithmResultType.timeout;

  /// Checks if the algorithm had an error
  bool get isError => resultType == AlgorithmResultType.error;

  /// Checks if the algorithm is not applicable
  bool get isNotApplicable => resultType == AlgorithmResultType.notApplicable;

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;

  /// Gets the execution time in microseconds
  int get executionTimeUs => executionTime.inMicroseconds;

  /// Gets the memory used in KB
  double get memoryUsedKB => memoryUsed / 1024.0;

  /// Gets the memory used in MB
  double get memoryUsedMB => memoryUsed / (1024.0 * 1024.0);

  /// Gets the input size in KB
  double get inputSizeKB => inputSize / 1024.0;

  /// Gets the input size in MB
  double get inputSizeMB => inputSize / (1024.0 * 1024.0);

  /// Gets the output size in KB
  double get outputSizeKB => outputSize / 1024.0;

  /// Gets the output size in MB
  double get outputSizeMB => outputSize / (1024.0 * 1024.0);

  /// Gets the compression ratio (output/input)
  double get compressionRatio {
    if (inputSize == 0) return 0.0;
    return outputSize / inputSize;
  }

  /// Gets the expansion ratio (input/output)
  double get expansionRatio {
    if (outputSize == 0) return 0.0;
    return inputSize / outputSize;
  }

  /// Gets the steps per second
  double get stepsPerSecond {
    if (executionTime.inMicroseconds == 0) return 0.0;
    return stepsExecuted / (executionTime.inMicroseconds / 1000000.0);
  }

  /// Gets the memory efficiency (steps per KB of memory)
  double get memoryEfficiency {
    if (memoryUsed == 0) return 0.0;
    return stepsExecuted / (memoryUsed / 1024.0);
  }

  /// Gets a summary of the algorithm result
  String get summary {
    final buffer = StringBuffer();
    buffer.write('Algorithm: $algorithmName');
    buffer.write(' (${algorithmType.name})');
    buffer.write(', Result: ${resultType.name}');
    buffer.write(', Success: $success');
    buffer.write(', Time: ${executionTimeMs}ms');
    buffer.write(', Steps: $stepsExecuted');
    buffer.write(', Memory: ${memoryUsedKB.toStringAsFixed(2)}KB');
    
    if (errorMessage.isNotEmpty) {
      buffer.write(', Error: $errorMessage');
    }
    
    return buffer.toString();
  }

  /// Gets a detailed description of the algorithm result
  String get description {
    final buffer = StringBuffer();
    buffer.writeln('Algorithm Result:');
    buffer.writeln('  Algorithm: $algorithmName ($algorithmType.name)');
    buffer.writeln('  ID: $algorithmId');
    buffer.writeln('  Result: ${resultType.name}');
    buffer.writeln('  Success: $success');
    buffer.writeln('  Execution time: ${executionTimeMs}ms');
    buffer.writeln('  Steps executed: $stepsExecuted');
    buffer.writeln('  Memory used: ${memoryUsedKB.toStringAsFixed(2)}KB');
    buffer.writeln('  Input size: ${inputSizeKB.toStringAsFixed(2)}KB');
    buffer.writeln('  Output size: ${outputSizeKB.toStringAsFixed(2)}KB');
    
    if (errorMessage.isNotEmpty) {
      buffer.writeln('  Error: $errorMessage');
    }
    
    buffer.writeln('  Compression ratio: ${compressionRatio.toStringAsFixed(3)}');
    buffer.writeln('  Steps per second: ${stepsPerSecond.toStringAsFixed(2)}');
    buffer.writeln('  Memory efficiency: ${memoryEfficiency.toStringAsFixed(2)} steps/KB');
    
    return buffer.toString();
  }

  /// Creates a copy with updated result type
  AlgorithmResult withResultType(AlgorithmResultType newResultType) {
    return copyWith(resultType: newResultType);
  }

  /// Creates a copy with updated success status
  AlgorithmResult withSuccess(bool newSuccess) {
    return copyWith(success: newSuccess);
  }

  /// Creates a copy with updated error message
  AlgorithmResult withErrorMessage(String newErrorMessage) {
    return copyWith(errorMessage: newErrorMessage);
  }

  /// Creates a copy with updated input data
  AlgorithmResult withInputData(Map<String, dynamic> newInputData) {
    return copyWith(inputData: newInputData);
  }

  /// Creates a copy with updated output data
  AlgorithmResult withOutputData(Map<String, dynamic> newOutputData) {
    return copyWith(outputData: newOutputData);
  }

  /// Creates a copy with updated metadata
  AlgorithmResult withMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(metadata: newMetadata);
  }

  /// Creates a copy with additional metadata
  AlgorithmResult withAdditionalMetadata(String key, dynamic value) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata[key] = value;
    return copyWith(metadata: newMetadata);
  }

  /// Creates a copy with updated performance metrics
  AlgorithmResult withPerformanceMetrics({
    required int newStepsExecuted,
    required int newMemoryUsed,
    required int newInputSize,
    required int newOutputSize,
  }) {
    return copyWith(
      stepsExecuted: newStepsExecuted,
      memoryUsed: newMemoryUsed,
      inputSize: newInputSize,
      outputSize: newOutputSize,
    );
  }

  /// Gets input data by key
  T? getInputData<T>(String key) {
    return inputData[key] as T?;
  }

  /// Gets output data by key
  T? getOutputData<T>(String key) {
    return outputData[key] as T?;
  }

  /// Gets metadata by key
  T? getMetadata<T>(String key) {
    return metadata[key] as T?;
  }

  /// Checks if input data contains a key
  bool hasInputData(String key) {
    return inputData.containsKey(key);
  }

  /// Checks if output data contains a key
  bool hasOutputData(String key) {
    return outputData.containsKey(key);
  }

  /// Checks if metadata contains a key
  bool hasMetadata(String key) {
    return metadata.containsKey(key);
  }
}

/// Factory methods for creating common algorithm result patterns
class AlgorithmResultFactory {
  /// Creates a successful algorithm result
  static AlgorithmResult success({
    required String algorithmId,
    required String algorithmName,
    required AlgorithmType algorithmType,
    required Duration executionTime,
    required Map<String, dynamic> inputData,
    required Map<String, dynamic> outputData,
    int stepsExecuted = 0,
    int memoryUsed = 0,
    int inputSize = 0,
    int outputSize = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return AlgorithmResult(
      algorithmId: algorithmId,
      algorithmName: algorithmName,
      algorithmType: algorithmType,
      resultType: AlgorithmResultType.success,
      success: true,
      executionTime: executionTime,
      inputData: inputData,
      outputData: outputData,
      stepsExecuted: stepsExecuted,
      memoryUsed: memoryUsed,
      inputSize: inputSize,
      outputSize: outputSize,
      metadata: metadata,
    );
  }

  /// Creates a failed algorithm result
  static AlgorithmResult failure({
    required String algorithmId,
    required String algorithmName,
    required AlgorithmType algorithmType,
    required Duration executionTime,
    required String errorMessage,
    required Map<String, dynamic> inputData,
    int stepsExecuted = 0,
    int memoryUsed = 0,
    int inputSize = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return AlgorithmResult(
      algorithmId: algorithmId,
      algorithmName: algorithmName,
      algorithmType: algorithmType,
      resultType: AlgorithmResultType.failure,
      success: false,
      executionTime: executionTime,
      errorMessage: errorMessage,
      inputData: inputData,
      stepsExecuted: stepsExecuted,
      memoryUsed: memoryUsed,
      inputSize: inputSize,
      metadata: metadata,
    );
  }

  /// Creates a timeout algorithm result
  static AlgorithmResult timeout({
    required String algorithmId,
    required String algorithmName,
    required AlgorithmType algorithmType,
    required Duration executionTime,
    required Duration timeout,
    required Map<String, dynamic> inputData,
    int stepsExecuted = 0,
    int memoryUsed = 0,
    int inputSize = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return AlgorithmResult(
      algorithmId: algorithmId,
      algorithmName: algorithmName,
      algorithmType: algorithmType,
      resultType: AlgorithmResultType.timeout,
      success: false,
      executionTime: executionTime,
      errorMessage: 'Algorithm timed out after ${timeout.inSeconds} seconds',
      inputData: inputData,
      stepsExecuted: stepsExecuted,
      memoryUsed: memoryUsed,
      inputSize: inputSize,
      metadata: metadata,
    );
  }

  /// Creates an error algorithm result
  static AlgorithmResult error({
    required String algorithmId,
    required String algorithmName,
    required AlgorithmType algorithmType,
    required Duration executionTime,
    required String errorMessage,
    required Map<String, dynamic> inputData,
    int stepsExecuted = 0,
    int memoryUsed = 0,
    int inputSize = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return AlgorithmResult(
      algorithmId: algorithmId,
      algorithmName: algorithmName,
      algorithmType: algorithmType,
      resultType: AlgorithmResultType.error,
      success: false,
      executionTime: executionTime,
      errorMessage: errorMessage,
      inputData: inputData,
      stepsExecuted: stepsExecuted,
      memoryUsed: memoryUsed,
      inputSize: inputSize,
      metadata: metadata,
    );
  }

  /// Creates a not applicable algorithm result
  static AlgorithmResult notApplicable({
    required String algorithmId,
    required String algorithmName,
    required AlgorithmType algorithmType,
    required String reason,
    required Map<String, dynamic> inputData,
    Map<String, dynamic> metadata = const {},
  }) {
    return AlgorithmResult(
      algorithmId: algorithmId,
      algorithmName: algorithmName,
      algorithmType: algorithmType,
      resultType: AlgorithmResultType.notApplicable,
      success: false,
      executionTime: Duration.zero,
      errorMessage: reason,
      inputData: inputData,
      metadata: metadata,
    );
  }

  /// Creates an algorithm result from an execution report
  static AlgorithmResult fromExecutionReport({
    required String algorithmId,
    required String algorithmName,
    required AlgorithmType algorithmType,
    required ExecutionReport executionReport,
    required Map<String, dynamic> inputData,
    required Map<String, dynamic> outputData,
    Map<String, dynamic> metadata = const {},
  }) {
    AlgorithmResultType resultType;
    bool success;
    String errorMessage = '';

    switch (executionReport.resultType) {
      case ExecutionResultType.success:
        resultType = AlgorithmResultType.success;
        success = true;
        break;
      case ExecutionResultType.failure:
        resultType = AlgorithmResultType.failure;
        success = false;
        errorMessage = executionReport.errorMessage;
        break;
      case ExecutionResultType.timeout:
        resultType = AlgorithmResultType.timeout;
        success = false;
        errorMessage = executionReport.errorMessage;
        break;
      case ExecutionResultType.infiniteLoop:
        resultType = AlgorithmResultType.error;
        success = false;
        errorMessage = executionReport.errorMessage;
        break;
      case ExecutionResultType.error:
        resultType = AlgorithmResultType.error;
        success = false;
        errorMessage = executionReport.errorMessage;
        break;
    }

    return AlgorithmResult(
      algorithmId: algorithmId,
      algorithmName: algorithmName,
      algorithmType: algorithmType,
      resultType: resultType,
      success: success,
      executionTime: executionReport.executionTime,
      errorMessage: errorMessage,
      inputData: inputData,
      outputData: outputData,
      stepsExecuted: executionReport.totalSteps,
      memoryUsed: 0, // Not available in execution report
      inputSize: 0, // Not available in execution report
      outputSize: 0, // Not available in execution report
      metadata: metadata,
    );
  }
}
