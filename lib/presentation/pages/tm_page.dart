import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/state.dart' as automaton_state;
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../providers/tm_editor_provider.dart';
import '../widgets/tm_canvas_native.dart';
import '../widgets/tm_algorithm_panel.dart';
import '../widgets/tm_simulation_panel.dart';
import '../widgets/fl_nodes_canvas_toolbar.dart';
import '../../features/canvas/fl_nodes/fl_nodes_tm_canvas_controller.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/fl_nodes/fl_nodes_highlight_channel.dart';

/// Page for working with Turing Machines
class TMPage extends ConsumerStatefulWidget {
  const TMPage({super.key});

  @override
  ConsumerState<TMPage> createState() => _TMPageState();
}

class _TMPageState extends ConsumerState<TMPage> {
  TM? _currentTM;
  int _stateCount = 0;
  int _transitionCount = 0;
  Set<String> _tapeSymbols = const <String>{};
  Set<String> _moveDirections = const <String>{};
  Set<String> _nondeterministicTransitionIds = const <String>{};
  bool _hasInitialState = false;
  bool _hasAcceptingState = false;
  ProviderSubscription<TMEditorState>? _tmEditorSub;
  late final FlNodesTmCanvasController _canvasController;
  late final FlNodesSimulationHighlightChannel _highlightChannel;
  late final SimulationHighlightService _highlightService;

  bool get _isMachineReady =>
      _currentTM != null && _hasInitialState && _hasAcceptingState;

  bool get _hasMachine => _currentTM != null && _stateCount > 0;

