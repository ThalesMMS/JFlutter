//
//  equivalence_comparison_step.dart
//  JFlutter
//
//  Define o modelo detalhado de passos da comparação de equivalência entre dois
//  autômatos finitos via construção do autômato produto. Captura pares de estados,
//  símbolos processados, caminhos percorridos, diferenças encontradas e resultados
//  de aceitação para cada etapa, permitindo visualização educacional passo a passo
//  do processo de comparação de linguagens.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'algorithm_step.dart';
import 'state.dart';

/// Represents a single step in language equivalence comparison using product automaton
class EquivalenceComparisonStep {
  /// Base algorithm step information
  final AlgorithmStep baseStep;

  /// Type of operation performed in this step
  final EquivalenceComparisonStepType stepType;

  /// Current state pair being processed from automaton A and B (qA, qB)
  final StatePair? currentStatePair;

  /// Symbol being processed in this step (null for non-symbol steps)
  final String? processedSymbol;

  /// Next state pair reached after processing symbol
  final StatePair? nextStatePair;

  /// Whether the current state pair has been visited before
  final bool isVisited;

  /// Whether the current state pair is accepting in automaton A
  final bool isAcceptingInA;

  /// Whether the current state pair is accepting in automaton B
  final bool isAcceptingInB;

  /// Whether acceptance status differs (indicates non-equivalence)
  final bool acceptanceDiffers;

  /// Path taken from initial state to current state (sequence of symbols)
  final List<String>? pathFromInitial;

  /// Distinguishing string found (if non-equivalent)
  final String? distinguishingString;

  /// Queue of state pairs to be processed
  final List<StatePair>? processingQueue;

  /// Set of visited state pairs
  final Set<StatePair>? visitedPairs;

  /// Normalized alphabet being used for comparison
  final Set<String>? normalizedAlphabet;

  /// Product automaton state ID created for this pair (if applicable)
  final String? productStateId;

  /// Product automaton state label created for this pair (if applicable)
  final String? productStateLabel;

  /// Whether this step resulted in finding a counterexample
  final bool foundCounterexample;

  const EquivalenceComparisonStep._internal({
    required this.baseStep,
    required this.stepType,
    this.currentStatePair,
    this.processedSymbol,
    this.nextStatePair,
    required this.isVisited,
    required this.isAcceptingInA,
    required this.isAcceptingInB,
    required this.acceptanceDiffers,
    this.pathFromInitial,
    this.distinguishingString,
    this.processingQueue,
    this.visitedPairs,
    this.normalizedAlphabet,
    this.productStateId,
    this.productStateLabel,
    required this.foundCounterexample,
  });

  factory EquivalenceComparisonStep({
    required AlgorithmStep baseStep,
    required EquivalenceComparisonStepType stepType,
    StatePair? currentStatePair,
    String? processedSymbol,
    StatePair? nextStatePair,
    bool isVisited = false,
    bool isAcceptingInA = false,
    bool isAcceptingInB = false,
    bool acceptanceDiffers = false,
    List<String>? pathFromInitial,
    String? distinguishingString,
    List<StatePair>? processingQueue,
    Set<StatePair>? visitedPairs,
    Set<String>? normalizedAlphabet,
    String? productStateId,
    String? productStateLabel,
    bool foundCounterexample = false,
  }) {
    return EquivalenceComparisonStep._internal(
      baseStep: baseStep,
      stepType: stepType,
      currentStatePair: currentStatePair,
      processedSymbol: processedSymbol,
      nextStatePair: nextStatePair,
      isVisited: isVisited,
      isAcceptingInA: isAcceptingInA,
      isAcceptingInB: isAcceptingInB,
      acceptanceDiffers: acceptanceDiffers,
      pathFromInitial: pathFromInitial != null
          ? List.unmodifiable(pathFromInitial)
          : null,
      distinguishingString: distinguishingString,
      processingQueue: processingQueue != null
          ? List.unmodifiable(processingQueue)
          : null,
      visitedPairs: visitedPairs != null
          ? Set.unmodifiable(visitedPairs)
          : null,
      normalizedAlphabet: normalizedAlphabet != null
          ? Set.unmodifiable(normalizedAlphabet)
          : null,
      productStateId: productStateId,
      productStateLabel: productStateLabel,
      foundCounterexample: foundCounterexample,
    );
  }

