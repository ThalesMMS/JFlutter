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
  int? _highlightedIndex;

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

  void _handleItemTap(int index) {
    setState(() {
      // Toggle highlight: if tapping the same item, deselect; otherwise select
      _highlightedIndex = _highlightedIndex == index ? null : index;
    });
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
        width: 145, // Compact width for mobile
        constraints: const BoxConstraints(maxHeight: 200), // Reduced height
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.layers, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6), // Reduced spacing
                Expanded(
                  child: Text(
                    'Stack (${widget.stackState.size})',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13, // Compact font size
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isSimulating)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Divider(height: 10), // Reduced divider height

            // Stack Info Panel
            _buildStackInfo(theme),
            const Divider(height: 10), // Reduced divider height

            // Content
            Flexible(
              child: widget.stackState.isEmpty
                  ? Center(
                      child: Text(
                        'Empty\n(Z₀: ${widget.initialStackSymbol})',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11, // Compact font size
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
                        final isHighlighted = _highlightedIndex == index;

                        Widget itemWidget = GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _handleItemTap(index),
                          child: Container(
                            // Ensure minimum 40x40 touch target (compact)
                            constraints: const BoxConstraints(
                              minHeight: 40,
                              minWidth: 40,
                            ),
                            margin: const EdgeInsets.only(bottom: 3), // Reduced
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8, // Reduced
                                    vertical: 8, // Reduced
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHighlighted
                                        ? theme.colorScheme.secondaryContainer
                                        : isTop
                                            ? theme.colorScheme.primaryContainer
                                            : theme.colorScheme.surfaceContainerHighest,
                                    border: isHighlighted
                                        ? Border.all(
                                            color: theme.colorScheme.secondary,
                                            width: 2,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isTop) ...[
                                        Icon(
                                          Icons.arrow_right,
                                          size: 11, // Slightly smaller
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 3),
                                      ],
                                      Flexible(
                                        child: Text(
                                          symbol,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: isTop || isHighlighted
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 11, // Compact font size
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isTop)
                                  Positioned(
                                    top: -5,
                                    right: -5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'TOP',
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                          fontSize: 7, // Compact badge
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
              const Divider(height: 10), // Reduced
              SizedBox(
                width: 60, // Fixed width like tape_drawer
                height: 24, // Match tape_drawer pattern
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // More compact
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Top: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10, // Smaller for mobile
                ),
              ),
              Flexible(
                child: Text(
                  topSymbol,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11, // Slightly reduced
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1), // Reduced spacing
          Text(
            'Size: $size',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10, // Smaller for mobile
            ),
          ),
          if (widget.stackState.lastOperation != null) ...[
            const SizedBox(height: 1), // Reduced spacing
            Text(
              'Op: ${widget.stackState.lastOperation}', // Shortened label
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9, // Smaller for mobile
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
