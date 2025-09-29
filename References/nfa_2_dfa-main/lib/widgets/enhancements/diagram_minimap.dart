import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '/widgets/state_diagram.dart';
import 'diagram_themes.dart';
import 'performance_optimizer.dart';
import 'dart:async';

/// کلاس‌های مورد نیاز برای minimap
enum StateType {
  normal,
  start,
  final_,
}

class StateNode {
  final String id;
  final String label;
  final Offset position;
  final StateType type;
  final Map<String, dynamic> metadata;
  final Color? customColor;

  const StateNode({
    required this.id,
    required this.label,
    required this.position,
    this.type = StateType.normal,
    this.metadata = const {},
    this.customColor,
  });

  StateNode copyWith({
    String? id,
    String? label,
    Offset? position,
    StateType? type,
    Map<String, dynamic>? metadata,
    Color? customColor,
  }) {
    return StateNode(
      id: id ?? this.id,
      label: label ?? this.label,
      position: position ?? this.position,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      customColor: customColor ?? this.customColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StateNode &&
        other.id == id &&
        other.label == label &&
        other.position == position &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^ label.hashCode ^ position.hashCode ^ type.hashCode;
  }
}

class StateTransition {
  final String id;
  final String fromState;
  final String toState;
  final String condition;
  final String? label;
  final Map<String, dynamic> metadata;
  final Color? customColor;

  const StateTransition({
    required this.id,
    required this.fromState,
    required this.toState,
    this.condition = '',
    this.label,
    this.metadata = const {},
    this.customColor,
  });

  StateTransition copyWith({
    String? id,
    String? fromState,
    String? toState,
    String? condition,
    String? label,
    Map<String, dynamic>? metadata,
    Color? customColor,
  }) {
    return StateTransition(
      id: id ?? this.id,
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      condition: condition ?? this.condition,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
      customColor: customColor ?? this.customColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StateTransition &&
        other.id == id &&
        other.fromState == fromState &&
        other.toState == toState &&
        other.condition == condition;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fromState.hashCode ^
        toState.hashCode ^
        condition.hashCode;
  }
}

// کلاس Theme موقت برای جلوگیری از خطا
class DiagramTheme {
  final Color backgroundColor;
  final Color primaryColor;
  final bool isDark;
  final DiagramThemeConfig config;

  const DiagramTheme({
    required this.backgroundColor,
    required this.primaryColor,
    this.isDark = false,
    required this.config,
  });
}

class DiagramThemeConfig {
  final double nodeSize;
  final Color gridColor;
  final Color edgeColor;
  final Color stateColor;
  final Color startStateColor;
  final Color finalStateColor;
  final Color selectedColor;
  final Color highlightColor;

  const DiagramThemeConfig({
    this.nodeSize = 20,
    this.gridColor = Colors.grey,
    this.edgeColor = Colors.black54,
    this.stateColor = Colors.blue,
    this.startStateColor = Colors.green,
    this.finalStateColor = Colors.red,
    this.selectedColor = Colors.orange,
    this.highlightColor = Colors.yellow,
  });
}

/// ویجت Minimap برای دیاگرام حالت
class DiagramMinimap extends StatefulWidget {
  final Size diagramSize;
  final Rect viewport;
  final List<StateNode> nodes;
  final List<StateTransition> transitions;
  final Function(Offset) onNavigate;
  final Function(double)? onZoomChanged;
  final DiagramTheme theme;
  final MinimapConfig config;
  final bool showStatistics;
  final Function(String)? onNodeSelected;

  const DiagramMinimap({
    super.key,
    required this.diagramSize,
    required this.viewport,
    required this.nodes,
    required this.transitions,
    required this.onNavigate,
    this.onZoomChanged,
    required this.theme,
    this.config = const MinimapConfig(),
    this.showStatistics = false,
    this.onNodeSelected,
  });

  @override
  State<DiagramMinimap> createState() => _DiagramMinimapState();
}

class _DiagramMinimapState extends State<DiagramMinimap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late MinimapController _controller;

  Offset? _dragStart;
  bool _isDragging = false;
  double _currentZoom = 1.0;
  Timer? _hideTimer;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _controller = MinimapController(
      diagramSize: widget.diagramSize,
      minimapSize: widget.config.size,
    );

