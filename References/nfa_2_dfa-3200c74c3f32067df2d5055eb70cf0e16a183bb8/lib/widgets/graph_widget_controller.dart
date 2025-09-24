import 'package:flutter/material.dart';
import '/screens/graph_painter.dart';
import 'dart:async';

class GraphWidgetController extends ChangeNotifier {

  GraphLayoutType _layoutType = GraphLayoutType.circular;
  GraphTheme _theme = GraphTheme.light;
  AnimationType _animationType = AnimationType.none;
  double _nodeSize = 30.0;
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;
  
  // Visual properties
  bool _showTransitionLabels = true;
  bool _showStateInfo = true;
  bool _showGrid = false;
  bool _show3DEffect = false;
  bool _showMinimap = false;
  bool _enablePhysics = false;
  bool _showStatistics = false;
  double _edgeBundling = 0.0;
  
  // Interaction properties
  String? _selectedState;
  String? _hoveredState;
  Set<String> _highlightedStates = {};
  Set<String> _highlightedTransitions = {};
  Map<String, Offset> _manualPositions = {};
  Map<String, Color> _customStateColors = {};
  Map<String, double> _stateWeights = {};
  Color _highlightColor = Colors.orange;
  
  // Animation controller
  final GraphAnimationController _animationController = GraphAnimationController();
  Timer? _animationTimer;
  
  // Export data
  Map<String, dynamic>? _lastExportData;
  
  // Getters
  GraphLayoutType get layoutType => _layoutType;
  GraphTheme get theme => _theme;
  AnimationType get animationType => _animationType;
  double get nodeSize => _nodeSize;
  double get zoomLevel => _zoomLevel;
  Offset get panOffset => _panOffset;
  bool get showTransitionLabels => _showTransitionLabels;
  bool get showStateInfo => _showStateInfo;
  bool get showGrid => _showGrid;
  bool get show3DEffect => _show3DEffect;
  bool get showMinimap => _showMinimap;
  bool get enablePhysics => _enablePhysics;
  bool get showStatistics => _showStatistics;
  double get edgeBundling => _edgeBundling;
  String? get selectedState => _selectedState;
  String? get hoveredState => _hoveredState;
  Set<String> get highlightedStates => _highlightedStates;
  Set<String> get highlightedTransitions => _highlightedTransitions;
  Map<String, Offset> get manualPositions => _manualPositions;
  Map<String, Color> get customStateColors => _customStateColors;
  Map<String, double> get stateWeights => _stateWeights;
  Color get highlightColor => _highlightColor;
  GraphAnimationController get animationController => _animationController;
  Map<String, dynamic>? get lastExportData => _lastExportData;

  // Setters with validation
  set layoutType(GraphLayoutType value) {
    if (_layoutType != value) {
      _layoutType = value;
      _triggerLayoutAnimation();
      notifyListeners();
    }
  }

  set theme(GraphTheme value) {
    if (_theme != value) {
      _theme = value;
      _triggerThemeAnimation();
      notifyListeners();
    }
  }

  set animationType(AnimationType value) {
    if (_animationType != value) {
      _animationType = value;
      _setupAnimationTimer();
      notifyListeners();
    }
  }

  set nodeSize(double value) {
    final clampedValue = value.clamp(10.0, 100.0);
    if (_nodeSize != clampedValue) {
      _nodeSize = clampedValue;
      notifyListeners();
    }
  }

  set zoomLevel(double value) {
    final clampedValue = value.clamp(0.1, 5.0);
    if (_zoomLevel != clampedValue) {
      _zoomLevel = clampedValue;
      notifyListeners();
    }
  }

  set panOffset(Offset value) {
    if (_panOffset != value) {
      _panOffset = value;
      notifyListeners();
    }
  }

  set showTransitionLabels(bool value) {
    if (_showTransitionLabels != value) {
      _showTransitionLabels = value;
      notifyListeners();
    }
  }

  set showStateInfo(bool value) {
    if (_showStateInfo != value) {
      _showStateInfo = value;
      notifyListeners();
    }
  }

  set showGrid(bool value) {
    if (_showGrid != value) {
      _showGrid = value;
      notifyListeners();
    }
  }

  set show3DEffect(bool value) {
    if (_show3DEffect != value) {
      _show3DEffect = value;
      notifyListeners();
    }
  }

  set showMinimap(bool value) {
    if (_showMinimap != value) {
      _showMinimap = value;
      notifyListeners();
    }
  }

  set enablePhysics(bool value) {
    if (_enablePhysics != value) {
      _enablePhysics = value;
      notifyListeners();
    }
  }

  set showStatistics(bool value) {
    if (_showStatistics != value) {
      _showStatistics = value;
      notifyListeners();
    }
  }

