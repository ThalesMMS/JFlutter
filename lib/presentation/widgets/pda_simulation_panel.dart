import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Panel for PDA simulation and string testing
class PDASimulationPanel extends ConsumerStatefulWidget {
  const PDASimulationPanel({super.key});

  @override
  ConsumerState<PDASimulationPanel> createState() => _PDASimulationPanelState();
}

class _PDASimulationPanelState extends ConsumerState<PDASimulationPanel> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _initialStackController = TextEditingController(text: 'Z');
  
  bool _isSimulating = false;
  String? _simulationResult;
  List<String> _simulationSteps = [];
  List<String> _stackHistory = [];
  String _currentStack = 'Z';

  @override
  void dispose() {
    _inputController.dispose();
    _initialStackController.dispose();
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
          'PDA Simulation',
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
              hintText: 'e.g., aabb, abab',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _initialStackController,
            decoration: const InputDecoration(
              labelText: 'Initial Stack Symbol',
              hintText: 'e.g., Z',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Examples: aabb (for balanced parentheses), abab (for palindromes)',
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
        onPressed: _isSimulating ? null : _simulatePDA,
        icon: _isSimulating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isSimulating ? 'Simulating...' : 'Simulate PDA'),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simulation Results',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: _simulationResult == null
              ? _buildEmptyResults(context)
              : _buildResults(context),
        ),
      ],
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                      if (index < _stackHistory.length)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Stack: ${_stackHistory[index]}',
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
          ],
        ],
      ),
    );
  }

  void _simulatePDA() {
    final inputString = _inputController.text.trim();
    final initialStack = _initialStackController.text.trim();
    
    if (inputString.isEmpty) {
      _showError('Please enter an input string');
      return;
    }
    
    if (initialStack.isEmpty) {
      _showError('Please enter an initial stack symbol');
      return;
    }
    
    setState(() {
      _isSimulating = true;
      _simulationResult = null;
      _simulationSteps.clear();
      _stackHistory.clear();
      _currentStack = initialStack;
    });
    
    // Simulate PDA execution
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _simulatePDAExecution(inputString, initialStack);
      }
    });
  }

  void _simulatePDAExecution(String inputString, String initialStack) {
    // Simple simulation for demonstration
    // In real implementation, this would use the actual PDA simulator
    final steps = <String>[];
    final stackHistory = <String>[];
    
    steps.add('Start: State q0, Stack: $initialStack, Input: $inputString');
    stackHistory.add(initialStack);
    
    // Simulate a simple PDA that accepts a^n b^n
    if (_simulateBalancedPDA(inputString, initialStack, steps, stackHistory)) {
      setState(() {
        _isSimulating = false;
        _simulationResult = 'Accepted';
        _simulationSteps = steps;
        _stackHistory = stackHistory;
      });
    } else {
      setState(() {
        _isSimulating = false;
        _simulationResult = 'Rejected';
        _simulationSteps = steps;
        _stackHistory = stackHistory;
      });
    }
  }

  bool _simulateBalancedPDA(String input, String initialStack, List<String> steps, List<String> stackHistory) {
    // Simple simulation for a^n b^n language
    String currentStack = initialStack;
    int inputIndex = 0;
    
    // Phase 1: Read 'a's and push to stack
    while (inputIndex < input.length && input[inputIndex] == 'a') {
      currentStack += 'A';
      steps.add('Read \'a\': Push A, Stack: $currentStack');
      stackHistory.add(currentStack);
      inputIndex++;
    }
    
    // Phase 2: Read 'b's and pop from stack
    while (inputIndex < input.length && input[inputIndex] == 'b') {
      if (currentStack.isEmpty || !currentStack.endsWith('A')) {
        steps.add('Read \'b\': Cannot pop A, Stack: $currentStack');
        stackHistory.add(currentStack);
        return false;
      }
      currentStack = currentStack.substring(0, currentStack.length - 1);
      steps.add('Read \'b\': Pop A, Stack: $currentStack');
      stackHistory.add(currentStack);
      inputIndex++;
    }
    
    // Check if input is fully consumed and stack is back to initial
    if (inputIndex == input.length && currentStack == initialStack) {
      steps.add('End: Input consumed, Stack: $currentStack');
      stackHistory.add(currentStack);
      return true;
    } else {
      steps.add('End: Input not fully consumed or stack not empty');
      stackHistory.add(currentStack);
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
