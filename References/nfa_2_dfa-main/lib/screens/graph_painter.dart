import 'package:flutter/material.dart';
import '../models/nfa.dart';
import '../models/dfa.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

enum GraphLayoutType {
  circular(Icons.radio_button_unchecked, 'دایره‌ای'),
  grid(Icons.grid_4x4, 'شبکه‌ای'),
  hierarchical(Icons.account_tree, 'سلسله مراتبی'),
  force(Icons.scatter_plot, 'نیروی جاذبه'),
  manual(Icons.pan_tool, 'دستی'),
  layered(Icons.layers, 'لایه‌ای'),
  radial(Icons.radar, 'شعاعی'),
  organic(Icons.nature, 'ارگانیک');

  const GraphLayoutType(this.icon, this.displayName);
  final IconData icon;
  final String displayName;
}

enum GraphTheme {
  light('روشن', Colors.blue, Colors.white, Colors.black),
  dark('تیره', Colors.purple, Color(0xFF121212), Colors.white),
  colorful('رنگارنگ', Colors.orange, Colors.white, Colors.black),
  minimal('مینیمال', Colors.grey, Colors.white, Colors.black87),
  neon('نئون', Colors.cyan, Colors.black, Colors.cyan),
  pastel('پاستلی', Colors.pink, Color(0xFFF8F9FA), Colors.black54),
  contrast('کنتراست بالا', Colors.red, Colors.white, Colors.black),
  nature('طبیعی', Colors.green, Color(0xFFF0F8F0), Colors.green);

  const GraphTheme(
      this.name, this.primaryColor, this.backgroundColor, this.textColor);
  final String name;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
}

enum AnimationType {
  none('بدون انیمیشن'),
  fade('محو شدن'),
  scale('تغییر اندازه'),
  slide('حرکت'),
  bounce('پرش'),
  pulse('پالس'),
  rotate('چرخش');

  const AnimationType(this.displayName);
  final String displayName;
}

class GraphAnimationController {
  double _currentFrame = 0.0;
  final double maxFrames = 60.0;
  final Map<String, double> _stateAnimations = {};
  final Map<String, double> _transitionAnimations = {};

  void startStateAnimation(String state, AnimationType type) {
    _stateAnimations[state] = 0.0;
  }

  void startTransitionAnimation(String transition, AnimationType type) {
    _transitionAnimations[transition] = 0.0;
  }

  void update() {
    _currentFrame = (_currentFrame + 1) % maxFrames;

    for (final key in _stateAnimations.keys.toList()) {
      _stateAnimations[key] = (_stateAnimations[key]! + 0.1).clamp(0.0, 1.0);
      if (_stateAnimations[key]! >= 1.0) {
        _stateAnimations.remove(key);
      }
    }

    for (final key in _transitionAnimations.keys.toList()) {
      _transitionAnimations[key] =
          (_transitionAnimations[key]! + 0.1).clamp(0.0, 1.0);
      if (_transitionAnimations[key]! >= 1.0) {
        _transitionAnimations.remove(key);
      }
    }
  }

  double getStateAnimation(String state) => _stateAnimations[state] ?? 1.0;
  double getTransitionAnimation(String transition) =>
      _transitionAnimations[transition] ?? 1.0;
  double get currentFrame => _currentFrame;
}

class AdvancedAutomatonPainter extends CustomPainter {
  final dynamic automaton;
  final String? selectedState;
  final String? hoveredState;
  final Set<String> highlightedStates;
  final Set<String> highlightedTransitions;
  final GraphLayoutType layoutType;
  final Map<String, Offset> manualPositions;
  final double nodeSize;
  final GraphTheme theme;
  final bool showTransitionLabels;
  final bool showStateInfo;
  final double simulationProgress;
  final Color highlightColor;
  final GraphAnimationController animationController;
  final AnimationType animationType;
  final bool showGrid;
  final bool show3DEffect;
  final double zoomLevel;
  final Offset panOffset;
  final bool showMinimap;
  final Map<String, Color> customStateColors;
  final Map<String, double> stateWeights;
  final bool enablePhysics;
  final double edgeBundling;
  final bool showStatistics;

  AdvancedAutomatonPainter({
    required this.automaton,
    this.selectedState,
    this.hoveredState,
    this.highlightedStates = const {},
    this.highlightedTransitions = const {},
    this.layoutType = GraphLayoutType.circular,
    this.manualPositions = const {},
    this.nodeSize = 30.0,
    this.theme = GraphTheme.light,
    this.showTransitionLabels = true,
    this.showStateInfo = true,
    this.simulationProgress = 0.0,
    this.highlightColor = Colors.orange,
    GraphAnimationController? animationController,
    this.animationType = AnimationType.none,
    this.showGrid = false,
    this.show3DEffect = false,
    this.zoomLevel = 1.0,
    this.panOffset = Offset.zero,
    this.showMinimap = false,
    this.customStateColors = const {},
    this.stateWeights = const {},
    this.enablePhysics = false,
    this.edgeBundling = 0.0,
    this.showStatistics = false,
  }) : animationController = animationController ?? GraphAnimationController();

