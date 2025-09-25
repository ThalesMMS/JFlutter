import 'dart:collection';

import '../models/fsa_transition.dart';
import '../models/simulation_step.dart';
import '../models/state.dart';
import '../models/tm.dart';
import '../models/tm_analysis.dart';
import '../models/tm_runtime.dart';
import '../models/tm_transition.dart';
import '../result.dart';

/// Simulates Turing Machines (TM) with support for multiple tapes and
/// nondeterministic branching.
class TMSimulator {
  /// Simulates a TM with an input string exploring every nondeterministic
  /// branch up to the configured limits.
  static Result<TMSimulationResult> simulate(
    TM tm,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
    int maxBranches = 128,
    int maxStepsPerBranch = 256,
    int maxVisitedConfigurations = 2000,
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      final validationResult = _validateInput(tm, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      if (tm.states.isEmpty) {
        return Failure('Cannot simulate empty Turing machine');
      }

      if (tm.initialState == null) {
        return Failure('Turing machine must have an initial state');
      }

      final determinismConflicts = _computeDeterminismConflicts(tm);
      final result = _explore(
        tm,
        inputString,
        stepByStep: stepByStep,
        timeout: timeout,
        maxBranches: maxBranches,
        maxStepsPerBranch: maxStepsPerBranch,
        maxVisitedConfigurations: maxVisitedConfigurations,
        determinismConflicts: determinismConflicts,
      );

      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating Turing machine: $e');
    }
  }

  /// Validates the input TM and string before simulation.
  static Result<void> _validateInput(TM tm, String inputString) {
    if (tm.states.isEmpty) {
      return Failure('Turing machine must have at least one state');
    }

    if (tm.initialState == null) {
      return Failure('Turing machine must have an initial state');
    }

    if (!tm.states.contains(tm.initialState)) {
      return Failure('Initial state must be in the states set');
    }

    for (final acceptingState in tm.acceptingStates) {
      if (!tm.states.contains(acceptingState)) {
        return Failure('Accepting state must be in the states set');
      }
    }

    for (final symbol in inputString.split('')) {
      if (!tm.alphabet.contains(symbol)) {
        return Failure('Input string contains invalid symbol: $symbol');
      }
    }

    return Success(null);
  }