  set edgeBundling(double value) {
    final clampedValue = value.clamp(0.0, 1.0);
    if (_edgeBundling != clampedValue) {
      _edgeBundling = clampedValue;
      notifyListeners();
    }
  }

  set highlightColor(Color value) {
    if (_highlightColor != value) {
      _highlightColor = value;
      notifyListeners();
    }
  }

  // State management methods
  void selectState(String? state) {
    if (_selectedState != state) {
      _selectedState = state;
      if (state != null) {
        _animationController.startStateAnimation(state, _animationType);
      }
      notifyListeners();
    }
  }

  void hoverState(String? state) {
    if (_hoveredState != state) {
      _hoveredState = state;
      notifyListeners();
    }
  }

  void highlightStates(Set<String> states) {
    if (_highlightedStates != states) {
      _highlightedStates = Set.from(states);
      for (final state in states) {
        _animationController.startStateAnimation(state, _animationType);
      }
      notifyListeners();
    }
  }

  void highlightTransitions(Set<String> transitions) {
    if (_highlightedTransitions != transitions) {
      _highlightedTransitions = Set.from(transitions);
      for (final transition in transitions) {
        _animationController.startTransitionAnimation(transition, _animationType);
      }
      notifyListeners();
    }
  }

  void addHighlightedState(String state) {
    if (!_highlightedStates.contains(state)) {
      _highlightedStates.add(state);
      _animationController.startStateAnimation(state, _animationType);
      notifyListeners();
    }
  }

  void removeHighlightedState(String state) {
    if (_highlightedStates.contains(state)) {
      _highlightedStates.remove(state);
      notifyListeners();
    }
  }

  void clearHighlights() {
    if (_highlightedStates.isNotEmpty || _highlightedTransitions.isNotEmpty) {
      _highlightedStates.clear();
      _highlightedTransitions.clear();
      notifyListeners();
    }
  }

  // Manual positioning methods
  void setStatePosition(String state, Offset position) {
    _manualPositions[state] = position;
    notifyListeners();
  }

  void removeStatePosition(String state) {
    if (_manualPositions.containsKey(state)) {
      _manualPositions.remove(state);
      notifyListeners();
    }
  }

  void clearManualPositions() {
    if (_manualPositions.isNotEmpty) {
      _manualPositions.clear();
      notifyListeners();
    }
  }

  // Customization methods
  void setStateColor(String state, Color color) {
    _customStateColors[state] = color;
    notifyListeners();
  }

  void removeStateColor(String state) {
    if (_customStateColors.containsKey(state)) {
      _customStateColors.remove(state);
      notifyListeners();
    }
  }

  void setStateWeight(String state, double weight) {
    _stateWeights[state] = weight.clamp(0.1, 5.0);
    notifyListeners();
  }

  void removeStateWeight(String state) {
    if (_stateWeights.containsKey(state)) {
      _stateWeights.remove(state);
      notifyListeners();
    }
  }

  // Zoom and pan methods
  void zoomIn([double factor = 1.2]) {
    zoomLevel = _zoomLevel * factor;
  }

  void zoomOut([double factor = 0.8]) {
    zoomLevel = _zoomLevel * factor;
  }

  void resetZoom() {
    zoomLevel = 1.0;
  }

  void pan(Offset delta) {
    panOffset = _panOffset + delta;
  }

  void resetPan() {
    panOffset = Offset.zero;
  }

  void resetView() {
    resetZoom();
    resetPan();
  }

  // Animation methods
  void _setupAnimationTimer() {
    _animationTimer?.cancel();
    if (_animationType != AnimationType.none) {
      _animationTimer = Timer.periodic(
        const Duration(milliseconds: 16), // ~60 FPS
        (timer) {
          _animationController.update();
          notifyListeners();
        },
      );
    }
  }

  void _triggerLayoutAnimation() {
    if (_animationType != AnimationType.none) {
      // Animate all states when layout changes
      for (final state in _highlightedStates) {
        _animationController.startStateAnimation(state, _animationType);
      }
    }
  }

  void _triggerThemeAnimation() {
    if (_animationType != AnimationType.none) {
      // Animate theme transition
      for (final state in _highlightedStates) {
        _animationController.startStateAnimation(state, AnimationType.fade);
      }
    }
  }

  void startSimulationAnimation(List<String> path) {
    clearHighlights();
    for (int i = 0; i < path.length; i++) {
      Timer(Duration(milliseconds: i * 500), () {
        highlightStates({path[i]});
        if (i < path.length - 1) {
          final transition = '${path[i]}->${path[i + 1]}';
          highlightTransitions({transition});
        }
      });
    }
  }

