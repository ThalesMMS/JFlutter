import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/algorithms/tm_simulator.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/core/models/transition.dart';

void main() {
  group('TMSimulator deterministic execution', () {
    test('accepts simple single-tape machine', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final qAccept = State(
        id: 'qa',
        label: 'qa',
        position: Vector2(100, 0),
        isInitial: false,
        isAccepting: true,
      );

      final stay = TMTransition(
        id: 'stay',
        fromState: q0,
        toState: qAccept,
        label: 'halt',
        readSymbol: 'B',
        writeSymbol: 'B',
        direction: TapeDirection.stay,
      );

      final tm = TM(
        id: 'single',
        name: 'single tape accept empty',
        states: {q0, qAccept},
        transitions: Set<Transition>.of({stay}),
        alphabet: {'0', '1'},
        initialState: q0,
        acceptingStates: {qAccept},
        created: DateTime(2024, 1, 1),
        modified: DateTime(2024, 1, 1),
        bounds: const math.Rectangle(0, 0, 100, 100),
        tapeAlphabet: {'0', '1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      final result = TMSimulator.simulate(tm, '', stepByStep: true);
      expect(result.isSuccess, isTrue);
      final simulation = result.data!;
      expect(simulation.accepted, isTrue);
      expect(simulation.steps, isNotEmpty);
      expect(simulation.branches.length, 1);
      expect(simulation.hasDeterminismConflicts, isFalse);
    });
  });

  group('TMSimulator multi-tape support', () {
    test('copies symbol to auxiliary tape before accepting', () {
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
        position: Vector2(120, 0),
        isAccepting: false,
      );
      final qAccept = State(
        id: 'qa',
        label: 'qa',
        position: Vector2(220, 0),
        isAccepting: true,
      );

      final writeAux = TMTransition(
        id: 'copy',
        fromState: q0,
        toState: q1,
        label: 'copy to tape1',
        actions: [
          const TMTapeAction(
            tape: 0,
            readSymbol: '1',
            writeSymbol: '1',
            direction: TapeDirection.right,
          ),
          const TMTapeAction(
            tape: 1,
            readSymbol: 'B',
            writeSymbol: '1',
            direction: TapeDirection.stay,
          ),
        ],
      );

      final halt = TMTransition(
        id: 'halt',
        fromState: q1,
        toState: qAccept,
        label: 'halt',
        actions: [
          const TMTapeAction(
            tape: 0,
            readSymbol: 'B',
            writeSymbol: 'B',
            direction: TapeDirection.stay,
          ),
          const TMTapeAction(
            tape: 1,
            readSymbol: '1',
            writeSymbol: '1',
            direction: TapeDirection.stay,
          ),
        ],
      );

      final tm = TM(
        id: 'copy',
        name: 'copy onto second tape',
        states: {q0, q1, qAccept},
        transitions: Set<Transition>.of({writeAux, halt}),
        alphabet: {'1'},
        initialState: q0,
        acceptingStates: {qAccept},
        created: DateTime(2024, 1, 1),
        modified: DateTime(2024, 1, 1),
        bounds: const math.Rectangle(0, 0, 200, 100),
        tapeAlphabet: {'1', 'B'},
        blankSymbol: 'B',
        tapeCount: 2,
      );

      final result = TMSimulator.simulate(tm, '1', stepByStep: true);
      expect(result.isSuccess, isTrue);
      final simulation = result.data!;
      expect(simulation.accepted, isTrue);
      expect(simulation.acceptingBranches.length, 1);
      final branch = simulation.acceptingBranches.first;
      expect(branch.configurations.last.tapes[1].read(), equals('1'));
      expect(simulation.hasDeterminismConflicts, isFalse);
    });
  });

  group('TMSimulator nondeterministic exploration', () {
    test('collects branches and determinism conflicts', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final qAccept = State(
        id: 'qa',
        label: 'qa',
        position: Vector2(100, 0),
        isAccepting: true,
      );
      final qReject = State(
        id: 'qr',
        label: 'qr',
        position: Vector2(100, 100),
        isAccepting: false,
      );

      final acceptTransition = TMTransition(
        id: 'accept',
        fromState: q0,
        toState: qAccept,
        label: 'accept',
        readSymbol: 'B',
        writeSymbol: 'B',
        direction: TapeDirection.stay,
      );
      final rejectTransition = TMTransition(
        id: 'reject',
        fromState: q0,
        toState: qReject,
        label: 'reject',
        readSymbol: 'B',
        writeSymbol: 'B',
        direction: TapeDirection.stay,
      );

      final tm = TM(
        id: 'nondet',
        name: 'nondeterministic choice',
        states: {q0, qAccept, qReject},
        transitions: Set<Transition>.of({acceptTransition, rejectTransition}),
        alphabet: {'0'},
        initialState: q0,
        acceptingStates: {qAccept},
        created: DateTime(2024, 1, 1),
        modified: DateTime(2024, 1, 1),
        bounds: const math.Rectangle(0, 0, 150, 150),
        tapeAlphabet: {'0', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      final result = TMSimulator.simulate(tm, '', stepByStep: true);
      expect(result.isSuccess, isTrue);
      final simulation = result.data!;
      expect(simulation.accepted, isTrue);
      expect(simulation.branches.length, 2);
      expect(simulation.acceptingBranches.length, 1);
      expect(simulation.hasDeterminismConflicts, isTrue);
      expect(simulation.determinismConflicts, isNotEmpty);
      final conflict = simulation.determinismConflicts.first;
      expect(conflict.transitions.length, 2);
      expect(conflict.state.id, equals('q0'));
    });
  });
}
