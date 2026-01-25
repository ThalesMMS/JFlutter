//
//  nfa_computation_tree_viewer.dart
//  JFlutter
//
//  Visualiza a árvore de computação de um NFA, exibindo todos os caminhos
//  não determinísticos com ramificações, destacando caminhos de aceitação em
//  verde e becos sem saída em vermelho. Oferece visualização hierárquica clara
//  para auxiliar estudantes a compreender o não determinismo em autômatos finitos.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';

import '../../../core/models/nfa_computation_tree.dart';
import '../../../core/models/nfa_path_node.dart';

/// Widget that displays the computation tree for an NFA simulation.
///
/// This widget renders the complete branching structure of an NFA execution,
/// showing all non-deterministic paths explored during simulation. Accepting
/// paths are highlighted in green, while dead-ends are marked in red to help
/// students understand NFA behavior.
///
/// Features:
/// - Hierarchical tree visualization with proper indentation
/// - Color-coded paths (green for accepting, red for dead-ends)
/// - Displays state, remaining input, and transitions at each node
/// - Collapsible branches for large trees to maintain usability
/// - Educational annotations for key concepts
/// - Material 3 theming integration
class NFAComputationTreeViewer extends StatefulWidget {
  /// The computation tree to visualize
  final NFAComputationTree computationTree;

  /// Optional title for the tree viewer
  final String? title;

  const NFAComputationTreeViewer({
    super.key,
    required this.computationTree,
    this.title,
  });

  @override
  State<NFAComputationTreeViewer> createState() =>
      _NFAComputationTreeViewerState();
}

class _NFAComputationTreeViewerState extends State<NFAComputationTreeViewer> {
  /// Threshold for showing collapse button on branches
  static const int branchCollapseThreshold = 3;

  /// Number of children to show when collapsed
  static const int collapsedChildrenCount = 3;

  /// Set of collapsed node identities (using hashCode as unique identifier)
  final Set<int> _collapsedNodes = {};

