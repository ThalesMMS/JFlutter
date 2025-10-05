import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/tm.dart';
import '../../../core/models/tm_transition.dart';
import '../../../presentation/providers/tm_editor_provider.dart';
import 'base_graphview_canvas_controller.dart';
import 'graphview_canvas_models.dart';
import 'graphview_tm_mapper.dart';

void _logTmCanvas(String message) {
  if (kDebugMode) {
    debugPrint('[GraphViewTmCanvasController] $message');
  }
}

/// Controller responsible for synchronising GraphView with the
/// [TMEditorNotifier].
class GraphViewTmCanvasController
    extends BaseGraphViewCanvasController<TMEditorNotifier, TM> {
  GraphViewTmCanvasController({
    required TMEditorNotifier editorNotifier,
    Graph? graph,
    GraphViewController? viewController,
    TransformationController? transformationController,
  }) : super(
          notifier: editorNotifier,
          graph: graph,
          viewController: viewController,
          transformationController: transformationController,
        );

  TMEditorNotifier get _notifier => notifier;

  @override
  TM? get currentDomainData => _notifier.state.tm;

  @override
  GraphViewAutomatonSnapshot toSnapshot(TM? machine) {
    return GraphViewTmMapper.toSnapshot(machine);
  }

  /// Synchronises the GraphView controller with the latest [machine].
  void synchronize(TM? machine) {
    _logTmCanvas(
      'Synchronizing TM canvas (states=${machine?.states.length ?? 0}, transitions=${machine?.tmTransitions.length ?? 0})',
    );
    synchronizeGraph(machine);
  }

  String _generateNodeId() {
    final reservedIds = <String>{...nodesCache.keys};
    final machine = _notifier.state.tm;
    if (machine != null) {
      for (final state in machine.states) {
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
    final machine = _notifier.state.tm;
    if (machine != null) {
      for (final transition in machine.tmTransitions) {
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
    final machine = _notifier.state.tm;
    if (machine != null) {
      for (final state in machine.states) {
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
    _logTmCanvas('addStateAtCenter requested');
    addStateAt(Offset.zero);
  }

  /// Adds a new state at the provided [worldPosition].
  void addStateAt(Offset worldPosition) {
    final nodeId = _generateNodeId();
    final label = _nextAvailableStateLabel();
    _logTmCanvas(
      'addStateAt -> id=$nodeId label=$label position=(${worldPosition.dx.toStringAsFixed(2)}, ${worldPosition.dy.toStringAsFixed(2)})',
    );
    performMutation(() {
      _notifier.upsertState(
        id: nodeId,
        label: label,
        x: worldPosition.dx,
        y: worldPosition.dy,
      );
    });
  }

  /// Moves an existing state to a new [position].
  void moveState(String id, Offset position) {
    _logTmCanvas(
      'moveState -> id=$id position=(${position.dx.toStringAsFixed(2)}, ${position.dy.toStringAsFixed(2)})',
    );
    performMutation(() {
      _notifier.moveState(
        id: id,
        x: position.dx,
        y: position.dy,
      );
    });
  }

  /// Updates the label displayed for the state identified by [id].
  void updateStateLabel(String id, String label) {
    final resolvedLabel = label.isEmpty ? id : label;
    _logTmCanvas('updateStateLabel -> id=$id label=$resolvedLabel');
    performMutation(() {
      _notifier.updateStateLabel(
        id: id,
        label: resolvedLabel,
      );
    });
  }

  /// Updates the flag metadata for the state identified by [id].
  void updateStateFlags(String id, {bool? isInitial, bool? isAccepting}) {
    _logTmCanvas(
      'updateStateFlags -> id=$id isInitial=$isInitial isAccepting=$isAccepting',
    );
    performMutation(() {
      _notifier.updateStateFlags(
        id: id,
        isInitial: isInitial,
        isAccepting: isAccepting,
      );
    });
  }

  /// Removes the state identified by [id] from the machine.
  void removeState(String id) {
    _logTmCanvas('removeState -> id=$id');
    performMutation(() {
      _notifier.removeState(id: id);
    });
  }

  /// Adds or updates a TM transition between [fromStateId] and [toStateId].
  void addOrUpdateTransition({
    required String fromStateId,
    required String toStateId,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    String? transitionId,
    double? controlPointX,
    double? controlPointY,
  }) {
    final edgeId = transitionId ?? _generateEdgeId();
    final controlPoint = (controlPointX != null && controlPointY != null)
        ? Vector2(controlPointX, controlPointY)
        : null;
    _logTmCanvas(
      'addOrUpdateTransition -> id=$edgeId from=$fromStateId to=$toStateId read=$readSymbol write=$writeSymbol dir=$direction cp=${controlPoint?.toString()}',
    );
    performMutation(() {
      _notifier.addOrUpdateTransition(
        id: edgeId,
        fromStateId: fromStateId,
        toStateId: toStateId,
        readSymbol: readSymbol,
        writeSymbol: writeSymbol,
        direction: direction,
        controlPoint: controlPoint,
      );
    });
  }

  /// Updates the control point for the transition identified by [id].
  void updateTransitionControlPoint(
    String id,
    double controlPointX,
    double controlPointY,
  ) {
    final edge = edgeById(id);
    if (edge == null) {
      _logTmCanvas('updateTransitionControlPoint skipped -> id=$id (edge not found)');
      return;
    }

    _logTmCanvas(
      'updateTransitionControlPoint -> id=$id cp=(${controlPointX.toStringAsFixed(2)}, ${controlPointY.toStringAsFixed(2)})',
    );
    addOrUpdateTransition(
      fromStateId: edge.fromStateId,
      toStateId: edge.toStateId,
      readSymbol: edge.readSymbol,
      writeSymbol: edge.writeSymbol,
      direction: edge.direction,
      transitionId: id,
      controlPointX: controlPointX,
      controlPointY: controlPointY,
    );
  }

  /// Removes the transition identified by [id] from the machine.
  void removeTransition(String id) {
    _logTmCanvas('removeTransition -> id=$id');
    performMutation(() {
      _notifier.removeTransition(id: id);
    });
  }

  @override
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot) {
    final template = _notifier.state.tm ??
        TM(
          id: snapshot.metadata.id ??
              'tm_${DateTime.now().microsecondsSinceEpoch}',
          name: snapshot.metadata.name ?? 'Canvas TM',
          states: const {},
          transitions: const {},
          alphabet: snapshot.metadata.alphabet.toSet(),
          initialState: null,
          acceptingStates: const {},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          tapeAlphabet: snapshot.metadata.alphabet.toSet().isEmpty
              ? const {'B'}
              : snapshot.metadata.alphabet.toSet(),
          blankSymbol: 'B',
          tapeCount: 1,
          panOffset: Vector2.zero(),
          zoomLevel: 1.0,
        );

    final merged = GraphViewTmMapper.mergeIntoTemplate(snapshot, template)
        .copyWith(
      id: snapshot.metadata.id ?? template.id,
      name: snapshot.metadata.name ?? template.name,
      tapeAlphabet: snapshot.metadata.alphabet.isNotEmpty
          ? snapshot.metadata.alphabet.toSet()
          : template.tapeAlphabet,
      modified: DateTime.now(),
    );

    _logTmCanvas(
      'applySnapshotToDomain -> states=${merged.states.length} transitions=${merged.tmTransitions.length}',
    );
    _notifier.setTm(merged);
    synchronize(merged);
  }
}
