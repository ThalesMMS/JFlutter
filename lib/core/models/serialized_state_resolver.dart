import 'package:vector_math/vector_math_64.dart';

import 'state.dart';

State resolveSerializedState(
  Object? value,
  Map<String, State>? statesById,
  String fieldName,
  String transitionType, {
  bool createMissingStateIds = false,
}) {
  if (value is String) {
    final state = statesById?[value];
    if (state != null) {
      return state;
    }

    if (createMissingStateIds && statesById != null) {
      final synthesizedState = State(
        id: value,
        label: value,
        position: Vector2.zero(),
      );
      statesById[value] = synthesizedState;
      return synthesizedState;
    }

    throw ArgumentError(
      'Unknown $fieldName state id "$value" in $transitionType transition JSON',
    );
  }

  if (value is Map) {
    final state = State.fromJson(value.cast<String, dynamic>());
    return statesById?[state.id] ?? state;
  }

  throw ArgumentError(
    'Expected $fieldName to be a state object or state id string',
  );
}
