import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:collection';
import 'performance_optimizer.dart';

/// مدیر اصلی الگوریتم‌های چیدمان
class LayoutManager {
  static final LayoutManager _instance = LayoutManager._internal();
  factory LayoutManager() => _instance;
  LayoutManager._internal();

  final ForceDirectedLayout _forceDirected = ForceDirectedLayout();
  final CircularLayout _circular = CircularLayout();
  final TreeLayout _tree = TreeLayout();
  final GridLayout _grid = GridLayout();
  final CustomLayout _custom = CustomLayout();
  final LayoutAnimator _animator = LayoutAnimator();
  final LayoutOptimizer _optimizer = LayoutOptimizer();

  ForceDirectedLayout get forceDirected => _forceDirected;
  CircularLayout get circular => _circular;
  TreeLayout get tree => _tree;
  GridLayout get grid => _grid;
  CustomLayout get custom => _custom;
  LayoutAnimator get animator => _animator;
  LayoutOptimizer get optimizer => _optimizer;

  /// محاسبه بهترین layout بر اساس نوع گراف
  LayoutType determineBestLayout(GraphData graph) {
    final nodeCount = graph.nodes.length;
    final edgeCount = graph.edges.length;
    final density = edgeCount / (nodeCount * (nodeCount - 1) / 2);

    // گراف‌های کوچک
    if (nodeCount <= 10) {
      return graph.isTree ? LayoutType.tree : LayoutType.circular;
    }

    // گراف‌های پراکنده
    if (density < 0.1) {
      return LayoutType.forceDirected;
    }

    // گراف‌های متوسط
    if (nodeCount <= 50) {
      return graph.isTree ? LayoutType.tree : LayoutType.forceDirected;
    }

    // گراف‌های بزرگ
    return LayoutType.grid;
  }

  /// اجرای layout با بهینه‌سازی
  Future<LayoutResult> calculateLayout(
    GraphData graph,
    LayoutType type,
    LayoutConstraints constraints,
  ) async {
    final stopwatch = Stopwatch()..start();

    // بهینه‌سازی پیش از محاسبه
    final optimizedGraph = await _optimizer.optimizeGraph(graph, constraints);

    LayoutResult result;
    switch (type) {
      case LayoutType.forceDirected:
        result = await _forceDirected.calculate(optimizedGraph, constraints);
        break;
      case LayoutType.circular:
        result = await _circular.calculate(optimizedGraph, constraints);
        break;
      case LayoutType.tree:
        result = await _tree.calculate(optimizedGraph, constraints);
        break;
      case LayoutType.grid:
        result = await _grid.calculate(optimizedGraph, constraints);
        break;
      case LayoutType.custom:
        result = await _custom.calculate(optimizedGraph, constraints);
        break;
    }

    stopwatch.stop();
    result.computationTime = stopwatch.elapsedMilliseconds;

    // اعمال محدودیت‌های نهایی
    result = _applyConstraints(result, constraints);

    return result;
  }

  LayoutResult _applyConstraints(
    LayoutResult result,
    LayoutConstraints constraints,
  ) {
    final nodes = Map<String, NodePosition>.from(result.nodePositions);

    // اعمال boundaries
    for (final entry in nodes.entries) {
      final pos = entry.value;
      final constrainedPos = NodePosition(
        nodeId: pos.nodeId,
        position: Offset(
          pos.position.dx.clamp(
            constraints.bounds.left,
            constraints.bounds.right,
          ),
          pos.position.dy.clamp(
            constraints.bounds.top,
            constraints.bounds.bottom,
          ),
        ),
        size: pos.size,
      );
      nodes[entry.key] = constrainedPos;
    }

    return LayoutResult(
      nodePositions: nodes,
      edges: result.edges,
      bounds: result.bounds,
      quality: result.quality,
      computationTime: result.computationTime,
    );
  }

  void dispose() {
    _forceDirected.dispose();
    _circular.dispose();
    _tree.dispose();
    _grid.dispose();
    _custom.dispose();
    _animator.dispose();
    _optimizer.dispose();
  }
}

/// الگوریتم Force-Directed Layout
class ForceDirectedLayout {
  // ثابت‌های پیش‌فرض
  static const double defaultSpringLength = 100.0;
  static const double defaultSpringStrength = 0.1;
  static const double defaultRepulsionStrength = 1000.0;
  static const double defaultDamping = 0.9;
  static const int defaultMaxIterations = 500;
  static const double convergenceThreshold = 0.1;

  // متغیرهای instance با نام‌های متفاوت
  double _springLength = defaultSpringLength;
  double _springStrength = defaultSpringStrength;
  double _repulsionStrength = defaultRepulsionStrength;
  double _damping = defaultDamping;
  int _maxIterations = defaultMaxIterations;

  void configure({
    double? springLength,
    double? springStrength,
    double? repulsionStrength,
    double? damping,
    int? maxIterations,
  }) {
    _springLength = springLength ?? _springLength;
    _springStrength = springStrength ?? _springStrength;
    _repulsionStrength = repulsionStrength ?? _repulsionStrength;
    _damping = damping ?? _damping;
    _maxIterations = maxIterations ?? _maxIterations;
  }

