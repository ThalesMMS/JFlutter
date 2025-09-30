import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';

/// ویجت پیشرفته دیاگرام حالت با قابلیت‌های کامل
class AdvancedStateDiagram extends StatefulWidget {
  final StateDiagramData data;
  final DiagramController? controller;
  final DiagramTheme? theme;
  final VoidCallback? onDataChanged;
  final Function(String nodeId)? onNodeSelected;
  final Function(String edgeId)? onEdgeSelected;
  final Function(List<String> selectedIds)? onSelectionChanged;
  final bool enableMultiSelection;
  final bool enableDragDrop;
  final bool enableContextMenu;
  final bool enableKeyboardShortcuts;
  final bool enableTouchGestures;
  final bool enableSearch;
  final bool enableStatistics;
  final bool enableMiniMap;
  final double minZoom;
  final double maxZoom;

  const AdvancedStateDiagram({
    super.key,
    required this.data,
    this.controller,
    this.theme,
    this.onDataChanged,
    this.onNodeSelected,
    this.onEdgeSelected,
    this.onSelectionChanged,
    this.enableMultiSelection = true,
    this.enableDragDrop = true,
    this.enableContextMenu = true,
    this.enableKeyboardShortcuts = true,
    this.enableTouchGestures = true,
    this.enableSearch = true,
    this.enableStatistics = true,
    this.enableMiniMap = false,
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
  });

  @override
  State<AdvancedStateDiagram> createState() => _AdvancedStateDiagramState();
}

