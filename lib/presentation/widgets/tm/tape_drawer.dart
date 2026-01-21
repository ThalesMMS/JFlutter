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

  const TMTapePanel({
    super.key,
    required this.tapeState,
    required this.tapeAlphabet,
    this.isSimulating = false,
    this.onClear,
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
    // Auto-scroll para manter cabeça visível
    if (_horizontalScrollController.hasClients) {
      const cellWidth = 50.0; // Adjusted for compact view
      final targetOffset = widget.tapeState.headPosition * cellWidth;
      _horizontalScrollController.animateTo(
        targetOffset,
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(visibleCells.length, (index) {
          final isHead = index == headIndex;
          final wasRead = isHead && widget.tapeState.wasRead;
          final wasWritten = isHead && widget.tapeState.wasWritten;
          return _buildTapeCell(
            visibleCells[index],
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
    bool isHead,
    bool wasRead,
    bool wasWritten,
    ThemeData theme,
    bool isMobile,
  ) {
    return Container(
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
  }
}