  Future<LayoutResult> calculate(
    GraphData graph,
    LayoutConstraints constraints,
  ) async {
    final positions = <String, Offset>{};
    final velocities = <String, Offset>{};
    final forces = <String, Offset>{};

    // مقداردهی اولیه positions
    _initializePositions(graph.nodes, positions, constraints.bounds);

    // مقداردهی اولیه velocities
    for (final node in graph.nodes) {
      velocities[node.id] = Offset.zero;
    }

    // شبیه‌سازی physics
    int iteration = 0;
    double totalEnergy = double.infinity;

    while (iteration < _maxIterations && totalEnergy > convergenceThreshold) {
      // پاک کردن forces
      for (final node in graph.nodes) {
        forces[node.id] = Offset.zero;
      }

      // محاسبه repulsion forces
      _calculateRepulsionForces(graph.nodes, positions, forces);

      // محاسبه spring forces
      _calculateSpringForces(graph.edges, positions, forces);

      // اعمال forces و به‌روزرسانی positions
      totalEnergy = _updatePositions(
        graph.nodes,
        positions,
        velocities,
        forces,
        constraints.bounds,
      );

      iteration++;

      // توقف برای جلوگیری از blocking UI
      if (iteration % 10 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    // ایجاد نتیجه نهایی
    final nodePositions = <String, NodePosition>{};
    for (final node in graph.nodes) {
      nodePositions[node.id] = NodePosition(
        nodeId: node.id,
        position: positions[node.id]!,
        size: Size(node.width, node.height),
      );
    }

    final layoutBounds = _calculateBounds(nodePositions.values.toList());
    final quality = _calculateQuality(graph, nodePositions);

    return LayoutResult(
      nodePositions: nodePositions,
      edges: _calculateEdgePositions(graph.edges, nodePositions),
      bounds: layoutBounds,
      quality: quality,
    );
  }

  void _initializePositions(
    List<GraphNode> nodes,
    Map<String, Offset> positions,
    Rect bounds,
  ) {
    final random = math.Random();
    final center = bounds.center;
    final radius = math.min(bounds.width, bounds.height) * 0.3;

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      // توزیع دایره‌ای اولیه
      final angle = (i * 2 * math.pi) / nodes.length;
      final x =
          center.dx + radius * math.cos(angle) + random.nextDouble() * 20 - 10;
      final y =
          center.dy + radius * math.sin(angle) + random.nextDouble() * 20 - 10;

      positions[node.id] = Offset(x, y);
    }
  }

  void _calculateRepulsionForces(
    List<GraphNode> nodes,
    Map<String, Offset> positions,
    Map<String, Offset> forces,
  ) {
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final node1 = nodes[i];
        final node2 = nodes[j];

        final pos1 = positions[node1.id]!;
        final pos2 = positions[node2.id]!;

        final dx = pos1.dx - pos2.dx;
        final dy = pos1.dy - pos2.dy;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance > 0) {
          final force = _repulsionStrength / (distance * distance);
          final fx = (dx / distance) * force;
          final fy = (dy / distance) * force;

          forces[node1.id] = forces[node1.id]! + Offset(fx, fy);
          forces[node2.id] = forces[node2.id]! - Offset(fx, fy);
        }
      }
    }
  }

  void _calculateSpringForces(
    List<GraphEdge> edges,
    Map<String, Offset> positions,
    Map<String, Offset> forces,
  ) {
    for (final edge in edges) {
      final pos1 = positions[edge.from]!;
      final pos2 = positions[edge.to]!;

      final dx = pos2.dx - pos1.dx;
      final dy = pos2.dy - pos1.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      if (distance > 0) {
        final displacement = distance - _springLength;
        final force = _springStrength * displacement;
        final fx = (dx / distance) * force;
        final fy = (dy / distance) * force;

        forces[edge.from] = forces[edge.from]! + Offset(fx, fy);
        forces[edge.to] = forces[edge.to]! - Offset(fx, fy);
      }
    }
  }

  double _updatePositions(
    List<GraphNode> nodes,
    Map<String, Offset> positions,
    Map<String, Offset> velocities,
    Map<String, Offset> forces,
    Rect bounds,
  ) {
    double totalEnergy = 0.0;

    for (final node in nodes) {
      final force = forces[node.id]!;
      final velocity = velocities[node.id]!;

      // به‌روزرسانی velocity
      final newVelocity = Offset(
        (velocity.dx + force.dx) * _damping,
        (velocity.dy + force.dy) * _damping,
      );
      velocities[node.id] = newVelocity;

      // به‌روزرسانی position
      final currentPos = positions[node.id]!;
      final newPos = Offset(
        (currentPos.dx + newVelocity.dx).clamp(
          bounds.left + 50,
          bounds.right - 50,
        ),
        (currentPos.dy + newVelocity.dy).clamp(
          bounds.top + 50,
          bounds.bottom - 50,
        ),
      );
      positions[node.id] = newPos;

      // محاسبه انرژی
      totalEnergy += newVelocity.distanceSquared;
    }

    return totalEnergy;
  }

  double _calculateQuality(
    GraphData graph,
    Map<String, NodePosition> positions,
  ) {
    double quality = 1.0;

    // کیفیت بر اساس تداخل نودها
    final overlaps = _countOverlaps(positions.values.toList());
    quality *= math.max(0.0, 1.0 - overlaps / graph.nodes.length);

    // کیفیت بر اساس توزیع یکنواخت
    final distribution = _calculateDistributionQuality(
      positions.values.toList(),
    );
    quality *= distribution;

    return quality;
  }

  int _countOverlaps(List<NodePosition> positions) {
    int overlaps = 0;
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final pos1 = positions[i];
        final pos2 = positions[j];
        final rect1 = Rect.fromCenter(
          center: pos1.position,
          width: pos1.size.width,
          height: pos1.size.height,
        );
        final rect2 = Rect.fromCenter(
          center: pos2.position,
          width: pos2.size.width,
          height: pos2.size.height,
        );

        if (rect1.overlaps(rect2)) {
          overlaps++;
        }
      }
    }
    return overlaps;
  }

  double _calculateDistributionQuality(List<NodePosition> positions) {
    if (positions.length < 2) return 1.0;

    final distances = <double>[];
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final distance =
            (positions[i].position - positions[j].position).distance;
        distances.add(distance);
      }
    }

    distances.sort();
    final median = distances[distances.length ~/ 2];
    final variance =
        distances.map((d) => math.pow(d - median, 2)).reduce((a, b) => a + b) /
        distances.length;

    return math.max(0.0, 1.0 - variance / (median * median));
  }

  void dispose() {
    // پاکسازی منابع
  }
}

