import 'package:flutter/material.dart';
import '../../core/ll_parsing.dart';
import '../../core/lr_parsing.dart';
import '../../core/cfg.dart';
import 'common_ui_components.dart';

/// Mobile-optimized widget for displaying LL parse table
class MobileLLParseTableWidget extends StatelessWidget {
  final LLParseTable table;

  const MobileLLParseTableWidget({
    super.key,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Tabela LL(1)',
            subtitle: 'Análise descendente',
            icon: Icons.table_chart,
          ),
          if (table.hasConflicts()) ...[
            StatusIndicator(
              isSuccess: false,
              message: 'Conflitos encontrados!',
              icon: Icons.warning,
            ),
            const SizedBox(height: CommonUIComponents.sectionSpacing),
          ],
          Expanded(
            child: isMobile ? _buildMobileTable(context) : _buildDesktopTable(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTable(BuildContext context) {
    return ListView.builder(
      itemCount: table.variables.length,
      itemBuilder: (context, variableIndex) {
        final variable = table.variables[variableIndex];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(
              variable,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 14, desktop: 16),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Terminals
                    ...table.terminals.map((terminal) {
                      final entries = table.getEntries(variable, terminal).toList();
                      return _buildTableRow(
                        context,
                        terminal,
                        entries,
                        isMobile: true,
                      );
                    }),
                    // End marker
                    _buildTableRow(
                      context,
                      '\$',
                      table.getEntries(variable, '\$').toList(),
                      isMobile: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildTableRow(BuildContext context, String symbol, List<String> entries, {required bool isMobile}) {
    final hasConflict = entries.length > 1;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasConflict ? Colors.red.shade50 : Colors.grey.shade50,
        border: Border.all(
          color: hasConflict ? Colors.red.shade300 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasConflict ? Colors.red.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 12, desktop: 14),
                color: hasConflict ? Colors.red.shade700 : Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entries.isEmpty ? '—' : entries.join(' | '),
              style: TextStyle(
                color: hasConflict ? Colors.red.shade700 : null,
                fontWeight: hasConflict ? FontWeight.bold : null,
                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 12, desktop: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile-optimized widget for displaying LR parse table
class MobileLRParseTableWidget extends StatelessWidget {
  final LRParseTable table;

  const MobileLRParseTableWidget({
    super.key,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Tabela LR(1)',
            subtitle: 'Análise ascendente',
            icon: Icons.account_tree,
          ),
          // Productions section
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produções:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 14, desktop: 16),
                  ),
                ),
                const SizedBox(height: 4),
                ...table.productions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final production = entry.value;
                  return Text(
                    '$index: ${production.toString()}',
                    style: TextStyle(
                      fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 12, desktop: 14),
                      fontFamily: 'monospace',
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: CommonUIComponents.sectionSpacing),
          Expanded(
            child: isMobile ? _buildMobileTable(context) : _buildDesktopTable(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTable(BuildContext context) {
    return ListView.builder(
      itemCount: table.states.length,
      itemBuilder: (context, stateIndex) {
        final state = table.states.elementAt(stateIndex);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(
              'Estado $state',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 14, desktop: 16),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action section
                    Text(
                      'Ações:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 12, desktop: 14),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...table.terminals.map((terminal) {
                      final action = table.getAction(state, terminal);
                      return _buildActionRow(
                        context,
                        terminal,
                        action,
                        isMobile: true,
                      );
                    }),
                    _buildActionRow(
                      context,
                      '\$',
                      table.getAction(state, '\$'),
                      isMobile: true,
                    ),
                    const SizedBox(height: 8),
                    // Goto section
                    Text(
                      'Goto:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 12, desktop: 14),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...table.variables.map((variable) {
                      final goto = table.getGoto(state, variable);
                      return _buildGotoRow(
                        context,
                        variable,
                        goto,
                        isMobile: true,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildActionRow(BuildContext context, String symbol, dynamic action, {required bool isMobile}) {
    final actionText = action?.toString() ?? '';
    final actionColor = _getActionColor(action?.action);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: actionColor?.withOpacity(0.1) ?? Colors.grey.shade50,
        border: Border.all(
          color: actionColor ?? Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: actionColor?.withOpacity(0.2) ?? Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 12, desktop: 14),
                color: actionColor ?? Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              actionText.isEmpty ? '—' : actionText,
              style: TextStyle(
                color: actionColor,
                fontWeight: FontWeight.bold,
                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 12, desktop: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGotoRow(BuildContext context, String variable, dynamic goto, {required bool isMobile}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              variable,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 12, desktop: 14),
                color: Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              goto?.toString() ?? '—',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 12, desktop: 14),
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

/// Mobile-optimized widget for displaying parsing steps
class MobileParsingStepsWidget extends StatelessWidget {
  final List<String> steps;
  final bool accepted;

  const MobileParsingStepsWidget({
    super.key,
    required this.steps,
    required this.accepted,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Passos do Parsing',
            subtitle: 'Execução passo-a-passo',
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
            child: isMobile ? _buildMobileSteps(context) : _buildDesktopSteps(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSteps(BuildContext context) {
    return ListView.builder(
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isError = step.contains('ERRO:');
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade50 : Colors.grey.shade50,
            border: Border.all(
              color: isError ? Colors.red.shade300 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isError ? Colors.red.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isError ? Colors.red.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step,
                  style: TextStyle(
                    color: isError ? Colors.red.shade700 : null,
                    fontWeight: isError ? FontWeight.bold : null,
                    fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 13, desktop: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopSteps(BuildContext context) {
    return ListView.builder(
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
    );
  }
}
