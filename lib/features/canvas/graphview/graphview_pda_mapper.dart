//
//  graphview_pda_mapper.dart
//  JFlutter
//
//  Utilitário que traduz autômatos de pilha para snapshots manipulados pelo
//  GraphView e recompõe modelos do domínio durante salvamentos do canvas. O
//  código mantém estados, símbolos de entrada e de pilha, além de inferir
//  marcadores lambda ao reconstruir as transições.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/pda.dart';
import '../../../core/models/pda_transition.dart';
import '../../../core/models/state.dart';
import '../../../core/models/transition.dart';
import 'graphview_canvas_models.dart';

/// Converts between [PDA] instances and GraphView snapshots consumed by the PDA
/// canvas controller.
class GraphViewPdaMapper {
  const GraphViewPdaMapper._();

  /// Formats a PDA transition label in the format: input, pop/push
  /// Lambda transitions are represented as λ
  static String formatPdaTransitionLabel({
    required String inputSymbol,
    required String popSymbol,
    required String pushSymbol,
    required bool isLambdaInput,
    required bool isLambdaPop,
    required bool isLambdaPush,
  }) {
    final input = isLambdaInput ? 'λ' : inputSymbol;
    final pop = isLambdaPop ? 'λ' : popSymbol;
    final push = isLambdaPush ? 'λ' : pushSymbol;
    return '$input, $pop/$push';
  }

  /// Converts the provided [automaton] into a GraphView snapshot.
  static GraphViewAutomatonSnapshot toSnapshot(PDA? automaton) {
    if (automaton == null) {
      return const GraphViewAutomatonSnapshot.empty();
    }

    final nodes = automaton.states.map((state) {
      return GraphViewCanvasNode(
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

    final edges = automaton.pdaTransitions.map((transition) {
      return GraphViewCanvasEdge(
        id: transition.id,
        fromStateId: transition.fromState.id,
        toStateId: transition.toState.id,
        symbols: const <String>[],
        controlPointX: transition.controlPoint.x,
        controlPointY: transition.controlPoint.y,
        readSymbol: transition.inputSymbol,
        popSymbol: transition.popSymbol,
        pushSymbol: transition.pushSymbol,
        isLambdaInput: transition.isLambdaInput,
        isLambdaPop: transition.isLambdaPop,
        isLambdaPush: transition.isLambdaPush,
      );
    }).toList();

    final metadata = GraphViewAutomatonMetadata(
      id: automaton.id,
      name: automaton.name,
      alphabet: automaton.alphabet.toList(),
    );

    return GraphViewAutomatonSnapshot(
      nodes: nodes,
      edges: edges,
      metadata: metadata,
    );
  }

  /// Rebuilds a [PDA] template with the data contained in [snapshot].
  static PDA mergeIntoTemplate(
    GraphViewAutomatonSnapshot snapshot,
    PDA template,
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

      final isLambdaInput =
          edge.isLambdaInput ?? (edge.readSymbol?.isEmpty ?? true);
      final isLambdaPop = edge.isLambdaPop ?? (edge.popSymbol?.isEmpty ?? true);
      final isLambdaPush =
          edge.isLambdaPush ?? (edge.pushSymbol?.isEmpty ?? true);

      final inputSymbol = edge.readSymbol ?? '';
      final popSymbol = edge.popSymbol ?? '';
      final pushSymbol = edge.pushSymbol ?? '';

      final label = formatPdaTransitionLabel(
        inputSymbol: inputSymbol,
        popSymbol: popSymbol,
        pushSymbol: pushSymbol,
        isLambdaInput: isLambdaInput,
        isLambdaPop: isLambdaPop,
        isLambdaPush: isLambdaPush,
      );

      return PDATransition(
        id: edge.id,
        fromState: fromState,
        toState: toState,
        label: label,
        controlPoint: controlPoint,
        type: TransitionType.deterministic,
        inputSymbol: inputSymbol,
        popSymbol: popSymbol,
        pushSymbol: pushSymbol,
        isLambdaInput: isLambdaInput,
        isLambdaPop: isLambdaPop,
        isLambdaPush: isLambdaPush,
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
        if (!(edge.isLambdaInput ?? false) &&
            (edge.readSymbol != null && edge.readSymbol!.isNotEmpty))
          edge.readSymbol!,
    };

    final stackAlphabet = <String>{
      ...template.stackAlphabet,
      for (final edge in snapshot.edges)
        if (!(edge.isLambdaPop ?? false) &&
            (edge.popSymbol != null && edge.popSymbol!.isNotEmpty))
          edge.popSymbol!,
      for (final edge in snapshot.edges)
        if (!(edge.isLambdaPush ?? false) &&
            (edge.pushSymbol != null && edge.pushSymbol!.isNotEmpty))
          edge.pushSymbol!,
    };

    final initialState = initialNode != null
        ? stateMap[initialNode.id]
        : template.initialState;

    return template.copyWith(
      states: states,
      transitions: transitions.map<Transition>((t) => t).toSet(),
      acceptingStates: acceptingStates,
      initialState: initialState,
      alphabet: alphabet,
      stackAlphabet: stackAlphabet,
    );
  }
}
