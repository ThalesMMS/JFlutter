import 'package:flutter/material.dart';
import '../../core/algo_log.dart';

class AlgoviewPanel extends StatelessWidget {
  const AlgoviewPanel({super.key});

  String _format(AlgoEvent e) {
    switch (e.algo) {
      case 'productDfa':
        if (e.step == 'newState') {
          return 'novo estado do produto ${e.data['id']}';
        }
        if (e.step == 'transition') {
          return '(${e.data['from']}, ${e.data['sym']}) → ${e.data['to']}';
        }
        break;
      case 'equivalence':
        if (e.step == 'diffFound') {
          return 'diferença encontrada no par ${e.data['pair']}';
        }
        if (e.step == 'final') {
          return 'AFDs equivalentes: ${e.data['equal'] == true ? 'sim' : 'não'}';
        }
        break;
      case 'removeLambda':
        if (e.step == 'closure') {
          final state = e.data['state'];
          final cl = (e.data['closure'] as List?)?.join(', ') ?? '';
          return 'ε-fecho($state) = {$cl}';
        }
        if (e.step == 'transition') {
          final from = e.data['from'];
          final sym = e.data['sym'];
          final to = (e.data['to'] as List?)?.join(', ') ?? '';
          return '($from, $sym) → {$to}';
        }
        break;
      case 'nfaToDfa':
        if (e.step == 'newState') {
          final id = e.data['id'];
          final subset = (e.data['subset'] as List?)?.join(', ') ?? '';
          return 'novo estado $id = {$subset}';
        }
        if (e.step == 'transition') {
          final from = e.data['from'];
          final sym = e.data['sym'];
          final to = e.data['to'];
          return '($from, $sym) → $to';
        }
        break;
      case 'dfaToRegex':
        if (e.step == 'eliminate') {
          final s = e.data['state'];
          return 'eliminando $s';
        }
        if (e.step == 'transition') {
          final fromName = e.data['fromName'];
          final toName = e.data['toName'];
          final via = e.data['via'];
          final regex = e.data['regex'];
          return '$fromName → $toName via $via: $regex';
        }
        if (e.step == 'final') {
          return 'ER = ${e.data['regex'] ?? ''}';
        }
        break;
      case 'minimizeDfa':
        if (e.step == 'initPartitions') {
          final fins = (e.data['finals'] as List?)?.join(', ') ?? '';
          final nfs = (e.data['nonFinals'] as List?)?.join(', ') ?? '';
          return 'partições iniciais — F={${fins}} / N={${nfs}}';
        }
        if (e.step == 'refined') {
          return 'refino de partições';
        }
        if (e.step == 'newState') {
          final id = e.data['id'];
          final reps = (e.data['represents'] as List?)?.join(', ') ?? '';
          return 'novo estado $id ← {$reps}';
        }
        if (e.step == 'transition') {
          return '(${e.data['from']}, ${e.data['sym']}) → ${e.data['to']}';
        }
        break;
      case 'completeDfa':
        if (e.step == 'addTrap') return 'adicionando estado armadilha';
        if (e.step == 'addMissing') return 'completando transições ausentes';
        if (e.step == 'final') return 'AFD já estava completo' ;
        break;
      case 'complement':
        if (e.step == 'flipFinals') return 'invertendo estados finais';
        break;
      case 'union':
        if (e.step == 'final') return 'União concluída';
        break;
      case 'difference':
        if (e.step == 'final') return 'Diferença concluída';
        break;
      case 'prefixClosure':
        if (e.step == 'final') return 'Fecho por Prefixos concluído';
        break;
      case 'suffixClosure':
        if (e.step == 'final') return 'Fecho por Sufixos concluído';
        break;
    }
    return '${e.algo}:${e.step}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AlgoEvent>>(
      valueListenable: AlgoLog.events,
      builder: (context, events, _) {
        final title = AlgoLog.lines.value.isNotEmpty ? AlgoLog.lines.value.first : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title ?? 'Log do Algoritmo', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(width: 8),
                TextButton(onPressed: AlgoLog.clear, child: const Text('Limpar')),
              ],
            ),
            Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: ListView(
                children: [
                  if (title != null) Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  for (final e in events) Text(_format(e)),
                  if (events.isEmpty)
                    ...AlgoLog.lines.value.skip(1).map<Widget>((l) => Text(l)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
