import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import '../models/nfa.dart';
import '../models/dfa.dart';
import '../models/state_model.dart';
import 'graph_painter.dart';

enum GraphLayoutType {
  circular,
  hierarchical,
  force,
  grid,
  manual;

  IconData get icon {
    switch (this) {
      case GraphLayoutType.circular:
        return Icons.radio_button_unchecked;
      case GraphLayoutType.hierarchical:
        return Icons.account_tree;
      case GraphLayoutType.force:
        return Icons.scatter_plot;
      case GraphLayoutType.grid:
        return Icons.grid_view;
      case GraphLayoutType.manual:
        return Icons.pan_tool;
    }
  }

  String get name {
    switch (this) {
      case GraphLayoutType.circular:
        return 'دایره‌ای';
      case GraphLayoutType.hierarchical:
        return 'سلسله مراتبی';
      case GraphLayoutType.force:
        return 'نیرو محور';
      case GraphLayoutType.grid:
        return 'شبکه‌ای';
      case GraphLayoutType.manual:
        return 'دستی';
    }
  }
}

enum AnimationType { bounce, fade, slide, scale, none }

class GraphTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color nodeColor;
  final Color edgeColor;

  const GraphTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.nodeColor,
    required this.edgeColor,
  });

  static const GraphTheme light = GraphTheme(
    primaryColor: Colors.blue,
    backgroundColor: Colors.white,
    textColor: Colors.black,
    nodeColor: Colors.lightBlue,
    edgeColor: Colors.grey,
  );

  static const GraphTheme dark = GraphTheme(
    primaryColor: Colors.blueAccent,
    backgroundColor: Colors.black,
    textColor: Colors.white,
    nodeColor: Colors.blueGrey,
    edgeColor: Colors.grey,
  );
}

class GraphAnimationController {
  double value = 0.0;

  void update(double newValue) {
    value = newValue;
  }
}

class GraphVisualizationScreen extends StatefulWidget {
  final dynamic automaton; // Can be NFA or DFA
  final String title;

  const GraphVisualizationScreen({
    super.key,
    required this.automaton,
    this.title = 'نمایش گرافیکی اتوماتا',
  });

  @override
  State<GraphVisualizationScreen> createState() =>
      _GraphVisualizationScreenState();
}

