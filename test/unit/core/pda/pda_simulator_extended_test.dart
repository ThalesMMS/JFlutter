//
//  pda_simulator_extended_test.dart
//  JFlutter
//
//  Testes que cobrem as funcionalidades adicionais do simulador de autômatos de
//  pilha introduzidas pela refatoração em arquivos part: analisePDA, geração de
//  cadeias aceitas e rejeitadas, simplificação, e os modelos de resultado
//  PDASimulationResult, PDAAnalysis e PDASimplificationSummary.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/pda_simulator.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

/// Simple PDA accepting {a^n b^n | n >= 1} by final state
PDA _pdaAnBn() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
  );
  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(200, 0),
    isAccepting: true,
  );

  final transitions = <PDATransition>{
    // q0: read 'a', push A
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q0,
      inputSymbol: 'a',
      popSymbol: '',
      pushSymbol: 'A',
      label: 'a,ε/A',
    ),
    // q0 -> q1: epsilon, no stack change (start consuming b's)
    PDATransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: '',
      label: 'ε,ε/ε',
    ),
    // q1: read 'b', pop A
    PDATransition(
      id: 't2',
      fromState: q1,
      toState: q1,
      inputSymbol: 'b',
      popSymbol: 'A',
      pushSymbol: '',
      label: 'b,A/ε',
    ),
    // q1 -> q2: epsilon transition to accepting state
    PDATransition(
      id: 't3',
      fromState: q1,
      toState: q2,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: '',
      label: 'ε,ε/ε',
    ),
  };

  return PDA(
    id: 'pda_anbn',
    name: 'a^n b^n',
    states: {q0, q1, q2},
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    stackAlphabet: {'Z', 'A'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

/// PDA accepting only 'a' by final state (simple, single-symbol)
PDA _pdaAcceptsA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );

  final transitions = <PDATransition>{
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q0,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: 'Z',
      label: 'ε,ε/Z',
    ),
    PDATransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'Z',
      label: 'a,Z/Z',
    ),
  };

  return PDA(
    id: 'pda_a',
    name: 'Accept a',
    states: {q0, q1},
    transitions: transitions,
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    stackAlphabet: {'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

/// PDA with an unreachable state
PDA _pdaWithUnreachableState() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final qUnreachable = State(
    id: 'qU',
    label: 'qU',
    position: Vector2(200, 0),
  );

  final transitions = <PDATransition>{
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q1,
      inputSymbol: 'a',
      popSymbol: '',
      pushSymbol: '',
      label: 'a,ε/ε',
    ),
    // qUnreachable -> q1 (not reachable from q0)
    PDATransition(
      id: 't1',
      fromState: qUnreachable,
      toState: q1,
      inputSymbol: 'b',
      popSymbol: '',
      pushSymbol: '',
      label: 'b,ε/ε',
    ),
  };

  return PDA(
    id: 'pda_unreachable',
    name: 'PDA with unreachable state',
    states: {q0, q1, qUnreachable},
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    stackAlphabet: {'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // PDASimulationResult model tests
  // =========================================================================
  group('PDASimulationResult - factory constructors', () {
    test('success factory sets accepted=true and no errorMessage', () {
      final result = PDASimulationResult.success(
        inputString: 'ab',
        steps: const [],
        executionTime: Duration.zero,
      );
      expect(result.accepted, true);
      expect(result.inputString, 'ab');
      expect(result.errorMessage, isNull);
      expect(result.steps, isEmpty);
    });

    test('failure factory sets accepted=false and errorMessage', () {
      const msg = 'No transition found';
      final result = PDASimulationResult.failure(
        inputString: 'xy',
        steps: const [],
        errorMessage: msg,
        executionTime: Duration.zero,
      );
      expect(result.accepted, false);
      expect(result.inputString, 'xy');
      expect(result.errorMessage, msg);
    });

    test('timeout factory sets accepted=false with timeout message', () {
      final result = PDASimulationResult.timeout(
        inputString: 'abc',
        steps: const [],
        executionTime: const Duration(seconds: 5),
      );
      expect(result.accepted, false);
      expect(result.errorMessage, contains('timed out'));
    });

    test('infiniteLoop factory sets accepted=false with loop message', () {
      final result = PDASimulationResult.infiniteLoop(
        inputString: 'abc',
        steps: const [],
        executionTime: const Duration(seconds: 1),
      );
      expect(result.accepted, false);
      expect(result.errorMessage, contains('loop'));
    });

    test('copyWith updates specified fields', () {
      final original = PDASimulationResult.success(
        inputString: 'a',
        steps: const [],
        executionTime: Duration.zero,
      );
      final updated = original.copyWith(
        inputString: 'b',
        accepted: false,
        errorMessage: 'new error',
        executionTime: const Duration(milliseconds: 100),
      );
      expect(updated.inputString, 'b');
      expect(updated.accepted, false);
      expect(updated.errorMessage, 'new error');
      expect(updated.executionTime, const Duration(milliseconds: 100));
    });

    test('copyWith without arguments preserves original values', () {
      final original = PDASimulationResult.failure(
        inputString: 'test',
        steps: const [],
        errorMessage: 'err',
        executionTime: const Duration(milliseconds: 42),
      );
      final copy = original.copyWith();
      expect(copy.inputString, original.inputString);
      expect(copy.accepted, original.accepted);
      expect(copy.errorMessage, original.errorMessage);
      expect(copy.executionTime, original.executionTime);
    });

    test('stores steps as an unmodifiable copy', () {
      final steps = <SimulationStep>[
        SimulationStep.pda(
          currentState: 'q0',
          remainingInput: 'a',
          stackContents: 'Z',
          stepNumber: 0,
        ),
      ];
      final result = PDASimulationResult.success(
        inputString: 'a',
        steps: steps,
        executionTime: Duration.zero,
      );

      steps.clear();

      expect(result.steps, hasLength(1));
      expect(
          () => result.steps.add(result.steps.first), throwsUnsupportedError);
    });
  });

  // =========================================================================
  // PDAAnalysis model tests
  // =========================================================================
  group('PDAAnalysis - copyWith', () {
    test('copyWith replaces specified sub-analyses', () {
      const originalStateAnalysis = PDAStateAnalysis(
        totalStates: 2,
        acceptingStates: 1,
        nonAcceptingStates: 1,
      );
      const originalTransitionAnalysis = PDATransitionAnalysis(
        totalTransitions: 1,
        pdaTransitions: 1,
        fsaTransitions: 0,
      );
      final originalStackAnalysis = StackAnalysis(
        pushOperations: {},
        popOperations: {},
        stackSymbols: {},
      );
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final originalReachability = PDAReachabilityAnalysis(
        reachableStates: {q0},
        unreachableStates: const {},
      );
      final analysis = PDAAnalysis(
        stateAnalysis: originalStateAnalysis,
        transitionAnalysis: originalTransitionAnalysis,
        stackAnalysis: originalStackAnalysis,
        reachabilityAnalysis: originalReachability,
        executionTime: Duration.zero,
      );

      const newStateAnalysis = PDAStateAnalysis(
        totalStates: 5,
        acceptingStates: 2,
        nonAcceptingStates: 3,
      );
      final updated = analysis.copyWith(stateAnalysis: newStateAnalysis);

      expect(updated.stateAnalysis.totalStates, 5);
      expect(updated.transitionAnalysis.totalTransitions, 1);
    });

    test('copyWith without arguments preserves all fields', () {
      const stateAnalysis = PDAStateAnalysis(
        totalStates: 3,
        acceptingStates: 1,
        nonAcceptingStates: 2,
      );
      const transitionAnalysis = PDATransitionAnalysis(
        totalTransitions: 2,
        pdaTransitions: 2,
        fsaTransitions: 0,
      );
      final stackAnalysis = StackAnalysis(
        pushOperations: {'A'},
        popOperations: {'A'},
        stackSymbols: {'A'},
      );
      final reachability = PDAReachabilityAnalysis(
        reachableStates: const {},
        unreachableStates: const {},
      );
      final analysis = PDAAnalysis(
        stateAnalysis: stateAnalysis,
        transitionAnalysis: transitionAnalysis,
        stackAnalysis: stackAnalysis,
        reachabilityAnalysis: reachability,
        executionTime: const Duration(milliseconds: 5),
      );

      final copy = analysis.copyWith();
      expect(copy.stateAnalysis.totalStates, 3);
      expect(copy.transitionAnalysis.pdaTransitions, 2);
      expect(copy.executionTime, const Duration(milliseconds: 5));
    });

    test('stack and reachability analyses expose unmodifiable sets', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
      );
      final pushOperations = {'A'};
      final reachables = {q0};
      final stackAnalysis = StackAnalysis(
        pushOperations: pushOperations,
        popOperations: const {'B'},
        stackSymbols: const {'A', 'B'},
      );
      final reachability = PDAReachabilityAnalysis(
        reachableStates: reachables,
        unreachableStates: const {},
      );

      pushOperations.add('C');
      reachables.clear();

      expect(stackAnalysis.pushOperations, {'A'});
      expect(reachability.reachableStates, {q0});
      expect(
        () => stackAnalysis.stackSymbols.add('C'),
        throwsUnsupportedError,
      );
      expect(
        () => reachability.reachableStates.clear(),
        throwsUnsupportedError,
      );
    });
  });

  // =========================================================================
  // PDASimplificationSummary and PDAMergeGroup
  // =========================================================================
  group('PDASimplificationSummary - hasMerges', () {
    test('hasMerges is false when no merge groups', () {
      final pda = _pdaAcceptsA();
      final summary = PDASimplificationSummary(
        minimizedPda: pda,
        removedStates: const {},
        unreachableStates: const {},
        nonProductiveStates: const {},
        removedTransitionIds: const {},
        mergeGroups: const [],
        changed: false,
        warnings: const [],
      );
      expect(summary.hasMerges, false);
    });

    test('hasMerges is false when merge groups have empty mergedStates', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final pda = _pdaAcceptsA();
      final emptyGroup =
          PDAMergeGroup(representative: q0, mergedStates: const {});
      final summary = PDASimplificationSummary(
        minimizedPda: pda,
        removedStates: const {},
        unreachableStates: const {},
        nonProductiveStates: const {},
        removedTransitionIds: const {},
        mergeGroups: [emptyGroup],
        changed: false,
        warnings: const [],
      );
      expect(summary.hasMerges, false);
    });

    test('hasMerges is true when at least one non-empty merge group', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
      );
      final pda = _pdaAcceptsA();
      final mergeGroup = PDAMergeGroup(representative: q0, mergedStates: {q1});
      final summary = PDASimplificationSummary(
        minimizedPda: pda,
        removedStates: {q1},
        unreachableStates: const {},
        nonProductiveStates: const {},
        removedTransitionIds: const {},
        mergeGroups: [mergeGroup],
        changed: true,
        warnings: const [],
      );
      expect(summary.hasMerges, true);
    });

    test('stores collection fields as unmodifiable copies', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
      );
      final pda = _pdaAcceptsA();
      final removedStates = {q1};
      final mergeGroups = [
        PDAMergeGroup(representative: q0, mergedStates: {q1}),
      ];
      final warnings = ['warning'];
      final summary = PDASimplificationSummary(
        minimizedPda: pda,
        removedStates: removedStates,
        unreachableStates: const {},
        nonProductiveStates: const {},
        removedTransitionIds: const {'t0'},
        mergeGroups: mergeGroups,
        changed: true,
        warnings: warnings,
      );

      removedStates.clear();
      mergeGroups.clear();
      warnings.clear();

      expect(summary.removedStates, {q1});
      expect(summary.mergeGroups, hasLength(1));
      expect(summary.warnings, ['warning']);
      expect(
          () => summary.removedTransitionIds.add('t1'), throwsUnsupportedError);
      expect(() => summary.mergeGroups.clear(), throwsUnsupportedError);
      expect(
        () => summary.mergeGroups.first.mergedStates.add(q0),
        throwsUnsupportedError,
      );
    });
  });

  group('PDAMergeGroup - isMeaningful', () {
    test('isMeaningful is false when mergedStates is empty', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final group = PDAMergeGroup(representative: q0, mergedStates: const {});
      expect(group.isMeaningful, false);
    });

    test('isMeaningful is true when mergedStates has elements', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
      );
      final group = PDAMergeGroup(representative: q0, mergedStates: {q1});
      expect(group.isMeaningful, true);
    });
  });

  // =========================================================================
  // PDASimulator.analyzePDA
  // =========================================================================
  group('PDASimulator.analyzePDA', () {
    test('returns success for valid PDA', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
    });

    test('reports correct state counts', () {
      final pda =
          _pdaAcceptsA(); // 2 states: q0 (non-accepting), q1 (accepting)
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      expect(result.data!.stateAnalysis.totalStates, 2);
      expect(result.data!.stateAnalysis.acceptingStates, 1);
      expect(result.data!.stateAnalysis.nonAcceptingStates, 1);
    });

    test('reports correct transition counts', () {
      final pda = _pdaAcceptsA(); // 2 PDA transitions
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      expect(result.data!.transitionAnalysis.totalTransitions, 2);
      expect(result.data!.transitionAnalysis.pdaTransitions, 2);
      expect(result.data!.transitionAnalysis.fsaTransitions, 0);
    });

    test('reports push operations from transitions', () {
      final pda = _pdaAcceptsA(); // pushes 'Z'
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      expect(result.data!.stackAnalysis.pushOperations, contains('Z'));
    });

    test('reports compound stack operations as full symbols', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
        isAccepting: true,
      );
      final pda = PDA(
        id: 'compound_stack_symbols',
        name: 'Compound Stack Symbols',
        states: {q0, q1},
        transitions: {
          PDATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            inputSymbol: '',
            popSymbol: 'BY',
            pushSymbol: 'AZ',
            label: 'ε,BY/AZ',
          ),
        },
        alphabet: const {},
        stackAlphabet: const {'A', 'B', 'Y', 'Z'},
        initialState: q0,
        acceptingStates: {q1},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      final result = PDASimulator.analyzePDA(pda);

      expect(result.isSuccess, true);
      expect(
          result.data!.stackAnalysis.stackSymbols, containsAll({'AZ', 'BY'}));
      expect(result.data!.stackAnalysis.stackSymbols, isNot(contains('A')));
      expect(result.data!.stackAnalysis.stackSymbols, isNot(contains('B')));
    });

    test('reports reachable states from initial state', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      final reachable = result.data!.reachabilityAnalysis.reachableStates
          .map((s) => s.id)
          .toSet();
      expect(reachable, contains('q0'));
      expect(reachable, contains('q1'));
    });

    test('identifies unreachable states', () {
      final pda = _pdaWithUnreachableState();
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      final unreachable = result.data!.reachabilityAnalysis.unreachableStates
          .map((s) => s.id)
          .toSet();
      expect(unreachable, contains('qU'));
    });

    test('includes execution time in result', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      expect(result.data!.executionTime, isNotNull);
    });

    test('returns error for PDA with no states', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final emptyPda = PDA(
        id: 'empty',
        name: 'Empty PDA',
        states: const {},
        transitions: const {},
        alphabet: const {},
        initialState: q0,
        acceptingStates: const {},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final result = PDASimulator.analyzePDA(emptyPda);
      expect(result.isSuccess, false);
    });

    test('analyzes a^n b^n PDA correctly', () {
      final pda = _pdaAnBn(); // 3 states, 4 transitions
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      expect(result.data!.stateAnalysis.totalStates, 3);
      expect(result.data!.stateAnalysis.acceptingStates, 1);
      expect(result.data!.transitionAnalysis.totalTransitions, 4);
    });
  });

  // =========================================================================
  // PDASimulator.findAcceptedStrings
  // =========================================================================
  group('PDASimulator.findAcceptedStrings', () {
    test('finds accepted strings for simple PDA', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findAcceptedStrings(pda, 2);
      expect(result.isSuccess, true);
      expect(result.data, contains('a'));
    });

    test('does not include rejected strings', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findAcceptedStrings(pda, 2);
      expect(result.isSuccess, true);
      // 'b' is not in alphabet and 'aa' is not accepted by this PDA
      expect(result.data, isNot(contains('b')));
    });

    test('respects maxResults limit', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findAcceptedStrings(pda, 3, maxResults: 1);
      expect(result.isSuccess, true);
      expect(result.data!.length, lessThanOrEqualTo(1));
    });

    test('returns empty set for maxLength 0 if empty string not accepted', () {
      final pda = _pdaAcceptsA(); // only 'a' is accepted
      final result = PDASimulator.findAcceptedStrings(pda, 0);
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('returns results as a Set (no duplicates)', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findAcceptedStrings(pda, 2);
      expect(result.isSuccess, true);
      final list = result.data!.toList();
      final unique = list.toSet();
      expect(list.length, unique.length);
    });

    test('propagates acceptance failures instead of skipping candidates', () {
      final pda = PDA(
        id: 'invalid',
        name: 'Invalid PDA',
        states: const {},
        transitions: const {},
        alphabet: const {},
        initialState: null,
        acceptingStates: const {},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
        stackAlphabet: const {'Z'},
      );

      final result = PDASimulator.findAcceptedStrings(pda, 0);

      expect(result.isSuccess, false);
      expect(result.error, contains('PDA acceptance failed'));
      expect(result.error, contains('PDA must have at least one state'));
    });
  });

  // =========================================================================
  // PDASimulator.findRejectedStrings
  // =========================================================================
  group('PDASimulator.findRejectedStrings', () {
    test('finds rejected strings for simple PDA', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findRejectedStrings(pda, 2);
      expect(result.isSuccess, true);
      // 'aa' should be rejected since PDA only accepts single 'a'
      expect(result.data, isNotEmpty);
    });

    test('does not include accepted strings', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findRejectedStrings(pda, 1);
      expect(result.isSuccess, true);
      expect(result.data, isNot(contains('a')));
    });

    test('respects maxResults limit', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findRejectedStrings(pda, 3, maxResults: 2);
      expect(result.isSuccess, true);
      expect(result.data!.length, lessThanOrEqualTo(2));
    });

    test('returns results as a Set (no duplicates)', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findRejectedStrings(pda, 2);
      expect(result.isSuccess, true);
      final list = result.data!.toList();
      final unique = list.toSet();
      expect(list.length, unique.length);
    });

    test('propagates acceptance failures instead of skipping candidates', () {
      final pda = PDA(
        id: 'invalid',
        name: 'Invalid PDA',
        states: const {},
        transitions: const {},
        alphabet: const {},
        initialState: null,
        acceptingStates: const {},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
        stackAlphabet: const {'Z'},
      );

      final result = PDASimulator.findRejectedStrings(pda, 0);

      expect(result.isSuccess, false);
      expect(result.error, contains('PDA acceptance failed'));
      expect(result.error, contains('PDA must have at least one state'));
    });
  });

  // =========================================================================
  // PDASimulator.simplify
  // =========================================================================
  group('PDASimulator.simplify', () {
    test('returns success for a valid, already-minimal PDA', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
    });

    test('simplified PDA has at least the initial state', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
      expect(result.data!.minimizedPda.states, isNotEmpty);
      expect(result.data!.minimizedPda.initialState, isNotNull);
    });

    test('simplified PDA preserves at least one accepting state', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
      expect(result.data!.minimizedPda.acceptingStates, isNotEmpty);
    });

    test('removes unreachable states from PDA', () {
      final pda = _pdaWithUnreachableState();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
      final stateIds =
          result.data!.minimizedPda.states.map((s) => s.id).toSet();
      expect(stateIds, isNot(contains('qU')));
    });

    test('reports removed states in summary', () {
      final pda = _pdaWithUnreachableState();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
      final removedIds = result.data!.removedStates.map((s) => s.id).toSet();
      expect(removedIds, contains('qU'));
    });

    test('changed flag is true when states were removed', () {
      final pda = _pdaWithUnreachableState();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
      expect(result.data!.changed, true);
    });

    test('treats FSA transitions as productive reachability edges', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
        isAccepting: true,
      );
      final transition = FSATransition(
        id: 'f0',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
        label: 'a',
      );
      final pda = PDA(
        id: 'mixed',
        name: 'Mixed PDA',
        states: {q0, q1},
        transitions: <Transition>{transition},
        alphabet: const {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
        stackAlphabet: const {'Z'},
      );

      final result = PDASimulator.simplify(pda);

      expect(result.isSuccess, true);
      expect(result.data!.minimizedPda.initialState?.id, 'q0');
      expect(result.data!.minimizedPda.transitions, hasLength(1));
      expect(
          result.data!.minimizedPda.transitions.single, isA<FSATransition>());
    });

    test('returns failure for empty PDA', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final emptyPda = PDA(
        id: 'empty',
        name: 'Empty',
        states: const {},
        transitions: const {},
        alphabet: const {},
        initialState: q0,
        acceptingStates: const {},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final result = PDASimulator.simplify(emptyPda);
      expect(result.isSuccess, false);
    });

    test('returns failure when PDA has no accepting states', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final noAcceptingPda = PDA(
        id: 'no_accept',
        name: 'No accepting states',
        states: {q0},
        transitions: const {},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: const {},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final result = PDASimulator.simplify(noAcceptingPda);
      expect(result.isSuccess, false);
    });

    test('returns failure when no initial state is defined', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isAccepting: true,
      );
      final noInitPda = PDA(
        id: 'no_init',
        name: 'No initial state',
        states: {q0},
        transitions: const {},
        alphabet: {'a'},
        acceptingStates: {q0},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final result = PDASimulator.simplify(noInitPda);
      expect(result.isSuccess, false);
    });
  });

  // =========================================================================
  // PDASimulator.accepts and rejects
  // =========================================================================
  group('PDASimulator.accepts and rejects', () {
    test('accepts returns true for accepted string', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.accepts(pda, 'a');
      expect(result.isSuccess, true);
      expect(result.data, true);
    });

    test('accepts returns false for rejected string', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.accepts(pda, 'aa');
      expect(result.isSuccess, true);
      expect(result.data, false);
    });

    test('rejects returns true for rejected string', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.rejects(pda, 'aa');
      expect(result.isSuccess, true);
      expect(result.data, true);
    });

    test('rejects returns false for accepted string', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.rejects(pda, 'a');
      expect(result.isSuccess, true);
      expect(result.data, false);
    });

    test('non-step simulation avoids storing full branch history', () {
      final pda = _pdaAnBn();
      final result = PDASimulator.simulateNPDA(
        pda,
        'aabb',
        stepByStep: false,
      );

      expect(result.isSuccess, true);
      expect(result.data!.accepted, true);
      expect(result.data!.steps, hasLength(1));
      expect(result.data!.steps.single.currentState, 'q2');
      expect(result.data!.steps.single.usedTransition, isNull);
    });

    test('deduplicates epsilon cycles during search', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final loop = PDATransition(
        id: 'loop',
        fromState: q0,
        toState: q0,
        inputSymbol: '',
        popSymbol: '',
        pushSymbol: '',
        label: 'ε,ε/ε',
      );
      final pda = PDA(
        id: 'cycle',
        name: 'Cycle PDA',
        states: {q0},
        transitions: <Transition>{loop},
        alphabet: const {},
        initialState: q0,
        acceptingStates: const {},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
        stackAlphabet: const {'Z'},
      );

      final result = PDASimulator.simulateNPDA(
        pda,
        '',
        maxConfigurations: 5,
        maxDepth: 50,
      );

      expect(result.isSuccess, true);
      expect(result.data!.accepted, false);
      expect(result.data!.errorMessage, contains('Rejected'));
    });
  });

  // =========================================================================
  // Validation path (pda_simulator_validation.dart)
  // =========================================================================
  group('PDASimulator validation via simulateNPDA', () {
    test('returns failure for PDA with empty states set', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final pda = PDA(
        id: 'bad',
        name: 'Bad PDA',
        states: const {},
        transitions: const {},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: const {},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final result = PDASimulator.simulateNPDA(pda, 'a');
      expect(result.isSuccess, false);
      expect(result.error, contains('state'));
    });

    test('returns failure when initial state not in states set', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final qOther = State(
        id: 'qOther',
        label: 'qOther',
        position: Vector2(100, 0),
        isAccepting: true,
      );
      // q0 is initial but only qOther is in states set
      final pda = PDA(
        id: 'bad2',
        name: 'Bad PDA 2',
        states: {qOther},
        transitions: const {},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {qOther},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final result = PDASimulator.simulateNPDA(pda, 'a');
      expect(result.isSuccess, false);
      expect(result.error, contains('Initial state'));
    });
  });

  // =========================================================================
  // Regression: empty string handling
  // =========================================================================
  group('PDASimulator - edge cases', () {
    test('simulateNPDA handles empty string input gracefully', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.simulateNPDA(pda, '');
      expect(result.isSuccess, true);
      // Empty string is rejected since PDA needs 'a'
      expect(result.data!.accepted, false);
    });

    test('findAcceptedStrings with maxLength=0 for epsilon-accepting PDA', () {
      // Build PDA that accepts empty string
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
        isAccepting: true,
      );
      final epsilonPda = PDA(
        id: 'eps',
        name: 'Epsilon PDA',
        states: {q0},
        transitions: const {},
        alphabet: const {},
        initialState: q0,
        acceptingStates: {q0},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final result = PDASimulator.findAcceptedStrings(epsilonPda, 0);
      expect(result.isSuccess, true);
      expect(result.data, contains(''));
    });
  });
}
