import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/models/fsa.dart';
import '../../data/services/file_operations_service.dart';

/// Panel for algorithm operations and controls
class AlgorithmPanel extends StatefulWidget {
  final VoidCallback? onNfaToDfa;
  final VoidCallback? onMinimizeDfa;
  final VoidCallback? onClear;
  final Function(String)? onRegexToNfa;
  final VoidCallback? onFaToRegex;
  final VoidCallback? onCompleteDfa;
  final VoidCallback? onFsaToGrammar;
  final VoidCallback? onAutoLayout;
  final Future<void> Function(FSA other)? onCompareEquivalence;
  final bool? equivalenceResult;
  final String? equivalenceDetails;

  const AlgorithmPanel({
    super.key,
    this.onNfaToDfa,
    this.onMinimizeDfa,
    this.onClear,
    this.onRegexToNfa,
    this.onFaToRegex,
    this.onCompleteDfa,
    this.onFsaToGrammar,
    this.onAutoLayout,
    this.onCompareEquivalence,
    this.equivalenceResult,
    this.equivalenceDetails,
  });

  @override
  State<AlgorithmPanel> createState() => _AlgorithmPanelState();
}

class _AlgorithmPanelState extends State<AlgorithmPanel> {
  final TextEditingController _regexController = TextEditingController();
  final FileOperationsService _fileService = FileOperationsService();
  bool _isExecuting = false;
  String? _currentAlgorithm;
  double _executionProgress = 0.0;
  String? _executionStatus;
  List<AlgorithmStep> _algorithmSteps = [];
  int _currentStepIndex = 0;

  @override
  void dispose() {
    _regexController.dispose();
    super.dispose();
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
              _buildAlgorithmButton(
                context,
                title: 'NFA to DFA',
                description:
                    'Convert non-deterministic to deterministic automaton',
                icon: Icons.transform,
                onPressed: () =>
                    _executeAlgorithm('NFA to DFA', widget.onNfaToDfa),
              ),

              const SizedBox(height: 12),

              // DFA minimization
              _buildAlgorithmButton(
                context,
                title: 'Minimize DFA',
                description: 'Minimize deterministic finite automaton',
                icon: Icons.compress,
                onPressed: () =>
                    _executeAlgorithm('Minimize DFA', widget.onMinimizeDfa),
              ),

              const SizedBox(height: 12),

              // Complete DFA
              _buildAlgorithmButton(
                context,
                title: 'Complete DFA',
                description: 'Add trap state to make DFA complete',
                icon: Icons.add_circle_outline,
                onPressed: () =>
                    _executeAlgorithm('Complete DFA', widget.onCompleteDfa),
              ),

              const SizedBox(height: 12),

              // FA to Regex conversion
              _buildAlgorithmButton(
                context,
                title: 'FA to Regex',
                description: 'Convert finite automaton to regular expression',
                icon: Icons.text_fields,
                onPressed: () =>
                    _executeAlgorithm('FA to Regex', widget.onFaToRegex),
              ),

              const SizedBox(height: 12),

              // FSA to Grammar conversion
              _buildAlgorithmButton(
                context,
                title: 'FSA to Grammar',
                description: 'Convert finite automaton to regular grammar',
                icon: Icons.transform,
                onPressed: () =>
                    _executeAlgorithm('FSA to Grammar', widget.onFsaToGrammar),
              ),

              const SizedBox(height: 12),

              // Auto Layout
              _buildAlgorithmButton(
                context,
                title: 'Auto Layout',
                description: 'Arrange states in a circle',
                icon: Icons.auto_awesome_motion,
                onPressed: widget.onAutoLayout,
              ),

              const SizedBox(height: 12),

              // Compare Equivalence
              _buildAlgorithmButton(
                context,
                title: 'Compare Equivalence',
                description: 'Compare two DFAs for equivalence',
                icon: Icons.compare_arrows,
                onPressed: _onCompareEquivalencePressed,
              ),

              const SizedBox(height: 12),

              // Clear automaton
              _buildAlgorithmButton(
                context,
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

  Widget _buildAlgorithmButton(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    VoidCallback? onPressed,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;
    final isCurrentAlgorithm = _currentAlgorithm == title;
    final isDisabled =
        (_isExecuting && !isCurrentAlgorithm) || onPressed == null;

    return InkWell(
      onTap: isDisabled ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isCurrentAlgorithm ? color : color.withValues(alpha: 0.3),
            width: isCurrentAlgorithm ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isCurrentAlgorithm
              ? color.withValues(alpha: 0.1)
              : isDisabled
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : null,
        ),
        child: Row(
          children: [
            if (isCurrentAlgorithm && _isExecuting)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(
                icon,
                color: isDisabled
                    ? colorScheme.outline.withValues(alpha: 0.5)
                    : color,
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
                      color: isDisabled
                          ? colorScheme.outline.withValues(alpha: 0.5)
                          : color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrentAlgorithm && _executionStatus != null
                        ? _executionStatus!
                        : description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDisabled
                          ? colorScheme.outline.withValues(alpha: 0.5)
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrentAlgorithm && _isExecuting)
              Text(
                '${(_executionProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: isDisabled
                    ? colorScheme.outline.withValues(alpha: 0.5)
                    : color.withValues(alpha: 0.5),
                size: 16,
              ),
          ],
        ),
      ),
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

  Future<void> _onCompareEquivalencePressed() async {
    if (widget.onCompareEquivalence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Load a DFA before comparing equivalence.'),
        ),
      );
      return;
    }

    final selection = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select DFA to compare',
      type: FileType.custom,
      allowedExtensions: const ['jff'],
    );

    if (selection == null || selection.files.single.path == null) {
      return;
    }

    setState(() {
      _isExecuting = true;
      _currentAlgorithm = 'Compare Equivalence';
      _executionStatus = 'Loading automaton...';
      _executionProgress = 0.25;
      _algorithmSteps = [
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
      ];
      _currentStepIndex = 0;
    });

    final loadResult = await _fileService.loadAutomatonFromJFLAP(
      selection.files.single.path!,
    );

    if (!mounted) return;

    if (!loadResult.isSuccess) {
      setState(() {
        _isExecuting = false;
        _executionStatus = 'Failed to load automaton';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loadResult.error ?? 'Unable to load automaton.'),
        ),
      );
      return;
    }

    setState(() {
      _currentStepIndex = 1;
      _executionProgress = 0.6;
      _executionStatus = 'Comparing automata...';
    });

    try {
      await widget.onCompareEquivalence!(loadResult.data!);
      if (!mounted) return;
      setState(() {
        _isExecuting = false;
        _executionStatus = 'Comparison complete';
        _executionProgress = 1.0;
        _currentStepIndex = _algorithmSteps.length - 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExecuting = false;
        _executionStatus = 'Comparison failed';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Comparison failed: $e')));
    }
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
