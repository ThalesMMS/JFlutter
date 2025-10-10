//
//  graphview_canvas_controller.dart
//  JFlutter
//
//  Controlador responsável por manter o canvas GraphView de autômatos finitos
//  sincronizado com o AutomatonProvider, coordenando criação de estados,
//  transições e rótulos conforme o usuário interage. O componente também gera
//  identificadores previsíveis, trata undo/redo e aplica snapshots recebidos do
//  domínio para atualizar o grafo exibido.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/constants/automaton_canvas.dart';
import '../../../core/models/fsa.dart';
import '../../../presentation/providers/automaton_provider.dart';
import 'base_graphview_canvas_controller.dart';
import 'graphview_automaton_mapper.dart';
import 'graphview_canvas_models.dart';

void _logAutomatonCanvas(String message) {
  if (kDebugMode) {
    debugPrint('[GraphViewCanvasController] $message');
  }
}

/// Controller that keeps the [Graph] in sync with the [AutomatonProvider].
class GraphViewCanvasController
    extends BaseGraphViewCanvasController<AutomatonProvider, FSA> {
  GraphViewCanvasController({
    required AutomatonProvider automatonProvider,
    Graph? graph,
    GraphViewController? viewController,
    TransformationController? transformationController,
  }) : super(
         notifier: automatonProvider,
         graph: graph,
         viewController: viewController,
         transformationController: transformationController,
       );

  AutomatonProvider get _provider => notifier;

  @override
  FSA? get currentDomainData => _provider.state.currentAutomaton;

  @override
  GraphViewAutomatonSnapshot toSnapshot(FSA? automaton) {
    return GraphViewAutomatonMapper.toSnapshot(automaton);
  }

  /// Synchronises the GraphView controller with the latest [automaton].
  void synchronize(FSA? automaton) {
    _logAutomatonCanvas(
      'Synchronizing canvas with automaton id=${automaton?.id} states=${automaton?.states.length ?? 0} transitions=${automaton?.transitions.length ?? 0}',
    );
    synchronizeGraph(automaton);
  }

  String _generateNodeId() {
    final reservedIds = <String>{...nodesCache.keys};
    final automaton = _provider.state.currentAutomaton;
    if (automaton != null) {
      for (final state in automaton.states) {
        reservedIds.add(state.id);
      }
    }
    var index = 0;
    while (true) {
      final candidate = 'state_$index';
      if (!reservedIds.contains(candidate)) {
        return candidate;
      }
      index++;
    }
  }

  String _generateEdgeId() {
    final reservedIds = <String>{...edgesCache.keys};
    final automaton = _provider.state.currentAutomaton;
    if (automaton != null) {
      for (final transition in automaton.transitions) {
        reservedIds.add(transition.id);
      }
    }
    var index = 0;
    while (true) {
      final candidate = 'transition_$index';
      if (!reservedIds.contains(candidate)) {
        return candidate;
      }
      index++;
    }
  }

  String _nextAvailableStateLabel() {
    final reservedLabels = <String>{};

    final automaton = _provider.state.currentAutomaton;
    if (automaton != null) {
      for (final state in automaton.states) {
        final label = state.label.trim();
        if (label.isNotEmpty) {
          reservedLabels.add(label);
        }
      }
    }

    for (final node in nodesCache.values) {
      final label = node.label.trim();
      if (label.isNotEmpty) {
        reservedLabels.add(label);
      }
    }

    var index = 0;
    while (reservedLabels.contains('q$index')) {
      index++;
    }
    return 'q$index';
  }

  /// Adds a new state centred in the current viewport.
  void addStateAtCenter() {
    _logAutomatonCanvas('addStateAtCenter requested');
    final worldCenter = resolveViewportCenterWorld();
    addStateAt(worldCenter);
  }

  /// Adds a new state at the provided [worldPosition].
  void addStateAt(Offset worldPosition) {
    final nodeId = _generateNodeId();
    final label = _nextAvailableStateLabel();
    final isFirstState =
        nodesCache.isEmpty &&
        (_provider.state.currentAutomaton?.states.isEmpty ?? true);

    _logAutomatonCanvas(
      'addStateAt -> id=$nodeId label=$label position=(${worldPosition.dx.toStringAsFixed(2)}, ${worldPosition.dy.toStringAsFixed(2)}) isFirstState=$isFirstState',
    );
    performMutation(() {
      _provider.addState(
        id: nodeId,
        label: label,
        x: worldPosition.dx,
        y: worldPosition.dy,
        isInitial: isFirstState ? true : null,
        isAccepting: false,
      );
    });
  }

  /// Moves an existing state to a new [position].
  void moveState(String id, Offset position) {
    _logAutomatonCanvas(
      'moveState -> id=$id position=(${position.dx.toStringAsFixed(2)}, ${position.dy.toStringAsFixed(2)})',
    );
    performMutation(() {
      _provider.moveState(id: id, x: position.dx, y: position.dy);
    });
  }

  /// Updates the label displayed for the state identified by [id].
  void updateStateLabel(String id, String label) {
    final resolvedLabel = label.isEmpty ? id : label;
    _logAutomatonCanvas('updateStateLabel -> id=$id label=$resolvedLabel');
    performMutation(() {
      _provider.updateStateLabel(id: id, label: resolvedLabel);
    });
  }

  /// Removes the state identified by [id] from the automaton.
  void removeState(String id) {
    _logAutomatonCanvas('removeState -> id=$id');
    performMutation(() {
      _provider.removeState(id: id);
    });
  }

  /// Updates the initial/final flags associated with the state [id].
  void updateStateFlags(String id, {bool? isInitial, bool? isAccepting}) {
    _logAutomatonCanvas(
      'updateStateFlags -> id=$id isInitial=$isInitial isAccepting=$isAccepting',
    );
    if (isInitial == null && isAccepting == null) {
      return;
    }
    performMutation(() {
      _provider.updateStateFlags(
        id: id,
        isInitial: isInitial,
        isAccepting: isAccepting,
      );
    });
  }

  /// Adds or updates a transition between [fromStateId] and [toStateId].
  void addOrUpdateTransition({
    required String fromStateId,
    required String toStateId,
    required String label,
    String? transitionId,
    double? controlPointX,
    double? controlPointY,
  }) {
    final edgeId = transitionId ?? _generateEdgeId();
    _logAutomatonCanvas(
      'addOrUpdateTransition -> id=$edgeId from=$fromStateId to=$toStateId label=$label cp=(${controlPointX?.toStringAsFixed(2)}, ${controlPointY?.toStringAsFixed(2)})',
    );
    performMutation(() {
      _provider.addOrUpdateTransition(
        id: edgeId,
        fromStateId: fromStateId,
        toStateId: toStateId,
        label: label,
        controlPointX: controlPointX,
        controlPointY: controlPointY,
      );
    });
  }

  /// Removes the transition identified by [id] from the automaton.
  void removeTransition(String id) {
    _logAutomatonCanvas('removeTransition -> id=$id');
    performMutation(() {
      _provider.removeTransition(id: id);
    });
  }

  /// Recomputes state positions using the Sugiyama layout algorithm.
  void applySugiyamaLayout() {
    final automaton = _provider.state.currentAutomaton;
    if (automaton == null) {
      _logAutomatonCanvas('applySugiyamaLayout ignored (no automaton)');
      return;
    }
    if (nodesCache.isEmpty) {
      _logAutomatonCanvas('applySugiyamaLayout ignored (empty graph)');
      return;
    }

    final configuration = SugiyamaConfiguration()
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
      ..nodeSeparation = 160
      ..levelSeparation = 160
      ..bendPointShape = CurvedBendPointShape(curveLength: 40);

    final layoutGraph = Graph()..isTree = graph.isTree;

    final nodeMap = <String, Node>{};
    for (final entry in nodesCache.entries) {
      final node = Node.Id(entry.key)
        ..size = const Size(kAutomatonStateDiameter, kAutomatonStateDiameter)
        ..position = Offset(entry.value.x, entry.value.y);
      nodeMap[entry.key] = node;
      layoutGraph.addNode(node);
    }

    for (final edge in edgesCache.values) {
      final from = nodeMap[edge.fromStateId];
      final to = nodeMap[edge.toStateId];
      if (from == null || to == null) {
        continue;
      }
      layoutGraph.addEdgeS(Edge(from, to));
    }

    final algorithm = SugiyamaAlgorithm(configuration);
    algorithm.run(layoutGraph, 0, 0);

    final updatedNodes = <GraphViewCanvasNode>[];
    for (final entry in nodeMap.entries) {
      final cached = nodesCache[entry.key];
      if (cached == null) {
        continue;
      }
      final position = entry.value.position;
      final hasFiniteCoordinates =
          position.dx.isFinite && position.dy.isFinite;
      final resolvedPosition = hasFiniteCoordinates
          ? position
          : Offset(cached.x, cached.y);
      updatedNodes.add(
        cached.copyWith(
          x: resolvedPosition.dx,
          y: resolvedPosition.dy,
        ),
      );
    }

    final snapshot = GraphViewAutomatonSnapshot(
      nodes: updatedNodes,
      edges: edgesCache.values.toList(growable: false),
      metadata: GraphViewAutomatonMetadata(
        id: automaton.id,
        name: automaton.name,
        alphabet: automaton.alphabet.toList(growable: false),
      ),
    );

    _logAutomatonCanvas(
      'applySugiyamaLayout -> nodes=${snapshot.nodes.length}',
    );

    performMutation(() {
      applySnapshotToDomain(snapshot);
    });
  }

  @override
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot) {
    final template =
        _provider.state.currentAutomaton ??
        FSA(
          id:
              snapshot.metadata.id ??
              'automaton_${DateTime.now().microsecondsSinceEpoch}',
          name: snapshot.metadata.name ?? 'Untitled Automaton',
          states: const {},
          transitions: const {},
          alphabet: snapshot.metadata.alphabet.toSet(),
          initialState: null,
          acceptingStates: const {},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          panOffset: Vector2.zero(),
          zoomLevel: 1.0,
        );

    final merged =
        GraphViewAutomatonMapper.mergeIntoTemplate(snapshot, template).copyWith(
          id: snapshot.metadata.id ?? template.id,
          name: snapshot.metadata.name ?? template.name,
          alphabet: snapshot.metadata.alphabet.isNotEmpty
              ? snapshot.metadata.alphabet.toSet()
              : template.alphabet,
          modified: DateTime.now(),
        );

    _logAutomatonCanvas(
      'applySnapshotToDomain -> states=${merged.states.length} transitions=${merged.transitions.length}',
    );
    _provider.updateAutomaton(merged);
    synchronize(merged);
  }
}
