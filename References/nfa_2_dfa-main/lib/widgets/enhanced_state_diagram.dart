import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state_diagram.dart' as original;
import '../models/nfa.dart';
import '../models/dfa.dart';

extension StateDiagramConfigExtension on original.StateDiagramConfig {
  original.StateDiagramConfig copyWith({
    double? nodeSeparation,
    double? levelSeparation,
    original.LayoutDirection? layoutDirection,
    double? nodeSize,
    double? fontSize,
    double? edgeWidth,
    double? boundaryMargin,
    double? minScale,
    double? maxScale,
    Color? stateColor,
    Color? startStateColor,
    Color? finalStateColor,
    Color? edgeColor,
    Color? selectedColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? backgroundColor,
    Color? gridColor,
    Duration? animationDuration,
    Curve? animationCurve,
    Color? transitionColor,
    Color? textColor,
  }) {
    return original.StateDiagramConfig(
      nodeSeparation: nodeSeparation ?? this.nodeSeparation,
      levelSeparation: levelSeparation ?? this.levelSeparation,
      layoutDirection: layoutDirection ?? this.layoutDirection,
      nodeSize: nodeSize ?? this.nodeSize,
      fontSize: fontSize ?? this.fontSize,
      edgeWidth: edgeWidth ?? this.edgeWidth,
      boundaryMargin: boundaryMargin ?? this.boundaryMargin,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      stateColor: stateColor ?? this.stateColor,
      startStateColor: startStateColor ?? this.startStateColor,
      finalStateColor: finalStateColor ?? this.finalStateColor,
      edgeColor: transitionColor ?? edgeColor ?? this.edgeColor,
      selectedColor: selectedColor ?? this.selectedColor,
      hoverColor: hoverColor ?? this.hoverColor,
      highlightColor: highlightColor ?? this.highlightColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridColor: gridColor ?? this.gridColor,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }
}

/// Enhanced State Diagram with all advanced features
class EnhancedStateDiagram extends StatefulWidget {
  // Core properties
  final dynamic automaton;
  final String? title;
  final String? description;

  // Feature toggles
  final bool enablePerformanceOptimization;
  final bool enableAdvancedInteractions;
  final bool enableCustomThemes;
  final bool enableLayoutAlgorithms;
  final bool enableMinimap;
  final bool enableAnimations;
  final bool enableKeyboardShortcuts;
  final bool enableContextMenu;
  final bool enableMultiSelection;
  final bool enableDragAndDrop;

  // Configuration
  final EnhancedDiagramConfig config;
  final DiagramThemeData? customTheme;
  final LayoutAlgorithmType layoutAlgorithm;
  final AnimationSettings animationSettings;
  final PerformanceSettings performanceSettings;

  // Callbacks
  final Function(String state)? onStateSelected;
  final Function(List<String> states)? onMultiStateSelected;
  final Function(String from, String to, String symbol)? onTransitionSelected;
  final Function(String state, Offset position)? onStateMoved;
  final Function(String action)? onKeyboardShortcut;
  final Function(BuildContext context, String state)? onContextMenuRequested;
  final Function(Map<String, dynamic> analytics)? onAnalyticsUpdate;

  // UI customization
  final Widget? headerWidget;
  final Widget? footerWidget;
  final List<Widget>? customToolbarItems;
  final bool showToolbar;
  final bool showStatusBar;
  final bool showAnalyticsPanel;

  const EnhancedStateDiagram({
    super.key,
    required this.automaton,
    this.title,
    this.description,

    // Feature toggles
    this.enablePerformanceOptimization = true,
    this.enableAdvancedInteractions = true,
    this.enableCustomThemes = true,
    this.enableLayoutAlgorithms = true,
    this.enableMinimap = false,
    this.enableAnimations = true,
    this.enableKeyboardShortcuts = true,
    this.enableContextMenu = true,
    this.enableMultiSelection = true,
    this.enableDragAndDrop = true,

    // Configuration
    this.config = const EnhancedDiagramConfig(),
    this.customTheme,
    this.layoutAlgorithm = LayoutAlgorithmType.sugiyama,
    this.animationSettings = const AnimationSettings(),
    this.performanceSettings = const PerformanceSettings(),

    // Callbacks
    this.onStateSelected,
    this.onMultiStateSelected,
    this.onTransitionSelected,
    this.onStateMoved,
    this.onKeyboardShortcut,
    this.onContextMenuRequested,
    this.onAnalyticsUpdate,

    // UI customization
    this.headerWidget,
    this.footerWidget,
    this.customToolbarItems,
    this.showToolbar = true,
    this.showStatusBar = true,
    this.showAnalyticsPanel = false,
  });

