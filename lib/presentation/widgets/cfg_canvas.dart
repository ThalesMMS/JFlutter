import 'package:flutter/material.dart';
import '../../core/cfg.dart';

class CFGCanvas extends StatefulWidget {
  final ContextFreeGrammar grammar;

  const CFGCanvas({
    super.key,
    required this.grammar,
  });

  @override
  State<CFGCanvas> createState() => _CFGCanvasState();
}

class _CFGCanvasState extends State<CFGCanvas> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Visualização da Gramática',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (widget.grammar.isWellFormed)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  )
                else
                  Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 20,
                  ),
              ],
            ),
          ),
          Expanded(
            child: widget.grammar.productions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma produção definida',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Adicione produções para visualizar a gramática',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGrammarInfo(),
                        const SizedBox(height: 24),
                        _buildProductionsList(),
                        const SizedBox(height: 24),
                        _buildGrammarAnalysis(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrammarInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações da Gramática',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Variável inicial', widget.grammar.startVariable),
            _buildInfoRow('Variáveis', widget.grammar.variables.join(', ')),
            _buildInfoRow('Terminais', widget.grammar.terminals.join(', ')),
            _buildInfoRow('Produções', '${widget.grammar.productions.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Não definido' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produções',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.grammar.productions.asMap().entries.map((entry) {
              final index = entry.key;
              final production = entry.value;
              return _buildProductionItem(index + 1, production);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionItem(int index, CFGProduction production) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  production.toString(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildProductionTypeChip(production),
                    const SizedBox(width: 8),
                    if (production.isLambdaProduction)
                      _buildChip('λ', Colors.orange)
                    else if (production.isTerminalProduction)
                      _buildChip('Terminal', Colors.blue)
                    else if (production.isUnitProduction)
                      _buildChip('Unitária', Colors.purple)
                    else if (production.isBinaryProduction)
                      _buildChip('Binária', Colors.green)
                    else
                      _buildChip('Geral', Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionTypeChip(CFGProduction production) {
    String type;
    Color color;
    
    if (production.isLambdaProduction) {
      type = 'λ';
      color = Colors.orange;
    } else if (production.isTerminalProduction) {
      type = 'Terminal';
      color = Colors.blue;
    } else if (production.isUnitProduction) {
      type = 'Unitária';
      color = Colors.purple;
    } else if (production.isBinaryProduction) {
      type = 'Binária';
      color = Colors.green;
    } else {
      type = 'Geral';
      color = Colors.grey;
    }
    
    return _buildChip(type, color);
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGrammarAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise da Gramática',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAnalysisItem(
              'Forma Normal de Chomsky',
              widget.grammar.isInCNF,
              'A gramática está em CNF se todas as produções são da forma A → BC ou A → a',
            ),
            _buildAnalysisItem(
              'Forma Normal de Greibach',
              widget.grammar.isInGNF,
              'A gramática está em GNF se todas as produções são da forma A → aα',
            ),
            _buildAnalysisItem(
              'Bem formada',
              widget.grammar.isWellFormed,
              'A gramática não possui erros de sintaxe',
            ),
            const SizedBox(height: 12),
            _buildProductionStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String title, bool isTrue, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isTrue ? Icons.check_circle : Icons.cancel,
            color: isTrue ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionStats() {
    final stats = <String, int>{
      'Total': widget.grammar.productions.length,
      'λ': widget.grammar.getLambdaProductions().length,
      'Unitárias': widget.grammar.getUnitProductions().length,
      'Terminais': widget.grammar.getTerminalProductions().length,
      'Binárias': widget.grammar.getBinaryProductions().length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas das Produções:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: stats.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
