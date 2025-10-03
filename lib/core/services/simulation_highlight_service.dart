import '../models/simulation_highlight.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';

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

  static SimulationHighlightChannel? _globalChannel;

  SimulationHighlightChannel? _channel;

  /// Registers a global highlight channel consumed by all service instances
  /// that don't override it locally.
  static void registerGlobalChannel(SimulationHighlightChannel? channel) {
    _globalChannel = channel;
  }

  /// Legacy helper kept for compatibility with older dispatcher-based flows.
  static void registerGlobalDispatcher(
    SimulationHighlightDispatcher? dispatcher,
  ) {
    registerGlobalChannel(
      dispatcher == null
          ? null
          : FunctionSimulationHighlightChannel(dispatcher),
    );
  }

  SimulationHighlightChannel? get channel => _channel ?? _globalChannel;

  set channel(SimulationHighlightChannel? value) {
    _channel = value;
  }

  /// Computes a highlight payload from a simulation result and step index.
  SimulationHighlight computeFromResult(
    SimulationResult? result,
    int stepIndex,
  ) {
    if (result == null) return SimulationHighlight.empty;
    return computeFromSteps(result.steps, stepIndex);
  }

  /// Computes a highlight payload from a list of steps.
  SimulationHighlight computeFromSteps(
    List<SimulationStep> steps,
    int stepIndex,
  ) {
    if (steps.isEmpty || stepIndex < 0 || stepIndex >= steps.length) {
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
    dispatch(highlight);
    return highlight;
  }

  /// Emits a highlight event derived from [steps] and [stepIndex].
  SimulationHighlight emitFromSteps(
    List<SimulationStep> steps,
    int stepIndex,
  ) {
    final highlight = computeFromSteps(steps, stepIndex);
    dispatch(highlight);
    return highlight;
  }

  /// Dispatches [highlight] to the Draw2D bridge.
  void dispatch(SimulationHighlight highlight) {
    channel?.send(highlight);
  }

  /// Sends a clear highlight event.
  void clear() {
    channel?.clear();
  }
}
