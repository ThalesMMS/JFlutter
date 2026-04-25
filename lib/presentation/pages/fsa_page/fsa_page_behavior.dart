part of '../fsa_page.dart';

extension _FSAPageStateBehavior on _FSAPageState {
  void _toggleCanvasTool(AutomatonCanvasTool tool) {
    final current = _toolController.activeTool;
    if (current == tool) {
      _toolController.setActiveTool(AutomatonCanvasTool.selection);
    } else {
      _toolController.setActiveTool(tool);
    }
  }

  void _handleAddStatePressed() {
    if (_toolController.activeTool != AutomatonCanvasTool.addState) {
      _toolController.setActiveTool(AutomatonCanvasTool.addState);
    }
    _canvasController.addStateAtCenter();
  }

  void _showSnack(String message, {bool isError = false}) {
    showAppSnackBar(
      context,
      message: message,
      tone: isError ? AppSnackBarTone.error : AppSnackBarTone.success,
    );
  }

  FSA? _requireAutomaton({
    bool requireDfa = false,
    bool requireLambda = false,
    String? missingMessage,
    String? invalidMessage,
  }) {
    final automaton = ref.read(automatonStateProvider).currentAutomaton;
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
      ref.read(automatonStateProvider.notifier).replaceCurrentAutomaton(result);
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
    ) algorithm,
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

