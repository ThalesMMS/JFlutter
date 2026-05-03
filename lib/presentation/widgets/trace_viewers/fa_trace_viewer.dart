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
import '../../../core/services/simulation_highlight_service.dart';
import '../fsa/input_tape_viewer.dart';
import '../step_explanation_card.dart';
import 'base_trace_viewer.dart';
import 'nfa_computation_tree_viewer.dart';

class FATraceViewer extends StatefulWidget {
  final SimulationResult result;
  const FATraceViewer({super.key, required this.result});

  @override
  State<FATraceViewer> createState() => _FATraceViewerState();
}

class _FATraceViewerState extends State<FATraceViewer> {
  final _highlightService = SimulationHighlightService();

  InputTapeState _buildTapeState() {
    if (widget.result.inputString.isEmpty || widget.result.steps.isEmpty) {
      return const InputTapeState.initial();
    }

    // Calculate position from last step
    final lastStep = widget.result.steps.last;
    final position =
        widget.result.inputString.length - lastStep.remainingInput.length;

    return InputTapeState(
      symbols: widget.result.inputString.split(''),
      currentPosition: position,
    );
  }

  Set<String> _extractAlphabet() {
    if (widget.result.inputString.isEmpty) {
      return {};
    }
    return widget.result.inputString.split('').toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.result.inputString.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InputTapePanel(
              tapeState: _buildTapeState(),
              inputAlphabet: _extractAlphabet(),
              isSimulating: false,
            ),
          ),
        BaseTraceViewer(
          result: widget.result,
          title: 'FA Trace (${widget.result.stepCount} steps)',
          highlightService: _highlightService,
          buildStepLine: (SimulationStep step, int index) {
            final remaining =
                step.remainingInput.isEmpty ? 'ε' : step.remainingInput;
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
                  if (step.explanation != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            );
          },
          detailsBuilder: (context, step, index) {
            return StepExplanationCard(
              explanation: step.explanation,
              titleWhenEmpty: 'Why this step happened',
            );
          },
        ),
        if (widget.result.computationTree != null) ...[
          const SizedBox(height: 16),
          NFAComputationTreeViewer(
            computationTree: widget.result.computationTree!,
          ),
        ],
      ],
    );
  }
}
