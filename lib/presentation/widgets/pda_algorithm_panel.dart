//
//  pda_algorithm_panel.dart
//  JFlutter
//
//  Apresenta hub de algoritmos para autômatos de pilha disponibilizando conversões, verificações e diagnósticos. Coordena chamadas ao serviço de conversão, exibe estados de carregamento e resume resultados textuais para orientar ajustes no PDA.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/pda_simulator.dart';
import '../../core/models/grammar.dart';
import '../../core/models/state.dart' as automaton_models;
import '../../data/services/conversion_service.dart';
import '../providers/pda_editor_provider.dart';
import 'common/algorithm_button.dart';
import 'common/algorithm_panel_header.dart';

/// Panel for PDA analysis algorithms
class PDAAlgorithmPanel extends ConsumerStatefulWidget {
  const PDAAlgorithmPanel({super.key, this.useExpanded = true});

  final bool useExpanded;

  @override
  ConsumerState<PDAAlgorithmPanel> createState() => _PDAAlgorithmPanelState();
}

class _PDAAlgorithmPanelState extends ConsumerState<PDAAlgorithmPanel> {
  bool _isAnalyzing = false;
  String? _analysisResult;
  Grammar? _latestConvertedGrammar;
  final ConversionService _conversionService = ConversionService();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AlgorithmPanelHeader(
              title: 'PDA Analysis',
              icon: Icons.auto_awesome,
            ),
            const SizedBox(height: 16),
            _buildAlgorithmButtons(context),
            const SizedBox(height: 16),
            _buildResultsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgorithmButtons(BuildContext context) {
    return Column(
      children: [
        AlgorithmButton(
          title: 'Convert to CFG',
          description: 'Convert PDA to equivalent context-free grammar',
          icon: Icons.transform,
          onPressed: _convertToCFG,
          isExecuting: _isAnalyzing,
        ),
        const SizedBox(height: 12),
        AlgorithmButton(
          title: 'Minimize PDA',
          description: 'Minimize the number of states in PDA',
          icon: Icons.compress,
          onPressed: _minimizePDA,
          isExecuting: _isAnalyzing,
        ),
        const SizedBox(height: 12),
        AlgorithmButton(
          title: 'Check Determinism',
          description: 'Determine if PDA is deterministic',
          icon: Icons.help_outline,
          onPressed: _checkDeterminism,
          isExecuting: _isAnalyzing,
        ),
        const SizedBox(height: 12),
        AlgorithmButton(
          title: 'Find Reachable States',
          description: 'Identify reachable states from initial state',
          icon: Icons.explore,
          onPressed: _findReachableStates,
          isExecuting: _isAnalyzing,
        ),
        const SizedBox(height: 12),
        AlgorithmButton(
          title: 'Language Analysis',
          description: 'Analyze the language accepted by PDA',
          icon: Icons.analytics,
          onPressed: _analyzeLanguage,
          isExecuting: _isAnalyzing,
        ),
        const SizedBox(height: 12),
        AlgorithmButton(
          title: 'Stack Operations',
          description: 'Analyze stack operations and depth',
          icon: Icons.storage,
          onPressed: _analyzeStackOperations,
          isExecuting: _isAnalyzing,
        ),
      ],
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Results',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (widget.useExpanded) Expanded(
                child: _analysisResult == null
                    ? _buildEmptyResults(context)
                    : _buildResults(context),
              ) else _analysisResult == null
                ? _buildEmptyResults(context)
                : _buildResults(context),
      ],
    );

    return widget.useExpanded ? Expanded(child: content) : content;
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
            'Select an algorithm above to analyze your PDA',
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
    final grammar = _latestConvertedGrammar;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              _analysisResult!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            if (grammar != null) ...[
              const SizedBox(height: 16),
              Divider(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              _buildGrammarSummary(context, grammar),
            ],
          ],
        ),
      ),
    );
  }

  void _convertToCFG() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar('Draw a PDA before converting to a grammar.');
      return;
    }

    setState(() {
      _latestConvertedGrammar = null;
    });

    _performAnalysis('PDA to CFG Conversion', () async {
      final conversionResult = _conversionService.convertPdaToCfg(
        ConversionRequest.pdaToCfg(pda: pda),
      );
      if (conversionResult.isSuccess) {
        _latestConvertedGrammar = conversionResult.data!.grammar;
        final grammar = _latestConvertedGrammar!;
        final extraSummary =
            'Generated grammar has ${grammar.productions.length} productions '
            'and ${grammar.nonterminals.length} non-terminals.';
        return '${conversionResult.data!.description}\n$extraSummary';
      }

      final message = 'Conversion failed: ${conversionResult.error}';
      _latestConvertedGrammar = null;
      _showSnackbar(message);
      return message;
    },
        resetConvertedGrammar: false);
  }

  void _minimizePDA() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar('Create a PDA to analyze minimization.');
      return;
    }

    _performAnalysis('PDA Minimization', () async {
      final simplificationResult = PDASimulator.simplify(pda);
      if (!simplificationResult.isSuccess) {
        final message = 'Minimization failed: ${simplificationResult.error}';
        _showSnackbar(message);
        return message;
      }

      final summary = simplificationResult.data!;
      ref.read(pdaEditorProvider.notifier).setPda(summary.minimizedPda);

      final buffer = StringBuffer();

      buffer.writeln(
        summary.changed
            ? 'PDA minimization applied successfully.'
            : 'The PDA is already minimal; no structural changes were required.',
      );
      buffer.writeln(
        'States: ${pda.states.length} → ${summary.minimizedPda.states.length}',
      );
      buffer.writeln(
        'Transitions: ${pda.pdaTransitions.length} → ${summary.minimizedPda.pdaTransitions.length}',
      );

      if (summary.unreachableStates.isNotEmpty) {
        buffer.writeln(
          'Removed unreachable states: ${_formatStateList(summary.unreachableStates)}',
        );
      }

      final removedNonProductive = summary.nonProductiveStates
          .difference(summary.unreachableStates)
          .intersection(summary.removedStates);
      if (removedNonProductive.isNotEmpty) {
        buffer.writeln(
          'Removed nonproductive states: ${_formatStateList(removedNonProductive)}',
        );
      }

      final mergedGroups = summary.mergeGroups.where(
        (group) => group.isMeaningful,
      );
      if (mergedGroups.isNotEmpty) {
        buffer.writeln('Merged equivalent states:');
        for (final group in mergedGroups) {
          final mergedNames = _formatStateList(group.mergedStates);
          buffer.writeln(
            '  $mergedNames → ${_formatStateName(group.representative)}',
          );
        }
      }

      if (summary.removedTransitionIds.isNotEmpty) {
        buffer.writeln(
          'Removed redundant transitions: ${summary.removedTransitionIds.length}',
        );
      }

      if (summary.warnings.isNotEmpty) {
        buffer.writeln('Warnings:');
        for (final warning in summary.warnings) {
          buffer.writeln('  • $warning');
        }
      }

      buffer.writeln('');
      buffer.writeln(
        'Resulting states: ${_formatStateList(summary.minimizedPda.states)}',
      );

      return buffer.toString();
    });
  }

  void _checkDeterminism() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar('Create a PDA to analyze determinism.');
      return;
    }

    _performAnalysis('Determinism Check', () async {
      final nondeterministicTransitions =
          editorState.nondeterministicTransitionIds;
      final buffer = StringBuffer();
      buffer.writeln('Determinism Analysis');
      buffer.writeln('Total transitions: ${pda.transitions.length}');
      buffer.writeln('');

      if (nondeterministicTransitions.isEmpty) {
        buffer.writeln(
          'Result: PDA is deterministic (no conflicting transitions).',
        );
      } else {
        buffer.writeln('Result: PDA is NON-deterministic.');
        buffer.writeln('Conflicting transitions:');
        for (final transition in pda.pdaTransitions) {
          if (nondeterministicTransitions.contains(transition.id)) {
            final input =
                transition.isLambdaInput || transition.inputSymbol.isEmpty
                ? 'λ'
                : transition.inputSymbol;
            final pop = transition.isLambdaPop || transition.popSymbol.isEmpty
                ? 'λ'
                : transition.popSymbol;
            final push =
                transition.isLambdaPush || transition.pushSymbol.isEmpty
                ? 'λ'
                : transition.pushSymbol;
            buffer.writeln(
              '  ${transition.fromState.label} -- $input, pop $pop / push $push → ${transition.toState.label}',
            );
          }
        }
      }

      if (editorState.lambdaTransitionIds.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(
          'Lambda transitions present: ${editorState.lambdaTransitionIds.length}',
        );
      }

      return buffer.toString();
    });
  }

  void _findReachableStates() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar('Create a PDA to analyze reachability.');
      return;
    }

    _performAnalysis('Reachable States Analysis', () async {
      final analysisResult = PDASimulator.analyzePDA(pda);
      if (!analysisResult.isSuccess) {
        final message = 'Analysis failed: ${analysisResult.error}';
        _showSnackbar(message);
        return message;
      }

      final analysis = analysisResult.data!;
      final reachable =
          analysis.reachabilityAnalysis.reachableStates
              .map((state) => state.label)
              .toList()
            ..sort();
      final unreachable =
          analysis.reachabilityAnalysis.unreachableStates
              .map((state) => state.label)
              .toList()
            ..sort();

      final buffer = StringBuffer();
      buffer.writeln('Initial state: ${pda.initialState?.label ?? '—'}');
      buffer.writeln('Reachable states (${reachable.length}):');
      buffer.writeln(reachable.isEmpty ? '  ∅' : '  {${reachable.join(', ')}}');
      buffer.writeln('');
      buffer.writeln('Unreachable states (${unreachable.length}):');
      buffer.writeln(
        unreachable.isEmpty ? '  ∅' : '  {${unreachable.join(', ')}}',
      );

      return buffer.toString();
    });
  }

  void _analyzeLanguage() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar('Create a PDA to analyze its language.');
      return;
    }

    _performAnalysis('Language Analysis', () async {
      final analysisResult = PDASimulator.analyzePDA(pda);
      if (!analysisResult.isSuccess) {
        final message = 'Analysis failed: ${analysisResult.error}';
        _showSnackbar(message);
        return message;
      }

      final acceptedStringsResult = PDASimulator.findAcceptedStrings(
        pda,
        3,
        maxResults: 10,
      );
      final rejectedStringsResult = PDASimulator.findRejectedStrings(
        pda,
        3,
        maxResults: 10,
      );

      final acceptedStrings = acceptedStringsResult.isSuccess
          ? acceptedStringsResult.data!.toList()
          : <String>[];
      final rejectedStrings = rejectedStringsResult.isSuccess
          ? rejectedStringsResult.data!.toList()
          : <String>[];
      acceptedStrings.sort();
      rejectedStrings.sort();

      final analysis = analysisResult.data!;
      final buffer = StringBuffer();
      buffer.writeln('Input alphabet:');
      if (pda.alphabet.isEmpty) {
        buffer.writeln('  ∅');
      } else {
        final sortedAlphabet = pda.alphabet.toList()..sort();
        buffer.writeln('  {${sortedAlphabet.join(', ')}}');
      }
      buffer.writeln('Stack alphabet symbols observed:');
      final stackSymbols = analysis.stackAnalysis.stackSymbols.toList()..sort();
      buffer.writeln(
        stackSymbols.isEmpty ? '  ∅' : '  {${stackSymbols.join(', ')}}',
      );
      buffer.writeln('Accepting states:');
      final acceptingLabels = pda.acceptingStates.map((s) => s.label).toList()
        ..sort();
      buffer.writeln(
        acceptingLabels.isEmpty ? '  ∅' : '  {${acceptingLabels.join(', ')}}',
      );
      buffer.writeln('');
      buffer.writeln('Sample accepted strings (length ≤ 3):');
      buffer.writeln(
        acceptedStrings.isEmpty
            ? '  None found'
            : '  {${acceptedStrings.join(', ')}}',
      );
      buffer.writeln('Sample rejected strings (length ≤ 3):');
      buffer.writeln(
        rejectedStrings.isEmpty
            ? '  None found'
            : '  {${rejectedStrings.join(', ')}}',
      );
      buffer.writeln('');
      buffer.writeln('Determinism:');
      buffer.writeln(
        editorState.nondeterministicTransitionIds.isEmpty
            ? '  Appears deterministic'
            : '  Contains nondeterministic branching',
      );

      if (!acceptedStringsResult.isSuccess) {
        buffer.writeln('');
        buffer.writeln(
          'Warning: Failed to enumerate accepted strings: ${acceptedStringsResult.error}.',
        );
      }
      if (!rejectedStringsResult.isSuccess) {
        buffer.writeln('');
        buffer.writeln(
          'Warning: Failed to enumerate rejected strings: ${rejectedStringsResult.error}.',
        );
      }

      return buffer.toString();
    });
  }

  void _analyzeStackOperations() {
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    if (pda == null) {
      _showSnackbar('Create a PDA to inspect stack operations.');
      return;
    }

    _performAnalysis('Stack Operations Analysis', () async {
      final analysisResult = PDASimulator.analyzePDA(pda);
      if (!analysisResult.isSuccess) {
        final message = 'Analysis failed: ${analysisResult.error}';
        _showSnackbar(message);
        return message;
      }

      final analysis = analysisResult.data!;
      final pushOps = analysis.stackAnalysis.pushOperations.toList()..sort();
      final popOps = analysis.stackAnalysis.popOperations.toList()..sort();
      final stackSymbols = analysis.stackAnalysis.stackSymbols.toList()..sort();

      final buffer = StringBuffer();
      buffer.writeln('Initial stack symbol: ${pda.initialStackSymbol}');
      buffer.writeln('Push operations (${pushOps.length}):');
      buffer.writeln(pushOps.isEmpty ? '  None' : '  {${pushOps.join(', ')}}');
      buffer.writeln('Pop operations (${popOps.length}):');
      buffer.writeln(popOps.isEmpty ? '  None' : '  {${popOps.join(', ')}}');
      buffer.writeln('Stack symbols touched (${stackSymbols.length}):');
      buffer.writeln(
        stackSymbols.isEmpty ? '  None' : '  {${stackSymbols.join(', ')}}',
      );
      buffer.writeln('');
      buffer.writeln(
        'Total transitions: ${analysis.transitionAnalysis.totalTransitions}',
      );
      buffer.writeln(
        'PDA transitions: ${analysis.transitionAnalysis.pdaTransitions}, '
        'FSA transitions: ${analysis.transitionAnalysis.fsaTransitions}',
      );

      return buffer.toString();
    });
  }

  void _performAnalysis(
    String algorithmName,
    Future<String> Function() analysisFunction, {
    bool resetConvertedGrammar = true,
  }) {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      if (resetConvertedGrammar) {
        _latestConvertedGrammar = null;
      }
    });

    Future.microtask(() async {
      try {
        final output = await analysisFunction();
        if (!mounted) {
          return;
        }
        setState(() {
          _isAnalyzing = false;
          _analysisResult = '=== $algorithmName ===\n\n$output';
        });
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isAnalyzing = false;
          _analysisResult =
              '=== $algorithmName ===\n\nError running analysis: $error';
        });
      }
    });
  }

  Widget _buildGrammarSummary(BuildContext context, Grammar grammar) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final terminals = grammar.terminals.toList()..sort();
    final nonterminals = grammar.nonterminals.toList()..sort();
    final productions = grammar.productions.toList()
      ..sort((a, b) {
        final orderComparison = a.order.compareTo(b.order);
        if (orderComparison != 0) {
          return orderComparison;
        }
        return a.id.compareTo(b.id);
      });

    String formatSymbols(List<String> symbols) {
      if (symbols.isEmpty) {
        return 'ε';
      }
      return symbols.join(' ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generated Grammar',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Start symbol: ${grammar.startSymbol}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              'Non-terminals: {${nonterminals.join(', ')}}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            Text(
              'Terminals: {${terminals.join(', ')}}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Productions (${productions.length}):',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...productions.map(
          (production) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${formatSymbols(production.leftSide)} → '
              '${production.isLambda ? 'ε' : formatSymbols(production.rightSide)}',
              style: textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackbar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatStateList(Iterable<automaton_models.State> states) {
    final names = states.map(_formatStateName).toList()..sort();
    if (names.isEmpty) {
      return '∅';
    }
    return names.join(', ');
  }

  String _formatStateName(automaton_models.State state) {
    return state.label.isNotEmpty ? state.label : state.id;
  }
}
