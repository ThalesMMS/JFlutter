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

  /// Cria cópia substituindo o topo
  StackState replace(String newSymbol) {
    if (symbols.isEmpty) return push(newSymbol);
    final newSymbols = [...symbols];
    newSymbols[newSymbols.length - 1] = newSymbol;
    return StackState(
      symbols: newSymbols,
      lastOperation: 'replace with $newSymbol',
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
  late Animation<Offset> _slideAnimation;
  int _previousStackSize = 0;
  bool _isPushAnimation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from bottom
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _scrollController = ScrollController();
    _previousStackSize = widget.stackState.size;
  }

  @override
  void didUpdateWidget(PDAStackPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stackState.symbols != widget.stackState.symbols) {
      // Detect push operation (stack grew)
      _isPushAnimation = widget.stackState.size > oldWidget.stackState.size;
      _animationController.forward(from: 0);
      _previousStackSize = widget.stackState.size;
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    // Auto-scroll para manter topo da pilha visível
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

            // Stack Info Panel
            _buildStackInfo(theme),
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

                        Widget itemWidget = Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
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
                              ),
                              if (isTop)
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'TOP',
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );

                        // Apply slide animation to top item on push
                        if (isTop && _isPushAnimation) {
                          itemWidget = SlideTransition(
                            position: _slideAnimation,
                            child: itemWidget,
                          );
                        }

                        return FadeTransition(
                          opacity: _animationController,
                          child: itemWidget,
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

  /// Builds compact info panel showing top symbol, size, and last operation
  Widget _buildStackInfo(ThemeData theme) {
    final topSymbol = widget.stackState.top ?? '(empty)';
    final size = widget.stackState.size;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Top: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                ),
              ),
              Text(
                topSymbol,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Size: $size',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
            ),
          ),
          if (widget.stackState.lastOperation != null) ...[
            const SizedBox(height: 2),
            Text(
              'Last op: ${widget.stackState.lastOperation}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