class _AdvancedStateDiagramState extends State<AdvancedStateDiagram>
    with TickerProviderStateMixin {
  // Controllers
  late DiagramController _controller;
  late TransformationController _transformationController;
  late AnimationController _animationController;

  // State management
  final Set<String> _selectedNodes = {};
  final Set<String> _selectedEdges = {};
  final Set<String> _hoveredElements = {};
  final Map<String, Offset> _nodePositions = {};
  final Map<String, GlobalKey> _nodeKeys = {};

  // Interaction state
  bool _isDragging = false;
  bool _isMultiSelecting = false;
  String? _draggedNodeId;
  Offset? _dragStartPosition;
  Rect? _selectionRect;

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _filteredNodes = {};

  // Context menu
  OverlayEntry? _contextMenuOverlay;

  // Focus and keyboard
  final FocusNode _focusNode = FocusNode();

  // Theme
  DiagramTheme? _currentTheme;

  // Statistics
  DiagramStatistics? _statistics;

  // Clipboard
  final Set<String> _copiedNodes = {};
  final Set<String> _copiedEdges = {};

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DiagramController();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializePositions();
    _updateStatistics();
    _setupKeyboardListeners();
    _currentTheme = widget.theme;

    _searchController.addListener(_onSearchChanged);
    _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(AdvancedStateDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _initializePositions();
      _updateStatistics();
    }
    if (oldWidget.theme != widget.theme) {
      setState(() {
        _currentTheme = widget.theme;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _transformationController.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    _contextMenuOverlay?.remove();
    super.dispose();
  }

  void _initializePositions() {
    final nodes = widget.data.nodes;
    if (nodes.isEmpty) return;

    // Auto-layout using force-directed algorithm if positions not set
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (_nodePositions.containsKey(node.id)) continue;

      // Circular layout as fallback
      final angle = (2 * math.pi * i) / nodes.length;
      final radius = 150.0;
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);

      _nodePositions[node.id] = Offset(x, y);
      _nodeKeys[node.id] = GlobalKey();
    }
  }

  void _updateStatistics() {
    final nodes = widget.data.nodes;
    final edges = widget.data.edges;

    final startStates = nodes.where((n) => n.isStart).length;
    final finalStates = nodes.where((n) => n.isFinal).length;
    final normalStates = nodes.length - startStates - finalStates;

    _statistics = DiagramStatistics(
      totalNodes: nodes.length,
      totalEdges: edges.length,
      startStates: startStates,
      finalStates: finalStates,
      normalStates: normalStates,
      selectedNodes: _selectedNodes.length,
      selectedEdges: _selectedEdges.length,
    );
  }

  void _setupKeyboardListeners() {
    if (!widget.enableKeyboardShortcuts) return;
    // Keyboard shortcuts will be handled in _handleKeyEvent
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredNodes.clear();

      if (_searchQuery.isNotEmpty) {
        for (final node in widget.data.nodes) {
          if (node.label.toLowerCase().contains(_searchQuery) ||
              node.id.toLowerCase().contains(_searchQuery)) {
            _filteredNodes.add(node.id);
          }
        }
      }
    });
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!widget.enableKeyboardShortcuts) return false;
    if (event is! KeyDownEvent) return false;

    final isCtrlPressed =
        event.logicalKey == LogicalKeyboardKey.control ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.controlLeft,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.controlRight,
        );

    final isCmdPressed =
        event.logicalKey == LogicalKeyboardKey.meta ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.metaLeft,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.metaRight,
        );

    final isModifierPressed = isCtrlPressed || isCmdPressed;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        _deleteSelected();
        return true;

      case LogicalKeyboardKey.keyA:
        if (isModifierPressed) {
          _selectAll();
          return true;
        }
        break;

      case LogicalKeyboardKey.keyC:
        if (isModifierPressed) {
          _copySelected();
          return true;
        }
        break;

      case LogicalKeyboardKey.keyV:
        if (isModifierPressed) {
          _pasteSelected();
          return true;
        }
        break;

      case LogicalKeyboardKey.keyZ:
        if (isModifierPressed) {
          _undo();
          return true;
        }
        break;

      case LogicalKeyboardKey.escape:
        _clearSelection();
        return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) => _handleKeyEvent(event)
          ? KeyEventResult.handled
          : KeyEventResult.ignored,
      child: Column(
        children: [
          if (widget.enableSearch) _buildSearchBar(),
          Expanded(
            child: Stack(
              children: [
                _buildMainDiagram(),
                if (widget.enableStatistics) _buildStatisticsPanel(),
                if (widget.enableMiniMap) _buildMiniMap(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _currentTheme?.colorScheme.surface ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search states...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildViewControls(),
        ],
      ),
    );
  }

  Widget _buildViewControls() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_in),
          onPressed: _zoomIn,
          tooltip: 'Zoom In',
        ),
        IconButton(
          icon: const Icon(Icons.zoom_out),
          onPressed: _zoomOut,
          tooltip: 'Zoom Out',
        ),
        IconButton(
          icon: const Icon(Icons.fit_screen),
          onPressed: _fitToScreen,
          tooltip: 'Fit to Screen',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _resetView,
          tooltip: 'Reset View',
        ),
      ],
    );
  }

  Widget _buildMainDiagram() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: widget.minZoom,
      maxScale: widget.maxZoom,
      constrained: false,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onSecondaryTapDown: widget.enableContextMenu
            ? _onSecondaryTapDown
            : null,
        child: CustomPaint(
          painter: StateDiagramPainter(
            data: widget.data,
            nodePositions: _nodePositions,
            selectedNodes: _selectedNodes,
            selectedEdges: _selectedEdges,
            hoveredElements: _hoveredElements,
            theme: _currentTheme,
            searchQuery: _searchQuery,
            filteredNodes: _filteredNodes,
            selectionRect: _selectionRect,
            animationValue: _animationController.value,
          ),
          size: const Size(800, 600),
          child: SizedBox(
            width: 800,
            height: 600,
            child: Stack(children: _buildNodeWidgets()),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNodeWidgets() {
    return widget.data.nodes.map((node) {
      final position = _nodePositions[node.id] ?? Offset.zero;
      final isSelected = _selectedNodes.contains(node.id);
      final isHovered = _hoveredElements.contains(node.id);
      final isFiltered =
          _searchQuery.isNotEmpty && !_filteredNodes.contains(node.id);

      return Positioned(
        left: position.dx - 35,
        top: position.dy - 35,
        child: GestureDetector(
          onTap: () => _onNodeTap(node.id),
          onTapDown: (_) => _onNodeTapDown(node.id),
          onPanStart: widget.enableDragDrop
              ? (details) => _onNodeDragStart(node.id, details)
              : null,
          onPanUpdate: widget.enableDragDrop
              ? (details) => _onNodeDragUpdate(node.id, details)
              : null,
          onPanEnd: widget.enableDragDrop
              ? (details) => _onNodeDragEnd(node.id, details)
              : null,
          child: MouseRegion(
            onEnter: (_) => _onNodeHover(node.id, true),
            onExit: (_) => _onNodeHover(node.id, false),
            child: AnimatedOpacity(
              opacity: isFiltered ? 0.3 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedScale(
                scale: isSelected ? 1.1 : (isHovered ? 1.05 : 1.0),
                duration: const Duration(milliseconds: 150),
                child: StateNodeWidget(
                  key: _nodeKeys[node.id],
                  node: node,
                  isSelected: isSelected,
                  isHovered: isHovered,
                  theme: _currentTheme,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStatisticsPanel() {
    if (_statistics == null) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      right: 16,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Statistics',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatItem('Total States', _statistics!.totalNodes),
              _buildStatItem('Total Transitions', _statistics!.totalEdges),
              _buildStatItem('Start States', _statistics!.startStates),
              _buildStatItem('Final States', _statistics!.finalStates),
              if (_statistics!.selectedNodes > 0)
                _buildStatItem('Selected', _statistics!.selectedNodes),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12)),
          Text(
            '$value',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMap() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.9),
        ),
        child: CustomPaint(
          painter: MiniMapPainter(
            data: widget.data,
            nodePositions: _nodePositions,
            viewport: _transformationController.value,
            theme: _currentTheme,
          ),
        ),
      ),
    );
  }

  // Event Handlers
  void _onTapDown(TapDownDetails details) {
    _focusNode.requestFocus();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isDragging && !widget.enableMultiSelection) {
      _clearSelection();
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isMultiSelecting && widget.enableMultiSelection) {
      _isMultiSelecting = true;
      _dragStartPosition = details.localPosition;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isMultiSelecting && _dragStartPosition != null) {
      setState(() {
        _selectionRect = Rect.fromPoints(
          _dragStartPosition!,
          details.localPosition,
        );
      });
      _updateMultiSelection();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isMultiSelecting) {
      _isMultiSelecting = false;
      _dragStartPosition = null;
      setState(() {
        _selectionRect = null;
      });
    }
  }

  void _onSecondaryTapDown(TapDownDetails details) {
    if (!widget.enableContextMenu) return;
    _showContextMenu(details.globalPosition);
  }

  void _onNodeTap(String nodeId) {
    if (widget.enableMultiSelection &&
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.controlLeft,
        )) {
      _toggleNodeSelection(nodeId);
    } else {
      _selectNode(nodeId);
    }
    widget.onNodeSelected?.call(nodeId);
  }

  void _onNodeTapDown(String nodeId) {
    HapticFeedback.lightImpact();
  }

  void _onNodeDragStart(String nodeId, DragStartDetails details) {
    if (!widget.enableDragDrop) return;

    setState(() {
      _isDragging = true;
      _draggedNodeId = nodeId;
    });

    if (!_selectedNodes.contains(nodeId)) {
      _selectNode(nodeId);
    }
  }

  void _onNodeDragUpdate(String nodeId, DragUpdateDetails details) {
    if (!widget.enableDragDrop || !_isDragging) return;

    setState(() {
      final currentPosition = _nodePositions[nodeId] ?? Offset.zero;
      _nodePositions[nodeId] = currentPosition + details.delta;

      // Move all selected nodes if multiple are selected
      if (_selectedNodes.length > 1) {
        for (final selectedId in _selectedNodes) {
          if (selectedId != nodeId) {
            final selectedPosition = _nodePositions[selectedId] ?? Offset.zero;
            _nodePositions[selectedId] = selectedPosition + details.delta;
          }
        }
      }
    });
  }

  void _onNodeDragEnd(String nodeId, DragEndDetails details) {
    if (!widget.enableDragDrop) return;

    setState(() {
      _isDragging = false;
      _draggedNodeId = null;
    });

    widget.onDataChanged?.call();
  }

  void _onNodeHover(String nodeId, bool isHovering) {
    setState(() {
      if (isHovering) {
        _hoveredElements.add(nodeId);
      } else {
        _hoveredElements.remove(nodeId);
      }
    });
  }

  void _updateMultiSelection() {
    if (_selectionRect == null) return;

    final newSelection = <String>{};
    for (final node in widget.data.nodes) {
      final position = _nodePositions[node.id] ?? Offset.zero;
      if (_selectionRect!.contains(position)) {
        newSelection.add(node.id);
      }
    }

    setState(() {
      _selectedNodes.clear();
      _selectedNodes.addAll(newSelection);
    });

    _updateStatistics();
    widget.onSelectionChanged?.call(_selectedNodes.toList());
  }

  // Selection methods
  void _selectNode(String nodeId) {
    setState(() {
      _selectedNodes.clear();
      _selectedNodes.add(nodeId);
    });
    _updateStatistics();
    widget.onSelectionChanged?.call([nodeId]);
  }

  void _toggleNodeSelection(String nodeId) {
    setState(() {
      if (_selectedNodes.contains(nodeId)) {
        _selectedNodes.remove(nodeId);
      } else {
        _selectedNodes.add(nodeId);
      }
    });
    _updateStatistics();
    widget.onSelectionChanged?.call(_selectedNodes.toList());
  }

  void _clearSelection() {
    setState(() {
      _selectedNodes.clear();
      _selectedEdges.clear();
    });
    _updateStatistics();
    widget.onSelectionChanged?.call([]);
  }

  void _selectAll() {
    setState(() {
      _selectedNodes.clear();
      _selectedNodes.addAll(widget.data.nodes.map((n) => n.id));
    });
    _updateStatistics();
    widget.onSelectionChanged?.call(_selectedNodes.toList());
  }

  // Keyboard shortcuts
  void _deleteSelected() {
    if (_selectedNodes.isEmpty && _selectedEdges.isEmpty) return;

    // TODO: Implement delete functionality
    // This would typically involve calling a method on the data model
    _clearSelection();
    widget.onDataChanged?.call();
  }

  void _copySelected() {
    _copiedNodes.clear();
    _copiedEdges.clear();
    _copiedNodes.addAll(_selectedNodes);
    _copiedEdges.addAll(_selectedEdges);
  }

  void _pasteSelected() {
    if (_copiedNodes.isEmpty) return;

    // TODO: Implement paste functionality
    // This would involve duplicating nodes and updating positions
    widget.onDataChanged?.call();
  }

  void _undo() {
    // TODO: Implement undo functionality
    // This would require maintaining a history of changes
  }

  // View controls
  void _zoomIn() {
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    if (scale < widget.maxZoom) {
      _transformationController.value = matrix * Matrix4.identity()
        ..scale(1.2);
    }
  }

  void _zoomOut() {
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    if (scale > widget.minZoom) {
      _transformationController.value = matrix * Matrix4.identity()
        ..scale(0.8);
    }
  }

  void _fitToScreen() {
    // Calculate bounds of all nodes
    if (_nodePositions.isEmpty) return;

    final positions = _nodePositions.values;
    final minX = positions.map((p) => p.dx).reduce(math.min) - 50;
    final maxX = positions.map((p) => p.dx).reduce(math.max) + 50;
    final minY = positions.map((p) => p.dy).reduce(math.min) - 50;
    final maxY = positions.map((p) => p.dy).reduce(math.max) + 50;

    final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    final viewportSize = MediaQuery.of(context).size;

    final scaleX = viewportSize.width / bounds.width;
    final scaleY = viewportSize.height / bounds.height;
    final scale = math.min(scaleX, scaleY) * 0.8; // Add some padding

    _transformationController.value = Matrix4.identity()
      ..translate(-bounds.left, -bounds.top)
      ..scale(scale);
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  // Context menu
  void _showContextMenu(Offset globalPosition) {
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => _hideContextMenu(),
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: globalPosition.dx,
                top: globalPosition.dy,
                child: _buildContextMenu(),
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_contextMenuOverlay!);
  }

  void _hideContextMenu() {
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = null;
  }

  Widget _buildContextMenu() {
    return Card(
      elevation: 8,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContextMenuItem(
              'Add State',
              Icons.add_circle_outline,
              _addState,
            ),
            _buildContextMenuItem(
              'Delete Selected',
              Icons.delete_outline,
              _deleteSelected,
            ),
            const Divider(height: 1),
            _buildContextMenuItem('Copy', Icons.copy, _copySelected),
            _buildContextMenuItem('Paste', Icons.paste, _pasteSelected),
            const Divider(height: 1),
            _buildContextMenuItem('Select All', Icons.select_all, _selectAll),
            _buildContextMenuItem(
              'Clear Selection',
              Icons.clear,
              _clearSelection,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenuItem(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        _hideContextMenu();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
    );
  }

  void _addState() {
    // TODO: Implement add state functionality
    widget.onDataChanged?.call();
  }
}

/// Widget برای نمایش نود حالت
class StateNodeWidget extends StatelessWidget {
  final StateNode node;
  final bool isSelected;
  final bool isHovered;
  final DiagramTheme? theme;

  const StateNodeWidget({
    super.key,
    required this.node,
    this.isSelected = false,
    this.isHovered = false,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getNodeColor().withOpacity(0.2),
        border: Border.all(color: _getNodeColor(), width: isSelected ? 3 : 2),
        boxShadow: [
          if (isHovered || isSelected)
            BoxShadow(
              color: _getNodeColor().withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              node.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: theme?.colorScheme.textPrimary ?? Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (node.isFinal)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _getNodeColor(), width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getNodeColor() {
    if (node.isStart) {
      return theme?.colorScheme.stateStart ?? Colors.green;
    } else if (node.isFinal) {
      return theme?.colorScheme.stateFinal ?? Colors.red;
    } else if (isSelected) {
      return theme?.colorScheme.stateSelected ?? Colors.orange;
    } else if (isHovered) {
      return theme?.colorScheme.stateHovered ?? Colors.purple;
    } else {
      return theme?.colorScheme.stateDefault ?? Colors.blue;
    }
  }
}

/// رسم‌کننده اصلی دیاگرام
class StateDiagramPainter extends CustomPainter {
  final StateDiagramData data;
  final Map<String, Offset> nodePositions;
  final Set<String> selectedNodes;
  final Set<String> selectedEdges;
  final Set<String> hoveredElements;
  final DiagramTheme? theme;
  final String searchQuery;
  final Set<String> filteredNodes;
  final Rect? selectionRect;
  final double animationValue;

  StateDiagramPainter({
    required this.data,
    required this.nodePositions,
    required this.selectedNodes,
    required this.selectedEdges,
    required this.hoveredElements,
    this.theme,
    this.searchQuery = '',
    required this.filteredNodes,
    this.selectionRect,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid
    _drawGrid(canvas, size);

    // Draw edges
    _drawEdges(canvas);

    // Draw selection rectangle
    if (selectionRect != null) {
      _drawSelectionRect(canvas);
    }

    // Draw search highlights
    if (searchQuery.isNotEmpty) {
      _drawSearchHighlights(canvas);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (theme?.colorScheme.grid ?? Colors.grey[300]!).withOpacity(0.5)
      ..strokeWidth = 0.5;

    const gridSize = 20.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawEdges(Canvas canvas) {
    final paint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final edge in data.edges) {
      final fromPos = nodePositions[edge.fromId];
      final toPos = nodePositions[edge.toId];

      if (fromPos == null || toPos == null) continue;

      final isSelected = selectedEdges.contains(edge.id);
      final isHighlighted = hoveredElements.contains(edge.id);

      // Edge color
      if (isSelected) {
        paint.color = theme?.colorScheme.edgeSelected ?? Colors.orange;
      } else if (isHighlighted) {
        paint.color = theme?.colorScheme.edgeHighlighted ?? Colors.yellow;
      } else {
        paint.color = theme?.colorScheme.edgeDefault ?? Colors.grey[600]!;
      }

      if (edge.fromId == edge.toId) {
        // Self-loop
        _drawSelfLoop(canvas, fromPos, paint, edge.label);
      } else {
        // Regular edge
        _drawRegularEdge(canvas, fromPos, toPos, paint, edge.label);
      }
    }
  }

  void _drawSelfLoop(
    Canvas canvas,
    Offset nodePos,
    Paint paint,
    String? label,
  ) {
    const radius = 30.0;
    final center = nodePos + const Offset(0, -radius - 35);
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: radius * 2,
    );

    canvas.drawArc(rect, -math.pi / 4, math.pi * 1.5, false, paint);

    // Arrow head
    final arrowPos =
        center +
        Offset(
          radius * math.cos(-math.pi / 4),
          radius * math.sin(-math.pi / 4),
        );
    _drawArrowHead(canvas, arrowPos, -math.pi / 4, paint);

    // Label
    if (label != null && label.isNotEmpty) {
      _drawEdgeLabel(canvas, center + const Offset(0, -15), label);
    }
  }

  void _drawRegularEdge(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
    String? label,
  ) {
    const nodeRadius = 35.0;

    // Calculate edge points (from node border to node border)
    final direction = (to - from);
    final distance = direction.distance;
    final unitVector = direction / distance;

    final startPoint = from + unitVector * nodeRadius;
    final endPoint = to - unitVector * nodeRadius;

    // Draw curve for better visual appeal
    final controlPoint =
        (startPoint + endPoint) / 2 +
        Offset(-unitVector.dy, unitVector.dx) * 20;

    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    canvas.drawPath(path, paint);

    // Arrow head
    final arrowDirection = (endPoint - controlPoint).direction;
    _drawArrowHead(canvas, endPoint, arrowDirection, paint);

    // Label
    if (label != null && label.isNotEmpty) {
      final labelPos =
          (startPoint + endPoint) / 2 +
          Offset(-unitVector.dy, unitVector.dx) * 15;
      _drawEdgeLabel(canvas, labelPos, label);
    }
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    double direction,
    Paint paint,
  ) {
    const arrowLength = 12.0;
    const arrowAngle = math.pi / 6;

    final p1 =
        tip +
        Offset(
          arrowLength * math.cos(direction + math.pi - arrowAngle),
          arrowLength * math.sin(direction + math.pi - arrowAngle),
        );

    final p2 =
        tip +
        Offset(
          arrowLength * math.cos(direction + math.pi + arrowAngle),
          arrowLength * math.sin(direction + math.pi + arrowAngle),
        );

    final arrowPath = Path();
    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(p1.dx, p1.dy);
    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(p2.dx, p2.dy);

    canvas.drawPath(arrowPath, paint);
  }

  void _drawEdgeLabel(Canvas canvas, Offset position, String label) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: theme?.colorScheme.textSecondary ?? Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Background for better readability
    final bgRect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 6,
      height: textPainter.height + 4,
    );

    final bgPaint = Paint()
      ..color = (theme?.colorScheme.surface ?? Colors.white).withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );

    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawSelectionRect(Canvas canvas) {
    if (selectionRect == null) return;

    final paint = Paint()
      ..color = (theme?.colorScheme.primary ?? Colors.blue).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = theme?.colorScheme.primary ?? Colors.blue
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Custom dash effect implementation since PathEffect.dash is not available
    _drawDashedRect(canvas, selectionRect!, borderPaint);
    canvas.drawRect(selectionRect!, paint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;

    // Top edge
    _drawDashedLine(
      canvas,
      rect.topLeft,
      rect.topRight,
      paint,
      dashWidth,
      dashSpace,
    );

    // Right edge
    _drawDashedLine(
      canvas,
      rect.topRight,
      rect.bottomRight,
      paint,
      dashWidth,
      dashSpace,
    );

    // Bottom edge
    _drawDashedLine(
      canvas,
      rect.bottomRight,
      rect.bottomLeft,
      paint,
      dashWidth,
      dashSpace,
    );

    // Left edge
    _drawDashedLine(
      canvas,
      rect.bottomLeft,
      rect.topLeft,
      paint,
      dashWidth,
      dashSpace,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final direction = end - start;
    final totalDistance = direction.distance;
    final unitVector = direction / totalDistance;

    double currentDistance = 0;
    bool isDash = true;

    while (currentDistance < totalDistance) {
      final nextDistance = currentDistance + (isDash ? dashWidth : dashSpace);

      if (isDash) {
        final dashStart = start + unitVector * currentDistance;
        final dashEnd =
            start + unitVector * math.min(nextDistance, totalDistance);
        canvas.drawLine(dashStart, dashEnd, paint);
      }

      currentDistance = nextDistance;
      isDash = !isDash;
    }
  }

  void _drawSearchHighlights(Canvas canvas) {
    for (final nodeId in filteredNodes) {
      final position = nodePositions[nodeId];
      if (position == null) continue;

      final paint = Paint()
        ..color = (theme?.colorScheme.stateHighlighted ?? Colors.yellow)
            .withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, 45, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! StateDiagramPainter ||
        oldDelegate.data != data ||
        oldDelegate.selectedNodes != selectedNodes ||
        oldDelegate.selectedEdges != selectedEdges ||
        oldDelegate.hoveredElements != hoveredElements ||
        oldDelegate.searchQuery != searchQuery ||
        oldDelegate.selectionRect != selectionRect ||
        oldDelegate.animationValue != animationValue;
  }
}

/// رسم‌کننده نقشه کوچک
class MiniMapPainter extends CustomPainter {
  final StateDiagramData data;
  final Map<String, Offset> nodePositions;
  final Matrix4 viewport;
  final DiagramTheme? theme;

  MiniMapPainter({
    required this.data,
    required this.nodePositions,
    required this.viewport,
    this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.isEmpty) return;

    // Calculate bounds
    final positions = nodePositions.values;
    final minX = positions.map((p) => p.dx).reduce(math.min);
    final maxX = positions.map((p) => p.dx).reduce(math.max);
    final minY = positions.map((p) => p.dy).reduce(math.min);
    final maxY = positions.map((p) => p.dy).reduce(math.max);

    final bounds = Rect.fromLTRB(minX - 50, minY - 50, maxX + 50, maxY + 50);
    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final scale = math.min(scaleX, scaleY);

    // Transform canvas
    canvas.save();
    canvas.translate(-bounds.left * scale, -bounds.top * scale);
    canvas.scale(scale);

    // Draw nodes
    final nodePaint = Paint()
      ..color = theme?.colorScheme.stateDefault ?? Colors.blue
      ..style = PaintingStyle.fill;

    for (final node in data.nodes) {
      final position = nodePositions[node.id];
      if (position == null) continue;

      canvas.drawCircle(position, 8, nodePaint);
    }

    // Draw edges
    final edgePaint = Paint()
      ..color = theme?.colorScheme.edgeDefault ?? Colors.grey
      ..strokeWidth = 1;

    for (final edge in data.edges) {
      final fromPos = nodePositions[edge.fromId];
      final toPos = nodePositions[edge.toId];

      if (fromPos == null || toPos == null || edge.fromId == edge.toId)
        continue;

      canvas.drawLine(fromPos, toPos, edgePaint);
    }

    canvas.restore();

    // Draw viewport indicator
    final viewportPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // This would require calculating the visible area from the transformation matrix
    // For now, draw a simple rectangle in the center
    final viewportRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.6,
      height: size.height * 0.6,
    );

    canvas.drawRect(viewportRect, viewportPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! MiniMapPainter ||
        oldDelegate.data != data ||
        oldDelegate.viewport != viewport;
  }
}

/// کنترلر دیاگرام
class DiagramController extends ChangeNotifier {
  StateDiagramData _data = StateDiagramData(nodes: [], edges: []);

  StateDiagramData get data => _data;

  void updateData(StateDiagramData newData) {
    _data = newData;
    notifyListeners();
  }

  void addNode(StateNode node) {
    _data = StateDiagramData(nodes: [..._data.nodes, node], edges: _data.edges);
    notifyListeners();
  }

  void removeNode(String nodeId) {
    _data = StateDiagramData(
      nodes: _data.nodes.where((n) => n.id != nodeId).toList(),
      edges: _data.edges
          .where((e) => e.fromId != nodeId && e.toId != nodeId)
          .toList(),
    );
    notifyListeners();
  }

  void addEdge(StateEdge edge) {
    _data = StateDiagramData(nodes: _data.nodes, edges: [..._data.edges, edge]);
    notifyListeners();
  }

  void removeEdge(String edgeId) {
    _data = StateDiagramData(
      nodes: _data.nodes,
      edges: _data.edges.where((e) => e.id != edgeId).toList(),
    );
    notifyListeners();
  }
}

/// مدل داده‌های دیاگرام
class StateDiagramData {
  final List<StateNode> nodes;
  final List<StateEdge> edges;

  const StateDiagramData({required this.nodes, required this.edges});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StateDiagramData &&
        other.nodes.length == nodes.length &&
        other.edges.length == edges.length;
  }

  @override
  int get hashCode => Object.hash(nodes.length, edges.length);
}

/// مدل نود حالت
class StateNode {
  final String id;
  final String label;
  final bool isStart;
  final bool isFinal;
  final Map<String, dynamic>? metadata;

  const StateNode({
    required this.id,
    required this.label,
    this.isStart = false,
    this.isFinal = false,
    this.metadata,
  });

  StateNode copyWith({
    String? id,
    String? label,
    bool? isStart,
    bool? isFinal,
    Map<String, dynamic>? metadata,
  }) {
    return StateNode(
      id: id ?? this.id,
      label: label ?? this.label,
      isStart: isStart ?? this.isStart,
      isFinal: isFinal ?? this.isFinal,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StateNode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// مدل یال حالت
class StateEdge {
  final String id;
  final String fromId;
  final String toId;
  final String? label;
  final Map<String, dynamic>? metadata;

  const StateEdge({
    required this.id,
    required this.fromId,
    required this.toId,
    this.label,
    this.metadata,
  });

  StateEdge copyWith({
    String? id,
    String? fromId,
    String? toId,
    String? label,
    Map<String, dynamic>? metadata,
  }) {
    return StateEdge(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StateEdge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// آمار دیاگرام
class DiagramStatistics {
  final int totalNodes;
  final int totalEdges;
  final int startStates;
  final int finalStates;
  final int normalStates;
  final int selectedNodes;
  final int selectedEdges;

  const DiagramStatistics({
    required this.totalNodes,
    required this.totalEdges,
    required this.startStates,
    required this.finalStates,
    required this.normalStates,
    required this.selectedNodes,
    required this.selectedEdges,
  });
}

/// کلاس‌های تم
class DiagramTheme {
  final DiagramColorScheme colorScheme;

  const DiagramTheme({required this.colorScheme});
}

class DiagramColorScheme {
  final Color surface;
  final Color primary;
  final Color stateStart;
  final Color stateFinal;
  final Color stateDefault;
  final Color stateSelected;
  final Color stateHovered;
  final Color stateHighlighted;
  final Color edgeDefault;
  final Color edgeSelected;
  final Color edgeHighlighted;
  final Color textPrimary;
  final Color textSecondary;
  final Color grid;

  const DiagramColorScheme({
    required this.surface,
    required this.primary,
    required this.stateStart,
    required this.stateFinal,
    required this.stateDefault,
    required this.stateSelected,
    required this.stateHovered,
    required this.stateHighlighted,
    required this.edgeDefault,
    required this.edgeSelected,
    required this.edgeHighlighted,
    required this.textPrimary,
    required this.textSecondary,
    required this.grid,
  });
}

/// نمونه استفاده
class DiagramExample extends StatefulWidget {
  const DiagramExample({super.key});

  @override
  State<DiagramExample> createState() => _DiagramExampleState();
}

class _DiagramExampleState extends State<DiagramExample> {
  late DiagramController controller;

  final sampleTheme = DiagramTheme(
    colorScheme: DiagramColorScheme(
      surface: Colors.white,
      primary: Colors.blue,
      stateStart: Colors.green,
      stateFinal: Colors.red,
      stateDefault: Colors.blue,
      stateSelected: Colors.orange,
      stateHovered: Colors.purple,
      stateHighlighted: Colors.yellow,
      edgeDefault: Colors.grey,
      edgeSelected: Colors.orange,
      edgeHighlighted: Colors.yellow,
      textPrimary: Colors.black,
      textSecondary: Colors.grey,
      grid: Colors.grey.shade300,
    ),
  );

  @override
  void initState() {
    super.initState();
    controller = DiagramController();
    _setupSampleData();
  }

  void _setupSampleData() {
    final data = StateDiagramData(
      nodes: [
        const StateNode(id: 'start', label: 'Start', isStart: true),
        const StateNode(id: 'state1', label: 'State 1'),
        const StateNode(id: 'state2', label: 'State 2'),
        const StateNode(id: 'end', label: 'End', isFinal: true),
      ],
      edges: [
        const StateEdge(id: 'e1', fromId: 'start', toId: 'state1', label: 'a'),
        const StateEdge(id: 'e2', fromId: 'state1', toId: 'state2', label: 'b'),
        const StateEdge(id: 'e3', fromId: 'state2', toId: 'end', label: 'c'),
        const StateEdge(
          id: 'e4',
          fromId: 'state1',
          toId: 'state1',
          label: 'loop',
        ),
      ],
    );
    controller.updateData(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced State Diagram'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: AdvancedStateDiagram(
        data: controller.data,
        controller: controller,
        theme: sampleTheme,
        enableMultiSelection: true,
        enableDragDrop: true,
        enableContextMenu: true,
        enableKeyboardShortcuts: true,
        enableTouchGestures: true,
        enableSearch: true,
        enableStatistics: true,
        enableMiniMap: true,
        onDataChanged: () {
          // Handle data changes
          print('Diagram data changed');
        },
        onNodeSelected: (nodeId) {
          print('Node selected: $nodeId');
        },
        onSelectionChanged: (selectedIds) {
          print('Selection changed: $selectedIds');
        },
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Ctrl+Click: Multi-select'),
            Text('• Delete: Delete selected'),
            Text('• Ctrl+A: Select all'),
            Text('• Ctrl+C: Copy'),
            Text('• Ctrl+V: Paste'),
            Text('• Ctrl+Z: Undo'),
            Text('• Esc: Clear selection'),
            Text('• Right-click: Context menu'),
            Text('• Drag: Move nodes'),
            Text('• Drag empty area: Multi-select'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