  // Preset configurations
  void applyPreset(GraphPreset preset) {
    switch (preset) {
      case GraphPreset.minimal:
        _theme = GraphTheme.minimal;
        _show3DEffect = false;
        _showGrid = false;
        _showMinimap = false;
        _showStatistics = false;
        _animationType = AnimationType.none;
        break;
      case GraphPreset.modern:
        _theme = GraphTheme.dark;
        _show3DEffect = true;
        _showGrid = true;
        _showMinimap = true;
        _showStatistics = true;
        _animationType = AnimationType.fade;
        break;
      case GraphPreset.interactive:
        _theme = GraphTheme.colorful;
        _enablePhysics = true;
        _animationType = AnimationType.bounce;
        _showTransitionLabels = true;
        _showStateInfo = true;
        break;
      case GraphPreset.academic:
        _theme = GraphTheme.light;
        _layoutType = GraphLayoutType.hierarchical;
        _showStatistics = true;
        _showStateInfo = true;
        _show3DEffect = false;
        break;
      case GraphPreset.presentation:
        _theme = GraphTheme.contrast;
        _nodeSize = 40.0;
        _show3DEffect = true;
        _animationType = AnimationType.scale;
        _showGrid = false;
        break;
    }
    notifyListeners();
  }

  // Export and import methods
  Map<String, dynamic> exportConfiguration() {
    final config = {
      'layoutType': _layoutType.name,
      'theme': _theme.name,
      'animationType': _animationType.name,
      'nodeSize': _nodeSize,
      'zoomLevel': _zoomLevel,
      'panOffset': {'dx': _panOffset.dx, 'dy': _panOffset.dy},
      'showTransitionLabels': _showTransitionLabels,
      'showStateInfo': _showStateInfo,
      'showGrid': _showGrid,
      'show3DEffect': _show3DEffect,
      'showMinimap': _showMinimap,
      'enablePhysics': _enablePhysics,
      'showStatistics': _showStatistics,
      'edgeBundling': _edgeBundling,
      'highlightColor': _highlightColor.value,
      'manualPositions': _manualPositions.map(
        (key, value) => MapEntry(key, {'dx': value.dx, 'dy': value.dy}),
      ),
      'customStateColors': _customStateColors.map(
        (key, value) => MapEntry(key, value.value),
      ),
      'stateWeights': _stateWeights,
    };
    
    _lastExportData = config;
    return config;
  }

