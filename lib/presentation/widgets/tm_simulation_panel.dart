import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Panel for Turing Machine simulation and string testing
class TMSimulationPanel extends ConsumerStatefulWidget {
  const TMSimulationPanel({super.key});

  @override
  ConsumerState<TMSimulationPanel> createState() => _TMSimulationPanelState();
}

class _TMSimulationPanelState extends ConsumerState<TMSimulationPanel> {
  final TextEditingController _inputController = TextEditingController();
  
  bool _isSimulating = false;
  String? _simulationResult;
  List<String> _simulationSteps = [];
  List<String> _tapeHistory = [];
  String _currentTape = '';
  int _headPosition = 0;
  int _currentStep = 0;

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
            _buildInputSection(context),
            const SizedBox(height: 16),
            _buildSimulateButton(context),
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
        Icon(
          Icons.play_arrow,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'TM Simulation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulation Input',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: 'Input String',
              hintText: 'e.g., 101, 1100, 111',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Examples: 101 (binary), 1100 (palindrome), 111 (counting)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSimulating ? null : _simulateTM,
        icon: _isSimulating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isSimulating ? 'Simulating...' : 'Simulate TM'),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulation Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _simulationResult == null
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
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
            'No simulation results yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter an input string and click Simulate to see results',
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
    final isAccepted = _simulationResult == 'Accepted';
    final color = isAccepted ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _simulationResult!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          if (_simulationSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Simulation Steps:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _simulationSteps.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _simulationSteps[index],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        if (index < _tapeHistory.length)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Tape: ${_tapeHistory[index]}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  void _simulateTM() {
    final inputString = _inputController.text.trim();
    
    if (inputString.isEmpty) {
      _showError('Please enter an input string');
      return;
    }
    
    setState(() {
      _isSimulating = true;
      _simulationResult = null;
      _simulationSteps.clear();
      _tapeHistory.clear();
      _currentTape = inputString;
      _headPosition = 0;
      _currentStep = 0;
    });
    
    // Simulate TM execution
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _simulateTMExecution(inputString);
      }
    });
  }

  void _simulateTMExecution(String inputString) {
    // Simple simulation for demonstration
    // In real implementation, this would use the actual TM simulator
    final steps = <String>[];
    final tapeHistory = <String>[];
    
    steps.add('Start: State q0, Tape: $inputString, Head: 0');
    tapeHistory.add(inputString);
    
    // Simulate a simple TM that accepts strings with equal number of 0s and 1s
    if (_simulateEqualOnesZerosTM(inputString, steps, tapeHistory)) {
      setState(() {
        _isSimulating = false;
        _simulationResult = 'Accepted';
        _simulationSteps = steps;
        _tapeHistory = tapeHistory;
      });
    } else {
      setState(() {
        _isSimulating = false;
        _simulationResult = 'Rejected';
        _simulationSteps = steps;
        _tapeHistory = tapeHistory;
      });
    }
  }

  bool _simulateEqualOnesZerosTM(String input, List<String> steps, List<String> tapeHistory) {
    // Simple simulation for a TM that accepts strings with equal number of 0s and 1s
    String tape = input;
    int head = 0;
    String state = 'q0';
    
    // Count 0s and 1s
    int zeros = input.split('0').length - 1;
    int ones = input.split('1').length - 1;
    
    if (zeros == ones && zeros > 0) {
      steps.add('Count: 0s=$zeros, 1s=$ones (equal)');
      tapeHistory.add(tape);
      steps.add('Accept: Equal number of 0s and 1s');
      tapeHistory.add(tape);
      return true;
    } else {
      steps.add('Count: 0s=$zeros, 1s=$ones (not equal)');
      tapeHistory.add(tape);
      steps.add('Reject: Unequal number of 0s and 1s');
      tapeHistory.add(tape);
      return false;
    }
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
