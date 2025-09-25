import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core_fa/core_fa.dart';

part 'configuration.freezed.dart';
part 'configuration.g.dart';

/// Configuration represents the state of an automaton at a specific point in execution
@freezed
class Configuration with _$Configuration {
  const factory Configuration({
    required String stateId,
    required String inputString,
    required int inputPosition,
    required String remainingInput,
    @Default('') String stackContents, // For PDA
    @Default('') String tapeContents, // For TM
    @Default(0) int tapePosition, // For TM
    @Default(0) int stepNumber,
    @Default({}) Map<String, dynamic> metadata,
  }) = _Configuration;

  factory Configuration.fromJson(Map<String, dynamic> json) => _$ConfigurationFromJson(json);
}

/// Extension methods for Configuration to provide automaton-specific functionality
extension ConfigurationExtension on Configuration {
  /// Validates the configuration properties
  List<String> validate() {
    final errors = <String>[];
    
    if (stateId.isEmpty) {
      errors.add('State ID cannot be empty');
    }
    
    if (inputPosition < 0) {
      errors.add('Input position cannot be negative');
    }
    
    if (inputPosition > inputString.length) {
      errors.add('Input position cannot exceed input string length');
    }
    
    if (stepNumber < 0) {
      errors.add('Step number cannot be negative');
    }
    
    if (tapePosition < 0) {
      errors.add('Tape position cannot be negative');
    }
    
    if (tapePosition > tapeContents.length) {
      errors.add('Tape position cannot exceed tape contents length');
    }
    
    return errors;
  }

  /// Checks if the configuration is valid
  bool get isValid => validate().isEmpty;

  /// Gets the current input symbol
  String? get currentInputSymbol {
    if (inputPosition >= inputString.length) return null;
    return inputString[inputPosition];
  }

  /// Gets the next input symbol
  String? get nextInputSymbol {
    if (inputPosition + 1 >= inputString.length) return null;
    return inputString[inputPosition + 1];
  }

  /// Gets the previous input symbol
  String? get previousInputSymbol {
    if (inputPosition <= 0) return null;
    return inputString[inputPosition - 1];
  }

  /// Gets the current tape symbol (for TM)
  String? get currentTapeSymbol {
    if (tapePosition >= tapeContents.length) return null;
    return tapeContents[tapePosition];
  }

  /// Gets the next tape symbol (for TM)
  String? get nextTapeSymbol {
    if (tapePosition + 1 >= tapeContents.length) return null;
    return tapeContents[tapePosition + 1];
  }

  /// Gets the previous tape symbol (for TM)
  String? get previousTapeSymbol {
    if (tapePosition <= 0) return null;
    return tapeContents[tapePosition - 1];
  }

  /// Gets the top of the stack (for PDA)
  String? get stackTop {
    if (stackContents.isEmpty) return null;
    return stackContents[0];
  }

  /// Gets the bottom of the stack (for PDA)
  String? get stackBottom {
    if (stackContents.isEmpty) return null;
    return stackContents[stackContents.length - 1];
  }

  /// Gets the number of input symbols consumed
  int get inputSymbolsConsumed => inputPosition;

  /// Gets the number of input symbols remaining
  int get inputSymbolsRemaining => inputString.length - inputPosition;

  /// Gets the number of stack symbols (for PDA)
  int get stackLength => stackContents.length;

  /// Gets the number of tape symbols (for TM)
  int get tapeLength => tapeContents.length;

  /// Checks if all input has been consumed
  bool get allInputConsumed => inputPosition >= inputString.length;

  /// Checks if the stack is empty (for PDA)
  bool get isStackEmpty => stackContents.isEmpty;

  /// Checks if the tape is empty (for TM)
  bool get isTapeEmpty => tapeContents.isEmpty;

  /// Gets a summary of the configuration
  String get summary {
    final buffer = StringBuffer();
    buffer.write('Step $stepNumber: State $stateId');
    
    if (inputString.isNotEmpty) {
      buffer.write(', Input: $inputString');
      buffer.write(' (pos: $inputPosition)');
    }
    
    if (stackContents.isNotEmpty) {
      buffer.write(', Stack: $stackContents');
    }
    
    if (tapeContents.isNotEmpty) {
      buffer.write(', Tape: $tapeContents');
      buffer.write(' (pos: $tapePosition)');
    }
    
    return buffer.toString();
  }