  void importConfiguration(Map<String, dynamic> config) {
    try {
      _layoutType = GraphLayoutType.values.firstWhere(
        (e) => e.name == config['layoutType'],
        orElse: () => GraphLayoutType.circular,
      );
      
      _theme = GraphTheme.values.firstWhere(
        (e) => e.name == config['theme'],
        orElse: () => GraphTheme.light,
      );
      
      _animationType = AnimationType.values.firstWhere(
        (e) => e.name == config['animationType'],
        orElse: () => AnimationType.none,
      );
      
      _nodeSize = (config['nodeSize'] as num?)?.toDouble() ?? 30.0;
      _zoomLevel = (config['zoomLevel'] as num?)?.toDouble() ?? 1.0;
      
      final panData = config['panOffset'] as Map<String, dynamic>?;
      if (panData != null) {
        _panOffset = Offset(
          (panData['dx'] as num?)?.toDouble() ?? 0.0,
          (panData['dy'] as num?)?.toDouble() ?? 0.0,
        );
      }
      
      _showTransitionLabels = config['showTransitionLabels'] as bool? ?? true;
      _showStateInfo = config['showStateInfo'] as bool? ?? true;
      _showGrid = config['showGrid'] as bool? ?? false;
      _show3DEffect = config['show3DEffect'] as bool? ?? false;
      _showMinimap = config['showMinimap'] as bool? ?? false;
      _enablePhysics = config['enablePhysics'] as bool? ?? false;
      _showStatistics = config['showStatistics'] as bool? ?? false;
      _edgeBundling = (config['edgeBundling'] as num?)?.toDouble() ?? 0.0;
      
      final colorValue = config['highlightColor'] as int?;
      if (colorValue != null) {
        _highlightColor = Color(colorValue);
      }
      
      final positions = config['manualPositions'] as Map<String, dynamic>?;
      if (positions != null) {
        _manualPositions = positions.map((key, value) {
          final pos = value as Map<String, dynamic>;
          return MapEntry(
            key,
            Offset(
              (pos['dx'] as num?)?.toDouble() ?? 0.0,
              (pos['dy'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        });
      }
      
      final colors = config['customStateColors'] as Map<String, dynamic>?;
      if (colors != null) {
        _customStateColors = colors.map((key, value) {
          return MapEntry(key, Color(value as int));
        });
      }
      
      final weights = config['stateWeights'] as Map<String, dynamic>?;
      if (weights != null) {
        _stateWeights = weights.map((key, value) {
          return MapEntry(key, (value as num).toDouble());
        });
      }
      
      _setupAnimationTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing configuration: $e');
    }
  }

  // Performance methods
  void optimizeForPerformance() {
    _animationType = AnimationType.none;
    _show3DEffect = false;
    _enablePhysics = false;
    _showMinimap = false;
    _edgeBundling = 0.0;
    notifyListeners();
  }

  void optimizeForQuality() {
    _show3DEffect = true;
    _animationType = AnimationType.fade;
    _showMinimap = true;
    _edgeBundling = 0.5;
    notifyListeners();
  }

  // Search and filter methods
  List<String> searchStates(String query, List<String> allStates) {
    if (query.isEmpty) return allStates;
    return allStates.where((state) =>
        state.toLowerCase().contains(query.toLowerCase())).toList();
  }

  void highlightSearchResults(String query, List<String> allStates) {
    final results = searchStates(query, allStates);
    highlightStates(results.toSet());
  }

  // Validation methods
  bool validateConfiguration() {
    return _nodeSize >= 10.0 &&
           _nodeSize <= 100.0 &&
           _zoomLevel >= 0.1 &&
           _zoomLevel <= 5.0 &&
           _edgeBundling >= 0.0 &&
           _edgeBundling <= 1.0;
  }

  // Cleanup
  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }
}

// Graph Preset Enum
enum GraphPreset {
  minimal('مینیمال'),
  modern('مدرن'),
  interactive('تعاملی'),
  academic('آکادمیک'),
  presentation('ارائه');

  const GraphPreset(this.displayName);
  final String displayName;
}

// Advanced Graph Widget
class AdvancedGraphWidget extends StatefulWidget {
  final dynamic automaton;
  final GraphWidgetController? controller;
  final VoidCallback? onStateSelected;
  final VoidCallback? onLayoutChanged;
  final bool enableGestures;
  final double? width;
  final double? height;

  const AdvancedGraphWidget({
    Key? key,
    required this.automaton,
    this.controller,
    this.onStateSelected,
    this.onLayoutChanged,
    this.enableGestures = true,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<AdvancedGraphWidget> createState() => _AdvancedGraphWidgetState();
}

class _AdvancedGraphWidgetState extends State<AdvancedGraphWidget>
    with TickerProviderStateMixin {
  late GraphWidgetController _controller;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GraphWidgetController();
    _controller.addListener(_onControllerChanged);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _scaleController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
    widget.onLayoutChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: _controller.theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: _controller.show3DEffect
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: widget.enableGestures
            ? _buildGestureDetector()
            : _buildCustomPaint(),
      ),
    );
  }

  Widget _buildGestureDetector() {
    return GestureDetector(
      onScaleStart: (details) {
        _scaleController.forward();
      },
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          _controller.zoomLevel = (_controller.zoomLevel * details.scale)
              .clamp(0.1, 5.0);
        }
        if (details.focalPointDelta != Offset.zero) {
          _controller.pan(details.focalPointDelta);
        }
      },
      onScaleEnd: (details) {
        _scaleController.reverse();
      },
      onTapUp: (details) {
        _handleTap(details.localPosition);
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildCustomPaint(),
          );
        },
      ),
    );
  }

  Widget _buildCustomPaint() {
    return CustomPaint(
      painter: AdvancedAutomatonPainter(
        automaton: widget.automaton,
        selectedState: _controller.selectedState,
        hoveredState: _controller.hoveredState,
        highlightedStates: _controller.highlightedStates,
        highlightedTransitions: _controller.highlightedTransitions,
        layoutType: _controller.layoutType,
        manualPositions: _controller.manualPositions,
        nodeSize: _controller.nodeSize,
        theme: _controller.theme,
        showTransitionLabels: _controller.showTransitionLabels,
        showStateInfo: _controller.showStateInfo,
        highlightColor: _controller.highlightColor,
        animationController: _controller.animationController,
        animationType: _controller.animationType,
        showGrid: _controller.showGrid,
        show3DEffect: _controller.show3DEffect,
        zoomLevel: _controller.zoomLevel,
        panOffset: _controller.panOffset,
        showMinimap: _controller.showMinimap,
        customStateColors: _controller.customStateColors,
        stateWeights: _controller.stateWeights,
        enablePhysics: _controller.enablePhysics,
        edgeBundling: _controller.edgeBundling,
        showStatistics: _controller.showStatistics,
      ),
      size: Size.infinite,
    );
  }

  void _handleTap(Offset position) {
    widget.onStateSelected?.call();
  }
}