/// الگوریتم Circular Layout
class CircularLayout {
  double _radius = 150.0;
  double _startAngle = 0.0;
  bool _clockwise = true;

  void configure({double? radius, double? startAngle, bool? clockwise}) {
    _radius = radius ?? _radius;
    _startAngle = startAngle ?? _startAngle;
    _clockwise = clockwise ?? _clockwise;
  }

  Future<LayoutResult> calculate(
    GraphData graph,
    LayoutConstraints constraints,
  ) async {
    final nodePositions = <String, NodePosition>{};
    final center = constraints.bounds.center;
    final nodes = graph.nodes;

    if (nodes.isEmpty) {
      return LayoutResult(
        nodePositions: {},
        edges: [],
        bounds: Rect.zero,
        quality: 1.0,
      );
    }

    // محاسبه شعاع بهینه
    final optimalRadius = _calculateOptimalRadius(
      nodes.length,
      constraints.bounds,
    );
    final actualRadius = math.min(_radius, optimalRadius);

    // قرار دادن نودها در دایره
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final angle =
          _startAngle +
          (i * 2 * math.pi / nodes.length) * (_clockwise ? 1 : -1);

      final x = center.dx + actualRadius * math.cos(angle);
      final y = center.dy + actualRadius * math.sin(angle);

      nodePositions[node.id] = NodePosition(
        nodeId: node.id,
        position: Offset(x, y),
        size: Size(node.width, node.height),
      );
    }

    final layoutBounds = _calculateBounds(nodePositions.values.toList());
    final quality = _calculateCircularQuality(
      nodePositions,
      center,
      actualRadius,
    );

    return LayoutResult(
      nodePositions: nodePositions,
      edges: _calculateEdgePositions(graph.edges, nodePositions),
      bounds: layoutBounds,
      quality: quality,
    );
  }

  double _calculateOptimalRadius(int nodeCount, Rect bounds) {
    if (nodeCount <= 1) return 50.0;

    // محاسبه شعاع بر اساس محیط مورد نیاز
    final circumference = nodeCount * 80.0; // ۸۰ پیکسل فاصله بین نودها
    final radius = circumference / (2 * math.pi);

    // محدود کردن به اندازه bounds
    final maxRadius = math.min(bounds.width, bounds.height) * 0.4;
    return math.min(radius, maxRadius);
  }

  double _calculateCircularQuality(
    Map<String, NodePosition> positions,
    Offset center,
    double radius,
  ) {
    if (positions.isEmpty) return 1.0;

    double quality = 1.0;

    // بررسی انحراف از دایره
    double totalDeviation = 0.0;
    for (final pos in positions.values) {
      final distanceFromCenter = (pos.position - center).distance;
      final deviation = (distanceFromCenter - radius).abs();
      totalDeviation += deviation;
    }

    final averageDeviation = totalDeviation / positions.length;
    quality *= math.max(0.0, 1.0 - averageDeviation / radius);

    return quality;
  }

  void dispose() {
    // پاکسازی منابع
  }
}

/// الگوریتم Tree/Hierarchical Layout
class TreeLayout {
  double _levelHeight = 100.0;
  double _siblingDistance = 80.0;
  TreeDirection _direction = TreeDirection.topDown;
  TreeAlignment _alignment = TreeAlignment.center;

  void configure({
    double? levelHeight,
    double? siblingDistance,
    TreeDirection? direction,
    TreeAlignment? alignment,
  }) {
    _levelHeight = levelHeight ?? _levelHeight;
    _siblingDistance = siblingDistance ?? _siblingDistance;
    _direction = direction ?? _direction;
    _alignment = alignment ?? _alignment;
  }

  Future<LayoutResult> calculate(
    GraphData graph,
    LayoutConstraints constraints,
  ) async {
    final nodePositions = <String, NodePosition>{};

    // تشخیص root node
    final rootNode = _findRootNode(graph);
    if (rootNode == null) {
      return _fallbackToForceDirected(graph, constraints);
    }

    // ساخت tree structure
    final tree = _buildTree(graph, rootNode.id);

    // محاسبه positions
    await _calculateTreePositions(tree, nodePositions, constraints);

    final layoutBounds = _calculateBounds(nodePositions.values.toList());
    final quality = _calculateTreeQuality(tree, nodePositions);

    return LayoutResult(
      nodePositions: nodePositions,
      edges: _calculateEdgePositions(graph.edges, nodePositions),
      bounds: layoutBounds,
      quality: quality,
    );
  }

  GraphNode? _findRootNode(GraphData graph) {
    // جستجوی نود بدون والد
    final hasParent = <String>{};
    for (final edge in graph.edges) {
      hasParent.add(edge.to);
    }

    for (final node in graph.nodes) {
      if (!hasParent.contains(node.id)) {
        return node;
      }
    }

    // اگر root پیدا نشد، اولین نود را انتخاب کن
    return graph.nodes.isNotEmpty ? graph.nodes.first : null;
  }

  TreeNode _buildTree(GraphData graph, String rootId) {
    final nodeMap = <String, GraphNode>{};
    for (final node in graph.nodes) {
      nodeMap[node.id] = node;
    }

    final childrenMap = <String, List<String>>{};
    for (final edge in graph.edges) {
      childrenMap.putIfAbsent(edge.from, () => []).add(edge.to);
    }

    TreeNode buildNode(String nodeId, int level) {
      final graphNode = nodeMap[nodeId]!;
      final children = childrenMap[nodeId] ?? [];

      return TreeNode(
        id: nodeId,
        graphNode: graphNode,
        level: level,
        children: children
            .map((childId) => buildNode(childId, level + 1))
            .toList(),
      );
    }

    return buildNode(rootId, 0);
  }

