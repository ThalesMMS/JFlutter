//
//  simulation_highlight_service.dart
//  JFlutter
//
//  Coordena o cálculo e a difusão de destaques visuais para simulações,
//  convertendo resultados e passos em conjuntos imutáveis de estados e
//  transições relevantes. Disponibiliza provedores Riverpod, canais de
//  comunicação e adaptadores para callbacks legados, além de registrar eventos
//  durante o despacho. Permite limpar, acompanhar e reaproveitar o último
//  destaque emitido pela interface interativa.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/simulation_highlight.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';

/// Provides access to the highlight service associated with the active canvas.
final canvasHighlightServiceProvider = Provider<SimulationHighlightService>((ref) {
  return SimulationHighlightService();
});

/// Utility responsible for deriving and broadcasting simulation highlights.
typedef SimulationHighlightDispatcher = void Function(
  SimulationHighlight highlight,
);

/// Destination that consumes highlight payloads emitted by the
/// [SimulationHighlightService].
abstract class SimulationHighlightChannel {
  /// Sends the provided [highlight] to the underlying consumer.
  void send(SimulationHighlight highlight);

  /// Clears any pending highlight from the consumer.
  void clear();
}

/// Adapter that forwards highlights to a legacy dispatcher callback.
class FunctionSimulationHighlightChannel implements SimulationHighlightChannel {
  FunctionSimulationHighlightChannel(this._dispatcher);

  final SimulationHighlightDispatcher _dispatcher;

  @override
  void clear() {
    _dispatcher(SimulationHighlight.empty);
  }

  @override
  void send(SimulationHighlight highlight) {
    _dispatcher(highlight);
  }
}

void _logHighlightEvent(String message) {
  if (kDebugMode) {
    debugPrint('[SimulationHighlightService] $message');
  }
}

class SimulationHighlightService {
  SimulationHighlightService({
    SimulationHighlightChannel? channel,
    SimulationHighlightDispatcher? dispatcher,
  })  : assert(
          channel == null || dispatcher == null,
          'Pass either a channel or a dispatcher, not both.',
        ),
        _channel = channel ??
            (dispatcher == null
                ? null
                : FunctionSimulationHighlightChannel(dispatcher));

  SimulationHighlightChannel? _channel;
  int _dispatchCount = 0;
  SimulationHighlight? _lastHighlight;

  SimulationHighlightChannel? get channel => _channel;

  set channel(SimulationHighlightChannel? value) {
    _channel = value;
  }

  /// Number of highlight payloads dispatched since the service was created.
  int get dispatchCount => _dispatchCount;

  /// Last highlight payload emitted by the service, if any.
  SimulationHighlight? get lastHighlight => _lastHighlight;

  /// Computes a highlight payload from a simulation result and step index.
  SimulationHighlight computeFromResult(
    SimulationResult? result,
    int stepIndex,
  ) {
    if (result == null) {
      _logHighlightEvent('Skipping highlight computation: no simulation result');
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
      _logHighlightEvent(
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
  SimulationHighlight emitFromResult(
    SimulationResult? result,
    int stepIndex,
  ) {
    final highlight = computeFromResult(result, stepIndex);
    _logHighlightEvent(
      'Computed highlight from result at step $stepIndex (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    dispatch(highlight);
    return highlight;
  }

  /// Emits a highlight event derived from [steps] and [stepIndex].
  SimulationHighlight emitFromSteps(
    List<SimulationStep> steps,
    int stepIndex,
  ) {
    final highlight = computeFromSteps(steps, stepIndex);
    _logHighlightEvent(
      'Computed highlight from steps at index $stepIndex (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    dispatch(highlight);
    return highlight;
  }

  /// Dispatches [highlight] to the active canvas highlight channel.
  void dispatch(SimulationHighlight highlight) {
    _dispatchCount++;
    _lastHighlight = highlight;
    _logHighlightEvent(
      'Dispatch #$_dispatchCount (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    channel?.send(highlight);
  }

  /// Sends a clear highlight event.
  void clear() {
    if (_dispatchCount > 0 || _lastHighlight != null) {
      _logHighlightEvent('Clearing highlight after $_dispatchCount dispatches');
    }
    _lastHighlight = null;
    channel?.clear();
  }
}