  @override
  void initState() {
    super.initState();
    _canvasController = FlNodesTmCanvasController(
      editorNotifier: ref.read(tmEditorProvider.notifier),
    );
    _canvasController.synchronize(ref.read(tmEditorProvider).tm);
    _highlightChannel = FlNodesSimulationHighlightChannel(_canvasController);
    _highlightService = SimulationHighlightService(channel: _highlightChannel);
    SimulationHighlightService.registerGlobalChannel(_highlightChannel);
    _tmEditorSub = ref.listenManual<TMEditorState>(
      tmEditorProvider,
      (previous, next) {
        if (!mounted) return;
        if (next.tm == null && _currentTM != null) {
          setState(() {
            _currentTM = null;
            _stateCount = 0;
            _transitionCount = 0;
            _tapeSymbols = const <String>{};
            _moveDirections = const <String>{};
            _nondeterministicTransitionIds = const <String>{};
            _hasInitialState = false;
            _hasAcceptingState = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _tmEditorSub?.close();
    _highlightService.clear();
    SimulationHighlightService.registerGlobalChannel(null);
    _canvasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 1024;

    return Scaffold(
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          // Mobile action buttons for additional panels
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.play_arrow,
                    label: 'Simulate',
                    onPressed: _openSimulationSheet,
                    isEnabled: _isMachineReady,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.auto_awesome,
                    label: 'Algorithms',
                    onPressed: _openAlgorithmSheet,
                    isEnabled: _hasMachine,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.bar_chart,
                    label: 'Metrics',
                    onPressed: _openMetricsSheet,
                  ),
                ),
              ],
            ),
          ),

          // Canvas occupies the remaining viewport height
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildCanvasWithToolbar(isMobile: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel - TM Canvas
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: _buildCanvasWithToolbar(isMobile: false),
          ),
        ),
        const SizedBox(width: 16),
        // Center panel - Simulation
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: TMSimulationPanel(
              highlightService: _highlightService,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Right panel - Algorithms
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const TMAlgorithmPanel(),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Container(
            margin: const EdgeInsets.all(8),
            child: _buildInfoPanel(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCanvasWithToolbar({required bool isMobile}) {
    final editorState = ref.watch(tmEditorProvider);
    final statusMessage = _buildToolbarStatusMessage(editorState);

    return Stack(
      children: [
        Positioned.fill(
          child: TMCanvasNative(
            controller: _canvasController,
            onTMModified: _handleTMUpdate,
          ),
        ),
        FlNodesCanvasToolbar(
          layout: isMobile
              ? FlNodesCanvasToolbarLayout.mobile
              : FlNodesCanvasToolbarLayout.desktop,
          onAddState: _canvasController.addStateAtCenter,
          onZoomIn: _canvasController.zoomIn,
          onZoomOut: _canvasController.zoomOut,
          onFitToContent: _canvasController.fitToContent,
          onResetView: _canvasController.resetView,
          onClear: () {
            ref.read(tmEditorProvider.notifier).updateFromCanvas(
                  states: const <automaton_state.State>[],
                  transitions: const <TMTransition>[],
                );
          },
          statusMessage: statusMessage,
        ),
      ],
    );
  }

  String _buildToolbarStatusMessage(TMEditorState editorState) {
    final tm = editorState.tm;
    final stateCount = editorState.states.length;
    final transitionCount = editorState.transitions.length;

    final messageParts = <String>[];

    final warnings = <String>[];
    if (tm == null || tm.initialState == null) {
      warnings.add('Missing start state');
    }
    if (tm == null || tm.acceptingStates.isEmpty) {
      warnings.add('No accepting states');
    }
    if (editorState.nondeterministicTransitionIds.isNotEmpty) {
      warnings.add('Nondeterministic transitions');
    }

    if (warnings.isNotEmpty) {
      messageParts.add('⚠ ${warnings.join(' · ')}');
    }

    if (stateCount == 0 && transitionCount == 0) {
      messageParts.add('No machine defined');
    } else {
      messageParts.add(
        '${_formatCount('state', 'states', stateCount)} · '
        '${_formatCount('transition', 'transitions', transitionCount)}',
      );
    }

    return messageParts.join(' · ');
  }

  String _formatCount(String singular, String plural, int count) {
    final label = count == 1 ? singular : plural;
    return '$count $label';
  }

  void _handleTMUpdate(TM tm) {
    final transitions = tm.tmTransitions;
    final nondeterministic = _findNondeterministicTransitions(transitions);
    final hasInitial = tm.initialState != null;
    final hasAccepting = tm.acceptingStates.isNotEmpty;

    setState(() {
      _currentTM = tm;
      _stateCount = tm.states.length;
      _transitionCount = transitions.length;
      _tapeSymbols = Set<String>.unmodifiable(tm.tapeAlphabet);
      _moveDirections = Set<String>.unmodifiable(
        transitions.map((t) => t.direction.name.toUpperCase()),
      );
      _nondeterministicTransitionIds = nondeterministic;
      _hasInitialState = hasInitial;
      _hasAcceptingState = hasAccepting;
    });
  }

  void _openSimulationSheet() {
    if (!_isMachineReady) return;

    _showDraggableSheet(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            TMSimulationPanel(
              highlightService: _highlightService,
            ),
          ],
        );
      },
      initialChildSize: 0.7,
    );
  }

  void _openAlgorithmSheet() {
    if (!_hasMachine) return;

    _showDraggableSheet(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: const [TMAlgorithmPanel()],
        );
      },
      initialChildSize: 0.6,
    );
  }

  void _openMetricsSheet() {
    _showDraggableSheet(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [_buildInfoPanel(context)],
        );
      },
      initialChildSize: 0.45,
      maxChildSize: 0.75,
    );
  }

  Future<void> _showDraggableSheet({
    required Widget Function(BuildContext context, ScrollController controller)
    builder,
    double initialChildSize = 0.6,
    double minChildSize = 0.3,
    double maxChildSize = 0.9,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          builder: (sheetContext, controller) {
            final color = Theme.of(sheetContext).colorScheme.surface;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Material(
                  color: color,
                  child: SafeArea(
                    top: false,
                    child: builder(sheetContext, controller),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoPanel(BuildContext context, {EdgeInsetsGeometry? margin}) {
    final theme = Theme.of(context);
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turing Machine Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor the structure of your machine and resolve issues before running simulations or algorithms.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('States', '$_stateCount', theme),
          _buildInfoRow('Transitions', '$_transitionCount', theme),
          _buildInfoRow('Tape Symbols', _formatSet(_tapeSymbols), theme),
          _buildInfoRow('Move Directions', _formatSet(_moveDirections), theme),
          _buildInfoRow(
            'Initial State',
            _hasInitialState ? 'Yes' : 'No',
            theme,
          ),
          _buildInfoRow(
            'Accepting State',
            _hasAcceptingState ? 'Yes' : 'No',
            theme,
          ),
          _buildInfoRow(
            'Simulation Ready',
            _isMachineReady ? 'Yes' : 'No',
            theme,
          ),
          _buildInfoRow(
            'Nondeterministic Transitions',
            _nondeterministicTransitionIds.isEmpty
                ? '0'
                : '${_nondeterministicTransitionIds.length}',
            theme,
          ),
          if (_nondeterministicTransitionIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Resolve nondeterminism before running deterministic algorithms.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    final textStyle = theme.textTheme.bodyMedium;
    final emphasizedStyle = textStyle?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $value', style: emphasizedStyle),
    );
  }

  String _formatSet(Set<String> values) {
    if (values.isEmpty) {
      return '-';
    }
    final sorted = values.toList()..sort();
    return sorted.join(', ');
  }

  Set<String> _findNondeterministicTransitions(Set<TMTransition> transitions) {
    final grouped = <String, List<TMTransition>>{};

    for (final transition in transitions) {
      final key = [
        transition.fromState.id,
        transition.readSymbol,
        transition.tapeNumber.toString(),
      ].join('|');

      grouped.putIfAbsent(key, () => <TMTransition>[]).add(transition);
    }

    return grouped.values
        .where((list) => list.length > 1)
        .expand((list) => list.map((transition) => transition.id))
        .toSet();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        minimumSize: Size.zero,
      ),
    );
  }
}
