import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/fsa.dart';

void main() {
  group('Automaton Model Tests', () {
    late State state1;
    late State state2;
    late State state3;
    late FSATransition transition1;
    late FSATransition transition2;
    late FSA testAutomaton;

    setUp(() {
      state1 = State(
        id: 'q0',
        label: 'Start',
        position: Vector2(100.0, 100.0),
        isInitial: true,
      );
      state2 = State(
        id: 'q1',
        label: 'Middle',
        position: Vector2(200.0, 200.0),
      );
      state3 = State(
        id: 'q2',
        label: 'End',
        position: Vector2(300.0, 300.0),
        isAccepting: true,
      );

      transition1 = FSATransition(
        id: 't0',
        fromState: state1,
        toState: state2,
        label: 'a',
        inputSymbols: {'a'},
      );
      transition2 = FSATransition(
        id: 't1',
        fromState: state2,
        toState: state3,
        label: 'b',
        inputSymbols: {'b'},
      );

      testAutomaton = FSA(
        id: 'automaton1',
        name: 'Test FSA',
        states: {state1, state2, state3},
        transitions: {transition1, transition2},
        alphabet: {'a', 'b'},
        initialState: state1,
        acceptingStates: {state3},
        created: DateTime(2024, 1, 1),
        modified: DateTime(2024, 1, 2),
        bounds: const math.Rectangle(0, 0, 400, 400),
      );
    });

    group('Constructor and Properties', () {
      test('should create automaton with required properties', () {
        expect(testAutomaton.id, 'automaton1');
        expect(testAutomaton.name, 'Test FSA');
        expect(testAutomaton.states, {state1, state2, state3});
        expect(testAutomaton.transitions, {transition1, transition2});
        expect(testAutomaton.alphabet, {'a', 'b'});
        expect(testAutomaton.initialState, state1);
        expect(testAutomaton.acceptingStates, {state3});
        expect(testAutomaton.type, AutomatonType.fsa);
        expect(testAutomaton.zoomLevel, 1.0);
        expect(testAutomaton.panOffset, Vector2.zero());
      });

      test('should create automaton with custom zoom and pan', () {
        final customAutomaton = FSA(
          id: 'automaton2',
          name: 'Custom FSA',
          states: {state1, state2},
          transitions: {transition1},
          alphabet: {'a'},
          initialState: state1,
          acceptingStates: {state2},
          created: DateTime(2024, 1, 1),
          modified: DateTime(2024, 1, 2),
          bounds: const math.Rectangle(0, 0, 300, 300),
          zoomLevel: 1.5,
          panOffset: Vector2(50.0, 50.0),
        );

        expect(customAutomaton.zoomLevel, 1.5);
        expect(customAutomaton.panOffset, Vector2(50.0, 50.0));
      });
    });

    group('copyWith Method', () {
      test('should create copy with updated properties', () {
        final newState = State(
          id: 'q3',
          label: 'New',
          position: Vector2(400.0, 400.0),
        );
        final updatedAutomaton = testAutomaton.copyWith(
          name: 'Updated FSA',
          states: {state1, state2, state3, newState},
          zoomLevel: 2.0,
        );

        expect(updatedAutomaton.name, 'Updated FSA');
        expect(updatedAutomaton.states, {state1, state2, state3, newState});
        expect(updatedAutomaton.zoomLevel, 2.0);
        expect(updatedAutomaton.id, 'automaton1'); // unchanged
        expect(updatedAutomaton.alphabet, {'a', 'b'}); // unchanged
      });

      test('should create copy with null values unchanged', () {
        final unchangedAutomaton = testAutomaton.copyWith();

        expect(unchangedAutomaton.id, testAutomaton.id);
        expect(unchangedAutomaton.name, testAutomaton.name);
        expect(unchangedAutomaton.states, testAutomaton.states);
        expect(unchangedAutomaton.transitions, testAutomaton.transitions);
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = testAutomaton.toJson();

        expect(json['id'], 'automaton1');
        expect(json['name'], 'Test FSA');
        expect(json['type'], 'FSA');
        expect(json['alphabet'], ['a', 'b']);
        expect(json['zoomLevel'], 1.0);
        expect(json['states'], isA<List>());
        expect(json['transitions'], isA<List>());
        expect(json['initialState'], isA<Map>());
        expect(json['acceptingStates'], isA<List>());
      });

      test('should create from JSON correctly', () {
        final json = testAutomaton.toJson();
        final recreatedAutomaton = FSA.fromJson(json);

        expect(recreatedAutomaton.id, testAutomaton.id);
        expect(recreatedAutomaton.name, testAutomaton.name);
        expect(recreatedAutomaton.type, testAutomaton.type);
        expect(recreatedAutomaton.alphabet, testAutomaton.alphabet);
        expect(recreatedAutomaton.states.length, testAutomaton.states.length);
        expect(recreatedAutomaton.transitions.length, testAutomaton.transitions.length);
      });
    });

    group('Equality and HashCode', () {
      test('should be equal to identical automaton', () {
        final identicalAutomaton = FSA(
          id: 'automaton1',
          name: 'Test FSA',
          states: {state1, state2, state3},
          transitions: {transition1, transition2},
          alphabet: {'a', 'b'},
          initialState: state1,
          acceptingStates: {state3},
          created: DateTime(2024, 1, 1),
          modified: DateTime(2024, 1, 2),
          bounds: const math.Rectangle(0, 0, 400, 400),
        );

        expect(testAutomaton, equals(identicalAutomaton));
        expect(testAutomaton.hashCode, equals(identicalAutomaton.hashCode));
      });

      test('should not be equal to different automaton', () {
        final differentAutomaton = FSA(
          id: 'automaton2',
          name: 'Different FSA',
          states: {state1, state2},
          transitions: {transition1},
          alphabet: {'a'},
          initialState: state1,
          acceptingStates: {state2},
          created: DateTime(2024, 1, 1),
          modified: DateTime(2024, 1, 2),
          bounds: const math.Rectangle(0, 0, 300, 300),
        );

        expect(testAutomaton, isNot(equals(differentAutomaton)));
        expect(testAutomaton.hashCode, isNot(equals(differentAutomaton.hashCode)));
      });
    });

    group('Validation', () {
      test('should validate correct automaton', () {
        final errors = testAutomaton.validate();
        expect(errors, isEmpty);
      });

      test('should detect empty ID', () {
        final invalidAutomaton = testAutomaton.copyWith(id: '');
        final errors = invalidAutomaton.validate();
        expect(errors, contains('Automaton ID cannot be empty'));
      });

      test('should detect empty name', () {
        final invalidAutomaton = testAutomaton.copyWith(name: '');
        final errors = invalidAutomaton.validate();
        expect(errors, contains('Automaton name cannot be empty'));
      });

      test('should detect empty states', () {
        final invalidAutomaton = testAutomaton.copyWith(states: {});
        final errors = invalidAutomaton.validate();
        expect(errors, contains('Automaton must have at least one state'));
      });

      test('should detect invalid initial state', () {
        final invalidState = State(
          id: 'q_invalid',
          label: 'Invalid',
          position: Vector2(500.0, 500.0),
        );
        final invalidAutomaton = testAutomaton.copyWith(initialState: invalidState);
        final errors = invalidAutomaton.validate();
        expect(errors, contains('Initial state must be in the states set'));
      });

      test('should detect invalid accepting state', () {
        final invalidState = State(
          id: 'q_invalid',
          label: 'Invalid',
          position: Vector2(500.0, 500.0),
        );
        final invalidAutomaton = testAutomaton.copyWith(acceptingStates: {invalidState});
        final errors = invalidAutomaton.validate();
        expect(errors, contains('Accepting state q_invalid must be in the states set'));
      });

      test('should detect invalid transition fromState', () {
        final invalidState = State(
          id: 'q_invalid',
          label: 'Invalid',
          position: Vector2(500.0, 500.0),
        );
        final invalidTransition = FSATransition(
          id: 't_invalid',
          fromState: invalidState,
          toState: state1,
          label: 'x',
          inputSymbols: {'x'},
        );
        final invalidAutomaton = testAutomaton.copyWith(
          transitions: {transition1, transition2, invalidTransition},
        );
        final errors = invalidAutomaton.validate();
        expect(errors, contains('Transition t_invalid references invalid fromState'));
      });

      test('should detect invalid transition toState', () {
        final invalidState = State(
          id: 'q_invalid',
          label: 'Invalid',
          position: Vector2(500.0, 500.0),
        );
        final invalidTransition = FSATransition(
          id: 't_invalid',
          fromState: state1,
          toState: invalidState,
          label: 'x',
          inputSymbols: {'x'},
        );
        final invalidAutomaton = testAutomaton.copyWith(
          transitions: {transition1, transition2, invalidTransition},
        );
        final errors = invalidAutomaton.validate();
        expect(errors, contains('Transition t_invalid references invalid toState'));
      });

      test('should detect invalid zoom level', () {
        final invalidAutomaton = testAutomaton.copyWith(zoomLevel: 0.1);
        final errors = invalidAutomaton.validate();
        expect(errors, contains('Zoom level must be between 0.5 and 3.0'));

        final invalidAutomaton2 = testAutomaton.copyWith(zoomLevel: 5.0);
        final errors2 = invalidAutomaton2.validate();
        expect(errors2, contains('Zoom level must be between 0.5 and 3.0'));
      });
    });

    group('Basic Properties', () {
      test('should check if automaton is valid', () {
        expect(testAutomaton.isValid, true);
        
        final invalidAutomaton = testAutomaton.copyWith(id: '');
        expect(invalidAutomaton.isValid, false);
      });

      test('should get correct counts', () {
        expect(testAutomaton.stateCount, 3);
        expect(testAutomaton.transitionCount, 2);
        expect(testAutomaton.acceptingStateCount, 1);
      });

      test('should check initial and accepting states', () {
        expect(testAutomaton.hasInitialState, true);
        expect(testAutomaton.hasAcceptingStates, true);

        final noInitialAutomaton = testAutomaton.copyWith(initialState: null);
        expect(noInitialAutomaton.hasInitialState, false);

        final noAcceptingAutomaton = testAutomaton.copyWith(acceptingStates: {});
        expect(noAcceptingAutomaton.hasAcceptingStates, false);
      });

      test('should get non-accepting and non-initial states', () {
        expect(testAutomaton.nonAcceptingStates, {state1, state2});
        expect(testAutomaton.nonInitialStates, {state2, state3});
      });
    });

    group('Transition Queries', () {
      test('should get transitions from state', () {
        final transitionsFromState1 = testAutomaton.getTransitionsFrom(state1);
        expect(transitionsFromState1, {transition1});

        final transitionsFromState2 = testAutomaton.getTransitionsFrom(state2);
        expect(transitionsFromState2, {transition2});

        final transitionsFromState3 = testAutomaton.getTransitionsFrom(state3);
        expect(transitionsFromState3, isEmpty);
      });

      test('should get transitions to state', () {
        final transitionsToState1 = testAutomaton.getTransitionsTo(state1);
        expect(transitionsToState1, isEmpty);

        final transitionsToState2 = testAutomaton.getTransitionsTo(state2);
        expect(transitionsToState2, {transition1});

        final transitionsToState3 = testAutomaton.getTransitionsTo(state3);
        expect(transitionsToState3, {transition2});
      });

      test('should get transitions between states', () {
        final transitionsBetween = testAutomaton.getTransitionsBetween(state1, state2);
        expect(transitionsBetween, {transition1});

        final transitionsBetweenReverse = testAutomaton.getTransitionsBetween(state2, state1);
        expect(transitionsBetweenReverse, isEmpty);
      });
    });

    group('Reachability Analysis', () {
      test('should get reachable states', () {
        final reachableFromState1 = testAutomaton.getReachableStates(state1);
        expect(reachableFromState1, {state1, state2, state3});

        final reachableFromState2 = testAutomaton.getReachableStates(state2);
        expect(reachableFromState2, {state2, state3});

        final reachableFromState3 = testAutomaton.getReachableStates(state3);
        expect(reachableFromState3, {state3});
      });

      test('should get states reaching target', () {
        final reachingState1 = testAutomaton.getStatesReaching(state1);
        expect(reachingState1, {state1});

        final reachingState2 = testAutomaton.getStatesReaching(state2);
        expect(reachingState2, {state1, state2});

        final reachingState3 = testAutomaton.getStatesReaching(state3);
        expect(reachingState3, {state1, state2, state3});
      });

      test('should check if state is reachable from initial', () {
        expect(testAutomaton.isStateReachable(state1), true);
        expect(testAutomaton.isStateReachable(state2), true);
        expect(testAutomaton.isStateReachable(state3), true);
      });

      test('should get unreachable states', () {
        expect(testAutomaton.unreachableStates, isEmpty);

        // Add an unreachable state
        final unreachableState = State(
          id: 'q_unreachable',
          label: 'Unreachable',
          position: Vector2(500.0, 500.0),
        );
        final automatonWithUnreachable = testAutomaton.copyWith(
          states: {state1, state2, state3, unreachableState},
        );
        expect(automatonWithUnreachable.unreachableStates, {unreachableState});
      });

      test('should get dead states', () {
        expect(testAutomaton.deadStates, isEmpty);

        // Add a dead state (cannot reach accepting state)
        final deadState = State(
          id: 'q_dead',
          label: 'Dead',
          position: Vector2(500.0, 500.0),
        );
        final deadTransition = FSATransition(
          id: 't_dead',
          fromState: deadState,
          toState: deadState, // self-loop
          label: 'x',
          inputSymbols: {'x'},
        );
        final automatonWithDead = testAutomaton.copyWith(
          states: {state1, state2, state3, deadState},
          transitions: {transition1, transition2, deadTransition},
        );
        expect(automatonWithDead.deadStates, {deadState});
      });
    });

    group('Geometric Calculations', () {
      test('should calculate center point', () {
        final center = testAutomaton.centerPoint;
        expect(center.x, 200.0); // (100 + 200 + 300) / 3
        expect(center.y, 200.0); // (100 + 200 + 300) / 3
      });

      test('should calculate center point for empty automaton', () {
        final emptyAutomaton = testAutomaton.copyWith(states: {});
        final center = emptyAutomaton.centerPoint;
        expect(center, Vector2.zero());
      });

      test('should calculate states bounding box', () {
        final boundingBox = testAutomaton.statesBoundingBox;
        expect(boundingBox.left, 100.0);
        expect(boundingBox.top, 100.0);
        expect(boundingBox.width, 200.0);
        expect(boundingBox.height, 200.0);
      });

      test('should calculate bounding box for empty automaton', () {
        final emptyAutomaton = testAutomaton.copyWith(states: {});
        final boundingBox = emptyAutomaton.statesBoundingBox;
        expect(boundingBox.left, 0.0);
        expect(boundingBox.top, 0.0);
        expect(boundingBox.width, 0.0);
        expect(boundingBox.height, 0.0);
      });
    });

    group('Language Properties', () {
      test('should check if automaton is empty', () {
        expect(testAutomaton.isEmpty, false);

        final emptyAutomaton = testAutomaton.copyWith(acceptingStates: {});
        expect(emptyAutomaton.isEmpty, true);

        final noInitialAutomaton = testAutomaton.copyWith(initialState: null);
        expect(noInitialAutomaton.isEmpty, true);
      });

      test('should check if automaton is universal', () {
        expect(testAutomaton.isUniversal, false);

        // Make all states accepting
        final universalAutomaton = testAutomaton.copyWith(
          acceptingStates: {state1, state2, state3},
        );
        expect(universalAutomaton.isUniversal, true);
      });
    });

    group('toString Method', () {
      test('should provide meaningful string representation', () {
        final string = testAutomaton.toString();
        expect(string, contains('automaton1'));
        expect(string, contains('Test FSA'));
        expect(string, contains('fsa'));
        expect(string, contains('states: 3'));
        expect(string, contains('transitions: 2'));
      });
    });
  });

  group('AutomatonType Enum Tests', () {
    test('should have correct descriptions', () {
      expect(AutomatonType.fsa.description, 'Finite State Automaton');
      expect(AutomatonType.pda.description, 'Pushdown Automaton');
      expect(AutomatonType.tm.description, 'Turing Machine');
    });

    test('should have correct short names', () {
      expect(AutomatonType.fsa.shortName, 'FSA');
      expect(AutomatonType.pda.shortName, 'PDA');
      expect(AutomatonType.tm.shortName, 'TM');
    });

    test('should correctly determine capabilities', () {
      expect(AutomatonType.fsa.hasStack, false);
      expect(AutomatonType.pda.hasStack, true);
      expect(AutomatonType.tm.hasStack, false);

      expect(AutomatonType.fsa.hasTape, false);
      expect(AutomatonType.pda.hasTape, false);
      expect(AutomatonType.tm.hasTape, true);

      expect(AutomatonType.fsa.hasOutput, false);
      expect(AutomatonType.pda.hasOutput, false);
      expect(AutomatonType.tm.hasOutput, true);
    });
  });
}
