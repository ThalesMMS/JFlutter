import 'package:flutter/material.dart';
import '../../core/ll_parsing.dart';
import '../../core/lr_parsing.dart';
import '../../core/cfg.dart';
import 'common_ui_components.dart';

/// Widget for displaying LL parse table
class LLParseTableWidget extends StatelessWidget {
  final LLParseTable table;

  const LLParseTableWidget({
    super.key,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Tabela de Parsing LL(1)',
            subtitle: 'Tabela de análise descendente',
            icon: Icons.table_chart,
          ),
          if (table.hasConflicts()) ...[
            StatusIndicator(
              isSuccess: false,
              message: 'Conflitos encontrados! ${table.getConflicts().map((conflict) => 'M[${conflict['variable']}, ${conflict['lookahead']}]: ${conflict['entries']}').join(', ')}',
              icon: Icons.warning,
            ),
            const SizedBox(height: CommonUIComponents.sectionSpacing),
          ],
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: CommonUIComponents.buttonSpacing,
                    headingRowColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    columns: [
                      DataColumn(label: Text('Variável')),
                      ...table.terminals.map((terminal) => 
                        DataColumn(label: Text(terminal, style: TextStyle(fontSize: CommonUIComponents.getResponsiveFontSize(context)))),
                      ),
                      const DataColumn(label: Text('\$')),
                    ],
                    rows: table.variables.map((variable) {
                      return DataRow(
                        cells: [
                          DataCell(Text(variable, style: TextStyle(fontSize: CommonUIComponents.getResponsiveFontSize(context)))),
                          ...table.terminals.map((terminal) {
                            final entries = table.getEntries(variable, terminal);
                            return DataCell(
                              Text(
                                entries.isEmpty ? '' : entries.join(' | '),
                                style: TextStyle(
                                  color: entries.length > 1 ? Colors.red : null,
                                  fontWeight: entries.length > 1 ? FontWeight.bold : null,
                                  fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 10, desktop: 12),
                                ),
                              ),
                            );
                          }),
                          DataCell(
                            Text(
                              table.getEntries(variable, '\$').join(' | '),
                              style: TextStyle(
                                color: table.getEntries(variable, '\$').length > 1 ? Colors.red : null,
                                fontWeight: table.getEntries(variable, '\$').length > 1 ? FontWeight.bold : null,
                                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 10, desktop: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget for displaying LR parse table
class LRParseTableWidget extends StatelessWidget {
  final LRParseTable table;

  const LRParseTableWidget({
    super.key,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Tabela de Parsing LR(1)',
            subtitle: 'Tabela de análise ascendente',
            icon: Icons.account_tree,
          ),
          Text(
            'Produções:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...table.productions.asMap().entries.map((entry) {
            final index = entry.key;
            final production = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('$index: ${production.toString()}'),
            );
          }),
          const SizedBox(height: CommonUIComponents.sectionSpacing),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: CommonUIComponents.buttonSpacing,
                    headingRowColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    columns: [
                      const DataColumn(label: Text('Estado')),
                      ...table.terminals.map((terminal) => 
                        DataColumn(label: Text(terminal, style: TextStyle(fontSize: CommonUIComponents.getResponsiveFontSize(context))))),
                      const DataColumn(label: Text('\$')),
                      ...table.variables.map((variable) => 
                        DataColumn(label: Text(variable, style: TextStyle(fontSize: CommonUIComponents.getResponsiveFontSize(context))))),
                    ],
                    rows: table.states.map((state) {
                      return DataRow(
                        cells: [
                          DataCell(Text(state.toString(), style: TextStyle(fontSize: CommonUIComponents.getResponsiveFontSize(context)))),
                          ...table.terminals.map((terminal) {
                            final action = table.getAction(state, terminal);
                            return DataCell(
                              Text(
                                action?.toString() ?? '',
                                style: TextStyle(
                                  color: _getActionColor(action?.action),
                                  fontWeight: FontWeight.bold,
                                  fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 10, desktop: 12),
                                ),
                              ),
                            );
                          }),
                          DataCell(
                            Text(
                              table.getAction(state, '\$')?.toString() ?? '',
                              style: TextStyle(
                                color: _getActionColor(table.getAction(state, '\$')?.action),
                                fontWeight: FontWeight.bold,
                                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 10, desktop: 12),
                              ),
                            ),
                          ),
                          ...table.variables.map((variable) {
                            final goto = table.getGoto(state, variable);
                            return DataCell(
                              Text(goto?.toString() ?? '', style: TextStyle(fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 10, desktop: 12))),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color? _getActionColor(String? action) {
    switch (action) {
      case 's':
        return Colors.blue;
      case 'r':
        return Colors.green;
      case 'acc':
        return Colors.purple;
      default:
        return null;
    }
  }
}

/// Widget for displaying parsing steps
class ParsingStepsWidget extends StatelessWidget {
  final List<String> steps;
  final bool accepted;

  const ParsingStepsWidget({
    super.key,
    required this.steps,
    required this.accepted,
  });

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Passos do Parsing',
            subtitle: 'Execução passo-a-passo do algoritmo',
            icon: Icons.play_arrow,
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accepted ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      accepted ? Icons.check_circle : Icons.cancel,
                      color: accepted ? Colors.green.shade700 : Colors.red.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      accepted ? 'Aceito' : 'Rejeitado',
                      style: TextStyle(
                        color: accepted ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: CommonUIComponents.getResponsiveFontSize(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final isError = step.contains('ERRO:');
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: EdgeInsets.all(CommonUIComponents.getResponsivePadding(context).left),
                    decoration: BoxDecoration(
                      color: isError ? Colors.red.shade50 : Colors.grey.shade50,
                      border: Border.all(
                        color: isError ? Colors.red.shade300 : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(CommonUIComponents.borderRadius),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: CommonUIComponents.getResponsiveIconSize(context),
                          height: CommonUIComponents.getResponsiveIconSize(context),
                          decoration: BoxDecoration(
                            color: isError ? Colors.red.shade100 : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(CommonUIComponents.getResponsiveIconSize(context) / 2),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 10, desktop: 12),
                                fontWeight: FontWeight.bold,
                                color: isError ? Colors.red.shade700 : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: CommonUIComponents.buttonSpacing),
                        Expanded(
                          child: Text(
                            step,
                            style: TextStyle(
                              color: isError ? Colors.red.shade700 : null,
                              fontWeight: isError ? FontWeight.bold : null,
                              fontSize: CommonUIComponents.getResponsiveFontSize(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget for displaying derivation
class DerivationWidget extends StatelessWidget {
  final List<CFGProduction> derivation;

  const DerivationWidget({
    super.key,
    required this.derivation,
  });

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Derivação',
            subtitle: 'Sequência de produções aplicadas',
            icon: Icons.account_tree,
          ),
          if (derivation.isEmpty)
            EmptyState(
              title: 'Nenhuma derivação encontrada',
              subtitle: 'Execute o parsing para ver a derivação',
              icon: Icons.search_off,
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: derivation.length,
                itemBuilder: (context, index) {
                  final production = derivation[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(CommonUIComponents.getResponsivePadding(context).left),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade300),
                      borderRadius: BorderRadius.circular(CommonUIComponents.borderRadius),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: CommonUIComponents.getResponsiveIconSize(context),
                          height: CommonUIComponents.getResponsiveIconSize(context),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(CommonUIComponents.getResponsiveIconSize(context) / 2),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 10, desktop: 12),
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: CommonUIComponents.buttonSpacing),
                        Expanded(
                          child: Text(
                            production.toString(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: CommonUIComponents.getResponsiveFontSize(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
