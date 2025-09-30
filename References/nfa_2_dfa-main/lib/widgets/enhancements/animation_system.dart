import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:async';

/// Data model for the entire state diagram.
class StateDiagramData {
  final List<StateNode> nodes;
  final List<StateEdge> edges;

  StateDiagramData({required this.nodes, required this.edges});
}

/// Data model for a single state (node) in the diagram.
class StateNode {
  final String id;
  final String label;
  final bool isStart;
  final bool isFinal;

  const StateNode({
    required this.id,
    required this.label,
    this.isStart = false,
    this.isFinal = false,
  });
}

/// Data model for a transition (edge) between states.
class StateEdge {
  final String id;
  final String fromId;
  final String toId;
  final String? label;

  const StateEdge({
    required this.id,
    required this.fromId,
    required this.toId,
    this.label,
  });
}

/// Theme data for styling the diagram.
class DiagramTheme {
  final DiagramColorScheme colorScheme;
  DiagramTheme({required this.colorScheme});
}

/// Color scheme for the diagram theme.
class DiagramColorScheme {
  final Color edgeDefault;
  final Color textSecondary;
  final Color textPrimary;
  final Color stateStart;
  final Color stateFinal;
  final Color stateDefault;

  DiagramColorScheme({
    required this.edgeDefault,
    required this.textSecondary,
    required this.textPrimary,
    required this.stateStart,
    required this.stateFinal,
    required this.stateDefault,
  });
}

enum AnimationState { stopped, playing, paused, error }

enum NodeEntranceType {
  fadeScale,
  slideFromLeft,
  slideFromTop,
  bounceIn,
  rotateIn,
}

enum NodeExitType { fadeScale, slideToRight, slideToBottom, implode }

enum PathAnimationEventType {
  stepStarted,
  stepCompleted,
  particleMoving,
  particlePosition,
  nodeActivated,
  nodePulse,
  completed,
}

enum NodeAnimationEventType { entrance, exit }

enum TimelineEventType {
  nodeEntrance,
  nodeExit,
  pathAnimation,
  rippleEffect,
  transitionHighlight,
}

class PathStep {
  final String nodeId;
  final String? edgeId;
  final String? symbol;
  final Duration timestamp;

  PathStep({
    required this.nodeId,
    this.edgeId,
    this.symbol,
    required this.timestamp,
  });
}

class PathAnimationEvent {
  final PathAnimationEventType type;
  final PathStep step;
  final double progress;
  final Map<String, dynamic>? data;

  PathAnimationEvent({
    required this.type,
    required this.step,
    required this.progress,
    this.data,
  });
}

class NodeAnimationEvent {
  final String nodeId;
  final NodeAnimationEventType type;
  final NodeAnimationProperties properties;
  final double progress;

  NodeAnimationEvent({
    required this.nodeId,
    required this.type,
    required this.properties,
    required this.progress,
  });
}

class NodeAnimationProperties {
  final double opacity;
  final double scale;
  final double rotation;
  final Offset offset;

  NodeAnimationProperties({
    this.opacity = 1.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offset = Offset.zero,
  });
}

class RippleState {
  final Offset position;
  final double radius;
  final double opacity;
  final Color color;

  RippleState({
    required this.position,
    required this.radius,
    required this.opacity,
    required this.color,
  });
}

class TransitionHighlightState {
  final String edgeId;
  final Offset from;
  final Offset to;
  final Color color;
  final double progress;
  final double thickness;

  TransitionHighlightState({
    required this.edgeId,
    required this.from,
    required this.to,
    required this.color,
    required this.progress,
    required this.thickness,
  });
}

class ParticleState {
  final Offset position;
  final String? symbol;
  final double opacity;

  ParticleState({required this.position, this.symbol, required this.opacity});
}

class TimelineEvent {
  final String id;
  final String name;
  final TimelineEventType type;
  final Duration timestamp;
  final Duration duration;
  final dynamic data;

  TimelineEvent({
    required this.id,
    required this.name,
    required this.type,
    required this.timestamp,
    required this.duration,
    this.data,
  });
}

class TimelineState {
  final Duration currentTime;
  final Duration totalDuration;
  final bool isPlaying;
  final double progress;

  TimelineState({
    required this.currentTime,
    required this.totalDuration,
    required this.isPlaying,
    required this.progress,
  });
}

class PerformanceFrame {
  final DateTime timestamp;
  final double frameTime;
  final double fps;
  final bool isDropped;

  PerformanceFrame({
    required this.timestamp,
    required this.frameTime,
    required this.fps,
    required this.isDropped,
  });
}

class AnimationSession {
  final DateTime startTime;
  final DateTime endTime;
  final int frameCount;
  final double averageFrameTime;
  final int droppedFrames;
  final double fps;

  AnimationSession({
    required this.startTime,
    required this.endTime,
    required this.frameCount,
    required this.averageFrameTime,
    required this.droppedFrames,
    required this.fps,
  });

  Duration get duration => endTime.difference(startTime);
}

class MetricsReport {
  final int totalSessions;
  final double averageFps;
  final int totalDroppedFrames;
  final double performanceScore;
  final List<String> recommendations;

  MetricsReport({
    required this.totalSessions,
    required this.averageFps,
    required this.totalDroppedFrames,
    required this.performanceScore,
    required this.recommendations,
  });
}

/// سیستم اصلی انیمیشن دیاگرام حالت
class AnimationSystem extends ChangeNotifier {
  static final AnimationSystem _instance = AnimationSystem._internal();
  factory AnimationSystem() => _instance;
  AnimationSystem._internal();

  // مدیران اصلی
  final PathAnimationManager _pathManager = PathAnimationManager();
  final NodeAnimationManager _nodeManager = NodeAnimationManager();
  final RippleAnimationManager _rippleManager = RippleAnimationManager();
  final TransitionHighlighter _transitionHighlighter = TransitionHighlighter();
  final AnimationTimeline _timeline = AnimationTimeline();
  final AnimationMetrics _metrics = AnimationMetrics();

  // وضعیت سیستم
  AnimationState _state = AnimationState.stopped;
  double _speed = 1.0;
  bool _loopEnabled = false;
  bool _autoPlay = false;

  // تنظیمات عمومی
  Duration _defaultDuration = const Duration(milliseconds: 800);
  Curve _defaultCurve = Curves.easeInOutCubic;
  bool _enablePerformanceMetrics = true;

  // Getters
  PathAnimationManager get pathManager => _pathManager;
  NodeAnimationManager get nodeManager => _nodeManager;
  RippleAnimationManager get rippleManager => _rippleManager;
  TransitionHighlighter get transitionHighlighter => _transitionHighlighter;
  AnimationTimeline get timeline => _timeline;
  AnimationMetrics get metrics => _metrics;
  AnimationState get state => _state;
  double get speed => _speed;
  bool get loopEnabled => _loopEnabled;
  bool get autoPlay => _autoPlay;

