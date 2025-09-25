import 'dart:async';
import 'package:flutter/material.dart';
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';
import 'package:conversions/conversions.dart';

/// Algorithm visualizer for step-by-step execution
class AlgorithmVisualizer {
  final AnimationController _animationController;
  final Function(VisualizationStep) onStepChanged;
  final Function(VisualizationResult) onVisualizationComplete;

  AlgorithmVisualizer({
    required AnimationController animationController,
    required this.onStepChanged,
    required this.onVisualizationComplete,
  }) : _animationController = animationController;

  /// Visualize NFA to DFA conversion
  Future<VisualizationResult> visualizeNFAToDFA(
    FiniteAutomaton nfa,
    String inputString,
  ) async {
    final steps = <VisualizationStep>[];
    final converter = NFAToDFAConverter();
    
    // Step 1: Show initial NFA
    steps.add(VisualizationStep(
      stepNumber: 0,
      title: 'Initial NFA',
      description: 'Starting with the given NFA',
      automaton: nfa,
      highlights: [],
      annotations: ['This is the input NFA that will be converted to DFA'],
    ));
    
    // Step 2: Show epsilon closure calculation
    final initialState = nfa.initialState;
    if (initialState != null) {
      final epsilonClosure = NFAToDFAConverter._epsilonClosure(nfa, {initialState.id});
      steps.add(VisualizationStep(
        stepNumber: 1,
        title: 'Epsilon Closure',
        description: 'Calculate epsilon closure of initial state',
        automaton: nfa,
        highlights: [initialState.id],
        annotations: ['Epsilon closure: ${epsilonClosure.join(', ')}'],
      ));
    }
    
    // Step 3: Show DFA construction
    final dfa = converter.convert(nfa);
    steps.add(VisualizationStep(
      stepNumber: 2,
      title: 'DFA Construction',
      description: 'Build DFA using subset construction',
      automaton: dfa,
      highlights: [],
      annotations: ['DFA constructed with ${dfa.states.length} states'],
    ));
    
    // Step 4: Show optimization
    final optimizedDFA = NFAToDFAConverter.optimize(dfa);
    steps.add(VisualizationStep(
      stepNumber: 3,
      title: 'DFA Optimization',
      description: 'Remove unreachable states',
      automaton: optimizedDFA,
      highlights: [],
      annotations: ['Optimized DFA with ${optimizedDFA.states.length} states'],
    ));
    
    return VisualizationResult(
      algorithm: 'NFA to DFA Conversion',
      steps: steps,
      finalResult: optimizedDFA,
      success: true,
    );
  }

  /// Visualize DFA minimization
  Future<VisualizationResult> visualizeDFAMinimization(
    FiniteAutomaton dfa,
  ) async {
    final steps = <VisualizationStep>[];
    final minimizer = DFAMinimizer();
    
    // Step 1: Show initial DFA
    steps.add(VisualizationStep(
      stepNumber: 0,
      title: 'Initial DFA',
      description: 'Starting with the given DFA',
      automaton: dfa,
      highlights: [],
      annotations: ['DFA with ${dfa.states.length} states'],
    ));
    
    // Step 2: Show partition initialization
    final finalStateIds = dfa.finalStates.map((s) => s.id).toSet();
    final nonFinalStateIds = dfa.states
        .where((s) => !s.isFinal)
        .map((s) => s.id)
        .toSet();
    
    steps.add(VisualizationStep(
      stepNumber: 1,
      title: 'Partition Initialization',
      description: 'Separate final and non-final states',
      automaton: dfa,
      highlights: finalStateIds.toList(),
      annotations: ['Final states: ${finalStateIds.join(', ')}', 'Non-final states: ${nonFinalStateIds.join(', ')}'],
    ));
    
    // Step 3: Show partition refinement
    steps.add(VisualizationStep(
      stepNumber: 2,
      title: 'Partition Refinement',
      description: 'Refine partition based on transitions',
      automaton: dfa,
      highlights: [],
      annotations: ['Refining partition to find equivalent states'],
    ));
    
    // Step 4: Show minimized DFA
    final minimizedDFA = minimizer.minimize(dfa);
    steps.add(VisualizationStep(
      stepNumber: 3,
      title: 'Minimized DFA',
      description: 'Final minimized DFA',
      automaton: minimizedDFA,
      highlights: [],
      annotations: ['Minimized DFA with ${minimizedDFA.states.length} states'],
    ));
    
    return VisualizationResult(
      algorithm: 'DFA Minimization',
      steps: steps,
      finalResult: minimizedDFA,
      success: true,
    );
  }

