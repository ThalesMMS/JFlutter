import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphview/GraphView.dart';
import 'dart:math' as math;
import '../models/nfa.dart';
import '../models/dfa.dart';

/// ویجت اصلی نمایش دیاگرام حالت
class StateDiagram extends StatefulWidget {
  final dynamic automaton;
  final StateDiagramConfig config;
  final Function(String state)? onStateSelected;
  final Function(String from, String to, String symbol)? onTransitionSelected;
  final bool showTransitionLabels;
  final bool enableAnimation;
  final bool showGrid;
  final bool enableZoom;
  final bool enablePan;
  final String? highlightedState;
  final Set<String>? highlightedTransitions;
  final bool showLegend;
  final bool showMinimap;
  final bool enablePhysics;
  final bool showTooltips;

  const StateDiagram({
    super.key,
    required this.automaton,
    this.config = const StateDiagramConfig(),
    this.onStateSelected,
    this.onTransitionSelected,
    this.showTransitionLabels = true,
    this.enableAnimation = true,
    this.showGrid = false,
    this.enableZoom = true,
    this.enablePan = true,
    this.highlightedState,
    this.highlightedTransitions,
    this.showLegend = false,
    this.showMinimap = false,
    this.enablePhysics = false,
    this.showTooltips = true,
  });

  @override
  State<StateDiagram> createState() => _StateDiagramState();
}

