//
//  grammar_simulation_panel.dart
//  JFlutter
//
//  Constrói painel interativo para testar cadeias em gramáticas aplicando algoritmos como CYK, LL e LR. Gerencia seleção de estratégia, entradas do usuário, execução assíncrona e apresentação de resultados com métricas de tempo e passos.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/grammar_parser.dart';
import '../../core/models/grammar.dart';
import '../../core/result.dart';
import '../providers/grammar_provider.dart';

/// Panel for grammar parsing and string testing
class GrammarSimulationPanel extends ConsumerStatefulWidget {
  const GrammarSimulationPanel({super.key, this.useExpanded = true});

  final bool useExpanded;

  @override
  ConsumerState<GrammarSimulationPanel> createState() =>
      _GrammarSimulationPanelState();
}

class _GrammarSimulationPanelState
    extends ConsumerState<GrammarSimulationPanel> {
  final TextEditingController _inputController = TextEditingController();

  bool _isParsing = false;
  String? _parseResult;
  List<String> _parseSteps = [];
  Duration? _executionTime;
  String _selectedAlgorithm = 'CYK';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

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
            _buildAlgorithmSelector(context),
            const SizedBox(height: 16),
            _buildInputSection(context),
            const SizedBox(height: 16),
            _buildParseButton(context),
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
        Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Grammar Parser',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAlgorithmSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parsing Algorithm',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedAlgorithm,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'CYK',
                child: Text('CYK (Cocke-Younger-Kasami)'),
              ),
              DropdownMenuItem(value: 'LL', child: Text('LL Parser')),
              DropdownMenuItem(value: 'LR', child: Text('LR Parser')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedAlgorithm = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test String',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: 'Input String',
              hintText: 'e.g., aabb, abab, ε',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _parseString(),
          ),
          const SizedBox(height: 8),
          Text(
            'Examples: aabb, abab, aabbb (for S → aSb | ab)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isParsing ? null : _parseString,
        icon: _isParsing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isParsing ? 'Parsing...' : 'Parse String'),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parse Results',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (widget.useExpanded)
          Expanded(
            child: _parseResult == null
                ? _buildEmptyResults(context)
                : _buildResults(context),
          )
        else
          _parseResult == null
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
            Icons.psychology,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No parse results yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a string and click Parse to see results',
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
    final isAccepted = _parseResult == 'Accepted';
    final color = isAccepted ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _parseResult!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_executionTime != null) ...[
            const SizedBox(height: 8),
            Text(
              'Execution time: ${_formatExecutionTime(_executionTime!)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (_parseSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Parse Steps:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _parseSteps.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${index + 1}. ${_parseSteps[index]}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _parseString() async {
    final inputString = _inputController.text.trim();

    if (inputString.isEmpty) {
      _showError('Please enter a string to parse');
      return;
    }

    final grammar = _buildCurrentGrammar();

    setState(() {
      _isParsing = true;
      _parseResult = null;
      _parseSteps.clear();
      _executionTime = null;
    });

    try {
      final parseOutcome = await Future<Result<ParseResult>>(() {
        return GrammarParser.parse(
          grammar,
          inputString,
          strategyHint: _mapSelectedAlgorithmToHint(),
        );
      });

      if (!mounted) {
        return;
      }

      if (!parseOutcome.isSuccess) {
        setState(() {
          _isParsing = false;
          _parseResult = null;
          _parseSteps = [];
          _executionTime = null;
        });
        _showError(parseOutcome.error ?? 'Failed to parse string');
        return;
      }

      final parseResult = parseOutcome.data!;
      final steps = _buildParseSteps(parseResult);

      setState(() {
        _isParsing = false;
        _parseResult = parseResult.accepted ? 'Accepted' : 'Rejected';
        _parseSteps = steps;
        _executionTime = parseResult.executionTime;
      });

      if (!parseResult.accepted && parseResult.errorMessage != null) {
        _showError(parseResult.errorMessage!);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isParsing = false;
        _parseResult = null;
        _parseSteps = [];
        _executionTime = null;
      });

      _showError('Failed to parse string: $e');
    }
  }

  Grammar _buildCurrentGrammar() {
    return ref.read(grammarProvider.notifier).buildGrammar();
  }

  ParsingStrategyHint _mapSelectedAlgorithmToHint() {
    switch (_selectedAlgorithm) {
      case 'CYK':
        return ParsingStrategyHint.cyk;
      case 'LL':
        return ParsingStrategyHint.ll;
      case 'LR':
        return ParsingStrategyHint.lr;
      default:
        return ParsingStrategyHint.auto;
    }
  }

  List<String> _buildParseSteps(ParseResult parseResult) {
    final steps = <String>[];

    if (parseResult.derivations.isNotEmpty) {
      for (final derivation in parseResult.derivations) {
        steps.add(derivation.join(' ⇒ '));
      }
    } else if (parseResult.accepted) {
      steps.add('No derivation steps available for this parser.');
    }

    if (parseResult.errorMessage != null &&
        parseResult.errorMessage!.isNotEmpty) {
      steps.add(parseResult.errorMessage!);
    }

    return steps;
  }

  String _formatExecutionTime(Duration duration) {
    if (duration.inMicroseconds < 1000) {
      return '${duration.inMicroseconds} μs';
    }
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds} ms';
    }
    return '${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')} s';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
