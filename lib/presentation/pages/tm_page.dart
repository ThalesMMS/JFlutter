import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../providers/tm_editor_provider.dart';
import '../widgets/tm_algorithm_panel.dart';
import '../widgets/tm_canvas.dart';
import '../widgets/tm_simulation_panel.dart';

/// Page for working with Turing Machines
class TMPage extends ConsumerStatefulWidget {
  const TMPage({super.key});

  @override
  ConsumerState<TMPage> createState() => _TMPageState();
}

class _TMPageState extends ConsumerState<TMPage> {
  final GlobalKey _canvasKey = GlobalKey();
  bool _showControls = true;
  bool _showSimulation = false;
  bool _showAlgorithms = false;
  TM? _currentTM;
  int _stateCount = 0;
  int _transitionCount = 0;
  Set<String> _tapeSymbols = const <String>{};
  Set<String> _moveDirections = const <String>{};
  Set<String> _nondeterministicTransitionIds = const <String>{};
  bool _hasInitialState = false;
  bool _hasAcceptingState = false;

  bool get _isMachineReady =>
      _currentTM != null && _hasInitialState && _hasAcceptingState;

  bool get _hasMachine => _currentTM != null && _stateCount > 0;

  @override
  void initState() {
    super.initState();

    ref.listen<TMEditorState>(tmEditorProvider, (previous, next) {
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
          _showSimulation = false;
          _showAlgorithms = false;
        });
      }
    });
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
          // Mobile controls toggle - more compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    icon: Icons.edit,
                    label: 'Editor',
                    isActive: _showControls,
                    onPressed: () => setState(() => _showControls = !_showControls),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleButton(
                    icon: Icons.play_arrow,
                    label: 'Simulate',
                    isActive: _showSimulation,
                    onPressed: () =>
                        setState(() => _showSimulation = !_showSimulation),
                    isEnabled: _isMachineReady,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleButton(
                    icon: Icons.auto_awesome,
                    label: 'Algorithms',
                    isActive: _showAlgorithms,
                    onPressed: () =>
                        setState(() => _showAlgorithms = !_showAlgorithms),
                    isEnabled: _hasMachine,
                  ),
                ),
              ],
            ),
          ),

          // Content area with proper scrolling
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Collapsible panels with better space management
                  if (_showControls || _showSimulation || _showAlgorithms) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          // TM canvas
                          if (_showControls) ...[
                            Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              child: TMCanvas(
                                canvasKey: _canvasKey,
                                onTMModified: _handleTMUpdate,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Simulation panel
                          if (_showSimulation) ...[
                            Container(
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: const TMSimulationPanel(),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Algorithm panel
                          if (_showAlgorithms) ...[
                            Container(
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: const TMAlgorithmPanel(),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Info panel (always visible)
                  _buildInfoPanel(
                    context,
                    margin: const EdgeInsets.all(8),
                  ),
                ],
              ),
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
            child: TMCanvas(
              canvasKey: _canvasKey,
              onTMModified: _handleTMUpdate,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Center panel - Simulation
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const TMSimulationPanel(),
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

  void _handleTMUpdate(TM tm) {
    final transitions = tm.tmTransitions;
    final nondeterministic = _findNondeterministicTransitions(transitions);
    final hasInitial = tm.initialState != null;
    final hasAccepting = tm.acceptingStates.isNotEmpty;
    final machineReady = hasInitial && hasAccepting;
    final machineAvailable = tm.states.isNotEmpty;

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

      if (!machineReady) {
        _showSimulation = false;
      }

      if (!machineAvailable) {
        _showAlgorithms = false;
      }
    });
  }

  Widget _buildInfoPanel(
    BuildContext context, {
    EdgeInsetsGeometry? margin,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
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
          _buildInfoRow('Initial State', _hasInitialState ? 'Yes' : 'No', theme),
          _buildInfoRow('Accepting State', _hasAcceptingState ? 'Yes' : 'No', theme),
          _buildInfoRow('Simulation Ready', _isMachineReady ? 'Yes' : 'No', theme),
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
      child: Text(
        '$label: $value',
        style: emphasizedStyle,
      ),
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

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isActive 
            ? Theme.of(context).colorScheme.onPrimary 
            : Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        minimumSize: Size.zero,
      ),
    );
  }
}
