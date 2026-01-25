//
//  regex_to_nfa_step.dart
//  JFlutter
//
//  Define o modelo detalhado de passos da conversão Regex→NFA via construção de
//  Thompson. Captura fragmentos de regex, operações (símbolo básico, concatenação,
//  união, estrela de Kleene), estados e transições criadas, e pilha de fragmentos
//  NFA para cada etapa do algoritmo, permitindo visualização educacional passo a
//  passo.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'algorithm_step.dart';
import 'state.dart';
import 'transition.dart';

/// Represents a single step in Regex to NFA conversion using Thompson's construction
class RegexToNFAStep {
  /// Base algorithm step information
  final AlgorithmStep baseStep;

  /// Type of operation performed in this step
  final RegexToNFAStepType stepType;

  /// Current regex substring being processed
  final String? regexFragment;

  /// Position in the original regex expression
  final int? regexPosition;

  /// Symbol being processed (for basic symbol steps)
  final String? processedSymbol;

  /// States created in this step
  final Set<State>? createdStates;

  /// Transitions created in this step
  final Set<Transition>? createdTransitions;

  /// Start state of the NFA fragment created/modified
  final State? fragmentStartState;

  /// Accept state of the NFA fragment created/modified
  final State? fragmentAcceptState;

  /// NFA fragment stack size after this step
  final int? stackSize;

  /// Whether this step combines two NFA fragments
  final bool combinesFragments;

  /// First fragment being combined (for binary operations)
  final String? firstFragmentLabel;

  /// Second fragment being combined (for binary operations)
  final String? secondFragmentLabel;

  /// Fragment being modified (for unary operations like Kleene star)
  final String? modifiedFragmentLabel;

  /// Whether this is the final NFA
  final bool isFinalNFA;

  /// Total number of states in the current NFA
  final int? totalStates;

  /// Total number of transitions in the current NFA
  final int? totalTransitions;

  const RegexToNFAStep._internal({
    required this.baseStep,
    required this.stepType,
    this.regexFragment,
    this.regexPosition,
    this.processedSymbol,
    this.createdStates,
    this.createdTransitions,
    this.fragmentStartState,
    this.fragmentAcceptState,
    this.stackSize,
    required this.combinesFragments,
    this.firstFragmentLabel,
    this.secondFragmentLabel,
    this.modifiedFragmentLabel,
    required this.isFinalNFA,
    this.totalStates,
    this.totalTransitions,
  });

  factory RegexToNFAStep({
    required AlgorithmStep baseStep,
    required RegexToNFAStepType stepType,
    String? regexFragment,
    int? regexPosition,
    String? processedSymbol,
    Set<State>? createdStates,
    Set<Transition>? createdTransitions,
    State? fragmentStartState,
    State? fragmentAcceptState,
    int? stackSize,
    bool combinesFragments = false,
    String? firstFragmentLabel,
    String? secondFragmentLabel,
    String? modifiedFragmentLabel,
    bool isFinalNFA = false,
    int? totalStates,
    int? totalTransitions,
  }) {
    return RegexToNFAStep._internal(
      baseStep: baseStep,
      stepType: stepType,
      regexFragment: regexFragment,
      regexPosition: regexPosition,
      processedSymbol: processedSymbol,
      createdStates: createdStates != null
          ? Set.unmodifiable(createdStates)
          : null,
      createdTransitions: createdTransitions != null
          ? Set.unmodifiable(createdTransitions)
          : null,
      fragmentStartState: fragmentStartState,
      fragmentAcceptState: fragmentAcceptState,
      stackSize: stackSize,
      combinesFragments: combinesFragments,
      firstFragmentLabel: firstFragmentLabel,
      secondFragmentLabel: secondFragmentLabel,
      modifiedFragmentLabel: modifiedFragmentLabel,
      isFinalNFA: isFinalNFA,
      totalStates: totalStates,
      totalTransitions: totalTransitions,
    );
  }

  /// Creates a step for starting the conversion
  factory RegexToNFAStep.start({
    required String id,
    required int stepNumber,
    required String regex,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Begin Thompson\'s construction',
        explanation:
            'Starting conversion of regular expression "$regex" to NFA using Thompson\'s construction. '
            'This algorithm builds an NFA by parsing the regex and creating NFA fragments for each subexpression, '
            'then combining them using ε-transitions according to regex operators.',
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.start,
      regexFragment: regex,
      regexPosition: 0,
      stackSize: 0,
    );
  }