  @override
  void paint(Canvas canvas, Size size) {
    // Apply zoom and pan transformations
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel);

    final positions = _calculateAdvancedLayout(size);

    // Draw background effects
    if (showGrid) _drawGrid(canvas, size);
    if (show3DEffect) _drawBackground3D(canvas, size);

    animationController.update();

    // Draw with advanced rendering
    _drawAdvancedTransitions(canvas, positions, size);
    _drawAdvancedStates(canvas, positions);

    if (showStateInfo) {
      _drawStateInformation(canvas, positions);
    }

    if (showStatistics) {
      _drawStatistics(canvas, size);
    }

    canvas.restore();

    if (showMinimap) {
      _drawMinimap(canvas, size, positions);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.textColor.withOpacity(0.1)
      ..strokeWidth = 1.0;

    const gridSize = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawBackground3D(Canvas canvas, Size size) {
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        theme.backgroundColor,
        theme.backgroundColor.withOpacity(0.8),
        theme.backgroundColor.withOpacity(0.6),
      ],
    );

    final paint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  Map<String, Offset> _calculateAdvancedLayout(Size size) {
    final states = _getStates();
    final positions = <String, Offset>{};

    if (states.isEmpty) return positions;

    // Apply manual positions first
    for (final state in states) {
      if (manualPositions.containsKey(state)) {
        positions[state] = manualPositions[state]!;
      }
    }

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    switch (layoutType) {
      case GraphLayoutType.circular:
        _calculateCircularLayout(states, positions, centerX, centerY, size);
        break;
      case GraphLayoutType.grid:
        _calculateGridLayout(states, positions, size);
        break;
      case GraphLayoutType.hierarchical:
        _calculateHierarchicalLayout(states, positions, size);
        break;
      case GraphLayoutType.force:
        _calculateForceLayout(states, positions, size);
        break;
      case GraphLayoutType.layered:
        _calculateLayeredLayout(states, positions, size);
        break;
      case GraphLayoutType.radial:
        _calculateRadialLayout(states, positions, centerX, centerY, size);
        break;
      case GraphLayoutType.organic:
        _calculateOrganicLayout(states, positions, size);
        break;
      case GraphLayoutType.manual:
        // Manual positions are already applied
        break;
    }

    // Apply physics if enabled
    if (enablePhysics) {
      _applyPhysicsSimulation(states, positions, size);
    }

    return positions;
  }

  void _calculateLayeredLayout(
      List<String> states, Map<String, Offset> positions, Size size) {
    final layers = _calculateStateLayers();
    final maxLayer =
        layers.values.isNotEmpty ? layers.values.reduce(math.max) : 0;

    final layerNodes = <int, List<String>>{};
    for (final state in states) {
      final layer = layers[state] ?? 0;
      layerNodes.putIfAbsent(layer, () => []).add(state);
    }

    for (int layer = 0; layer <= maxLayer; layer++) {
      final nodesInLayer = layerNodes[layer] ?? [];
      if (nodesInLayer.isEmpty) continue;

      final layerY = size.height / (maxLayer + 2) * (layer + 1);

      for (int i = 0; i < nodesInLayer.length; i++) {
        if (!positions.containsKey(nodesInLayer[i])) {
          final layerX = size.width / (nodesInLayer.length + 1) * (i + 1);
          positions[nodesInLayer[i]] = Offset(layerX, layerY);
        }
      }
    }
  }

  void _calculateRadialLayout(
      List<String> states,
      Map<String, Offset> positions,
      double centerX,
      double centerY,
      Size size) {
    final startState = _getStartState();
    final distances = _calculateDistancesFromStart(startState);
    final maxDistance =
        distances.values.isNotEmpty ? distances.values.reduce(math.max) : 1;

    final rings = <int, List<String>>{};
    for (final state in states) {
      final distance = distances[state] ?? maxDistance;
      rings.putIfAbsent(distance, () => []).add(state);
    }

    for (final distance in rings.keys) {
      final nodesInRing = rings[distance]!;
      final radius =
          (distance + 1) * math.min(centerX, centerY) / (maxDistance + 2) * 0.8;

      for (int i = 0; i < nodesInRing.length; i++) {
        if (!positions.containsKey(nodesInRing[i])) {
          final angle = (2 * math.pi * i) / nodesInRing.length;
          final x = centerX + radius * math.cos(angle);
          final y = centerY + radius * math.sin(angle);
          positions[nodesInRing[i]] = Offset(x, y);
        }
      }
    }
  }