  static TMSimulationResult _explore(
    TM tm,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
    required int maxBranches,
    required int maxStepsPerBranch,
    required int maxVisitedConfigurations,
    required List<TMDeterminismConflict> determinismConflicts,
  }) {
    final startTime = DateTime.now();

    final initialTapes = List<TMTape>.generate(
      tm.tapeCount,
      (index) => index == 0
          ? TMTape.fromInput(input: inputString, blankSymbol: tm.blankSymbol)
          : TMTape.fromInput(input: '', blankSymbol: tm.blankSymbol),
      growable: false,
    );

    final initialSnapshot = TMConfigurationSnapshot(
      state: tm.initialState!,
      tapes: initialTapes,
      step: 0,
    );

    final queue = Queue<_ConfigurationPath>()
      ..add(_ConfigurationPath([initialSnapshot]));

    final branches = <TMBranchTrace>[];
    final visited = <String>{initialSnapshot.signature()};
    var exploredBranches = 0;
    var timedOut = false;
    var truncated = false;

    while (queue.isNotEmpty) {
      if (exploredBranches >= maxBranches) {
        truncated = true;
        break;
      }

      final path = queue.removeFirst();
      final current = path.current;

      if (_isAccepting(tm, current.state)) {
        branches.add(TMBranchTrace(
          configurations: path.configurations,
          reason: TMHaltReason.accepted,
          accepted: true,
        ));
        exploredBranches++;
        continue;
      }

      final elapsed = DateTime.now().difference(startTime);
      if (elapsed > timeout) {
        branches.add(TMBranchTrace(
          configurations: path.configurations,
          reason: TMHaltReason.timeout,
          accepted: false,
        ));
        timedOut = true;
        break;
      }

      final readVector = current.tapes.map((tape) => tape.read()).toList();
      final enabledTransitions = tm.tmTransitions
          .where((transition) =>
              transition.fromState == current.state &&
              transition.matchesReadVector(readVector))
          .toList();

      if (enabledTransitions.isEmpty) {
        branches.add(TMBranchTrace(
          configurations: path.configurations,
          reason: TMHaltReason.rejected,
          accepted: false,
        ));
        exploredBranches++;
        continue;
      }

      for (final transition in enabledTransitions) {
        final nextTapes = List<TMTape>.generate(tm.tapeCount, (index) {
          final action = transition.actionForTape(index);
          final afterWrite = current.tapes[index].write(action.writeSymbol);
          return afterWrite.move(action.direction);
        }, growable: false);

        final nextSnapshot = TMConfigurationSnapshot(
          state: transition.toState,
          tapes: nextTapes,
          step: current.step + 1,
          transition: transition,
        );

        final nextPath = path.advance(nextSnapshot);

        if (nextSnapshot.step > maxStepsPerBranch) {
          branches.add(TMBranchTrace(
            configurations: nextPath.configurations,
            reason: TMHaltReason.exceededLimit,
            accepted: false,
          ));
          exploredBranches++;
          truncated = true;
          continue;
        }

        if (visited.length >= maxVisitedConfigurations) {
          branches.add(TMBranchTrace(
            configurations: nextPath.configurations,
            reason: TMHaltReason.exceededLimit,
            accepted: false,
          ));
          exploredBranches++;
          truncated = true;
          continue;
        }

        final signature = nextSnapshot.signature();
        if (visited.add(signature)) {
          queue.add(nextPath);
        }
      }
    }

    if (branches.isEmpty) {
      branches.add(TMBranchTrace(
        configurations: [initialSnapshot],
        reason: TMHaltReason.rejected,
        accepted: false,
      ));
    }

    final accepted = branches.any((branch) => branch.accepted);
    final primaryBranch = _selectPrimaryBranch(branches);
    final steps =
        stepByStep && primaryBranch != null ? _buildSteps(primaryBranch) : <SimulationStep>[];

    String? errorMessage;
    if (!accepted) {
      if (timedOut) {
        errorMessage = 'Simulation timed out';
      } else if (branches.any((branch) =>
          branch.reason == TMHaltReason.exceededLimit ||
          branch.reason == TMHaltReason.timeout)) {
        errorMessage =
            'Simulation truncated before exploring all configurations';
      } else {
        errorMessage = 'Input not accepted';
      }
    }

    return TMSimulationResult(
      inputString: inputString,
      accepted: accepted,
      steps: steps,
      branches: branches,
      determinismConflicts: determinismConflicts,
      exploredBranches: branches.length,
      truncated: truncated,
      timedOut: timedOut,
      errorMessage: errorMessage,
      executionTime: Duration.zero,
    );
  }

  static bool _isAccepting(TM tm, State state) {
    return tm.acceptingStates.any((accepting) => accepting.id == state.id);
  }

  static TMBranchTrace? _selectPrimaryBranch(List<TMBranchTrace> branches) {
    if (branches.isEmpty) {
      return null;
    }
    for (final branch in branches) {
      if (branch.accepted) {
        return branch;
      }
    }
    return branches.first;
  }

  static List<SimulationStep> _buildSteps(TMBranchTrace branch) {
    if (branch.configurations.isEmpty) {
      return const [];
    }

    final steps = <SimulationStep>[];
    final initial = branch.configurations.first;
    final initialTape = _formatTapes(initial.tapes);
    steps.add(
      SimulationStep.initial(
        initialState: initial.state.id,
        inputString: '',
        initialTapeSymbol: initialTape,
      ),
    );

    for (var i = 1; i < branch.configurations.length; i++) {
      final snapshot = branch.configurations[i];
      final previous = branch.configurations[i - 1];
      final transition = snapshot.transition;
      final tapeContents = _formatTapes(snapshot.tapes);
      final usedTransition = transition != null
          ? transition.actions
              .map((action) =>
                  't${action.tape}:${action.readSymbol}/${action.writeSymbol},${action.direction.shortLabel}')
              .join(' | ')
          : null;

      steps.add(
        SimulationStep.tm(
          currentState: previous.state.id,
          remainingInput: '',
          tapeContents: tapeContents,
          usedTransition: usedTransition,
          stepNumber: i,
        ),
      );
    }

    final finalSnapshot = branch.configurations.last;
    steps.add(
      SimulationStep.finalStep(
        finalState: finalSnapshot.state.id,
        remainingInput: '',
        stackContents: '',
        tapeContents: _formatTapes(finalSnapshot.tapes),
        stepNumber: branch.configurations.length,
      ),
    );

    return steps;
  }

  static String _formatTapes(List<TMTape> tapes) {
    return tapes
        .asMap()
        .entries
        .map((entry) => 'T${entry.key}:${entry.value.render(radius: 6)}')
        .join(' || ');
  }

  /// Tests if a TM accepts a specific string.
  static Result<bool> accepts(TM tm, String inputString) {
    final simulation = simulate(tm, inputString);
    if (!simulation.isSuccess) {
      return Failure(simulation.error!);
    }
    return Success(simulation.data!.accepted);
  }

  /// Tests if a TM rejects a specific string.
  static Result<bool> rejects(TM tm, String inputString) {
    final result = accepts(tm, inputString);
    if (!result.isSuccess) {
      return Failure(result.error!);
    }
    return Success(!result.data!);
  }

  static Result<Set<String>> findAcceptedStrings(
    TM tm,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final acceptedStrings = <String>{};
      final alphabet = tm.alphabet.toList();

      for (var length = 0;
          length <= maxLength && acceptedStrings.length < maxResults;
          length++) {
        _generateStrings(
          tm,
          alphabet,
          '',
          length,
          acceptedStrings,
          maxResults,
        );
      }

      return Success(acceptedStrings);
    } catch (e) {
      return Failure('Error finding accepted strings: $e');
    }
  }

  static void _generateStrings(
    TM tm,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> acceptedStrings,
    int maxResults,
  ) {
    if (acceptedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final result = accepts(tm, currentString);
      if (result.isSuccess && result.data!) {
        acceptedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      _generateStrings(
        tm,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        acceptedStrings,
        maxResults,
      );
    }
  }

  static Result<Set<String>> findRejectedStrings(
    TM tm,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final rejectedStrings = <String>{};
      final alphabet = tm.alphabet.toList();

      for (var length = 0;
          length <= maxLength && rejectedStrings.length < maxResults;
          length++) {
        _generateRejectedStrings(
          tm,
          alphabet,
          '',
          length,
          rejectedStrings,
          maxResults,
        );
      }

      return Success(rejectedStrings);
    } catch (e) {
      return Failure('Error finding rejected strings: $e');
    }
  }

  static void _generateRejectedStrings(
    TM tm,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> rejectedStrings,
    int maxResults,
  ) {
    if (rejectedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final result = accepts(tm, currentString);
      if (result.isSuccess && !result.data!) {
        rejectedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      _generateRejectedStrings(
        tm,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        rejectedStrings,
        maxResults,
      );
    }
  }

  static Result<TMAnalysis> analyzeTM(
    TM tm, {
    int maxInputLength = 10,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      final validationResult = _validateInput(tm, '');
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      if (tm.states.isEmpty) {
        return Failure('Cannot analyze empty Turing machine');
      }

      if (tm.initialState == null) {
        return Failure('Turing machine must have an initial state');
      }

      final analysis = _analyzeTM(tm, maxInputLength, timeout);
      final finalResult = analysis.copyWith(executionTime: stopwatch.elapsed);
      return Success(finalResult);
    } catch (e) {
      return Failure('Error analyzing Turing machine: $e');
    }
  }

  static TMAnalysis _analyzeTM(
    TM tm,
    int maxInputLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    final stateAnalysis = _analyzeStates(tm);
    final transitionAnalysis = _analyzeTransitions(tm);
    final tapeAnalysis = _analyzeTapeOperations(tm);
    final reachabilityAnalysis = _analyzeReachability(tm);

    return TMAnalysis(
      stateAnalysis: stateAnalysis,
      transitionAnalysis: transitionAnalysis,
      tapeAnalysis: tapeAnalysis,
      reachabilityAnalysis: reachabilityAnalysis,
      executionTime: DateTime.now().difference(startTime),
    );
  }

  static TMStateAnalysis _analyzeStates(TM tm) {
    final totalStates = tm.states.length;
    final acceptingStates = tm.acceptingStates.length;
    final nonAcceptingStates = totalStates - acceptingStates;

    return TMStateAnalysis(
      totalStates: totalStates,
      acceptingStates: acceptingStates,
      nonAcceptingStates: nonAcceptingStates,
    );
  }

  static TMTransitionAnalysis _analyzeTransitions(TM tm) {
    final totalTransitions = tm.transitions.length;
    final tmTransitions = tm.transitions.whereType<TMTransition>().length;
    final fsaTransitions = tm.transitions.whereType<FSATransition>().length;

    return TMTransitionAnalysis(
      totalTransitions: totalTransitions,
      tmTransitions: tmTransitions,
      fsaTransitions: fsaTransitions,
    );
  }

  static TapeAnalysis _analyzeTapeOperations(TM tm) {
    final writeOperations = <String>{};
    final readOperations = <String>{};
    final moveDirections = <String>{};
    final tapeSymbols = <String>{};

    for (final transition in tm.tmTransitions) {
      for (final action in transition.actions) {
        writeOperations.add(action.writeSymbol);
        readOperations.add(action.readSymbol);
        moveDirections.add(action.direction.name);
        tapeSymbols.add(action.readSymbol);
        tapeSymbols.add(action.writeSymbol);
      }
    }

    return TapeAnalysis(
      writeOperations: writeOperations,
      readOperations: readOperations,
      moveDirections: moveDirections,
      tapeSymbols: tapeSymbols,
    );
  }

  static TMReachabilityAnalysis _analyzeReachability(TM tm) {
    final reachableStates = <State>{};
    final unreachableStates = <State>{};

    if (tm.initialState != null) {
      _findReachableStates(tm, tm.initialState!, reachableStates);
    }

    for (final state in tm.states) {
      if (!reachableStates.contains(state)) {
        unreachableStates.add(state);
      }
    }

    return TMReachabilityAnalysis(
      reachableStates: reachableStates,
      unreachableStates: unreachableStates,
    );
  }

  static void _findReachableStates(
    TM tm,
    State currentState,
    Set<State> reachableStates,
  ) {
    if (reachableStates.contains(currentState)) {
      return;
    }

    reachableStates.add(currentState);

    for (final transition in tm.transitions) {
      if (transition.fromState == currentState) {
        _findReachableStates(tm, transition.toState, reachableStates);
      }
    }
  }

  static List<TMDeterminismConflict> _computeDeterminismConflicts(TM tm) {
    final conflicts = <TMDeterminismConflict>[];
    final grouped = <String, List<TMTransition>>{};
    final readVectors = <String, List<String>>{};

    for (final transition in tm.tmTransitions) {
      final vector = <String>[];
      for (var tape = 0; tape < tm.tapeCount; tape++) {
        final action = transition.actionForTape(tape);
        vector.add(action.readSymbol);
      }
      final key = '${transition.fromState.id}::${vector.join('\u0001')}';
      grouped.putIfAbsent(key, () => []).add(transition);
      readVectors[key] = vector;
    }

    grouped.forEach((key, transitions) {
      if (transitions.length > 1) {
        final parts = key.split('::');
        final stateId = parts.first;
        final state = tm.states.firstWhere((s) => s.id == stateId);
        conflicts.add(
          TMDeterminismConflict(
            state: state,
            readVector: readVectors[key] ?? const [],
            transitions: transitions,
          ),
        );
      }
    });

    return conflicts;
  }
}