  Future<void> _calculateTreePositions(
    TreeNode tree,
    Map<String, NodePosition> positions,
    LayoutConstraints constraints,
  ) async {
    // محاسبه عرض هر سطح
    final levelWidths = <int, double>{};
    _calculateLevelWidths(tree, levelWidths);

    // محاسبه positions
    final bounds = constraints.bounds;
    final startX = bounds.left + 50;
    final startY = bounds.top + 50;

    await _positionNode(
      tree,
      positions,
      startX,
      startY,
      bounds.width - 100,
      levelWidths,
    );
  }

  void _calculateLevelWidths(TreeNode node, Map<int, double> levelWidths) {
    final currentWidth = levelWidths[node.level] ?? 0.0;
    levelWidths[node.level] =
        currentWidth + node.graphNode.width + _siblingDistance;

    for (final child in node.children) {
      _calculateLevelWidths(child, levelWidths);
    }
  }

  Future<void> _positionNode(
    TreeNode node,
    Map<String, NodePosition> positions,
    double x,
    double y,
    double availableWidth,
    Map<int, double> levelWidths,
  ) async {
    // موقعیت نود جاری
    final nodeX =
        _direction == TreeDirection.topDown ||
            _direction == TreeDirection.bottomUp
        ? x
        : y;
    final nodeY =
        _direction == TreeDirection.topDown ||
            _direction == TreeDirection.bottomUp
        ? y
        : x;

    positions[node.id] = NodePosition(
      nodeId: node.id,
      position: Offset(nodeX, nodeY),
      size: Size(node.graphNode.width, node.graphNode.height),
    );

    // موقعیت فرزندان
    if (node.children.isNotEmpty) {
      final totalChildrenWidth = node.children.length * _siblingDistance;
      final childStartX = nodeX - totalChildrenWidth / 2;
      final childY = _direction == TreeDirection.topDown
          ? nodeY + _levelHeight
          : nodeY - _levelHeight;

      for (int i = 0; i < node.children.length; i++) {
        final child = node.children[i];
        final childX = childStartX + i * _siblingDistance;

        await _positionNode(
          child,
          positions,
          childX,
          childY,
          availableWidth,
          levelWidths,
        );

        // توقف برای جلوگیری از blocking
        if (i % 5 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
    }
  }

  Future<LayoutResult> _fallbackToForceDirected(
    GraphData graph,
    LayoutConstraints constraints,
  ) async {
    final forceDirected = ForceDirectedLayout();
    return await forceDirected.calculate(graph, constraints);
  }

  double _calculateTreeQuality(
    TreeNode tree,
    Map<String, NodePosition> positions,
  ) {
    // کیفیت بر اساس تراز بودن سطوح و عدم تداخل
    return 0.8; // مقدار ثابت برای سادگی
  }

  void dispose() {
    // پاکسازی منابع
  }
}

/// الگوریتم Grid Layout
class GridLayout {
  int _columns = 5;
  double _cellWidth = 120.0;
  double _cellHeight = 80.0;
  double _padding = 20.0;

  void configure({
    int? columns,
    double? cellWidth,
    double? cellHeight,
    double? padding,
  }) {
    _columns = columns ?? _columns;
    _cellWidth = cellWidth ?? _cellWidth;
    _cellHeight = cellHeight ?? _cellHeight;
    _padding = padding ?? _padding;
  }

  Future<LayoutResult> calculate(
    GraphData graph,
    LayoutConstraints constraints,
  ) async {
    final nodePositions = <String, NodePosition>{};
    final nodes = graph.nodes;

    if (nodes.isEmpty) {
      return LayoutResult(
        nodePositions: {},
        edges: [],
        bounds: Rect.zero,
        quality: 1.0,
      );
    }

    // محاسبه تعداد columns بهینه
    final optimalColumns = _calculateOptimalColumns(
      nodes.length,
      constraints.bounds,
    );
    final actualColumns = math.min(_columns, optimalColumns);
    final rows = (nodes.length / actualColumns).ceil();

    // محاسبه نقطه شروع
    final totalWidth =
        actualColumns * _cellWidth + (actualColumns - 1) * _padding;
    final totalHeight = rows * _cellHeight + (rows - 1) * _padding;
    final startX = constraints.bounds.center.dx - totalWidth / 2;
    final startY = constraints.bounds.center.dy - totalHeight / 2;

    // قرار دادن نودها در grid
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final row = i ~/ actualColumns;
      final col = i % actualColumns;

      final x = startX + col * (_cellWidth + _padding) + _cellWidth / 2;
      final y = startY + row * (_cellHeight + _padding) + _cellHeight / 2;

      nodePositions[node.id] = NodePosition(
        nodeId: node.id,
        position: Offset(x, y),
        size: Size(node.width, node.height),
      );

      // توقف برای جلوگیری از blocking
      if (i % 10 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    final layoutBounds = _calculateBounds(nodePositions.values.toList());
    final quality = _calculateGridQuality(nodePositions, actualColumns);

    return LayoutResult(
      nodePositions: nodePositions,
      edges: _calculateEdgePositions(graph.edges, nodePositions),
      bounds: layoutBounds,
      quality: quality,
    );
  }

  int _calculateOptimalColumns(int nodeCount, Rect bounds) {
    if (nodeCount <= 1) return 1;

    final availableWidth = bounds.width - 100; // حاشیه
    final maxColumns = (availableWidth / (_cellWidth + _padding)).floor();

    // انتخاب تعداد columns که بهترین aspect ratio را دارد
    final idealColumns = math.sqrt(nodeCount).ceil();
    return math.min(idealColumns, maxColumns);
  }

  double _calculateGridQuality(
    Map<String, NodePosition> positions,
    int columns,
  ) {
    // Grid layout همیشه کیفیت بالایی دارد
    return 0.9;
  }

  void dispose() {
    // پاکسازی منابع
  }
}

/// الگوریتم Custom Layout
class CustomLayout {
  final List<LayoutRule> _rules = [];
  final Map<String, Offset> _fixedPositions = {};

  void addRule(LayoutRule rule) {
    _rules.add(rule);
  }

  void setFixedPosition(String nodeId, Offset position) {
    _fixedPositions[nodeId] = position;
  }

  void clearRules() {
    _rules.clear();
  }

  void clearFixedPositions() {
    _fixedPositions.clear();
  }

  Future<LayoutResult> calculate(
    GraphData graph,
    LayoutConstraints constraints,
  ) async {
    final nodePositions = <String, NodePosition>{};

    // اعمال موقعیت‌های ثابت
    for (final entry in _fixedPositions.entries) {
      final node = graph.nodes.firstWhere((n) => n.id == entry.key);
      nodePositions[entry.key] = NodePosition(
        nodeId: entry.key,
        position: entry.value,
        size: Size(node.width, node.height),
      );
    }

    // اعمال rules
    for (final rule in _rules) {
      await _applyRule(rule, graph, nodePositions, constraints);
    }

    // پر کردن نودهای باقی‌مانده با الگوریتم پیش‌فرض
    await _fillRemainingNodes(graph, nodePositions, constraints);

    final layoutBounds = _calculateBounds(nodePositions.values.toList());
    final quality = _calculateCustomQuality(nodePositions, _rules);

    return LayoutResult(
      nodePositions: nodePositions,
      edges: _calculateEdgePositions(graph.edges, nodePositions),
      bounds: layoutBounds,
      quality: quality,
    );
  }

  Future<void> _applyRule(
    LayoutRule rule,
    GraphData graph,
    Map<String, NodePosition> positions,
    LayoutConstraints constraints,
  ) async {
    switch (rule.type) {
      case LayoutRuleType.alignHorizontal:
        _alignNodesHorizontally(rule.nodeIds, positions, graph, rule.value);
        break;
      case LayoutRuleType.alignVertical:
        _alignNodesVertically(rule.nodeIds, positions, graph, rule.value);
        break;
      case LayoutRuleType.distributeHorizontal:
        _distributeNodesHorizontally(
          rule.nodeIds,
          positions,
          graph,
          constraints.bounds,
        );
        break;
      case LayoutRuleType.distributeVertical:
        _distributeNodesVertically(
          rule.nodeIds,
          positions,
          graph,
          constraints.bounds,
        );
        break;
      case LayoutRuleType.keepDistance:
        _maintainDistance(rule.nodeIds, positions, graph, rule.value);
        break;
      case LayoutRuleType.centerAround:
        _centerNodesAround(rule.nodeIds, positions, graph, rule.centerPoint!);
        break;
    }
  }

  void _alignNodesHorizontally(
    List<String> nodeIds,
    Map<String, NodePosition> positions,
    GraphData graph,
    double y,
  ) {
    for (final nodeId in nodeIds) {
      if (positions.containsKey(nodeId)) {
        final current = positions[nodeId]!;
        positions[nodeId] = NodePosition(
          nodeId: nodeId,
          position: Offset(current.position.dx, y),
          size: current.size,
        );
      }
    }
  }

  void _alignNodesVertically(
    List<String> nodeIds,
    Map<String, NodePosition> positions,
    GraphData graph,
    double x,
  ) {
    for (final nodeId in nodeIds) {
      if (positions.containsKey(nodeId)) {
        final current = positions[nodeId]!;
        positions[nodeId] = NodePosition(
          nodeId: nodeId,
          position: Offset(x, current.position.dy),
          size: current.size,
        );
      }
    }
  }

  void _distributeNodesHorizontally(
    List<String> nodeIds,
    Map<String, NodePosition> positions,
    GraphData graph,
    Rect bounds,
  ) {
    if (nodeIds.length < 2) return;

    final spacing = (bounds.width - 100) / (nodeIds.length - 1);
    final startX = bounds.left + 50;

    for (int i = 0; i < nodeIds.length; i++) {
      final nodeId = nodeIds[i];
      if (positions.containsKey(nodeId)) {
        final current = positions[nodeId]!;
        positions[nodeId] = NodePosition(
          nodeId: nodeId,
          position: Offset(startX + i * spacing, current.position.dy),
          size: current.size,
        );
      }
    }
  }

  void _distributeNodesVertically(
    List<String> nodeIds,
    Map<String, NodePosition> positions,
    GraphData graph,
    Rect bounds,
  ) {
    if (nodeIds.length < 2) return;

    final spacing = (bounds.height - 100) / (nodeIds.length - 1);
    final startY = bounds.top + 50;

    for (int i = 0; i < nodeIds.length; i++) {
      final nodeId = nodeIds[i];
      if (positions.containsKey(nodeId)) {
        final current = positions[nodeId]!;
        positions[nodeId] = NodePosition(
          nodeId: nodeId,
          position: Offset(current.position.dx, startY + i * spacing),
          size: current.size,
        );
      }
    }
  }

  void _maintainDistance(
    List<String> nodeIds,
    Map<String, NodePosition> positions,
    GraphData graph,
    double distance,
  ) {
    if (nodeIds.length < 2) return;

    final firstNodeId = nodeIds[0];
    if (!positions.containsKey(firstNodeId)) return;

    final firstPos = positions[firstNodeId]!.position;

    for (int i = 1; i < nodeIds.length; i++) {
      final nodeId = nodeIds[i];
      if (positions.containsKey(nodeId)) {
        final current = positions[nodeId]!;
        final angle = math.atan2(
          current.position.dy - firstPos.dy,
          current.position.dx - firstPos.dx,
        );
        final newPos = Offset(
          firstPos.dx + distance * math.cos(angle),
          firstPos.dy + distance * math.sin(angle),
        );

        positions[nodeId] = NodePosition(
          nodeId: nodeId,
          position: newPos,
          size: current.size,
        );
      }
    }
  }

  void _centerNodesAround(
    List<String> nodeIds,
    Map<String, NodePosition> positions,
    GraphData graph,
    Offset center,
  ) {
    final radius = 100.0;

    for (int i = 0; i < nodeIds.length; i++) {
      final nodeId = nodeIds[i];
      final node = graph.nodes.firstWhere((n) => n.id == nodeId);

      final angle = (i * 2 * math.pi) / nodeIds.length;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      positions[nodeId] = NodePosition(
        nodeId: nodeId,
        position: Offset(x, y),
        size: Size(node.width, node.height),
      );
    }
  }

  Future<void> _fillRemainingNodes(
    GraphData graph,
    Map<String, NodePosition> positions,
    LayoutConstraints constraints,
  ) async {
    final remainingNodes = graph.nodes
        .where((node) => !positions.containsKey(node.id))
        .toList();

    if (remainingNodes.isEmpty) return;

    // استفاده از Grid Layout برای نودهای باقی‌مانده
    final gridLayout = GridLayout();
    final remainingGraph = GraphData(
      nodes: remainingNodes,
      edges: graph.edges
          .where(
            (edge) =>
                remainingNodes.any((n) => n.id == edge.from) &&
                remainingNodes.any((n) => n.id == edge.to),
          )
          .toList(),
    );

    final result = await gridLayout.calculate(remainingGraph, constraints);
    positions.addAll(result.nodePositions);
  }

  double _calculateCustomQuality(
    Map<String, NodePosition> positions,
    List<LayoutRule> rules,
  ) {
    // کیفیت بر اساس رعایت rules
    double quality = 1.0;

    for (final rule in rules) {
      quality *= _evaluateRule(rule, positions);
    }

    return quality;
  }

  double _evaluateRule(LayoutRule rule, Map<String, NodePosition> positions) {
    // ارزیابی رعایت هر rule
    return 1.0; // مقدار ثابت برای سادگی
  }

  void dispose() {
    _rules.clear();
    _fixedPositions.clear();
  }
}

/// مدیر انیمیشن‌های Layout
class LayoutAnimator {
  final Map<String, AnimationController> _controllers = {};
  final Map<String, Animation<Offset>> _positionAnimations = {};
  final Map<String, Tween<Offset>> _positionTweens = {};

  Duration _animationDuration = const Duration(milliseconds: 800);
  Curve _animationCurve = Curves.easeInOutCubic;
  bool _enableAnimations = true;

  void configure({
    Duration? animationDuration,
    Curve? animationCurve,
    bool? enableAnimations,
  }) {
    _animationDuration = animationDuration ?? _animationDuration;
    _animationCurve = animationCurve ?? _animationCurve;
    _enableAnimations = enableAnimations ?? _enableAnimations;
  }

  Future<void> animateToLayout(
    Map<String, NodePosition> fromPositions,
    Map<String, NodePosition> toPositions,
    TickerProvider vsync, {
    VoidCallback? onComplete,
  }) async {
    if (!_enableAnimations) {
      onComplete?.call();
      return;
    }

    final completer = Completer<void>();
    final animatingNodes = <String>{};

    // ایجاد انیمیشن برای هر نود
    for (final entry in toPositions.entries) {
      final nodeId = entry.key;
      final toPosition = entry.value;
      final fromPosition = fromPositions[nodeId];

      if (fromPosition == null) continue;

      // تنها در صورت تغییر موقعیت انیمیشن اجرا شود
      if ((fromPosition.position - toPosition.position).distance < 1.0)
        continue;

      animatingNodes.add(nodeId);

      final controller = AnimationController(
        duration: _animationDuration,
        vsync: vsync,
      );

      final tween = Tween<Offset>(
        begin: fromPosition.position,
        end: toPosition.position,
      );

      final animation = tween.animate(
        CurvedAnimation(parent: controller, curve: _animationCurve),
      );

      _controllers[nodeId] = controller;
      _positionTweens[nodeId] = tween;
      _positionAnimations[nodeId] = animation;

      controller.forward();
    }

    if (animatingNodes.isEmpty) {
      onComplete?.call();
      return;
    }

    // انتظار برای تکمیل همه انیمیشن‌ها
    final futures = animatingNodes
        .map((nodeId) => _controllers[nodeId]!.forward())
        .toList();
    await Future.wait(futures);

    // پاکسازی
    for (final nodeId in animatingNodes) {
      _controllers[nodeId]?.dispose();
      _controllers.remove(nodeId);
      _positionTweens.remove(nodeId);
      _positionAnimations.remove(nodeId);
    }

    onComplete?.call();
  }

  Offset? getCurrentPosition(String nodeId) {
    final animation = _positionAnimations[nodeId];
    return animation?.value;
  }

  bool isAnimating(String nodeId) {
    final controller = _controllers[nodeId];
    return controller?.isAnimating ?? false;
  }

  void stopAnimation(String nodeId) {
    final controller = _controllers[nodeId];
    controller?.stop();
  }

  void stopAllAnimations() {
    for (final controller in _controllers.values) {
      controller.stop();
    }
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _positionTweens.clear();
    _positionAnimations.clear();
  }
}

/// بهینه‌ساز Layout
class LayoutOptimizer {
  final PerformanceOptimizer _performanceOptimizer = PerformanceOptimizer();

  Future<GraphData> optimizeGraph(
    GraphData graph,
    LayoutConstraints constraints,
  ) async {
    // بهینه‌سازی بر اساس عملکرد سیستم
    final report = await _getLatestPerformanceReport();

    if (report != null && report.severity == PerformanceSeverity.critical) {
      return _aggressiveOptimization(graph, constraints);
    } else if (report != null &&
        report.severity == PerformanceSeverity.warning) {
      return _moderateOptimization(graph, constraints);
    }

    return graph; // بدون بهینه‌سازی
  }

  Future<PerformanceReport?> _getLatestPerformanceReport() async {
    // دریافت آخرین گزارش عملکرد
    try {
      return await _performanceOptimizer.monitor.reports.first.timeout(
        Duration(milliseconds: 100),
      );
    } catch (e) {
      return null;
    }
  }

  GraphData _aggressiveOptimization(
    GraphData graph,
    LayoutConstraints constraints,
  ) {
    // حذف نودهای کم‌اهمیت
    final importantNodes = _selectImportantNodes(graph, 0.3); // ۳۰٪ نودها

    return GraphData(
      nodes: importantNodes,
      edges: _filterEdges(graph.edges, importantNodes.map((n) => n.id).toSet()),
    );
  }

  GraphData _moderateOptimization(
    GraphData graph,
    LayoutConstraints constraints,
  ) {
    // حذف برخی نودهای کم‌اهمیت
    final importantNodes = _selectImportantNodes(graph, 0.7); // ۷۰٪ نودها

    return GraphData(
      nodes: importantNodes,
      edges: _filterEdges(graph.edges, importantNodes.map((n) => n.id).toSet()),
    );
  }

  List<GraphNode> _selectImportantNodes(GraphData graph, double ratio) {
    final nodeCount = (graph.nodes.length * ratio).round();

    // اولویت‌بندی نودها بر اساس تعداد connections
    final connectionCounts = <String, int>{};
    for (final edge in graph.edges) {
      connectionCounts[edge.from] = (connectionCounts[edge.from] ?? 0) + 1;
      connectionCounts[edge.to] = (connectionCounts[edge.to] ?? 0) + 1;
    }

    final sortedNodes = graph.nodes.toList()
      ..sort(
        (a, b) => (connectionCounts[b.id] ?? 0).compareTo(
          connectionCounts[a.id] ?? 0,
        ),
      );

    return sortedNodes.take(nodeCount).toList();
  }

  List<GraphEdge> _filterEdges(List<GraphEdge> edges, Set<String> nodeIds) {
    return edges
        .where(
          (edge) => nodeIds.contains(edge.from) && nodeIds.contains(edge.to),
        )
        .toList();
  }

  void dispose() {
    // پاکسازی منابع
  }
}

/// محاسبه مشترک bounds و edges
Rect _calculateBounds(List<NodePosition> positions) {
  if (positions.isEmpty) return Rect.zero;

  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;

  for (final pos in positions) {
    final rect = Rect.fromCenter(
      center: pos.position,
      width: pos.size.width,
      height: pos.size.height,
    );

    minX = math.min(minX, rect.left);
    minY = math.min(minY, rect.top);
    maxX = math.max(maxX, rect.right);
    maxY = math.max(maxY, rect.bottom);
  }

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

List<EdgePosition> _calculateEdgePositions(
  List<GraphEdge> edges,
  Map<String, NodePosition> nodePositions,
) {
  final edgePositions = <EdgePosition>[];

  for (final edge in edges) {
    final fromPos = nodePositions[edge.from];
    final toPos = nodePositions[edge.to];

    if (fromPos != null && toPos != null) {
      edgePositions.add(
        EdgePosition(
          edgeId: edge.id,
          from: fromPos.position,
          to: toPos.position,
          controlPoints: _calculateControlPoints(
            fromPos.position,
            toPos.position,
          ),
        ),
      );
    }
  }

  return edgePositions;
}

List<Offset> _calculateControlPoints(Offset from, Offset to) {
  // محاسبه نقاط کنترل برای منحنی‌های بزیه
  final midPoint = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
  final distance = (to - from).distance;
  final offset = distance * 0.2;

  // محاسبه نقطه کنترل عمود بر خط اتصال
  final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
  final controlPoint = Offset(
    midPoint.dx + offset * math.cos(angle + math.pi / 2),
    midPoint.dy + offset * math.sin(angle + math.pi / 2),
  );

  return [controlPoint];
}

/// کلاس‌های مدل و داده‌ای

enum LayoutType { forceDirected, circular, tree, grid, custom }

enum TreeDirection { topDown, bottomUp, leftRight, rightLeft }

enum TreeAlignment { left, center, right }

enum LayoutRuleType {
  alignHorizontal,
  alignVertical,
  distributeHorizontal,
  distributeVertical,
  keepDistance,
  centerAround,
}

class GraphData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final bool isTree;

  GraphData({required this.nodes, required this.edges, bool? isTree})
    : isTree = isTree ?? _checkIsTree(nodes, edges);

  static bool _checkIsTree(List<GraphNode> nodes, List<GraphEdge> edges) {
    if (nodes.length != edges.length + 1) return false;

    // بررسی عدم وجود cycle
    final visited = <String>{};
    final recStack = <String>{};

    bool hasCycle(String nodeId, Map<String, List<String>> adjacency) {
      visited.add(nodeId);
      recStack.add(nodeId);

      final neighbors = adjacency[nodeId] ?? [];
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          if (hasCycle(neighbor, adjacency)) return true;
        } else if (recStack.contains(neighbor)) {
          return true;
        }
      }

      recStack.remove(nodeId);
      return false;
    }

    final adjacency = <String, List<String>>{};
    for (final edge in edges) {
      adjacency.putIfAbsent(edge.from, () => []).add(edge.to);
    }

    for (final node in nodes) {
      if (!visited.contains(node.id)) {
        if (hasCycle(node.id, adjacency)) return false;
      }
    }

    return true;
  }
}

class GraphNode {
  final String id;
  final String label;
  final double width;
  final double height;
  final Map<String, dynamic> metadata;