class _GraphVisualizationScreenState extends State<GraphVisualizationScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _entryAnimationController;
  late AnimationController _simulationAnimationController;
  late AnimationController _highlightAnimationController;
  late GraphAnimationController _graphAnimationController;

  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _simulationProgress;
  late Animation<Color?> _highlightColor;

  // Interactive States
  double _scaleFactor = 1.0;
  Offset _panOffset = Offset.zero;
  String? _selectedState;
  String? _hoveredState;
  Set<String> _highlightedStates = {};
  Set<String> _highlightedTransitions = {};

  // Simulation
  bool _isSimulating = false;
  String _simulationInput = '';
  int _currentInputIndex = 0;
  List<String> _simulationPath = [];
  List<String> _currentStates = [];
  bool _simulationAccepted = false;

  // Layout and Visual Options
  GraphLayoutType _layoutType = GraphLayoutType.circular;
  Map<String, Offset> _manualPositions = {};
  Map<String, Offset> _calculatedPositions = {};
  bool _isDragging = false;
  String? _draggedState;

  bool _showTransitionLabels = true;
  bool _showStateInfo = true;
  double _nodeSize = 30.0;
  GraphTheme _currentTheme = GraphTheme.light;
  AnimationType _animationType = AnimationType.bounce;
  bool _showGrid = false;
  bool _show3DEffect = false;
  bool _showMinimap = false;
  Map<String, Color> _customStateColors = {};
  Map<String, double> _stateWeights = {};
  bool _enablePhysics = false;
  double _edgeBundling = 0.0;
  bool _showStatistics = false;

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateLayout());
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    _simulationAnimationController.dispose();
    _highlightAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _entryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _simulationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _simulationProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _simulationAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _highlightAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _highlightColor =
        ColorTween(
          begin: Colors.orange.shade300,
          end: Colors.orange.shade600,
        ).animate(
          CurvedAnimation(
            parent: _highlightAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _graphAnimationController = GraphAnimationController();

    _entryAnimationController.forward();
    _highlightAnimationController.repeat(reverse: true);
  }

  void _calculateLayout() {
    final states = _getStates();
    if (states.isEmpty || !mounted) return;

    final size = MediaQuery.of(context).size;

    switch (_layoutType) {
      case GraphLayoutType.circular:
        _calculateCircularLayout(states, size);
        break;
      case GraphLayoutType.hierarchical:
        _calculateHierarchicalLayout(states, size);
        break;
      case GraphLayoutType.force:
        _calculateForceLayout(states, size);
        break;
      case GraphLayoutType.grid:
        _calculateGridLayout(states, size);
        break;
      case GraphLayoutType.manual:
        // Positions are handled manually
        break;
      default:
        _calculateCircularLayout(states, size);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _calculateCircularLayout(List<String> states, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(center.dx, center.dy) * 0.6;
    _calculatedPositions.clear();

    if (states.length == 1) {
      _calculatedPositions[states[0]] = center;
      return;
    }

    for (int i = 0; i < states.length; i++) {
      final angle = (2 * math.pi * i) / states.length - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      _calculatedPositions[states[i]] = Offset(x, y);
    }
  }

  void _calculateHierarchicalLayout(List<String> states, Size size) {
    _calculatedPositions.clear();
    final startState = _getStartState();
    if (startState.isEmpty) {
      _calculateCircularLayout(states, size);
      return;
    }

    final levels = <int, List<String>>{};
    final visited = <String>{};
    final queue = [(startState, 0)];
    visited.add(startState);

    while (queue.isNotEmpty) {
      final (current, level) = queue.removeAt(0);
      levels.putIfAbsent(level, () => []).add(current);

      final transitions = _getTransitionsFromState(current);
      for (final transition in transitions) {
        final nextState = transition['to'] as String;
        if (!visited.contains(nextState)) {
          visited.add(nextState);
          queue.add((nextState, level + 1));
        }
      }
    }

    for (final state in states) {
      if (!visited.contains(state)) {
        levels.putIfAbsent(0, () => []).add(state);
      }
    }

    final maxLevel = levels.keys.isNotEmpty ? levels.keys.reduce(math.max) : 0;

    levels.forEach((level, statesInLevel) {
      final y = size.height / (maxLevel + 2) * (level + 1);
      for (int i = 0; i < statesInLevel.length; i++) {
        final x = size.width / (statesInLevel.length + 1) * (i + 1);
        _calculatedPositions[statesInLevel[i]] = Offset(x, y);
      }
    });
  }

  void _calculateForceLayout(List<String> states, Size size) {
    _calculateGridLayout(states, size);
  }

  void _calculateGridLayout(List<String> states, Size size) {
    _calculatedPositions.clear();
    if (states.isEmpty) return;

    final cols = math.sqrt(states.length).ceil();
    final rows = (states.length / cols).ceil();
    final cellWidth = size.width / (cols + 1);
    final cellHeight = size.height / (rows + 1);

    for (int i = 0; i < states.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      final x = cellWidth * (col + 1);
      final y = cellHeight * (row + 1);
      _calculatedPositions[states[i]] = Offset(x, y);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAdvancedAppBar(),
      body: Column(
        children: [
          _buildAdvancedControlPanel(),
          if (_isSimulating) _buildSimulationPanel(),
          Expanded(child: _buildInteractiveGraphView()),
        ],
      ),
      drawer: _buildSettingsDrawer(),
      floatingActionButton: _buildAdvancedFAB(),
      bottomNavigationBar: _buildBottomControls(),
    );
  }

  PreferredSizeWidget _buildAdvancedAppBar() {
    return AppBar(
      title: Text(widget.title),
      backgroundColor: _currentTheme.primaryColor,
      elevation: 4,
      actions: [
        IconButton(
          icon: const Icon(Icons.play_arrow_rounded),
          onPressed: _showSimulationDialog,
          tooltip: 'شبیه‌سازی ورودی',
        ),
        IconButton(
          icon: Icon(_layoutType.icon),
          onPressed: _showLayoutOptions,
          tooltip: 'تغییر چیدمان',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'تنظیمات',
        ),
      ],
    );
  }

  Widget _buildAdvancedControlPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _currentTheme.backgroundColor.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _selectedState != null
          ? _buildStateDetails()
          : _buildAutomatonInfo(),
    );
  }

  Widget _buildAutomatonInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoChip('حالات', '${_getStates().length}', Icons.bubble_chart),
        _buildInfoChip('الفبا', '${_getAlphabet().length}', Icons.translate),
        _buildInfoChip(
          'نوع',
          widget.automaton is NFA ? 'NFA' : 'DFA',
          Icons.device_hub,
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18, color: _currentTheme.primaryColor),
      label: Text('$label: $value'),
      backgroundColor: _currentTheme.primaryColor.withOpacity(0.1),
    );
  }

  Widget _buildStateDetails() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _currentTheme.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'حالت انتخاب شده: $_selectedState\n${_getStateInfo(_selectedState!)}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _currentTheme.textColor,
        ),
      ),
    );
  }

  Widget _buildSimulationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _currentTheme.primaryColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ورودی: $_simulationInput',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'موقعیت: $_currentInputIndex/${_simulationInput.length}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'حالات فعلی: ${_currentStates.join(', ')}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _simulationAccepted ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _simulationAccepted ? 'پذیرفته شده' : 'رد شده',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _currentInputIndex < _simulationInput.length
                    ? _nextStep
                    : null,
                child: const Text('قدم بعدی'),
              ),
              ElevatedButton(
                onPressed: _stopSimulation,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('توقف'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveGraphView() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onScaleStart: (details) {},
        onScaleUpdate: (details) {
          setState(() {
            _scaleFactor = math.max(
              0.5,
              math.min(3.0, _scaleFactor * details.scale),
            );
          });
        },
        onPanStart: (details) {
          final localPosition = (context.findRenderObject() as RenderBox?)
              ?.globalToLocal(details.globalPosition);
          if (localPosition != null && _layoutType == GraphLayoutType.manual) {
            _draggedState = _getStateAtPosition(localPosition);
            _isDragging = _draggedState != null;
          }
        },
        onPanUpdate: (details) {
          if (_isDragging && _draggedState != null) {
            setState(() {
              _manualPositions[_draggedState!] =
                  (_manualPositions[_draggedState!] ??
                      _getEffectivePositions()[_draggedState!]!) +
                  details.delta / _scaleFactor;
            });
          } else {
            setState(() {
              _panOffset += details.delta;
            });
          }
        },
        onPanEnd: (_) {
          _isDragging = false;
          _draggedState = null;
        },
        onTapDown: (details) {
          final localPosition = (context.findRenderObject() as RenderBox?)
              ?.globalToLocal(details.globalPosition);
          if (localPosition != null) {
            final state = _getStateAtPosition(localPosition);
            setState(() {
              _selectedState = _selectedState == state ? null : state;
            });
          }
        },
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Container(
            color: _currentTheme.backgroundColor,
            child: _buildSimpleGraph(),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleGraph() {
    return CustomPaint(
      painter: SimpleAutomatonPainter(
        states: _getStates(),
        transitions: _getAllTransitions(),
        positions: _getEffectivePositions(),
        selectedState: _selectedState,
        highlightedStates: _highlightedStates,
        nodeSize: _nodeSize,
        theme: _currentTheme,
        scaleFactor: _scaleFactor,
        panOffset: _panOffset,
        startState: _getStartState(),
        finalStates: _getFinalStates(),
      ),
      size: Size.infinite,
    );
  }

  Widget _buildSettingsDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: _currentTheme.primaryColor),
            child: const Text(
              'تنظیمات نمایش',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          SwitchListTile(
            title: const Text('نمایش برچسب انتقالات'),
            value: _showTransitionLabels,
            onChanged: (value) => setState(() => _showTransitionLabels = value),
          ),
          SwitchListTile(
            title: const Text('نمایش اطلاعات حالت'),
            value: _showStateInfo,
            onChanged: (value) => setState(() => _showStateInfo = value),
          ),
          ListTile(
            title: const Text('اندازه گره'),
            subtitle: Slider(
              value: _nodeSize,
              min: 20,
              max: 60,
              divisions: 8,
              onChanged: (value) => setState(() => _nodeSize = value),
            ),
          ),
          ListTile(
            title: const Text('نوع چیدمان'),
            subtitle: DropdownButton<GraphLayoutType>(
              value: _layoutType,
              isExpanded: true,
              items: GraphLayoutType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 16),
                      const SizedBox(width: 8),
                      Text(type.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _layoutType = value);
                  _calculateLayout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFAB() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "zoom_in",
          mini: true,
          onPressed: () =>
              setState(() => _scaleFactor = math.min(3.0, _scaleFactor * 1.2)),
          child: const Icon(Icons.zoom_in),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "zoom_out",
          mini: true,
          onPressed: () =>
              setState(() => _scaleFactor = math.max(0.5, _scaleFactor / 1.2)),
          child: const Icon(Icons.zoom_out),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "reset_view",
          onPressed: () => setState(() {
            _scaleFactor = 1.0;
            _panOffset = Offset.zero;
          }),
          child: const Icon(Icons.center_focus_strong),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calculateLayout,
            tooltip: 'محاسبه مجدد چیدمان',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _exportGraph,
            tooltip: 'ذخیره تصویر',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareGraph,
            tooltip: 'اشتراک‌گذاری',
          ),
        ],
      ),
    );
  }

  void _startSimulation() {
    if (_simulationInput.isEmpty) return;

    final alphabet = _getAlphabet().toSet();
    for (int i = 0; i < _simulationInput.length; i++) {
      if (!alphabet.contains(_simulationInput[i])) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('نماد "${_simulationInput[i]}" در الفبا موجود نیست'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    Set<String> initialStates = {_getStartState()};
    if (widget.automaton is NFA) {
      initialStates = _getEpsilonClosureForSet({
        _getStartState(),
      }, widget.automaton as NFA);
    }

    setState(() {
      _isSimulating = true;
      _currentInputIndex = 0;
      _currentStates = initialStates.toList()..sort();
      _simulationPath = [_currentStates.join(',')];
      _highlightedStates = initialStates;
      _highlightedTransitions = {};
      _checkAcceptance();
    });
  }

  void _nextStep() {
    if (_currentInputIndex >= _simulationInput.length) return;

    _simulationAnimationController.forward(from: 0);
    final currentSymbol = _simulationInput[_currentInputIndex];

    if (widget.automaton is NFA) {
      _simulateNFAStep(currentSymbol);
    } else if (widget.automaton is DFA) {
      _simulateDFAStep(currentSymbol);
    }

    setState(() {
      _currentInputIndex++;
      if (_currentInputIndex == _simulationInput.length) {
        _checkAcceptance();
      }
    });
  }

  void _simulateNFAStep(String symbol) {
    final nfa = widget.automaton as NFA;
    final newStatesFromSymbol = <String>{};
    final newTransitions = <String>{};

    for (final state in _currentStates) {
      final transitions = nfa.getTransitions(state, symbol);
      for (final nextState in transitions) {
        newStatesFromSymbol.add(nextState);
        newTransitions.add('$state->$nextState');
      }
    }

    final finalNewStates = _getEpsilonClosureForSet(newStatesFromSymbol, nfa);

    _currentStates = finalNewStates.toList()..sort();
    _highlightedStates = finalNewStates;
    _highlightedTransitions = newTransitions;
    _simulationPath.add(_currentStates.join(','));
  }

  void _simulateDFAStep(String symbol) {
    final dfa = widget.automaton as DFA;
    if (_currentStates.isEmpty) return;

    final currentStateName = _currentStates.first;
    final currentStateSet = _getStateSetFromName(currentStateName);

    if (currentStateSet.states.isEmpty) {
      _currentStates = [];
      _highlightedStates = {};
      _highlightedTransitions = {};
      return;
    }

    final nextStateSet = dfa.getTransition(currentStateSet, symbol);

    if (nextStateSet != null) {
      final nextStateName = dfa.getStateName(nextStateSet);
      _currentStates = [nextStateName];
      _highlightedStates = {nextStateName};
      _highlightedTransitions = {'$currentStateName->$nextStateName'};
      _simulationPath.add(nextStateName);
    } else {
      _currentStates = [];
      _highlightedStates = {};
      _highlightedTransitions = {};
    }
  }

  void _checkAcceptance() {
    final finalStates = _getFinalStates();
    _simulationAccepted = _currentStates.any(
      (state) => finalStates.contains(state),
    );
  }

  void _stopSimulation() {
    setState(() {
      _isSimulating = false;
      _highlightedStates.clear();
      _highlightedTransitions.clear();
      _currentStates.clear();
      _simulationPath.clear();
      _simulationAccepted = false;
    });
  }

  Set<String> _getEpsilonClosureForSet(Set<String> states, NFA nfa) {
    var closure = <String>{};
    var queue = states.toList();
    var visited = Set<String>.from(states);
    closure.addAll(states);

    while (queue.isNotEmpty) {
      final currentState = queue.removeAt(0);
      final epsilonTransitions = nfa.getTransitions(currentState, NFA.epsilon);
      for (final nextState in epsilonTransitions) {
        if (!visited.contains(nextState)) {
          visited.add(nextState);
          closure.add(nextState);
          queue.add(nextState);
        }
      }
    }
    return closure;
  }

  StateSet _getStateSetFromName(String name) {
    final dfa = widget.automaton as DFA;
    for (final stateSet in dfa.states) {
      if (dfa.getStateName(stateSet) == name) {
        return stateSet;
      }
    }
    return const StateSet({});
  }

  List<String> _getStates() {
    try {
      if (widget.automaton is NFA) {
        return (widget.automaton as NFA).states.toList()..sort();
      } else if (widget.automaton is DFA) {
        final dfa = widget.automaton as DFA;
        return dfa.states.map((s) => dfa.getStateName(s)).toList()..sort();
      }
    } catch (e) {
      print('Error getting states: $e');
    }
    return [];
  }

  List<String> _getAlphabet() {
    try {
      if (widget.automaton is NFA) {
        return (widget.automaton as NFA).alphabet.toList()..sort();
      } else if (widget.automaton is DFA) {
        return (widget.automaton as DFA).alphabet.toList()..sort();
      }
    } catch (e) {
      print('Error getting alphabet: $e');
    }
    return [];
  }

  String _getStartState() {
    try {
      if (widget.automaton is NFA) {
        return (widget.automaton as NFA).startState;
      } else if (widget.automaton is DFA) {
        final dfa = widget.automaton as DFA;
        return dfa.startState != null ? dfa.getStateName(dfa.startState!) : '';
      }
    } catch (e) {
      print('Error getting start state: $e');
    }
    return '';
  }

  Set<String> _getFinalStates() {
    try {
      if (widget.automaton is NFA) {
        return (widget.automaton as NFA).finalStates;
      } else if (widget.automaton is DFA) {
        final dfa = widget.automaton as DFA;
        return dfa.finalStates.map((s) => dfa.getStateName(s)).toSet();
      }
    } catch (e) {
      print('Error getting final states: $e');
    }
    return {};
  }

  String _getStateInfo(String state) {
    final isStart = state == _getStartState();
    final isFinal = _getFinalStates().contains(state);
    final transitions = _getTransitionsFromState(state);

    String type = '';
    if (isStart) type += 'شروع';
    if (isFinal) {
      if (type.isNotEmpty) type += ' و ';
      type += 'پایانی';
    }
    if (type.isEmpty) type = 'عادی';

    return 'نوع: $type | انتقالات خروجی: ${transitions.length}';
  }

  List<Map<String, dynamic>> _getTransitionsFromState(String state) {
    final transitions = <Map<String, dynamic>>[];

    try {
      if (widget.automaton is NFA) {
        final nfa = widget.automaton as NFA;
        final symbols = nfa.alphabet.union({NFA.epsilon});
        for (final symbol in symbols) {
          final nextStates = nfa.getTransitions(state, symbol);
          for (final nextState in nextStates) {
            transitions.add({'from': state, 'symbol': symbol, 'to': nextState});
          }
        }
      } else if (widget.automaton is DFA) {
        final dfa = widget.automaton as DFA;
        final stateSet = _getStateSetFromName(state);
        if (stateSet.states.isNotEmpty) {
          for (final symbol in dfa.alphabet) {
            final nextStateSet = dfa.getTransition(stateSet, symbol);
            if (nextStateSet != null) {
              transitions.add({
                'from': state,
                'symbol': symbol,
                'to': dfa.getStateName(nextStateSet),
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error getting transitions from state $state: $e');
    }
    return transitions;
  }

  List<Map<String, dynamic>> _getAllTransitions() {
    final allTransitions = <Map<String, dynamic>>[];
    final states = _getStates();

    for (final state in states) {
      allTransitions.addAll(_getTransitionsFromState(state));
    }

    return allTransitions;
  }

  Map<String, Offset> _getEffectivePositions() {
    final positions = <String, Offset>{};
    final states = _getStates();
    final defaultPositions = _calculatedPositions;

    for (final state in states) {
      if (_manualPositions.containsKey(state)) {
        positions[state] = _manualPositions[state]!;
      } else if (defaultPositions.containsKey(state)) {
        positions[state] = defaultPositions[state]!;
      } else {
        positions[state] = Offset(150.0 * (states.indexOf(state) + 1), 200);
      }
    }
    return positions;
  }

  String? _getStateAtPosition(Offset position) {
    final positions = _getEffectivePositions();
    double closestDistance = double.infinity;
    String? closestState;

    for (final entry in positions.entries) {
      final state = entry.key;
      final statePos = entry.value;
      final adjustedPos = statePos * _scaleFactor + _panOffset;
      final distance = (position - adjustedPos).distance;
      if (distance < closestDistance &&
          distance <= (_nodeSize * _scaleFactor)) {
        closestDistance = distance;
        closestState = state;
      }
    }
    return closestState;
  }

  void _showSimulationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String input = '';
        return AlertDialog(
          title: const Text('شبیه‌سازی ورودی'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('رشته ورودی را وارد کنید:'),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => input = value,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'مثال: abc',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'الفبا: ${_getAlphabet().join(', ')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _simulationInput = input;
                });
                _startSimulation();
              },
              child: const Text('شروع'),
            ),
          ],
        );
      },
    );
  }

  void _showLayoutOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'انتخاب نوع چیدمان',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...GraphLayoutType.values.map((type) {
                return ListTile(
                  leading: Icon(type.icon),
                  title: Text(type.name),
                  selected: _layoutType == type,
                  onTap: () {
                    setState(() => _layoutType = type);
                    _calculateLayout();
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportGraph() async {
    try {
      final boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/automaton_graph.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تصویر در ${file.path} ذخیره شد')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در ذخیره تصویر: $e')));
      }
    }
  }

  Future<void> _shareGraph() async {
    try {
      final boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final directory = await getTemporaryDirectory();
          final file = File('${directory.path}/automaton_graph.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());

          await Share.shareXFiles([
            XFile(file.path),
          ], text: 'نمایش گرافیکی اتوماتا');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در اشتراک‌گذاری: $e')));
      }
    }
  }
}