class _ConfigurationPath {
  _ConfigurationPath(this.configurations);

  final List<TMConfigurationSnapshot> configurations;

  TMConfigurationSnapshot get current => configurations.last;

  _ConfigurationPath advance(TMConfigurationSnapshot snapshot) {
    final next = List<TMConfigurationSnapshot>.from(configurations)..add(snapshot);
    return _ConfigurationPath(next);
  }
}

/// Result of simulating a TM including all explored branches and diagnostics.
class TMSimulationResult {
  const TMSimulationResult({
    required this.inputString,
    required this.accepted,
    required this.steps,
    required this.branches,
    required this.determinismConflicts,
    required this.executionTime,
    this.errorMessage,
    this.timedOut = false,
    this.truncated = false,
    this.exploredBranches = 0,
  });

  final String inputString;
  final bool accepted;
  final List<SimulationStep> steps;
  final List<TMBranchTrace> branches;
  final List<TMDeterminismConflict> determinismConflicts;
  final Duration executionTime;
  final String? errorMessage;
  final bool timedOut;
  final bool truncated;
  final int exploredBranches;

  TMBranchTrace? get primaryBranch {
    for (final branch in branches) {
      if (branch.accepted) {
        return branch;
      }
    }
    if (branches.isEmpty) {
      return null;
    }
    return branches.first;
  }

  List<TMBranchTrace> get acceptingBranches =>
      branches.where((branch) => branch.accepted).toList(growable: false);

  bool get hasDeterminismConflicts => determinismConflicts.isNotEmpty;

  TMSimulationResult copyWith({
    String? inputString,
    bool? accepted,
    List<SimulationStep>? steps,
    List<TMBranchTrace>? branches,
    List<TMDeterminismConflict>? determinismConflicts,
    Duration? executionTime,
    String? errorMessage,
    bool? timedOut,
    bool? truncated,
    int? exploredBranches,
  }) {
    return TMSimulationResult(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      steps: steps ?? this.steps,
      branches: branches ?? this.branches,
      determinismConflicts: determinismConflicts ?? this.determinismConflicts,
      executionTime: executionTime ?? this.executionTime,
      errorMessage: errorMessage ?? this.errorMessage,
      timedOut: timedOut ?? this.timedOut,
      truncated: truncated ?? this.truncated,
      exploredBranches: exploredBranches ?? this.exploredBranches,
    );
  }
}
