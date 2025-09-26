import 'package:flutter/material.dart';

import '../../../core/algorithms/pda_simulator.dart';
import '../../../core/models/simulation_step.dart';
import 'base_trace_viewer.dart';

class PDATraceViewer extends StatelessWidget {
  final PDASimulationResult result;
  const PDATraceViewer({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return BaseTraceViewer(
      result: _asSimulationResult(),
      title: 'PDA Trace (${result.steps.length} steps)',
      buildStepLine: (SimulationStep step, int index) {
        final remaining = step.remainingInput.isEmpty ? 'λ' : step.remainingInput;
        final stack = step.stackContents.isEmpty ? 'λ' : step.stackContents;
        final transition = step.usedTransition != null ? ' | ${step.usedTransition}' : '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text('${index + 1}.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'q=${step.currentState} | rem=$remaining | stack=$stack$transition',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Convert PDASimulationResult to core SimulationResult-like container for BaseTraceViewer.
  _PDAAdapter _asSimulationResult() {
    return _PDAAdapter(
      inputString: result.inputString,
      accepted: result.accepted,
      steps: result.steps,
      errorMessage: result.errorMessage ?? '',
      executionTime: result.executionTime,
    );
  }
}

class _PDAAdapter implements SimulationLike {
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

  _PDAAdapter({
    required this.inputString,
    required this.accepted,
    required this.steps,
    required this.errorMessage,
    required this.executionTime,
  });
}

// Minimal interface expected by BaseTraceViewer; we use duck typing by field names.
abstract class SimulationLike {
  String get inputString;
  bool get accepted;
  List<SimulationStep> get steps;
  String get errorMessage;
  Duration get executionTime;
}


