part of '../pda_simulator_extended_test.dart';

void _runPdaModelTests() {
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
        () => result.steps.add(result.steps.first),
        throwsUnsupportedError,
      );
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
      final q0 = State(id: 'q0', label: 'q0', position: Vector2.zero());
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
      expect(() => stackAnalysis.stackSymbols.add('C'), throwsUnsupportedError);
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
      final emptyGroup = PDAMergeGroup(
        representative: q0,
        mergedStates: const {},
      );
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
      final q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));
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
      final q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));
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
        () => summary.removedTransitionIds.add('t1'),
        throwsUnsupportedError,
      );
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
      final q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));
      final group = PDAMergeGroup(representative: q0, mergedStates: {q1});
      expect(group.isMeaningful, true);
    });
  });

  // =========================================================================
  // PDASimulator.analyzePDA
  // =========================================================================
}
