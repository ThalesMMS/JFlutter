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
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: isMobile ? _buildMobileLayout(state) : _buildDesktopLayout(state),
    );
  }

  Widget _buildMobileLayout(AutomatonState state) {
    return Column(
      children: [
        // Mobile controls toggle
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showControls = !_showControls),
                  icon: Icon(_showControls ? Icons.visibility_off : Icons.visibility),
                  label: Text(_showControls ? 'Hide Controls' : 'Show Controls'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showSimulation = !_showSimulation),
                  icon: Icon(_showSimulation ? Icons.visibility_off : Icons.play_arrow),
                  label: Text(_showSimulation ? 'Hide Simulation' : 'Show Simulation'),
                ),
              ),
            ],
          ),
        ),
        
        // Controls panel (collapsible on mobile)
        if (_showControls) ...[
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
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
          ),
        ],
        
        // Simulation panel (collapsible on mobile)
        if (_showSimulation) ...[
          Expanded(
            flex: 1,
            child: SimulationPanel(
              onSimulate: (inputString) => ref.read(automatonProvider.notifier).simulateAutomaton(inputString),
              simulationResult: state.simulationResult,
              regexResult: state.regexResult,
            ),
          ),
        ],
        
        // Canvas (full width on mobile)
        Expanded(
          flex: _showControls || _showSimulation ? 2 : 1,
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
      ],
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
