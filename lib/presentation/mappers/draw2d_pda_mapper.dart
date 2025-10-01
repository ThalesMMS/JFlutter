import 'package:collection/collection.dart';

import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/state.dart';

/// Utility that converts [PDA] models into the structure expected by the
/// Draw2D canvas runtime.
class Draw2DPdaMapper {
  const Draw2DPdaMapper._();

  static const double _stateDiameter = 60.0;
  static const double _stateRadius = _stateDiameter / 2;

  /// Converts the provided [pda] into a Draw2D compatible JSON map.
  static Map<String, dynamic> toJson(PDA? pda) {
    if (pda == null) {
      return {
        'id': null,
        'type': 'pda',
        'name': null,
        'alphabet': const <String>[],
        'states': const <Map<String, dynamic>>[],
        'transitions': const <Map<String, dynamic>>[],
        'initialStateId': null,
        'stackAlphabet': const <String>[],
        'initialStackSymbol': null,
      };
    }

    final sortedStates = pda.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final sortedTransitions = pda.pdaTransitions.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final Map<String, String> stateIdMap = {};
    final statesJson = sortedStates.map((state) {
      final draw2dId = _stableStateId(pda.id, state.id);
      stateIdMap[state.id] = draw2dId;
      return _stateToJson(draw2dId, state);
    }).toList(growable: false);

    final transitionsJson = sortedTransitions.map((transition) {
      final draw2dId = _stableTransitionId(pda.id, transition.id);
      final fromId = stateIdMap[transition.fromState.id];
      final toId = stateIdMap[transition.toState.id];
      return _transitionToJson(draw2dId, fromId, toId, transition);
    }).whereNotNull().toList(growable: false);

    final initialId = pda.initialState != null
        ? stateIdMap[pda.initialState!.id]
        : null;

    return {
      'id': pda.id,
      'type': 'pda',
      'name': pda.name,
      'alphabet': pda.alphabet.toList()..sort(),
      'states': statesJson,
      'transitions': transitionsJson,
      'initialStateId': initialId,
      'stackAlphabet': pda.stackAlphabet.toList()..sort(),
      'initialStackSymbol': pda.initialStackSymbol,
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
    PDATransition transition,
  ) {
    if (fromId == null || toId == null) {
      return null;
    }

    final control = transition.controlPoint;
    final label = transition.label.isNotEmpty
        ? transition.label
        : _formatLabel(transition);

    return {
      'id': draw2dId,
      'sourceId': transition.id,
      'from': fromId,
      'to': toId,
      'label': label,
      'readSymbol': transition.inputSymbol,
      'popSymbol': transition.popSymbol,
      'pushSymbol': transition.pushSymbol,
      'isLambdaInput': transition.isLambdaInput,
      'isLambdaPop': transition.isLambdaPop,
      'isLambdaPush': transition.isLambdaPush,
      'controlPoint': {
        'x': control.x.isFinite ? control.x : 0.0,
        'y': control.y.isFinite ? control.y : 0.0,
      },
    };
  }

  static String _formatLabel(PDATransition transition) {
    final read = transition.isLambdaInput ? 'λ' : transition.inputSymbol;
    final pop = transition.isLambdaPop ? 'λ' : transition.popSymbol;
    final push = transition.isLambdaPush ? 'λ' : transition.pushSymbol;
    return '$read, $pop/$push';
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