  /// تنظیم کردن سیستم
  void configure({
    Duration? defaultDuration,
    Curve? defaultCurve,
    double? speed,
    bool? loopEnabled,
    bool? autoPlay,
    bool? enablePerformanceMetrics,
  }) {
    _defaultDuration = defaultDuration ?? _defaultDuration;
    _defaultCurve = defaultCurve ?? _defaultCurve;
    _speed = speed ?? _speed;
    _loopEnabled = loopEnabled ?? _loopEnabled;
    _autoPlay = autoPlay ?? _autoPlay;
    _enablePerformanceMetrics =
        enablePerformanceMetrics ?? _enablePerformanceMetrics;

    _pathManager.configure(
      defaultDuration: _defaultDuration,
      defaultCurve: _defaultCurve,
      speed: _speed,
    );
    _nodeManager.configure(
      defaultDuration: _defaultDuration,
      defaultCurve: _defaultCurve,
    );
    _rippleManager.configure(
      defaultDuration: _defaultDuration,
      defaultCurve: _defaultCurve,
    );

    notifyListeners();
  }

  /// شروع انیمیشن
  Future<void> play() async {
    if (_state == AnimationState.playing) return;

    _setState(AnimationState.playing);
    if (_enablePerformanceMetrics) _metrics.startSession();

    try {
      await _timeline.play();
    } catch (e) {
      debugPrint('Animation play error: $e');
      _setState(AnimationState.error);
    }
  }

  /// توقف انیمیشن
  void pause() {
    if (_state != AnimationState.playing) return;

    _setState(AnimationState.paused);
    _timeline.pause();
    if (_enablePerformanceMetrics) _metrics.pauseSession();
  }

  /// متوقف کردن کامل انیمیشن
  void stop() {
    _setState(AnimationState.stopped);
    _timeline.stop();
    _pathManager.stopAll();
    _nodeManager.stopAll();
    _rippleManager.stopAll();
    _transitionHighlighter.clear();
    if (_enablePerformanceMetrics) _metrics.endSession();
    notifyListeners();
  }

  /// قدم بعدی انیمیشن
  Future<void> stepForward() async {
    if (_state == AnimationState.playing) {
      pause();
    }
    await _timeline.stepForward();
    notifyListeners();
  }

  /// قدم قبلی انیمیشن
  Future<void> stepBackward() async {
    if (_state == AnimationState.playing) {
      pause();
    }
    await _timeline.stepBackward();
    notifyListeners();
  }

  /// رفتن به زمان خاص
  Future<void> seekTo(Duration time) async {
    await _timeline.seekTo(time);
    notifyListeners();
  }

  /// اجرای string در مسیر
  Future<void> executeString(
    String input,
    List<StateNode> nodes,
    List<StateEdge> edges,
    Map<String, Offset> nodePositions,
  ) async {
    stop(); // Stop any current animation
    final path = _findExecutionPath(input, nodes, edges);
    if (path.isEmpty) {
      debugPrint("No valid path found for input: $input");
      return;
    }

    _timeline.clearEvents();
    _timeline.addEvent(
      TimelineEvent(
        id: 'path_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Animate: $input',
        type: TimelineEventType.pathAnimation,
        timestamp: Duration.zero,
        duration: Duration(
          milliseconds:
              (path.length * (_defaultDuration.inMilliseconds / _speed))
                  .round(),
        ),
        data: {
          'path': path,
          'nodePositions': nodePositions,
          'input': input,
          'stepDuration': _defaultDuration,
        },
      ),
    );

    if (_autoPlay) {
      await play();
    }
    notifyListeners();
  }

  /// انیمیشن ورود نود
  Future<void> animateNodeEntrance(
    String nodeId,
    Offset position, {
    NodeEntranceType type = NodeEntranceType.fadeScale,
    Duration? duration,
  }) async {
    await _nodeManager.animateEntrance(
      nodeId: nodeId,
      position: position,
      type: type,
      duration: duration ?? _defaultDuration,
    );
  }

  /// انیمیشن خروج نود
  Future<void> animateNodeExit(
    String nodeId, {
    NodeExitType type = NodeExitType.fadeScale,
    Duration? duration,
  }) async {
    await _nodeManager.animateExit(
      nodeId: nodeId,
      type: type,
      duration: duration ?? _defaultDuration,
    );
  }

  /// ایجاد ripple effect
  void createRipple(
    Offset position, {
    Color? color,
    double? maxRadius,
    Duration? duration,
  }) {
    _rippleManager.createRipple(
      position: position,
      color: color ?? Colors.blue.withOpacity(0.3),
      maxRadius: maxRadius ?? 100.0,
      duration: duration ?? _defaultDuration,
    );
  }

  /// هایلایت کردن transition
  void highlightTransition(
    String edgeId,
    Offset from,
    Offset to, {
    Color? color,
    Duration? duration,
  }) {
    _transitionHighlighter.highlight(
      edgeId: edgeId,
      from: from,
      to: to,
      color: color ?? Colors.orange,
      duration: duration ?? _defaultDuration,
    );
  }

  List<PathStep> _findExecutionPath(
    String input,
    List<StateNode> nodes,
    List<StateEdge> edges,
  ) {
    final path = <PathStep>[];
    if (nodes.isEmpty) return path;

    final startNode = nodes.firstWhere(
      (n) => n.isStart,
      orElse: () => nodes.first,
    );
    String currentNodeId = startNode.id;

    path.add(
      PathStep(
        nodeId: currentNodeId,
        edgeId: null,
        symbol: null,
        timestamp: Duration.zero,
      ),
    );

    for (int i = 0; i < input.length; i++) {
      final symbol = input[i];
      final transition = edges.firstWhere(
        (e) => e.fromId == currentNodeId && e.label == symbol,
        orElse: () => const StateEdge(id: '', fromId: '', toId: ''),
      );

      if (transition.id.isEmpty) {
        debugPrint(
          "Path execution stopped: No transition for symbol '$symbol' from node '$currentNodeId'.",
        );
        break;
      }

      currentNodeId = transition.toId;
      path.add(
        PathStep(
          nodeId: currentNodeId,
          edgeId: transition.id,
          symbol: symbol,
          timestamp: Duration(
            milliseconds: (i + 1) * 1000,
          ), // Relative timestamp
        ),
      );
    }
    return path;
  }

  void _setState(AnimationState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pathManager.dispose();
    _nodeManager.dispose();
    _rippleManager.dispose();
    _transitionHighlighter.dispose();
    _timeline.dispose();
    _metrics.dispose();
    super.dispose();
  }
}

