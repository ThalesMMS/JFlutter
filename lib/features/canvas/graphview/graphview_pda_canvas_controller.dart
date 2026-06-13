//
//  graphview_pda_canvas_controller.dart
//  JFlutter
//
//  Controlador dedicado aos autômatos de pilha que sincroniza o GraphView com o
//  estado do PDAEditorNotifier, lidando com criação, movimentação e rótulos dos
//  nós, além de manter transições configuradas com símbolos de pilha. Também
//  orquestra snapshots vindos do domínio e registra logs úteis durante
//  mutações do grafo.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    extends BaseGraphViewCanvasController<PDAEditorNotifier, PDA>
    with SharedGraphViewStateController<PDAEditorNotifier, PDA> {
  GraphViewPdaCanvasController({
    required PDAEditorNotifier editorNotifier,
    super.graph,
    super.viewController,
    super.transformationController,
    super.historyLimit,
    super.cacheEvictionThreshold,
  }) : super(notifier: editorNotifier);

  PDAEditorNotifier get _notifier => notifier;

  @override
  PDA? get currentDomainData => _notifier.state.pda;

  @override
  Iterable<String> get domainStateIds {
    final automaton = currentDomainData;
    return automaton?.states.map((state) => state.id) ?? const <String>[];
  }

  @override
  Iterable<String> get domainStateLabels {
    final automaton = currentDomainData;
    return automaton?.states.map((state) => state.label) ?? const <String>[];
  }

  @override
  Iterable<String> get domainTransitionIds {
    final automaton = currentDomainData;
    return automaton?.pdaTransitions.map((transition) => transition.id) ??
        const <String>[];
  }

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

  @override
  void addDomainState({
    required String id,
    required String label,
    required Offset position,
  }) {
    _notifier.addOrUpdateState(
      id: id,
      label: label,
      x: position.dx,
      y: position.dy,
    );
  }

  @override
  void moveDomainState({required String id, required Offset position}) {
    _notifier.moveState(id: id, x: position.dx, y: position.dy);
  }

  @override
  void updateDomainStateLabel({required String id, required String label}) {
    _notifier.updateStateLabel(id: id, label: label);
  }

  @override
  void updateDomainStateFlags({
    required String id,
    bool? isInitial,
    bool? isAccepting,
  }) {
    _notifier.updateStateFlags(
      id: id,
      isInitial: isInitial,
      isAccepting: isAccepting,
    );
  }

  @override
  void removeDomainState(String id) {
    _notifier.removeState(id: id);
  }

  @override
  void logCanvasStateMutation(String message) {
    _logPdaCanvas(message);
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
    final edgeId = transitionId ?? generateEdgeId();
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

    final merged =
        GraphViewPdaMapper.mergeIntoTemplate(snapshot, template).copyWith(
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