  GraphNode({
    required this.id,
    required this.label,
    this.width = 80.0,
    this.height = 40.0,
    this.metadata = const {},
  });
}

class GraphEdge {
  final String id;
  final String from;
  final String to;
  final String? label;
  final Map<String, dynamic> metadata;

  GraphEdge({
    required this.id,
    required this.from,
    required this.to,
    this.label,
    this.metadata = const {},
  });
}

class NodePosition {
  final String nodeId;
  final Offset position;
  final Size size;

  NodePosition({
    required this.nodeId,
    required this.position,
    required this.size,
  });
}

class EdgePosition {
  final String edgeId;
  final Offset from;
  final Offset to;
  final List<Offset> controlPoints;

  EdgePosition({
    required this.edgeId,
    required this.from,
    required this.to,
    this.controlPoints = const [],
  });
}

class LayoutConstraints {
  final Rect bounds;
  final double minNodeDistance;
  final double maxNodeDistance;
  final bool allowOverlap;
  final Set<String> fixedNodes;

  LayoutConstraints({
    required this.bounds,
    this.minNodeDistance = 50.0,
    this.maxNodeDistance = 200.0,
    this.allowOverlap = false,
    this.fixedNodes = const {},
  });
}

class LayoutResult {
  final Map<String, NodePosition> nodePositions;
  final List<EdgePosition> edges;
  final Rect bounds;
  final double quality;
  int? computationTime;

