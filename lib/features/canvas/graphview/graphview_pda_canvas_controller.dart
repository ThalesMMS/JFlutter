/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/features/canvas/graphview/graphview_pda_canvas_controller.dart
/// Descrição: Coordena o canvas GraphView para autômatos de pilha, gerenciando
///            sincronização, seleção e manipulação visual das estruturas PDA.
/// ---------------------------------------------------------------------------
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/pda.dart';
import '../../../presentation/providers/pda_editor_provider.dart';
import 'base_graphview_canvas_controller.dart';
import 'graphview_canvas_models.dart';
import 'graphview_pda_mapper.dart';

void _logPdaCanvas(String message) {
  if (kDebugMode) {
    debugPrint('[GraphViewPdaCanvasController] $message');
  }
}

/// Controller responsible for synchronising GraphView with the
/// [PDAEditorNotifier].
class GraphViewPdaCanvasController
    extends BaseGraphViewCanvasController<PDAEditorNotifier, PDA> {
  GraphViewPdaCanvasController({
    required PDAEditorNotifier editorNotifier,
    Graph? graph,
    GraphViewController? viewController,
    TransformationController? transformationController,
  }) : super(
          notifier: editorNotifier,
          graph: graph,
          viewController: viewController,
          transformationController: transformationController,
        );

  PDAEditorNotifier get _notifier => notifier;

  @override
  PDA? get currentDomainData => _notifier.state.pda;

  @override
  GraphViewAutomatonSnapshot toSnapshot(PDA? automaton) {
    return GraphViewPdaMapper.toSnapshot(automaton);
  }

  /// Synchronises the GraphView controller with the latest [automaton].
  void synchronize(PDA? automaton) {
    _logPdaCanvas(
      'Synchronizing PDA canvas (states=${automaton?.states.length ?? 0}, transitions=${automaton?.pdaTransitions.length ?? 0})',
    );
    synchronizeGraph(automaton);
  }

  String _generateNodeId() {
    final reservedIds = <String>{...nodesCache.keys};
    final automaton = _notifier.state.pda;
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
    final automaton = _notifier.state.pda;
    if (automaton != null) {
      for (final transition in automaton.pdaTransitions) {
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
    final automaton = _notifier.state.pda;
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
    _logPdaCanvas('addStateAtCenter requested');
    final worldCenter = resolveViewportCenterWorld();
    addStateAt(worldCenter);
  }

  /// Adds a new state at the provided [worldPosition].
  void addStateAt(Offset worldPosition) {
    final nodeId = _generateNodeId();
    final label = _nextAvailableStateLabel();
    _logPdaCanvas(
      'addStateAt -> id=$nodeId label=$label position=(${worldPosition.dx.toStringAsFixed(2)}, ${worldPosition.dy.toStringAsFixed(2)})',
    );
    performMutation(() {
      _notifier.addOrUpdateState(
        id: nodeId,
        label: label,
        x: worldPosition.dx,
        y: worldPosition.dy,
      );
    });
  }

  /// Moves an existing state to a new [position].
  void moveState(String id, Offset position) {
    _logPdaCanvas(
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
    _logPdaCanvas('updateStateLabel -> id=$id label=$resolvedLabel');
    performMutation(() {
      _notifier.updateStateLabel(
        id: id,
        label: resolvedLabel,
      );
    });
  }

  /// Updates the flag metadata for the state identified by [id].
  void updateStateFlags(String id, {bool? isInitial, bool? isAccepting}) {
    _logPdaCanvas(
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

  /// Removes the state identified by [id] from the automaton.
  void removeState(String id) {
    _logPdaCanvas('removeState -> id=$id');
    performMutation(() {
      _notifier.removeState(id: id);
    });
  }

  /// Adds or updates a transition between [fromStateId] and [toStateId].
  void addOrUpdateTransition({
    required String fromStateId,
    required String toStateId,
    String? readSymbol,
    String? popSymbol,
    String? pushSymbol,
    bool? isLambdaInput,
    bool? isLambdaPop,
    bool? isLambdaPush,
    String? transitionId,
    double? controlPointX,
    double? controlPointY,
  }) {
    final edgeId = transitionId ?? _generateEdgeId();
    final controlPoint = (controlPointX != null && controlPointY != null)
        ? Vector2(controlPointX, controlPointY)
        : null;
    _logPdaCanvas(
      'addOrUpdateTransition -> id=$edgeId from=$fromStateId to=$toStateId read=$readSymbol pop=$popSymbol push=$pushSymbol cp=${controlPoint?.toString()}',
    );
    performMutation(() {
      _notifier.upsertTransition(
        id: edgeId,
        fromStateId: fromStateId,
        toStateId: toStateId,
        readSymbol: readSymbol,
        popSymbol: popSymbol,
        pushSymbol: pushSymbol,
        isLambdaInput: isLambdaInput,
        isLambdaPop: isLambdaPop,
        isLambdaPush: isLambdaPush,
        controlPoint: controlPoint,
      );
    });
  }

  /// Updates only the geometry of the transition identified by [id].
  void updateTransitionControlPoint(
    String id,
    double controlPointX,
    double controlPointY,
  ) {
    _logPdaCanvas(
      'updateTransitionControlPoint -> id=$id cp=(${controlPointX.toStringAsFixed(2)}, ${controlPointY.toStringAsFixed(2)})',
    );
    performMutation(() {
      _notifier.upsertTransition(
        id: id,
        controlPoint: Vector2(controlPointX, controlPointY),
      );
    });
  }

  /// Removes the transition identified by [id] from the automaton.
  void removeTransition(String id) {
    _logPdaCanvas('removeTransition -> id=$id');
    performMutation(() {
      _notifier.removeTransition(id: id);
    });
  }

  @override
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot) {
    final template = _notifier.state.pda ??
        PDA(
          id: snapshot.metadata.id ??
              'pda_${DateTime.now().microsecondsSinceEpoch}',
          name: snapshot.metadata.name ?? 'Canvas PDA',
          states: const {},
          transitions: const {},
          alphabet: snapshot.metadata.alphabet.toSet(),
          initialState: null,
          acceptingStates: const {},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          stackAlphabet: const {'Z'},
          initialStackSymbol: 'Z',
          panOffset: Vector2.zero(),
          zoomLevel: 1.0,
        );

    final merged = GraphViewPdaMapper.mergeIntoTemplate(snapshot, template)
        .copyWith(
      id: snapshot.metadata.id ?? template.id,
      name: snapshot.metadata.name ?? template.name,
      alphabet: snapshot.metadata.alphabet.isNotEmpty
          ? snapshot.metadata.alphabet.toSet()
          : template.alphabet,
      modified: DateTime.now(),
    );

    _logPdaCanvas(
      'applySnapshotToDomain -> states=${merged.states.length} transitions=${merged.pdaTransitions.length}',
    );
    _notifier.setPda(merged);
    synchronize(merged);
  }
}
