import 'package:flutter/material.dart';
import '../../core/models/simulation_result.dart';

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
      });
      
      widget.onSimulate(inputString);
      
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
}
