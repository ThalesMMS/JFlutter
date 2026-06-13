import '../../core/models/simulation_step.dart';

/// Shared immutable step-navigation behavior for trace state objects.
mixin TraceStepNavigation<TState> {
  int get currentStepIndex;

  List<SimulationStep> get steps;

  TState copyWithStepIndex(int currentStepIndex);

  TState navigateToStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= steps.length) {
      return this as TState;
    }
    return copyWithStepIndex(stepIndex);
  }

  TState nextStep() {
    final nextIndex = currentStepIndex + 1;
    if (nextIndex >= steps.length) {
      return this as TState;
    }
    return copyWithStepIndex(nextIndex);
  }

  TState previousStep() {
    final previousIndex = currentStepIndex - 1;
    if (previousIndex < 0) {
      return this as TState;
    }
    return copyWithStepIndex(previousIndex);
  }

  TState firstStep() {
    if (currentStepIndex == 0) {
      return this as TState;
    }
    return copyWithStepIndex(0);
  }

  TState lastStep() {
    if (steps.isEmpty) {
      return this as TState;
    }
    return copyWithStepIndex(steps.length - 1);
  }

  SimulationStep? get currentStep {
    if (currentStepIndex < 0 || currentStepIndex >= steps.length) {
      return null;
    }
    return steps[currentStepIndex];
  }

  bool get canNavigateNext =>
      currentStepIndex >= 0 && currentStepIndex < steps.length - 1;

  bool get canNavigatePrevious => currentStepIndex > 0;
}
