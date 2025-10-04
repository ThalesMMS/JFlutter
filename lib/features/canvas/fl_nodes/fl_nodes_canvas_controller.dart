import 'dart:math' as math;

import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/fsa.dart';
import '../../../core/constants/automaton_canvas.dart';
import '../../../presentation/providers/automaton_provider.dart';
import 'base_fl_nodes_canvas_controller.dart';
import 'fl_nodes_automaton_mapper.dart';
import 'fl_nodes_canvas_models.dart';

/// Controller that keeps the [FlNodeEditorController] in sync with the
/// [AutomatonProvider].
class FlNodesCanvasController extends BaseFlNodesCanvasController<AutomatonProvider, FSA> {
  FlNodesCanvasController({
    required AutomatonProvider automatonProvider,
    FlNodeEditorController? editorController,
  }) : super(
          notifier: automatonProvider,
          editorController: editorController,
        );

  AutomatonProvider get _provider => notifier;

  @override
  FSA? get currentDomainData => _provider.state.currentAutomaton;

  @override
  String get statePrototypeId => 'automaton_state';

  @override
  String get stateDescription => 'Estado do autômato finito';

  @override
  FlNodesAutomatonSnapshot toSnapshot(FSA? automaton) {
    return FlNodesAutomatonMapper.toSnapshot(automaton);
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

  @override
  FlNodesCanvasNode createCanvasNode(NodeInstance node) {
    final label = _nextAvailableStateLabel();
    final labelField =
        node.fields[BaseFlNodesCanvasController.labelFieldId];
    if (labelField != null) {
      labelField.data = label;
    }
    final resolvedLabel = resolveLabel(node);
    final isFirstState = nodesCache.isEmpty;
    return FlNodesCanvasNode(
      id: node.id,
      label: resolvedLabel,
      x: node.offset.dx,
      y: node.offset.dy,
      isInitial: isFirstState,
      isAccepting: false,
    );
  }

  @override
  void onCanvasNodeAdded(FlNodesCanvasNode node) {
    performMutation(() {
      _provider.addState(
        id: node.id,
        label: node.label,
        x: node.x,
        y: node.y,
        isInitial: node.isInitial ? true : null,
        isAccepting: node.isAccepting,
      );
    });
  }

  @override
  void onCanvasNodeRemoved(String nodeId) {
    performMutation(() {
      _provider.removeState(id: nodeId);
    });
  }

  @override
  void onCanvasNodesMoved(Map<String, FlNodesCanvasNode> updatedNodes) {
    performMutation(() {
      for (final entry in updatedNodes.entries) {
        _provider.moveState(
          id: entry.key,
          x: entry.value.x,
          y: entry.value.y,
        );
      }
    });
  }

  @override
  void onCanvasNodeLabelUpdated(FlNodesCanvasNode node) {
    performMutation(() {
      _provider.updateStateLabel(
        id: node.id,
        label: node.label.isEmpty ? node.id : node.label,
      );
    });
  }

  @override
  FlNodesCanvasEdge? createEdgeForLink(Link link) {
    final fromStateId = link.fromTo.from;
    final toStateId = link.fromTo.to;

    final fromNode = nodeById(fromStateId);
    final toNode = nodeById(toStateId);

    Offset? controlPoint;
    if (fromNode != null && toNode != null) {
      final existingParallel = edgesCache.values.where(
        (edge) =>
            edge.fromStateId == fromStateId && edge.toStateId == toStateId,
      );
      final index = existingParallel.length;

      if (fromStateId == toStateId) {
        controlPoint = _computeLoopControlPoint(fromNode, index);
      } else {
        controlPoint = _computeParallelControlPoint(
          fromNode,
          toNode,
          index,
        );
      }
    }

    return FlNodesCanvasEdge(
      id: link.id,
      fromStateId: fromStateId,
      toStateId: toStateId,
      symbols: const <String>[],
      lambdaSymbol: null,
      controlPointX: controlPoint?.dx,
      controlPointY: controlPoint?.dy,
    );
  }

  @override
  void onCanvasEdgeAdded(FlNodesCanvasEdge edge) {
    performMutation(() {
      _provider.addOrUpdateTransition(
        id: edge.id,
        fromStateId: edge.fromStateId,
        toStateId: edge.toStateId,
        label: edge.label,
        controlPointX: edge.controlPointX,
        controlPointY: edge.controlPointY,
      );
    });
  }

  @override
  void onCanvasEdgeRemoved(String edgeId) {
    performMutation(() {
      _provider.removeTransition(id: edgeId);
    });
  }

  @override
  void onCanvasEdgeGeometryUpdated(FlNodesCanvasEdge edge, Offset controlPoint) {
    performMutation(() {
      _provider.addOrUpdateTransition(
        id: edge.id,
        fromStateId: edge.fromStateId,
        toStateId: edge.toStateId,
        label: edge.label,
        controlPointX: controlPoint.dx,
        controlPointY: controlPoint.dy,
      );
    });
  }

  Offset _nodeCenter(FlNodesCanvasNode node) {
    const radius = kAutomatonStateDiameter / 2;
    return Offset(node.x + radius, node.y + radius);
  }

  Offset _computeLoopControlPoint(FlNodesCanvasNode node, int index) {
    final center = _nodeCenter(node);
    final radius = kAutomatonStateDiameter / 2;
    const double angleStep = math.pi / 8;
    const double baseAngle = -math.pi / 2;

    double angle;
    if (index == 0) {
      angle = baseAngle;
    } else {
      final tier = (index + 1) ~/ 2;
      final sign = index.isOdd ? 1 : -1;
      angle = baseAngle + sign * angleStep * tier;
    }

    final distance = radius * 2.2 + 24 * ((index + 1) ~/ 2);
    return center + Offset(math.cos(angle), math.sin(angle)) * distance;
  }

  Offset? _computeParallelControlPoint(
    FlNodesCanvasNode fromNode,
    FlNodesCanvasNode toNode,
    int index,
  ) {
    if (index == 0) {
      return null;
    }

    final start = _nodeCenter(fromNode);
    final end = _nodeCenter(toNode);
    final direction = end - start;
    if (direction.distanceSquared == 0) {
      return _computeLoopControlPoint(fromNode, index);
    }

    final normal = Offset(-direction.dy, direction.dx);
    final normalised = _normalise(normal);
    if (normalised == Offset.zero) {
      return null;
    }

    final midPoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final tier = (index + 1) ~/ 2;
    final sign = index.isOdd ? 1 : -1;
    final distance = direction.distance;
    final baseOffset = ((distance / 3).clamp(48.0, 160.0)) as double;
    final magnitude = baseOffset * tier * sign;

    return midPoint + normalised * magnitude;
  }

  Offset _normalise(Offset vector) {
    final length = vector.distance;
    if (length == 0) {
      return Offset.zero;
    }
    return vector / length;
  }

  /// Synchronises the fl_nodes controller with the latest [automaton].
  void synchronize(FSA? automaton) {
    synchronizeCanvas(automaton);
  }

  @override
  void applySnapshotToDomain(FlNodesAutomatonSnapshot snapshot) {
    final template = _provider.state.currentAutomaton ??
        FSA(
          id: snapshot.metadata.id ?? 'automaton_${DateTime.now().microsecondsSinceEpoch}',
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

    final merged = FlNodesAutomatonMapper.mergeIntoTemplate(snapshot, template)
        .copyWith(
      id: snapshot.metadata.id ?? template.id,
      name: snapshot.metadata.name ?? template.name,
      alphabet: snapshot.metadata.alphabet.isNotEmpty
          ? snapshot.metadata.alphabet.toSet()
          : template.alphabet,
      modified: DateTime.now(),
    );

    _provider.updateAutomaton(merged);
    synchronize(merged);
  }
}