  void _calculateOrganicLayout(
      List<String> states, Map<String, Offset> positions, Size size) {
    final random = math.Random(42);
    final connections = _getConnections();

    // Initialize positions in organic clusters
    final clusterCenters = <Offset>[];
    final numClusters = math.max(1, states.length ~/ 5);

    for (int i = 0; i < numClusters; i++) {
      clusterCenters.add(Offset(
        size.width * (0.2 + 0.6 * random.nextDouble()),
        size.height * (0.2 + 0.6 * random.nextDouble()),
      ));
    }

    for (int i = 0; i < states.length; i++) {
      if (!positions.containsKey(states[i])) {
        final clusterIndex = i % numClusters;
        final center = clusterCenters[clusterIndex];
        final angle = random.nextDouble() * 2 * math.pi;
        final distance = random.nextDouble() * 100;

        positions[states[i]] = Offset(
          center.dx + distance * math.cos(angle),
          center.dy + distance * math.sin(angle),
        );
      }
    }

    // Apply organic force simulation
    for (int iteration = 0; iteration < 100; iteration++) {
      final forces = <String, Offset>{};

      // Initialize forces
      for (final state in states) {
        forces[state] = Offset.zero;
      }

      // Organic clustering forces
      for (int i = 0; i < states.length; i++) {
        for (int j = i + 1; j < states.length; j++) {
          final state1 = states[i];
          final state2 = states[j];
          final pos1 = positions[state1]!;
          final pos2 = positions[state2]!;
          final distance = (pos1 - pos2).distance;

          if (distance > 0) {
            final repulsion = (3000 / (distance * distance)) *
                (1 + 0.5 * math.sin(iteration * 0.1));
            final direction = (pos1 - pos2) / distance;

            forces[state1] = forces[state1]! + direction * repulsion;
            forces[state2] = forces[state2]! - direction * repulsion;
          }
        }
      }

      for (final connection in connections) {
        final state1 = connection['from'] as String;
        final state2 = connection['to'] as String;
        final pos1 = positions[state1]!;
        final pos2 = positions[state2]!;
        final distance = (pos1 - pos2).distance;

        if (distance > 0) {
          final attraction =
              distance * 0.015 * (1 + 0.3 * math.cos(iteration * 0.05));
          final direction = (pos2 - pos1) / distance;

          forces[state1] = forces[state1]! + direction * attraction;
          forces[state2] = forces[state2]! - direction * attraction;
        }
      }

      // Apply forces with organic damping
      for (final state in states) {
        if (!manualPositions.containsKey(state)) {
          final force = forces[state]!;
          final dampingFactor = 0.1 * (1 - iteration / 100);
          final newPos = positions[state]! + force * dampingFactor;

          positions[state] = Offset(
            newPos.dx.clamp(nodeSize, size.width - nodeSize),
            newPos.dy.clamp(nodeSize, size.height - nodeSize),
          );
        }
      }
    }
  }

  void _applyPhysicsSimulation(
      List<String> states, Map<String, Offset> positions, Size size) {
    final velocities = <String, Offset>{};
    final masses = <String, double>{};

    // Initialize physics properties
    for (final state in states) {
      velocities[state] = Offset.zero;
      masses[state] = stateWeights[state] ?? 1.0;
    }

    for (int step = 0; step < 20; step++) {
      final forces = <String, Offset>{};

      // Initialize forces
      for (final state in states) {
        forces[state] = Offset.zero;
      }

      // Spring forces between connected nodes
      final connections = _getConnections();
      for (final connection in connections) {
        final state1 = connection['from'] as String;
        final state2 = connection['to'] as String;
        final pos1 = positions[state1]!;
        final pos2 = positions[state2]!;
        final distance = (pos1 - pos2).distance;
        const idealDistance = 100.0;

        if (distance > 0) {
          final springForce = (distance - idealDistance) * 0.02;
          final direction = (pos2 - pos1) / distance;

          forces[state1] = forces[state1]! + direction * springForce;
          forces[state2] = forces[state2]! - direction * springForce;
        }
      }

      // Collision detection and response
      for (int i = 0; i < states.length; i++) {
        for (int j = i + 1; j < states.length; j++) {
          final state1 = states[i];
          final state2 = states[j];
          final pos1 = positions[state1]!;
          final pos2 = positions[state2]!;
          final distance = (pos1 - pos2).distance;
          final minDistance = nodeSize * 2.5;

          if (distance < minDistance && distance > 0) {
            final overlap = minDistance - distance;
            final direction = (pos1 - pos2) / distance;
            final force = direction * overlap * 0.5;

            forces[state1] = forces[state1]! + force;
            forces[state2] = forces[state2]! - force;
          }
        }
      }

      for (final state in states) {
        if (!manualPositions.containsKey(state)) {
          final force = forces[state]!;
          final mass = masses[state]!;
          final acceleration = force / mass;

          velocities[state] = velocities[state]! + acceleration;
          velocities[state] = velocities[state]! * 0.95; // Damping

          final newPos = positions[state]! + velocities[state]!;
          positions[state] = Offset(
            newPos.dx.clamp(nodeSize, size.width - nodeSize),
            newPos.dy.clamp(nodeSize, size.height - nodeSize),
          );
        }
      }
    }
  }

  Map<String, int> _calculateStateLayers() {
    final layers = <String, int>{};
    final startState = _getStartState();
    final queue = <String>[startState];
    layers[startState] = 0;

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentLayer = layers[current] ?? 0;
      final transitions = _getTransitionsFromState(current);

      for (final transition in transitions) {
        final target = transition['to'] as String;
        if (!layers.containsKey(target)) {
          layers[target] = currentLayer + 1;
          queue.add(target);
        }
      }
    }