  LayoutResult({
    required this.nodePositions,
    required this.edges,
    required this.bounds,
    required this.quality,
    this.computationTime,
  });
}

class TreeNode {
  final String id;
  final GraphNode graphNode;
  final int level;
  final List<TreeNode> children;

  TreeNode({
    required this.id,
    required this.graphNode,
    required this.level,
    required this.children,
  });
}

class LayoutRule {
  final LayoutRuleType type;
  final List<String> nodeIds;
  final double value;
  final Offset? centerPoint;

  LayoutRule({
    required this.type,
    required this.nodeIds,
    this.value = 0.0,
    this.centerPoint,
  });
}

/// Widget برای نمایش Layout
class LayoutWidget extends StatefulWidget {
  final GraphData graph;
  final LayoutType layoutType;
  final LayoutConstraints constraints;
  final bool enableAnimations;
  final Function(NodePosition)? onNodeTap;
  final Function(EdgePosition)? onEdgeTap;

  const LayoutWidget({
    super.key,
    required this.graph,
    required this.layoutType,
    required this.constraints,
    this.enableAnimations = true,
    this.onNodeTap,
    this.onEdgeTap,
  });

  @override
  State<LayoutWidget> createState() => _LayoutWidgetState();
}

class _LayoutWidgetState extends State<LayoutWidget>
    with TickerProviderStateMixin {
  LayoutResult? _currentLayout;
  bool _isCalculating = false;
  final LayoutManager _layoutManager = LayoutManager();

  @override
  void initState() {
    super.initState();
    _calculateLayout();
  }

  @override
  void didUpdateWidget(LayoutWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph ||
        oldWidget.layoutType != widget.layoutType) {
      _calculateLayout();
    }
  }

