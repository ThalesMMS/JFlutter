import '../models/simulation_highlight.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';

/// Utility responsible for deriving and broadcasting simulation highlights.
typedef SimulationHighlightDispatcher = void Function(
  SimulationHighlight highlight,
);

class SimulationHighlightService {
  SimulationHighlightService({SimulationHighlightDispatcher? dispatcher})
      : _dispatcher = dispatcher;

  static SimulationHighlightDispatcher? _globalDispatcher;

  SimulationHighlightDispatcher? _dispatcher;

  static void registerGlobalDispatcher(
    SimulationHighlightDispatcher? dispatcher,
  ) {
    _globalDispatcher = dispatcher;
  }

  SimulationHighlightDispatcher? get dispatcher =>
      _dispatcher ?? _globalDispatcher;

  set dispatcher(SimulationHighlightDispatcher? value) {
    _dispatcher = value;
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
    dispatcher?.call(highlight);
  }

  /// Sends a clear highlight event.
  void clear() {
    dispatcher?.call(SimulationHighlight.empty);
  }
}
