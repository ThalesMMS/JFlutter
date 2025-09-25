import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/models/fsa.dart';
import '../../data/services/file_operations_service.dart';
import 'algorithm_panel/algorithm_action_button.dart';
import 'algorithm_panel/algorithm_progress_indicator.dart';
import 'algorithm_panel/algorithm_step.dart';
import 'algorithm_panel/algorithm_steps_list.dart';
import 'algorithm_panel/equivalence_result_card.dart';

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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Regex to NFA conversion
            _buildRegexInput(context),
            
            const SizedBox(height: 12),
            
            // NFA to DFA conversion
            AlgorithmActionButton(
              title: 'NFA to DFA',
              description: 'Convert non-deterministic to deterministic automaton',
              icon: Icons.transform,
              onPressed: () => _executeAlgorithm('NFA to DFA', widget.onNfaToDfa),
              isExecuting: _isExecuting,
              isCurrentAlgorithm: _currentAlgorithm == 'NFA to DFA',
              executionProgress: _executionProgress,
              executionStatus: _executionStatus,
            ),
            
            const SizedBox(height: 12),
            
            // DFA minimization
            AlgorithmActionButton(
              title: 'Minimize DFA',
              description: 'Minimize deterministic finite automaton',
              icon: Icons.compress,
              onPressed: () => _executeAlgorithm('Minimize DFA', widget.onMinimizeDfa),
              isExecuting: _isExecuting,
              isCurrentAlgorithm: _currentAlgorithm == 'Minimize DFA',
              executionProgress: _executionProgress,
              executionStatus: _executionStatus,
            ),

            const SizedBox(height: 12),

            // Complete DFA
            AlgorithmActionButton(
              title: 'Complete DFA',
              description: 'Add trap state to make DFA complete',
              icon: Icons.add_circle_outline,
              onPressed: () => _executeAlgorithm('Complete DFA', widget.onCompleteDfa),
              isExecuting: _isExecuting,
              isCurrentAlgorithm: _currentAlgorithm == 'Complete DFA',
              executionProgress: _executionProgress,
              executionStatus: _executionStatus,
            ),

            const SizedBox(height: 12),
            
            // FA to Regex conversion
            AlgorithmActionButton(
              title: 'FA to Regex',
              description: 'Convert finite automaton to regular expression',
              icon: Icons.text_fields,
              onPressed: () => _executeAlgorithm('FA to Regex', widget.onFaToRegex),
              isExecuting: _isExecuting,
              isCurrentAlgorithm: _currentAlgorithm == 'FA to Regex',
              executionProgress: _executionProgress,
              executionStatus: _executionStatus,
            ),

            const SizedBox(height: 12),

            // FSA to Grammar conversion
            AlgorithmActionButton(
              title: 'FSA to Grammar',
              description: 'Convert finite automaton to regular grammar',
              icon: Icons.transform,
              onPressed: () => _executeAlgorithm('FSA to Grammar', widget.onFsaToGrammar),
              isExecuting: _isExecuting,
              isCurrentAlgorithm: _currentAlgorithm == 'FSA to Grammar',
              executionProgress: _executionProgress,
              executionStatus: _executionStatus,
            ),

            const SizedBox(height: 12),

            // Auto Layout
            AlgorithmActionButton(
              title: 'Auto Layout',
              description: 'Arrange states in a circle',
              icon: Icons.auto_awesome_motion,
              onPressed: widget.onAutoLayout,
              isExecuting: _isExecuting,
              isCurrentAlgorithm: _currentAlgorithm == 'Auto Layout',
              executionProgress: _executionProgress,
              executionStatus: _executionStatus,
            ),

            const SizedBox(height: 12),

            // Compare Equivalence
            AlgorithmActionButton(
              title: 'Compare Equivalence',
              description: 'Compare two DFAs for equivalence',
              icon: Icons.compare_arrows,
              onPressed: _onCompareEquivalencePressed,
              isExecuting: _isExecuting,
              isCurrentAlgorithm: _currentAlgorithm == 'Compare Equivalence',
              executionProgress: _executionProgress,
              executionStatus: _executionStatus,
            ),
            
            const SizedBox(height: 12),
            
            // Clear automaton
            AlgorithmActionButton(
              title: 'Clear',
              description: 'Clear current automaton',
              icon: Icons.clear,
              onPressed: widget.onClear,
              isDestructive: true,
              isExecuting: _isExecuting,
              isCurrentAlgorithm: _currentAlgorithm == 'Clear',
              executionProgress: _executionProgress,
              executionStatus: _executionStatus,
            ),
            
            // Progress indicator
            if (_isExecuting) ...[
              const SizedBox(height: 16),
              AlgorithmProgressIndicator(
                algorithmName: _currentAlgorithm,
                progress: _executionProgress,
                status: _executionStatus,
              ),
            ],
            
            // Algorithm execution steps
            if (_algorithmSteps.isNotEmpty) ...[
              const SizedBox(height: 16),
              AlgorithmStepsList(
                steps: _algorithmSteps,
                currentStepIndex: _currentStepIndex,
              ),
            ],

            if (widget.equivalenceResult != null ||
                (widget.equivalenceDetails?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 16),
              EquivalenceResultCard(
                result: widget.equivalenceResult,
                details: widget.equivalenceDetails,
              ),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
                if (_regexController.text.isNotEmpty && widget.onRegexToNfa != null) {
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

  Future<void> _onCompareEquivalencePressed() async {
    if (widget.onCompareEquivalence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Load a DFA before comparing equivalence.')),
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

    final loadResult =
        await _fileService.loadAutomatonFromJFLAP(selection.files.single.path!);

    if (!mounted) return;

    if (!loadResult.isSuccess) {
      setState(() {
        _isExecuting = false;
        _executionStatus = 'Failed to load automaton';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loadResult.error ?? 'Unable to load automaton.')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comparison failed: $e')),
      );
    }
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
          AlgorithmStep(
            title: 'Finalize',
            description: 'Create minimized DFA',
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
      _executionStatus = 'Executing step ${stepIndex + 1} of ${_algorithmSteps.length}';
    });
    
    // Simulate step execution time
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _executeStep(stepIndex + 1, callback);
      }
    });
  }
}

