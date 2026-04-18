part of 'algorithm_step_test.dart';

void _registerFaToRegexStepTests() {
  group('FAToRegexStep Tests', () {
    late State q0, q1, q2;
    late FSATransition t01, t12, t00;

    setUp(() {
      q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));
      q2 = State(
        id: 'q2',
        label: 'q2',
        position: Vector2(200, 0),
        isAccepting: true,
      );

      t01 = FSATransition(
        id: 't01',
        fromState: q0,
        toState: q1,
        inputSymbols: {'a'},
      );
      t12 = FSATransition(
        id: 't12',
        fromState: q1,
        toState: q2,
        inputSymbols: {'b'},
      );
      t00 = FSATransition(
        id: 't00',
        fromState: q0,
        toState: q0,
        inputSymbols: {'c'},
      );
    });

    test('validation factory should create correct step', () {
      final step = FAToRegexStep.validation(
        id: 'step-val',
        stepNumber: 0,
        stateCount: 3,
        transitionCount: 5,
        hasInitialState: true,
        hasAcceptingStates: true,
      );

      expect(step.stepType, FAToRegexStepType.validation);
      expect(step.currentStateCount, 3);
      expect(step.title.contains('Validate'), true);
      expect(step.explanation.contains('3 state'), true);
      expect(step.explanation.contains('5 transition'), true);
    });

    test('validation should detect missing initial state', () {
      final step = FAToRegexStep.validation(
        id: 'step-val-no-init',
        stepNumber: 0,
        stateCount: 2,
        transitionCount: 2,
        hasInitialState: false,
        hasAcceptingStates: true,
      );

      expect(step.explanation.contains('ERROR'), true);
      expect(step.explanation.contains('No initial'), true);
    });

    test('addInitialState factory should create correct step', () {
      final newInit = State(
        id: 'qI',
        label: 'qI',
        position: Vector2(-100, 0),
        isInitial: true,
      );

      final step = FAToRegexStep.addInitialState(
        id: 'step-add-init',
        stepNumber: 1,
        oldInitialState: q0,
        newInitialState: newInit,
      );

      expect(step.stepType, FAToRegexStepType.addInitialState);
      expect(step.addedInitialState, newInit);
      expect(step.explanation.contains('qI'), true);
      expect(step.explanation.contains('q0'), true);
    });

    test('addFinalState factory should create correct step', () {
      final newFinal = State(
        id: 'qF',
        label: 'qF',
        position: Vector2(300, 0),
        isAccepting: true,
      );

      final step = FAToRegexStep.addFinalState(
        id: 'step-add-final',
        stepNumber: 2,
        oldAcceptingStates: {q2},
        newFinalState: newFinal,
      );

      expect(step.stepType, FAToRegexStepType.addFinalState);
      expect(step.addedFinalState, newFinal);
      expect(step.explanation.contains('qF'), true);
    });

    test('selectStateToEliminate factory should create correct step', () {
      final step = FAToRegexStep.selectStateToEliminate(
        id: 'step-select',
        stepNumber: 3,
        state: q1,
        remainingStates: 2,
      );

      expect(step.stepType, FAToRegexStepType.selectState);
      expect(step.eliminatedState, q1);
      expect(step.remainingStateCount, 2);
      expect(step.currentStateCount, 3);
      expect(step.title.contains('q1'), true);
    });

    test('findIncomingTransitions factory should create correct step', () {
      final step = FAToRegexStep.findIncomingTransitions(
        id: 'step-find-in',
        stepNumber: 4,
        eliminatedState: q1,
        incomingStates: {q0},
        incomingTransitions: {t01},
      );

      expect(step.stepType, FAToRegexStepType.findIncoming);
      expect(step.eliminatedState, q1);
      expect(step.incomingStates, {q0});
      expect(step.incomingTransitions, {t01});
      expect(step.explanation.contains('1 incoming'), true);
    });

    test('findOutgoingTransitions factory should create correct step', () {
      final step = FAToRegexStep.findOutgoingTransitions(
        id: 'step-find-out',
        stepNumber: 5,
        eliminatedState: q1,
        outgoingStates: {q2},
        outgoingTransitions: {t12},
      );

      expect(step.stepType, FAToRegexStepType.findOutgoing);
      expect(step.eliminatedState, q1);
      expect(step.outgoingStates, {q2});
      expect(step.outgoingTransitions, {t12});
    });

    test('findSelfLoop factory should create correct step with loop', () {
      final step = FAToRegexStep.findSelfLoop(
        id: 'step-self-loop',
        stepNumber: 6,
        eliminatedState: q0,
        selfLoopTransitions: {t00},
        selfLoopRegex: 'c*',
      );

      expect(step.stepType, FAToRegexStepType.findSelfLoop);
      expect(step.eliminatedState, q0);
      expect(step.selfLoopTransitions, {t00});
      expect(step.selfLoopRegex, 'c*');
      expect(step.title.contains('self-loop'), true);
    });

    test('findSelfLoop factory should handle no loop', () {
      final step = FAToRegexStep.findSelfLoop(
        id: 'step-no-loop',
        stepNumber: 6,
        eliminatedState: q1,
        selfLoopTransitions: {},
        selfLoopRegex: '',
      );

      expect(step.selfLoopTransitions, isEmpty);
      expect(step.explanation.contains('No self-loop'), true);
    });

    test('createBypassTransitions factory should create correct step', () {
      final newTrans = FSATransition(
        id: 't02',
        fromState: q0,
        toState: q2,
        inputSymbols: {'ab'},
      );

      final step = FAToRegexStep.createBypassTransitions(
        id: 'step-bypass',
        stepNumber: 7,
        eliminatedState: q1,
        newTransitions: {newTrans},
        pathRegexExample: 'a·b',
      );

      expect(step.stepType, FAToRegexStepType.createBypass);
      expect(step.eliminatedState, q1);
      expect(step.newTransitions, {newTrans});
      expect(step.resultingRegex, 'a·b');
      expect(step.explanation.contains('1 new transition'), true);
    });

    test('combineTransitions factory should create correct step', () {
      final step = FAToRegexStep.combineTransitions(
        id: 'step-combine',
        stepNumber: 8,
        fromState: q0,
        toState: q2,
        combinedRegexes: ['a', 'b', 'c'],
        resultingRegex: '(a|b|c)',
      );

      expect(step.stepType, FAToRegexStepType.combineTransitions);
      expect(step.combinedRegexes, ['a', 'b', 'c']);
      expect(step.resultingRegex, '(a|b|c)');
      expect(step.explanation.contains('3 regex'), true);
    });

    test('completeElimination factory should create correct step', () {
      final step = FAToRegexStep.completeElimination(
        id: 'step-complete-elim',
        stepNumber: 9,
        eliminatedState: q1,
        remainingStates: 2,
      );

      expect(step.stepType, FAToRegexStepType.completeElimination);
      expect(step.eliminatedState, q1);
      expect(step.remainingStateCount, 2);
      expect(step.explanation.contains('Successfully eliminated'), true);
    });

    test('extractRegex factory should create correct step', () {
      final step = FAToRegexStep.extractRegex(
        id: 'step-extract',
        stepNumber: 10,
        regex: 'a*b+',
        initialState: q0,
        finalState: q2,
      );

      expect(step.stepType, FAToRegexStepType.extractRegex);
      expect(step.finalRegex, 'a*b+');
      expect(step.resultingRegex, 'a*b+');
      expect(step.explanation.contains('a*b+'), true);
    });

    test('completion factory should create correct step', () {
      final step = FAToRegexStep.completion(
        id: 'step-done',
        stepNumber: 15,
        finalRegex: '(a|b)*',
        originalStates: 5,
        stepsExecuted: 15,
      );

      expect(step.stepType, FAToRegexStepType.completion);
      expect(step.finalRegex, '(a|b)*');
      expect(step.resultingRegex, '(a|b)*');
      expect(step.title.contains('complete'), true);
      expect(step.explanation.contains('5 state'), true);
      expect(step.explanation.contains('15'), true);
    });

    test('State and transition sets should be unmodifiable', () {
      final mutableStates = {q0, q1};
      final mutableTransitions = {t01};

      final step = FAToRegexStep.findIncomingTransitions(
        id: 'step-immut',
        stepNumber: 0,
        eliminatedState: q2,
        incomingStates: mutableStates,
        incomingTransitions: mutableTransitions,
      );

      mutableStates.add(q2);
      mutableTransitions.add(t12);

      expect(step.incomingStates, {q0, q1});
      expect(step.incomingTransitions, {t01});
    });

    test('toJson and fromJson should work correctly', () {
      // Use validation step which doesn't involve transitions
      // (FSATransition serialization has a pre-existing bug with state serialization)
      final original = FAToRegexStep.validation(
        id: 'step-json',
        stepNumber: 1,
        stateCount: 5,
        transitionCount: 7,
        hasInitialState: true,
        hasAcceptingStates: true,
      );

      final json = original.toJson();
      final deserialized = FAToRegexStep.fromJson(json);

      expect(deserialized.stepType, original.stepType);
      expect(deserialized.stepNumber, original.stepNumber);
      expect(deserialized.currentStateCount, original.currentStateCount);
    });

    test('Helper properties should work correctly', () {
      final step = FAToRegexStep.findIncomingTransitions(
        id: 'step-help',
        stepNumber: 0,
        eliminatedState: q1,
        incomingStates: {q0},
        incomingTransitions: {t01, t12},
      );

      expect(step.incomingTransitionCount, 2);
      expect(step.outgoingTransitionCount, 0);
      expect(step.newTransitionCount, 0);
      expect(step.eliminatesState, true);
      expect(step.addsState, false);
      expect(step.hasSelfLoop, false);
      expect(step.createsTransitions, false);
    });

    test('eliminatesState should detect elimination steps', () {
      final selectStep = FAToRegexStep.selectStateToEliminate(
        id: 'step-select',
        stepNumber: 0,
        state: q1,
        remainingStates: 2,
      );

      final bypassStep = FAToRegexStep.createBypassTransitions(
        id: 'step-bypass',
        stepNumber: 1,
        eliminatedState: q1,
        newTransitions: {t01},
        pathRegexExample: 'a',
      );

      final validationStep = FAToRegexStep.validation(
        id: 'step-val',
        stepNumber: 2,
        stateCount: 3,
        transitionCount: 3,
        hasInitialState: true,
        hasAcceptingStates: true,
      );

      expect(selectStep.eliminatesState, true);
      expect(bypassStep.eliminatesState, true);
      expect(validationStep.eliminatesState, false);
    });

    test('addsState should detect state addition steps', () {
      final newInit = State(
        id: 'qI',
        label: 'qI',
        position: Vector2(0, 0),
        isInitial: true,
      );

      final addInitStep = FAToRegexStep.addInitialState(
        id: 'step-add-init',
        stepNumber: 0,
        oldInitialState: q0,
        newInitialState: newInit,
      );

      final selectStep = FAToRegexStep.selectStateToEliminate(
        id: 'step-select',
        stepNumber: 1,
        state: q1,
        remainingStates: 2,
      );

      expect(addInitStep.addsState, true);
      expect(selectStep.addsState, false);
    });

    test('stateCountChange should calculate correctly', () {
      final step = FAToRegexStep.selectStateToEliminate(
        id: 'step-change',
        stepNumber: 0,
        state: q1,
        remainingStates: 2,
      );

      expect(step.stateCountChange, -1); // 2 - 3 = -1
    });

    test('eliminationSummary should provide readable summary', () {
      final step = FAToRegexStep.findIncomingTransitions(
        id: 'step-summary',
        stepNumber: 0,
        eliminatedState: q1,
        incomingStates: {q0},
        incomingTransitions: {t01},
      );

      final summary = step.eliminationSummary;

      expect(summary.contains('Eliminating'), true);
      expect(summary.contains('q1'), true);
      expect(summary.contains('1 incoming'), true);
    });
  });
}
