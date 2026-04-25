part of '../pda_simulator_extended_test.dart';

void _runPdaSimulationTests() {
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
      final result = PDASimulator.simulateNPDA(pda, 'aabb', stepByStep: false);

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
        alphabet: const {'a'},
        initialState: q0,
        acceptingStates: const {},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
        stackAlphabet: const {'Z'},
      );

      final result = PDASimulator.simulateNPDA(
        pda,
        'a',
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