  /// Visualize regex to NFA conversion
  Future<VisualizationResult> visualizeRegexToNFA(
    RegularExpression regex,
  ) async {
    final steps = <VisualizationStep>[];
    final converter = RegexToNFAConverter();
    
    // Step 1: Show regex pattern
    steps.add(VisualizationStep(
      stepNumber: 0,
      title: 'Regular Expression',
      description: 'Starting with the regex pattern',
      automaton: null,
      highlights: [],
      annotations: ['Pattern: ${regex.pattern}'],
    ));
    
    // Step 2: Show AST construction
    steps.add(VisualizationStep(
      stepNumber: 1,
      title: 'AST Construction',
      description: 'Build Abstract Syntax Tree',
      automaton: null,
      highlights: [],
      annotations: ['Parsing regex into AST structure'],
    ));
    
    // Step 3: Show NFA construction
    final nfa = converter.convert(regex);
    steps.add(VisualizationStep(
      stepNumber: 2,
      title: 'NFA Construction',
      description: 'Build NFA using Thompson construction',
      automaton: nfa,
      highlights: [],
      annotations: ['NFA constructed with ${nfa.states.length} states'],
    ));
    
    return VisualizationResult(
      algorithm: 'Regex to NFA Conversion',
      steps: steps,
      finalResult: nfa,
      success: true,
    );
  }

  /// Visualize language operations
  Future<VisualizationResult> visualizeLanguageOperation(
    String operation,
    FiniteAutomaton fa1,
    FiniteAutomaton fa2,
  ) async {
    final steps = <VisualizationStep>[];
    
    // Step 1: Show first automaton
    steps.add(VisualizationStep(
      stepNumber: 0,
      title: 'First Automaton',
      description: 'First input automaton',
      automaton: fa1,
      highlights: [],
      annotations: ['Automaton A with ${fa1.states.length} states'],
    ));
    
    // Step 2: Show second automaton
    steps.add(VisualizationStep(
      stepNumber: 1,
      title: 'Second Automaton',
      description: 'Second input automaton',
      automaton: fa2,
      highlights: [],
      annotations: ['Automaton B with ${fa2.states.length} states'],
    ));
    
    // Step 3: Show operation result
    FiniteAutomaton result;
    switch (operation.toLowerCase()) {
      case 'union':
        result = LanguageOperations.union(fa1, fa2);
        break;
      case 'intersection':
        result = LanguageOperations.intersection(fa1, fa2);
        break;
      case 'concatenation':
        result = LanguageOperations.concatenation(fa1, fa2);
        break;
      default:
        throw ArgumentError('Unsupported operation: $operation');
    }
    
    steps.add(VisualizationStep(
      stepNumber: 2,
      title: 'Operation Result',
      description: 'Result of $operation operation',
      automaton: result,
      highlights: [],
      annotations: ['Result has ${result.states.length} states'],
    ));
    
    return VisualizationResult(
      algorithm: 'Language Operation: $operation',
      steps: steps,
      finalResult: result,
      success: true,
    );
  }

  /// Visualize automaton simulation
  Future<VisualizationResult> visualizeSimulation(
    FiniteAutomaton automaton,
    String inputString,
  ) async {
    final steps = <VisualizationStep>[];
    final currentStates = <String>{automaton.initialState?.id ?? ''};
    
    // Step 1: Show initial state
    steps.add(VisualizationStep(
      stepNumber: 0,
      title: 'Initial State',
      description: 'Start simulation',
      automaton: automaton,
      highlights: currentStates.toList(),
      annotations: ['Starting in state: ${currentStates.join(', ')}'],
    ));
    
    // Step 2: Process each input symbol
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      final nextStates = <String>{};
      
      for (final state in currentStates) {
        final transitions = automaton.transitions.where(
          (t) => t.from == state && t.symbol == symbol,
        );
        
        for (final transition in transitions) {
          nextStates.add(transition.to);
        }
      }
      
      currentStates.clear();
      currentStates.addAll(nextStates);
      
      steps.add(VisualizationStep(
        stepNumber: i + 1,
        title: 'Process Symbol: $symbol',
        description: 'After reading symbol $symbol',
        automaton: automaton,
        highlights: currentStates.toList(),
        annotations: ['Current states: ${currentStates.join(', ')}'],
      ));
    }
    
    // Step 3: Show final result
    final isAccepted = currentStates.any((state) => 
        automaton.finalStates.any((finalState) => finalState.id == state));
    
    steps.add(VisualizationStep(
      stepNumber: inputString.length + 1,
      title: 'Simulation Complete',
      description: 'Final result',
      automaton: automaton,
      highlights: currentStates.toList(),
      annotations: ['Input $inputString is ${isAccepted ? 'accepted' : 'rejected'}'],
    ));
    
