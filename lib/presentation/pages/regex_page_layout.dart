part of 'regex_page.dart';

extension _RegexPageLayoutSections on _RegexPageState {
  Widget _buildMobileLayout(AlgorithmOperationState algorithmState) {
    final l10n = AppLocalizations.of(context);
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: _buildInputArea(algorithmState),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'regex_mobile_context_help_fab',
          onPressed: _showContextualHelp,
          tooltip: l10n.contextAwareHelp,
          child: const Icon(Icons.help_outline),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(AlgorithmOperationState algorithmState) {
    final l10n = AppLocalizations.of(context);
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Scaffold(
        body: Row(
          children: [
            // Left panel - Regex input and testing
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  child: _buildInputArea(algorithmState),
                ),
              ),
            ),

            // Right panel - Algorithm operations
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.algorithms,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Algorithm panel
                    Expanded(
                      child: AlgorithmPanel(
                        onNfaToDfa: _convertToDFA,
                        onMinimizeDfa: null,
                        onClear: _clearInputs,
                        onRegexToNfa: (regex) {
                          _regexController.text = regex;
                          _validateRegex();
                          _convertToNFA();
                        },
                        onFaToRegex: null,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Simulation panel
                    Expanded(
                      child: SimulationPanel(
                        onSimulate: (input) {
                          _testStringController.text = input;
                          _testStringMatch();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'regex_desktop_context_help_fab',
          onPressed: _showContextualHelp,
          tooltip: l10n.contextAwareHelp,
          child: const Icon(Icons.help_outline),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(AlgorithmOperationState algorithmState) {
    final l10n = AppLocalizations.of(context);
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Scaffold(
        body: TabletLayoutContainer(
          canvas: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildInputArea(algorithmState),
          ),
          algorithmPanel: AlgorithmPanel(
            onNfaToDfa: _convertToDFA,
            onMinimizeDfa: null,
            onClear: _clearInputs,
            onRegexToNfa: (regex) {
              _regexController.text = regex;
              _validateRegex();
              _convertToNFA();
            },
            onFaToRegex: null,
          ),
          simulationPanel: SimulationPanel(
            onSimulate: (input) {
              _testStringController.text = input;
              _testStringMatch();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'regex_tablet_context_help_fab',
          onPressed: _showContextualHelp,
          tooltip: l10n.contextAwareHelp,
          child: const Icon(Icons.help_outline),
        ),
      ),
    );
  }

  Widget _buildInputArea(AlgorithmOperationState algorithmState) {
    final l10n = AppLocalizations.of(context);
    final faToRegexWidget = _buildFaToRegexResult(algorithmState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.regularExpressionTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Regex input
        Text(
          l10n.regularExpressionLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('regex_input_field'),
          controller: _regexController,
          decoration: InputDecoration(
            hintText: l10n.regularExpressionHint,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _validateRegex,
              icon: const Icon(Icons.check),
              tooltip: l10n.validateRegex,
            ),
          ),
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          onChanged: (value) => _validateRegex(),
        ),

        // Validation status
        const SizedBox(height: 8),
        if (_currentRegex.isEmpty)
          ErrorBanner(
            message: l10n.enterRegexToValidate,
            severity: ErrorSeverity.info,
            showRetryButton: false,
            showDismissButton: false,
          )
        else
          ErrorBanner(
            message: _isValid
                ? l10n.validRegex
                : (_errorMessage.isNotEmpty
                    ? _errorMessage
                    : l10n.invalidRegex),
            severity: _isValid ? ErrorSeverity.success : ErrorSeverity.error,
            showRetryButton: false,
            showDismissButton: false,
          ),

        const SizedBox(height: 24),

        // Test string input
        Text(l10n.testStringLabel,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('regex_test_input_field'),
          controller: _testStringController,
          decoration: InputDecoration(
            hintText: l10n.testStringHint,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _testStringMatch,
              icon: const Icon(Icons.play_arrow),
              tooltip: l10n.testStringTooltip,
            ),
          ),
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          onChanged: (value) => _testStringMatch(),
        ),

        // Match result
        const SizedBox(height: 8),
        if (_hasTested)
          ErrorBanner(
            message: _matches ? l10n.matches : l10n.doesNotMatch,
            severity: _matches ? ErrorSeverity.success : ErrorSeverity.warning,
            showRetryButton: false,
            showDismissButton: false,
          ),

        const SizedBox(height: 24),

        // Conversion buttons
        Text(
          l10n.convertToAutomaton,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 420) {
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _convertToNFA,
                      icon: const Icon(Icons.account_tree),
                      label: Text(l10n.convertToNfa),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _convertToDFA,
                      icon: const Icon(Icons.account_tree_outlined),
                      label: Text(l10n.convertToDfa),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _convertToNFA,
                    icon: const Icon(Icons.account_tree),
                    label: Text(l10n.convertToNfa),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _convertToDFA,
                    icon: const Icon(Icons.account_tree_outlined),
                    label: Text(l10n.convertToDfa),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // FA→Regex conversion result display
        if (faToRegexWidget != null) ...[
          faToRegexWidget,
          const SizedBox(height: 16),
        ],

        // Simplification toggle
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SwitchSettingTile(
              title: l10n.simplifyOutput,
              subtitle: l10n.simplifyOutputSubtitle,
              value: _simplifyOutput,
              onChanged: _setSimplifyOutput,
              switchKey: const ValueKey('regex_simplify_output_switch'),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Simplification steps section
        _buildSimplificationStepsSection(),

        const SizedBox(height: 16),

        // Complexity analysis section
        _buildComplexityAnalysisSection(),

        const SizedBox(height: 16),

        // Sample strings section
        _buildSampleStringsSection(),

        const SizedBox(height: 24),

        // Compare regular expressions
        Text(
          l10n.compareRegularExpressions,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comparisonRegexController,
          decoration: InputDecoration(
            hintText: l10n.comparisonRegexHint,
            border: const OutlineInputBorder(),
          ),
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: _compareRegexEquivalence,
            icon: const Icon(Icons.compare_arrows),
            label: Text(l10n.compareEquivalence),
          ),
        ),
        if (_equivalenceMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          ErrorBanner(
            message: _equivalenceMessage,
            severity: _equivalenceResult == true
                ? ErrorSeverity.success
                : ErrorSeverity.warning,
            showRetryButton: false,
            showDismissButton: false,
          ),
        ],

        const SizedBox(height: 24),

        // Help section
        SizedBox(
          width: double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.regexHelp,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.regexHelpPatterns,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _clearInputs() {
    _regexController.clear();
    _testStringController.clear();
    _comparisonRegexController.clear();
    ref.read(automatonAlgorithmProvider.notifier).clearAlgorithmResults();
    _resetClearedInputsState();
  }

  Widget? _buildFaToRegexResult(
    AlgorithmOperationState algorithmState,
  ) {
    final l10n = AppLocalizations.of(context);

    // Only show if we have conversion results
    if (algorithmState.rawRegexResult == null &&
        algorithmState.simplifiedRegexResult == null) {
      return null;
    }

    final rawRegex = algorithmState.rawRegexResult;
    final simplifiedRegex = algorithmState.simplifiedRegexResult;
    final displayedFromSimplified =
        (_simplifyOutput && simplifiedRegex != null) ||
            (!_simplifyOutput && rawRegex == null && simplifiedRegex != null);
    final displayedRegex = displayedFromSimplified ? simplifiedRegex : rawRegex;

    if (displayedRegex == null) return null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  displayedFromSimplified
                      ? l10n.convertedRegexSimplified
                      : l10n.convertedRegexRaw,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    try {
                      await Clipboard.setData(
                        ClipboardData(text: displayedRegex),
                      );
                    } catch (error) {
                      debugPrint('Failed to copy regex: $error');
                      return;
                    }
                    if (!mounted) return;
                    _showFeedback(
                      l10n.regexCopiedToClipboard,
                      tone: AppSnackBarTone.success,
                    );
                  },
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: l10n.copyToClipboard,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: SelectableText(
                displayedRegex,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (algorithmState.rawRegexResult != null &&
                algorithmState.simplifiedRegexResult != null &&
                algorithmState.rawRegexResult !=
                    algorithmState.simplifiedRegexResult)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _simplifyOutput
                      ? l10n.toggleOffRawOutput
                      : l10n.toggleOnSimplifiedOutput,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