/// مدیر انیمیشن مسیرها
class PathAnimationManager {
  final List<PathAnimationController> _activeAnimations = [];
  Duration _defaultDuration = const Duration(milliseconds: 800);
  Curve _defaultCurve = Curves.easeInOutCubic;
  double _speed = 1.0;

  void configure({
    Duration? defaultDuration,
    Curve? defaultCurve,
    double? speed,
  }) {
    _defaultDuration = defaultDuration ?? _defaultDuration;
    _defaultCurve = defaultCurve ?? _defaultCurve;
    _speed = speed ?? _speed;
  }

  Future<void> animatePath({
    required List<PathStep> path,
    required Map<String, Offset> nodePositions,
    required String input,
    Duration? stepDuration,
  }) async {
    if (path.isEmpty) return;
    final controller = PathAnimationController(
      path: path,
      nodePositions: nodePositions,
      input: input,
      stepDuration: stepDuration ?? _defaultDuration,
      curve: _defaultCurve,
      speed: _speed,
    );
    _activeAnimations.add(controller);
    try {
      await controller.animate();
    } finally {
      _activeAnimations.remove(controller);
      controller.dispose();
    }
  }

  void stopAll() {
    for (final controller in _activeAnimations) {
      controller.stop();
    }
    _activeAnimations.clear();
  }

  void dispose() {
    stopAll();
  }
}

/// کنترلر انیمیشن مسیر
class PathAnimationController {
  final List<PathStep> path;
  final Map<String, Offset> nodePositions;
  final String input;
  final Duration stepDuration;
  final Curve curve;
  final double speed;

  final StreamController<PathAnimationEvent> _eventController =
      StreamController<PathAnimationEvent>.broadcast();
  bool _isDisposed = false;

  PathAnimationController({
    required this.path,
    required this.nodePositions,
    required this.input,
    required this.stepDuration,
    required this.curve,
    required this.speed,
  });

  Stream<PathAnimationEvent> get events => _eventController.stream;

  Future<void> animate() async {
    for (int i = 0; i < path.length; i++) {
      if (_isDisposed) break;
      final step = path[i];

      _eventController.add(
        PathAnimationEvent(
          type: PathAnimationEventType.stepStarted,
          step: step,
          progress: i / path.length,
        ),
      );

      if (i > 0) {
        final previousStep = path[i - 1];
        await _animateMovement(
          nodePositions[previousStep.nodeId] ?? Offset.zero,
          nodePositions[step.nodeId] ?? Offset.zero,
          step.edgeId,
          step.symbol,
        );
      }

      await _animateNodeActivation(step.nodeId);

      _eventController.add(
        PathAnimationEvent(
          type: PathAnimationEventType.stepCompleted,
          step: step,
          progress: (i + 1) / path.length,
        ),
      );

      await Future.delayed(
        Duration(
          milliseconds: (stepDuration.inMilliseconds * 0.2 / speed).round(),
        ),
      );
    }

    if (!_isDisposed) {
      _eventController.add(
        PathAnimationEvent(
          type: PathAnimationEventType.completed,
          step: path.last,
          progress: 1.0,
        ),
      );
    }
  }

  Future<void> _animateMovement(
    Offset from,
    Offset to,
    String? edgeId,
    String? symbol,
  ) async {
    _eventController.add(
      PathAnimationEvent(
        type: PathAnimationEventType.particleMoving,
        step: PathStep(
          nodeId: '',
          edgeId: edgeId,
          symbol: symbol,
          timestamp: Duration.zero,
        ),
        progress: 0.0,
        data: {'from': from, 'to': to, 'symbol': symbol},
      ),
    );

    const steps = 20;
    for (int i = 0; i <= steps; i++) {
      if (_isDisposed) break;
      final t = i / steps;
      final position = Offset.lerp(from, to, curve.transform(t))!;
      _eventController.add(
        PathAnimationEvent(
          type: PathAnimationEventType.particlePosition,
          step: PathStep(
            nodeId: '',
            edgeId: edgeId,
            symbol: symbol,
            timestamp: Duration.zero,
          ),
          progress: t,
          data: {'position': position, 'symbol': symbol},
        ),
      );
      await Future.delayed(
        Duration(
          milliseconds: (stepDuration.inMilliseconds / steps / speed).round(),
        ),
      );
    }
  }

  Future<void> _animateNodeActivation(String nodeId) async {
    _eventController.add(
      PathAnimationEvent(
        type: PathAnimationEventType.nodeActivated,
        step: PathStep(
          nodeId: nodeId,
          edgeId: null,
          symbol: null,
          timestamp: Duration.zero,
        ),
        progress: 0.0,
      ),
    );

    const pulseSteps = 10;
    for (int i = 0; i <= pulseSteps; i++) {
      if (_isDisposed) break;
      final t = i / pulseSteps;
      final scale = 1.0 + 0.2 * math.sin(t * math.pi);
      _eventController.add(
        PathAnimationEvent(
          type: PathAnimationEventType.nodePulse,
          step: PathStep(
            nodeId: nodeId,
            edgeId: null,
            symbol: null,
            timestamp: Duration.zero,
          ),
          progress: t,
          data: {'scale': scale},
        ),
      );
      await Future.delayed(
        Duration(
          milliseconds: (stepDuration.inMilliseconds * 0.3 / pulseSteps / speed)
              .round(),
        ),
      );
    }
  }

  void stop() {
    _isDisposed = true;
  }

  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _eventController.close();
    }
  }
}

/// مدیر انیمیشن نودها
class NodeAnimationManager {
  final Map<String, NodeAnimationController> _activeAnimations = {};
  Duration _defaultDuration = const Duration(milliseconds: 800);
  Curve _defaultCurve = Curves.easeInOutCubic;

  void configure({Duration? defaultDuration, Curve? defaultCurve}) {
    _defaultDuration = defaultDuration ?? _defaultDuration;
    _defaultCurve = defaultCurve ?? _defaultCurve;
  }

  Future<void> animateEntrance({
    required String nodeId,
    required Offset position,
    NodeEntranceType type = NodeEntranceType.fadeScale,
    Duration? duration,
  }) async {
    final controller = NodeAnimationController(
      nodeId: nodeId,
      position: position,
      duration: duration ?? _defaultDuration,
      curve: _defaultCurve,
    );
    _activeAnimations[nodeId] = controller;
    try {
      await controller.animateEntrance(type);
    } finally {
      _activeAnimations.remove(nodeId);
      controller.dispose();
    }
  }

  Future<void> animateExit({
    required String nodeId,
    NodeExitType type = NodeExitType.fadeScale,
    Duration? duration,
  }) async {
    _activeAnimations[nodeId]?.stop();
    _activeAnimations.remove(nodeId);

    final controller = NodeAnimationController(
      nodeId: nodeId,
      position: Offset.zero, // Position is not relevant for exit
      duration: duration ?? _defaultDuration,
      curve: _defaultCurve,
    );
    _activeAnimations[nodeId] = controller;
    try {
      await controller.animateExit(type);
    } finally {
      _activeAnimations.remove(nodeId);
      controller.dispose();
    }
  }