  /// Creates a step for processing a basic symbol
  factory RegexToNFAStep.basicSymbol({
    required String id,
    required int stepNumber,
    required String symbol,
    required int position,
    required State startState,
    required State acceptState,
    required Transition transition,
    required int stackSize,
  }) {
    final displaySymbol = symbol.isEmpty ? 'ε' : symbol;
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Create NFA for symbol \'$displaySymbol\'',
        explanation:
            'Processing symbol \'$displaySymbol\' at position $position. '
            'Creating a simple NFA fragment with two states: '
            'start state ${startState.label} and accept state ${acceptState.label}, '
            'connected by a transition on \'$displaySymbol\'. '
            'This fragment is pushed onto the NFA stack.',
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.basicSymbol,
      regexFragment: symbol,
      regexPosition: position,
      processedSymbol: symbol,
      createdStates: {startState, acceptState},
      createdTransitions: {transition},
      fragmentStartState: startState,
      fragmentAcceptState: acceptState,
      stackSize: stackSize,
    );
  }

  /// Creates a step for the concatenation operation
  factory RegexToNFAStep.concatenation({
    required String id,
    required int stepNumber,
    required int position,
    required String firstFragmentLabel,
    required String secondFragmentLabel,
    required State firstStart,
    required State firstAccept,
    required State secondStart,
    required State secondAccept,
    required Transition epsilonTransition,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Apply concatenation',
        explanation:
            'Concatenating two NFA fragments at position $position. '
            'Popping fragments for "$secondFragmentLabel" and "$firstFragmentLabel" from the stack. '
            'Merging the accept state of the first fragment (${firstAccept.label}) with the start state '
            'of the second fragment (${secondStart.label}) using an ε-transition. '
            'The resulting fragment has start state ${firstStart.label} and accept state ${secondAccept.label}.',
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.concatenation,
      regexPosition: position,
      combinesFragments: true,
      firstFragmentLabel: firstFragmentLabel,
      secondFragmentLabel: secondFragmentLabel,
      createdTransitions: {epsilonTransition},
      fragmentStartState: firstStart,
      fragmentAcceptState: secondAccept,
      stackSize: stackSize,
    );
  }

  /// Creates a step for the union (alternation) operation
  factory RegexToNFAStep.union({
    required String id,
    required int stepNumber,
    required int position,
    required String firstFragmentLabel,
    required String secondFragmentLabel,
    required State newStart,
    required State newAccept,
    required State firstStart,
    required State firstAccept,
    required State secondStart,
    required State secondAccept,
    required Set<Transition> newTransitions,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Apply union (alternation)',
        explanation:
            'Creating union of two NFA fragments at position $position for pattern ($firstFragmentLabel|$secondFragmentLabel). '
            'Popping two fragments from the stack. Creating new start state ${newStart.label} with ε-transitions '
            'to both fragment starts (${firstStart.label} and ${secondStart.label}). '
            'Creating new accept state ${newAccept.label} with ε-transitions from both fragment accept states '
            '(${firstAccept.label} and ${secondAccept.label}). '
            'The NFA can now follow either path non-deterministically.',
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.union,
      regexPosition: position,
      combinesFragments: true,
      firstFragmentLabel: firstFragmentLabel,
      secondFragmentLabel: secondFragmentLabel,
      createdStates: {newStart, newAccept},
      createdTransitions: newTransitions,
      fragmentStartState: newStart,
      fragmentAcceptState: newAccept,
      stackSize: stackSize,
    );
  }

  /// Creates a step for the Kleene star operation
  factory RegexToNFAStep.kleeneStar({
    required String id,
    required int stepNumber,
    required int position,
    required String fragmentLabel,
    required State newStart,
    required State newAccept,
    required State oldStart,
    required State oldAccept,
    required Set<Transition> newTransitions,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Apply Kleene star (*)',
        explanation:
            'Applying Kleene star to fragment "$fragmentLabel" at position $position. '
            'Popping fragment from stack. Creating new start state ${newStart.label} and accept state ${newAccept.label}. '
            'Adding ε-transitions: (1) ${newStart.label} → ${oldStart.label} to enter the loop, '
            '(2) ${newStart.label} → ${newAccept.label} to skip the loop (zero iterations), '
            '(3) ${oldAccept.label} → ${oldStart.label} to repeat the loop, '
            '(4) ${oldAccept.label} → ${newAccept.label} to exit the loop. '
            'This allows zero or more repetitions of the pattern.',
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.kleeneStar,
      regexPosition: position,
      modifiedFragmentLabel: fragmentLabel,
      createdStates: {newStart, newAccept},
      createdTransitions: newTransitions,
      fragmentStartState: newStart,
      fragmentAcceptState: newAccept,
      stackSize: stackSize,
    );
  }

  /// Creates a step for the plus operation (one or more)
  factory RegexToNFAStep.plus({
    required String id,
    required int stepNumber,
    required int position,
    required String fragmentLabel,
    required State newStart,
    required State newAccept,
    required State oldStart,
    required State oldAccept,
    required Set<Transition> newTransitions,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Apply plus (+)',
        explanation:
            'Applying plus operator to fragment "$fragmentLabel" at position $position. '
            'Popping fragment from stack. Creating new start state ${newStart.label} and accept state ${newAccept.label}. '
            'Adding ε-transitions: (1) ${newStart.label} → ${oldStart.label} to enter (required first iteration), '
            '(2) ${oldAccept.label} → ${oldStart.label} to repeat the loop, '
            '(3) ${oldAccept.label} → ${newAccept.label} to exit the loop. '
            'This requires at least one iteration, unlike Kleene star.',
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.plus,
      regexPosition: position,
      modifiedFragmentLabel: fragmentLabel,
      createdStates: {newStart, newAccept},
      createdTransitions: newTransitions,
      fragmentStartState: newStart,
      fragmentAcceptState: newAccept,
      stackSize: stackSize,
    );
  }

  /// Creates a step for the optional operation (zero or one)
  factory RegexToNFAStep.optional({
    required String id,
    required int stepNumber,
    required int position,
    required String fragmentLabel,
    required State newStart,
    required State newAccept,
    required State oldStart,
    required State oldAccept,
    required Set<Transition> newTransitions,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Apply optional (?)',
        explanation:
            'Applying optional operator to fragment "$fragmentLabel" at position $position. '
            'Popping fragment from stack. Creating new start state ${newStart.label} and accept state ${newAccept.label}. '
            'Adding ε-transitions: (1) ${newStart.label} → ${oldStart.label} to match the pattern, '
            '(2) ${newStart.label} → ${newAccept.label} to skip the pattern (zero occurrences), '
            '(3) ${oldAccept.label} → ${newAccept.label} to complete after matching. '
            'This allows zero or one occurrence of the pattern.',
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.optional,
      regexPosition: position,
      modifiedFragmentLabel: fragmentLabel,
      createdStates: {newStart, newAccept},
      createdTransitions: newTransitions,
      fragmentStartState: newStart,
      fragmentAcceptState: newAccept,
      stackSize: stackSize,
    );
  }

  /// Creates a step for completing the NFA construction
  factory RegexToNFAStep.complete({
    required String id,
    required int stepNumber,
    required State finalStartState,
    required State finalAcceptState,
    required int totalStates,
    required int totalTransitions,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Complete NFA construction',
        explanation:
            'Thompson\'s construction complete. The final NFA has been built with '
            'start state ${finalStartState.label} and accept state ${finalAcceptState.label}. '
            'Total states: $totalStates. Total transitions: $totalTransitions. '
            'The NFA accepts exactly the language defined by the regular expression.',
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.complete,
      fragmentStartState: finalStartState,
      fragmentAcceptState: finalAcceptState,
      isFinalNFA: true,
      totalStates: totalStates,
      totalTransitions: totalTransitions,
      stackSize: 1,
    );
  }
}