  /// Creates an initialization step
  factory EquivalenceComparisonStep.initialization({
    required String id,
    required int stepNumber,
    required String automatonAName,
    required String automatonBName,
  }) {
    return EquivalenceComparisonStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Initialize comparison',
        explanation:
            'Starting language equivalence comparison between automaton $automatonAName and automaton $automatonBName. '
            'We will construct a product automaton and search for a distinguishing string using breadth-first search. '
            'If we find a state pair (qA, qB) where one is accepting and the other is not, the languages are different.',
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: EquivalenceComparisonStepType.initialization,
    );
  }

  /// Creates an alphabet normalization step
  factory EquivalenceComparisonStep.normalization({
    required String id,
    required int stepNumber,
    required Set<String> alphabetA,
    required Set<String> alphabetB,
    required Set<String> normalizedAlphabet,
  }) {
    final alphabetAStr = alphabetA.join(', ');
    final alphabetBStr = alphabetB.join(', ');
    final normalizedStr = normalizedAlphabet.join(', ');
    return EquivalenceComparisonStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Normalize alphabets',
        explanation:
            'Combining alphabets from both automata. '
            'Automaton A uses: {$alphabetAStr}. '
            'Automaton B uses: {$alphabetBStr}. '
            'Normalized alphabet: {$normalizedStr}. '
            'Both automata will be completed to handle all symbols in the normalized alphabet.',
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: EquivalenceComparisonStepType.normalization,
      normalizedAlphabet: normalizedAlphabet,
    );
  }

  /// Creates a DFA conversion step
  factory EquivalenceComparisonStep.dfaConversion({
    required String id,
    required int stepNumber,
    required String automatonName,
    required bool wasNFA,
    required int nfaStateCount,
    required int dfaStateCount,
  }) {
    final conversionInfo = wasNFA
        ? 'Converting $automatonName from NFA with $nfaStateCount states to DFA with $dfaStateCount states using subset construction. '
        : '$automatonName is already a DFA with $dfaStateCount states. ';
    return EquivalenceComparisonStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: wasNFA
            ? 'Convert $automatonName to DFA'
            : 'Verify $automatonName is DFA',
        explanation:
            '${conversionInfo}For equivalence comparison, both automata must be deterministic.',
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: EquivalenceComparisonStepType.dfaConversion,
    );
  }

  /// Creates a product construction step
  factory EquivalenceComparisonStep.productConstruction({
    required String id,
    required int stepNumber,
    required State initialStateA,
    required State initialStateB,
    required StatePair initialPair,
  }) {
    final pairLabel = '(${initialStateA.label}, ${initialStateB.label})';
    return EquivalenceComparisonStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Construct initial product state',
        explanation:
            'Creating the initial state of the product automaton from initial states '
            '${initialStateA.label} and ${initialStateB.label}. '
            'Product state is labeled as $pairLabel. '
            'We will explore this product automaton using BFS to check if we can reach a state '
            'where acceptance status differs.',
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: EquivalenceComparisonStepType.productConstruction,
      currentStatePair: initialPair,
      productStateId: 'q0',
      productStateLabel: pairLabel,
      isAcceptingInA: initialStateA.isAccepting,
      isAcceptingInB: initialStateB.isAccepting,
      acceptanceDiffers: initialStateA.isAccepting != initialStateB.isAccepting,
    );
  }

  /// Creates a state visit step
  factory EquivalenceComparisonStep.stateVisit({
    required String id,
    required int stepNumber,
    required StatePair statePair,
    required bool isAcceptingInA,
    required bool isAcceptingInB,
    required List<String> pathFromInitial,
    required int queueSize,
    required int visitedCount,
  }) {
    final pairLabel = '(${statePair.stateA.label}, ${statePair.stateB.label})';
    final pathStr = pathFromInitial.isEmpty
        ? 'ε (empty string)'
        : pathFromInitial.join('');
    final acceptanceInfo = isAcceptingInA == isAcceptingInB
        ? 'Both states have the same acceptance status.'
        : 'DIFFERENCE FOUND: ${statePair.stateA.label} is ${isAcceptingInA ? "accepting" : "non-accepting"} '
              'but ${statePair.stateB.label} is ${isAcceptingInB ? "accepting" : "non-accepting"}.';
    return EquivalenceComparisonStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Visit state pair $pairLabel',
        explanation:
            'Visiting product state $pairLabel (path: $pathStr). '
            '$acceptanceInfo '
            'Queue size: $queueSize. Visited: $visitedCount state pairs.',
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: EquivalenceComparisonStepType.stateVisit,
      currentStatePair: statePair,
      isAcceptingInA: isAcceptingInA,
      isAcceptingInB: isAcceptingInB,
      acceptanceDiffers: isAcceptingInA != isAcceptingInB,
      pathFromInitial: pathFromInitial,
      productStateLabel: pairLabel,
    );
  }

  /// Creates a symbol processing step
  factory EquivalenceComparisonStep.processSymbol({
    required String id,
    required int stepNumber,
    required StatePair currentPair,
    required String symbol,
    required StatePair nextPair,
    required bool isNewState,
  }) {
    final currentLabel =
        '(${currentPair.stateA.label}, ${currentPair.stateB.label})';
    final nextLabel = '(${nextPair.stateA.label}, ${nextPair.stateB.label})';
    final newStateInfo = isNewState
        ? 'This is a new state pair that will be added to the queue.'
        : 'This state pair has already been visited.';
    return EquivalenceComparisonStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Process symbol \'$symbol\'',
        explanation:
            'From state pair $currentLabel, processing symbol \'$symbol\'. '
            'Automaton A transitions from ${currentPair.stateA.label} to ${nextPair.stateA.label}. '
            'Automaton B transitions from ${currentPair.stateB.label} to ${nextPair.stateB.label}. '
            'Next product state: $nextLabel. $newStateInfo',
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: EquivalenceComparisonStepType.stateVisit,
      currentStatePair: currentPair,
      processedSymbol: symbol,
      nextStatePair: nextPair,
      isVisited: !isNewState,
      productStateLabel: nextLabel,
    );
  }

  /// Creates an equivalence check step
  factory EquivalenceComparisonStep.equivalenceCheck({
    required String id,
    required int stepNumber,
    required int totalStatesVisited,
    required int totalTransitionsChecked,
  }) {
    return EquivalenceComparisonStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Confirm equivalence',
        explanation:
            'Completed exploration of the product automaton without finding any state pair '
            'where acceptance status differs. Visited $totalStatesVisited state pairs and checked '
            '$totalTransitionsChecked transitions. The two automata are EQUIVALENT - they recognize '
            'the same language.',
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: EquivalenceComparisonStepType.equivalenceCheck,
    );
  }

  /// Creates a counterexample found step
  factory EquivalenceComparisonStep.counterexampleFound({
    required String id,
    required int stepNumber,
    required StatePair statePair,
    required String distinguishingString,
    required bool acceptedByA,
    required bool acceptedByB,
  }) {
    final pairLabel = '(${statePair.stateA.label}, ${statePair.stateB.label})';
    final stringDisplay = distinguishingString.isEmpty
        ? 'ε (empty string)'
        : '"$distinguishingString"';
    final acceptanceExplanation = acceptedByA
        ? 'This string is ACCEPTED by automaton A but REJECTED by automaton B.'
        : 'This string is REJECTED by automaton A but ACCEPTED by automaton B.';
    return EquivalenceComparisonStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Counterexample found',
        explanation:
            'Found a distinguishing string at state pair $pairLabel. '
            'The string $stringDisplay differentiates the two languages. '
            '$acceptanceExplanation '
            'The automata are NOT EQUIVALENT.',
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: EquivalenceComparisonStepType.counterexampleFound,
      currentStatePair: statePair,
      distinguishingString: distinguishingString,
      isAcceptingInA: acceptedByA,
      isAcceptingInB: acceptedByB,
      acceptanceDiffers: true,
      foundCounterexample: true,
      productStateLabel: pairLabel,
    );
  }

  /// Creates a completion step
  factory EquivalenceComparisonStep.completion({
    required String id,
    required int stepNumber,
    required bool isEquivalent,
    required int totalStepsExecuted,
    required int executionTimeMs,
  }) {
    final resultText = isEquivalent
        ? 'The two automata are EQUIVALENT - they recognize the same language.'
        : 'The two automata are NOT EQUIVALENT - a distinguishing string was found.';
    return EquivalenceComparisonStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Comparison complete',
        explanation:
            'Language equivalence comparison completed in $totalStepsExecuted steps '
            '($executionTimeMs ms). $resultText',
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: EquivalenceComparisonStepType.completion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EquivalenceComparisonStep &&
        other.baseStep == baseStep &&
        other.stepType == stepType &&
        other.currentStatePair == currentStatePair &&
        other.processedSymbol == processedSymbol &&
        other.nextStatePair == nextStatePair &&
        other.isVisited == isVisited &&
        other.isAcceptingInA == isAcceptingInA &&
        other.isAcceptingInB == isAcceptingInB &&
        other.acceptanceDiffers == acceptanceDiffers &&
        other.distinguishingString == distinguishingString &&
        other.foundCounterexample == foundCounterexample;
  }

  @override
  int get hashCode {
    return Object.hash(
      baseStep,
      stepType,
      currentStatePair,
      processedSymbol,
      nextStatePair,
      isVisited,
      isAcceptingInA,
      isAcceptingInB,
      acceptanceDiffers,
      distinguishingString,
      foundCounterexample,
    );
  }

  @override
  String toString() {
    return 'EquivalenceComparisonStep('
        'stepNumber: ${baseStep.stepNumber}, '
        'type: $stepType, '
        'title: ${baseStep.title})';
  }
}

