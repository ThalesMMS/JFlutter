import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/state.dart' as automaton_state;
import '../providers/pda_editor_provider.dart';
import '../widgets/fl_nodes_canvas_toolbar.dart';
import '../widgets/mobile_automaton_controls.dart';
import '../widgets/pda_canvas_native.dart';
import '../widgets/pda_algorithm_panel.dart';
import '../widgets/pda_simulation_panel.dart';
import '../../features/canvas/fl_nodes/fl_nodes_pda_canvas_controller.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/fl_nodes/fl_nodes_highlight_channel.dart';

/// Page for working with Pushdown Automata
class PDAPage extends ConsumerStatefulWidget {
  const PDAPage({super.key});

  @override
  ConsumerState<PDAPage> createState() => _PDAPageState();
}

class _PDAPageState extends ConsumerState<PDAPage> {
  PDA? _latestPda;
  int _stateCount = 0;
  int _transitionCount = 0;
  bool _hasUnsavedChanges = false;
  ProviderSubscription<PDAEditorState>? _pdaEditorSub;
  late final FlNodesPdaCanvasController _canvasController;
  late final FlNodesSimulationHighlightChannel _highlightChannel;
  late final SimulationHighlightService _highlightService;

  @override
  void initState() {
    super.initState();
    _canvasController = FlNodesPdaCanvasController(
      editorNotifier: ref.read(pdaEditorProvider.notifier),
    );
    _canvasController.synchronize(ref.read(pdaEditorProvider).pda);
    _highlightChannel = FlNodesSimulationHighlightChannel(_canvasController);
    _highlightService = SimulationHighlightService(channel: _highlightChannel);
    _pdaEditorSub = ref.listenManual<PDAEditorState>(
      pdaEditorProvider,
      (previous, next) {
        if (!mounted) return;
        if (next.pda == null && _latestPda != null) {
          setState(() {
            _latestPda = null;
            _stateCount = 0;
            _transitionCount = 0;
            _hasUnsavedChanges = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _pdaEditorSub?.close();
    _highlightService.clear();
    _canvasController.dispose();
    super.dispose();
  }

  void _handlePdaModified(PDA pda) {
    setState(() {
      _latestPda = pda;
      _stateCount = pda.states.length;
      _transitionCount = pda.pdaTransitions.length;
      _hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 1024;

    return ProviderScope(
      overrides: [
        canvasHighlightServiceProvider.overrideWithValue(_highlightService),
      ],
      child: Scaffold(
        body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: _buildCanvasWithToolbar(
                    PDACanvasNative(
                      controller: _canvasController,
                      onPdaModified: _handlePdaModified,
                    ),
                    isMobile: true,
                  ),
                ),
              ),
              _buildMobileInfoPanel(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pushdown Automata Editor',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create states, transitions with stack operations, and test strings. PDAs can recognize context-free languages.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildPdaInfoMetrics(context),
          if (_hasUnsavedChanges) ...[
            const SizedBox(height: 12),
            Row(
              key: const ValueKey('pda_info_unsaved_changes'),
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Unsaved changes',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPanelSheet({
    required BuildContext context,
    required String title,
    required Widget child,
    IconData? icon,
  }) async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                      child: Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [child],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel - PDA Canvas
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: _buildCanvasWithToolbar(
              PDACanvasNative(
                controller: _canvasController,
                onPdaModified: _handlePdaModified,
              ),
              isMobile: false,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Center panel - Simulation
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: PDASimulationPanel(
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
            child: const PDAAlgorithmPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildPdaInfoMetrics(BuildContext context) {
    final chips = <Widget>[
      _buildInfoChip(
        context,
        label: 'States',
        value: _stateCount.toString(),
        key: const ValueKey('pda_info_state_count'),
      ),
      _buildInfoChip(
        context,
        label: 'Transitions',
        value: _transitionCount.toString(),
        key: const ValueKey('pda_info_transition_count'),
      ),
    ];

    if (_latestPda != null) {
      chips.add(
        _buildInfoChip(
          context,
          label: 'Stack symbols',
          value: _latestPda!.stackAlphabet.length.toString(),
          key: const ValueKey('pda_info_stack_count'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current PDA: ${_latestPda?.name ?? 'None'}',
          key: const ValueKey('pda_info_current_name'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required String label,
    required String value,
    Key? key,
  }) {
    return Chip(
      key: key,
      label: Text('$label: $value'),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildCanvasWithToolbar(
    Widget canvas, {
    required bool isMobile,
  }) {
    final editorState = ref.watch(pdaEditorProvider);
    final statusMessage = _buildToolbarStatusMessage(editorState);
    final hasPda = editorState.pda != null && editorState.pda!.states.isNotEmpty;

    if (isMobile) {
      return Stack(
        children: [
          Positioned.fill(child: canvas),
          MobileAutomatonControls(
            onAddState: _canvasController.addStateAtCenter,
            onZoomIn: _canvasController.zoomIn,
            onZoomOut: _canvasController.zoomOut,
            onFitToContent: _canvasController.fitToContent,
            onResetView: _canvasController.resetView,
            onClear: () =>
                ref.read(pdaEditorProvider.notifier).updateFromCanvas(
                      states: const <automaton_state.State>[],
                      transitions: const <PDATransition>[],
                    ),
            onSimulate: () => _showPanelSheet(
              context: context,
              title: 'PDA Simulation',
              icon: Icons.play_arrow,
              child: PDASimulationPanel(
                highlightService: _highlightService,
              ),
            ),
            isSimulationEnabled: hasPda,
            onAlgorithms: () => _showPanelSheet(
              context: context,
              title: 'PDA Algorithms',
              icon: Icons.auto_awesome,
              child: const PDAAlgorithmPanel(),
            ),
            isAlgorithmsEnabled: hasPda,
            statusMessage: statusMessage,
          ),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: canvas),
        FlNodesCanvasToolbar(
          layout: FlNodesCanvasToolbarLayout.desktop,
          onAddState: _canvasController.addStateAtCenter,
          onZoomIn: _canvasController.zoomIn,
          onZoomOut: _canvasController.zoomOut,
          onFitToContent: _canvasController.fitToContent,
          onResetView: _canvasController.resetView,
          onClear: () => ref.read(pdaEditorProvider.notifier).updateFromCanvas(
                states: const <automaton_state.State>[],
                transitions: const <PDATransition>[],
              ),
          statusMessage: statusMessage,
        ),
      ],
    );
  }

  String _buildToolbarStatusMessage(PDAEditorState editorState) {
    final pda = editorState.pda;
    final hasPda = pda != null && pda.states.isNotEmpty;
    final stateCount = pda?.states.length ?? 0;
    final transitionCount = pda?.pdaTransitions.length ?? 0;

    final messageParts = <String>[];

    if (_hasUnsavedChanges) {
      messageParts.add('Unsaved changes');
    }

    final warnings = <String>[];
    if (editorState.nondeterministicTransitionIds.isNotEmpty) {
      warnings.add('Nondeterministic transitions');
    }
    if (editorState.lambdaTransitionIds.isNotEmpty) {
      warnings.add('λ-transitions present');
    }

    if (warnings.isNotEmpty) {
      messageParts.add('⚠ ${warnings.join(' · ')}');
    }

    if (hasPda) {
      messageParts.add(
        '${_formatCount('state', 'states', stateCount)} · '
        '${_formatCount('transition', 'transitions', transitionCount)}',
      );
    } else {
      messageParts.add('No PDA loaded');
    }

    return messageParts.join(' · ');
  }

  String _formatCount(String singular, String plural, int count) {
    final label = count == 1 ? singular : plural;
    return '$count $label';
  }
}