/// Types of steps in regex to NFA conversion
enum RegexToNFAStepType {
  /// Starting the Thompson's construction algorithm
  start,

  /// Creating NFA for a basic symbol or epsilon
  basicSymbol,

  /// Concatenating two NFA fragments
  concatenation,

  /// Creating union (alternation) of two NFA fragments
  union,

  /// Applying Kleene star (zero or more) to an NFA fragment
  kleeneStar,

  /// Applying plus (one or more) to an NFA fragment
  plus,

  /// Applying optional (zero or one) to an NFA fragment
  optional,

  /// Completing the final NFA
  complete,
}

/// Extension methods for RegexToNFAStepType
extension RegexToNFAStepTypeExtension on RegexToNFAStepType {
  /// Gets a human-readable name for the step type
  String get displayName {
    switch (this) {
      case RegexToNFAStepType.start:
        return 'Start';
      case RegexToNFAStepType.basicSymbol:
        return 'Basic Symbol';
      case RegexToNFAStepType.concatenation:
        return 'Concatenation';
      case RegexToNFAStepType.union:
        return 'Union';
      case RegexToNFAStepType.kleeneStar:
        return 'Kleene Star';
      case RegexToNFAStepType.plus:
        return 'Plus';
      case RegexToNFAStepType.optional:
        return 'Optional';
      case RegexToNFAStepType.complete:
        return 'Complete';
    }
  }

  /// Gets a short description of what this step type does
  String get description {
    switch (this) {
      case RegexToNFAStepType.start:
        return 'Initialize Thompson\'s construction';
      case RegexToNFAStepType.basicSymbol:
        return 'Create NFA fragment for a single symbol';
      case RegexToNFAStepType.concatenation:
        return 'Concatenate two NFA fragments';
      case RegexToNFAStepType.union:
        return 'Create union of two NFA fragments';
      case RegexToNFAStepType.kleeneStar:
        return 'Apply Kleene star (zero or more repetitions)';
      case RegexToNFAStepType.plus:
        return 'Apply plus (one or more repetitions)';
      case RegexToNFAStepType.optional:
        return 'Apply optional (zero or one occurrence)';
      case RegexToNFAStepType.complete:
        return 'Finalize the NFA construction';
    }
  }
}