  void stopAll() {
    for (var controller in _activeAnimations.values) {
      controller.stop();
    }
    _activeAnimations.clear();
  }

  void dispose() {
    stopAll();
  }
}

/// کنترلر انیمیشن نود
class NodeAnimationController {
  final String nodeId;
  final Offset position;
  final Duration duration;
  final Curve curve;
  final StreamController<NodeAnimationEvent> _eventController =
      StreamController<NodeAnimationEvent>.broadcast();
  bool _isDisposed = false;

  NodeAnimationController({
    required this.nodeId,
    required this.position,
    required this.duration,
    required this.curve,
  });

  Stream<NodeAnimationEvent> get events => _eventController.stream;

  Future<void> animateEntrance(NodeEntranceType type) async {
    const steps = 30;
    for (int i = 0; i <= steps; i++) {
      if (_isDisposed) break;
      final t = curve.transform(i / steps);
      final properties = _calculateEntranceProperties(type, t);
      _eventController.add(
        NodeAnimationEvent(
          nodeId: nodeId,
          type: NodeAnimationEventType.entrance,
          properties: properties,
          progress: t,
        ),
      );
      await Future.delayed(
        Duration(milliseconds: duration.inMilliseconds ~/ steps),
      );
    }
  }

  Future<void> animateExit(NodeExitType type) async {
    const steps = 30;
    for (int i = 0; i <= steps; i++) {
      if (_isDisposed) break;
      final t = curve.transform(i / steps);
      final properties = _calculateExitProperties(type, t);
      _eventController.add(
        NodeAnimationEvent(
          nodeId: nodeId,
          type: NodeAnimationEventType.exit,
          properties: properties,
          progress: t,
        ),
      );
      await Future.delayed(
        Duration(milliseconds: duration.inMilliseconds ~/ steps),
      );
    }
  }

  NodeAnimationProperties _calculateEntranceProperties(
    NodeEntranceType type,
    double t,
  ) {
    switch (type) {
      case NodeEntranceType.fadeScale:
        return NodeAnimationProperties(opacity: t, scale: 0.3 + (0.7 * t));
      case NodeEntranceType.slideFromLeft:
        return NodeAnimationProperties(offset: Offset(-100 * (1 - t), 0));
      case NodeEntranceType.slideFromTop:
        return NodeAnimationProperties(offset: Offset(0, -100 * (1 - t)));
      case NodeEntranceType.bounceIn:
        return NodeAnimationProperties(opacity: t, scale: _bounceOut(t));
      case NodeEntranceType.rotateIn:
        return NodeAnimationProperties(
          opacity: t,
          scale: t,
          rotation: (1 - t) * 2 * math.pi,
        );
    }
  }

  NodeAnimationProperties _calculateExitProperties(
    NodeExitType type,
    double t,
  ) {
    switch (type) {
      case NodeExitType.fadeScale:
        return NodeAnimationProperties(opacity: 1 - t, scale: 1.0 - (0.7 * t));
      case NodeExitType.slideToRight:
        return NodeAnimationProperties(offset: Offset(100 * t, 0));
      case NodeExitType.slideToBottom:
        return NodeAnimationProperties(offset: Offset(0, 100 * t));
      case NodeExitType.implode:
        return NodeAnimationProperties(
          opacity: 1 - t,
          scale: 1.0 - t,
          rotation: t * 2 * math.pi,
        );
    }
  }

  double _bounceOut(double t) {
    if (t < 1 / 2.75) return 7.5625 * t * t;
    if (t < 2 / 2.75) return 7.5625 * (t -= 1.5 / 2.75) * t + 0.75;
    if (t < 2.5 / 2.75) return 7.5625 * (t -= 2.25 / 2.75) * t + 0.9375;
    return 7.5625 * (t -= 2.625 / 2.75) * t + 0.984375;
  }

  void stop() {
    _isDisposed = true;
  }

  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _eventController.close();
    }
  }
}

/// مدیر Ripple Effects
class RippleAnimationManager {
  final List<RippleController> _activeRipples = [];
  Duration _defaultDuration = const Duration(milliseconds: 800);
  Curve _defaultCurve = Curves.easeOut;

  void configure({Duration? defaultDuration, Curve? defaultCurve}) {
    _defaultDuration = defaultDuration ?? _defaultDuration;
    _defaultCurve = defaultCurve ?? _defaultCurve;
  }

  void createRipple({
    required Offset position,
    required Color color,
    required double maxRadius,
    Duration? duration,
  }) {
    final controller = RippleController(
      position: position,
      color: color,
      maxRadius: maxRadius,
      duration: duration ?? _defaultDuration,
      curve: _defaultCurve,
    );
    _activeRipples.add(controller);
    controller.animate().whenComplete(() {
      _activeRipples.remove(controller);
      controller.dispose();
    });
  }

  List<RippleState> getCurrentRipples() =>
      _activeRipples.map((c) => c.currentState).toList();
  void stopAll() {
    for (var c in _activeRipples) {
      c.stop();
    }
    _activeRipples.clear();
  }

  void dispose() => stopAll();
}

/// کنترلر Ripple
class RippleController {
  final Offset position;
  final Color color;
  final double maxRadius;
  final Duration duration;
  final Curve curve;
  late RippleState _currentState;
  bool _isDisposed = false;

  RippleController({
    required this.position,
    required this.color,
    required this.maxRadius,
    required this.duration,
    required this.curve,
  }) {
    _currentState = RippleState(
      position: position,
      radius: 0,
      opacity: 1.0,
      color: color,
    );
  }

  RippleState get currentState => _currentState;

  Future<void> animate() async {
    const steps = 60;
    for (int i = 0; i <= steps; i++) {
      if (_isDisposed) break;
      final t = curve.transform(i / steps);
      _currentState = RippleState(
        position: position,
        radius: maxRadius * t,
        opacity: (1.0 - t).clamp(0.0, 1.0),
        color: color,
      );
      await Future.delayed(
        Duration(microseconds: duration.inMicroseconds ~/ steps),
      );
    }
  }

  void stop() => _isDisposed = true;
  void dispose() => _isDisposed = true;
}

/// مدیر هایلایت Transition
class TransitionHighlighter {
  final Map<String, TransitionHighlightController> _activeHighlights = {};

  void highlight({
    required String edgeId,
    required Offset from,
    required Offset to,
    required Color color,
    required Duration duration,
  }) {
    _activeHighlights[edgeId]?.stop();
    final controller = TransitionHighlightController(
      edgeId: edgeId,
      from: from,
      to: to,
      color: color,
      duration: duration,
    );
    _activeHighlights[edgeId] = controller;
    controller.animate().whenComplete(() {
      _activeHighlights.remove(edgeId);
      controller.dispose();
    });
  }

