import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/fsa.dart';
import '../providers/automaton_provider.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/automaton_canvas/index.dart';
import '../widgets/simulation_panel.dart';
import 'grammar_page.dart';
import 'regex_page.dart';

/// Page for working with Finite State Automata
class FSAPage extends ConsumerStatefulWidget {
  const FSAPage({super.key});

  @override
  ConsumerState<FSAPage> createState() => _FSAPageState();
}

class _FSAPageState extends ConsumerState<FSAPage> {
  final GlobalKey _canvasKey = GlobalKey();

  Future<void> _handleFaToRegex() async {
    final notifier = ref.read(automatonProvider.notifier);
    final regex = await notifier.convertFaToRegex();
    if (!mounted || regex == null) {
      if (mounted && ref.read(automatonProvider).error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(automatonProvider).error!)),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegexPage(),
      ),
    );
  }

  Future<void> _handleFsaToGrammar() async {
    final notifier = ref.read(automatonProvider.notifier);
    final grammar = await notifier.convertFsaToGrammar();
    if (!mounted || grammar == null) {
      if (mounted && ref.read(automatonProvider).error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(automatonProvider).error!)),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GrammarPage(),
      ),
    );
  }

  Future<void> _handleCompareEquivalence(FSA other) async {
    await ref.read(automatonProvider.notifier).compareEquivalence(other);
    if (!mounted) return;
    final message = ref.read(automatonProvider).equivalenceDetails;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Show controls',
                icon: const Icon(Icons.tune),
                onPressed: _openAlgorithmSheet,
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Run simulation',
                icon: const Icon(Icons.play_arrow),
                onPressed: _openSimulationSheet,
              ),
            ],
          ),
        ),

        // Canvas - gets maximum available space
        Expanded(
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

  Future<void> _openAlgorithmSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AlgorithmPanel(
                    onNfaToDfa: () =>
                        ref.read(automatonProvider.notifier).convertNfaToDfa(),
                    onMinimizeDfa: () =>
                        ref.read(automatonProvider.notifier).minimizeDfa(),
                    onCompleteDfa: () =>
                        ref.read(automatonProvider.notifier).completeDfa(),
                    onFsaToGrammar: _handleFsaToGrammar,
                    onAutoLayout: () =>
                        ref.read(automatonProvider.notifier).applyAutoLayout(),
                    onClear: () =>
                        ref.read(automatonProvider.notifier).clearAutomaton(),
                    onRegexToNfa: (regex) => ref
                        .read(automatonProvider.notifier)
                        .convertRegexToNfa(regex),
                    onFaToRegex: _handleFaToRegex,
                    onCompareEquivalence: _handleCompareEquivalence,
                    equivalenceResult:
                        ref.read(automatonProvider).equivalenceResult,
                    equivalenceDetails:
                        ref.read(automatonProvider).equivalenceDetails,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openSimulationSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SimulationPanel(
                    onSimulate: (inputString) => ref
                        .read(automatonProvider.notifier)
                        .simulateAutomaton(inputString),
                    simulationResult:
                        ref.read(automatonProvider).simulationResult,
                    regexResult: ref.read(automatonProvider).regexResult,
                  ),
                ),
              );
            },
          ),
        );
      },
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
                onCompleteDfa: () => ref.read(automatonProvider.notifier).completeDfa(),
                onFsaToGrammar: _handleFsaToGrammar,
                onAutoLayout: () => ref.read(automatonProvider.notifier).applyAutoLayout(),
                onClear: () => ref.read(automatonProvider.notifier).clearAutomaton(),
                onRegexToNfa: (regex) => ref.read(automatonProvider.notifier).convertRegexToNfa(regex),
                onFaToRegex: _handleFaToRegex,
                onCompareEquivalence: _handleCompareEquivalence,
                equivalenceResult: state.equivalenceResult,
                equivalenceDetails: state.equivalenceDetails,
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
