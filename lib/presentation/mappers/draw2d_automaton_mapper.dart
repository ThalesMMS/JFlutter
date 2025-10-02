import 'package:collection/collection.dart';
import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/state.dart';

/// Utility that converts [FSA] models into the structure expected by the
/// Draw2D canvas.
class Draw2DAutomatonMapper {
  const Draw2DAutomatonMapper._();

  static const double _stateDiameter = 60.0;
  static const double _stateRadius = _stateDiameter / 2;

  /// Converts the provided [automaton] into a Draw2D compatible JSON map.
  static Map<String, dynamic> toJson(FSA? automaton) {
    if (automaton == null) {
      return {
        'id': null,
        'type': 'fsa',
        'name': null,
        'alphabet': const <String>[],
        'states': const <Map<String, dynamic>>[],
        'transitions': const <Map<String, dynamic>>[],
        'initialStateId': null,
      };
    }

    final sortedStates = automaton.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final sortedTransitions = automaton.transitions
        .whereType<FSATransition>()
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final Map<String, String> stateIdMap = {};
    final statesJson = sortedStates.map((state) {
      final draw2dId = _stableStateId(automaton.id, state.id);
      stateIdMap[state.id] = draw2dId;
      return _stateToJson(draw2dId, state);
    }).toList(growable: false);

    final transitionsJson = sortedTransitions.map((transition) {
      final draw2dId = _stableTransitionId(automaton.id, transition.id);
      final fromId = stateIdMap[transition.fromState.id];
      final toId = stateIdMap[transition.toState.id];
      return _transitionToJson(draw2dId, fromId, toId, transition);
    }).whereNotNull().toList(growable: false);

    final initialId = automaton.initialState != null
        ? stateIdMap[automaton.initialState!.id]
        : null;

    return {
      'id': automaton.id,
      'type': 'fsa',
      'name': automaton.name,
      'alphabet': automaton.alphabet.toList()..sort(),
      'states': statesJson,
      'transitions': transitionsJson,
      'initialStateId': initialId,
    };
  }

  static Map<String, dynamic> _stateToJson(String id, State state) {
    final position = state.position;
    final x = position.x.isFinite ? position.x : 0.0;
    final y = position.y.isFinite ? position.y : 0.0;
    return {
      'id': id,
      'sourceId': state.id,
      'label': state.label,
      'isInitial': state.isInitial,
      'isAccepting': state.isAccepting,
      'position': {
        'x': x - _stateRadius,
        'y': y - _stateRadius,
      },
    };
  }

  static Map<String, dynamic>? _transitionToJson(
    String draw2dId,
    String? fromId,
    String? toId,
    FSATransition transition,
  ) {
    if (fromId == null || toId == null) {
      return null;
    }

    final sortedSymbols = transition.inputSymbols.toList()..sort();
    final label = transition.lambdaSymbol ?? sortedSymbols.join(',');

    final control = transition.controlPoint;
    return {
      'id': draw2dId,
      'sourceId': transition.id,
      'from': fromId,
      'to': toId,
      'label': label,
      'controlPoint': {
        'x': control.x.isFinite ? control.x : 0.0,
        'y': control.y.isFinite ? control.y : 0.0,
      },
    };
  }

  static String _stableStateId(String automatonId, String stateId) {
    return 'state_${_hashFor(automatonId)}_${_hashFor(stateId)}';
  }

  static String _stableTransitionId(String automatonId, String transitionId) {
    return 'transition_${_hashFor(automatonId)}_${_hashFor(transitionId)}';
  }

  static int _hashFor(String value) {
    return value.codeUnits.fold<int>(17, (hash, code) => hash * 31 + code);
  }
}