  List<TransitionHighlightState> getCurrentHighlights() =>
      _activeHighlights.values.map((c) => c.currentState).toList();
  void clear() {
    for (var c in _activeHighlights.values) {
      c.stop();
    }
    _activeHighlights.clear();
  }

  void dispose() => clear();
}

/// کنترلر Transition Highlight
class TransitionHighlightController {
  final String edgeId;
  final Offset from;
  final Offset to;
  final Color color;
  final Duration duration;
  late TransitionHighlightState _currentState;
  bool _isDisposed = false;

  TransitionHighlightController({
    required this.edgeId,
    required this.from,
    required this.to,
    required this.color,
    required this.duration,
  }) {
    _currentState = TransitionHighlightState(
      edgeId: edgeId,
      from: from,
      to: to,
      color: color,
      progress: 0.0,
      thickness: 3.0,
    );
  }

  TransitionHighlightState get currentState => _currentState;

  Future<void> animate() async {
    const steps = 60;
    for (int i = 0; i <= steps; i++) {
      if (_isDisposed) break;
      final t = i / steps;
      final progress = t < 0.5 ? t * 2 : 2 * (1 - t);
      final thickness = 3.0 + 2.0 * math.sin(t * math.pi * 4);
      _currentState = TransitionHighlightState(
        edgeId: edgeId,
        from: from,
        to: to,
        color: color.withOpacity(0.7 + 0.3 * progress),
        progress: progress,
        thickness: thickness,
      );
      await Future.delayed(
        Duration(microseconds: duration.inMicroseconds ~/ steps),
      );
    }
  }

  void stop() => _isDisposed = true;
  void dispose() => _isDisposed = true;
}

/// مدیر Timeline انیمیشن
class AnimationTimeline {
  final List<TimelineEvent> _events = [];
  Duration _currentTime = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  Timer? _timer;
  final StreamController<TimelineState> _stateController =
      StreamController<TimelineState>.broadcast();

  Stream<TimelineState> get stateStream => _stateController.stream;
  Duration get currentTime => _currentTime;
  Duration get totalDuration => _totalDuration;
  bool get isPlaying => _isPlaying;
  List<TimelineEvent> get events => List.unmodifiable(_events);

  void addEvent(TimelineEvent event) {
    _events.add(event);
    _events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (_events.isNotEmpty) {
      final lastEvent = _events.last;
      _totalDuration = lastEvent.timestamp + lastEvent.duration;
    }
    _notifyStateChange();
  }

  void removeEvent(String eventId) {
    _events.removeWhere((event) => event.id == eventId);
    _notifyStateChange();
  }

  void clearEvents() {
    _events.clear();
    _totalDuration = Duration.zero;
    _currentTime = Duration.zero;
    _notifyStateChange();
  }

  Future<void> play() async {
    if (_isPlaying) return;
    _isPlaying = true;
    _notifyStateChange();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _currentTime += const Duration(milliseconds: 16);

      final currentEvents = _events
          .where(
            (e) =>
                _currentTime >= e.timestamp &&
                _currentTime <= e.timestamp + e.duration,
          )
          .toList();

      for (final event in currentEvents) {
        if (!_isEventActive(event.id)) {
          _setActiveEvent(event.id);
          _executeEvent(event);
        }
      }

      _notifyStateChange();
      if (_currentTime >= _totalDuration) {
        stop();
        if (AnimationSystem().loopEnabled) {
          play();
        }
      }
    });
  }

  final Set<String> _activeEvents = {};
  bool _isEventActive(String eventId) => _activeEvents.contains(eventId);
  void _setActiveEvent(String eventId) => _activeEvents.add(eventId);

  void pause() {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _notifyStateChange();
  }

  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _currentTime = Duration.zero;
    _activeEvents.clear();
    _notifyStateChange();
  }

  Future<void> stepForward() async {
    if (_events.isEmpty) return;
    final nextEvent = _events.firstWhere(
      (e) => e.timestamp > _currentTime,
      orElse: () => _events.last,
    );
    _currentTime = nextEvent.timestamp;
    _executeEvent(nextEvent);
    _notifyStateChange();
  }

  Future<void> stepBackward() async {
    if (_events.isEmpty) return;
    final prevEvent = _events.lastWhere(
      (e) => e.timestamp < _currentTime,
      orElse: () => _events.first,
    );
    _currentTime = prevEvent.timestamp;
    _executeEvent(prevEvent);
    _notifyStateChange();
  }

  Future<void> seekTo(Duration time) async {
    _currentTime = Duration(
      milliseconds: time.inMilliseconds.clamp(0, _totalDuration.inMilliseconds),
    );
    final eventsToExecute = _events
        .where((e) => e.timestamp <= _currentTime)
        .toList();
    for (final event in eventsToExecute) {
      _executeEvent(event);
    }
    _notifyStateChange();
  }

  void _executeEvent(TimelineEvent event) {
    final data = event.data as Map<String, dynamic>;
    switch (event.type) {
      case TimelineEventType.nodeEntrance:
        AnimationSystem()._nodeManager.animateEntrance(
          nodeId: data['nodeId'],
          position: data['position'],
          type: data['type'] ?? NodeEntranceType.fadeScale,
          duration: event.duration,
        );
        break;
      case TimelineEventType.nodeExit:
        AnimationSystem()._nodeManager.animateExit(
          nodeId: data['nodeId'],
          type: data['type'] ?? NodeExitType.fadeScale,
          duration: event.duration,
        );
        break;
      case TimelineEventType.pathAnimation:
        AnimationSystem()._pathManager.animatePath(
          path: data['path'],
          nodePositions: data['nodePositions'],
          input: data['input'],
          stepDuration: data['stepDuration'],
        );
        break;
      case TimelineEventType.rippleEffect:
        AnimationSystem()._rippleManager.createRipple(
          position: data['position'],
          color: data['color'],
          maxRadius: data['maxRadius'],
          duration: event.duration,
        );
        break;
      case TimelineEventType.transitionHighlight:
        AnimationSystem()._transitionHighlighter.highlight(
          edgeId: data['edgeId'],
          from: data['from'],
          to: data['to'],
          color: data['color'],
          duration: event.duration,
        );
        break;
    }
  }

  void _notifyStateChange() {
    if (_stateController.isClosed) return;
    _stateController.add(
      TimelineState(
        currentTime: _currentTime,
        totalDuration: _totalDuration,
        isPlaying: _isPlaying,
        progress: _totalDuration.inMilliseconds > 0
            ? _currentTime.inMilliseconds / _totalDuration.inMilliseconds
            : 0.0,
      ),
    );
  }

  void dispose() {
    _timer?.cancel();
    _stateController.close();
  }
}