class SimpleAutomatonPainter extends CustomPainter {
  final List<String> states;
  final List<Map<String, dynamic>> transitions;
  final Map<String, Offset> positions;
  final String? selectedState;
  final Set<String> highlightedStates;
  final double nodeSize;
  final GraphTheme theme;
  final double scaleFactor;
  final Offset panOffset;
  final String startState;
  final Set<String> finalStates;

  SimpleAutomatonPainter({
    required this.states,
    required this.transitions,
    required this.positions,
    this.selectedState,
    required this.highlightedStates,
    required this.nodeSize,
    required this.theme,
    required this.scaleFactor,
    required this.panOffset,
    required this.startState,
    required this.finalStates,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (states.isEmpty) return;

    _drawTransitions(canvas);

    _drawNodes(canvas);
  }

  void _drawTransitions(Canvas canvas) {
    final paint = Paint()
      ..color = theme.edgeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = theme.edgeColor
      ..style = PaintingStyle.fill;

    for (final transition in transitions) {
      final from = transition['from'] as String;
      final to = transition['to'] as String;
      final symbol = transition['symbol'] as String;

      final fromPos = positions[from];
      final toPos = positions[to];

      if (fromPos != null && toPos != null) {
        final startPoint = fromPos * scaleFactor + panOffset;
        final endPoint = toPos * scaleFactor + panOffset;

        // Self loop
        if (from == to) {
          _drawSelfLoop(canvas, startPoint, symbol, paint);
        } else {
          _drawArrow(canvas, startPoint, endPoint, symbol, paint, arrowPaint);
        }
      }
    }
  }

  void _drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    String symbol,
    Paint paint,
    Paint arrowPaint,
  ) {
    // Calculate edge points on circle circumference
    final direction = (end - start).normalize();
    final adjustedStart = start + direction * (nodeSize * scaleFactor);
    final adjustedEnd = end - direction * (nodeSize * scaleFactor);

    // Draw line
    canvas.drawLine(adjustedStart, adjustedEnd, paint);

    // Draw arrowhead
    final arrowSize = 8.0 * scaleFactor;
    final arrowAngle = math.pi / 6;

    final arrowPoint1 =
        adjustedEnd +
        Offset(
          -arrowSize * math.cos(direction.direction - arrowAngle),
          -arrowSize * math.sin(direction.direction - arrowAngle),
        );

    final arrowPoint2 =
        adjustedEnd +
        Offset(
          -arrowSize * math.cos(direction.direction + arrowAngle),
          -arrowSize * math.sin(direction.direction + arrowAngle),
        );

    final arrowPath = Path()
      ..moveTo(adjustedEnd.dx, adjustedEnd.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);

    // Draw label
    _drawTransitionLabel(canvas, (adjustedStart + adjustedEnd) / 2, symbol);
  }