  /// Global collapse state
  bool _allCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with tree statistics
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_tree,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title ?? 'NFA Computation Tree',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Global collapse/expand button
                  if (_hasCollapsibleBranches())
                    TextButton.icon(
                      onPressed: _toggleAllBranches,
                      icon: Icon(
                        _allCollapsed ? Icons.unfold_more : Icons.unfold_less,
                      ),
                      label: Text(
                        _allCollapsed ? 'Expand All' : 'Collapse All',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatistics(context),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Legend
        _buildLegend(context),
        const SizedBox(height: 12),

        // Tree visualization
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTree(context),
          ),
        ),
      ],
    );
  }

  /// Checks if tree has branches that can be collapsed
  bool _hasCollapsibleBranches() {
    return _countCollapsibleNodes(widget.computationTree.root) > 0;
  }

  /// Counts nodes with many children recursively
  int _countCollapsibleNodes(NFAPathNode node) {
    int count = 0;
    if (node.children.length > branchCollapseThreshold) {
      count++;
    }
    for (final child in node.children) {
      count += _countCollapsibleNodes(child);
    }
    return count;
  }

  /// Toggles all collapsible branches
  void _toggleAllBranches() {
    setState(() {
      _allCollapsed = !_allCollapsed;
      _collapsedNodes.clear();
      if (_allCollapsed) {
        _addAllCollapsibleNodes(widget.computationTree.root);
      }
    });
  }

  /// Adds all nodes with many children to collapsed set
  void _addAllCollapsibleNodes(NFAPathNode node) {
    if (node.children.length > branchCollapseThreshold) {
      _collapsedNodes.add(node.hashCode);
    }
    for (final child in node.children) {
      _addAllCollapsibleNodes(child);
    }
  }

  /// Toggles collapse state for a specific node
  void _toggleNodeCollapse(NFAPathNode node) {
    setState(() {
      final nodeId = node.hashCode;
      if (_collapsedNodes.contains(nodeId)) {
        _collapsedNodes.remove(nodeId);
      } else {
        _collapsedNodes.add(nodeId);
      }
    });
  }

  /// Checks if a node is collapsed
  bool _isNodeCollapsed(NFAPathNode node) {
    return _collapsedNodes.contains(node.hashCode);
  }

  /// Builds the statistics summary for the tree
  Widget _buildStatistics(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildStatItem(
          context,
          icon: Icons.hub,
          label: 'Total Nodes',
          value: '${widget.computationTree.totalNodes}',
          color: colorScheme.onSurfaceVariant,
        ),
        _buildStatItem(
          context,
          icon: Icons.call_split,
          label: 'Paths',
          value: '${widget.computationTree.totalPaths}',
          color: colorScheme.onSurfaceVariant,
        ),
        _buildStatItem(
          context,
          icon: Icons.check_circle,
          label: 'Accepting',
          value: '${widget.computationTree.acceptingPathCount}',
          color: Colors.green.shade700,
        ),
        _buildStatItem(
          context,
          icon: Icons.cancel,
          label: 'Dead-ends',
          value: '${widget.computationTree.deadEndPathCount}',
          color: Colors.red.shade700,
        ),
        _buildStatItem(
          context,
          icon: Icons.height,
          label: 'Max Depth',
          value: '${widget.computationTree.maxDepth}',
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  /// Builds a single statistic item
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Builds the color legend
  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(
            context,
            color: Colors.green.shade700,
            label: 'Accepting path',
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 16),
          _buildLegendItem(
            context,
            color: Colors.red.shade700,
            label: 'Dead-end path',
            icon: Icons.cancel_outlined,
          ),
          const SizedBox(width: 16),
          _buildLegendItem(
            context,
            color: colorScheme.onSurface,
            label: 'Active path',
            icon: Icons.radio_button_unchecked,
          ),
        ],
      ),
    );
  }

  /// Builds a single legend item
  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }

  /// Builds the tree structure recursively
  Widget _buildTree(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildNode(context, widget.computationTree.root, 0, true)],
    );
  }

  /// Builds a single tree node and its children
  Widget _buildNode(
    BuildContext context,
    NFAPathNode node,
    int depth,
    bool isRoot,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine node color based on status
    Color nodeColor;
    Color backgroundColor;
    IconData nodeIcon;

    if (node.isAccepting) {
      nodeColor = Colors.green.shade700;
      backgroundColor = Colors.green.shade50;
      nodeIcon = Icons.check_circle;
    } else if (node.isDeadEnd) {
      nodeColor = Colors.red.shade700;
      backgroundColor = Colors.red.shade50;
      nodeIcon = Icons.cancel;
    } else {
      nodeColor = colorScheme.onSurface;
      backgroundColor = colorScheme.surface;
      nodeIcon = Icons.radio_button_unchecked;
    }

    // Calculate left padding for indentation
    const indentSize = 40.0;
    final leftPadding = depth * indentSize;

    // Determine if this node should show collapse button
    final hasCollapsibleChildren =
        node.children.length > branchCollapseThreshold;
    final isCollapsed = _isNodeCollapsed(node);

    // Determine visible children
    final visibleChildren = isCollapsed && hasCollapsibleChildren
        ? node.children.take(collapsedChildrenCount).toList()
        : node.children;
    final hiddenChildrenCount = node.children.length - visibleChildren.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current node
        Padding(
          padding: EdgeInsets.only(left: leftPadding, bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Branching indicator
              if (!isRoot) ...[
                CustomPaint(
                  size: const Size(20, 20),
                  painter: _BranchLinePainter(colorScheme.outline),
                ),
                const SizedBox(width: 4),
              ],

              // Node container
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: nodeColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(nodeIcon, size: 16, color: nodeColor),
                    const SizedBox(width: 6),
                    _buildNodeContent(context, node, nodeColor),
                  ],
                ),
              ),

              // Collapse/expand button for nodes with many children
              if (hasCollapsibleChildren) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _toggleNodeCollapse(node),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCollapsed
                              ? Icons.keyboard_arrow_right
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        Text(
                          '${node.children.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Child nodes
        if (visibleChildren.isNotEmpty)
          ...visibleChildren.map(
            (child) => _buildNode(context, child, depth + 1, false),
          ),

        // Hidden children indicator
        if (hiddenChildrenCount > 0)
          Padding(
            padding: EdgeInsets.only(left: leftPadding + 24, bottom: 4),
            child: InkWell(
              onTap: () => _toggleNodeCollapse(node),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '+$hiddenChildrenCount more branch${hiddenChildrenCount > 1 ? 'es' : ''} hidden',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the content display for a node
  Widget _buildNodeContent(
    BuildContext context,
    NFAPathNode node,
    Color textColor,
  ) {
    final theme = Theme.of(context);
    final remaining = node.remainingInput.isEmpty ? 'ε' : node.remainingInput;
    final transition = node.inputSymbol != null
        ? ' via ${node.inputSymbol}'
        : (node.isInitial ? ' (start)' : '');

    return Text(
      'q=${node.currentState} | remaining=$remaining$transition',
      style: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Custom painter for drawing branch connection lines
class _BranchLinePainter extends CustomPainter {
  final Color color;

  _BranchLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw L-shaped branch line
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BranchLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
