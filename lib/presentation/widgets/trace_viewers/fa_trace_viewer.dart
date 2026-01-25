//
//  fa_trace_viewer.dart
//  JFlutter
//
//  Exibe os traços de simulação de autômatos finitos reutilizando o
//  BaseTraceViewer para mostrar estado atual, entrada restante e transições
//  consumidas, utilizando convenções clássicas como ε para indicar cadeia vazia.
//  Funciona com resultados de DFAs e NFAs de forma uniforme, fornecendo uma
//  visualização cronológica que pode ser estendida com metadados adicionais.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../../core/models/simulation_result.dart';
import '../../../core/models/simulation_step.dart';
import '../fsa/input_tape_viewer.dart';
import 'base_trace_viewer.dart';
import 'nfa_computation_tree_viewer.dart';

class FATraceViewer extends StatelessWidget {
  final SimulationResult result;
  const FATraceViewer({super.key, required this.result});

  InputTapeState _buildTapeState() {
    if (result.inputString.isEmpty || result.steps.isEmpty) {
      return const InputTapeState.initial();
    }

    // Calculate position from last step
    final lastStep = result.steps.last;
    final position = result.inputString.length - lastStep.remainingInput.length;

    return InputTapeState(
      symbols: result.inputString.split(''),
      currentPosition: position,
    );
  }

  Set<String> _extractAlphabet() {
    if (result.inputString.isEmpty) {
      return {};
    }
    return result.inputString.split('').toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.inputString.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InputTapePanel(
              tapeState: _buildTapeState(),
              inputAlphabet: _extractAlphabet(),
              isSimulating: false,
            ),
          ),
        BaseTraceViewer(
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
        ),
        if (result.computationTree != null) ...[
          const SizedBox(height: 16),
          NFAComputationTreeViewer(computationTree: result.computationTree!),
        ],
      ],
    );
  }
}
