/// Single step in an automaton simulation
class SimulationStep {
  /// Current state in this step
  final String currentState;
  
  /// Remaining input string
  final String remainingInput;
  
  /// Stack contents (for PDA)
  final String stackContents;
  
  /// Tape contents (for TM)
  final String tapeContents;
  
  /// Transition used in this step (if any)
  final String? usedTransition;
  
  /// Step number in the simulation
  final int stepNumber;

  const SimulationStep({
    required this.currentState,
    required this.remainingInput,
    this.stackContents = '',
    this.tapeContents = '',
    this.usedTransition,
    required this.stepNumber,
  });

  /// Creates a copy of this simulation step with updated properties
  SimulationStep copyWith({
    String? currentState,
    String? remainingInput,
    String? stackContents,
    String? tapeContents,
    String? usedTransition,
    int? stepNumber,
  }) {
    return SimulationStep(
      currentState: currentState ?? this.currentState,
      remainingInput: remainingInput ?? this.remainingInput,
      stackContents: stackContents ?? this.stackContents,
      tapeContents: tapeContents ?? this.tapeContents,
      usedTransition: usedTransition ?? this.usedTransition,
      stepNumber: stepNumber ?? this.stepNumber,
    );
  }

  /// Converts the simulation step to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'currentState': currentState,
      'remainingInput': remainingInput,
      'stackContents': stackContents,
      'tapeContents': tapeContents,
      'usedTransition': usedTransition,
      'stepNumber': stepNumber,
    };
  }

  /// Creates a simulation step from a JSON representation
  factory SimulationStep.fromJson(Map<String, dynamic> json) {
    return SimulationStep(
      currentState: json['currentState'] as String,
      remainingInput: json['remainingInput'] as String,
      stackContents: json['stackContents'] as String? ?? '',
      tapeContents: json['tapeContents'] as String? ?? '',
      usedTransition: json['usedTransition'] as String?,
      stepNumber: json['stepNumber'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimulationStep &&
        other.currentState == currentState &&
        other.remainingInput == remainingInput &&
        other.stackContents == stackContents &&
        other.tapeContents == tapeContents &&
        other.usedTransition == usedTransition &&
        other.stepNumber == stepNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentState,
      remainingInput,
      stackContents,
      tapeContents,
      usedTransition,
      stepNumber,
    );
  }

  @override
  String toString() {
    return 'SimulationStep(stepNumber: $stepNumber, currentState: $currentState, remainingInput: $remainingInput)';
  }

  /// Checks if this is the first step
  bool get isFirstStep => stepNumber == 1;

  /// Checks if this is the last step
  bool get isLastStep => stepNumber == 0; // This will be set by the simulation

  /// Checks if a transition was used in this step
  bool get hasTransition => usedTransition != null;

  /// Checks if this step has stack operations (for PDA)
  bool get hasStackOperations => stackContents.isNotEmpty;

  /// Checks if this step has tape operations (for TM)
  bool get hasTapeOperations => tapeContents.isNotEmpty;

  /// Gets the number of remaining input symbols
  int get remainingInputLength => remainingInput.length;

  /// Gets the number of stack symbols (for PDA)
  int get stackLength => stackContents.length;

  /// Gets the number of tape symbols (for TM)
  int get tapeLength => tapeContents.length;

  /// Gets the top of the stack (for PDA)
  String? get stackTop => stackContents.isNotEmpty ? stackContents[0] : null;

  /// Gets the current tape symbol (for TM)
  String? get currentTapeSymbol => tapeContents.isNotEmpty ? tapeContents[0] : null;

  /// Gets the next input symbol
  String? get nextInputSymbol => remainingInput.isNotEmpty ? remainingInput[0] : null;

  /// Gets the consumed input in this step
  String get consumedInput {
    // This would need to be calculated based on the previous step
    // For now, return empty string
    return '';
  }

  /// Gets the stack operation performed (for PDA)
  String get stackOperation {
    if (stackContents.isEmpty) return 'none';
    return 'stack: $stackContents';
  }

  /// Gets the tape operation performed (for TM)
  String get tapeOperation {
    if (tapeContents.isEmpty) return 'none';
    return 'tape: $tapeContents';
  }

  /// Gets a summary of this step
  String get summary {
    final buffer = StringBuffer();
    buffer.write('Step $stepNumber: State $currentState');
    
    if (remainingInput.isNotEmpty) {
      buffer.write(', Input: $remainingInput');
    }
    
    if (stackContents.isNotEmpty) {
      buffer.write(', Stack: $stackContents');
    }
    
    if (tapeContents.isNotEmpty) {
      buffer.write(', Tape: $tapeContents');
    }
    
    if (usedTransition != null) {
      buffer.write(', Transition: $usedTransition');
    }
    
    return buffer.toString();
  }

  /// Creates a simulation step for FSA
  factory SimulationStep.fsa({
    required String currentState,
    required String remainingInput,
    String? usedTransition,
    required int stepNumber,
  }) {
    return SimulationStep(
      currentState: currentState,
      remainingInput: remainingInput,
      usedTransition: usedTransition,
      stepNumber: stepNumber,
    );
  }

  /// Creates a simulation step for PDA
  factory SimulationStep.pda({
    required String currentState,
    required String remainingInput,
    required String stackContents,
    String? usedTransition,
    required int stepNumber,
  }) {
    return SimulationStep(
      currentState: currentState,
      remainingInput: remainingInput,
      stackContents: stackContents,
      usedTransition: usedTransition,
      stepNumber: stepNumber,
    );
  }

  /// Creates a simulation step for TM
  factory SimulationStep.tm({
    required String currentState,
    required String remainingInput,
    required String tapeContents,
    String? usedTransition,
    required int stepNumber,
  }) {
    return SimulationStep(
      currentState: currentState,
      remainingInput: remainingInput,
      tapeContents: tapeContents,
      usedTransition: usedTransition,
      stepNumber: stepNumber,
    );
  }

  /// Creates an initial simulation step
  factory SimulationStep.initial({
    required String initialState,
    required String inputString,
    String? initialStackSymbol,
    String? initialTapeSymbol,
  }) {
    return SimulationStep(
      currentState: initialState,
      remainingInput: inputString,
      stackContents: initialStackSymbol ?? '',
      tapeContents: initialTapeSymbol ?? '',
      stepNumber: 0,
    );
  }

  /// Creates a final simulation step
  factory SimulationStep.final({
    required String finalState,
    required String remainingInput,
    required String stackContents,
    required String tapeContents,
    required int stepNumber,
  }) {
    return SimulationStep(
      currentState: finalState,
      remainingInput: remainingInput,
      stackContents: stackContents,
      tapeContents: tapeContents,
      stepNumber: stepNumber,
    );
  }
}
