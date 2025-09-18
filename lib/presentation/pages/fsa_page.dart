import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/automaton_provider.dart';
import '../widgets/automaton_canvas.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/simulation_panel.dart';

/// Page for working with Finite State Automata
class FSAPage extends ConsumerStatefulWidget {
  const FSAPage({super.key});

  @override
  ConsumerState<FSAPage> createState() => _FSAPageState();
}

class _FSAPageState extends ConsumerState<FSAPage> {
  final GlobalKey _canvasKey = GlobalKey();
  bool _showControls = true;
  bool _showSimulation = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(automatonProvider);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 1024;

    return Scaffold(
      body: isMobile ? _buildMobileLayout(state) : _buildDesktopLayout(state),
    );
  }

  Widget _buildMobileLayout(AutomatonState state) {
    return Column(
      children: [
        // Mobile controls toggle - more compact
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  icon: Icons.tune,
                  label: 'Controls',
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
                  onPressed: () => setState(() => _showSimulation = !_showSimulation),
                ),
              ),
            ],
          ),
        ),

        // Canvas - gets maximum available space
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: AutomatonCanvas(
              automaton: state.currentAutomaton,
              canvasKey: _canvasKey,
              onAutomatonChanged: (automaton) {
                ref.read(automatonProvider.notifier).updateAutomaton(automaton);
              },
            ),
          ),
        ),

        // Collapsible panels with better space management
        if (_showControls || _showSimulation) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                // Controls panel
                if (_showControls) ...[
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: AlgorithmPanel(
                          onNfaToDfa: () => ref.read(automatonProvider.notifier).convertNfaToDfa(),
                          onMinimizeDfa: () => ref.read(automatonProvider.notifier).minimizeDfa(),
                          onClear: () => ref.read(automatonProvider.notifier).clearAutomaton(),
                          onRegexToNfa: (regex) => ref.read(automatonProvider.notifier).convertRegexToNfa(regex),
                      onFaToRegex: () => ref.read(automatonProvider.notifier).convertFaToRegex(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Simulation panel
                if (_showSimulation) ...[
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SimulationPanel(
                          onSimulate: (inputString) => ref.read(automatonProvider.notifier).simulateAutomaton(inputString),
                          simulationResult: state.simulationResult,
                      regexResult: state.regexResult,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isActive 
            ? Theme.of(context).colorScheme.onPrimary 
            : Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        minimumSize: Size.zero,
      ),
    );
  }

  Widget _buildDesktopLayout(AutomatonState state) {
    return Row(
      children: [
        // Left panel - Controls
        Expanded(
          flex: 2,
          child: Column(
            children: [
              AlgorithmPanel(
                onNfaToDfa: () => ref.read(automatonProvider.notifier).convertNfaToDfa(),
                onMinimizeDfa: () => ref.read(automatonProvider.notifier).minimizeDfa(),
                onClear: () => ref.read(automatonProvider.notifier).clearAutomaton(),
                onRegexToNfa: (regex) => ref.read(automatonProvider.notifier).convertRegexToNfa(regex),
                onFaToRegex: () => ref.read(automatonProvider.notifier).convertFaToRegex(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Center panel - Canvas
        Expanded(
          flex: 3,
          child: AutomatonCanvas(
            automaton: state.currentAutomaton,
            canvasKey: _canvasKey,
            onAutomatonChanged: (automaton) {
              ref.read(automatonProvider.notifier).updateAutomaton(automaton);
            },
          ),
        ),
        const SizedBox(width: 16),
        // Right panel - Simulation
        Expanded(
          flex: 2,
          child: SimulationPanel(
            onSimulate: (inputString) => ref.read(automatonProvider.notifier).simulateAutomaton(inputString),
            simulationResult: state.simulationResult,
            regexResult: state.regexResult,
          ),
        ),
      ],
    );
  }
}