  /// Gets a detailed description of the configuration
  String get description {
    final buffer = StringBuffer();
    buffer.writeln('Configuration at step $stepNumber:');
    buffer.writeln('  Current state: $stateId');
    buffer.writeln('  Input string: $inputString');
    buffer.writeln('  Input position: $inputPosition');
    buffer.writeln('  Remaining input: $remainingInput');
    
    if (stackContents.isNotEmpty) {
      buffer.writeln('  Stack contents: $stackContents');
    }
    
    if (tapeContents.isNotEmpty) {
      buffer.writeln('  Tape contents: $tapeContents');
      buffer.writeln('  Tape position: $tapePosition');
    }
    
    if (metadata.isNotEmpty) {
      buffer.writeln('  Metadata: $metadata');
    }
    
    return buffer.toString();
  }

  /// Creates a copy with updated input position
  Configuration withInputPosition(int newPosition) {
    return copyWith(
      inputPosition: newPosition,
      remainingInput: inputString.substring(newPosition),
    );
  }

  /// Creates a copy with updated tape position
  Configuration withTapePosition(int newPosition) {
    return copyWith(tapePosition: newPosition);
  }

  /// Creates a copy with updated stack contents
  Configuration withStackContents(String newStackContents) {
    return copyWith(stackContents: newStackContents);
  }

  /// Creates a copy with updated tape contents
  Configuration withTapeContents(String newTapeContents) {
    return copyWith(tapeContents: newTapeContents);
  }

  /// Creates a copy with updated state
  Configuration withState(String newStateId) {
    return copyWith(stateId: newStateId);
  }

  /// Creates a copy with updated step number
  Configuration withStepNumber(int newStepNumber) {
    return copyWith(stepNumber: newStepNumber);
  }

  /// Creates a copy with updated metadata
  Configuration withMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(metadata: newMetadata);
  }

  /// Creates a copy with additional metadata
  Configuration withAdditionalMetadata(String key, dynamic value) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata[key] = value;
    return copyWith(metadata: newMetadata);
  }
}

/// Factory methods for creating common configuration patterns
class ConfigurationFactory {
  /// Creates an initial configuration for FSA
  static Configuration fsaInitial({
    required String initialStateId,
    required String inputString,
  }) {
    return Configuration(
      stateId: initialStateId,
      inputString: inputString,
      inputPosition: 0,
      remainingInput: inputString,
      stepNumber: 0,
    );
  }

  /// Creates an initial configuration for PDA
  static Configuration pdaInitial({
    required String initialStateId,
    required String inputString,
    required String initialStackSymbol,
  }) {
    return Configuration(
      stateId: initialStateId,
      inputString: inputString,
      inputPosition: 0,
      remainingInput: inputString,
      stackContents: initialStackSymbol,
      stepNumber: 0,
    );
  }

  /// Creates an initial configuration for TM
  static Configuration tmInitial({
    required String initialStateId,
    required String inputString,
    required String tapeContents,
    int tapePosition = 0,
  }) {
    return Configuration(
      stateId: initialStateId,
      inputString: inputString,
      inputPosition: 0,
      remainingInput: inputString,
      tapeContents: tapeContents,
      tapePosition: tapePosition,
      stepNumber: 0,
    );
  }

  /// Creates a final configuration
  static Configuration final_({
    required String finalStateId,
    required String inputString,
    required int inputPosition,
    String stackContents = '',
    String tapeContents = '',
    int tapePosition = 0,
    required int stepNumber,
  }) {
    return Configuration(
      stateId: finalStateId,
      inputString: inputString,
      inputPosition: inputPosition,
      remainingInput: inputString.substring(inputPosition),
      stackContents: stackContents,
      tapeContents: tapeContents,
      tapePosition: tapePosition,
      stepNumber: stepNumber,
    );
  }

  /// Creates a configuration from a simulation step
  static Configuration fromSimulationStep({
    required String currentState,
    required String inputString,
    required int inputPosition,
    String stackContents = '',
    String tapeContents = '',
    int tapePosition = 0,
    required int stepNumber,
    Map<String, dynamic> metadata = const {},
  }) {
    return Configuration(
      stateId: currentState,
      inputString: inputString,
      inputPosition: inputPosition,
      remainingInput: inputString.substring(inputPosition),
      stackContents: stackContents,
      tapeContents: tapeContents,
      tapePosition: tapePosition,
      stepNumber: stepNumber,
      metadata: metadata,
    );
  }
}
