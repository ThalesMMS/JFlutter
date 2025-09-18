import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/simulation_step.dart';

/// Panel for automaton simulation
class SimulationPanel extends StatefulWidget {
  final Function(String) onSimulate;
  final SimulationResult? simulationResult;
  final String? regexResult;

  const SimulationPanel({
    super.key,
    required this.onSimulate,
    this.simulationResult,
    this.regexResult,
  });

  @override
  State<SimulationPanel> createState() => _SimulationPanelState();
}

class _SimulationPanelState extends State<SimulationPanel> {
  final TextEditingController _inputController = TextEditingController();
  bool _isSimulating = false;
  bool _isStepByStep = false;
  int _currentStepIndex = 0;
  List<SimulationStep> _simulationSteps = [];
  bool _isPlaying = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _simulate() {
    final inputString = _inputController.text.trim();
    if (inputString.isNotEmpty) {
      setState(() {
        _isSimulating = true;
        _currentStepIndex = 0;
        _simulationSteps.clear();
      });
      
      widget.onSimulate(inputString);
      
      // Generate step-by-step simulation
      if (_isStepByStep) {
        _generateStepByStepSimulation(inputString);
      }
      
      // Reset simulation state after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isSimulating = false;
          });
        }
      });
    }
  }

  void _generateStepByStepSimulation(String inputString) {
    // Generate detailed simulation steps
    final steps = <SimulationStep>[];
    
    // Initial step
    steps.add(SimulationStep(
      stepNumber: 0,
      currentState: 'q0',
      remainingInput: inputString,
      description: 'Start simulation at initial state q0',
      isAccepted: false,
    ));
    
    // Simulate each character
    String currentState = 'q0';
    String remainingInput = inputString;
    
    for (int i = 0; i < inputString.length; i++) {
      final char = inputString[i];
      final nextState = _getNextState(currentState, char);
      
      steps.add(SimulationStep(
        stepNumber: i + 1,
        currentState: currentState,
        inputSymbol: char,
        nextState: nextState,
        remainingInput: remainingInput.substring(1),
        description: 'Read "$char" from state $currentState, move to state $nextState',
        isAccepted: false,
      ));
      
      currentState = nextState;
      remainingInput = remainingInput.substring(1);
    }
    
    // Final step
    final isAccepted = _isAcceptingState(currentState);
    steps.add(SimulationStep(
      stepNumber: steps.length,
      currentState: currentState,
      remainingInput: '',
      description: isAccepted 
          ? 'Reached accepting state $currentState - String accepted!'
          : 'Reached non-accepting state $currentState - String rejected!',
      isAccepted: isAccepted,
    ));
    
    setState(() {
      _simulationSteps = steps;
    });
  }

  String _getNextState(String currentState, String inputSymbol) {
    // Simple state transition logic for demonstration
    // In real implementation, this would use the actual automaton
    if (currentState == 'q0' && inputSymbol == 'a') return 'q1';
    if (currentState == 'q1' && inputSymbol == 'b') return 'q2';
    if (currentState == 'q2' && inputSymbol == 'a') return 'q1';
    return 'q0'; // Default transition
  }

  bool _isAcceptingState(String state) {
    // Simple accepting state check for demonstration
    return state == 'q2';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Input field
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: 'Input String',
                hintText: 'Enter string to test',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _simulate(),
            ),
            
            const SizedBox(height: 16),
            
            // Simulate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSimulating ? null : _simulate,
                icon: _isSimulating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isSimulating ? 'Simulating...' : 'Simulate'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Step-by-step controls
            _buildStepByStepControls(context),
            
            // Results
            if (widget.simulationResult != null) ...[
              Text(
                'Simulation Result',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildResultCard(context, widget.simulationResult!),
            ],
            
            // Step-by-step execution
            if (_isStepByStep && _simulationSteps.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildStepByStepExecution(context),
            ],
            
            // Regex Result
            if (widget.regexResult != null) ...[
              const SizedBox(height: 16),
              Text(
                'Regex Result',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildRegexResultCard(context, widget.regexResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, SimulationResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAccepted = result.isAccepted;
    final color = isAccepted ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAccepted ? 'Accepted' : 'Rejected',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          if (result.steps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Steps: ${result.steps.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          
          if (result.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error: ${result.errorMessage}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegexResultCard(BuildContext context, String regex) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Regular Expression',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Text(
              regex,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepByStepControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Step-by-Step Mode',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Switch(
                value: _isStepByStep,
                onChanged: (value) {
                  setState(() {
                    _isStepByStep = value;
                    if (!value) {
                      _currentStepIndex = 0;
                      _simulationSteps.clear();
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepByStepExecution(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step-by-Step Execution',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Step ${_currentStepIndex + 1} of ${_simulationSteps.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Current step display
          if (_currentStepIndex < _simulationSteps.length)
            _buildCurrentStep(context, _simulationSteps[_currentStepIndex]),
          
          const SizedBox(height: 12),
          
          // Navigation controls
          _buildStepNavigationControls(context),
          
          const SizedBox(height: 12),
          
          // Step list
          _buildStepList(context),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, SimulationStep step) {
    final color = (step.isAccepted ?? false) ? Colors.green : Colors.blue;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                (step.isAccepted ?? false) ? Icons.check_circle : Icons.play_circle,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Step ${step.stepNumber}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            step.description ?? 'No description',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (step.inputSymbol != null) ...[
            const SizedBox(height: 4),
            Text(
              'Input: "${step.inputSymbol}"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
          if (step.nextState != null) ...[
            const SizedBox(height: 4),
            Text(
              'Next State: ${step.nextState}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepNavigationControls(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: _currentStepIndex > 0 ? _previousStep : null,
          icon: const Icon(Icons.skip_previous),
          tooltip: 'Previous Step',
        ),
        IconButton(
          onPressed: _isPlaying ? _pauseSteps : _playSteps,
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          tooltip: _isPlaying ? 'Pause' : 'Play',
        ),
        IconButton(
          onPressed: _currentStepIndex < _simulationSteps.length - 1 ? _nextStep : null,
          icon: const Icon(Icons.skip_next),
          tooltip: 'Next Step',
        ),
        const Spacer(),
        IconButton(
          onPressed: _resetSteps,
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset',
        ),
      ],
    );
  }

  Widget _buildStepList(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListView.builder(
        itemCount: _simulationSteps.length,
        itemBuilder: (context, index) {
          final step = _simulationSteps[index];
          final isCurrentStep = index == _currentStepIndex;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrentStep 
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCurrentStep 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  child: Text(
                    '${step.stepNumber}',
                    style: TextStyle(
                      color: isCurrentStep 
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.description ?? 'No description',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (step.isAccepted ?? false)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  void _nextStep() {
    if (_currentStepIndex < _simulationSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  void _playSteps() {
    setState(() {
      _isPlaying = true;
    });
    
    _playStepAnimation();
  }

  void _pauseSteps() {
    setState(() {
      _isPlaying = false;
    });
  }

  void _playStepAnimation() {
    if (_isPlaying && _currentStepIndex < _simulationSteps.length - 1) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_isPlaying && mounted) {
          setState(() {
            _currentStepIndex++;
          });
          _playStepAnimation();
        }
      });
    } else {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _resetSteps() {
    setState(() {
      _currentStepIndex = 0;
      _isPlaying = false;
    });
  }
}
