import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/state.dart';
import '../../../core/models/tm.dart';
import '../../../core/models/tm_transition.dart';
import '../../../core/models/transition.dart';
import 'fl_nodes_canvas_models.dart';

/// Converts between [TM] instances and fl_nodes snapshots consumed by the TM
/// canvas controller.
class FlNodesTmMapper {
  const FlNodesTmMapper._();

  static FlNodesAutomatonSnapshot toSnapshot(TM? machine) {
    if (machine == null) {
      return const FlNodesAutomatonSnapshot.empty();
    }

    final nodes = machine.states.map((state) {
      return FlNodesCanvasNode(
        id: state.id,
        label: state.label,
        x: state.position.x,
        y: state.position.y,
        isInitial: state.isInitial,
        isAccepting: state.isAccepting,
      );
    }).toList();

    final edges = machine.transitions.whereType<TMTransition>().map((transition) {
      final controlPoint = transition.controlPoint;
      return FlNodesCanvasEdge(
        id: transition.id,
        fromStateId: transition.fromState.id,
        toStateId: transition.toState.id,
        symbols: transition.readSymbol.isEmpty
            ? const <String>[]
            : <String>[transition.readSymbol],
        controlPointX: controlPoint.x,
        controlPointY: controlPoint.y,
        readSymbol: transition.readSymbol,
        writeSymbol: transition.writeSymbol,
        direction: transition.direction,
        tapeNumber: transition.tapeNumber,
      );
    }).toList();

    final metadata = FlNodesAutomatonMetadata(
      id: machine.id,
      name: machine.name,
      alphabet: machine.tapeAlphabet.toList(),
    );

    return FlNodesAutomatonSnapshot(
      nodes: nodes,
      edges: edges,
      metadata: metadata,
    );
  }

  static TM mergeIntoTemplate(FlNodesAutomatonSnapshot snapshot, TM template) {
    final states = snapshot.nodes
        .map(
          (node) => State(
            id: node.id,
            label: node.label,
            position: Vector2(node.x, node.y),
            isInitial: node.isInitial,
            isAccepting: node.isAccepting,
          ),
        )
        .toSet();

    final stateMap = {for (final state in states) state.id: state};

    final transitions = snapshot.edges.map((edge) {
      final fromState = stateMap[edge.fromStateId];
      final toState = stateMap[edge.toStateId];
      if (fromState == null || toState == null) {
        throw StateError('Edge references missing state: ${edge.toJson()}');
      }
      final readSymbol = edge.readSymbol ??
          (edge.symbols.isNotEmpty ? edge.symbols.first : '');
      return TMTransition(
        id: edge.id,
        fromState: fromState,
        toState: toState,
        label: edge.label,
        controlPoint: (edge.controlPointX != null && edge.controlPointY != null)
            ? Vector2(edge.controlPointX!, edge.controlPointY!)
            : Vector2.zero(),
        readSymbol: readSymbol,
        writeSymbol: edge.writeSymbol ?? '',
        direction: edge.direction ?? TapeDirection.right,
        tapeNumber: edge.tapeNumber ?? 0,
      );
    }).toSet();

    final acceptingStates = {
      for (final node in snapshot.nodes.where((node) => node.isAccepting))
        stateMap[node.id]!,
    };

    FlNodesCanvasNode? initialNode;
    for (final node in snapshot.nodes) {
      if (node.isInitial) {
        initialNode = node;
        break;
      }
    }
    initialNode ??= snapshot.nodes.isNotEmpty ? snapshot.nodes.first : null;

    final resolvedInitialState =
        initialNode != null ? stateMap[initialNode.id] : template.initialState;

    final tapeAlphabet = <String>{
      ...template.tapeAlphabet,
      ...snapshot.edges
          .expand((edge) => [edge.readSymbol, edge.writeSymbol])
          .whereType<String>(),
    };

    return template.copyWith(
      states: states,
      transitions: transitions.map<Transition>((t) => t).toSet(),
      acceptingStates: acceptingStates,
      initialState: resolvedInitialState,
      tapeAlphabet: tapeAlphabet,
    );
  }
}