class _StateDiagramState extends State<StateDiagram>
    with TickerProviderStateMixin {
  final Graph _graph = Graph();
  late final SugiyamaConfiguration _configuration;
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  late final AnimationController _pulseController;
  late final AnimationController _transitionController;

  final Map<String, Node> _nodes = {};
  final Map<String, List<TransitionInfo>> _transitions = {};
  final GlobalKey _graphKey = GlobalKey();

  String? _selectedState;
  String? _hoveredState;
  String? _tooltipState;
  Offset? _tooltipPosition;
  bool _isGraphBuilt = false;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _buildConfiguration();
    _buildGraph();
  }

  @override
  void didUpdateWidget(StateDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.automaton != widget.automaton ||
        oldWidget.config != widget.config) {
      _buildConfiguration();
      _buildGraph();
    }
  }

  void _initializeControllers() {
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    if (widget.enableAnimation) {
      _animationController.forward();
    }
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale != _currentScale) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _buildConfiguration() {
    _configuration = SugiyamaConfiguration()
      ..nodeSeparation = widget.config.nodeSeparation.toInt()
      ..levelSeparation = widget.config.levelSeparation.toInt()
      ..orientation = _getOrientation()
      ..coordinateAssignment = CoordinateAssignment.Average;
  }

  int _getOrientation() {
    switch (widget.config.layoutDirection) {
      case LayoutDirection.leftToRight:
        return SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;
      case LayoutDirection.topToBottom:
        return SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
      case LayoutDirection.rightToLeft:
        return SugiyamaConfiguration.ORIENTATION_RIGHT_LEFT;
      case LayoutDirection.bottomToTop:
        return SugiyamaConfiguration.ORIENTATION_BOTTOM_TOP;
    }
  }

  void _buildGraph() {
    _graph.nodes.clear();
    _nodes.clear();
    _transitions.clear();

    if (widget.automaton is NFA) {
      _buildFromNFA(widget.automaton as NFA);
    } else if (widget.automaton is DFA) {
      _buildFromDFA(widget.automaton as DFA);
    }

    setState(() {
      _isGraphBuilt = true;
    });
  }

  // [FIXED] متد اصلاح شده برای مدیریت انتقال‌های حلقه‌ای (self-loops)
  void _buildFromNFA(NFA nfa) {
    if (nfa.states.isEmpty) return;

    for (var stateName in nfa.states) {
      final node = Node.Id(stateName);
      _nodes[stateName] = node;
      _graph.addNode(node);
    }

    nfa.transitions.forEach((from, symbols) {
      symbols.forEach((symbol, toStates) {
        for (var toState in toStates) {
          if (from != toState) {
            _graph.addEdge(_nodes[from]!, _nodes[toState]!);
          }

          _transitions.putIfAbsent(from, () => []);
          _transitions[from]!.add(TransitionInfo(
            from: from,
            to: toState,
            symbol: symbol,
            isEpsilon: symbol == NFA.epsilon,
          ));
        }
      });
    });
  }

  // [FIXED] متد اصلاح شده برای مدیریت انتقال‌های حلقه‌ای (self-loops)
  void _buildFromDFA(DFA dfa) {
    if (dfa.states.isEmpty) return;

    for (var stateSet in dfa.states) {
      final stateName = dfa.getStateName(stateSet);
      final node = Node.Id(stateName);
      _nodes[stateName] = node;
      _graph.addNode(node);
    }

    dfa.transitions.forEach((fromStateSet, symbols) {
      final fromName = dfa.getStateName(fromStateSet);
      symbols.forEach((symbol, toStateSet) {
        final toName = dfa.getStateName(toStateSet);

        if (fromName != toName) {
          _graph.addEdge(_nodes[fromName]!, _nodes[toName]!);
        }

        _transitions.putIfAbsent(fromName, () => []);
        _transitions[fromName]!.add(TransitionInfo(
          from: fromName,
          to: toName,
          symbol: symbol,
          isEpsilon: false,
        ));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGraphBuilt || _nodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('در حال ساخت دیاگرام...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (widget.showLegend) _buildLegend(),
        Expanded(
          child: Stack(
            children: [
              if (widget.showGrid) _buildGrid(),
              _buildGraphView(),
              _buildControls(),
              if (widget.showMinimap) _buildMinimap(),
              if (_tooltipState != null && widget.showTooltips) _buildTooltip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          _buildLegendItem('Start State', widget.config.startStateColor, true),
          _buildLegendItem('Final State', widget.config.finalStateColor, false,
              isDouble: true),
          _buildLegendItem('Normal State', widget.config.stateColor, false),
          _buildLegendItem('Selected', widget.config.selectedColor, false),
          _buildLegendItem('Highlighted', widget.config.highlightColor, false),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isStart,
      {bool isDouble = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(
              color: color,
              width: isStart ? 3 : (isDouble ? 2 : 1),
            ),
          ),
          child: isDouble
              ? Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1),
                  ),
                )
              : isStart
                  ? Center(
                      child: Icon(
                        Icons.play_arrow,
                        size: 12,
                        color: color,
                      ),
                    )
                  : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(
        gridSize: 20 * _currentScale,
        color: Theme.of(context).dividerColor.withOpacity(0.3),
        strokeWidth: 0.5,
      ),
    );
  }

  Widget _buildGraphView() {
    Widget graphView = GraphView(
      key: _graphKey,
      graph: _graph,
      algorithm: SugiyamaAlgorithm(_configuration),
      builder: (Node node) => _buildAdvancedNode(node),
    );

    if (widget.enableAnimation) {
      graphView = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final curvedValue =
              Curves.elasticOut.transform(_animationController.value);
          return Transform.scale(
            scale: curvedValue,
            child: Opacity(
              opacity: _animationController.value,
              child: child,
            ),
          );
        },
        child: graphView,
      );
    }

    if (!widget.enableZoom && !widget.enablePan) {
      return graphView;
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      constrained: false,
      boundaryMargin: EdgeInsets.all(widget.config.boundaryMargin),
      minScale: widget.config.minScale,
      maxScale: widget.config.maxScale,
      panEnabled: widget.enablePan,
      scaleEnabled: widget.enableZoom,
      onInteractionStart: (_) => _hideTooltip(),
      child: graphView,
    );
  }

  Widget _buildAdvancedNode(Node node) {
    final nodeId = node.key!.value as String;
    final nodeInfo = _getNodeInfo(nodeId);

    return GestureDetector(
      onTap: () => _handleNodeTap(nodeId),
      onTapDown: (details) => _handleNodeTapDown(nodeId, details),
      onTapCancel: () => _handleNodeTapCancel(),
      child: MouseRegion(
        onEnter: (event) => _handleNodeHover(nodeId, event.position),
        onExit: (_) => _handleNodeExit(),
        child: AnimatedBuilder(
          animation:
              Listenable.merge([_pulseController, _transitionController]),
          builder: (context, child) {
            final isHighlighted = widget.highlightedState == nodeId;
            final pulseValue = isHighlighted ? _pulseController.value : 0.0;

            return Transform.scale(
              scale: 1.0 + (pulseValue * 0.15),
              child: _buildNodeContainer(nodeId, nodeInfo, pulseValue),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNodeContainer(
      String nodeId, NodeInfo nodeInfo, double pulseValue) {
    final isSelected = _selectedState == nodeId;
    final isHovered = _hoveredState == nodeId;
    final isHighlighted = widget.highlightedState == nodeId;
    final selfLoops =
        _transitions[nodeId]?.where((t) => t.isSelfLoop).toList() ?? [];

    return Container(
      width: widget.config.nodeSize,
      height: widget.config.nodeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getNodeGradient(nodeInfo, isSelected, isHovered),
        border: Border.all(
          color: _getNodeBorderColor(
              nodeInfo, isSelected, isHovered, isHighlighted),
          width: _getNodeBorderWidth(nodeInfo, isSelected, isHovered),
        ),
        boxShadow: _getNodeShadows(nodeInfo, isSelected, isHovered, pulseValue),
      ),
      child: Stack(
        clipBehavior: Clip.none, // اجازه می‌دهد ویجت‌های فرزند بیرون بزنند
        alignment: Alignment.center,
        children: [
          if (nodeInfo.isFinal) _buildInnerCircle(nodeInfo),
          Center(
            child: Text(
              nodeId,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize:
                    widget.config.fontSize * (0.8 + (_currentScale * 0.2)),
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (nodeInfo.isStart) _buildStartIndicator(),
          if (isSelected) _buildSelectionIndicator(),
          if (selfLoops.isNotEmpty)
            Positioned(
              top: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Theme.of(context).dividerColor, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: 12, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      selfLoops.map((l) => l.symbol).join(','),
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Gradient _getNodeGradient(
      NodeInfo nodeInfo, bool isSelected, bool isHovered) {
    final baseColor = _getNodeColor(nodeInfo);
    final color1 = isSelected ? baseColor : baseColor.withOpacity(0.1);
    final color2 =
        isSelected ? baseColor.withOpacity(0.7) : baseColor.withOpacity(0.05);

    if (isHovered) {
      return RadialGradient(
        colors: [color1.withOpacity(0.3), color2.withOpacity(0.8)],
      );
    }

    return RadialGradient(
      colors: [color1, color2],
    );
  }

  List<BoxShadow> _getNodeShadows(
      NodeInfo nodeInfo, bool isSelected, bool isHovered, double pulseValue) {
    final shadows = <BoxShadow>[
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

    if (isSelected || isHovered) {
      shadows.add(
        BoxShadow(
          color: _getNodeColor(nodeInfo).withOpacity(0.4),
          blurRadius: 12 + (pulseValue * 8),
          spreadRadius: 3 + (pulseValue * 3),
        ),
      );
    }

    return shadows;
  }

  Widget _buildInnerCircle(NodeInfo nodeInfo) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _getNodeColor(nodeInfo),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildStartIndicator() {
    return Positioned(
      top: -8,
      left: -8,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.config.startStateColor,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(
          Icons.play_arrow,
          size: 8,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.config.selectedColor,
            width: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          _buildControlPanel(),
          const SizedBox(height: 16),
          _buildInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.enableZoom) ...[
            _buildControlButton(
              icon: Icons.zoom_in,
              onPressed: () => _zoomIn(),
              tooltip: 'Zoom In',
            ),
            const SizedBox(height: 4),
            _buildControlButton(
              icon: Icons.zoom_out,
              onPressed: () => _zoomOut(),
              tooltip: 'Zoom Out',
            ),
            const SizedBox(height: 4),
          ],
          _buildControlButton(
            icon: Icons.center_focus_strong,
            onPressed: _centerGraph,
            tooltip: 'Center Graph',
          ),
          const SizedBox(height: 4),
          _buildControlButton(
            icon: Icons.refresh,
            onPressed: _resetGraph,
            tooltip: 'Reset Graph',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    if (_selectedState == null) return const SizedBox.shrink();

    final nodeInfo = _getNodeInfo(_selectedState!);
    final transitions = _transitions[_selectedState!] ?? [];

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'State: $_selectedState',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (nodeInfo.isStart)
            _buildInfoChip('Start State', widget.config.startStateColor),
          if (nodeInfo.isFinal)
            _buildInfoChip('Final State', widget.config.finalStateColor),
          if (transitions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Transitions (${transitions.length}):',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            ...transitions.take(3).map((t) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    '${t.symbol} → ${t.to}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                )),
            if (transitions.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '... and ${transitions.length - 3} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMinimap() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Center(
          child: Text(
            'Minimap\n(Coming Soon)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip() {
    if (_tooltipState == null || _tooltipPosition == null) {
      return const SizedBox.shrink();
    }

    final nodeInfo = _getNodeInfo(_tooltipState!);
    final transitions = _transitions[_tooltipState!] ?? [];

    return Positioned(
      left: _tooltipPosition!.dx + 10,
      top: _tooltipPosition!.dy - 10,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _tooltipState!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (nodeInfo.isStart || nodeInfo.isFinal) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (nodeInfo.isStart) 'Start',
                    if (nodeInfo.isFinal) 'Final',
                  ].join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
              if (transitions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${transitions.length} transition${transitions.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    final button = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }

  // Event Handlers
  void _handleNodeTap(String nodeId) {
    setState(() {
      _selectedState = _selectedState == nodeId ? null : nodeId;
    });
    widget.onStateSelected?.call(nodeId);
    HapticFeedback.lightImpact();
  }

  void _handleNodeTapDown(String nodeId, TapDownDetails details) {
    setState(() => _hoveredState = nodeId);
  }

  void _handleNodeTapCancel() {
    setState(() => _hoveredState = null);
  }

  void _handleNodeHover(String nodeId, Offset position) {
    setState(() {
      _hoveredState = nodeId;
      if (widget.showTooltips) {
        _tooltipState = nodeId;
        _tooltipPosition = position;
      }
    });
  }

  void _handleNodeExit() {
    setState(() {
      _hoveredState = null;
      _tooltipState = null;
      _tooltipPosition = null;
    });
  }

  void _hideTooltip() {
    setState(() {
      _tooltipState = null;
      _tooltipPosition = null;
    });
  }

  // Control Methods
  void _zoomIn() {
    final currentValue = _transformationController.value;
    final newScale = math.min(
        currentValue.getMaxScaleOnAxis() * 1.2, widget.config.maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _zoomOut() {
    final currentValue = _transformationController.value;
    final newScale = math.max(
        currentValue.getMaxScaleOnAxis() / 1.2, widget.config.minScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _centerGraph() {
    _transformationController.value = Matrix4.identity();
  }

  void _resetGraph() {
    setState(() {
      _selectedState = null;
      _hoveredState = null;
      _tooltipState = null;
      _tooltipPosition = null;
    });
    _centerGraph();
    _buildGraph();
    if (widget.enableAnimation) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  // Helper Methods
  NodeInfo _getNodeInfo(String nodeId) {
    bool isStart = false;
    bool isFinal = false;

    if (widget.automaton is NFA) {
      final nfa = widget.automaton as NFA;
      isStart = nfa.startState == nodeId;
      isFinal = nfa.finalStates.contains(nodeId);
    } else if (widget.automaton is DFA) {
      final dfa = widget.automaton as DFA;
      isStart =
          dfa.startState != null && dfa.getStateName(dfa.startState!) == nodeId;
      isFinal = dfa.finalStates.any((s) => dfa.getStateName(s) == nodeId);
    }

    return NodeInfo(isStart: isStart, isFinal: isFinal);
  }

  Color _getNodeColor(NodeInfo nodeInfo) {
    if (nodeInfo.isStart) return widget.config.startStateColor;
    if (nodeInfo.isFinal) return widget.config.finalStateColor;
    return widget.config.stateColor;
  }

  Color _getNodeBorderColor(
      NodeInfo nodeInfo, bool isSelected, bool isHovered, bool isHighlighted) {
    if (isSelected) return widget.config.selectedColor;
    if (isHovered) return widget.config.hoverColor;
    if (isHighlighted) return widget.config.highlightColor;
    return _getNodeColor(nodeInfo);
  }

  double _getNodeBorderWidth(
      NodeInfo nodeInfo, bool isSelected, bool isHovered) {
    if (isSelected) return 4.0;
    if (isHovered) return 3.0;
    if (nodeInfo.isStart) return 3.0;
    return 2.0;
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _transitionController.dispose();
    super.dispose();
  }
}

/// کلاس تنظیمات دیاگرام حالت
class StateDiagramConfig {
  final double nodeSeparation;
  final double levelSeparation;
  final LayoutDirection layoutDirection;
  final double nodeSize;
  final double fontSize;
  final double edgeWidth;
  final double boundaryMargin;
  final double minScale;
  final double maxScale;
  final Color stateColor;
  final Color startStateColor;
  final Color finalStateColor;
  final Color edgeColor;
  final Color selectedColor;
  final Color hoverColor;
  final Color highlightColor;
  final Color backgroundColor;
  final Color gridColor;
  final Duration animationDuration;
  final Curve animationCurve;

  const StateDiagramConfig({
    this.nodeSeparation = 100,
    this.levelSeparation = 120,
    this.layoutDirection = LayoutDirection.leftToRight,
    this.nodeSize = 70,
    this.fontSize = 16,
    this.edgeWidth = 2.5,
    this.boundaryMargin = 150,
    this.minScale = 0.1,
    this.maxScale = 4.0,
    this.stateColor = const Color(0xFF2196F3),
    this.startStateColor = const Color(0xFF4CAF50),
    this.finalStateColor = const Color(0xFFF44336),
    this.edgeColor = const Color(0xFF424242),
    this.selectedColor = const Color(0xFFFF9800),
    this.hoverColor = const Color(0xFF9C27B0),
    this.highlightColor = const Color(0xFFFFEB3B),
    this.backgroundColor = const Color(0xFFFAFAFA),
    this.gridColor = const Color(0xFFE0E0E0),
    this.animationDuration = const Duration(milliseconds: 1500),
    this.animationCurve = Curves.elasticOut,
  });
}

/// جهت چیدمان گراف
enum LayoutDirection {
  leftToRight,
  topToBottom,
  rightToLeft,
  bottomToTop,
}

/// اطلاعات نود
class NodeInfo {
  final bool isStart;
  final bool isFinal;

  const NodeInfo({
    required this.isStart,
    required this.isFinal,
  });
}

/// اطلاعات انتقال
class TransitionInfo {
  final String from;
  final String to;
  final String symbol;
  final bool isEpsilon;
  final bool isSelfLoop;

  TransitionInfo({
    required this.from,
    required this.to,
    required this.symbol,
    this.isEpsilon = false,
  }) : isSelfLoop = (from == to);
}

/// رسم کننده شبکه پس‌زمینه
class GridPainter extends CustomPainter {
  final double gridSize;
  final Color color;
  final double strokeWidth;

  GridPainter({
    required this.gridSize,
    required this.color,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.gridSize != gridSize || oldDelegate.color != color;
}
