//
//  simulation_highlight_service.dart
//  JFlutter
//
//  Orquestra a emissão de destaques de simulação com suporte a canais plugáveis e
//  dispatchers legados, oferecendo provedores Riverpod para integração com o canvas.
//  Constrói conjuntos de estados e transições relevantes por passo, registra eventos
//  em modo debug e disponibiliza utilidades para reemitir ou limpar seleções.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/simulation_highlight.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import 'highlight_channel.dart';

/// Provides access to the highlight service associated with the active canvas.
final canvasHighlightServiceProvider = Provider<SimulationHighlightService>((
  ref,
) {
  return SimulationHighlightService();
});

/// Utility responsible for deriving and broadcasting simulation highlights.
typedef SimulationHighlightDispatcher = HighlightDispatcher;

/// Destination that consumes highlight payloads emitted by the
/// [SimulationHighlightService].
abstract class SimulationHighlightChannel implements HighlightChannel {}

/// Adapter that forwards highlights to a legacy dispatcher callback.
class FunctionSimulationHighlightChannel extends FunctionHighlightChannel
    implements SimulationHighlightChannel {
  FunctionSimulationHighlightChannel(super.dispatcher);
}

class SimulationHighlightService {
  SimulationHighlightService({
    SimulationHighlightChannel? channel,
    SimulationHighlightDispatcher? dispatcher,
  }) : _highlightDispatch =
            HighlightDispatchController<SimulationHighlightChannel>(
          debugLabel: 'SimulationHighlightService',
          channel: channel,
          dispatcher: dispatcher,
          channelFromDispatcher: FunctionSimulationHighlightChannel.new,
        );

  final HighlightDispatchController<SimulationHighlightChannel>
      _highlightDispatch;

  SimulationHighlightChannel? get channel => _highlightDispatch.channel;

  set channel(SimulationHighlightChannel? value) {
    _highlightDispatch.channel = value;
  }

  /// Number of highlight payloads dispatched since the service was created.
  int get dispatchCount => _highlightDispatch.dispatchCount;

  /// Last highlight payload emitted by the service, if any.
  SimulationHighlight? get lastHighlight => _highlightDispatch.lastHighlight;

  /// Computes a highlight payload from a simulation result and step index.
  SimulationHighlight computeFromResult(
    SimulationResult? result,
    int stepIndex,
  ) {
    if (result == null) {
      _highlightDispatch.log(
        'Skipping highlight computation: no simulation result',
      );
      return SimulationHighlight.empty;
    }
    return computeFromSteps(result.steps, stepIndex);
  }

  /// Computes a highlight payload from a list of steps.
  SimulationHighlight computeFromSteps(
    List<SimulationStep> steps,
    int stepIndex,
  ) {
    if (steps.isEmpty || stepIndex < 0 || stepIndex >= steps.length) {
      _highlightDispatch.log(
        'Ignoring highlight request for step $stepIndex (available: ${steps.length})',
      );
      return SimulationHighlight.empty;
    }

    final current = steps[stepIndex];
    final stateIds = <String>{};

    void addState(String? id) {
      if (id == null) return;
      final trimmed = id.trim();
      if (trimmed.isNotEmpty) {
        stateIds.add(trimmed);
      }
    }

    addState(current.currentState);
    addState(current.nextState);
    if ((current.nextState == null || current.nextState!.isEmpty) &&
        stepIndex + 1 < steps.length) {
      addState(steps[stepIndex + 1].currentState);
    }

    final transitionIds = <String>{};
    final usedTransition = current.usedTransition?.trim();
    if (usedTransition != null && usedTransition.isNotEmpty) {
      transitionIds.add(usedTransition);
    }

    return SimulationHighlight(
      stateIds: Set.unmodifiable(stateIds),
      transitionIds: Set.unmodifiable(transitionIds),
    );
  }

  /// Emits a highlight event derived from [result] and [stepIndex].
  SimulationHighlight emitFromResult(SimulationResult? result, int stepIndex) {
    final highlight = computeFromResult(result, stepIndex);
    _highlightDispatch.log(
      'Computed highlight from result at step $stepIndex (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    dispatch(highlight);
    return highlight;
  }

  /// Emits a highlight event derived from [steps] and [stepIndex].
  SimulationHighlight emitFromSteps(List<SimulationStep> steps, int stepIndex) {
    final highlight = computeFromSteps(steps, stepIndex);
    _highlightDispatch.log(
      'Computed highlight from steps at index $stepIndex (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    dispatch(highlight);
    return highlight;
  }

  /// Dispatches [highlight] to the active canvas highlight channel.
  void dispatch(SimulationHighlight highlight) {
    _highlightDispatch.dispatch(highlight);
  }

  /// Sends a clear highlight event.
  void clear() {
    _highlightDispatch.clear();
  }
}
