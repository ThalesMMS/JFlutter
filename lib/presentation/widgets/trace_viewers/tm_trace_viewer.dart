import 'package:flutter/material.dart';

import '../../../core/algorithms/tm_simulator.dart';
import '../../../core/models/simulation_step.dart';
import 'base_trace_viewer.dart';

class TMTraceViewer extends StatelessWidget {
  final TMSimulationResult result;
  const TMTraceViewer({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return BaseTraceViewer(
      result: _asSimulationResult(),
      title: 'TM Trace (${result.steps.length} steps)',
      buildStepLine: (SimulationStep step, int index) {
        final tape = step.tapeContents.isEmpty ? '□' : step.tapeContents;
        final transition =
            step.usedTransition != null ? ' | read ${step.usedTransition}' : '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text('${index + 1}.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'q=${step.currentState} | tape=$tape$transition',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _TMAdapter _asSimulationResult() {
    return _TMAdapter(
      inputString: result.inputString,
      accepted: result.accepted,
      steps: result.steps,
      errorMessage: result.errorMessage ?? '',
      executionTime: result.executionTime,
    );
  }
}

class _TMAdapter implements SimulationLike {
  @override
  final String inputString;
  @override
  final bool accepted;
  @override
  final List<SimulationStep> steps;
  @override
  final String errorMessage;
  @override
  final Duration executionTime;

  _TMAdapter({
    required this.inputString,
    required this.accepted,
    required this.steps,
    required this.errorMessage,
    required this.executionTime,
  });
}

abstract class SimulationLike {
  String get inputString;
  bool get accepted;
  List<SimulationStep> get steps;
  String get errorMessage;
  Duration get executionTime;
}
