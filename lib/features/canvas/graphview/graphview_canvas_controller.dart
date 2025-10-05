import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart';

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
    final isFirstState = nodesCache.isEmpty &&
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
      _provider.moveState(
        id: id,
        x: position.dx,
        y: position.dy,
      );
    });
  }

  /// Updates the label displayed for the state identified by [id].
  void updateStateLabel(String id, String label) {
    final resolvedLabel = label.isEmpty ? id : label;
    _logAutomatonCanvas('updateStateLabel -> id=$id label=$resolvedLabel');
    performMutation(() {
      _provider.updateStateLabel(
        id: id,
        label: resolvedLabel,
      );
    });
  }

  /// Removes the state identified by [id] from the automaton.
  void removeState(String id) {
    _logAutomatonCanvas('removeState -> id=$id');
    performMutation(() {
      _provider.removeState(id: id);
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

  @override
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot) {
    final template = _provider.state.currentAutomaton ??
        FSA(
          id: snapshot.metadata.id ??
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

    final merged = GraphViewAutomatonMapper.mergeIntoTemplate(snapshot, template)
        .copyWith(
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
