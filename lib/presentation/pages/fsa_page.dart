import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/models/fsa.dart';
import '../providers/algorithm_provider.dart';
import '../providers/automaton_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/automaton_canvas.dart';
import '../widgets/draw2d_canvas_view.dart';
import '../widgets/draw2d_canvas_toolbar.dart';
import '../widgets/draw2d_platform_support.dart';
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
  void _showSnack(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError
              ? TextStyle(color: theme.colorScheme.onErrorContainer)
              : null,
        ),
        backgroundColor: isError ? theme.colorScheme.errorContainer : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  FSA? _requireAutomaton({
    bool requireDfa = false,
    bool requireLambda = false,
    String? missingMessage,
    String? invalidMessage,
  }) {
    final automaton = ref.read(automatonProvider).currentAutomaton;
    if (automaton == null) {
      _showSnack(
        missingMessage ?? 'Load an automaton before running this operation.',
        isError: true,
      );
      return null;
    }

    if (requireDfa &&
        !(automaton.isDeterministic && !automaton.hasEpsilonTransitions)) {
      _showSnack(
        invalidMessage ??
            'This operation requires a deterministic automaton without ε-transitions.',
        isError: true,
      );
      return null;
    }

    if (requireLambda && !automaton.hasEpsilonTransitions) {
      _showSnack(
        invalidMessage ??
            'The current automaton does not contain λ-transitions.',
        isError: true,
      );
      return null;
    }

    return automaton;
  }

  Future<void> _applyAlgorithmResult({required String successMessage}) async {
    final algorithmState = ref.read(algorithmProvider);
    final notifier = ref.read(algorithmProvider.notifier);
    final error = algorithmState.error;
    final result = algorithmState.result;

    if (error != null) {
      _showSnack(error, isError: true);
      notifier.clearResult();
      return;
    }

    if (result is AutomatonEntity) {
      ref.read(automatonProvider.notifier).replaceCurrentAutomaton(result);
      _showSnack(successMessage);
      notifier.clearResult();
      return;
    }

    notifier.clearResult();
    if (result != null) {
      _showSnack('Unexpected result returned by the algorithm.', isError: true);
    }
  }

  Future<void> _runUnaryAlgorithm({
    required Future<void> Function(
      AlgorithmProvider notifier,
      AutomatonEntity entity,
    )
    algorithm,
    required String successMessage,
    bool requireDfa = false,
    bool requireLambda = false,
    String? invalidMessage,
  }) async {
    final automaton = _requireAutomaton(
      requireDfa: requireDfa,
      requireLambda: requireLambda,
      invalidMessage: invalidMessage,
    );
    if (automaton == null) return;

    final automatonNotifier = ref.read(automatonProvider.notifier);
    final entity = automatonNotifier.currentAutomatonEntity;
    if (entity == null) {
      _showSnack(
        'Unable to prepare the current automaton for processing.',
        isError: true,
      );
      return;
    }

    await algorithm(ref.read(algorithmProvider.notifier), entity);
    if (!mounted) return;
    await _applyAlgorithmResult(successMessage: successMessage);
  }

  Future<void> _runBinaryAlgorithm({
    required FSA other,
    required Future<void> Function(
      AlgorithmProvider notifier,
      AutomatonEntity current,
      AutomatonEntity other,
    )
    algorithm,
    required String successMessage,
    bool requireDfa = false,
    String? invalidMessage,
  }) async {
    final automaton = _requireAutomaton(
      requireDfa: requireDfa,
      invalidMessage: invalidMessage,
    );
    if (automaton == null) return;

    final automatonNotifier = ref.read(automatonProvider.notifier);
    final currentEntity = automatonNotifier.currentAutomatonEntity;
    if (currentEntity == null) {
      _showSnack(
        'Unable to prepare the current automaton for processing.',
        isError: true,
      );
      return;
    }

    final otherEntity = automatonNotifier.convertFsaToEntity(other);

    await algorithm(
      ref.read(algorithmProvider.notifier),
      currentEntity,
      otherEntity,
    );
    if (!mounted) return;
    await _applyAlgorithmResult(successMessage: successMessage);
  }

  Future<void> _handleRemoveLambda() async {
    await _runUnaryAlgorithm(
      algorithm: (notifier, entity) => notifier.removeLambdaTransitions(entity),
      successMessage: 'λ-transitions removed successfully.',
      requireLambda: true,
      invalidMessage:
          'The current automaton must contain λ-transitions to remove them.',
    );
  }

  Future<void> _handleComplementDfa() async {
    await _runUnaryAlgorithm(
      algorithm: (notifier, entity) => notifier.complementDfa(entity),
      successMessage: 'Complement computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Complement is only available for deterministic automata without ε-transitions.',
    );
  }

  Future<void> _handlePrefixClosure() async {
    await _runUnaryAlgorithm(
      algorithm: (notifier, entity) => notifier.prefixClosureDfa(entity),
      successMessage: 'Prefix closure computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Prefix closure is only available for deterministic automata without ε-transitions.',
    );
  }

  Future<void> _handleSuffixClosure() async {
    await _runUnaryAlgorithm(
      algorithm: (notifier, entity) => notifier.suffixClosureDfa(entity),
      successMessage: 'Suffix closure computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Suffix closure is only available for deterministic automata without ε-transitions.',
    );
  }

  Future<void> _handleUnionDfa(FSA other) async {
    await _runBinaryAlgorithm(
      other: other,
      algorithm: (notifier, current, loaded) =>
          notifier.unionDfa(current, loaded),
      successMessage: 'Union computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Binary DFA operations require a deterministic automaton without ε-transitions.',
    );
  }

  Future<void> _handleIntersectionDfa(FSA other) async {
    await _runBinaryAlgorithm(
      other: other,
      algorithm: (notifier, current, loaded) =>
          notifier.intersectionDfa(current, loaded),
      successMessage: 'Intersection computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Binary DFA operations require a deterministic automaton without ε-transitions.',
    );
  }

  Future<void> _handleDifferenceDfa(FSA other) async {
    await _runBinaryAlgorithm(
      other: other,
      algorithm: (notifier, current, loaded) =>
          notifier.differenceDfa(current, loaded),
      successMessage: 'Difference computed successfully.',
      requireDfa: true,
      invalidMessage:
          'Binary DFA operations require a deterministic automaton without ε-transitions.',
    );
  }

  AlgorithmPanel _buildAlgorithmPanelForState(AutomatonState state) {
    final automatonNotifier = ref.read(automatonProvider.notifier);
    final automaton = state.currentAutomaton;
    final hasAutomaton = automaton != null;
    final hasLambda = automaton?.hasEpsilonTransitions ?? false;
    final isDfa =
        automaton != null &&
        automaton.isDeterministic &&
        !automaton.hasEpsilonTransitions;

    return AlgorithmPanel(
      onNfaToDfa: hasAutomaton
          ? () => automatonNotifier.convertNfaToDfa()
          : null,
      onRemoveLambda: hasLambda ? _handleRemoveLambda : null,
      onMinimizeDfa: isDfa ? () => automatonNotifier.minimizeDfa() : null,
      onCompleteDfa: isDfa ? () => automatonNotifier.completeDfa() : null,
      onComplementDfa: isDfa ? _handleComplementDfa : null,
      onUnionDfa: isDfa ? _handleUnionDfa : null,
      onIntersectionDfa: isDfa ? _handleIntersectionDfa : null,
      onDifferenceDfa: isDfa ? _handleDifferenceDfa : null,
      onPrefixClosure: isDfa ? _handlePrefixClosure : null,
      onSuffixClosure: isDfa ? _handleSuffixClosure : null,
      onFsaToGrammar: hasAutomaton ? _handleFsaToGrammar : null,
      onAutoLayout: hasAutomaton
          ? () => automatonNotifier.applyAutoLayout()
          : null,
      onClear: () => automatonNotifier.clearAutomaton(),
      onRegexToNfa: (regex) =>
          ref.read(automatonProvider.notifier).convertRegexToNfa(regex),
      onFaToRegex: hasAutomaton ? _handleFaToRegex : null,
      onCompareEquivalence: isDfa ? _handleCompareEquivalence : null,
      equivalenceResult: state.equivalenceResult,
      equivalenceDetails: state.equivalenceDetails,
    );
  }

  Future<void> _handleFaToRegex() async {
    final notifier = ref.read(automatonProvider.notifier);
    final regex = await notifier.convertFaToRegex();
    if (!mounted || regex == null) {
      if (mounted && ref.read(automatonProvider).error != null) {
        _showSnack(ref.read(automatonProvider).error!, isError: true);
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegexPage()));
  }

  Future<void> _handleFsaToGrammar() async {
    final notifier = ref.read(automatonProvider.notifier);
    final grammar = await notifier.convertFsaToGrammar();
    if (!mounted || grammar == null) {
      if (mounted && ref.read(automatonProvider).error != null) {
        _showSnack(ref.read(automatonProvider).error!, isError: true);
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GrammarPage()));
  }

  Future<void> _handleCompareEquivalence(FSA other) async {
    await ref.read(automatonProvider.notifier).compareEquivalence(other);
    if (!mounted) return;
    final message = ref.read(automatonProvider).equivalenceDetails;
    if (message != null) {
      _showSnack(message);
    }
  }

  Widget _buildCanvasArea({
    required AutomatonState state,
    required bool isMobile,
  }) {
    Widget buildAutomatonCanvas() {
      return AutomatonCanvas(
        automaton: state.currentAutomaton,
        canvasKey: _canvasKey,
        onAutomatonChanged: (automaton) {
          ref.read(automatonProvider.notifier).updateAutomaton(automaton);
        },
        simulationResult: state.simulationResult,
        showTrace: state.simulationResult != null,
      );
    }

    Widget buildCanvasWithToolbar(Widget child) {
      return Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            top: 12,
            right: 12,
            child: Draw2DCanvasToolbar(
              onClear: () => ref.read(automatonProvider.notifier).clearAutomaton(),
            ),
          ),
        ],
      );
    }

    if (kIsWeb) {
      return buildCanvasWithToolbar(buildAutomatonCanvas());
    }

    final settings = ref.watch(settingsProvider);
    final useDraw2dCanvas =
        settings.useDraw2dCanvas && isDraw2dWebViewSupported();

    if (useDraw2dCanvas) {
      return buildCanvasWithToolbar(const Draw2DCanvasView());
    }

    return buildCanvasWithToolbar(buildAutomatonCanvas());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(automatonProvider);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 1024;

    return Scaffold(
      body: isMobile
          ? _buildMobileLayout(state)
          : _buildDesktopLayout(state),
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
            child: _buildCanvasArea(
              state: state,
              isMobile: true,
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
                  child: Consumer(
                    builder: (context, sheetRef, _) {
                      final sheetState = sheetRef.watch(automatonProvider);
                      return _buildAlgorithmPanelForState(sheetState);
                    },
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
                    simulationResult: ref
                        .read(automatonProvider)
                        .simulationResult,
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
          child: Column(children: [_buildAlgorithmPanelForState(state)]),
        ),
        const SizedBox(width: 16),
        // Center panel - Canvas
        Expanded(
          flex: 3,
          child: _buildCanvasArea(
            state: state,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        // Right panel - Simulation
        Expanded(
          flex: 2,
          child: SimulationPanel(
            onSimulate: (inputString) => ref
                .read(automatonProvider.notifier)
                .simulateAutomaton(inputString),
            simulationResult: state.simulationResult,
            regexResult: state.regexResult,
          ),
        ),
      ],
    );
  }

}