    _animationController.forward();
    _startAutoHideTimer();
  }

  void _startAutoHideTimer() {
    if (!widget.config.autoHide) return;

    _hideTimer?.cancel();
    _hideTimer = Timer(widget.config.autoHideDuration, () {
      if (mounted && !_isDragging) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _showMinimap() {
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
    }
    _startAutoHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: widget.config.margin.right,
      bottom: widget.config.margin.bottom,
      child: MouseRegion(
        onEnter: (_) => _showMinimap(),
        onExit: (_) => _startAutoHideTimer(),
        child: AnimatedOpacity(
          opacity: _isVisible ? widget.config.opacity : 0.3,
          duration: const Duration(milliseconds: 200),
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fadeAnimation.value,
                child: _buildMinimapContainer(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMinimapContainer() {
    return Container(
      width: widget.config.size.width,
      height: widget.config.size.height + (widget.showStatistics ? 60 : 0),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(widget.config.borderRadius),
        border: Border.all(
          color: widget.theme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMinimapHeader(),
          Expanded(
            child: _buildMinimapView(),
          ),
          if (widget.showStatistics) _buildStatistics(),
          if (widget.config.showZoomControls) _buildZoomControls(),
        ],
      ),
    );
  }

  Widget _buildMinimapHeader() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: widget.theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.config.borderRadius),
          topRight: Radius.circular(widget.config.borderRadius),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.map,
            size: 16,
            color: widget.theme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Minimap',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: widget.theme.primaryColor,
            ),
          ),
          const Spacer(),
          Text(
            '${(widget.viewport.width / widget.diagramSize.width * 100).round()}%',
            style: TextStyle(
              fontSize: 10,
              color: widget.theme.primaryColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimapView() {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
        margin: const EdgeInsets.all(4),
        child: CustomPaint(
          painter: MinimapPainter(
            diagramSize: widget.diagramSize,
            viewport: widget.viewport,
            nodes: widget.nodes,
            transitions: widget.transitions,
            theme: widget.theme,
            config: widget.config,
            controller: _controller,
          ),
          size: Size(
            widget.config.size.width - 8,
            widget.config.size.height - (widget.showStatistics ? 94 : 34),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final visibleNodes =
        _controller.getVisibleNodes(widget.nodes, widget.viewport);
    final totalNodes = widget.nodes.length;
    final totalTransitions = widget.transitions.length;

    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.theme.primaryColor.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: widget.theme.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Nodes', '$visibleNodes/$totalNodes'),
              _buildStatItem('Edges', '$totalTransitions'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Zoom', '${(_currentZoom * 100).round()}%'),
              _buildStatItem('Scale',
                  '1:${(widget.diagramSize.width / widget.config.size.width).round()}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: widget.theme.primaryColor.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: widget.theme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: widget.theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(widget.config.borderRadius),
          bottomRight: Radius.circular(widget.config.borderRadius),
        ),
        border: Border(
          top: BorderSide(
            color: widget.theme.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildZoomButton(Icons.remove, () => _changeZoom(-0.1)),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '${(_currentZoom * 100).round()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: widget.theme.primaryColor,
              ),
            ),
          ),
          _buildZoomButton(Icons.add, () => _changeZoom(0.1)),
          const SizedBox(width: 8),
          _buildZoomButton(Icons.fit_screen, _fitToScreen),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.theme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: widget.theme.primaryColor,
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _showMinimap();

    final localPosition = details.localPosition;
    final diagramPosition = _controller.minimapToDiagramCoordinates(
      localPosition,
      Size(
        widget.config.size.width - 8,
        widget.config.size.height - (widget.showStatistics ? 94 : 34),
      ),
    );

    widget.onNavigate(diagramPosition);

    // بررسی کلیک روی نود
    final clickedNode = _findNodeAtPosition(diagramPosition);
    if (clickedNode != null && widget.onNodeSelected != null) {
      widget.onNodeSelected!(clickedNode.id);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    _showMinimap();
    _dragStart = details.localPosition;
    _isDragging = true;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragStart == null) return;

    final delta = details.localPosition - _dragStart!;
    final diagramDelta = _controller.minimapToDiagramDelta(
      delta,
      Size(
        widget.config.size.width - 8,
        widget.config.size.height - (widget.showStatistics ? 94 : 34),
      ),
    );

    final newCenter = widget.viewport.center + diagramDelta;
    widget.onNavigate(newCenter);

    _dragStart = details.localPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    _isDragging = false;
    _dragStart = null;
    _startAutoHideTimer();
  }

  void _changeZoom(double delta) {
    _currentZoom = (_currentZoom + delta).clamp(0.1, 5.0);
    widget.onZoomChanged?.call(_currentZoom);
  }

  void _fitToScreen() {
    if (widget.nodes.isEmpty) return;

    // محاسبه bounding box نودها
    final bounds = _controller.calculateNodesBounds(widget.nodes);

    // محاسبه zoom مناسب
    final scaleX = widget.config.size.width / bounds.width;
    final scaleY = widget.config.size.height / bounds.height;
    final scale = math.min(scaleX, scaleY) * 0.8; // اندکی padding

    _currentZoom = scale;
    widget.onZoomChanged?.call(_currentZoom);
    widget.onNavigate(bounds.center);
  }

  StateNode? _findNodeAtPosition(Offset position) {
    for (final node in widget.nodes) {
      final nodeRect = Rect.fromCenter(
        center: node.position,
        width: widget.theme.config.nodeSize * 2,
        height: widget.theme.config.nodeSize * 2,
      );

      if (nodeRect.contains(position)) {
        return node;
      }
    }
    return null;
  }

  @override
  void didUpdateWidget(DiagramMinimap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.diagramSize != widget.diagramSize ||
        oldWidget.config.size != widget.config.size) {
      _controller = MinimapController(
        diagramSize: widget.diagramSize,
        minimapSize: widget.config.size,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }
}

/// کنترلر Minimap
class MinimapController {
  final Size diagramSize;
  final Size minimapSize;
  late final double scale;

  MinimapController({
    required this.diagramSize,
    required this.minimapSize,
  }) {
    scale = math.min(
      minimapSize.width / diagramSize.width,
      minimapSize.height / diagramSize.height,
    );
  }

  /// تبدیل مختصات minimap به مختصات دیاگرام
  Offset minimapToDiagramCoordinates(
      Offset minimapPoint, Size actualMinimapSize) {
    final actualScale = math.min(
      actualMinimapSize.width / diagramSize.width,
      actualMinimapSize.height / diagramSize.height,
    );

    return Offset(
      minimapPoint.dx / actualScale,
      minimapPoint.dy / actualScale,
    );
  }

  /// تبدیل delta مختصات minimap به delta دیاگرام
  Offset minimapToDiagramDelta(Offset minimapDelta, Size actualMinimapSize) {
    final actualScale = math.min(
      actualMinimapSize.width / diagramSize.width,
      actualMinimapSize.height / diagramSize.height,
    );

    return Offset(
      minimapDelta.dx / actualScale,
      minimapDelta.dy / actualScale,
    );
  }

  /// تبدیل مختصات دیاگرام به مختصات minimap
  Offset diagramToMinimapCoordinates(
      Offset diagramPoint, Size actualMinimapSize) {
    final actualScale = math.min(
      actualMinimapSize.width / diagramSize.width,
      actualMinimapSize.height / diagramSize.height,
    );

    return Offset(
      diagramPoint.dx * actualScale,
      diagramPoint.dy * actualScale,
    );
  }

  /// محاسبه محدوده نودها
  Rect calculateNodesBounds(List<StateNode> nodes) {
    if (nodes.isEmpty) return Rect.zero;

    double minX = nodes.first.position.dx;
    double maxX = nodes.first.position.dx;
    double minY = nodes.first.position.dy;
    double maxY = nodes.first.position.dy;

    for (final node in nodes) {
      minX = math.min(minX, node.position.dx);
      maxX = math.max(maxX, node.position.dx);
      minY = math.min(minY, node.position.dy);
      maxY = math.max(maxY, node.position.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// محاسبه تعداد نودهای قابل مشاهده
  int getVisibleNodes(List<StateNode> nodes, Rect viewport) {
    int visibleCount = 0;

    for (final node in nodes) {
      if (viewport.contains(node.position)) {
        visibleCount++;
      }
    }

    return visibleCount;
  }
}

/// رسم کننده Minimap
class MinimapPainter extends CustomPainter {
  final Size diagramSize;
  final Rect viewport;
  final List<StateNode> nodes;
  final List<StateTransition> transitions;
  final DiagramTheme theme;
  final MinimapConfig config;
  final MinimapController controller;

  MinimapPainter({
    required this.diagramSize,
    required this.viewport,
    required this.nodes,
    required this.transitions,
    required this.theme,
    required this.config,
    required this.controller,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / diagramSize.width,
      size.height / diagramSize.height,
    );

    canvas.save();
    canvas.scale(scale);

    // رسم پس‌زمینه
    _drawBackground(canvas);

    // رسم شبکه در صورت فعال بودن
    if (config.showGrid) {
      _drawGrid(canvas);
    }

    // رسم transitions
    _drawTransitions(canvas);

    // رسم نودها
    _drawNodes(canvas);

    // رسم viewport indicator
    _drawViewportIndicator(canvas);

    canvas.restore();

    // رسم اطلاعات اضافی
    _drawOverlayInfo(canvas, size);
  }

  void _drawBackground(Canvas canvas) {
    final paint = Paint()
      ..color = theme.backgroundColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, diagramSize.width, diagramSize.height),
      paint,
    );
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = theme.config.gridColor.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSpacing = 100.0;

    // خطوط عمودی
    for (double x = 0; x <= diagramSize.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, diagramSize.height),
        paint,
      );
    }

    // خطوط افقی
    for (double y = 0; y <= diagramSize.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(diagramSize.width, y),
        paint,
      );
    }
  }

  void _drawTransitions(Canvas canvas) {
    if (!config.showTransitions) return;

    final paint = Paint()
      ..color = theme.config.edgeColor.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final transition in transitions) {
      final fromNode =
          nodes.where((n) => n.id == transition.fromState).firstOrNull;
      final toNode = nodes.where((n) => n.id == transition.toState).firstOrNull;

      if (fromNode != null && toNode != null) {
        canvas.drawLine(fromNode.position, toNode.position, paint);
      }
    }
  }

  void _drawNodes(Canvas canvas) {
    final normalPaint = Paint()
      ..color = theme.config.stateColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final startPaint = Paint()
      ..color = theme.config.startStateColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final finalPaint = Paint()
      ..color = theme.config.finalStateColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = theme.config.stateColor.withOpacity(0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final node in nodes) {
      Paint fillPaint;
      switch (node.type) {
        case StateType.start:
          fillPaint = startPaint;
          break;
        case StateType.final_:
          fillPaint = finalPaint;
          break;
        default:
          fillPaint = normalPaint;
      }

      final nodeRadius = config.nodeSize;

      // رسم نود
      canvas.drawCircle(node.position, nodeRadius, fillPaint);
      canvas.drawCircle(node.position, nodeRadius, borderPaint);

      // رسم دایره داخلی برای حالت پایانی
      if (node.type == StateType.final_) {
        canvas.drawCircle(node.position, nodeRadius * 0.7, borderPaint);
      }

      // رسم نام نود در صورت فعال بودن
      if (config.showLabels && nodeRadius > 3) {
        _drawNodeLabel(canvas, node, nodeRadius);
      }
    }
  }

  void _drawNodeLabel(Canvas canvas, StateNode node, double nodeRadius) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.label.length > 3 ? node.label.substring(0, 3) : node.label,
        style: TextStyle(
          color: theme.isDark ? Colors.white : Colors.black,
          fontSize: math.max(6, nodeRadius * 0.4),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final offset = Offset(
      node.position.dx - textPainter.width / 2,
      node.position.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
  }

  void _drawViewportIndicator(Canvas canvas) {
    final paint = Paint()
      ..color = theme.primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = theme.primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // رسم محدوده viewport
    canvas.drawRect(viewport, paint);
    canvas.drawRect(viewport, borderPaint);

    // رسم مرکز viewport
    final centerPaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(viewport.center, 3.0, centerPaint);
  }

  void _drawOverlayInfo(Canvas canvas, Size size) {
    if (!config.showCurrentPosition) return;

    // رسم موقعیت فعلی در گوشه
    final textPainter = TextPainter(
      text: TextSpan(
        text: '(${viewport.center.dx.round()}, ${viewport.center.dy.round()})',
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final offset = Offset(
      size.width - textPainter.width - 4,
      4,
    );

    // رسم پس‌زمینه متن
    final bgRect = Rect.fromLTWH(
      offset.dx - 2,
      offset.dy - 1,
      textPainter.width + 4,
      textPainter.height + 2,
    );

    final bgPaint = Paint()
      ..color = theme.backgroundColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(2)),
      bgPaint,
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) {
    return oldDelegate.viewport != viewport ||
        oldDelegate.nodes != nodes ||
        oldDelegate.transitions != transitions ||
        oldDelegate.theme != theme ||
        oldDelegate.config != config;
  }
}

/// تنظیمات Minimap
class MinimapConfig {
  final Size size;
  final EdgeInsets margin;
  final double opacity;
  final double borderRadius;
  final bool autoHide;
  final Duration autoHideDuration;
  final bool showGrid;
  final bool showTransitions;
  final bool showLabels;
  final bool showZoomControls;
  final bool showCurrentPosition;
  final double nodeSize;
  final Color? backgroundColor;
  final Color? borderColor;

  const MinimapConfig({
    this.size = const Size(200, 150),
    this.margin = const EdgeInsets.all(16),
    this.opacity = 0.9,
    this.borderRadius = 8.0,
    this.autoHide = false,
    this.autoHideDuration = const Duration(seconds: 3),
    this.showGrid = true,
    this.showTransitions = true,
    this.showLabels = false,
    this.showZoomControls = true,
    this.showCurrentPosition = true,
    this.nodeSize = 4.0,
    this.backgroundColor,
    this.borderColor,
  });

  MinimapConfig copyWith({
    Size? size,
    EdgeInsets? margin,
    double? opacity,
    double? borderRadius,
    bool? autoHide,
    Duration? autoHideDuration,
    bool? showGrid,
    bool? showTransitions,
    bool? showLabels,
    bool? showZoomControls,
    bool? showCurrentPosition,
    double? nodeSize,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return MinimapConfig(
      size: size ?? this.size,
      margin: margin ?? this.margin,
      opacity: opacity ?? this.opacity,
      borderRadius: borderRadius ?? this.borderRadius,
      autoHide: autoHide ?? this.autoHide,
      autoHideDuration: autoHideDuration ?? this.autoHideDuration,
      showGrid: showGrid ?? this.showGrid,
      showTransitions: showTransitions ?? this.showTransitions,
      showLabels: showLabels ?? this.showLabels,
      showZoomControls: showZoomControls ?? this.showZoomControls,
      showCurrentPosition: showCurrentPosition ?? this.showCurrentPosition,
      nodeSize: nodeSize ?? this.nodeSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}

/// ویجت تنظیمات پیشرفته Minimap
class MinimapSettings extends StatefulWidget {
  final MinimapConfig config;
  final Function(MinimapConfig) onConfigChanged;
  final DiagramTheme theme;

  const MinimapSettings({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.theme,
  });

  @override
  State<MinimapSettings> createState() => _MinimapSettingsState();
}

class _MinimapSettingsState extends State<MinimapSettings> {
  late MinimapConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.primaryColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionTitle('Minimap Settings'),
          const SizedBox(height: 16),
          _buildSizeSliders(),
          const SizedBox(height: 16),
          _buildVisibilityToggles(),
          const SizedBox(height: 16),
          _buildAppearanceControls(),
          const SizedBox(height: 16),
          _buildBehaviorSettings(),
          const SizedBox(height: 16),
          _buildPresetButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: widget.theme.primaryColor,
      ),
    );
  }

  Widget _buildSizeSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTitle('Size'),
        _buildSlider(
          'Width',
          _config.size.width,
          100,
          400,
          (value) => _updateConfig(_config.copyWith(
            size: Size(value, _config.size.height),
          )),
        ),
        _buildSlider(
          'Height',
          _config.size.height,
          75,
          300,
          (value) => _updateConfig(_config.copyWith(
            size: Size(_config.size.width, value),
          )),
        ),
        _buildSlider(
          'Node Size',
          _config.nodeSize,
          2,
          10,
          (value) => _updateConfig(_config.copyWith(nodeSize: value)),
        ),
      ],
    );
  }

  Widget _buildVisibilityToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTitle('Visibility'),
        _buildToggle(
          'Show Grid',
          _config.showGrid,
          (value) => _updateConfig(_config.copyWith(showGrid: value)),
        ),
        _buildToggle(
          'Show Transitions',
          _config.showTransitions,
          (value) => _updateConfig(_config.copyWith(showTransitions: value)),
        ),
        _buildToggle(
          'Show Labels',
          _config.showLabels,
          (value) => _updateConfig(_config.copyWith(showLabels: value)),
        ),
        _buildToggle(
          'Show Zoom Controls',
          _config.showZoomControls,
          (value) => _updateConfig(_config.copyWith(showZoomControls: value)),
        ),
        _buildToggle(
          'Show Current Position',
          _config.showCurrentPosition,
          (value) =>
              _updateConfig(_config.copyWith(showCurrentPosition: value)),
        ),
      ],
    );
  }

