//
//  fa_trace_viewer.dart
//  JFlutter
//
//  Visualizador de traços para simulações de autômatos finitos que destaca
//  estado corrente, entrada remanescente e transição consumida a cada passo.
//  Reaproveita a infraestrutura do BaseTraceViewer para manter consistência e
//  reforça notações clássicas como ε para cadeias vazias, servindo painéis de
//  simulação e depuração.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../../core/models/simulation_result.dart';
import '../../../core/models/simulation_step.dart';
import 'base_trace_viewer.dart';

class FATraceViewer extends StatelessWidget {
  final SimulationResult result;
  const FATraceViewer({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return BaseTraceViewer(
      result: result,
      title: 'FA Trace (${result.steps.length} steps)',
      buildStepLine: (SimulationStep step, int index) {
        final remaining = step.remainingInput.isEmpty
            ? 'ε'
            : step.remainingInput;
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
                  'q=${step.currentState} | remaining=$remaining$transition',
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
}
