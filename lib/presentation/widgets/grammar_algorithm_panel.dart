import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/grammar_analyzer.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/result.dart';
import '../providers/automaton_provider.dart';
import '../providers/grammar_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/pda_editor_provider.dart';

/// Panel for grammar analysis algorithms
class GrammarAlgorithmPanel extends ConsumerStatefulWidget {
  const GrammarAlgorithmPanel({super.key});

  @override
  ConsumerState<GrammarAlgorithmPanel> createState() =>
      _GrammarAlgorithmPanelState();
}

class _GrammarAlgorithmPanelState extends ConsumerState<GrammarAlgorithmPanel> {
  bool _isAnalyzing = false;
  String? _analysisResult;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildAlgorithmButtons(context),
            const SizedBox(height: 16),
            _buildResultsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Grammar Analysis',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAlgorithmButtons(BuildContext context) {
    final grammarState = ref.watch(grammarProvider);
    return Column(
      children: [
        _buildConversionSection(context, grammarState),
        const SizedBox(height: 24),
        _buildAlgorithmButton(
          context,
          title: 'Remove Left Recursion',
          description: 'Eliminate left recursion from grammar',
          icon: Icons.transform,
          onPressed: _removeLeftRecursion,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Left Factor',
          description: 'Apply left factoring to grammar',
          icon: Icons.account_tree,
          onPressed: _leftFactor,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Find First Sets',
          description: 'Calculate FIRST sets for all variables',
          icon: Icons.first_page,
          onPressed: _findFirstSets,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Find Follow Sets',
          description: 'Calculate FOLLOW sets for all variables',
          icon: Icons.last_page,
          onPressed: _findFollowSets,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Build Parse Table',
          description: 'Generate LL(1) or LR(1) parse table',
          icon: Icons.table_chart,
          onPressed: _buildParseTable,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Check Ambiguity',
          description: 'Detect if grammar is ambiguous',
          icon: Icons.help_outline,
          onPressed: _checkAmbiguity,
        ),
      ],
    );
  }

  Widget _buildConversionSection(
    BuildContext context,
    GrammarState grammarState,
  ) {
    final hasProductions = grammarState.productions.isNotEmpty;
    final isBusy = grammarState.isConverting;
    final isDisabled = isBusy || !hasProductions;
    final activeConversion = grammarState.activeConversion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conversions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildConversionButton(
          context,
          label: 'Convert Right-Linear Grammar to FSA',
          processingLabel: 'Converting to FSA...',
          icon: Icons.sync_alt,
          isProcessing: isBusy &&
              activeConversion == GrammarConversionType.grammarToFsa,
          isDisabled: isDisabled,
          onPressed: _convertToAutomaton,
        ),
        const SizedBox(height: 12),
        _buildConversionButton(
          context,
          label: 'Convert Grammar to PDA (General)',
          processingLabel: 'Converting to PDA...',
          icon: Icons.auto_fix_high,
          isProcessing: isBusy &&
              activeConversion == GrammarConversionType.grammarToPda,
          isDisabled: isDisabled,
          onPressed: _convertToPdaGeneral,
        ),
        const SizedBox(height: 12),
        _buildConversionButton(
          context,
          label: 'Convert Grammar to PDA (Standard)',
          processingLabel: 'Converting (Standard)...',
          icon: Icons.layers,
          isProcessing: isBusy &&
              activeConversion == GrammarConversionType.grammarToPdaStandard,
          isDisabled: isDisabled,
          onPressed: _convertToPdaStandard,
        ),
        const SizedBox(height: 12),
        _buildConversionButton(
          context,
          label: 'Convert Grammar to PDA (Greibach)',
          processingLabel: 'Converting (Greibach)...',
          icon: Icons.stacked_bar_chart,
          isProcessing: isBusy &&
              activeConversion == GrammarConversionType.grammarToPdaGreibach,
          isDisabled: isDisabled,
          onPressed: _convertToPdaGreibach,
        ),
        if (!hasProductions)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Add at least one production rule to enable conversions.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        if (grammarState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              grammarState.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlgorithmButton(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _isAnalyzing ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isAnalyzing
                ? colorScheme.outline.withValues(alpha: 0.3)
                : colorScheme.primary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: _isAnalyzing
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _isAnalyzing ? colorScheme.outline : colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _isAnalyzing
                          ? colorScheme.outline
                          : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (_isAnalyzing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.primary.withValues(alpha: 0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToAutomaton() async {
    final result = await ref
        .read(grammarProvider.notifier)
        .convertToAutomaton();

    if (!mounted) return;

    if (result.isSuccess) {
      final automaton = result.data!;
      ref.read(automatonProvider.notifier).updateAutomaton(automaton);

      if (!mounted) return;

      ref.read(homeNavigationProvider.notifier).goToFsa();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Grammar converted to automaton. Switched to FSA workspace.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final message = result.error ?? 'Failed to convert grammar to automaton.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildConversionButton(
    BuildContext context, {
    required String label,
    required String processingLabel,
    required IconData icon,
    required bool isProcessing,
    required bool isDisabled,
    required Future<void> Function() onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isDisabled
            ? null
            : () async {
                await onPressed();
              },
        icon: isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(isProcessing ? processingLabel : label),
      ),
    );
  }

  Future<void> _convertToPdaGeneral() {
    return _handlePdaConversion(
      convert: () => ref.read(grammarProvider.notifier).convertToPda(),
      successMessage:
          'Grammar converted to PDA (general). Switched to PDA workspace.',
    );
  }

  Future<void> _convertToPdaStandard() {
    return _handlePdaConversion(
      convert: () =>
          ref.read(grammarProvider.notifier).convertToPdaStandard(),
      successMessage:
          'Grammar converted to PDA (standard). Switched to PDA workspace.',
    );
  }

  Future<void> _convertToPdaGreibach() {
    return _handlePdaConversion(
      convert: () =>
          ref.read(grammarProvider.notifier).convertToPdaGreibach(),
      successMessage:
          'Grammar converted to PDA (Greibach). Switched to PDA workspace.',
    );
  }

  Future<void> _handlePdaConversion({
    required Future<Result<PDA>> Function() convert,
    required String successMessage,
  }) async {
    final result = await convert();

    if (!mounted) return;

    if (result.isSuccess) {
      final pda = result.data!;
      ref.read(pdaEditorProvider.notifier).setPda(pda);
      ref.read(homeNavigationProvider.notifier).goToPda();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final message = result.error ?? 'Failed to convert grammar to PDA.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildResultsSection(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Results',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _analysisResult == null
                ? _buildEmptyResults(context)
                : _buildResults(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No analysis results yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an algorithm above to analyze your grammar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Text(
          _analysisResult!,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
        ),
      ),
    );
  }

  void _removeLeftRecursion() {
    _performAnalysis<Grammar>(
      'Remove Left Recursion',
      (grammar) async => GrammarAnalyzer.removeDirectLeftRecursion(grammar),
      (original, report) => _formatTransformationResult(
        title: 'Left Recursion Removal Analysis',
        original: original,
        transformed: report.value,
        notes: report.notes,
        derivations: report.derivations,
      ),
    );
  }

  void _leftFactor() {
    _performAnalysis<Grammar>(
      'Left Factoring',
      (grammar) async => GrammarAnalyzer.leftFactor(grammar),
      (original, report) => _formatTransformationResult(
        title: 'Left Factoring Analysis',
        original: original,
        transformed: report.value,
        notes: report.notes,
        derivations: report.derivations,
      ),
    );
  }

  void _findFirstSets() {
    _performAnalysis<Map<String, Set<String>>>(
      'FIRST Sets',
      (grammar) async => GrammarAnalyzer.computeFirstSets(grammar),
      (original, report) => _formatSetResult(
        title: 'FIRST Sets Analysis',
        sets: report.value,
        notes: report.notes,
        derivations: report.derivations,
      ),
    );
  }

  void _findFollowSets() {
    _performAnalysis<Map<String, Set<String>>>(
      'FOLLOW Sets',
      (grammar) async => GrammarAnalyzer.computeFollowSets(grammar),
      (original, report) => _formatSetResult(
        title: 'FOLLOW Sets Analysis',
        sets: report.value,
        notes: report.notes,
        derivations: report.derivations,
      ),
    );
  }

  void _buildParseTable() {
    _performAnalysis<LL1ParseTable>(
      'LL(1) Parse Table',
      (grammar) async => GrammarAnalyzer.buildLL1ParseTable(grammar),
      (original, report) => _formatParseTableResult(report),
    );
  }

  void _checkAmbiguity() {
    _performAnalysis<bool>(
      'Ambiguity Check',
      (grammar) async => GrammarAnalyzer.detectAmbiguity(grammar),
      (original, report) => _formatAmbiguityResult(report),
    );
  }

  Future<void> _performAnalysis<T>(
    String algorithmName,
    Future<Result<GrammarAnalysisReport<T>>> Function(Grammar grammar)
    runAnalysis,
    String Function(Grammar original, GrammarAnalysisReport<T> report)
    formatter,
  ) async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    final grammar = ref.read(grammarProvider.notifier).buildGrammar();
    final validationErrors = grammar.validate();

    if (validationErrors.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _analysisResult = _formatError(
          'Cannot run $algorithmName due to grammar validation errors',
          validationErrors,
        );
      });
      return;
    }

    try {
      final result = await runAnalysis(grammar);
      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _analysisResult = result.isSuccess
            ? formatter(grammar, result.data!)
            : '$algorithmName failed: ${result.error}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _analysisResult = '$algorithmName failed: $error';
      });
    }
  }

  String _formatTransformationResult({
    required String title,
    required Grammar original,
    required Grammar transformed,
    required List<String> notes,
    required List<String> derivations,
  }) {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('')
      ..writeln('Original Grammar:')
      ..writeln(_formatGrammar(original))
      ..writeln('')
      ..writeln('Transformed Grammar:')
      ..writeln(_formatGrammar(transformed));

    _appendSection(buffer, 'Notes', notes);
    _appendSection(buffer, 'Derivations', derivations);

    return buffer.toString();
  }

  String _formatSetResult({
    required String title,
    required Map<String, Set<String>> sets,
    required List<String> notes,
    required List<String> derivations,
  }) {
    final entries = sets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('');

    for (final entry in entries) {
      final values = entry.value.toList()..sort(_symbolComparator);
      final label = title.contains('FOLLOW') ? 'FOLLOW' : 'FIRST';
      buffer.writeln('$label(${entry.key}) = {${values.join(', ')}}');
    }

    _appendSection(buffer, 'Notes', notes);
    _appendSection(buffer, 'Derivations', derivations);

    return buffer.toString();
  }

  String _formatParseTableResult(GrammarAnalysisReport<LL1ParseTable> report) {
    final table = report.value;
    final terminals = table.terminals.toList()..sort(_symbolComparator);
    final nonTerminals = table.nonTerminals.toList()..sort(_symbolComparator);
    final buffer = StringBuffer()
      ..writeln('LL(1) Parse Table Analysis')
      ..writeln('');

    buffer.writeln(['NT', ...terminals].join('\t'));
    for (final nt in nonTerminals) {
      final row = <String>[nt];
      for (final terminal in terminals) {
        final entries = table.table[nt]?[terminal] ?? const <List<String>>[];
        if (entries.isEmpty) {
          row.add('-');
        } else {
          row.add(
            entries
                .map((symbols) => symbols.isEmpty ? 'ε' : symbols.join(' '))
                .join(' | '),
          );
        }
      }
      buffer.writeln(row.join('\t'));
    }

    _appendSection(buffer, 'Notes', report.notes);
    _appendSection(buffer, 'Conflicts', report.conflicts);
    _appendSection(buffer, 'Derivations', report.derivations);

    return buffer.toString();
  }

  String _formatAmbiguityResult(GrammarAnalysisReport<bool> report) {
    final status = report.value ? 'Unambiguous' : 'Ambiguous';
    final buffer = StringBuffer()
      ..writeln('Ambiguity Analysis')
      ..writeln('')
      ..writeln('Status: $status');

    _appendSection(buffer, 'Notes', report.notes);
    _appendSection(buffer, 'Conflicts', report.conflicts);
    _appendSection(buffer, 'Derivations', report.derivations);

    return buffer.toString();
  }

  String _formatGrammar(Grammar grammar) {
    final productions = grammar.productions.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final grouped = <String, List<String>>{};

    for (final production in productions) {
      if (production.leftSide.isEmpty) {
        continue;
      }
      final left = production.leftSide.first;
      final right = production.isLambda || production.rightSide.isEmpty
          ? 'ε'
          : production.rightSide.join(' ');
      grouped.putIfAbsent(left, () => <String>[]).add(right);
    }

    final nonTerminals = grouped.keys.toList()..sort(_symbolComparator);
    return nonTerminals
        .map((nt) => '$nt → ${grouped[nt]!.join(' | ')}')
        .join('\n');
  }

  void _appendSection(StringBuffer buffer, String title, List<String> entries) {
    if (entries.isEmpty) {
      return;
    }

    buffer
      ..writeln('')
      ..writeln('$title:');
    for (final entry in entries) {
      buffer.writeln('- $entry');
    }
  }

  String _formatError(String heading, List<String> messages) {
    final buffer = StringBuffer()
      ..writeln(heading)
      ..writeln('');

    for (final message in messages) {
      buffer.writeln('- $message');
    }

    return buffer.toString();
  }

  int _symbolComparator(String a, String b) {
    if (a == b) {
      return 0;
    }
    return a.compareTo(b);
  }
}