  @override
  State<EnhancedStateDiagram> createState() => _EnhancedStateDiagramState();
}

class _EnhancedStateDiagramState extends State<EnhancedStateDiagram>
    with TickerProviderStateMixin {
  // Controllers for each enhancement
  late PerformanceOptimizer _performanceOptimizer;
  late DiagramThemeManager _themeManager;
  late LayoutAlgorithmManager _layoutManager;
  late AdvancedInteractionManager _interactionManager;
  late DiagramMinimapController _minimapController;
  late AnimationSystemManager _animationManager;

  // State management
  late EnhancedDiagramState _diagramState;
  final FocusNode _focusNode = FocusNode();

  // Analytics
  final Map<String, dynamic> _analytics = {};
  DateTime? _lastInteractionTime;
  bool _showAnalyticsPanel = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeState();
    _setupKeyboardListeners();
    _startAnalyticsTracking();
  }

  void _initializeControllers() {
    // Performance optimization
    if (widget.enablePerformanceOptimization) {
      _performanceOptimizer = PerformanceOptimizer(
        settings: widget.performanceSettings,
        automaton: widget.automaton,
      );
    }

    // Theme management
    if (widget.enableCustomThemes) {
      _themeManager = DiagramThemeManager(
        initialTheme: widget.customTheme,
        config: widget.config,
      );
    }

    // Layout algorithms
    if (widget.enableLayoutAlgorithms) {
      _layoutManager = LayoutAlgorithmManager(
        algorithm: widget.layoutAlgorithm,
        automaton: widget.automaton,
      );
    }

    // Advanced interactions
    if (widget.enableAdvancedInteractions) {
      _interactionManager = AdvancedInteractionManager(
        enableMultiSelection: widget.enableMultiSelection,
        enableDragAndDrop: widget.enableDragAndDrop,
        enableContextMenu: widget.enableContextMenu,
        onStateSelected: _handleStateSelection,
        onMultiStateSelected: _handleMultiStateSelection,
        onStateMoved: _handleStateMoved,
        onContextMenuRequested: _handleContextMenuRequested,
      );
    }

    // Minimap
    if (widget.enableMinimap) {
      _minimapController = DiagramMinimapController(
        automaton: widget.automaton,
      );
    }

    // Animations
    if (widget.enableAnimations) {
      _animationManager = AnimationSystemManager(
        vsync: this,
        settings: widget.animationSettings,
      );
    }
  }

  void _initializeState() {
    _diagramState = EnhancedDiagramState(
      automaton: widget.automaton,
      selectedStates: <String>{},
      hoveredState: null,
      draggedState: null,
      currentLayout: widget.layoutAlgorithm,
      isLoading: false,
    );
  }

  void _setupKeyboardListeners() {
    if (widget.enableKeyboardShortcuts) {
      _focusNode.requestFocus();
    }
  }

