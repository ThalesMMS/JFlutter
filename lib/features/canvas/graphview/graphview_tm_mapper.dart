//
//  graphview_tm_mapper.dart
//  JFlutter
//
//  Utilitário que converte máquinas de Turing em snapshots compatíveis com o
//  GraphView e reidrata modelos do domínio a partir de edições visuais. O
//  mapeamento preserva estados, transições, direção de fita e alfabetos para
//  garantir consistência entre a camada visual e os dados centrais.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/state.dart';
import '../../../core/models/tm.dart';
import '../../../core/models/tm_transition.dart';
import '../../../core/models/transition.dart';
import 'graphview_canvas_models.dart';

/// Converts between [TM] instances and GraphView snapshots consumed by the TM
/// canvas controller.
class GraphViewTmMapper {
  const GraphViewTmMapper._();

  /// Converts the provided Turing Machine into a GraphView snapshot.
  static GraphViewAutomatonSnapshot toSnapshot(TM? machine) {
    if (machine == null) {
      return const GraphViewAutomatonSnapshot.empty();
    }

    final nodes = machine.states.map((state) {
      return GraphViewCanvasNode(
        id: state.id,
        label: state.label,
        x: state.position.x,
        y: state.position.y,
        isInitial: machine.initialState?.id == state.id,
        isAccepting: machine.acceptingStates.any(
          (candidate) => candidate.id == state.id,
        ),
      );
    }).toList();

    final edges = machine.tmTransitions.map((transition) {
      return GraphViewCanvasEdge(
        id: transition.id,
        fromStateId: transition.fromState.id,
        toStateId: transition.toState.id,
        symbols: const <String>[],
        controlPointX: transition.controlPoint.x,
        controlPointY: transition.controlPoint.y,
        readSymbol: transition.readSymbol,
        writeSymbol: transition.writeSymbol,
        direction: transition.direction,
        tapeNumber: transition.tapeNumber,
      );
    }).toList();

    final metadata = GraphViewAutomatonMetadata(
      id: machine.id,
      name: machine.name,
      alphabet: machine.alphabet.toList(),
    );

    return GraphViewAutomatonSnapshot(
      nodes: nodes,
      edges: edges,
      metadata: metadata,
    );
  }

  /// Rebuilds a [TM] template using the data contained in [snapshot].
  static TM mergeIntoTemplate(
    GraphViewAutomatonSnapshot snapshot,
    TM template,
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

      final controlPoint =
          (edge.controlPointX != null && edge.controlPointY != null)
              ? Vector2(edge.controlPointX!, edge.controlPointY!)
              : Vector2.zero();

      final direction = edge.direction ?? TapeDirection.right;

      return TMTransition(
        id: edge.id,
        fromState: fromState,
        toState: toState,
        label: edge.label,
        controlPoint: controlPoint,
        readSymbol: edge.readSymbol ?? '',
        writeSymbol: edge.writeSymbol ?? '',
        direction: direction,
        tapeNumber: edge.tapeNumber ?? 0,
      );
    }).toSet();

    final acceptingStates = {
      for (final node in snapshot.nodes.where((node) => node.isAccepting))
        stateMap[node.id]!,
    };

    GraphViewCanvasNode? initialNode;
    for (final node in snapshot.nodes) {
      if (node.isInitial) {
        initialNode = node;
        break;
      }
    }

    final alphabet = <String>{
      ...template.alphabet,
      for (final edge in snapshot.edges)
        if (edge.readSymbol != null && edge.readSymbol!.isNotEmpty)
          edge.readSymbol!,
      for (final edge in snapshot.edges)
        if (edge.writeSymbol != null && edge.writeSymbol!.isNotEmpty)
          edge.writeSymbol!,
    };

    final initialState =
        initialNode != null ? stateMap[initialNode.id] : template.initialState;

    return template.copyWith(
      states: states,
      transitions: transitions.map<Transition>((t) => t).toSet(),
      acceptingStates: acceptingStates,
      initialState: initialState,
      alphabet: alphabet,
    );
  }
}