/// مدیر آمار عملکرد انیمیشن
class AnimationMetrics {
  final List<PerformanceFrame> _frames = [];
  final List<AnimationSession> _sessions = [];
  DateTime? _sessionStartTime;
  int _frameCount = 0;
  double _totalFrameTime = 0.0;
  int _droppedFrames = 0;
  bool _isRecording = false;
  Timer? _metricsTimer;

  bool get isRecording => _isRecording;
  int get frameCount => _frameCount;
  double get averageFrameTime =>
      _frameCount > 0 ? _totalFrameTime / _frameCount : 0.0;
  double get fps => averageFrameTime > 0 ? 1000.0 / averageFrameTime : 0.0;
  int get droppedFrames => _droppedFrames;
  List<AnimationSession> get sessions => List.unmodifiable(_sessions);

  void startSession() {
    _sessionStartTime = DateTime.now();
    _frameCount = 0;
    _totalFrameTime = 0.0;
    _droppedFrames = 0;
    _isRecording = true;
    _metricsTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) => _recordFrame(),
    );
  }

  void pauseSession() {
    _isRecording = false;
    _metricsTimer?.cancel();
  }

  void endSession() {
    if (_sessionStartTime != null) {
      final session = AnimationSession(
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        frameCount: _frameCount,
        averageFrameTime: averageFrameTime,
        droppedFrames: _droppedFrames,
        fps: fps,
      );
      _sessions.add(session);
      if (_sessions.length > 10) _sessions.removeAt(0);
    }
    _isRecording = false;
    _metricsTimer?.cancel();
    _sessionStartTime = null;
  }

  void _recordFrame() {
    if (!_isRecording) return;
    const frameTime = 16.0; // Assume 60fps
    _frameCount++;
    _totalFrameTime += frameTime;
    if (frameTime > 20.0) _droppedFrames++;
    final frame = PerformanceFrame(
      timestamp: DateTime.now(),
      frameTime: frameTime,
      fps: 1000.0 / frameTime,
      isDropped: frameTime > 20.0,
    );
    _frames.add(frame);
    if (_frames.length > 100) _frames.removeAt(0);
  }

  MetricsReport generateReport() {
    if (_sessions.isEmpty) {
      return MetricsReport(
        totalSessions: 0,
        averageFps: 0,
        totalDroppedFrames: 0,
        performanceScore: 100,
        recommendations: [],
      );
    }
    return MetricsReport(
      totalSessions: _sessions.length,
      averageFps:
          _sessions.map((s) => s.fps).reduce((a, b) => a + b) /
          _sessions.length,
      totalDroppedFrames: _sessions.fold(0, (sum, s) => sum + s.droppedFrames),
      performanceScore: _calculatePerformanceScore(),
      recommendations: _generateRecommendations(),
    );
  }

  double _calculatePerformanceScore() {
    if (_sessions.isEmpty) return 100.0;
    final avgFps =
        _sessions.map((s) => s.fps).reduce((a, b) => a + b) / _sessions.length;
    final totalDropped = _sessions.fold(0, (sum, s) => sum + s.droppedFrames);
    final fpsScore = (avgFps / 60.0).clamp(0.0, 1.0) * 70.0;
    final droppedScore = totalDropped == 0
        ? 30.0
        : math.max(0.0, 30.0 - totalDropped);
    return fpsScore + droppedScore;
  }

  List<String> _generateRecommendations() {
    final recs = <String>[];
    if (fps < 30)
      recs.addAll([
        'Consider reducing animation complexity',
        'Enable performance optimization mode',
      ]);
    if (droppedFrames > 10)
      recs.addAll([
        'Reduce concurrent animations',
        'Use simpler animation curves',
      ]);
    if (averageFrameTime > 25)
      recs.addAll([
        'Optimize rendering performance',
        'Consider reducing particle effects',
      ]);
    return recs;
  }

  void dispose() {
    _metricsTimer?.cancel();
    _frames.clear();
    _sessions.clear();
  }
}

/// Widget اصلی نمایش انیمیشن
class AnimatedStateDiagram extends StatefulWidget {
  final StateDiagramData data;
  final Map<String, Offset> nodePositions;
  final AnimationSystem animationSystem;
  final DiagramTheme? theme;
  final Function(String nodeId)? onNodeTap;
  final Function(String edgeId)? onEdgeTap;

  const AnimatedStateDiagram({
    super.key,
    required this.data,
    required this.nodePositions,
    required this.animationSystem,
    this.theme,
    this.onNodeTap,
    this.onEdgeTap,
  });

  @override
  State<AnimatedStateDiagram> createState() => _AnimatedStateDiagramState();
}

