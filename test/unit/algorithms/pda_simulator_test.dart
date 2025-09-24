import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/algorithms/pda_simulator.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';

void main() {
  group('PDASimulator acceptance modes', () {
    test('accepts when stack empties under empty-stack mode', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(1, 0),
        isAccepting: false,
      );

      final consumeInput = PDATransition.readAndStack(
        id: 'read_a',
        fromState: q0,
        toState: q1,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'A',
      );
      final clearStack = PDATransition(
        id: 'clear',
        fromState: q1,
        toState: q1,
        label: 'ε,A→ε',
        inputSymbol: '',
        popSymbol: 'A',
        pushSymbol: '',
        isLambdaInput: true,
        isLambdaPush: true,
      );

      final pda = PDA(
        id: 'empty-stack',
        name: 'empty-stack acceptance',
        states: {q0, q1},
        transitions: Set<Transition>.from({consumeInput, clearStack}),
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: <State>{},
        created: DateTime(2024, 1, 1),
        modified: DateTime(2024, 1, 1),
        bounds: const math.Rectangle(0, 0, 100, 100),
        stackAlphabet: {'Z', 'A'},
        initialStackSymbol: 'Z',
        acceptanceMode: PDAAcceptanceMode.emptyStack,
      );

      final result = PDASimulator.simulate(pda, 'a', stepByStep: true);
      expect(result.isSuccess, isTrue);

      final simulation = result.data!;
      expect(simulation.accepted, isTrue);
      expect(simulation.acceptanceMode, PDAAcceptanceMode.emptyStack);
      expect(simulation.acceptedBranches.length, 1);
      final witness = simulation.acceptedBranches.first;
      expect(witness.acceptedByEmptyStack, isTrue);
      expect(witness.acceptedByFinalState, isFalse);
      expect(simulation.isDeterministic, isTrue);
      expect(simulation.determinismConflicts, isEmpty);
    });
  });

  group('PDASimulator nondeterministic exploration', () {
    PDA _buildBranchingPda() {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(1, 0),
        isAccepting: false,
      );
      final q2 = State(
        id: 'q2',
        label: 'q2',
        position: Vector2(2, 0),
        isAccepting: false,
      );

      final branchA = PDATransition.readAndStack(
        id: 'push_a',
        fromState: q0,
        toState: q1,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'A',
      );
      final branchB = PDATransition.readAndStack(
        id: 'push_b',
        fromState: q0,
        toState: q2,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'B',
      );
      final popA = PDATransition(
        id: 'pop_a',
        fromState: q1,
        toState: q1,
        label: 'ε,A→ε',
        inputSymbol: '',
        popSymbol: 'A',
        pushSymbol: '',
        isLambdaInput: true,
        isLambdaPush: true,
      );
      final popB = PDATransition(
        id: 'pop_b',
        fromState: q2,
        toState: q2,
        label: 'ε,B→ε',
        inputSymbol: '',
        popSymbol: 'B',
        pushSymbol: '',
        isLambdaInput: true,
        isLambdaPush: true,
      );

      return PDA(
        id: 'npda',
        name: 'branching npda',
        states: {q0, q1, q2},
        transitions: Set<Transition>.from({branchA, branchB, popA, popB}),
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: <State>{},
        created: DateTime(2024, 1, 1),
        modified: DateTime(2024, 1, 1),
        bounds: const math.Rectangle(0, 0, 120, 120),
        stackAlphabet: {'Z', 'A', 'B'},
        initialStackSymbol: 'Z',
        acceptanceMode: PDAAcceptanceMode.either,
      );
    }

    test('collects multiple accepting branches and conflicts', () {
      final pda = _buildBranchingPda();
      final result = PDASimulator.simulate(pda, 'a');
      expect(result.isSuccess, isTrue);

      final simulation = result.data!;
      expect(simulation.accepted, isTrue);
      expect(simulation.isDeterministic, isFalse);
      expect(simulation.determinismConflicts, isNotEmpty);
      expect(simulation.acceptedBranches.length, 2);
      expect(simulation.hasMultipleAcceptingBranches, isTrue);
      expect(simulation.branchesTruncated, isFalse);
    });

    test('honours maxAcceptedPaths limit by truncating exploration', () {
      final pda = _buildBranchingPda();
      final limitedResult = PDASimulator.simulate(
        pda,
        'a',
        maxAcceptedPaths: 1,
      );
      expect(limitedResult.isSuccess, isTrue);

      final simulation = limitedResult.data!;
      expect(simulation.acceptedBranches.length, 1);
      expect(simulation.branchesTruncated, isTrue);
      expect(simulation.accepted, isTrue);
    });
  });
}
