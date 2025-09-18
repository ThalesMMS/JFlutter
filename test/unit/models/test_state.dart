import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:jflutter/core/models/state.dart';

void main() {
  group('State Model Tests', () {
    late State testState;
    late Vector2 testPosition;

    setUp(() {
      testPosition = Vector2(100.0, 200.0);
      testState = State(
        id: 'q0',
        label: 'Start',
        position: testPosition,
        isInitial: true,
        isAccepting: false,
        type: StateType.normal,
        properties: {'color': 'blue'},
      );
    });

    group('Constructor and Properties', () {
      test('should create state with required properties', () {
        expect(testState.id, 'q0');
        expect(testState.label, 'Start');
        expect(testState.name, 'Start'); // name should be alias for label
        expect(testState.position, testPosition);
        expect(testState.isInitial, true);
        expect(testState.isAccepting, false);
        expect(testState.type, StateType.normal);
        expect(testState.properties, {'color': 'blue'});
      });

      test('should create state with default values', () {
        final defaultState = State(
          id: 'q1',
          label: 'State1',
          position: Vector2(50.0, 75.0),
        );

        expect(defaultState.isInitial, false);
        expect(defaultState.isAccepting, false);
        expect(defaultState.type, StateType.normal);
        expect(defaultState.properties, {});
      });

      test('should handle empty label', () {
        final emptyLabelState = State(
          id: 'q2',
          label: '',
          position: Vector2(0.0, 0.0),
        );

        expect(emptyLabelState.label, '');
        expect(emptyLabelState.name, '');
      });
    });

    group('copyWith Method', () {
      test('should create copy with updated properties', () {
        final updatedState = testState.copyWith(
          id: 'q1',
          label: 'Updated',
          isAccepting: true,
          type: StateType.accepting,
        );

        expect(updatedState.id, 'q1');
        expect(updatedState.label, 'Updated');
        expect(updatedState.position, testPosition); // unchanged
        expect(updatedState.isInitial, true); // unchanged
        expect(updatedState.isAccepting, true);
        expect(updatedState.type, StateType.accepting);
        expect(updatedState.properties, {'color': 'blue'}); // unchanged
      });

      test('should create copy with null values unchanged', () {
        final unchangedState = testState.copyWith();

        expect(unchangedState.id, testState.id);
        expect(unchangedState.label, testState.label);
        expect(unchangedState.position, testState.position);
        expect(unchangedState.isInitial, testState.isInitial);
        expect(unchangedState.isAccepting, testState.isAccepting);
        expect(unchangedState.type, testState.type);
        expect(unchangedState.properties, testState.properties);
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = testState.toJson();

        expect(json['id'], 'q0');
        expect(json['label'], 'Start');
        expect(json['position']['x'], 100.0);
        expect(json['position']['y'], 200.0);
        expect(json['isInitial'], true);
        expect(json['isAccepting'], false);
        expect(json['type'], 'normal');
        expect(json['properties'], {'color': 'blue'});
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'q1',
          'label': 'Test',
          'position': {'x': 150.0, 'y': 250.0},
          'isInitial': false,
          'isAccepting': true,
          'type': 'accepting',
          'properties': {'size': 'large'},
        };

        final state = State.fromJson(json);

        expect(state.id, 'q1');
        expect(state.label, 'Test');
        expect(state.position.x, 150.0);
        expect(state.position.y, 250.0);
        expect(state.isInitial, false);
        expect(state.isAccepting, true);
        expect(state.type, StateType.accepting);
        expect(state.properties, {'size': 'large'});
      });

      test('should handle missing optional fields in JSON', () {
        final json = {
          'id': 'q2',
          'label': 'Minimal',
          'position': {'x': 0.0, 'y': 0.0},
        };

        final state = State.fromJson(json);

        expect(state.id, 'q2');
        expect(state.label, 'Minimal');
        expect(state.isInitial, false);
        expect(state.isAccepting, false);
        expect(state.type, StateType.normal);
        expect(state.properties, {});
      });

      test('should handle unknown state type in JSON', () {
        final json = {
          'id': 'q3',
          'label': 'Unknown',
          'position': {'x': 0.0, 'y': 0.0},
          'type': 'unknown_type',
        };

        final state = State.fromJson(json);

        expect(state.type, StateType.normal); // should default to normal
      });
    });

    group('Equality and HashCode', () {
      test('should be equal to identical state', () {
        final identicalState = State(
          id: 'q0',
          label: 'Start',
          position: testPosition,
          isInitial: true,
          isAccepting: false,
          type: StateType.normal,
          properties: {'color': 'blue'},
        );

        expect(testState, equals(identicalState));
        expect(testState.hashCode, equals(identicalState.hashCode));
      });

      test('should not be equal to different state', () {
        final differentState = State(
          id: 'q1',
          label: 'Different',
          position: testPosition,
        );

        expect(testState, isNot(equals(differentState)));
        expect(testState.hashCode, isNot(equals(differentState.hashCode)));
      });

      test('should not be equal to state with different position', () {
        final differentPositionState = testState.copyWith(
          position: Vector2(200.0, 300.0),
        );

        expect(testState, isNot(equals(differentPositionState)));
      });
    });

    group('Validation', () {
      test('should validate correct state', () {
        final errors = testState.validate();
        expect(errors, isEmpty);
      });

      test('should detect empty ID', () {
        final invalidState = testState.copyWith(id: '');
        final errors = invalidState.validate();
        expect(errors, contains('State ID cannot be empty'));
      });

      test('should detect negative position', () {
        final invalidState = testState.copyWith(
          position: Vector2(-10.0, -20.0),
        );
        final errors = invalidState.validate();
        expect(errors, contains('State position must be non-negative'));
      });

      test('should detect negative x position', () {
        final invalidState = testState.copyWith(
          position: Vector2(-5.0, 100.0),
        );
        final errors = invalidState.validate();
        expect(errors, contains('State position must be non-negative'));
      });

      test('should detect negative y position', () {
        final invalidState = testState.copyWith(
          position: Vector2(100.0, -5.0),
        );
        final errors = invalidState.validate();
        expect(errors, contains('State position must be non-negative'));
      });
    });

    group('Utility Methods', () {
      test('should check if state is within bounds', () {
        final topLeft = Vector2(50.0, 150.0);
        final bottomRight = Vector2(150.0, 250.0);

        expect(testState.isWithinBounds(topLeft, bottomRight), true);
      });

      test('should detect state outside bounds', () {
        final topLeft = Vector2(200.0, 300.0);
        final bottomRight = Vector2(300.0, 400.0);

        expect(testState.isWithinBounds(topLeft, bottomRight), false);
      });

      test('should calculate distance to another state', () {
        final otherState = State(
          id: 'q1',
          label: 'Other',
          position: Vector2(200.0, 300.0),
        );

        final distance = testState.distanceTo(otherState);
        expect(distance, closeTo(141.42, 0.01)); // sqrt((200-100)² + (300-200)²)
      });

      test('should detect overlapping states', () {
        final overlappingState = State(
          id: 'q1',
          label: 'Overlap',
          position: Vector2(110.0, 210.0), // 10 units away
        );

        expect(testState.overlapsWith(overlappingState, 10.0), true);
        expect(testState.overlapsWith(overlappingState, 5.0), false);
      });

      test('should not overlap with distant state', () {
        final distantState = State(
          id: 'q1',
          label: 'Distant',
          position: Vector2(300.0, 400.0),
        );

        expect(testState.overlapsWith(distantState, 50.0), false);
      });
    });

    group('toString Method', () {
      test('should provide meaningful string representation', () {
        final string = testState.toString();
        expect(string, contains('q0'));
        expect(string, contains('Start'));
        expect(string, contains('isInitial: true'));
        expect(string, contains('isAccepting: false'));
        expect(string, contains('normal'));
      });
    });
  });

  group('StateType Enum Tests', () {
    test('should have correct descriptions', () {
      expect(StateType.normal.description, 'Normal state');
      expect(StateType.trap.description, 'Trap state');
      expect(StateType.accepting.description, 'Accepting state');
      expect(StateType.initial.description, 'Initial state');
      expect(StateType.dead.description, 'Dead state');
    });

    test('should correctly determine if state can be accepting', () {
      expect(StateType.normal.canBeAccepting, true);
      expect(StateType.accepting.canBeAccepting, true);
      expect(StateType.initial.canBeAccepting, true);
      expect(StateType.trap.canBeAccepting, false);
      expect(StateType.dead.canBeAccepting, false);
    });

    test('should correctly determine if state can be initial', () {
      expect(StateType.normal.canBeInitial, true);
      expect(StateType.accepting.canBeInitial, true);
      expect(StateType.initial.canBeInitial, true);
      expect(StateType.trap.canBeInitial, true);
      expect(StateType.dead.canBeInitial, false);
    });
  });
}
