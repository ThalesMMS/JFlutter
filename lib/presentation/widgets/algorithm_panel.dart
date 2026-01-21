//
//  algorithm_panel.dart
//  JFlutter
//
//  Consolida os comandos de algoritmos aplicáveis aos autômatos finitos,
//  reunindo conversões NFA→DFA, minimização, complementação, operações de
//  linguagem e transformações com expressões regulares em um painel único.
//  Controla progresso, feedback textual e carregamento de autômatos externos via
//  FilePicker, executando callbacks fornecidos pela camada de apresentação para
//  orquestrar AlgorithmOperations.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/models/fsa.dart';
import '../../data/services/file_operations_service.dart';
import 'common/algorithm_button.dart';
import 'utils/platform_file_loader.dart';

/// Panel for algorithm operations and controls
class AlgorithmPanel extends StatefulWidget {
  final VoidCallback? onNfaToDfa;
  final VoidCallback? onMinimizeDfa;
  final VoidCallback? onClear;
  final Function(String)? onRegexToNfa;
  final VoidCallback? onFaToRegex;
  final VoidCallback? onRemoveLambda;
  final VoidCallback? onCompleteDfa;
  final VoidCallback? onComplementDfa;
  final Future<void> Function(FSA other)? onUnionDfa;
  final Future<void> Function(FSA other)? onIntersectionDfa;
  final Future<void> Function(FSA other)? onDifferenceDfa;
  final VoidCallback? onPrefixClosure;
  final VoidCallback? onSuffixClosure;
  final VoidCallback? onFsaToGrammar;
  final VoidCallback? onAutoLayout;
  final Future<void> Function(FSA other)? onCompareEquivalence;
  final bool? equivalenceResult;
  final String? equivalenceDetails;
  final FileOperationsService fileService;

  AlgorithmPanel({
    super.key,
    this.onNfaToDfa,
    this.onMinimizeDfa,
    this.onClear,
    this.onRegexToNfa,
    this.onFaToRegex,
    this.onRemoveLambda,
    this.onCompleteDfa,
    this.onComplementDfa,
    this.onUnionDfa,
    this.onIntersectionDfa,
    this.onDifferenceDfa,
    this.onPrefixClosure,
    this.onSuffixClosure,
    this.onFsaToGrammar,
    this.onAutoLayout,
    this.onCompareEquivalence,
    this.equivalenceResult,
    this.equivalenceDetails,
    FileOperationsService? fileService,
  }) : fileService = fileService ?? FileOperationsService();

  @override
  State<AlgorithmPanel> createState() => _AlgorithmPanelState();
}

class _AlgorithmPanelState extends State<AlgorithmPanel> {
  final TextEditingController _regexController = TextEditingController();
  late final FileOperationsService _fileService;
  bool _isExecuting = false;
  String? _currentAlgorithm;
  double _executionProgress = 0.0;
  String? _executionStatus;
  List<AlgorithmStep> _algorithmSteps = [];
  int _currentStepIndex = 0;

