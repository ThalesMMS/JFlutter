import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/fsa.dart';
import '../../../core/models/fsa_transition.dart';
import '../../../core/models/state.dart';
import 'fl_nodes_canvas_models.dart';

/// Utility helpers to convert between [FSA] instances and fl_nodes snapshots.
class FlNodesAutomatonMapper {
  const FlNodesAutomatonMapper._();

  /// Converts the provided [automaton] into a snapshot consumed by the
  /// [FlNodesCanvasController].
  static FlNodesAutomatonSnapshot toSnapshot(FSA? automaton) {
    if (automaton == null) {
      return const FlNodesAutomatonSnapshot.empty();
    }

    final nodes = automaton.states.map((state) {
      return FlNodesCanvasNode(
        id: state.id,
        label: state.label,
        x: state.position.x,
        y: state.position.y,
        isInitial: automaton.initialState?.id == state.id,
        isAccepting: automaton.acceptingStates.any(
          (candidate) => candidate.id == state.id,
        ),
      );
    }).toList();

    final edges = automaton.fsaTransitions.map((transition) {
      return FlNodesCanvasEdge(
        id: transition.id,
        fromStateId: transition.fromState.id,
        toStateId: transition.toState.id,
        symbols: transition.inputSymbols.toList(),
        lambdaSymbol: transition.lambdaSymbol,
        controlPointX: transition.controlPoint.x,
        controlPointY: transition.controlPoint.y,
      );
    }).toList();

    final metadata = FlNodesAutomatonMetadata(
      id: automaton.id,
      name: automaton.name,
      alphabet: automaton.alphabet.toList(),
    );

    return FlNodesAutomatonSnapshot(
      nodes: nodes,
      edges: edges,
      metadata: metadata,
    );
  }

  /// Rebuilds an [FSA] template with the snapshot produced by the canvas.
  static FSA mergeIntoTemplate(
    FlNodesAutomatonSnapshot snapshot,
    FSA template,
  ) {
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
      return FSATransition(
        id: edge.id,
        fromState: fromState,
        toState: toState,
        inputSymbols: edge.symbols.toSet(),
        lambdaSymbol: edge.lambdaSymbol,
        label: edge.label,
        controlPoint: edge.controlPointX != null && edge.controlPointY != null
            ? Vector2(edge.controlPointX!, edge.controlPointY!)
            : null,
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

    final alphabet = <String>{
      ...template.alphabet,
      for (final edge in snapshot.edges) ...edge.symbols,
    }..removeWhere((symbol) => symbol.isEmpty);

    final initialState =
        initialNode != null ? stateMap[initialNode.id] : template.initialState;

    return template.copyWith(
      states: states,
      transitions: transitions,
      acceptingStates: acceptingStates,
      initialState: initialState,
      alphabet: alphabet,
    );
  }
}