  Widget _buildAppearanceControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTitle('Appearance'),
        _buildSlider(
          'Opacity',
          _config.opacity,
          0.3,
          1.0,
          (value) => _updateConfig(_config.copyWith(opacity: value)),
        ),
        _buildSlider(
          'Border Radius',
          _config.borderRadius,
          0,
          20,
          (value) => _updateConfig(_config.copyWith(borderRadius: value)),
        ),
      ],
    );
  }

  Widget _buildBehaviorSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTitle('Behavior'),
        _buildToggle(
          'Auto Hide',
          _config.autoHide,
          (value) => _updateConfig(_config.copyWith(autoHide: value)),
        ),
        if (_config.autoHide)
          _buildSlider(
            'Auto Hide Duration (seconds)',
            _config.autoHideDuration.inSeconds.toDouble(),
            1,
            10,
            (value) => _updateConfig(_config.copyWith(
              autoHideDuration: Duration(seconds: value.round()),
            )),
          ),
      ],
    );
  }

  Widget _buildPresetButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTitle('Presets'),
        Wrap(
          spacing: 8,
          children: [
            _buildPresetButton('Compact', _getCompactPreset()),
            _buildPresetButton('Standard', _getStandardPreset()),
            _buildPresetButton('Detailed', _getDetailedPreset()),
            _buildPresetButton('Minimal', _getMinimalPreset()),
          ],
        ),
      ],
    );
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: widget.theme.primaryColor.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: widget.theme.primaryColor.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) * (max > 10 ? 1 : 10)).round(),
              activeColor: widget.theme.primaryColor,
              inactiveColor: widget.theme.primaryColor.withOpacity(0.3),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(value > 10 ? 0 : 1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.theme.primaryColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: widget.theme.primaryColor.withOpacity(0.7),
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: widget.theme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, MinimapConfig preset) {
    return GestureDetector(
      onTap: () => _updateConfig(preset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: widget.theme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: widget.theme.primaryColor,
          ),
        ),
      ),
    );
  }

  void _updateConfig(MinimapConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig);
  }

  MinimapConfig _getCompactPreset() {
    return const MinimapConfig(
      size: Size(150, 100),
      showGrid: false,
      showLabels: false,
      showZoomControls: false,
      showCurrentPosition: false,
      nodeSize: 3.0,
      opacity: 0.8,
    );
  }

  MinimapConfig _getStandardPreset() {
    return const MinimapConfig(
      size: Size(200, 150),
      showGrid: true,
      showLabels: false,
      showZoomControls: true,
      showCurrentPosition: true,
      nodeSize: 4.0,
      opacity: 0.9,
    );
  }

  MinimapConfig _getDetailedPreset() {
    return const MinimapConfig(
      size: Size(300, 225),
      showGrid: true,
      showLabels: true,
      showZoomControls: true,
      showCurrentPosition: true,
      nodeSize: 6.0,
      opacity: 1.0,
    );
  }

  MinimapConfig _getMinimalPreset() {
    return const MinimapConfig(
      size: Size(120, 80),
      showGrid: false,
      showLabels: false,
      showZoomControls: false,
      showCurrentPosition: false,
      nodeSize: 2.0,
      opacity: 0.7,
      autoHide: true,
    );
  }
}