  void _showSnack(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    final snackBar = SnackBar(
      content: Text(
        message,
        style: isError
            ? TextStyle(color: theme.colorScheme.onErrorContainer)
            : null,
      ),
      backgroundColor: isError ? theme.colorScheme.errorContainer : null,
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    _regexController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fileService = widget.fileService;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Algorithms',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Regex to NFA conversion
              _buildRegexInput(context),

              const SizedBox(height: 12),

              // NFA to DFA conversion
              AlgorithmButton(
                title: 'NFA to DFA',
                description:
                    'Convert non-deterministic to deterministic automaton',
                icon: Icons.transform,
                onPressed: widget.onNfaToDfa == null
                    ? null
                    : () => _executeAlgorithm('NFA to DFA', widget.onNfaToDfa),
                isExecuting: _isExecuting && _currentAlgorithm == 'NFA to DFA',
                isSelected: _currentAlgorithm == 'NFA to DFA',
                executionProgress: _currentAlgorithm == 'NFA to DFA'
                    ? _executionProgress
                    : null,
                executionStatus:
                    _currentAlgorithm == 'NFA to DFA' ? _executionStatus : null,
              ),

              const SizedBox(height: 12),

              // Remove lambda transitions
              AlgorithmButton(
                title: 'Remove λ-transitions',
                description: 'Eliminate epsilon transitions from the automaton',
                icon: Icons.highlight_off,
                onPressed: widget.onRemoveLambda == null
                    ? null
                    : () => _executeAlgorithm(
                          'Remove λ-transitions',
                          widget.onRemoveLambda,
                        ),
                isExecuting:
                    _isExecuting && _currentAlgorithm == 'Remove λ-transitions',
                isSelected: _currentAlgorithm == 'Remove λ-transitions',
                executionProgress: _currentAlgorithm == 'Remove λ-transitions'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'Remove λ-transitions'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // DFA minimization
              AlgorithmButton(
                title: 'Minimize DFA',
                description: 'Minimize deterministic finite automaton',
                icon: Icons.compress,
                onPressed: widget.onMinimizeDfa == null
                    ? null
                    : () =>
                        _executeAlgorithm('Minimize DFA', widget.onMinimizeDfa),
                isExecuting: _isExecuting && _currentAlgorithm == 'Minimize DFA',
                isSelected: _currentAlgorithm == 'Minimize DFA',
                executionProgress: _currentAlgorithm == 'Minimize DFA'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'Minimize DFA'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // Complete DFA
              AlgorithmButton(
                title: 'Complete DFA',
                description: 'Add trap state to make DFA complete',
                icon: Icons.add_circle_outline,
                onPressed: widget.onCompleteDfa == null
                    ? null
                    : () =>
                        _executeAlgorithm('Complete DFA', widget.onCompleteDfa),
                isExecuting: _isExecuting && _currentAlgorithm == 'Complete DFA',
                isSelected: _currentAlgorithm == 'Complete DFA',
                executionProgress: _currentAlgorithm == 'Complete DFA'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'Complete DFA'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // Complement DFA
              AlgorithmButton(
                title: 'Complement DFA',
                description: 'Flip accepting states after completion',
                icon: Icons.flip,
                onPressed: widget.onComplementDfa == null
                    ? null
                    : () => _executeAlgorithm(
                          'Complement DFA',
                          widget.onComplementDfa,
                        ),
                isExecuting:
                    _isExecuting && _currentAlgorithm == 'Complement DFA',
                isSelected: _currentAlgorithm == 'Complement DFA',
                executionProgress: _currentAlgorithm == 'Complement DFA'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'Complement DFA'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // Union of DFAs
              AlgorithmButton(
                title: 'Union of DFAs',
                description:
                    'Combine this DFA with another automaton from file',
                icon: Icons.merge_type,
                onPressed: () => _runBinaryOperation(
                  algorithmName: 'Union of DFAs',
                  callback: widget.onUnionDfa,
                  dialogTitle: 'Select DFA for union',
                  steps: _buildBinaryOperationSteps(
                    actionTitle: 'Compute Union',
                    actionDescription:
                        'Create the product automaton accepting when either DFA accepts',
                  ),
                  executingStatus: 'Building union automaton...',
                  successStatus: 'Union complete',
                  missingCallbackMessage:
                      'Load a DFA before computing the union.',
                ),
                isExecuting: _isExecuting && _currentAlgorithm == 'Union of DFAs',
                isSelected: _currentAlgorithm == 'Union of DFAs',
                executionProgress: _currentAlgorithm == 'Union of DFAs'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'Union of DFAs'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // Intersection of DFAs
              AlgorithmButton(
                title: 'Intersection of DFAs',
                description:
                    'Intersect this DFA with another automaton from file',
                icon: Icons.call_merge,
                onPressed: () => _runBinaryOperation(
                  algorithmName: 'Intersection of DFAs',
                  callback: widget.onIntersectionDfa,
                  dialogTitle: 'Select DFA for intersection',
                  steps: _buildBinaryOperationSteps(
                    actionTitle: 'Compute Intersection',
                    actionDescription:
                        'Construct the product automaton accepting when both DFAs accept',
                  ),
                  executingStatus: 'Building intersection automaton...',
                  successStatus: 'Intersection complete',
                  missingCallbackMessage:
                      'Load a DFA before computing the intersection.',
                ),
                isExecuting:
                    _isExecuting && _currentAlgorithm == 'Intersection of DFAs',
                isSelected: _currentAlgorithm == 'Intersection of DFAs',
                executionProgress: _currentAlgorithm == 'Intersection of DFAs'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'Intersection of DFAs'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // Difference of DFAs
              AlgorithmButton(
                title: 'Difference of DFAs',
                description:
                    'Compute the language difference with another DFA from file',
                icon: Icons.call_split,
                onPressed: () => _runBinaryOperation(
                  algorithmName: 'Difference of DFAs',
                  callback: widget.onDifferenceDfa,
                  dialogTitle: 'Select DFA for difference',
                  steps: _buildBinaryOperationSteps(
                    actionTitle: 'Compute Difference',
                    actionDescription:
                        'Build the product automaton accepting strings in A but not in B',
                  ),
                  executingStatus: 'Building difference automaton...',
                  successStatus: 'Difference complete',
                  missingCallbackMessage:
                      'Load a DFA before computing the difference.',
                ),
                isExecuting:
                    _isExecuting && _currentAlgorithm == 'Difference of DFAs',
                isSelected: _currentAlgorithm == 'Difference of DFAs',
                executionProgress: _currentAlgorithm == 'Difference of DFAs'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'Difference of DFAs'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // Prefix closure
              AlgorithmButton(
                title: 'Prefix Closure',
                description: 'Accept all prefixes of the DFA language',
                icon: Icons.vertical_align_top,
                onPressed: widget.onPrefixClosure == null
                    ? null
                    : () => _executeAlgorithm(
                          'Prefix Closure',
                          widget.onPrefixClosure,
                        ),
                isExecuting:
                    _isExecuting && _currentAlgorithm == 'Prefix Closure',
                isSelected: _currentAlgorithm == 'Prefix Closure',
                executionProgress: _currentAlgorithm == 'Prefix Closure'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'Prefix Closure'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // Suffix closure
              AlgorithmButton(
                title: 'Suffix Closure',
                description: 'Accept all suffixes of the DFA language',
                icon: Icons.vertical_align_bottom,
                onPressed: widget.onSuffixClosure == null
                    ? null
                    : () => _executeAlgorithm(
                          'Suffix Closure',
                          widget.onSuffixClosure,
                        ),
                isExecuting:
                    _isExecuting && _currentAlgorithm == 'Suffix Closure',
                isSelected: _currentAlgorithm == 'Suffix Closure',
                executionProgress: _currentAlgorithm == 'Suffix Closure'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'Suffix Closure'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // FA to Regex conversion
              AlgorithmButton(
                title: 'FA to Regex',
                description: 'Convert finite automaton to regular expression',
                icon: Icons.text_fields,
                onPressed: widget.onFaToRegex == null
                    ? null
                    : () => _executeAlgorithm('FA to Regex', widget.onFaToRegex),
                isExecuting: _isExecuting && _currentAlgorithm == 'FA to Regex',
                isSelected: _currentAlgorithm == 'FA to Regex',
                executionProgress: _currentAlgorithm == 'FA to Regex'
                    ? _executionProgress
                    : null,
                executionStatus:
                    _currentAlgorithm == 'FA to Regex' ? _executionStatus : null,
              ),

              const SizedBox(height: 12),

              // FSA to Grammar conversion
              AlgorithmButton(
                title: 'FSA to Grammar',
                description: 'Convert finite automaton to regular grammar',
                icon: Icons.transform,
                onPressed: widget.onFsaToGrammar == null
                    ? null
                    : () => _executeAlgorithm(
                          'FSA to Grammar',
                          widget.onFsaToGrammar,
                        ),
                isExecuting:
                    _isExecuting && _currentAlgorithm == 'FSA to Grammar',
                isSelected: _currentAlgorithm == 'FSA to Grammar',
                executionProgress: _currentAlgorithm == 'FSA to Grammar'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'FSA to Grammar'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // Auto Layout
              AlgorithmButton(
                title: 'Auto Layout',
                description: 'Arrange states in a circle',
                icon: Icons.auto_awesome_motion,
                onPressed: widget.onAutoLayout,
              ),

              const SizedBox(height: 12),

              // Compare Equivalence
              AlgorithmButton(
                title: 'Compare Equivalence',
                description: 'Compare two DFAs for equivalence',
                icon: Icons.compare_arrows,
                onPressed: _onCompareEquivalencePressed,
                isExecuting:
                    _isExecuting && _currentAlgorithm == 'Compare Equivalence',
                isSelected: _currentAlgorithm == 'Compare Equivalence',
                executionProgress: _currentAlgorithm == 'Compare Equivalence'
                    ? _executionProgress
                    : null,
                executionStatus: _currentAlgorithm == 'Compare Equivalence'
                    ? _executionStatus
                    : null,
              ),

              const SizedBox(height: 12),

              // Clear automaton
              AlgorithmButton(
                title: 'Clear',
                description: 'Clear current automaton',
                icon: Icons.clear,
                onPressed: widget.onClear,
                isDestructive: true,
              ),

              // Progress indicator
              if (_isExecuting) ...[
                const SizedBox(height: 16),
                _buildProgressIndicator(context),
              ],

              // Algorithm execution steps
              if (_algorithmSteps.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildAlgorithmSteps(context),
              ],

              if (widget.equivalenceResult != null ||
                  (widget.equivalenceDetails?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 16),
                _buildEquivalenceResult(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegexInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regex to NFA',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _regexController,
                decoration: const InputDecoration(
                  labelText: 'Regular Expression',
                  hintText: 'e.g., (a|b)*',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty && widget.onRegexToNfa != null) {
                    widget.onRegexToNfa!(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_regexController.text.isNotEmpty &&
                    widget.onRegexToNfa != null) {
                  widget.onRegexToNfa!(_regexController.text);
                }
              },
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildProgressIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
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
                'Executing $_currentAlgorithm',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _executionProgress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _executionStatus ?? 'Processing...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmSteps(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Algorithm Steps',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _algorithmSteps.length,
              itemBuilder: (context, index) {
                final step = _algorithmSteps[index];
                final isCurrentStep = index == _currentStepIndex;
                final isCompleted = index < _currentStepIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentStep
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : isCompleted
                        ? Theme.of(context).colorScheme.surface
                        : null,
                    border: Border.all(
                      color: isCurrentStep
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isCompleted
                            ? Colors.green
                            : isCurrentStep
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCurrentStep
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentStep)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AlgorithmStep> _buildBinaryOperationSteps({
    required String actionTitle,
    required String actionDescription,
  }) {
    return [
      AlgorithmStep(
        title: 'Load Automaton',
        description: 'Parse the selected JFLAP file',
      ),
      AlgorithmStep(
        title: 'Normalise DFAs',
        description: 'Align alphabets and ensure determinism',
      ),
      AlgorithmStep(title: actionTitle, description: actionDescription),
    ];
  }

  Future<void> _runBinaryOperation({
    required String algorithmName,
    required Future<void> Function(FSA other)? callback,
    required String dialogTitle,
    required List<AlgorithmStep> steps,
    required String executingStatus,
    required String successStatus,
    String? missingCallbackMessage,
  }) async {
    if (callback == null) {
      _showSnack(
        missingCallbackMessage ?? 'Load a DFA before executing $algorithmName.',
        isError: true,
      );
      return;
    }

    final selection = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: const ['jff'],
      withData: true,
    );

    if (selection == null || selection.files.isEmpty) {
      return;
    }

    final file = selection.files.single;
    setState(() {
      _isExecuting = true;
      _currentAlgorithm = algorithmName;
      _executionStatus = 'Loading automaton...';
      _executionProgress = 0.0;
      _algorithmSteps = steps;
      _currentStepIndex = steps.isEmpty ? 0 : 0;
    });

    final loadResult = await loadAutomatonFromPlatformFile(_fileService, file);

    if (!mounted) return;

    if (!loadResult.isSuccess) {
      setState(() {
        _isExecuting = false;
        _executionStatus = 'Failed to load automaton';
      });
      _showSnack(
        loadResult.error ?? 'Selected file did not contain readable data.',
        isError: true,
      );
      return;
    }

    if (steps.length > 1) {
      setState(() {
        _currentStepIndex = 1;
        _executionProgress = 1 / steps.length;
        _executionStatus = executingStatus;
      });
    } else {
      setState(() {
        _executionProgress = 0.5;
        _executionStatus = executingStatus;
      });
    }

    try {
      await callback(loadResult.data!);
      if (!mounted) return;
      setState(() {
        _isExecuting = false;
        _executionStatus = successStatus;
        _executionProgress = 1.0;
        _currentStepIndex = steps.isEmpty ? 0 : steps.length - 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExecuting = false;
        _executionStatus = '$algorithmName failed';
      });
      _showSnack('$algorithmName failed: $e', isError: true);
    }
  }

  Future<void> _onCompareEquivalencePressed() async {
    await _runBinaryOperation(
      algorithmName: 'Compare Equivalence',
      callback: widget.onCompareEquivalence,
      dialogTitle: 'Select DFA to compare',
      steps: [
        AlgorithmStep(
          title: 'Load Automaton',
          description: 'Parse the selected JFLAP file',
        ),
        AlgorithmStep(
          title: 'Normalize DFAs',
          description: 'Prepare automata for comparison',
        ),
        AlgorithmStep(
          title: 'Compare Languages',
          description: 'Search for distinguishing strings',
        ),
      ],
      executingStatus: 'Comparing automata...',
      successStatus: 'Comparison complete',
      missingCallbackMessage: 'Load a DFA before comparing equivalence.',
    );
  }

  Widget _buildEquivalenceResult(BuildContext context) {
    final result = widget.equivalenceResult;
    final message = widget.equivalenceDetails ?? '';
    final theme = Theme.of(context);
    final Color accent;
    IconData icon;

    if (result == null) {
      accent = theme.colorScheme.secondary;
      icon = Icons.info_outline;
    } else if (result) {
      accent = Colors.green;
      icon = Icons.check_circle;
    } else {
      accent = Colors.red;
      icon = Icons.cancel;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 8),
              Text(
                result == null
                    ? 'Equivalence comparison'
                    : result
                    ? 'Automata are equivalent'
                    : 'Automata are not equivalent',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  void _executeAlgorithm(String algorithmName, VoidCallback? callback) {
    if (callback == null) return;

    setState(() {
      _isExecuting = true;
      _currentAlgorithm = algorithmName;
      _executionProgress = 0.0;
      _executionStatus = 'Initializing...';
      _algorithmSteps.clear();
      _currentStepIndex = 0;
    });

    // Generate algorithm steps
    _generateAlgorithmSteps(algorithmName);

    // Execute the algorithm with progress simulation
    _simulateAlgorithmExecution(callback);
  }

  void _generateAlgorithmSteps(String algorithmName) {
    final steps = <AlgorithmStep>[];

    switch (algorithmName) {
      case 'NFA to DFA':
        steps.addAll([
          AlgorithmStep(
            title: 'Initialize',
            description: 'Set up DFA states and transitions',
          ),
          AlgorithmStep(
            title: 'Find Epsilon Closures',
            description: 'Calculate epsilon closures for NFA states',
          ),
          AlgorithmStep(
            title: 'Build State Transitions',
            description: 'Create DFA transitions from NFA transitions',
          ),
          AlgorithmStep(
            title: 'Determine Accepting States',
            description: 'Mark DFA states that contain NFA accepting states',
          ),
          AlgorithmStep(
            title: 'Optimize',
            description: 'Remove unreachable states and optimize structure',
          ),
        ]);
        break;
      case 'Minimize DFA':
        steps.addAll([
          AlgorithmStep(
            title: 'Initialize',
            description: 'Set up equivalence classes',
          ),
          AlgorithmStep(
            title: 'Find Distinguishable States',
            description: 'Identify states that can be distinguished',
          ),
          AlgorithmStep(
            title: 'Merge Equivalent States',
            description: 'Combine indistinguishable states',
          ),
          AlgorithmStep(
            title: 'Update Transitions',
            description: 'Redirect transitions to merged states',
          ),
          AlgorithmStep(title: 'Finalize', description: 'Create minimized DFA'),
        ]);
        break;
      case 'Remove λ-transitions':
        steps.addAll([
          AlgorithmStep(
            title: 'Detect λ-transitions',
            description: 'Identify all epsilon transitions and their sources',
          ),
          AlgorithmStep(
            title: 'Propagate Symbols',
            description: 'Distribute incoming symbols over λ-reachable states',
          ),
          AlgorithmStep(
            title: 'Rebuild Transitions',
            description: 'Create direct transitions without λ moves',
          ),
          AlgorithmStep(
            title: 'Cleanup',
            description: 'Remove unreachable states and duplicate transitions',
          ),
        ]);
        break;
      case 'Complete DFA':
        steps.addAll([
          AlgorithmStep(
            title: 'Inspect Alphabet',
            description: 'Verify coverage of every symbol from each state',
          ),
          AlgorithmStep(
            title: 'Add Trap State',
            description: 'Create a sink for missing transitions',
          ),
          AlgorithmStep(
            title: 'Connect Missing Arcs',
            description: 'Redirect incomplete transitions to the trap state',
          ),
        ]);
        break;
      case 'Complement DFA':
        steps.addAll([
          AlgorithmStep(
            title: 'Validate Determinism',
            description: 'Ensure the automaton is a proper DFA',
          ),
          AlgorithmStep(
            title: 'Complete Automaton',
            description: 'Add missing transitions using a trap state',
          ),
          AlgorithmStep(
            title: 'Flip Accepting States',
            description: 'Toggle which states are accepting',
          ),
        ]);
        break;
      case 'Prefix Closure':
        steps.addAll([
          AlgorithmStep(
            title: 'Validate Determinism',
            description: 'Confirm the DFA has no nondeterminism or λ moves',
          ),
          AlgorithmStep(
            title: 'Complete Automaton',
            description: 'Ensure every symbol has an outgoing transition',
          ),
          AlgorithmStep(
            title: 'Mark Prefix States',
            description: 'Identify states that can reach an accepting state',
          ),
        ]);
        break;
      case 'Suffix Closure':
        steps.addAll([
          AlgorithmStep(
            title: 'Validate Determinism',
            description: 'Confirm determinism and absence of λ transitions',
          ),
          AlgorithmStep(
            title: 'Expand Initial Access',
            description:
                'Add ε-links to states reachable from the initial state',
          ),
          AlgorithmStep(
            title: 'Determinize Result',
            description: 'Convert the resulting NFA back into a DFA',
          ),
        ]);
        break;
      case 'FA to Regex':
        steps.addAll([
          AlgorithmStep(
            title: 'Initialize',
            description: 'Set up state elimination process',
          ),
          AlgorithmStep(
            title: 'Add New Start/End States',
            description: 'Create single start and end states',
          ),
          AlgorithmStep(
            title: 'Eliminate States',
            description: 'Remove states one by one, updating transitions',
          ),
          AlgorithmStep(
            title: 'Combine Transitions',
            description: 'Merge parallel transitions with union',
          ),
          AlgorithmStep(
            title: 'Extract Regex',
            description: 'Extract final regular expression',
          ),
        ]);
        break;
    }

    setState(() {
      _algorithmSteps = steps;
    });
  }

  void _simulateAlgorithmExecution(VoidCallback callback) {
    _executeStep(0, callback);
  }

  void _executeStep(int stepIndex, VoidCallback callback) {
    if (stepIndex >= _algorithmSteps.length) {
      // Algorithm completed
      setState(() {
        _isExecuting = false;
        _executionProgress = 1.0;
        _executionStatus = 'Completed successfully';
      });

      // Execute the actual callback
      callback();
      return;
    }

    setState(() {
      _currentStepIndex = stepIndex;
      _executionProgress = stepIndex / _algorithmSteps.length;
      _executionStatus =
          'Executing step ${stepIndex + 1} of ${_algorithmSteps.length}';
    });

    // Simulate step execution time
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _executeStep(stepIndex + 1, callback);
      }
    });
  }
}

/// Data class for algorithm execution steps
class AlgorithmStep {
  final String title;
  final String description;
  final Map<String, dynamic>? data;

  AlgorithmStep({required this.title, required this.description, this.data});
}