/// Types of steps in the equivalence comparison algorithm
enum EquivalenceComparisonStepType {
  /// Initial setup and preparation
  initialization,

  /// Normalizing alphabets from both automata
  normalization,

  /// Converting NFA to DFA (if needed)
  dfaConversion,

  /// Constructing the product automaton
  productConstruction,

  /// Visiting a state pair during BFS traversal
  stateVisit,

  /// Checking final equivalence result
  equivalenceCheck,

  /// Found a counterexample (distinguishing string)
  counterexampleFound,

  /// Algorithm completion
  completion,
}

/// Extension methods for EquivalenceComparisonStepType
extension EquivalenceComparisonStepTypeExtension
    on EquivalenceComparisonStepType {
  /// Gets a human-readable name for the step type
  String get displayName {
    switch (this) {
      case EquivalenceComparisonStepType.initialization:
        return 'Initialization';
      case EquivalenceComparisonStepType.normalization:
        return 'Alphabet Normalization';
      case EquivalenceComparisonStepType.dfaConversion:
        return 'DFA Conversion';
      case EquivalenceComparisonStepType.productConstruction:
        return 'Product Construction';
      case EquivalenceComparisonStepType.stateVisit:
        return 'State Visit';
      case EquivalenceComparisonStepType.equivalenceCheck:
        return 'Equivalence Check';
      case EquivalenceComparisonStepType.counterexampleFound:
        return 'Counterexample Found';
      case EquivalenceComparisonStepType.completion:
        return 'Completion';
    }
  }
}

/// Represents a pair of states from two automata in the product construction
class StatePair {
  /// State from the first automaton
  final State stateA;

  /// State from the second automaton
  final State stateB;

  const StatePair({required this.stateA, required this.stateB});

  /// Gets the combined label for this state pair
  String get label => '(${stateA.label}, ${stateB.label})';

  /// Gets the combined ID for this state pair
  String get id => '${stateA.id}_${stateB.id}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatePair &&
        other.stateA == stateA &&
        other.stateB == stateB;
  }

  @override
  int get hashCode => Object.hash(stateA, stateB);

  @override
  String toString() => label;
}
