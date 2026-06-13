import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/pda/pda_simulator_facade.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/presentation/providers/fa_trace_provider.dart';
import 'package:jflutter/presentation/providers/pda_trace_provider.dart';
import 'package:jflutter/presentation/providers/trace_step_navigation.dart';
import 'package:jflutter/presentation/providers/unified_trace_provider.dart';

void main() {
  group('TraceStepNavigation', () {
    test('shared helper bounds navigation for a concrete state', () {
      final state = _FakeTraceState(
        currentStepIndex: 1,
        steps: _steps(3),
      );

      expect(state.navigateToStep(-1), same(state));
      expect(state.navigateToStep(3), same(state));
      expect(state.navigateToStep(2).currentStepIndex, equals(2));
      expect(state.nextStep().currentStepIndex, equals(2));
      expect(state.previousStep().currentStepIndex, equals(0));
      expect(state.firstStep().currentStepIndex, equals(0));
      expect(state.lastStep().currentStepIndex, equals(2));
      expect(state.currentStep, same(state.steps[1]));
      expect(state.canNavigateNext, isTrue);
      expect(state.canNavigatePrevious, isTrue);
    });

    test('shared helper leaves empty traces at the current index', () {
      const state = _FakeTraceState(currentStepIndex: 0, steps: []);

      expect(state.navigateToStep(0), same(state));
      expect(state.nextStep(), same(state));
      expect(state.previousStep(), same(state));
      expect(state.lastStep(), same(state));
      expect(state.currentStep, isNull);
      expect(state.canNavigateNext, isFalse);
      expect(state.canNavigatePrevious, isFalse);
    });

    test('FA, PDA, and unified states use the same step boundaries', () {
      final faState = FATraceState(
        result: _faResult(3),
        currentStepIndex: 1,
      );
      final pdaState = PDATraceState(
        result: _pdaResult(3),
        currentStepIndex: 1,
      );
      final unifiedState = UnifiedTraceState(
        currentTrace: _faResult(3),
        currentStepIndex: 1,
      );

      expect(faState.previousStep().currentStepIndex, equals(0));
      expect(pdaState.previousStep().currentStepIndex, equals(0));
      expect(unifiedState.previousStep().currentStepIndex, equals(0));

      expect(faState.lastStep().currentStepIndex, equals(2));
      expect(pdaState.lastStep().currentStepIndex, equals(2));
      expect(unifiedState.lastStep().currentStepIndex, equals(2));

      expect(faState.navigateToStep(3), same(faState));
      expect(pdaState.navigateToStep(3), same(pdaState));
      expect(unifiedState.navigateToStep(3), same(unifiedState));
    });

    test('FA, PDA, and unified states do not move lastStep on empty traces',
        () {
      final faState = FATraceState(result: _faResult(0));
      final pdaState = PDATraceState(result: _pdaResult(0));
      final unifiedState = UnifiedTraceState(currentTrace: _faResult(0));

      expect(faState.lastStep().currentStepIndex, equals(0));
      expect(pdaState.lastStep().currentStepIndex, equals(0));
      expect(unifiedState.lastStep().currentStepIndex, equals(0));
    });
  });
}

class _FakeTraceState with TraceStepNavigation<_FakeTraceState> {
  @override
  final int currentStepIndex;

  @override
  final List<SimulationStep> steps;

  const _FakeTraceState({
    required this.currentStepIndex,
    required this.steps,
  });

  @override
  _FakeTraceState copyWithStepIndex(int currentStepIndex) {
    return _FakeTraceState(
      currentStepIndex: currentStepIndex,
      steps: steps,
    );
  }
}

SimulationResult _faResult(int stepCount) {
  return SimulationResult.success(
    inputString: 'abba',
    steps: _steps(stepCount),
    executionTime: const Duration(milliseconds: 1),
  );
}

PDASimulationResult _pdaResult(int stepCount) {
  return PDASimulationResult.success(
    inputString: 'abba',
    steps: _steps(stepCount),
    executionTime: const Duration(milliseconds: 1),
  );
}

List<SimulationStep> _steps(int count) {
  return List<SimulationStep>.generate(
    count,
    (index) => SimulationStep(
      currentState: 'q$index',
      remainingInput: 'a' * (count - index),
      stepNumber: index,
    ),
  );
}