    final automatonNotifier = ref.read(automatonStateProvider.notifier);
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
    ) algorithm,
    required String successMessage,
    bool requireDfa = false,
    String? invalidMessage,
  }) async {
    final automaton = _requireAutomaton(
      requireDfa: requireDfa,
      invalidMessage: invalidMessage,
    );
    if (automaton == null) return;

    final automatonNotifier = ref.read(automatonStateProvider.notifier);
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

  void _handleStepByStepModeChanged(bool enabled) {
    _updatePageState(() {
      _stepByStepMode = enabled;
    });
    if (!enabled) {
      ref.read(algorithmStepProvider.notifier).clearSteps();
    }
  }

  Future<void> _handleNfaToDfa() async {
    if (_stepByStepMode) {
      await _handleNfaToDfaWithSteps();
    } else {
      await ref.read(automatonAlgorithmProvider.notifier).convertNfaToDfa();
    }
  }

  Future<void> _handleNfaToDfaWithSteps() async {
    final automaton = _requireAutomaton();
    if (automaton == null) return;

    await ref
        .read(automatonAlgorithmProvider.notifier)
        .convertNfaToDfaWithSteps();
  }

  Future<void> _handleMinimizeDfa() async {
    if (_stepByStepMode) {
      await _handleMinimizeDfaWithSteps();
    } else {
      await ref.read(automatonAlgorithmProvider.notifier).minimizeDfa();
    }
  }

  Future<void> _handleMinimizeDfaWithSteps() async {
    final automaton = _requireAutomaton(requireDfa: true);
    if (automaton == null) return;

    await ref.read(automatonAlgorithmProvider.notifier).minimizeDfaWithSteps();
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

  Widget _buildStepViewerPanel() {
    final stepState = ref.watch(algorithmStepProvider);

    if (!stepState.hasSteps) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewerMaxHeight = constraints.maxHeight.isFinite
              ? (constraints.maxHeight - _kStepViewerNavigationControlsHeight)
                  .clamp(_kStepViewerMinHeight, _kStepViewerMaxHeight)
              : _kStepViewerDefaultHeight;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stepState.currentStep != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: viewerMaxHeight),
                  child: SingleChildScrollView(
                    child: AlgorithmStepViewer(step: stepState.currentStep!),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: StepNavigationControls(
                  currentStepIndex: stepState.currentStepIndex,
                  totalSteps: stepState.totalSteps,
                  isPlaying: stepState.isPlaying,
                  onPrevious: stepState.hasPreviousStep
                      ? () => ref
                          .read(algorithmStepProvider.notifier)
                          .previousStep()
                      : null,
                  onPlayPause: () => ref
                      .read(algorithmStepProvider.notifier)
                      .togglePlayPause(),
                  onNext: stepState.hasNextStep
                      ? () =>
                          ref.read(algorithmStepProvider.notifier).nextStep()
                      : null,
                  onReset: () => ref
                      .read(algorithmStepProvider.notifier)
                      .jumpToFirstStep(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  AlgorithmPanel _buildAlgorithmPanelForState(
    AutomatonStateProviderState state,
    AlgorithmOperationState algorithmState,
  ) {
    final automatonNotifier = ref.read(automatonStateProvider.notifier);
    final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
    final layoutNotifier = ref.read(automatonLayoutProvider.notifier);
    final automaton = state.currentAutomaton;
    final hasAutomaton = automaton != null;
    final hasLambda = automaton?.hasEpsilonTransitions ?? false;
    final isDfa = automaton != null &&
        automaton.isDeterministic &&
        !automaton.hasEpsilonTransitions;

    return AlgorithmPanel(
      currentAutomaton: hasAutomaton ? automaton : null,
      onNfaToDfa: hasAutomaton ? _handleNfaToDfa : null,
      onRemoveLambda: hasLambda ? _handleRemoveLambda : null,
      onMinimizeDfa: isDfa ? _handleMinimizeDfa : null,
      onCompleteDfa: isDfa ? () => algorithmNotifier.completeDfa() : null,
      onComplementDfa: isDfa ? _handleComplementDfa : null,
      onUnionDfa: isDfa ? _handleUnionDfa : null,
      onIntersectionDfa: isDfa ? _handleIntersectionDfa : null,
      onDifferenceDfa: isDfa ? _handleDifferenceDfa : null,
      onPrefixClosure: isDfa ? _handlePrefixClosure : null,
      onSuffixClosure: isDfa ? _handleSuffixClosure : null,
      onFsaToGrammar: hasAutomaton ? _handleFsaToGrammar : null,
      onAutoLayout:
          hasAutomaton ? () => layoutNotifier.applyAutoLayout() : null,
      onClear: () => automatonNotifier.clearAutomaton(),
      onRegexToNfa: (regex) => algorithmNotifier.convertRegexToNfa(regex),
      onFaToRegex: hasAutomaton ? _handleFaToRegex : null,
      onCompareEquivalence: isDfa ? _handleCompareEquivalence : null,
      equivalenceResult: algorithmState.equivalenceResult,
      equivalenceDetails: algorithmState.equivalenceDetails,
      onStepByStepModeChanged: _handleStepByStepModeChanged,
    );
  }

  Future<void> _handleFaToRegex() async {
    if (_stepByStepMode) {
      await _handleFaToRegexWithSteps();
    } else {
      final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
      final regex = await algorithmNotifier.convertFaToRegex();
      if (!mounted || regex == null) {
        final algorithmState = ref.read(automatonAlgorithmProvider);
        if (mounted && algorithmState.error != null) {
          _showSnack(algorithmState.error!, isError: true);
        }
        return;
      }

      if (!mounted) return;
      _showRegexResultDialog(regex, isStepByStep: false);
    }
  }

  Future<void> _handleFaToRegexWithSteps() async {
    final automaton = _requireAutomaton();
    if (automaton == null) return;

    final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
    final regex = await algorithmNotifier.convertFaToRegexWithSteps();
    if (!mounted || regex == null) {
      final algorithmState = ref.read(automatonAlgorithmProvider);
      if (mounted && algorithmState.error != null) {
        _showSnack(algorithmState.error!, isError: true);
      }
      return;
    }

    if (!mounted) return;
    _showRegexResultDialog(regex, isStepByStep: true);
  }

  void _showRegexResultDialog(String regex, {required bool isStepByStep}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isStepByStep
              ? 'FA to Regex Result (Step-by-Step)'
              : 'FA to Regex Result',
        ),
        content: SelectableText(regex),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFsaToGrammar() async {
    final algorithmNotifier = ref.read(automatonAlgorithmProvider.notifier);
    final grammar = await algorithmNotifier.convertFsaToGrammar();
    if (!mounted || grammar == null) {
      final algorithmState = ref.read(automatonAlgorithmProvider);
      if (mounted && algorithmState.error != null) {
        _showSnack(algorithmState.error!, isError: true);
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GrammarPage()));
  }

  Future<void> _handleCompareEquivalence(FSA other) async {
    await ref
        .read(automatonAlgorithmProvider.notifier)
        .compareEquivalence(other);
    if (!mounted) return;
    final message = ref.read(automatonAlgorithmProvider).equivalenceDetails;
    if (message != null) {
      _showSnack(message);
    }
  }

  void _showContextualHelp() {
    final helpNotifier = ref.read(helpProvider.notifier);
    final automaton = ref.read(automatonStateProvider).currentAutomaton;

    // Determine the most relevant help content based on current automaton state
    String helpContextId;
    if (automaton == null) {
      helpContextId = 'usage_getting_started';
    } else if (automaton.hasEpsilonTransitions) {
      helpContextId = 'concept_nfa';
    } else if (automaton.isDeterministic) {
      helpContextId = 'concept_dfa';
    } else {
      helpContextId = 'concept_nfa';
    }

    final helpContent = helpNotifier.getHelpByContext(helpContextId);
    if (helpContent != null) {
      ContextAwareHelpPanel.show(context, helpContent: helpContent);
    }
  }

  Widget _buildCanvasArea({
    required AutomatonStateProviderState state,
    required bool isMobile,
  }) {
    final simulationState = ref.watch(automatonSimulationProvider);
    Widget buildAutomatonCanvas() {
      return AutomatonCanvas(
        automaton: state.currentAutomaton,
        canvasKey: _canvasKey,
        controller: _canvasController,
        toolController: _toolController,
        simulationResult: simulationState.simulationResult,
        showTrace: simulationState.simulationResult != null,
      );
    }

    final statusMessage = _buildToolbarStatusMessage(state);

    Widget buildCanvasWithToolbar(Widget child) {
      final hasAutomaton = state.currentAutomaton != null;
      final onHelp = _showContextualHelp;
      final onSimulate = hasAutomaton ? _openSimulationSheet : null;
      final onAlgorithms = hasAutomaton ? _openAlgorithmSheet : null;

      final combinedListenable = Listenable.merge([
        _toolController,
        _canvasController.graphRevision,
      ]);

      if (isMobile) {
        return Stack(
          children: [
            Positioned.fill(child: child),
            Positioned(
              top: 16,
              left: 16,
              child: _CanvasQuickActions(
                onHelp: onHelp,
                onSimulate: onSimulate,
                onAlgorithms: onAlgorithms,
              ),
            ),
            // Badge DFA/NFA/ε-NFA
            FSADeterminismOverlay(automaton: state.currentAutomaton),
            AnimatedBuilder(
              animation: combinedListenable,
              builder: (context, _) {
                return MobileAutomatonControls(
                  enableToolSelection: true,
                  showSelectionTool: true,
                  activeTool: _toolController.activeTool,
                  onSelectTool: () => _toolController.setActiveTool(
                    AutomatonCanvasTool.selection,
                  ),
                  onAddState: _handleAddStatePressed,
                  onAddTransition: () =>
                      _toggleCanvasTool(AutomatonCanvasTool.transition),
                  onFitToContent: _canvasController.fitToContent,
                  onResetView: _canvasController.resetView,
                  onClear: () => ref
                      .read(automatonStateProvider.notifier)
                      .clearAutomaton(),
                  onUndo: _canvasController.canUndo
                      ? () => _canvasController.undo()
                      : null,
                  onRedo: _canvasController.canRedo
                      ? () => _canvasController.redo()
                      : null,
                  canUndo: _canvasController.canUndo,
                  canRedo: _canvasController.canRedo,
                  onSimulate: null,
                  isSimulationEnabled: false,
                  onAlgorithms: null,
                  isAlgorithmsEnabled: false,
                  statusMessage: statusMessage,
                );
              },
            ),
          ],
        );
      }

      return Stack(
        children: [
          Positioned.fill(child: child),
          // Badge DFA/NFA/ε-NFA (desktop)
          FSADeterminismOverlay(automaton: state.currentAutomaton),
          AnimatedBuilder(
            animation: combinedListenable,
            builder: (context, _) {
              return GraphViewCanvasToolbar(
                layout: GraphViewCanvasToolbarLayout.desktop,
                controller: _canvasController,
                enableToolSelection: true,
                showSelectionTool: true,
                activeTool: _toolController.activeTool,
                onSelectTool: () => _toolController.setActiveTool(
                  AutomatonCanvasTool.selection,
                ),
                onAddState: _handleAddStatePressed,
                onAddTransition: () =>
                    _toggleCanvasTool(AutomatonCanvasTool.transition),
                onClear: () =>
                    ref.read(automatonStateProvider.notifier).clearAutomaton(),
                statusMessage: statusMessage,
              );
            },
          ),
        ],
      );
    }

    // Wrap canvas with step navigator at the bottom
    return Column(
      children: [
        Expanded(child: buildCanvasWithToolbar(buildAutomatonCanvas())),
        const AlgorithmStepNavigator(),
      ],
    );
  }

  String _buildToolbarStatusMessage(AutomatonStateProviderState state) {
    final automaton = state.currentAutomaton;
    if (automaton == null) {
      return 'No automaton loaded';
    }

    final warnings = <String>[];
    if (automaton.initialState == null) {
      warnings.add('Missing start state');
    }
    if (automaton.acceptingStates.isEmpty) {
      warnings.add('No accepting states');
    }
    if (!automaton.isDeterministic) {
      warnings.add('Nondeterministic');
    }
    if (automaton.hasEpsilonTransitions) {
      warnings.add('λ-transitions present');
    }

    final counts =
        '${_formatCount('state', 'states', automaton.states.length)} · '
        '${_formatCount('transition', 'transitions', automaton.transitions.length)}';

    if (warnings.isEmpty) {
      return counts;
    }

    return '⚠ ${warnings.join(' · ')} · $counts';
  }

  String _formatCount(String singular, String plural, int count) {
    final label = count == 1 ? singular : plural;
    return '$count $label';
  }

  Widget _buildMobileLayout(AutomatonStateProviderState state) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              child: _buildCanvasArea(state: state, isMobile: true),
            ),
          ),
        ],
      ),
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
                      final sheetState = sheetRef.watch(automatonStateProvider);
                      final algorithmState = sheetRef.watch(
                        automatonAlgorithmProvider,
                      );
                      final stepState = sheetRef.watch(algorithmStepProvider);
                      return Column(
                        children: [
                          _buildAlgorithmPanelForState(
                            sheetState,
                            algorithmState,
                          ),
                          if (stepState.hasSteps) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: _kMobileStepViewerHeight,
                              child: _buildStepViewerPanel(),
                            ),
                          ],
                        ],
                      );
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
                  child: Consumer(
                    builder: (context, sheetRef, _) {
                      final simulationState = sheetRef.watch(
                        automatonSimulationProvider,
                      );
                      final algorithmState = sheetRef.watch(
                        automatonAlgorithmProvider,
                      );
                      return SimulationPanel(
                        onSimulate: (inputString) => sheetRef
                            .read(automatonSimulationProvider.notifier)
                            .simulateAutomaton(inputString),
                        simulationResult: simulationState.simulationResult,
                        regexResult: algorithmState.regexResult,
                        highlightService: _highlightService,
                      );
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

  Widget _buildDesktopLayout(AutomatonStateProviderState state) {
    final algorithmState = ref.watch(automatonAlgorithmProvider);
    final simulationState = ref.watch(automatonSimulationProvider);
    final stepState = ref.watch(algorithmStepProvider);

    return Row(
      children: [
        // Left panel - Controls and Step Viewer
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                child: _buildAlgorithmPanelForState(state, algorithmState),
              ),
              if (stepState.hasSteps) ...[
                const SizedBox(height: 8),
                Expanded(child: _buildStepViewerPanel()),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Center panel - Canvas
        Expanded(
          flex: 3,
          child: _buildCanvasArea(state: state, isMobile: false),
        ),
        const SizedBox(width: 16),
        // Right panel - Simulation
        Expanded(
          flex: 2,
          child: SimulationPanel(
            onSimulate: (inputString) => ref
                .read(automatonSimulationProvider.notifier)
                .simulateAutomaton(inputString),
            simulationResult: simulationState.simulationResult,
            regexResult: algorithmState.regexResult,
            highlightService: _highlightService,
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(AutomatonStateProviderState state) {
    final algorithmState = ref.watch(automatonAlgorithmProvider);
    final simulationState = ref.watch(automatonSimulationProvider);
    final stepState = ref.watch(algorithmStepProvider);
    final tabletStepViewerMaxHeight = (MediaQuery.sizeOf(context).height * 0.45)
        .clamp(_kTabletStepViewerMinHeight, _kTabletStepViewerMaxHeight);

    final algorithmColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAlgorithmPanelForState(state, algorithmState),
        if (stepState.hasSteps) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: _kTabletStepViewerMinHeight,
              maxHeight: tabletStepViewerMaxHeight,
            ),
            child: _buildStepViewerPanel(),
          ),
        ],
      ],
    );

    return TabletLayoutContainer(
      canvas: _buildCanvasArea(state: state, isMobile: false),
      algorithmPanel: algorithmColumn,
      simulationPanel: SimulationPanel(
        onSimulate: (inputString) => ref
            .read(automatonSimulationProvider.notifier)
            .simulateAutomaton(inputString),
        simulationResult: simulationState.simulationResult,
        regexResult: algorithmState.regexResult,
        highlightService: _highlightService,
      ),
    );
  }
}
