//
//  input_tape_viewer.dart
//  JFlutter
//
//  Widget para visualização da fita de entrada do FSA (DFA/NFA), acessível
//  durante edição e simulação. Mostra símbolos de entrada e posição atual.
//
//  Created for Phase 2 improvements - Enhanced Step-by-Step Visualization
//

import 'package:flutter/material.dart';

/// Estado da fita de entrada em um momento específico
class InputTapeState {
  final List<String> symbols;
  final int currentPosition;
  final String? lastOperation;

  const InputTapeState({
    required this.symbols,
    required this.currentPosition,
    this.lastOperation,
  });

  /// Fita vazia/inicial
  const InputTapeState.initial()
    : symbols = const [],
      currentPosition = 0,
      lastOperation = null;

  bool get isEmpty => symbols.isEmpty;

  /// Símbolo atual sendo lido
  String? get currentSymbol {
    if (currentPosition < 0 || currentPosition >= symbols.length) {
      return null;
    }
    return symbols[currentPosition];
  }

  /// Se a leitura está completa
  bool get isComplete => currentPosition >= symbols.length;

  /// Quantidade de símbolos lidos
  int get symbolsRead => currentPosition;

  /// Quantidade de símbolos restantes
  int get symbolsRemaining => symbols.length - currentPosition;
}

/// Painel flutuante para visualização da fita de entrada
class InputTapePanel extends StatefulWidget {
  final InputTapeState tapeState;
  final Set<String> inputAlphabet;
  final bool isSimulating;
  final VoidCallback? onClear;

  const InputTapePanel({
    super.key,
    required this.tapeState,
    required this.inputAlphabet,
    this.isSimulating = false,
    this.onClear,
  });

  @override
  State<InputTapePanel> createState() => _InputTapePanelState();
}

class _InputTapePanelState extends State<InputTapePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _horizontalScrollController = ScrollController();
  }

  @override
  void didUpdateWidget(InputTapePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tapeState.currentPosition !=
        widget.tapeState.currentPosition) {
      _animationController.forward(from: 0);
      _scrollToCurrentPosition();
    }
  }

  void _scrollToCurrentPosition() {
    // Auto-scroll para manter posição atual visível
    if (_horizontalScrollController.hasClients) {
      const cellWidth = 50.0;
      final targetOffset = widget.tapeState.currentPosition * cellWidth;
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
                  Icons.text_fields,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Input (${widget.tapeState.symbolsRead}/${widget.tapeState.symbols.length})',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.isSimulating) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 12),

            // Tape Visual
            SizedBox(height: 60, child: _buildTapeContent(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildTapeContent(ThemeData theme) {
    if (widget.tapeState.isEmpty) {
      return Center(
        child: Text(
          'No input',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(widget.tapeState.symbols.length, (index) {
          final isCurrent = index == widget.tapeState.currentPosition;
          final isRead = index < widget.tapeState.currentPosition;
          return _buildTapeCell(
            widget.tapeState.symbols[index],
            isCurrent,
            isRead,
            theme,
          );
        }),
      ),
    );
  }

  Widget _buildTapeCell(
    String symbol,
    bool isCurrent,
    bool isRead,
    ThemeData theme,
  ) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.colorScheme.primaryContainer
            : isRead
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: isCurrent
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isCurrent ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isCurrent)
            Icon(
              Icons.arrow_downward,
              size: 10,
              color: theme.colorScheme.primary,
            ),
          Text(
            symbol,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'monospace',
              color: isCurrent
                  ? theme.colorScheme.primary
                  : isRead
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
