import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dfa.dart';

class TransitionTable extends StatefulWidget {
  final DFA dfa;
  final bool showHeaders;
  final bool enableInteraction;
  final Function(String state, String symbol)? onCellTap;
  final VoidCallback? onExport;

  const TransitionTable({
    super.key,
    required this.dfa,
    this.showHeaders = true,
    this.enableInteraction = false,
    this.onCellTap,
    this.onExport,
  });

  @override
  State<TransitionTable> createState() => _TransitionTableState();
}

class _TransitionTableState extends State<TransitionTable>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Set<String> _highlightedCells = {};
  String? _hoveredCell;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tableData = widget.dfa.getTransitionTable();
    final sortedStates = tableData.keys.toList()..sort();
    final sortedAlphabet = widget.dfa.alphabet.toList()..sort();

    if (sortedStates.isEmpty) {
      return _buildEmptyState(theme);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          if (widget.showHeaders) _buildTableHeader(theme),
          Expanded(
            child: _buildScrollableTable(
              theme,
              sortedStates,
              sortedAlphabet,
              tableData,
            ),
          ),
          if (widget.onExport != null) _buildActionBar(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'جدول انتقالات برای نمایش وجود ندارد',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'ابتدا حالت‌ها و انتقالات را تعریف کنید',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.table_view_rounded,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'جدول انتقالات',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          _buildLegend(theme),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem(
          theme,
          Icons.arrow_right_alt_rounded,
          'حالت شروع',
          theme.colorScheme.secondary,
        ),
        const SizedBox(width: 16),
        _buildLegendItem(
          theme,
          Icons.star,
          'حالت پایانی',
          theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildScrollableTable(
    ThemeData theme,
    List<String> states,
    List<String> alphabet,
    Map<String, Map<String, String>> tableData,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        child: Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              controller: _verticalController,
              child:
                  _buildAdvancedDataTable(theme, states, alphabet, tableData),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedDataTable(
    ThemeData theme,
    List<String> states,
    List<String> alphabet,
    Map<String, Map<String, String>> tableData,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: DataTable(
        headingRowHeight: 60,
        dataRowMinHeight: 50,
        dataRowMaxHeight: 50,
        showCheckboxColumn: false,
        dividerThickness: 1,
        headingRowColor: MaterialStateProperty.resolveWith((states) {
          return theme.colorScheme.primaryContainer.withOpacity(0.3);
        }),
        columns: _buildAdvancedColumns(alphabet, theme),
        rows: _buildAdvancedRows(states, alphabet, tableData, theme),
      ),
    );
  }

  List<DataColumn> _buildAdvancedColumns(
      List<String> alphabet, ThemeData theme) {
    return [
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'State',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      ...alphabet.map((symbol) => DataColumn(
            label: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                ),
              ),
              child: Text(
                symbol,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )),
    ];
  }

  List<DataRow> _buildAdvancedRows(
    List<String> states,
    List<String> alphabet,
    Map<String, Map<String, String>> tableData,
    ThemeData theme,
  ) {
    return states.asMap().entries.map((entry) {
      final index = entry.key;
      final stateName = entry.value;
      final isStart = widget.dfa.startState != null &&
          widget.dfa.getStateName(widget.dfa.startState!) == stateName;
      final isFinal = widget.dfa.finalStates
          .any((s) => widget.dfa.getStateName(s) == stateName);

      return DataRow(
        color: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) {
            return theme.colorScheme.primary.withOpacity(0.05);
          }
          return index.isEven
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceVariant.withOpacity(0.3);
        }),
        cells: [
          DataCell(_buildAdvancedStateCell(stateName, isStart, isFinal, theme)),
          ...alphabet.map((symbol) {
            final destination = tableData[stateName]?[symbol] ?? '∅';
            final cellKey = '$stateName-$symbol';
            return DataCell(
              _buildTransitionCell(destination, cellKey, theme),
              onTap: widget.enableInteraction
                  ? () => _handleCellTap(stateName, symbol)
                  : null,
            );
          }),
        ],
      );
    }).toList();
  }

  Widget _buildAdvancedStateCell(
    String name,
    bool isStart,
    bool isFinal,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            if (isStart && isFinal) ...[
              theme.colorScheme.tertiary.withOpacity(0.2),
              theme.colorScheme.secondary.withOpacity(0.2),
            ] else if (isStart) ...[
              theme.colorScheme.secondary.withOpacity(0.2),
              theme.colorScheme.secondary.withOpacity(0.1),
            ] else if (isFinal) ...[
              theme.colorScheme.tertiary.withOpacity(0.2),
              theme.colorScheme.tertiary.withOpacity(0.1),
            ] else ...[
              Colors.transparent,
              Colors.transparent,
            ]
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isStart || isFinal
              ? (isStart
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.tertiary)
                  .withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStart)
            Tooltip(
              message: 'حالت شروع',
              child: Icon(
                Icons.arrow_right_alt_rounded,
                size: 20,
                color: theme.colorScheme.secondary,
              ),
            ),
          if (isFinal)
            Tooltip(
              message: 'حالت پایانی',
              child: Icon(
                Icons.star,
                size: 18,
                color: theme.colorScheme.tertiary,
              ),
            ),
          if (isStart || isFinal) const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionCell(
      String destination, String cellKey, ThemeData theme) {
    final isHighlighted = _highlightedCells.contains(cellKey);
    final isHovered = _hoveredCell == cellKey;
    final isEmpty = destination == '∅';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCell = cellKey),
      onExit: (_) => setState(() => _hoveredCell = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? theme.colorScheme.primary.withOpacity(0.2)
              : isHovered
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isHighlighted
                ? theme.colorScheme.primary.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isEmpty
                  ? theme.colorScheme.error.withOpacity(0.1)
                  : theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isEmpty
                    ? theme.colorScheme.error.withOpacity(0.3)
                    : theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Text(
              destination,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isEmpty
                    ? theme.colorScheme.error
                    : theme.colorScheme.onPrimaryContainer,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: widget.onExport,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('خروجی جدول'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _copyTableToClipboard,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('کپی'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const Spacer(),
          IconButton.outlined(
            onPressed: _resetHighlights,
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: 'پاک کردن هایلایت‌ها',
          ),
        ],
      ),
    );
  }

  void _handleCellTap(String state, String symbol) {
    setState(() {
      final cellKey = '$state-$symbol';
      if (_highlightedCells.contains(cellKey)) {
        _highlightedCells.remove(cellKey);
      } else {
        _highlightedCells.add(cellKey);
      }
    });

    widget.onCellTap?.call(state, symbol);
    HapticFeedback.selectionClick();
  }

  void _resetHighlights() {
    setState(() {
      _highlightedCells.clear();
    });
    HapticFeedback.lightImpact();
  }

  void _copyTableToClipboard() {
    final tableData = widget.dfa.getTransitionTable();
    final sortedStates = tableData.keys.toList()..sort();
    final sortedAlphabet = widget.dfa.alphabet.toList()..sort();

    final buffer = StringBuffer();

    // Header
    buffer.write('State\t');
    buffer.writeln(sortedAlphabet.join('\t'));

    // Rows
    for (final state in sortedStates) {
      buffer.write('$state\t');
      final transitions = sortedAlphabet.map((symbol) {
        return tableData[state]?[symbol] ?? '∅';
      }).join('\t');
      buffer.writeln(transitions);
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جدول کپی شد'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