  void _drawSelfLoop(Canvas canvas, Offset center, String symbol, Paint paint) {
    final loopRadius = nodeSize * scaleFactor * 0.8;
    final loopCenter = center + Offset(0, -loopRadius - nodeSize * scaleFactor);

    canvas.drawCircle(loopCenter, loopRadius, paint);

    // Draw arrow on loop
    final arrowPos = loopCenter + Offset(loopRadius, 0);
    final arrowPaint = Paint()
      ..color = theme.edgeColor
      ..style = PaintingStyle.fill;

    final arrowPath = Path()
      ..moveTo(arrowPos.dx, arrowPos.dy)
      ..lineTo(arrowPos.dx - 8, arrowPos.dy - 4)
      ..lineTo(arrowPos.dx - 8, arrowPos.dy + 4)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);

    // Draw label
    _drawTransitionLabel(
      canvas,
      loopCenter + Offset(0, -loopRadius - 10),
      symbol,
    );
  }

  void _drawTransitionLabel(Canvas canvas, Offset position, String symbol) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol == 'ε' ? 'ε' : symbol,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 12 * scaleFactor,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw background
    final bgRect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 6,
      height: textPainter.height + 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = theme.backgroundColor.withOpacity(0.8),
    );

    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawNodes(Canvas canvas) {
    for (final state in states) {
      final position = positions[state];
      if (position != null) {
        final center = position * scaleFactor + panOffset;
        _drawNode(canvas, center, state);
      }
    }
  }

  void _drawNode(Canvas canvas, Offset center, String state) {
    final radius = nodeSize * scaleFactor;

    // Determine node color
    Color nodeColor = theme.nodeColor;
    if (highlightedStates.contains(state)) {
      nodeColor = Colors.orange;
    } else if (selectedState == state) {
      nodeColor = theme.primaryColor;
    }

    // Draw outer circle for final states
    if (finalStates.contains(state)) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = nodeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Draw main circle
    canvas.drawCircle(center, radius, Paint()..color = nodeColor);

    // Draw border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = theme.textColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw start state indicator
    if (state == startState) {
      final arrowStart = center - Offset(radius + 20, 0);
      final arrowEnd = center - Offset(radius + 5, 0);

      canvas.drawLine(
        arrowStart,
        arrowEnd,
        Paint()
          ..color = theme.textColor
          ..strokeWidth = 2,
      );

      // Arrow head
      final arrowPath = Path()
        ..moveTo(arrowEnd.dx, arrowEnd.dy)
        ..lineTo(arrowEnd.dx - 8, arrowEnd.dy - 4)
        ..lineTo(arrowEnd.dx - 8, arrowEnd.dy + 4)
        ..close();

      canvas.drawPath(arrowPath, Paint()..color = theme.textColor);
    }

    // Draw state label
    final textPainter = TextPainter(
      text: TextSpan(
        text: state,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 14 * scaleFactor,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
