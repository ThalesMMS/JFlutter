import '../../core/models/state.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';

/// Utility that converts [TM] models into the structure expected by the
/// Draw2D canvas bridge.
class Draw2DTMMapper {
  const Draw2DTMMapper._();

  static const double _stateDiameter = 60.0;
  static const double _stateRadius = _stateDiameter / 2;

  static Map<String, dynamic> toJson(TM? machine) {
    if (machine == null) {
      return {
        'id': null,
        'name': null,
        'states': const <Map<String, dynamic>>[],
        'transitions': const <Map<String, dynamic>>[],
        'initialStateId': null,
      };
    }

    final sortedStates = machine.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final sortedTransitions =
        machine.transitions.whereType<TMTransition>().toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    final Map<String, String> stateIdMap = {};
    final statesJson = sortedStates.map((state) {
      final draw2dId = _stableStateId(machine.id, state.id);
      stateIdMap[state.id] = draw2dId;
      return _stateToJson(draw2dId, state);
    }).toList(growable: false);

    final transitionsJson = sortedTransitions.map((transition) {
      final draw2dId = _stableTransitionId(machine.id, transition.id);
      final fromId = stateIdMap[transition.fromState.id];
      final toId = stateIdMap[transition.toState.id];
      return _transitionToJson(draw2dId, fromId, toId, transition);
    }).whereType<Map<String, dynamic>>().toList(growable: false);

    final initialId = machine.initialState != null
        ? stateIdMap[machine.initialState!.id]
        : null;

    return {
      'id': machine.id,
      'name': machine.name,
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
    TMTransition transition,
  ) {
    if (fromId == null || toId == null) {
      return null;
    }

    final control = transition.controlPoint;
    final label = _formatTransitionLabel(transition);

    return {
      'id': draw2dId,
      'sourceId': transition.id,
      'from': fromId,
      'to': toId,
      'label': label,
      'readSymbol': transition.readSymbol,
      'writeSymbol': transition.writeSymbol,
      'direction': _directionSymbol(transition.direction),
      'tapeNumber': transition.tapeNumber,
      'controlPoint': {
        'x': control.x.isFinite ? control.x : 0.0,
        'y': control.y.isFinite ? control.y : 0.0,
      },
    };
  }

  static String _formatTransitionLabel(TMTransition transition) {
    return '${transition.readSymbol.isEmpty ? '∅' : transition.readSymbol}'
        '/${transition.writeSymbol.isEmpty ? '∅' : transition.writeSymbol},'
        '${_directionSymbol(transition.direction)}';
  }

  static String _directionSymbol(TapeDirection direction) {
    switch (direction) {
      case TapeDirection.left:
        return 'L';
      case TapeDirection.right:
        return 'R';
      case TapeDirection.stay:
        return 'S';
    }
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
