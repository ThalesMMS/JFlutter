//
//  algorithm_step_highlight_service.dart
//  JFlutter
//
//  Orquestra a emissão de destaques de passos de algoritmos com suporte a canais
//  plugáveis e dispatchers legados, oferecendo provedores Riverpod para integração
//  com o canvas. Extrai conjuntos de estados e transições relevantes por passo,
//  registra eventos em modo debug e disponibiliza utilidades para reemitir ou
//  limpar seleções durante visualização passo a passo de algoritmos.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dfa_minimization_step.dart';
import '../models/nfa_to_dfa_step.dart';
import '../models/regex_to_nfa_step.dart';
import '../models/simulation_highlight.dart';
import '../models/state.dart';
import '../models/transition.dart';

/// Provides access to the algorithm step highlight service associated with the
/// active canvas.
final canvasAlgorithmStepHighlightServiceProvider =
    Provider<AlgorithmStepHighlightService>((ref) {
      return AlgorithmStepHighlightService();
    });

/// Utility responsible for deriving and broadcasting algorithm step highlights.
typedef AlgorithmStepHighlightDispatcher =
    void Function(SimulationHighlight highlight);

/// Destination that consumes highlight payloads emitted by the
/// [AlgorithmStepHighlightService].
abstract class AlgorithmStepHighlightChannel {
  /// Sends the provided [highlight] to the underlying consumer.
  void send(SimulationHighlight highlight);

  /// Clears any pending highlight from the consumer.
  void clear();
}

/// Adapter that forwards highlights to a legacy dispatcher callback.
class FunctionAlgorithmStepHighlightChannel
    implements AlgorithmStepHighlightChannel {
  FunctionAlgorithmStepHighlightChannel(this._dispatcher);

  final AlgorithmStepHighlightDispatcher _dispatcher;

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
    debugPrint('[AlgorithmStepHighlightService] $message');
  }
}

class AlgorithmStepHighlightService {
  AlgorithmStepHighlightService({
    AlgorithmStepHighlightChannel? channel,
    AlgorithmStepHighlightDispatcher? dispatcher,
  }) : assert(
         channel == null || dispatcher == null,
         'Pass either a channel or a dispatcher, not both.',
       ),
       _channel =
           channel ??
           (dispatcher == null
               ? null
               : FunctionAlgorithmStepHighlightChannel(dispatcher));

  AlgorithmStepHighlightChannel? _channel;
  int _dispatchCount = 0;
  SimulationHighlight? _lastHighlight;

  AlgorithmStepHighlightChannel? get channel => _channel;

  set channel(AlgorithmStepHighlightChannel? value) {
    _channel = value;
  }

  /// Number of highlight payloads dispatched since the service was created.
  int get dispatchCount => _dispatchCount;

  /// Last highlight payload emitted by the service, if any.
  SimulationHighlight? get lastHighlight => _lastHighlight;

  /// Computes a highlight payload from step metadata.
  SimulationHighlight computeFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) {
      _logHighlightEvent('Skipping highlight computation: no step metadata');
      return SimulationHighlight.empty;
    }

    return _extractHighlightFromMetadata(metadata);
  }

  /// Computes a highlight payload from a list of metadata maps.
  SimulationHighlight computeFromMetadataList(
    List<Map<String, dynamic>> metadataList,
    int stepIndex,
  ) {
    if (metadataList.isEmpty ||
        stepIndex < 0 ||
        stepIndex >= metadataList.length) {
      _logHighlightEvent(
        'Ignoring highlight request for step $stepIndex (available: ${metadataList.length})',
      );
      return SimulationHighlight.empty;
    }

    return computeFromMetadata(metadataList[stepIndex]);
  }

  /// Emits a highlight event derived from [metadata].
  SimulationHighlight emitFromMetadata(Map<String, dynamic>? metadata) {
    final highlight = computeFromMetadata(metadata);
    _logHighlightEvent(
      'Computed highlight from metadata (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    dispatch(highlight);
    return highlight;
  }

  /// Emits a highlight event derived from [metadataList] and [stepIndex].
  SimulationHighlight emitFromMetadataList(
    List<Map<String, dynamic>> metadataList,
    int stepIndex,
  ) {
    final highlight = computeFromMetadataList(metadataList, stepIndex);
    _logHighlightEvent(
      'Computed highlight from metadata list at index $stepIndex (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
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

  /// Extracts state and transition IDs from step metadata
  SimulationHighlight _extractHighlightFromMetadata(
    Map<String, dynamic> metadata,
  ) {
    final stateIds = <String>{};
    final transitionIds = <String>{};

    // Handle NFAToDFAStep
    if (metadata.containsKey('nfaToDfaStep')) {
      final step = metadata['nfaToDfaStep'];
      if (step is NFAToDFAStep) {
        _addStateIdsFromSet(stateIds, step.currentStateSet);
        if (step.epsilonClosure != null) {
          _addStateIdsFromSet(stateIds, step.epsilonClosure!);
        }
        if (step.reachableStates != null) {
          _addStateIdsFromSet(stateIds, step.reachableStates!);
        }
        if (step.nextStateSet != null) {
          _addStateIdsFromSet(stateIds, step.nextStateSet!);
        }
        if (step.dfaStateId != null) {
          stateIds.add(step.dfaStateId!);
        }
      }
    }

    // Handle DFAMinimizationStep
    if (metadata.containsKey('dfaMinimizationStep')) {
      final step = metadata['dfaMinimizationStep'];
      if (step is DFAMinimizationStep) {
        if (step.processingSet != null) {
          _addStateIdsFromSet(stateIds, step.processingSet!);
        }
        if (step.splitSet != null) {
          _addStateIdsFromSet(stateIds, step.splitSet!);
        }
        if (step.splitIntersection != null) {
          _addStateIdsFromSet(stateIds, step.splitIntersection!);
        }
        if (step.splitDifference != null) {
          _addStateIdsFromSet(stateIds, step.splitDifference!);
        }
        if (step.equivalenceClassStates != null) {
          _addStateIdsFromSet(stateIds, step.equivalenceClassStates!);
        }
        if (step.equivalenceClassId != null) {
          stateIds.add(step.equivalenceClassId!);
        }
      }
    }

    // Handle RegexToNFAStep
    if (metadata.containsKey('regexToNfaStep')) {
      final step = metadata['regexToNfaStep'];
      if (step is RegexToNFAStep) {
        if (step.createdStates != null) {
          _addStateIdsFromSet(stateIds, step.createdStates!);
        }
        if (step.createdTransitions != null) {
          _addTransitionIdsFromSet(transitionIds, step.createdTransitions!);
        }
        if (step.fragmentStartState != null) {
          stateIds.add(step.fragmentStartState!.id);
        }
        if (step.fragmentAcceptState != null) {
          stateIds.add(step.fragmentAcceptState!.id);
        }
      }
    }

    return SimulationHighlight(
      stateIds: Set.unmodifiable(stateIds),
      transitionIds: Set.unmodifiable(transitionIds),
    );
  }

  /// Helper to add state IDs from a set of States
  void _addStateIdsFromSet(Set<String> targetSet, Set<State> states) {
    for (final state in states) {
      final trimmed = state.id.trim();
      if (trimmed.isNotEmpty) {
        targetSet.add(trimmed);
      }
    }
  }

  /// Helper to add transition IDs from a set of Transitions
  void _addTransitionIdsFromSet(
    Set<String> targetSet,
    Set<Transition> transitions,
  ) {
    for (final transition in transitions) {
      final trimmed = transition.id.trim();
      if (trimmed.isNotEmpty) {
        targetSet.add(trimmed);
      }
    }
  }
}