    return VisualizationResult(
      algorithm: 'Automaton Simulation',
      steps: steps,
      finalResult: automaton,
      success: true,
    );
  }

  /// Play visualization steps
  Future<void> playVisualization(VisualizationResult result) async {
    for (final step in result.steps) {
      onStepChanged(step);
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    onVisualizationComplete(result);
  }

  /// Pause visualization
  void pauseVisualization() {
    _animationController.stop();
  }

  /// Resume visualization
  void resumeVisualization() {
    _animationController.forward();
  }

  /// Stop visualization
  void stopVisualization() {
    _animationController.reset();
  }

  /// Set visualization speed
  void setVisualizationSpeed(double speed) {
    _animationController.duration = Duration(milliseconds: (1000 / speed).round());
  }
}

/// Visualization step
class VisualizationStep {
  final int stepNumber;
  final String title;
  final String description;
  final FiniteAutomaton? automaton;
  final List<String> highlights;
  final List<String> annotations;

  const VisualizationStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.automaton,
    required this.highlights,
    required this.annotations,
  });
}

/// Visualization result
class VisualizationResult {
  final String algorithm;
  final List<VisualizationStep> steps;
  final FiniteAutomaton? finalResult;
  final bool success;
  final String? errorMessage;

  const VisualizationResult({
    required this.algorithm,
    required this.steps,
    this.finalResult,
    required this.success,
    this.errorMessage,
  });
}

/// Visualization controller
class VisualizationController {
  final AlgorithmVisualizer _visualizer;
  final StreamController<VisualizationStep> _stepController = StreamController.broadcast();
  final StreamController<VisualizationResult> _resultController = StreamController.broadcast();

  VisualizationController({required AlgorithmVisualizer visualizer})
      : _visualizer = visualizer;

  /// Get step stream
  Stream<VisualizationStep> get stepStream => _stepController.stream;

  /// Get result stream
  Stream<VisualizationResult> get resultStream => _resultController.stream;

  /// Start visualization
  Future<void> startVisualization(VisualizationResult result) async {
    await _visualizer.playVisualization(result);
  }

  /// Pause visualization
  void pauseVisualization() {
    _visualizer.pauseVisualization();
  }

  /// Resume visualization
  void resumeVisualization() {
    _visualizer.resumeVisualization();
  }

  /// Stop visualization
  void stopVisualization() {
    _visualizer.stopVisualization();
  }

  /// Set speed
  void setSpeed(double speed) {
    _visualizer.setVisualizationSpeed(speed);
  }

  /// Dispose
  void dispose() {
    _stepController.close();
    _resultController.close();
  }
}

/// Visualization widget
class VisualizationWidget extends StatefulWidget {
  final VisualizationResult result;
  final Function(VisualizationStep)? onStepChanged;
  final Function(VisualizationResult)? onComplete;

  const VisualizationWidget({
    Key? key,
    required this.result,
    this.onStepChanged,
    this.onComplete,
  }) : super(key: key);

  @override
  State<VisualizationWidget> createState() => _VisualizationWidgetState();
}

class _VisualizationWidgetState extends State<VisualizationWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late VisualizationController _controller;
  int _currentStep = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _controller = VisualizationController(
      visualizer: AlgorithmVisualizer(
        animationController: _animationController,
        onStepChanged: (step) {
          setState(() {
            _currentStep = step.stepNumber;
          });
          widget.onStepChanged?.call(step);
        },
        onVisualizationComplete: (result) {
          setState(() {
            _isPlaying = false;
          });
          widget.onComplete?.call(result);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stop,
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: _previousStep,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: _nextStep,
            ),
          ],
        ),
        
        // Step information
        Text(
          'Step ${_currentStep + 1} of ${widget.result.steps.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        
        // Step content
        Expanded(
          child: _buildStepContent(),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    if (_currentStep >= widget.result.steps.length) {
      return const Center(child: Text('Visualization complete'));
    }
    
    final step = widget.result.steps[_currentStep];
    
    return Column(
      children: [
        Text(
          step.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          step.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        
        // Annotations
        if (step.annotations.isNotEmpty)
          Column(
            children: step.annotations.map((annotation) => 
              Text(annotation, style: Theme.of(context).textTheme.bodyMedium)
            ).toList(),
          ),
        
        // Automaton visualization would go here
        if (step.automaton != null)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: const Center(
                child: Text('Automaton visualization would be rendered here'),
              ),
            ),
          ),
      ],
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    if (_isPlaying) {
      _controller.startVisualization(widget.result);
    } else {
      _controller.pauseVisualization();
    }
  }

  void _stop() {
    setState(() {
      _isPlaying = false;
      _currentStep = 0;
    });
    _controller.stopVisualization();
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < widget.result.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }
}