    return layers;
  }

  Map<String, int> _calculateDistancesFromStart(String startState) {
    final distances = <String, int>{};
    final queue = <String>[startState];
    distances[startState] = 0;

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentDistance = distances[current] ?? 0;
      final transitions = _getTransitionsFromState(current);

      for (final transition in transitions) {
        final target = transition['to'] as String;
        if (!distances.containsKey(target)) {
          distances[target] = currentDistance + 1;
          queue.add(target);
        }
      }
    }

    return distances;
  }

  void _drawAdvancedStates(Canvas canvas, Map<String, Offset> positions) {
    final states = _getStates();
    final startState = _getStartState();
    final finalStates = _getFinalStates();

    for (final state in states) {
      final position = positions[state];
      if (position == null) continue;

      final isStart = state == startState;
      final isFinal = finalStates.contains(state);
      final isSelected = state == selectedState;
      final isHovered = state == hoveredState;
      final isHighlighted = highlightedStates.contains(state);

      final animationValue = animationController.getStateAnimation(state);

      // Draw state with advanced styling and animations
      _drawAdvancedState(canvas, position, state,
          isStart: isStart,
          isFinal: isFinal,
          isSelected: isSelected,
          isHovered: isHovered,
          isHighlighted: isHighlighted,
          animationValue: animationValue);
    }
  }

  void _drawAdvancedState(
    Canvas canvas,
    Offset position,
    String stateName, {
    bool isStart = false,
    bool isFinal = false,
    bool isSelected = false,
    bool isHovered = false,
    bool isHighlighted = false,
    double animationValue = 1.0,
  }) {
    // Apply animation transformations
    final animatedNodeSize = nodeSize *
        (animationType == AnimationType.scale
            ? (0.5 + 0.5 * animationValue)
            : 1.0);

    final animatedPosition = animationType == AnimationType.slide
        ? Offset(position.dx, position.dy - 20 * (1 - animationValue))
        : position;

    final opacity = animationType == AnimationType.fade ? animationValue : 1.0;

    final bounceScale = animationType == AnimationType.bounce
        ? 1.0 + 0.3 * math.sin(animationController.currentFrame * 0.3)
        : 1.0;

    final pulseScale = animationType == AnimationType.pulse
        ? 1.0 + 0.2 * math.sin(animationController.currentFrame * 0.2)
        : 1.0;

    final rotationAngle = animationType == AnimationType.rotate
        ? animationController.currentFrame * 0.1
        : 0.0;

    final finalNodeSize = animatedNodeSize * bounceScale * pulseScale;

    // Save canvas state for transformations
    canvas.save();
    canvas.translate(animatedPosition.dx, animatedPosition.dy);
    canvas.rotate(rotationAngle);

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Determine colors with custom state colors
    Color fillColor = customStateColors[stateName] ?? theme.backgroundColor;
    Color strokeColor = theme.primaryColor;

    if (isFinal) {
      fillColor = customStateColors[stateName] ?? Colors.green.shade100;
      strokeColor = Colors.green.shade600;
    } else {
      fillColor = customStateColors[stateName] ?? Colors.blue.shade50;
      strokeColor = Colors.blue.shade400;
    }

    if (isHighlighted) {
      fillColor = highlightColor.withOpacity(0.3);
      strokeColor = highlightColor;
    }

    if (isSelected) {
      strokeColor = Colors.orange.shade600;
      strokePaint.strokeWidth = 3.0;
    }

    if (isHovered) {
      fillColor = fillColor.withOpacity(0.8);
    }

    // Apply opacity for fade animation
    fillColor = fillColor.withOpacity(fillColor.opacity * opacity);
    strokeColor = strokeColor.withOpacity(strokeColor.opacity * opacity);

    // Draw 3D effect shadow if enabled
    if (show3DEffect) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3 * opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(3, 3), finalNodeSize, shadowPaint);
    }

    // Draw glow effect for highlighted states
    if (isHighlighted || isSelected) {
      final glowPaint = Paint()
        ..color = (isSelected ? Colors.orange : highlightColor)
            .withOpacity(0.3 * opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, finalNodeSize + 8, glowPaint);
    }

    // Draw main circle with gradient
    if (theme == GraphTheme.neon || theme == GraphTheme.colorful) {
      final gradient = RadialGradient(
        colors: [fillColor, fillColor.withOpacity(0.7)],
      );
      paint.shader = gradient.createShader(
          Rect.fromCircle(center: Offset.zero, radius: finalNodeSize));
    } else {
      paint.color = fillColor;
    }

    canvas.drawCircle(Offset.zero, finalNodeSize, paint);

    // Draw border with weight-based thickness
    final weight = stateWeights[stateName] ?? 1.0;
    strokePaint.strokeWidth = 2.0 * weight;
    strokePaint.color = strokeColor;

    if (isStart) {
      strokePaint.strokeWidth = 4.0 * weight;
    }
    canvas.drawCircle(Offset.zero, finalNodeSize, strokePaint);

    // Draw inner circle for final states
    if (isFinal) {
      strokePaint.strokeWidth = 2.0;
      canvas.drawCircle(Offset.zero, finalNodeSize - 6, strokePaint);
    }

    // Draw state label with enhanced typography
    final textStyle = TextStyle(
      color: theme.textColor.withOpacity(opacity),
      fontSize: math.min(14, finalNodeSize / 2),
      fontWeight: FontWeight.bold,
      shadows: theme == GraphTheme.neon
          ? [
              Shadow(
                color: theme.primaryColor.withOpacity(0.8),
                offset: const Offset(0, 0),
                blurRadius: 4,
              ),
            ]
          : [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
    );

    final textPainter = TextPainter(
      text: TextSpan(text: stateName, style: textStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(
          -textPainter.width / 2,
          -textPainter.height / 2,
        ));

    canvas.restore();
  }

  void _drawAdvancedTransitions(
      Canvas canvas, Map<String, Offset> positions, Size size) {
    final paint = Paint()
      ..color = theme.textColor.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final transitions = _getTransitions();
    final groupedTransitions = <String, List<String>>{};

    // Group transitions by from/to pairs
    for (final t in transitions) {
      final key = '${t["from"]}->${t["to"]}';
      groupedTransitions.putIfAbsent(key, () => []).add(t['symbol'] as String);
    }

    groupedTransitions.forEach((key, symbols) {
      final parts = key.split('->');
      final fromState = parts[0];
      final toState = parts[1];
      final fromPos = positions[fromState];
      final toPos = positions[toState];

      if (fromPos == null || toPos == null) return;

      final isHighlighted = highlightedTransitions.contains(key);
      final label = symbols.join(',');
      final animationValue = animationController.getTransitionAnimation(key);

      // Apply transition-specific styling
      if (isHighlighted) {
        paint.color = highlightColor;
        paint.strokeWidth = 3.0;
      } else {
        paint.color = theme.textColor.withOpacity(0.7 * animationValue);
        paint.strokeWidth = 2.0;
      }

      if (fromState == toState) {
        _drawAdvancedSelfLoop(canvas, paint, fromPos, label, animationValue);
      } else {
        _drawAdvancedArrow(
            canvas, paint, fromPos, toPos, label, animationValue);
      }
    });
  }

  void _drawAdvancedArrow(Canvas canvas, Paint paint, Offset from, Offset to,
      String label, double animationValue) {
    final direction = (to - from).normalize();
    final startPoint = from + direction * (nodeSize + 2);
    final endPoint = to - direction * (nodeSize + 2);

    // Apply edge bundling if enabled
    final controlPoint = edgeBundling > 0
        ? _calculateBundledControlPoint(startPoint, endPoint, edgeBundling)
        : _calculateControlPoint(startPoint, endPoint);

    // Create animated path
    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);

    if (animationValue < 1.0) {
      // Animate path drawing
      final animatedEnd = Offset.lerp(startPoint, endPoint, animationValue)!;
      final animatedControl =
          Offset.lerp(startPoint, controlPoint, animationValue)!;
      path.quadraticBezierTo(animatedControl.dx, animatedControl.dy,
          animatedEnd.dx, animatedEnd.dy);
    } else {
      path.quadraticBezierTo(
          controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    }

    // Draw path with enhanced effects
    if (theme == GraphTheme.neon) {
      // Neon glow effect
      final glowPaint = Paint()
        ..color = paint.color.withOpacity(0.3)
        ..strokeWidth = paint.strokeWidth * 3
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(path, glowPaint);
    }

    // Main path with gradient
    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        startPoint,
        endPoint,
        [paint.color.withOpacity(0.3), paint.color],
      )
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, gradientPaint);

    // Draw arrowhead with animation
    if (animationValue >= 0.8) {
      final arrowEndPoint = animationValue < 1.0
          ? Offset.lerp(startPoint, endPoint, animationValue)!
          : endPoint;
      _drawArrowhead(canvas, paint, arrowEndPoint, direction);
    }

    // Draw label with enhanced styling
    if (showTransitionLabels && label.isNotEmpty && animationValue > 0.5) {
      _drawTransitionLabel(canvas, controlPoint, label, animationValue);
    }
  }

  void _drawAdvancedSelfLoop(Canvas canvas, Paint paint, Offset center,
      String label, double animationValue) {
    final loopRadius = nodeSize * 0.8;
    final loopCenter = Offset(center.dx, center.dy - nodeSize - loopRadius);

    final rect = Rect.fromCircle(center: loopCenter, radius: loopRadius);
    final path = Path();
    final sweepAngle = math.pi * 1.6 * animationValue;
    path.addArc(rect, math.pi * 0.2, sweepAngle);

    if (theme == GraphTheme.neon) {
      final glowPaint = Paint()
        ..color = paint.color.withOpacity(0.3)
        ..strokeWidth = paint.strokeWidth * 3
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(path, glowPaint);
    }

    final gradientPaint = Paint()
      ..shader = ui.Gradient.sweep(
        loopCenter,
        [
          paint.color.withOpacity(0.3),
          paint.color,
          paint.color.withOpacity(0.3)
        ],
      )
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, gradientPaint);

    // Draw arrowhead
    if (animationValue >= 0.8) {
      final arrowAngle = math.pi * 0.2;
      final arrowPos = Offset(
        loopCenter.dx + loopRadius * math.cos(arrowAngle),
        loopCenter.dy + loopRadius * math.sin(arrowAngle),
      );
      final arrowDirection =
          Offset(-math.sin(arrowAngle), math.cos(arrowAngle));
      _drawArrowhead(canvas, paint, arrowPos, arrowDirection);
    }

    // Draw label
    if (showTransitionLabels && label.isNotEmpty && animationValue > 0.5) {
      _drawTransitionLabel(
          canvas,
          Offset(center.dx, center.dy - nodeSize - loopRadius * 2 - 10),
          label,
          animationValue);
    }
  }

  void _drawArrowhead(
      Canvas canvas, Paint paint, Offset position, Offset direction) {
    const arrowSize = 12.0;
    final arrowPath = Path();
    final angle = math.atan2(direction.dy, direction.dx);

    arrowPath.moveTo(position.dx, position.dy);
    arrowPath.lineTo(
      position.dx - arrowSize * math.cos(angle - 0.4),
      position.dy - arrowSize * math.sin(angle - 0.4),
    );
    arrowPath.lineTo(
      position.dx - arrowSize * 0.7 * math.cos(angle),
      position.dy - arrowSize * 0.7 * math.sin(angle),
    );
    arrowPath.lineTo(
      position.dx - arrowSize * math.cos(angle + 0.4),
      position.dy - arrowSize * math.sin(angle + 0.4),
    );
    arrowPath.close();

    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    if (theme == GraphTheme.neon) {
      arrowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    }

    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawTransitionLabel(Canvas canvas, Offset position, String label,
      [double opacity = 1.0]) {
    final textStyle = TextStyle(
      color: Colors.red.shade700.withOpacity(opacity),
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    if (theme == GraphTheme.neon) {
      textStyle.copyWith(
        shadows: [
          Shadow(
            color: Colors.red.withOpacity(0.8),
            offset: const Offset(0, 0),
            blurRadius: 3,
          ),
        ],
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw enhanced background
    final backgroundPaint = Paint()
      ..color = theme.backgroundColor.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.fill;

    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: textPainter.width + 8,
        height: textPainter.height + 4,
      ),
      const Radius.circular(6),
    );

    // Draw shadow for depth
    if (show3DEffect) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2 * opacity)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(backgroundRect.shift(const Offset(2, 2)), shadowPaint);
    }

    canvas.drawRRect(backgroundRect, backgroundPaint);

    // Draw border with theme colors
    final borderPaint = Paint()
      ..color = theme.primaryColor.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(backgroundRect, borderPaint);

    // Draw text
    textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        ));
  }

  void _drawStateInformation(Canvas canvas, Map<String, Offset> positions) {
    if (!showStateInfo) return;

    final states = _getStates();
    for (final state in states) {
      final position = positions[state];
      if (position == null) continue;

      // Draw state degree information
      final inDegree = _getInDegree(state);
      final outDegree = _getOutDegree(state);

      if (inDegree > 0 || outDegree > 0) {
        final infoText = 'In: $inDegree, Out: $outDegree';
        final textPainter = TextPainter(
          text: TextSpan(
            text: infoText,
            style: TextStyle(
              color: theme.textColor.withOpacity(0.6),
              fontSize: 9,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
            canvas,
            Offset(
              position.dx - textPainter.width / 2,
              position.dy + nodeSize + 5,
            ));
      }
    }
  }

  void _drawStatistics(Canvas canvas, Size size) {
    final stats = _calculateGraphStatistics();
    final statisticsText = [
      'States: ${stats['states']}',
      'Transitions: ${stats['transitions']}',
      'Density: ${stats['density'].toStringAsFixed(2)}',
      'Max Degree: ${stats['maxDegree']}',
    ].join(' | ');

    final textPainter = TextPainter(
      text: TextSpan(
        text: statisticsText,
        style: TextStyle(
          color: theme.textColor.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw background
    final backgroundRect =
        Rect.fromLTWH(10, 10, textPainter.width + 20, textPainter.height + 10);
    final backgroundPaint = Paint()
      ..color = theme.backgroundColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(8)),
      backgroundPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = theme.primaryColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(8)),
      borderPaint,
    );

    textPainter.paint(canvas, const Offset(20, 15));
  }

  void _drawMinimap(Canvas canvas, Size size, Map<String, Offset> positions) {
    const minimapSize = Size(150, 100);
    final minimapRect = Rect.fromLTWH(
      size.width - minimapSize.width - 20,
      20,
      minimapSize.width,
      minimapSize.height,
    );

    // Draw minimap background
    final backgroundPaint = Paint()
      ..color = theme.backgroundColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(minimapRect, const Radius.circular(8)),
      backgroundPaint,
    );

    // Draw minimap border
    final borderPaint = Paint()
      ..color = theme.primaryColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(minimapRect, const Radius.circular(8)),
      borderPaint,
    );

    // Calculate scale for minimap
    if (positions.isEmpty) return;

    final minX = positions.values.map((p) => p.dx).reduce(math.min);
    final maxX = positions.values.map((p) => p.dx).reduce(math.max);
    final minY = positions.values.map((p) => p.dy).reduce(math.min);
    final maxY = positions.values.map((p) => p.dy).reduce(math.max);

    final scaleX = (minimapSize.width - 20) / (maxX - minX);
    final scaleY = (minimapSize.height - 20) / (maxY - minY);
    final scale = math.min(scaleX, scaleY);

    // Draw states in minimap
    final minimapPaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.fill;

    for (final entry in positions.entries) {
      final scaledX = (entry.value.dx - minX) * scale + minimapRect.left + 10;
      final scaledY = (entry.value.dy - minY) * scale + minimapRect.top + 10;
      canvas.drawCircle(Offset(scaledX, scaledY), 2, minimapPaint);
    }

    // Draw current view indicator
    final viewIndicatorPaint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final viewRect = Rect.fromLTWH(
      minimapRect.left + 10,
      minimapRect.top + 10,
      minimapSize.width / zoomLevel,
      minimapSize.height / zoomLevel,
    );

    canvas.drawRect(viewRect, viewIndicatorPaint);
  }

  Offset _calculateControlPoint(Offset start, Offset end) {
    final midPoint = (start + end) / 2;
    final perpendicular =
        Offset(-(end.dy - start.dy), end.dx - start.dx).normalize();
    return midPoint + perpendicular * 30;
  }

  Offset _calculateBundledControlPoint(
      Offset start, Offset end, double bundling) {
    final midPoint = (start + end) / 2;
    final perpendicular =
        Offset(-(end.dy - start.dy), end.dx - start.dx).normalize();
    final bundlingOffset = perpendicular * (30 + bundling * 20);
    return midPoint + bundlingOffset;
  }

  Map<String, dynamic> _calculateGraphStatistics() {
    final states = _getStates();
    final transitions = _getTransitions();
    final maxPossibleEdges = states.length * (states.length - 1);
    final density =
        maxPossibleEdges > 0 ? transitions.length / maxPossibleEdges : 0.0;

    final degrees = <String, int>{};
    for (final state in states) {
      degrees[state] = _getInDegree(state) + _getOutDegree(state);
    }

    final maxDegree =
        degrees.values.isNotEmpty ? degrees.values.reduce(math.max) : 0;

    return {
      'states': states.length,
      'transitions': transitions.length,
      'density': density,
      'maxDegree': maxDegree,
    };
  }

  int _getInDegree(String state) {
    return _getTransitions().where((t) => t['to'] == state).length;
  }

  int _getOutDegree(String state) {
    return _getTransitions().where((t) => t['from'] == state).length;
  }

  // Keep existing helper methods
  void _calculateCircularLayout(
      List<String> states,
      Map<String, Offset> positions,
      double centerX,
      double centerY,
      Size size) {
    final radius = math.min(centerX, centerY) * 0.6;

    for (int i = 0; i < states.length; i++) {
      if (!positions.containsKey(states[i])) {
        final angle = (2 * math.pi * i) / states.length - math.pi / 2;
        final x = centerX + radius * math.cos(angle);
        final y = centerY + radius * math.sin(angle);
        positions[states[i]] = Offset(x, y);
      }
    }
  }

  void _calculateGridLayout(
      List<String> states, Map<String, Offset> positions, Size size) {
    final cols = math.sqrt(states.length).ceil();
    final rows = (states.length / cols).ceil();
    final cellWidth = size.width / (cols + 1);
    final cellHeight = size.height / (rows + 1);

    for (int i = 0; i < states.length; i++) {
      if (!positions.containsKey(states[i])) {
        final row = i ~/ cols;
        final col = i % cols;
        final x = cellWidth * (col + 1);
        final y = cellHeight * (row + 1);
        positions[states[i]] = Offset(x, y);
      }
    }
  }

  void _calculateHierarchicalLayout(
      List<String> states, Map<String, Offset> positions, Size size) {
    final startState = _getStartState();
    final levels = <String, int>{};
    final queue = <String>[startState];
    levels[startState] = 0;
    int maxLevel = 0;

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentLevel = levels[current] ?? 0;
      final transitions = _getTransitionsFromState(current);

      for (final transition in transitions) {
        final target = transition['to'] as String;
        if (!levels.containsKey(target)) {
          levels[target] = currentLevel + 1;
          maxLevel = math.max(maxLevel, currentLevel + 1);
          queue.add(target);
        }
      }
    }

    final levelCounts = <int, int>{};
    for (final state in states) {
      final level = levels[state] ?? maxLevel;
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;
    }

    final levelPositions = <int, int>{};
    for (final state in states) {
      if (!positions.containsKey(state)) {
        final level = levels[state] ?? maxLevel;
        final levelCount = levelCounts[level] ?? 1;
        final positionInLevel = levelPositions[level] ?? 0;
        levelPositions[level] = positionInLevel + 1;

        final x = size.width / (levelCount + 1) * (positionInLevel + 1);
        final y = size.height / (maxLevel + 2) * (level + 1);
        positions[state] = Offset(x, y);
      }
    }
  }

  void _calculateForceLayout(
      List<String> states, Map<String, Offset> positions, Size size) {
    final forces = <String, Offset>{};
    final connections = _getConnections();
    final random = math.Random();

    for (final state in states) {
      if (!positions.containsKey(state)) {
        positions[state] = Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        );
      }
      forces[state] = Offset.zero;
    }

    for (int iteration = 0; iteration < 50; iteration++) {
      for (final state in states) {
        forces[state] = Offset.zero;
      }

      for (int i = 0; i < states.length; i++) {
        for (int j = i + 1; j < states.length; j++) {
          final state1 = states[i];
          final state2 = states[j];
          final pos1 = positions[state1]!;
          final pos2 = positions[state2]!;

          final distance = (pos1 - pos2).distance;
          if (distance > 0) {
            final repulsion = 5000 / (distance * distance);
            final direction = (pos1 - pos2) / distance;

            forces[state1] = forces[state1]! + direction * repulsion;
            forces[state2] = forces[state2]! - direction * repulsion;
          }
        }
      }

      for (final connection in connections) {
        final state1 = connection['from'] as String;
        final state2 = connection['to'] as String;
        final pos1 = positions[state1]!;
        final pos2 = positions[state2]!;

        final distance = (pos1 - pos2).distance;
        if (distance > 0) {
          final attraction = distance * 0.01;
          final direction = (pos2 - pos1) / distance;

          forces[state1] = forces[state1]! + direction * attraction;
          forces[state2] = forces[state2]! - direction * attraction;
        }
      }

      for (final state in states) {
        if (!manualPositions.containsKey(state)) {
          final force = forces[state]!;
          final newPos = positions[state]! + force * 0.1;

          positions[state] = Offset(
            newPos.dx.clamp(nodeSize, size.width - nodeSize),
            newPos.dy.clamp(nodeSize, size.height - nodeSize),
          );
        }
      }
    }
  }

  // Keep all existing helper methods for data extraction
  List<String> _getStates() {
    if (automaton is NFA) {
      return (automaton as NFA).states.toList()..sort();
    } else if (automaton is DFA) {
      final dfa = automaton as DFA;
      return dfa.states.map((s) => dfa.getStateName(s)).toList()..sort();
    }
    return [];
  }

  String _getStartState() {
    if (automaton is NFA) {
      return (automaton as NFA).startState;
    } else if (automaton is DFA) {
      final dfa = automaton as DFA;
      return dfa.startState != null ? dfa.getStateName(dfa.startState!) : '';
    }
    return '';
  }

  Set<String> _getFinalStates() {
    if (automaton is NFA) {
      return (automaton as NFA).finalStates;
    } else if (automaton is DFA) {
      final dfa = automaton as DFA;
      return dfa.finalStates.map((s) => dfa.getStateName(s)).toSet();
    }
    return {};
  }

  List<Map<String, dynamic>> _getTransitions() {
    final transitions = <Map<String, dynamic>>[];

    if (automaton is NFA) {
      final nfa = automaton as NFA;
      for (final fromState in nfa.transitions.keys) {
        for (final symbol in nfa.transitions[fromState]!.keys) {
          final toStates = nfa.transitions[fromState]![symbol]!;
          for (final toState in toStates) {
            transitions.add({
              'from': fromState,
              'to': toState,
              'symbol': symbol,
            });
          }
        }
      }
    } else if (automaton is DFA) {
      final dfa = automaton as DFA;
      final dfaTransitions = dfa.transitions;
      for (final fromStateSet in dfaTransitions.keys) {
        final fromStateName = dfa.getStateName(fromStateSet);
        final symbolMap = dfaTransitions[fromStateSet]!;
        for (final symbol in symbolMap.keys) {
          final toStateSet = symbolMap[symbol]!;
          final toStateName = dfa.getStateName(toStateSet);
          transitions.add({
            'from': fromStateName,
            'to': toStateName,
            'symbol': symbol,
          });
        }
      }
    }

    return transitions;
  }

  List<Map<String, String>> _getConnections() {
    return _getTransitions()
        .map((t) => {'from': t['from'] as String, 'to': t['to'] as String})
        .toList();
  }

  List<Map<String, dynamic>> _getTransitionsFromState(String state) {
    return _getTransitions().where((t) => t['from'] == state).toList();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Enhanced Extension for vector operations
extension OffsetExtensions on Offset {
  Offset normalize() {
    final length = distance;
    if (length == 0) return Offset.zero;
    return this / length;
  }

  Offset rotate(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(dx * cos - dy * sin, dx * sin + dy * cos);
  }

  double get length => math.sqrt(dx * dx + dy * dy);
}