  Future<void> _calculateLayout() async {
    if (_isCalculating) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final newLayout = await _layoutManager.calculateLayout(
        widget.graph,
        widget.layoutType,
        widget.constraints,
      );

      if (widget.enableAnimations && _currentLayout != null) {
        await _layoutManager.animator.animateToLayout(
          _currentLayout!.nodePositions,
          newLayout.nodePositions,
          this,
          onComplete: () {
            setState(() {
              _currentLayout = newLayout;
              _isCalculating = false;
            });
          },
        );
      } else {
        setState(() {
          _currentLayout = newLayout;
          _isCalculating = false;
        });
      }
    } catch (e) {
      debugPrint('Layout calculation error: $e');
      setState(() {
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLayout == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // رسم edges
        CustomPaint(
          painter: EdgePainter(_currentLayout!.edges),
          size: Size.infinite,
        ),

        // رسم nodes
        ..._buildNodes(),

        // نمایش اطلاعات layout
        if (_isCalculating)
          const Positioned(
            top: 10,
            right: 10,
            child: CircularProgressIndicator(),
          ),

        Positioned(bottom: 10, left: 10, child: _buildLayoutInfo()),
      ],
    );
  }

  List<Widget> _buildNodes() {
    return _currentLayout!.nodePositions.entries.map((entry) {
      final position = entry.value;
      return Positioned(
        left: position.position.dx - position.size.width / 2,
        top: position.position.dy - position.size.height / 2,
        child: GestureDetector(
          onTap: () => widget.onNodeTap?.call(position),
          child: Container(
            width: position.size.width,
            height: position.size.height,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                position.nodeId,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLayoutInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Layout: ${widget.layoutType.name}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Nodes: ${widget.graph.nodes.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Quality: ${(_currentLayout!.quality * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (_currentLayout!.computationTime != null)
            Text(
              'Time: ${_currentLayout!.computationTime}ms',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _layoutManager.dispose();
    super.dispose();
  }
}

/// Painter برای رسم edges
class EdgePainter extends CustomPainter {
  final List<EdgePosition> edges;
  final Paint _edgePaint = Paint()
    ..color = Colors.grey.shade600
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  EdgePainter(this.edges);

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      if (edge.controlPoints.isNotEmpty) {
        // رسم منحنی بزیه
        final path = Path();
        path.moveTo(edge.from.dx, edge.from.dy);

        for (final controlPoint in edge.controlPoints) {
          path.quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            edge.to.dx,
            edge.to.dy,
          );
        }

        canvas.drawPath(path, _edgePaint);
      } else {
        // رسم خط مستقیم
        canvas.drawLine(edge.from, edge.to, _edgePaint);
      }

      // رسم فلش در انتهای edge
      _drawArrow(canvas, edge.from, edge.to);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to) {
    final arrowLength = 10.0;
    final arrowAngle = math.pi / 6;

    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);

    final arrowPoint1 = Offset(
      to.dx - arrowLength * math.cos(angle - arrowAngle),
      to.dy - arrowLength * math.sin(angle - arrowAngle),
    );

    final arrowPoint2 = Offset(
      to.dx - arrowLength * math.cos(angle + arrowAngle),
      to.dy - arrowLength * math.sin(angle + arrowAngle),
    );

    final arrowPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();

    canvas.drawPath(arrowPath, _edgePaint..style = PaintingStyle.fill);
    _edgePaint.style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(EdgePainter oldDelegate) {
    return edges != oldDelegate.edges;
  }
}
