//
//  tape_drawer.dart
//  JFlutter
//
//  Bottom drawer para visualização da fita da Máquina de Turing, acessível
//  durante edição e simulação. Mostra células, posição da cabeça e operações.
//
//  Created for Phase 1 improvements - November 2025
//

import 'package:flutter/material.dart';

/// Estado da fita em um momento específico
class TapeState {
  final List<String> cells;
  final int headPosition;
  final String blankSymbol;
  final String? lastOperation;
  final String? lastReadSymbol;
  final String? lastWriteSymbol;

  const TapeState({
    required this.cells,
    required this.headPosition,
    this.blankSymbol = '□',
    this.lastOperation,
    this.lastReadSymbol,
    this.lastWriteSymbol,
  });

  /// Fita vazia/inicial
  TapeState.initial({this.blankSymbol = '□'})
    : cells = const [],
      headPosition = 0,
      lastOperation = null,
      lastReadSymbol = null,
      lastWriteSymbol = null;

  bool get isEmpty => cells.isEmpty;

  /// Célula sob a cabeça
  String get currentCell {
    if (headPosition < 0 || headPosition >= cells.length) {
      return blankSymbol;
    }
    return cells[headPosition];
  }

  /// True se a célula atual foi lida na última operação
  bool get wasRead => lastReadSymbol != null;

  /// True se a célula atual foi escrita na última operação
  bool get wasWritten => lastWriteSymbol != null;

  /// Retorna células visíveis (com padding de blanks se necessário)
  List<String> getVisibleCells({int padding = 3}) {
    if (cells.isEmpty) {
      return List.filled(padding * 2 + 1, blankSymbol);
    }

    final start = headPosition - padding;
    final end = headPosition + padding + 1;
    final result = <String>[];

    for (var i = start; i < end; i++) {
      if (i < 0 || i >= cells.length) {
        result.add(blankSymbol);
      } else {
        result.add(cells[i]);
      }
    }

    return result;
  }

  /// Índice da cabeça nas células visíveis
  int getHeadIndexInVisible({int padding = 3}) {
    return padding;
  }
}

/// Painel flutuante para visualização da fita
class TMTapePanel extends StatefulWidget {
  final TapeState tapeState;
  final Set<String> tapeAlphabet;
  final bool isSimulating;
  final VoidCallback? onClear;
  final void Function(int cellIndex, String newValue)? onCellEdit;

  const TMTapePanel({
    super.key,
    required this.tapeState,
    required this.tapeAlphabet,
    this.isSimulating = false,
    this.onClear,
    this.onCellEdit,
  });

  @override
  State<TMTapePanel> createState() => _TMTapePanelState();
}

class _TMTapePanelState extends State<TMTapePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _horizontalScrollController;
  int _previousHeadPosition = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _horizontalScrollController = ScrollController();
    _previousHeadPosition = widget.tapeState.headPosition;
  }

  @override
  void didUpdateWidget(TMTapePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tapeState.headPosition != widget.tapeState.headPosition) {
      _animationController.forward(from: 0);
      _previousHeadPosition = oldWidget.tapeState.headPosition;
      _scrollToHead();
    }
  }

  void _scrollToHead() {
    // Auto-scroll para manter cabeça centralizada na viewport
    if (_horizontalScrollController.hasClients) {
      const cellWidth = 50.0; // Adjusted for compact view
      final scrollPosition = _horizontalScrollController.position;
      final viewportWidth = scrollPosition.viewportDimension;

      // Calcula offset para centralizar a cabeça
      final headCenterOffset = widget.tapeState.headPosition * cellWidth;
      final targetOffset = headCenterOffset - (viewportWidth / 2) + (cellWidth / 2);

      // Clamp para não ultrapassar os limites do conteúdo
      final minOffset = scrollPosition.minScrollExtent;
      final maxOffset = scrollPosition.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(minOffset, maxOffset);

      _horizontalScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _showCellEditDialog(int cellIndex, String currentSymbol) async {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: currentSymbol);
    final focusNode = FocusNode();

    // Request focus after dialog is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Cell $cellIndex',
          style: theme.textTheme.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick selection buttons for tape alphabet
            if (widget.tapeAlphabet.isNotEmpty) ...[
              Text(
                'Tape Alphabet:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Blank symbol button
                  _buildSymbolButton(
                    widget.tapeState.blankSymbol,
                    () {
                      controller.text = widget.tapeState.blankSymbol;
                    },
                    theme,
                  ),
                  // Tape alphabet symbols
                  ...widget.tapeAlphabet.map(
                    (symbol) => _buildSymbolButton(
                      symbol,
                      () {
                        controller.text = symbol;
                      },
                      theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            // Text input field
            TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Symbol',
                hintText: 'Enter a symbol',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                  },
                ),
              ),
              maxLength: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.isEmpty
                  ? widget.tapeState.blankSymbol
                  : controller.text;
              Navigator.of(context).pop(value);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    controller.dispose();
    focusNode.dispose();

    if (result != null && mounted) {
      widget.onCellEdit?.call(cellIndex, result);
    }
  }

  Widget _buildSymbolButton(
    String symbol,
    VoidCallback onPressed,
    ThemeData theme,
  ) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          symbol,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.horizontal_rule,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tape (Head: ${widget.tapeState.headPosition})',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.onClear != null)
                  SizedBox(
                    width: 60,
                    height: 24,
                    child: TextButton(
                      onPressed: widget.onClear,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: theme.colorScheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 12),

            // Tape Visual
            SizedBox(
              height: 60,
              child: _buildTapeContent(theme, true), // Always compact mode
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTapeContent(ThemeData theme, bool isMobile) {
    if (widget.tapeState.isEmpty) {
      return Center(
        child: Text(
          'Empty (□: ${widget.tapeState.blankSymbol})',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    final visibleCells = widget.tapeState.getVisibleCells(padding: 4);
    final headIndex = widget.tapeState.getHeadIndexInVisible(padding: 4);
    final padding = 4;
    final startIndex = widget.tapeState.headPosition - padding;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(visibleCells.length, (index) {
          final isHead = index == headIndex;
          final wasRead = isHead && widget.tapeState.wasRead;
          final wasWritten = isHead && widget.tapeState.wasWritten;
          final actualCellIndex = startIndex + index;
          return _buildTapeCell(
            visibleCells[index],
            actualCellIndex,
            isHead,
            wasRead,
            wasWritten,
            theme,
            true,
          );
        }),
      ),
    );
  }

  Widget _buildTapeCell(
    String symbol,
    int cellIndex,
    bool isHead,
    bool wasRead,
    bool wasWritten,
    ThemeData theme,
    bool isMobile,
  ) {
    final canEdit = !widget.isSimulating && widget.onCellEdit != null;

    final cellWidget = Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isHead
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: isHead
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isHead ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Main cell content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isHead)
                Icon(
                  Icons.arrow_downward,
                  size: 10,
                  color: theme.colorScheme.primary,
                ),
              Text(
                symbol,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isHead ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'monospace',
                  color: isHead
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          // Read indicator badge (top-left)
          if (wasRead)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.visibility,
                  size: 8,
                  color: theme.colorScheme.onTertiary,
                ),
              ),
            ),
          // Write indicator badge (top-right)
          if (wasWritten)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  size: 8,
                  color: theme.colorScheme.onSecondary,
                ),
              ),
            ),
        ],
      ),
    );

    if (!canEdit) {
      return cellWidget;
    }

    return InkWell(
      onTap: () => _showCellEditDialog(cellIndex, symbol),
      borderRadius: BorderRadius.circular(4),
      child: cellWidget,
    );
  }
}
