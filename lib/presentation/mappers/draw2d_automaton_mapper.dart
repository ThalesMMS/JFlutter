import 'package:collection/collection.dart';

import '../../core/models/fsa.dart';
import '../../features/canvas/fl_nodes/fl_nodes_automaton_mapper.dart';
import '../../features/canvas/fl_nodes/fl_nodes_canvas_models.dart';

/// Utility that converts [FSA] models into the structure expected by the
/// Draw2D canvas.
class Draw2DAutomatonMapper {
  const Draw2DAutomatonMapper._();

  static const double _stateDiameter = 60.0;
  static const double _stateRadius = _stateDiameter / 2;

  /// Converts the provided [automaton] into a Draw2D compatible JSON map.
  static Map<String, dynamic> toJson(FSA? automaton) {
    final snapshot = FlNodesAutomatonMapper.toSnapshot(automaton);

    if (snapshot.nodes.isEmpty) {
      return {
        'id': snapshot.metadata.id,
        'type': 'fsa',
        'name': snapshot.metadata.name,
        'alphabet': snapshot.metadata.alphabet.toList()..sort(),
        'states': const <Map<String, dynamic>>[],
        'transitions': const <Map<String, dynamic>>[],
        'initialStateId': null,
      };
    }

    final sortedNodes = snapshot.nodes.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final sortedEdges = snapshot.edges.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final Map<String, String> stateIdMap = {};
    final automatonId = snapshot.metadata.id ?? 'automaton';

    final statesJson = sortedNodes.map((node) {
      final draw2dId = _stableStateId(automatonId, node.id);
      stateIdMap[node.id] = draw2dId;
      return _stateToJson(draw2dId, node);
    }).toList(growable: false);

    final transitionsJson = sortedEdges.map((edge) {
      final draw2dId = _stableTransitionId(automatonId, edge.id);
      final fromId = stateIdMap[edge.fromStateId];
      final toId = stateIdMap[edge.toStateId];
      return _transitionToJson(draw2dId, fromId, toId, edge);
    }).whereNotNull().toList(growable: false);

    String? initialId;
    for (final node in sortedNodes) {
      if (node.isInitial) {
        initialId = stateIdMap[node.id];
        break;
      }
    }

    final alphabet = snapshot.metadata.alphabet.toList()..sort();

    return {
      'id': snapshot.metadata.id,
      'type': 'fsa',
      'name': snapshot.metadata.name,
      'alphabet': alphabet,
      'states': statesJson,
      'transitions': transitionsJson,
      'initialStateId': initialId,
    };
  }

  static Map<String, dynamic> _stateToJson(String id, FlNodesCanvasNode node) {
    final x = node.x.isFinite ? node.x : 0.0;
    final y = node.y.isFinite ? node.y : 0.0;
    return {
      'id': id,
      'sourceId': node.id,
      'label': node.label,
      'isInitial': node.isInitial,
      'isAccepting': node.isAccepting,
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
    FlNodesCanvasEdge edge,
  ) {
    if (fromId == null || toId == null) {
      return null;
    }

    final label = edge.label;

    final controlX = edge.controlPointX ?? 0.0;
    final controlY = edge.controlPointY ?? 0.0;
    return {
      'id': draw2dId,
      'sourceId': edge.id,
      'from': fromId,
      'to': toId,
      'label': label,
      'controlPoint': {
        'x': controlX.isFinite ? controlX : 0.0,
        'y': controlY.isFinite ? controlY : 0.0,
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
