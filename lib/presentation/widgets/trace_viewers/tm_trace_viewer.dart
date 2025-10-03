import 'package:flutter/material.dart';

import '../../../core/algorithms/tm_simulator.dart';
import '../../../core/models/simulation_result.dart';
import '../../../core/models/simulation_step.dart';
import '../../../core/services/simulation_highlight_service.dart';
import 'base_trace_viewer.dart';

class TMTraceViewer extends StatelessWidget {
  final TMSimulationResult result;
  final SimulationHighlightService? highlightService;

  const TMTraceViewer({
    super.key,
    required this.result,
    this.highlightService,
  });

  @override
  Widget build(BuildContext context) {
    return BaseTraceViewer(
      result: _asSimulationResult(),
      title: 'TM Trace (${result.steps.length} steps)',
      highlightService: highlightService,
      buildStepLine: (SimulationStep step, int index) {
        final tape = step.tapeContents.isEmpty ? '□' : step.tapeContents;
        final transition = step.usedTransition != null
            ? ' | read ${step.usedTransition}'
            : '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(
                '${index + 1}.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'q=${step.currentState} | tape=$tape$transition',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SimulationResult _asSimulationResult() {
    final errorMessage = result.errorMessage ?? '';

    if (result.accepted) {
      return SimulationResult.success(
        inputString: result.inputString,
        steps: result.steps,
        executionTime: result.executionTime,
      );
    }

    final normalizedMessage = errorMessage.toLowerCase();
    if (normalizedMessage.contains('timeout')) {
      return SimulationResult.timeout(
        inputString: result.inputString,
        steps: result.steps,
        executionTime: result.executionTime,
      );
    }

    if (normalizedMessage.contains('infinite')) {
      return SimulationResult.infiniteLoop(
        inputString: result.inputString,
        steps: result.steps,
        executionTime: result.executionTime,
      );
    }

    final failureMessage = errorMessage.isNotEmpty
        ? errorMessage
        : 'Simulation rejected';

    return SimulationResult.failure(
      inputString: result.inputString,
      steps: result.steps,
      errorMessage: failureMessage,
      executionTime: result.executionTime,
    );
  }
}
