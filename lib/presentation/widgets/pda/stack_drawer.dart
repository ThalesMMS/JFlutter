//
//  stack_drawer.dart
//  JFlutter
//
//  Bottom drawer para visualização da pilha do PDA, acessível durante edição
//  e simulação. Suporta modo compacto para mobile e expandido para desktop.
//
//  Created for Phase 1 improvements - November 2025
//

import 'package:flutter/material.dart';

/// Estado da pilha em um momento específico
class StackState {
  final List<String> symbols;
  final String? lastOperation;

  const StackState({required this.symbols, this.lastOperation});

  /// Pilha vazia
  const StackState.empty() : symbols = const [], lastOperation = null;

  bool get isEmpty => symbols.isEmpty;
  String? get top => symbols.isEmpty ? null : symbols.last;
  int get size => symbols.length;

  /// Cria cópia com push
  StackState push(String symbol) {
    return StackState(
      symbols: [...symbols, symbol],
      lastOperation: 'push $symbol',
    );
  }

  /// Cria cópia com pop
  StackState pop() {
    if (symbols.isEmpty) return this;
    final popped = symbols.last;
    return StackState(
      symbols: symbols.sublist(0, symbols.length - 1),
      lastOperation: 'pop $popped',
    );
  }
}

/// Painel flutuante para visualização da pilha
class PDAStackPanel extends StatefulWidget {
  final StackState stackState;
  final String initialStackSymbol;
  final Set<String> stackAlphabet;
  final bool isSimulating;
  final VoidCallback? onClear;

  const PDAStackPanel({
    super.key,
    required this.stackState,
    required this.initialStackSymbol,
    required this.stackAlphabet,
    this.isSimulating = false,
    this.onClear,
  });

  @override
  State<PDAStackPanel> createState() => _PDAStackPanelState();
}

class _PDAStackPanelState extends State<PDAStackPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(PDAStackPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stackState.symbols != widget.stackState.symbols) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 160,
        constraints: const BoxConstraints(maxHeight: 220),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.layers, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Stack (${widget.stackState.size})',
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

            // Content
            Flexible(
              child: widget.stackState.isEmpty
                  ? Center(
                      child: Text(
                        'Empty\n(Z₀: ${widget.initialStackSymbol})',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      itemCount: widget.stackState.symbols.length,
                      itemBuilder: (context, index) {
                        // Show from top to bottom
                        final reversedIndex =
                            widget.stackState.symbols.length - 1 - index;
                        final symbol = widget.stackState.symbols[reversedIndex];
                        final isTop = index == 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isTop
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              if (isTop) ...[
                                Icon(
                                  Icons.arrow_right,
                                  size: 12,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                symbol,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: isTop
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            if (widget.onClear != null) ...[
              const Divider(height: 12),
              SizedBox(
                height: 28,
                child: TextButton.icon(
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.clear_all, size: 14),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