  void _startAnalyticsTracking() {
    _analytics['creation_time'] = DateTime.now().toIso8601String();
    _analytics['automaton_type'] = widget.automaton.runtimeType.toString();
    _analytics['enabled_features'] = _getEnabledFeatures();
    _updateAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: widget.enableKeyboardShortcuts ? _handleKeyEvent : null,
      child: Column(
        children: [
          if (widget.headerWidget != null) widget.headerWidget!,
          if (widget.showToolbar) _buildToolbar(),
          Expanded(
            child: _buildMainContent(),
          ),
          if (widget.showStatusBar) _buildStatusBar(),
          if (widget.footerWidget != null) widget.footerWidget!,
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 16),
          ],

          const Spacer(),

          // Layout algorithm selector
          if (widget.enableLayoutAlgorithms) ...[
            _buildLayoutSelector(),
            const SizedBox(width: 8),
          ],

          // Theme selector
          if (widget.enableCustomThemes) ...[
            _buildThemeSelector(),
            const SizedBox(width: 8),
          ],

          // Custom toolbar items
          if (widget.customToolbarItems != null) ...[
            ...widget.customToolbarItems!,
            const SizedBox(width: 8),
          ],

          // Analytics toggle
          if (widget.showAnalyticsPanel) ...[
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () => _toggleAnalyticsPanel(),
              tooltip: 'Show Analytics',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLayoutSelector() {
    return DropdownButton<LayoutAlgorithmType>(
      value: _diagramState.currentLayout,
      onChanged: (value) {
        if (value != null) {
          _changeLayoutAlgorithm(value);
        }
      },
      items: LayoutAlgorithmType.values.map((algorithm) {
        return DropdownMenuItem(
          value: algorithm,
          child: Text(_getLayoutAlgorithmName(algorithm)),
        );
      }).toList(),
    );
  }

  Widget _buildThemeSelector() {
    return PopupMenuButton<DiagramThemeData>(
      icon: const Icon(Icons.palette),
      tooltip: 'Select Theme',
      onSelected: (theme) {
        if (widget.enableCustomThemes) {
          _themeManager.setTheme(theme);
          setState(() {});
        }
      },
      itemBuilder: (context) {
        return DiagramThemePresets.getAllThemes().map((theme) {
          return PopupMenuItem(
            value: theme,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.stateColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(theme.name),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildMainContent() {
    return Row(
      children: [
        // Main diagram area
        Expanded(
          child: _buildEnhancedDiagram(),
        ),

        // Analytics panel
        if (widget.showAnalyticsPanel && _shouldShowAnalyticsPanel())
          _buildAnalyticsPanel(),
      ],
    );
  }

  Widget _buildEnhancedDiagram() {
    Widget diagram = original.StateDiagram(
      automaton: widget.automaton,
      config: _getEffectiveConfig(),
      onStateSelected: _handleBasicStateSelection,
      onTransitionSelected: widget.onTransitionSelected,
      showTransitionLabels: widget.config.showTransitionLabels,
      enableAnimation: widget.enableAnimations,
      showGrid: widget.config.showGrid,
      enableZoom: widget.config.enableZoom,
      enablePan: widget.config.enablePan,
      highlightedState: _diagramState.selectedStates.isNotEmpty
          ? _diagramState.selectedStates.first
          : null,
      showTooltips: widget.config.showTooltips,
    );

    // Apply performance optimization
    if (widget.enablePerformanceOptimization) {
      diagram = _performanceOptimizer.optimize(diagram);
    }

    // Apply theme
    if (widget.enableCustomThemes) {
      diagram = _themeManager.applyTheme(diagram);
    }

    // Apply layout algorithm
    if (widget.enableLayoutAlgorithms) {
      diagram = _layoutManager.applyLayout(diagram);
    }

    // Apply advanced interactions
    if (widget.enableAdvancedInteractions) {
      diagram = _interactionManager.enhance(diagram);
    }

    // Apply animations
    if (widget.enableAnimations) {
      diagram = _animationManager.animate(diagram);
    }

    // Add minimap overlay
    if (widget.enableMinimap) {
      diagram = Stack(
        children: [
          diagram,
          Positioned(
            bottom: 16,
            right: 16,
            child: _minimapController.buildMinimap(context),
          ),
        ],
      );
    }

    return diagram;
  }

  Widget _buildStatusBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _getStatusText(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          if (_diagramState.isLoading) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Processing...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsPanel() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Analytics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _analytics.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value.toString(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Event handlers
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyA:
          if (isCtrlPressed) {
            _selectAllStates();
            return KeyEventResult.handled;
          }
          break;
        case LogicalKeyboardKey.escape:
          _clearSelection();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.delete:
          _deleteSelectedStates();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyZ:
          if (isCtrlPressed) {
            _undo();
            return KeyEventResult.handled;
          }
          break;
        case LogicalKeyboardKey.keyY:
          if (isCtrlPressed) {
            _redo();
            return KeyEventResult.handled;
          }
          break;
      }

      widget.onKeyboardShortcut?.call(event.logicalKey.keyLabel);
    }

    return KeyEventResult.ignored;
  }

  void _handleBasicStateSelection(String state) {
    _updateLastInteractionTime();
    _handleStateSelection(state);
  }

  void _handleStateSelection(String state) {
    setState(() {
      if (_diagramState.selectedStates.contains(state)) {
        _diagramState.selectedStates.remove(state);
      } else {
        if (!widget.enableMultiSelection) {
          _diagramState.selectedStates.clear();
        }
        _diagramState.selectedStates.add(state);
      }
    });

    widget.onStateSelected?.call(state);
    if (widget.enableMultiSelection) {
      widget.onMultiStateSelected?.call(_diagramState.selectedStates.toList());
    }

    _updateAnalytics();
  }

  void _handleMultiStateSelection(List<String> states) {
    setState(() {
      _diagramState.selectedStates = states.toSet();
    });

    widget.onMultiStateSelected?.call(states);
    _updateAnalytics();
  }

  void _handleStateMoved(String state, Offset position) {
    _updateLastInteractionTime();
    widget.onStateMoved?.call(state, position);
    _updateAnalytics();
  }

  void _handleContextMenuRequested(String state) {
    if (widget.onContextMenuRequested != null) {
      widget.onContextMenuRequested!(context, state);
    }
  }

  // Helper methods
  void _changeLayoutAlgorithm(LayoutAlgorithmType algorithm) {
    setState(() {
      _diagramState.currentLayout = algorithm;
      _diagramState.isLoading = true;
    });

    if (widget.enableLayoutAlgorithms) {
      _layoutManager.changeAlgorithm(algorithm).then((_) {
        setState(() {
          _diagramState.isLoading = false;
        });
      });
    }

    _updateAnalytics();
  }

  void _selectAllStates() {
    setState(() {
      _diagramState.selectedStates = _getAllStateNames().toSet();
    });

    if (widget.enableMultiSelection) {
      widget.onMultiStateSelected?.call(_diagramState.selectedStates.toList());
    }

    _updateAnalytics();
  }

  void _clearSelection() {
    setState(() {
      _diagramState.selectedStates.clear();
    });

    if (widget.enableMultiSelection) {
      widget.onMultiStateSelected?.call([]);
    }
  }

  void _deleteSelectedStates() {
    // Implementation depends on whether automaton is mutable
    // This is a placeholder for the functionality
    _updateAnalytics();
  }

  void _undo() {
    // Implementation for undo functionality
    _updateAnalytics();
  }

  void _redo() {
    // Implementation for redo functionality
    _updateAnalytics();
  }

  void _toggleAnalyticsPanel() {
    setState(() {
      _showAnalyticsPanel = !_showAnalyticsPanel;
    });
  }

  void _updateLastInteractionTime() {
    _lastInteractionTime = DateTime.now();
  }

  void _updateAnalytics() {
    _analytics['selected_states_count'] = _diagramState.selectedStates.length;
    _analytics['current_layout'] = _diagramState.currentLayout.toString();
    _analytics['last_interaction'] = _lastInteractionTime?.toIso8601String();
    _analytics['total_interactions'] =
        (_analytics['total_interactions'] ?? 0) + 1;

    widget.onAnalyticsUpdate?.call(Map.from(_analytics));
  }

  original.StateDiagramConfig _getEffectiveConfig() {
    var config = widget.config.baseConfig;

    if (widget.enableCustomThemes && _themeManager.currentTheme != null) {
      final theme = _themeManager.currentTheme!;

      // Use copyWith method from extension
      config = config.copyWith(
        stateColor: theme.stateColor,
        startStateColor: theme.startStateColor,
        finalStateColor: theme.finalStateColor,
        backgroundColor: theme.backgroundColor,
        transitionColor: theme.transitionColor,
        nodeSize: theme.stateRadius * 2, // Convert radius to diameter
        edgeWidth: theme.strokeWidth,
      );
    }

    return config;
  }

  String _getStatusText() {
    final stateCount = _getAllStateNames().length;
    final selectedCount = _diagramState.selectedStates.length;

    if (selectedCount > 0) {
      return '$selectedCount of $stateCount states selected';
    } else {
      return '$stateCount states';
    }
  }

  String _getLayoutAlgorithmName(LayoutAlgorithmType algorithm) {
    switch (algorithm) {
      case LayoutAlgorithmType.sugiyama:
        return 'Hierarchical';
      case LayoutAlgorithmType.forceDirected:
        return 'Force Directed';
      case LayoutAlgorithmType.circular:
        return 'Circular';
      case LayoutAlgorithmType.grid:
        return 'Grid';
      case LayoutAlgorithmType.tree:
        return 'Tree';
      case LayoutAlgorithmType.random:
        return 'Random';
    }
  }

  List<String> _getAllStateNames() {
    if (widget.automaton is NFA) {
      return (widget.automaton as NFA).states.toList();
    } else if (widget.automaton is DFA) {
      final dfa = widget.automaton as DFA;
      return dfa.states.map((s) => dfa.getStateName(s)).toList();
    }
    return [];
  }

  List<String> _getEnabledFeatures() {
    final features = <String>[];
    if (widget.enablePerformanceOptimization) features.add('performance');
    if (widget.enableAdvancedInteractions) features.add('interactions');
    if (widget.enableCustomThemes) features.add('themes');
    if (widget.enableLayoutAlgorithms) features.add('layouts');
    if (widget.enableMinimap) features.add('minimap');
    if (widget.enableAnimations) features.add('animations');
    return features;
  }

  bool _shouldShowAnalyticsPanel() {
    return _showAnalyticsPanel;
  }

  @override
  void dispose() {
    _focusNode.dispose();

    if (widget.enablePerformanceOptimization) {
      _performanceOptimizer.dispose();
    }
    if (widget.enableCustomThemes) {
      _themeManager.dispose();
    }
    if (widget.enableLayoutAlgorithms) {
      _layoutManager.dispose();
    }
    if (widget.enableAdvancedInteractions) {
      _interactionManager.dispose();
    }
    if (widget.enableMinimap) {
      _minimapController.dispose();
    }
    if (widget.enableAnimations) {
      _animationManager.dispose();
    }

    super.dispose();
  }
}

/// Configuration class for Enhanced State Diagram
class EnhancedDiagramConfig {
  final original.StateDiagramConfig baseConfig;
  final bool showTransitionLabels;
  final bool showGrid;
  final bool enableZoom;
  final bool enablePan;
  final bool showTooltips;
  final bool enableDebugMode;
  final Duration debounceTime;
  final int maxStatesForOptimization;

  const EnhancedDiagramConfig({
    this.baseConfig = const original.StateDiagramConfig(),
    this.showTransitionLabels = true,
    this.showGrid = false,
    this.enableZoom = true,
    this.enablePan = true,
    this.showTooltips = true,
    this.enableDebugMode = false,
    this.debounceTime = const Duration(milliseconds: 300),
    this.maxStatesForOptimization = 100,
  });

  // Added copyWith method
  EnhancedDiagramConfig copyWith({
    original.StateDiagramConfig? baseConfig,
    bool? showTransitionLabels,
    bool? showGrid,
    bool? enableZoom,
    bool? enablePan,
    bool? showTooltips,
    bool? enableDebugMode,
    Duration? debounceTime,
    int? maxStatesForOptimization,
  }) {
    return EnhancedDiagramConfig(
      baseConfig: baseConfig ?? this.baseConfig,
      showTransitionLabels: showTransitionLabels ?? this.showTransitionLabels,
      showGrid: showGrid ?? this.showGrid,
      enableZoom: enableZoom ?? this.enableZoom,
      enablePan: enablePan ?? this.enablePan,
      showTooltips: showTooltips ?? this.showTooltips,
      enableDebugMode: enableDebugMode ?? this.enableDebugMode,
      debounceTime: debounceTime ?? this.debounceTime,
      maxStatesForOptimization:
          maxStatesForOptimization ?? this.maxStatesForOptimization,
    );
  }
}

/// State management for Enhanced Diagram
class EnhancedDiagramState {
  final dynamic automaton;
  Set<String> selectedStates;
  String? hoveredState;
  String? draggedState;
  LayoutAlgorithmType currentLayout;
  bool isLoading;

  EnhancedDiagramState({
    required this.automaton,
    required this.selectedStates,
    this.hoveredState,
    this.draggedState,
    required this.currentLayout,
    required this.isLoading,
  });
}

/// Layout algorithm types
enum LayoutAlgorithmType {
  sugiyama,
  forceDirected,
  circular,
  grid,
  tree,
  random,
}

/// Animation settings
class AnimationSettings {
  final Duration entranceAnimationDuration;
  final Duration highlightAnimationDuration;
  final Duration layoutTransitionDuration;
  final Curve animationCurve;
  final bool enablePathAnimation;
  final bool enableRippleEffects;

  const AnimationSettings({
    this.entranceAnimationDuration = const Duration(milliseconds: 1500),
    this.highlightAnimationDuration = const Duration(milliseconds: 1200),
    this.layoutTransitionDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeOutCubic,
    this.enablePathAnimation = true,
    this.enableRippleEffects = true,
  });
}

/// Performance settings
class PerformanceSettings {
  final bool enableVirtualization;
  final bool enableLazyLoading;
  final bool enableCaching;
  final int maxVisibleNodes;
  final int cacheSize;
  final Duration debounceTime;

  const PerformanceSettings({
    this.enableVirtualization = true,
    this.enableLazyLoading = true,
    this.enableCaching = true,
    this.maxVisibleNodes = 500,
    this.cacheSize = 1000,
    this.debounceTime = const Duration(milliseconds: 100),
  });
}

/// Theme data for diagrams
class DiagramThemeData {
  final String name;
  final Color stateColor;
  final Color startStateColor;
  final Color finalStateColor;
  final Color backgroundColor;
  final Color transitionColor;
  final Color textColor;
  final Color selectedStateColor;
  final Color hoveredStateColor;
  final double stateRadius;
  final double strokeWidth;

  const DiagramThemeData({
    required this.name,
    required this.stateColor,
    required this.startStateColor,
    required this.finalStateColor,
    required this.backgroundColor,
    required this.transitionColor,
    required this.textColor,
    required this.selectedStateColor,
    required this.hoveredStateColor,
    this.stateRadius = 30.0,
    this.strokeWidth = 2.0,
  });
}

/// Theme presets
class DiagramThemePresets {
  static const DiagramThemeData defaultTheme = DiagramThemeData(
    name: 'Default',
    stateColor: Colors.white,
    startStateColor: Colors.green,
    finalStateColor: Colors.red,
    backgroundColor: Colors.white,
    transitionColor: Colors.black,
    textColor: Colors.black,
    selectedStateColor: Colors.blue,
    hoveredStateColor: Colors.grey,
  );

  static const DiagramThemeData darkTheme = DiagramThemeData(
    name: 'Dark',
    stateColor: Color(0xFF2D2D2D),
    startStateColor: Color(0xFF4CAF50),
    finalStateColor: Color(0xFFF44336),
    backgroundColor: Color(0xFF121212),
    transitionColor: Colors.white,
    textColor: Colors.white,
    selectedStateColor: Color(0xFF2196F3),
    hoveredStateColor: Color(0xFF424242),
  );

  static List<DiagramThemeData> getAllThemes() {
    return [defaultTheme, darkTheme];
  }
}

/// Performance optimizer
class PerformanceOptimizer {
  final PerformanceSettings settings;
  final dynamic automaton;

  PerformanceOptimizer({
    required this.settings,
    required this.automaton,
  });

  Widget optimize(Widget widget) {
    // Apply performance optimizations
    return widget;
  }

  void dispose() {
    // Cleanup resources
  }
}

/// Diagram minimap controller
class DiagramMinimapController {
  final dynamic automaton;

  DiagramMinimapController({
    required this.automaton,
  });

  Widget buildMinimap(BuildContext context) {
    return Container(
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text('Minimap', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  void dispose() {
    // Cleanup resources
  }
}

/// Animation system manager
class AnimationSystemManager {
  final TickerProvider vsync;
  final AnimationSettings settings;
  late List<AnimationController> _controllers;

  AnimationSystemManager({
    required this.vsync,
    required this.settings,
  }) {
    _controllers = [];
  }

  Widget animate(Widget widget) {
    // Apply animations to widget
    return AnimatedContainer(
      duration: settings.entranceAnimationDuration,
      curve: settings.animationCurve,
      child: widget,
    );
  }

  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
  }
}

/// Theme manager
class DiagramThemeManager {
  DiagramThemeData? currentTheme;
  final EnhancedDiagramConfig config;

  DiagramThemeManager({
    DiagramThemeData? initialTheme,
    required this.config,
  }) : currentTheme = initialTheme ?? DiagramThemePresets.defaultTheme;

  void setTheme(DiagramThemeData theme) {
    currentTheme = theme;
  }

  Widget applyTheme(Widget widget) {
    // Apply theme to widget
    return widget;
  }

  void dispose() {
    // Cleanup resources
  }
}

/// Layout algorithm manager
class LayoutAlgorithmManager {
  LayoutAlgorithmType algorithm;
  final dynamic automaton;

  LayoutAlgorithmManager({
    required this.algorithm,
    required this.automaton,
  });

  Future<void> changeAlgorithm(LayoutAlgorithmType newAlgorithm) async {
    algorithm = newAlgorithm;
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Widget applyLayout(Widget widget) {
    return widget;
  }

  void dispose() {}
}

/// Advanced interaction manager
class AdvancedInteractionManager {
  final bool enableMultiSelection;
  final bool enableDragAndDrop;
  final bool enableContextMenu;
  final Function(String) onStateSelected;
  final Function(List<String>) onMultiStateSelected;
  final Function(String, Offset) onStateMoved;
  final Function(String) onContextMenuRequested;

  AdvancedInteractionManager({
    required this.enableMultiSelection,
    required this.enableDragAndDrop,
    required this.enableContextMenu,
    required this.onStateSelected,
    required this.onMultiStateSelected,
    required this.onStateMoved,
    required this.onContextMenuRequested,
  });

  Widget enhance(Widget widget) {
    return widget;
  }

  void dispose() {}
}