class _AnimatedStateDiagramState extends State<AnimatedStateDiagram> {
  final Map<String, NodeAnimationProperties> _nodeAnimations = {};
  final List<RippleState> _ripples = [];
  final List<TransitionHighlightState> _highlights = [];
  final Map<String, ParticleState> _particles = {};
  final List<StreamSubscription> _subscriptions = [];
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimationListeners();
    _startUpdateTimer();
  }

  @override
  void didUpdateWidget(covariant AnimatedStateDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationSystem != oldWidget.animationSystem) {
      _cleanupListeners();
      _setupAnimationListeners();
    }
  }

  void _setupAnimationListeners() {
    _subscriptions.add(
      widget.animationSystem.timeline.stateStream.listen((_) {
        _subscribeToPathControllers();
      }),
    );
    _subscribeToPathControllers();
  }

  void _subscribeToPathControllers() {
    final activeControllers =
        widget.animationSystem.pathManager._activeAnimations;
    _subscriptions.whereType<StreamSubscription<PathAnimationEvent>>().forEach(
      (sub) => sub.cancel(),
    );

    for (final controller in activeControllers) {
      final sub = controller.events.listen(
        _handlePathEvent,
        onDone: () {
          if (mounted) setState(() => _particles.clear());
        },
      );
      _subscriptions.add(sub);
    }
  }

  void _handlePathEvent(PathAnimationEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event.type) {
        case PathAnimationEventType.particleMoving:
          final data = event.data!;
          _particles[event.step.edgeId ?? ''] = ParticleState(
            position: data['from'],
            symbol: data['symbol'],
            opacity: 1.0,
          );
          break;
        case PathAnimationEventType.particlePosition:
          final data = event.data!;
          _particles[event.step.edgeId ?? ''] = ParticleState(
            position: data['position'],
            symbol: data['symbol'],
            opacity: 1.0 - event.progress * 0.5,
          );
          break;
        case PathAnimationEventType.nodeActivated:
          _nodeAnimations[event.step.nodeId] = NodeAnimationProperties(
            scale: 1.2,
          );
          break;
        case PathAnimationEventType.nodePulse:
          _nodeAnimations[event.step.nodeId] = NodeAnimationProperties(
            scale: event.data!['scale'],
          );
          break;
        case PathAnimationEventType.stepCompleted:
          _nodeAnimations[event.step.nodeId] =
              NodeAnimationProperties(); // Reset
          break;
        case PathAnimationEventType.completed:
          _particles.clear();
          break;
        default:
          break;
      }
    });
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _ripples.clear();
        _ripples.addAll(
          widget.animationSystem.rippleManager.getCurrentRipples(),
        );
        _highlights.clear();
        _highlights.addAll(
          widget.animationSystem.transitionHighlighter.getCurrentHighlights(),
        );
      });
    });
  }

  void _cleanupListeners() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _updateTimer?.cancel();
  }

  @override
  void dispose() {
    _cleanupListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AnimatedDiagramPainter(
        data: widget.data,
        nodePositions: widget.nodePositions,
        nodeAnimations: _nodeAnimations,
        ripples: _ripples,
        highlights: _highlights,
        particles: _particles,
        theme: widget.theme,
      ),
      child: GestureDetector(
        onTapDown: (details) {
          final pos = details.localPosition;
          for (final node in widget.data.nodes) {
            final nodePos = widget.nodePositions[node.id];
            if (nodePos != null && (pos - nodePos).distance < 35) {
              widget.onNodeTap?.call(node.id);
              widget.animationSystem.createRipple(nodePos);
              return;
            }
          }
        },
        child: Container(
          color: Colors.transparent, // Make GestureDetector hittable
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

/// Painter برای رسم انیمیشن‌ها
class AnimatedDiagramPainter extends CustomPainter {
  final StateDiagramData data;
  final Map<String, Offset> nodePositions;
  final Map<String, NodeAnimationProperties> nodeAnimations;
  final List<RippleState> ripples;
  final List<TransitionHighlightState> highlights;
  final Map<String, ParticleState> particles;
  final DiagramTheme? theme;

  AnimatedDiagramPainter({
    required this.data,
    required this.nodePositions,
    required this.nodeAnimations,
    required this.ripples,
    required this.highlights,
    required this.particles,
    this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawRipples(canvas);
    _drawEdges(canvas);
    _drawParticles(canvas);
    _drawNodes(canvas);
  }

  void _drawRipples(Canvas canvas) {
    for (final ripple in ripples) {
      final paint = Paint()
        ..color = ripple.color.withOpacity(ripple.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(ripple.position, ripple.radius, paint);
      final innerPaint = Paint()
        ..color = ripple.color.withOpacity(ripple.opacity * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(ripple.position, ripple.radius * 0.7, innerPaint);
    }
  }

  void _drawEdges(Canvas canvas) {
    final defaultPaint = Paint()
      ..color = theme?.colorScheme.edgeDefault ?? Colors.grey
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final edge in data.edges) {
      final fromPos = nodePositions[edge.fromId];
      final toPos = nodePositions[edge.toId];
      if (fromPos == null || toPos == null) continue;

      TransitionHighlightState? highlight;
      for (final h in highlights) {
        if (h.edgeId == edge.id) {
          highlight = h;
          break;
        }
      }

      final paint = highlight != null
          ? (Paint()
              ..color = highlight.color
              ..strokeWidth = highlight.thickness
              ..style = PaintingStyle.stroke)
          : defaultPaint;

      if (edge.fromId == edge.toId) {
        _drawSelfLoop(canvas, fromPos, paint, edge.label);
      } else {
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
    const radius = 25.0;
    final center = nodePos + const Offset(0, -radius - 30);
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: radius * 2,
    );
    canvas.drawArc(rect, -math.pi / 4, math.pi * 1.5, false, paint);
    final arrowPos =
        center +
        Offset(
          radius * math.cos(-math.pi / 4),
          radius * math.sin(-math.pi / 4),
        );
    _drawArrowHead(canvas, arrowPos, -math.pi / 4, paint);
  }

  void _drawRegularEdge(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
    String? label,
  ) {
    const nodeRadius = 30.0;
    final direction = to - from;
    final unitVector = direction / direction.distance;
    final startPoint = from + unitVector * nodeRadius;
    final endPoint = to - unitVector * nodeRadius;
    canvas.drawLine(startPoint, endPoint, paint);
    final arrowDirection = math.atan2(
      endPoint.dy - startPoint.dy,
      endPoint.dx - startPoint.dx,
    );
    _drawArrowHead(canvas, endPoint, arrowDirection, paint);
    if (label != null && label.isNotEmpty) {
      _drawEdgeLabel(canvas, (startPoint + endPoint) / 2, label);
    }
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    double direction,
    Paint paint,
  ) {
    const arrowLength = 10.0;
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
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p2.dx, p2.dy);
    canvas.drawPath(path, paint);
  }

  void _drawEdgeLabel(Canvas canvas, Offset position, String label) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: theme?.colorScheme.textSecondary ?? Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawParticles(Canvas canvas) {
    for (final particle in particles.values) {
      if (particle.symbol == null) continue;
      final paint = Paint()
        ..color = Colors.orange.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particle.position, 8, paint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.symbol!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        particle.position -
            Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in data.nodes) {
      final position = nodePositions[node.id];
      if (position == null) continue;
      final anim = nodeAnimations[node.id] ?? NodeAnimationProperties();
      canvas.save();
      canvas.translate(
        position.dx + anim.offset.dx,
        position.dy + anim.offset.dy,
      );
      canvas.scale(anim.scale);
      canvas.rotate(anim.rotation);

      final paint = Paint()
        ..color = _getNodeColor(node).withOpacity(anim.opacity)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = _getNodeBorderColor(node).withOpacity(anim.opacity)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset.zero, 30, paint);
      canvas.drawCircle(Offset.zero, 30, borderPaint);
      if (node.isFinal) {
        final innerPaint = Paint()
          ..color = _getNodeBorderColor(node).withOpacity(anim.opacity)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset.zero, 22, innerPaint);
      }
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.label,
          style: TextStyle(
            color: (theme?.colorScheme.textPrimary ?? Colors.black).withOpacity(
              anim.opacity,
            ),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  Color _getNodeColor(StateNode node) {
    if (node.isStart)
      return theme?.colorScheme.stateStart ?? Colors.green.shade100;
    if (node.isFinal)
      return theme?.colorScheme.stateFinal ?? Colors.red.shade100;
    return theme?.colorScheme.stateDefault ?? Colors.blue.shade100;
  }

  Color _getNodeBorderColor(StateNode node) {
    if (node.isStart) return theme?.colorScheme.stateStart ?? Colors.green;
    if (node.isFinal) return theme?.colorScheme.stateFinal ?? Colors.red;
    return theme?.colorScheme.stateDefault ?? Colors.blue;
  }

  @override
  bool shouldRepaint(covariant AnimatedDiagramPainter oldDelegate) => true;
}

/// Widget کنترل انیمیشن
class AnimationControlPanel extends StatefulWidget {
  final AnimationSystem animationSystem;
  final Function(String) onStringSubmitted;

  const AnimationControlPanel({
    super.key,
    required this.animationSystem,
    required this.onStringSubmitted,
  });

  @override
  State<AnimationControlPanel> createState() => _AnimationControlPanelState();
}

class _AnimationControlPanelState extends State<AnimationControlPanel> {
  final TextEditingController _stringController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.animationSystem.addListener(_onAnimationSystemChanged);
  }

  @override
  void dispose() {
    widget.animationSystem.removeListener(_onAnimationSystemChanged);
    _stringController.dispose();
    super.dispose();
  }

  void _onAnimationSystemChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = widget.animationSystem;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _stringController,
            decoration: InputDecoration(
              labelText: 'Input String',
              hintText: 'Enter string to animate...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.play_circle_fill),
                onPressed: () =>
                    widget.onStringSubmitted(_stringController.text),
              ),
            ),
            onSubmitted: widget.onStringSubmitted,
          ),
          const SizedBox(height: 12),
          StreamBuilder<TimelineState>(
            stream: system.timeline.stateStream,
            initialData: TimelineState(
              currentTime: Duration.zero,
              totalDuration: Duration.zero,
              isPlaying: false,
              progress: 0,
            ),
            builder: (context, snapshot) {
              final state = snapshot.data!;
              return Column(
                children: [
                  if (state.totalDuration > Duration.zero)
                    Slider(
                      value: state.currentTime.inMilliseconds.toDouble().clamp(
                        0.0,
                        state.totalDuration.inMilliseconds.toDouble(),
                      ),
                      min: 0.0,
                      max: state.totalDuration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        system.seekTo(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(state.currentTime),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _formatDuration(state.totalDuration),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: system.stepBackward,
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Step Backward',
              ),
              IconButton(
                iconSize: 36,
                onPressed: system.state == AnimationState.playing
                    ? system.pause
                    : system.play,
                icon: Icon(
                  system.state == AnimationState.playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                ),
                tooltip: system.state == AnimationState.playing
                    ? 'Pause'
                    : 'Play',
              ),
              IconButton(
                onPressed: system.stop,
                icon: const Icon(Icons.stop),
                tooltip: 'Stop',
              ),
              IconButton(
                onPressed: system.stepForward,
                icon: const Icon(Icons.skip_next),
                tooltip: 'Step Forward',
              ),
              const Spacer(),
              Text('Speed', style: Theme.of(context).textTheme.bodySmall),
              SizedBox(
                width: 120,
                child: Slider(
                  value: system.speed,
                  min: 0.1,
                  max: 3.0,
                  divisions: 29,
                  label: '${system.speed.toStringAsFixed(1)}x',
                  onChanged: (value) => system.configure(speed: value),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Loop Animation',
                child: Switch(
                  value: system.loopEnabled,
                  onChanged: (value) => system.configure(loopEnabled: value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    return d.toString().split('.').first.padLeft(8, "0");
  }
}

/// Widget نمایش آمار عملکرد
class AnimationMetricsWidget extends StatefulWidget {
  final AnimationMetrics metrics;
  const AnimationMetricsWidget({super.key, required this.metrics});

  @override
  State<AnimationMetricsWidget> createState() => _AnimationMetricsWidgetState();
}

class _AnimationMetricsWidgetState extends State<AnimationMetricsWidget> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.metrics.isRecording && widget.metrics.sessions.isEmpty) {
      return const SizedBox.shrink();
    }
    final report = widget.metrics.generateReport();
    final score = report.performanceScore;

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            value: score / 100.0,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(
              score > 80
                  ? Colors.greenAccent
                  : score > 50
                  ? Colors.orangeAccent
                  : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Perf: ${score.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'FPS: ${report.averageFps.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Dropped: ${report.totalDroppedFrames}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ویجت نمونه استفاده کامل
class AnimationSystemExample extends StatefulWidget {
  const AnimationSystemExample({super.key});

  @override
  State<AnimationSystemExample> createState() => _AnimationSystemExampleState();
}

class _AnimationSystemExampleState extends State<AnimationSystemExample> {
  final AnimationSystem _animationSystem = AnimationSystem();
  late StateDiagramData _diagramData;
  late Map<String, Offset> _nodePositions;

  @override
  void initState() {
    super.initState();
    _setupSampleData();
    _animationSystem.configure(
      defaultDuration: const Duration(milliseconds: 1000),
      enablePerformanceMetrics: true,
      autoPlay: true,
    );
  }

  @override
  void dispose() {
    _animationSystem.dispose();
    super.dispose();
  }

  void _setupSampleData() {
    _diagramData = StateDiagramData(
      nodes: [
        const StateNode(id: 'q0', label: 'q0', isStart: true),
        const StateNode(id: 'q1', label: 'q1'),
        const StateNode(id: 'q2', label: 'q2', isFinal: true),
      ],
      edges: [
        const StateEdge(id: 'e1', fromId: 'q0', toId: 'q1', label: 'a'),
        const StateEdge(id: 'e2', fromId: 'q1', toId: 'q2', label: 'b'),
        const StateEdge(id: 'e3', fromId: 'q1', toId: 'q1', label: 'a'),
        const StateEdge(id: 'e4', fromId: 'q0', toId: 'q0', label: 'b'),
      ],
    );

    _nodePositions = {
      'q0': const Offset(150, 200),
      'q1': const Offset(350, 200),
      'q2': const Offset(550, 200),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('State Diagram Animation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showMetricsDialog,
            tooltip: 'Show Performance Report',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                AnimatedStateDiagram(
                  data: _diagramData,
                  nodePositions: _nodePositions,
                  animationSystem: _animationSystem,
                  onNodeTap: (nodeId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Node tapped: $nodeId'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: AnimationMetricsWidget(
                    metrics: _animationSystem.metrics,
                  ),
                ),
              ],
            ),
          ),
          AnimationControlPanel(
            animationSystem: _animationSystem,
            onStringSubmitted: (input) {
              _animationSystem.executeString(
                input,
                _diagramData.nodes,
                _diagramData.edges,
                _nodePositions,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMetricsDialog() {
    final report = _animationSystem.metrics.generateReport();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Report'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('Total Sessions: ${report.totalSessions}'),
              Text('Average FPS: ${report.averageFps.toStringAsFixed(1)}'),
              Text('Total Dropped Frames: ${report.totalDroppedFrames}'),
              Text(
                'Performance Score: ${report.performanceScore.toStringAsFixed(1)}%',
              ),
              if (report.recommendations.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Recommendations:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...report.recommendations.map((r) => Text('• $r')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