/// ویجت نمایش آمار پیشرفته
class MinimapStatistics extends StatelessWidget {
  final List<StateNode> nodes;
  final List<StateTransition> transitions;
  final Rect viewport;
  final Size diagramSize;
  final DiagramTheme theme;

  const MinimapStatistics({
    super.key,
    required this.nodes,
    required this.transitions,
    required this.viewport,
    required this.diagramSize,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatRow('Total Nodes', '${stats.totalNodes}'),
          _buildStatRow('Visible Nodes', '${stats.visibleNodes}'),
          _buildStatRow('Hidden Nodes', '${stats.hiddenNodes}'),
          _buildStatRow('Transitions', '${stats.totalTransitions}'),
          _buildStatRow('Start States', '${stats.startStates}'),
          _buildStatRow('Final States', '${stats.finalStates}'),
          const Divider(height: 16),
          _buildStatRow('Viewport Coverage',
              '${stats.viewportCoverage.toStringAsFixed(1)}%'),
          _buildStatRow('Diagram Scale', '1:${stats.scale.toStringAsFixed(0)}'),
          _buildStatRow(
              'Node Density', '${stats.nodeDensity.toStringAsFixed(2)}/unit²'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.primaryColor.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  MinimapStats _calculateStatistics() {
    final visibleNodes =
        nodes.where((node) => viewport.contains(node.position)).length;
    final startStates =
        nodes.where((node) => node.type == StateType.start).length;
    final finalStates =
        nodes.where((node) => node.type == StateType.final_).length;

    final viewportArea = viewport.width * viewport.height;
    final diagramArea = diagramSize.width * diagramSize.height;
    final viewportCoverage = (viewportArea / diagramArea) * 100;

    final scale = math.max(diagramSize.width / 200, diagramSize.height / 150);

    final nodeDensity =
        nodes.length / (diagramArea / 10000); // nodes per 100x100 unit

    return MinimapStats(
      totalNodes: nodes.length,
      visibleNodes: visibleNodes,
      hiddenNodes: nodes.length - visibleNodes,
      totalTransitions: transitions.length,
      startStates: startStates,
      finalStates: finalStates,
      viewportCoverage: viewportCoverage,
      scale: scale,
      nodeDensity: nodeDensity,
    );
  }
}

/// کلاس آمار Minimap
class MinimapStats {
  final int totalNodes;
  final int visibleNodes;
  final int hiddenNodes;
  final int totalTransitions;
  final int startStates;
  final int finalStates;
  final double viewportCoverage;
  final double scale;
  final double nodeDensity;

  MinimapStats({
    required this.totalNodes,
    required this.visibleNodes,
    required this.hiddenNodes,
    required this.totalTransitions,
    required this.startStates,
    required this.finalStates,
    required this.viewportCoverage,
    required this.scale,
    required this.nodeDensity,
  });
}

/// ویجت Minimap با قابلیت‌های پیشرفته
class AdvancedMinimap extends StatefulWidget {
  final Size diagramSize;
  final Rect viewport;
  final List<StateNode> nodes;
  final List<StateTransition> transitions;
  final Function(Offset) onNavigate;
  final Function(double)? onZoomChanged;
  final DiagramTheme theme;
  final Function(String)? onNodeSelected;
  final Function(String)? onNodeHighlighted;
  final Set<String>? highlightedNodes;
  final String? selectedNode;

  const AdvancedMinimap({
    super.key,
    required this.diagramSize,
    required this.viewport,
    required this.nodes,
    required this.transitions,
    required this.onNavigate,
    this.onZoomChanged,
    required this.theme,
    this.onNodeSelected,
    this.onNodeHighlighted,
    this.highlightedNodes,
    this.selectedNode,
  });

  @override
  State<AdvancedMinimap> createState() => _AdvancedMinimapState();
}

class _AdvancedMinimapState extends State<AdvancedMinimap>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  MinimapConfig _config = const MinimapConfig();
  bool _showSettings = false;
  bool _showStatistics = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DiagramMinimap(
          diagramSize: widget.diagramSize,
          viewport: widget.viewport,
          nodes: widget.nodes,
          transitions: widget.transitions,
          onNavigate: widget.onNavigate,
          onZoomChanged: widget.onZoomChanged,
          theme: widget.theme,
          config: _config,
          showStatistics: _showStatistics,
          onNodeSelected: widget.onNodeSelected,
        ),

        // دکمه‌های کنترل
        Positioned(
          right: _config.margin.right,
          bottom: _config.margin.bottom + _config.size.height + 8,
          child: _buildControlButtons(),
        ),

        // پنل تنظیمات
        if (_showSettings)
          Positioned(
            right: _config.margin.right + _config.size.width + 16,
            bottom: _config.margin.bottom,
            child: MinimapSettings(
              config: _config,
              onConfigChanged: (config) {
                setState(() {
                  _config = config;
                });
              },
              theme: widget.theme,
            ),
          ),

        // آمار پیشرفته
        if (_showStatistics)
          Positioned(
            right: _config.margin.right,
            bottom: _config.margin.bottom + _config.size.height + 70,
            child: MinimapStatistics(
              nodes: widget.nodes,
              transitions: widget.transitions,
              viewport: widget.viewport,
              diagramSize: widget.diagramSize,
              theme: widget.theme,
            ),
          ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildControlButton(
          Icons.settings,
          'Settings',
          _showSettings,
          () => setState(() => _showSettings = !_showSettings),
        ),
        const SizedBox(width: 8),
        _buildControlButton(
          Icons.analytics,
          'Statistics',
          _showStatistics,
          () => setState(() => _showStatistics = !_showStatistics),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    IconData icon,
    String tooltip,
    bool isActive,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? widget.theme.primaryColor
                : widget.theme.backgroundColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.theme.primaryColor.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? Colors.white : widget.theme.primaryColor,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

/// Extension برای کار راحت‌تر با StateNode
extension StateNodeExtensions on StateNode {
  bool get isStart => type == StateType.start;
  bool get isFinal => type == StateType.final_;
  bool get isNormal => type == StateType.normal;
}

/// Helper functions
class MinimapUtils {
  /// محاسبه بهترین سایز minimap بر اساس سایز دیاگرام
  static Size calculateOptimalSize(
      Size diagramSize, double maxWidth, double maxHeight) {
    final aspectRatio = diagramSize.width / diagramSize.height;

    if (aspectRatio > 1) {
      // عرض بیشتر از ارتفاع
      final width = math.min(maxWidth, maxHeight * aspectRatio);
      final height = width / aspectRatio;
      return Size(width, height);
    } else {
      // ارتفاع بیشتر از عرض
      final height = math.min(maxHeight, maxWidth / aspectRatio);
      final width = height * aspectRatio;
      return Size(width, height);
    }
  }

  /// تعیین رنگ نود بر اساس نوع و وضعیت
  static Color getNodeColor(
    StateNode node,
    DiagramTheme theme, {
    bool isSelected = false,
    bool isHighlighted = false,
    double opacity = 1.0,
  }) {
    Color baseColor;

    switch (node.type) {
      case StateType.start:
        baseColor = theme.config.startStateColor;
        break;
      case StateType.final_:
        baseColor = theme.config.finalStateColor;
        break;
      default:
        baseColor = theme.config.stateColor;
    }

    if (isSelected) {
      baseColor = theme.config.selectedColor;
    } else if (isHighlighted) {
      baseColor = theme.config.highlightColor;
    }

    return baseColor.withOpacity(opacity);
  }

  /// محاسبه مختصات بهینه برای قرارگیری minimap
  static Offset calculateOptimalPosition(
      Size screenSize, Size minimapSize, EdgeInsets safeArea) {
    final rightMargin = 16.0;
    final bottomMargin = 16.0;

    return Offset(
      screenSize.width - minimapSize.width - rightMargin - safeArea.right,
      screenSize.height - minimapSize.height - bottomMargin - safeArea.bottom,
    );
  }
}
