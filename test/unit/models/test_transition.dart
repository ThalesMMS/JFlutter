import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/core/models/fsa_transition.dart';

void main() {
  group('Transition Model Tests', () {
    late State fromState;
    late State toState;
    late FSATransition testTransition;

    setUp(() {
      fromState = State(
        id: 'q0',
        label: 'Start',
        position: Vector2(100.0, 100.0),
        isInitial: true,
      );
      toState = State(
        id: 'q1',
        label: 'End',
        position: Vector2(200.0, 200.0),
        isAccepting: true,
      );
      testTransition = FSATransition(
        id: 't0',
        fromState: fromState,
        toState: toState,
        label: 'a',
        inputSymbols: {'a'},
        type: TransitionType.deterministic,
      );
    });

    group('Constructor and Properties', () {
      test('should create transition with required properties', () {
        expect(testTransition.id, 't0');
        expect(testTransition.fromState, fromState);
        expect(testTransition.toState, toState);
        expect(testTransition.label, 'a');
        expect(testTransition.inputSymbols, {'a'});
        expect(testTransition.type, TransitionType.deterministic);
        expect(testTransition.controlPoint, Vector2.zero());
      });

      test('should create transition with custom control point', () {
        final controlPoint = Vector2(150.0, 150.0);
        final transition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: toState,
          label: 'b',
          controlPoint: controlPoint,
          inputSymbols: {'b'},
        );

        expect(transition.controlPoint, controlPoint);
      });

      test('should create epsilon transition', () {
        final epsilonTransition = FSATransition.epsilon(
          id: 't2',
          fromState: fromState,
          toState: toState,
        );

        expect(epsilonTransition.lambdaSymbol, 'ε');
        expect(epsilonTransition.inputSymbols, isEmpty);
        expect(epsilonTransition.type, TransitionType.epsilon);
        expect(epsilonTransition.isEpsilonTransition, true);
      });

      test('should create deterministic transition', () {
        final detTransition = FSATransition.deterministic(
          id: 't3',
          fromState: fromState,
          toState: toState,
          symbol: 'c',
        );

        expect(detTransition.inputSymbols, {'c'});
        expect(detTransition.type, TransitionType.deterministic);
        expect(detTransition.isDeterministic, true);
        expect(detTransition.isNondeterministic, false);
      });

      test('should create non-deterministic transition', () {
        final nondetTransition = FSATransition.nondeterministic(
          id: 't4',
          fromState: fromState,
          toState: toState,
          symbols: {'a', 'b', 'c'},
        );

        expect(nondetTransition.inputSymbols, {'a', 'b', 'c'});
        expect(nondetTransition.type, TransitionType.nondeterministic);
        expect(nondetTransition.isDeterministic, false);
        expect(nondetTransition.isNondeterministic, true);
      });
    });

    group('copyWith Method', () {
      test('should create copy with updated properties', () {
        final updatedTransition = testTransition.copyWith(
          id: 't1',
          label: 'b',
          inputSymbols: {'b'},
          type: TransitionType.nondeterministic,
        );

        expect(updatedTransition.id, 't1');
        expect(updatedTransition.label, 'b');
        expect(updatedTransition.inputSymbols, {'b'});
        expect(updatedTransition.type, TransitionType.nondeterministic);
        expect(updatedTransition.fromState, fromState); // unchanged
        expect(updatedTransition.toState, toState); // unchanged
      });

      test('should create copy with null values unchanged', () {
        final unchangedTransition = testTransition.copyWith();

        expect(unchangedTransition.id, testTransition.id);
        expect(unchangedTransition.label, testTransition.label);
        expect(unchangedTransition.inputSymbols, testTransition.inputSymbols);
        expect(unchangedTransition.type, testTransition.type);
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = testTransition.toJson();

        expect(json['id'], 't0');
        expect(json['fromState'], fromState.id);
        expect(json['toState'], toState.id);
        expect(json['label'], 'a');
        expect(json['type'], 'deterministic');
        expect(json['transitionType'], 'fsa');
        expect(json['inputSymbols'], ['a']);
        expect(json['lambdaSymbol'], null);
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 't1',
          'fromState': fromState.toJson(),
          'toState': toState.toJson(),
          'label': 'b',
          'controlPoint': {'x': 150.0, 'y': 150.0},
          'type': 'nondeterministic',
          'transitionType': 'fsa',
          'inputSymbols': ['b', 'c'],
          'lambdaSymbol': null,
        };

        final transition = FSATransition.fromJson(json);

        expect(transition.id, 't1');
        expect(transition.label, 'b');
        expect(transition.inputSymbols, {'b', 'c'});
        expect(transition.type, TransitionType.nondeterministic);
        expect(transition.controlPoint.x, 150.0);
        expect(transition.controlPoint.y, 150.0);
      });

      test('should handle epsilon transition in JSON', () {
        final json = {
          'id': 't2',
          'fromState': fromState.toJson(),
          'toState': toState.toJson(),
          'label': 'ε',
          'controlPoint': {'x': 0.0, 'y': 0.0},
          'type': 'epsilon',
          'transitionType': 'fsa',
          'inputSymbols': [],
          'lambdaSymbol': 'ε',
        };

        final transition = FSATransition.fromJson(json);

        expect(transition.lambdaSymbol, 'ε');
        expect(transition.inputSymbols, isEmpty);
        expect(transition.type, TransitionType.epsilon);
        expect(transition.isEpsilonTransition, true);
      });
    });

    group('Equality and HashCode', () {
      test('should be equal to identical transition', () {
        final identicalTransition = FSATransition(
          id: 't0',
          fromState: fromState,
          toState: toState,
          label: 'a',
          inputSymbols: {'a'},
          type: TransitionType.deterministic,
        );

        expect(testTransition, equals(identicalTransition));
        expect(testTransition.hashCode, equals(identicalTransition.hashCode));
      });

      test('should not be equal to different transition', () {
        final differentTransition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: toState,
          label: 'b',
          inputSymbols: {'b'},
        );

        expect(testTransition, isNot(equals(differentTransition)));
        expect(testTransition.hashCode, isNot(equals(differentTransition.hashCode)));
      });
    });

    group('Validation', () {
      test('should validate correct transition', () {
        final errors = testTransition.validate();
        expect(errors, isEmpty);
      });

      test('should detect empty ID', () {
        final invalidTransition = testTransition.copyWith(id: '');
        final errors = invalidTransition.validate();
        expect(errors, contains('Transition ID cannot be empty'));
      });

      test('should detect empty label', () {
        final invalidTransition = testTransition.copyWith(label: '');
        final errors = invalidTransition.validate();
        expect(errors, contains('Transition label cannot be empty'));
      });

      test('should detect self-loop without control point', () {
        final selfLoopTransition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: fromState, // self-loop
          label: 'a',
          inputSymbols: {'a'},
        );
        final errors = selfLoopTransition.validate();
        expect(errors, contains('Self-loop transitions must have a control point'));
      });

      test('should validate self-loop with control point', () {
        final selfLoopTransition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: fromState, // self-loop
          label: 'a',
          controlPoint: Vector2(10.0, 10.0),
          inputSymbols: {'a'},
        );
        final errors = selfLoopTransition.validate();
        expect(errors, isEmpty);
      });

      test('should detect FSA transition without symbols', () {
        final invalidTransition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: toState,
          label: 'empty',
          inputSymbols: const {},
        );
        final errors = invalidTransition.validate();
        expect(errors, contains('FSA transition must have input symbols or be an epsilon transition'));
      });

      test('should detect FSA transition with both symbols and lambda', () {
        final invalidTransition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: toState,
          label: 'invalid',
          inputSymbols: {'a'},
          lambdaSymbol: 'ε',
        );
        final errors = invalidTransition.validate();
        expect(errors, contains('FSA transition cannot have both input symbols and lambda symbol'));
      });

      test('should detect empty lambda symbol', () {
        final invalidTransition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: toState,
          label: 'empty',
          inputSymbols: const {},
          lambdaSymbol: '',
        );
        final errors = invalidTransition.validate();
        expect(errors, contains('Lambda symbol cannot be empty'));
      });

      test('should detect empty input symbol', () {
        final invalidTransition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: toState,
          label: 'empty',
          inputSymbols: {'a', '', 'c'},
        );
        final errors = invalidTransition.validate();
        expect(errors, contains('Input symbol cannot be empty'));
      });
    });

    group('Utility Methods', () {
      test('should detect self-loop', () {
        final selfLoopTransition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: fromState,
          label: 'a',
          inputSymbols: {'a'},
        );

        expect(selfLoopTransition.isSelfLoop, true);
        expect(testTransition.isSelfLoop, false);
      });

      test('should calculate arc length for regular transition', () {
        final length = testTransition.arcLength;
        expect(length, closeTo(141.42, 0.01)); // sqrt((200-100)² + (200-100)²)
      });

      test('should calculate arc length for self-loop', () {
        final selfLoopTransition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: fromState,
          label: 'a',
          inputSymbols: {'a'},
        );

        final length = selfLoopTransition.arcLength;
        expect(length, closeTo(125.66, 0.01)); // 2 * π * 20
      });

      test('should calculate midpoint for regular transition', () {
        final midpoint = testTransition.midpoint;
        expect(midpoint.x, 150.0); // (100 + 200) / 2
        expect(midpoint.y, 150.0); // (100 + 200) / 2
      });

      test('should calculate midpoint for self-loop', () {
        final selfLoopTransition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: fromState,
          label: 'a',
          inputSymbols: {'a'},
        );

        final midpoint = selfLoopTransition.midpoint;
        expect(midpoint.x, 120.0); // 100 + 20
        expect(midpoint.y, 100.0); // 100 + 0
      });

      test('should calculate angle', () {
        final angle = testTransition.angle;
        expect(angle, closeTo(0.785, 0.01)); // π/4 radians (45 degrees)
      });

      test('should check if accepts symbol', () {
        expect(testTransition.acceptsSymbol('a'), true);
        expect(testTransition.acceptsSymbol('b'), false);
      });

      test('should check if accepts any symbol', () {
        expect(testTransition.acceptsAnySymbol({'a', 'b'}), true);
        expect(testTransition.acceptsAnySymbol({'b', 'c'}), false);
      });

      test('should get accepted symbols', () {
        expect(testTransition.acceptedSymbols, {'a'});
      });

      test('should handle epsilon transition symbol acceptance', () {
        final epsilonTransition = FSATransition.epsilon(
          id: 't1',
          fromState: fromState,
          toState: toState,
        );

        expect(epsilonTransition.acceptsSymbol('ε'), true);
        expect(epsilonTransition.acceptsSymbol('a'), false);
        expect(epsilonTransition.acceptedSymbols, {'ε'});
      });
    });

    group('toString Method', () {
      test('should provide meaningful string representation', () {
        final string = testTransition.toString();
        expect(string, contains('t0'));
        expect(string, contains('q0'));
        expect(string, contains('q1'));
        expect(string, contains('{a}'));
      });
    });
  });

  group('TransitionType Enum Tests', () {
    test('should have correct descriptions', () {
      expect(TransitionType.deterministic.description, 'Deterministic transition');
      expect(TransitionType.nondeterministic.description, 'Non-deterministic transition');
      expect(TransitionType.epsilon.description, 'Epsilon transition');
    });

    test('should correctly determine if allows multiple symbols', () {
      expect(TransitionType.deterministic.allowsMultipleSymbols, false);
      expect(TransitionType.nondeterministic.allowsMultipleSymbols, true);
      expect(TransitionType.epsilon.allowsMultipleSymbols, false);
    });
  });
}
