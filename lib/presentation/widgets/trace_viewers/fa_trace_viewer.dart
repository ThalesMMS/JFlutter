/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/widgets/trace_viewers/fa_trace_viewer.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Apresenta traços de simulação de autômatos finitos detalhando estado corrente, entrada restante e transição utilizada. Utiliza convenções como ε para cadeia vazia reforçando terminologia de teoria de autômatos.
/// Contexto: Se baseia no BaseTraceViewer para renderização padronizada e suporta personalização de linhas de passo. É utilizado por painéis de simulação para oferecer visão cronológica de execuções.
/// Observações: Opera diretamente com SimulationResult genérico tornando-se compatível com DFAs, NFAs e execuções passo a passo. Pode ser estendido para incluir metadados adicionais sem romper a API existente.
/// ---------------------------------------------------------------------------
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
