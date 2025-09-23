import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/pda_simulator.dart';
import '../../core/models/pda.dart';
import '../../core/models/simulation_step.dart';
import '../../core/result.dart';
import '../providers/pda_editor_provider.dart';

typedef PDASimulatorRunner = Result<PDASimulationResult> Function(
  PDA,
  String, {
  bool stepByStep,
  Duration timeout,
});

final pdaSimulatorRunnerProvider = Provider<PDASimulatorRunner>(
  (ref) => (
    pda,
    inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return PDASimulator.simulate(
      pda,
      inputString,
      stepByStep: stepByStep,
      timeout: timeout,
    );
  },
);

/// Encapsulates the PDA input controls, execution trigger, and results view
/// so the widget can manage the full life cycle of a simulation from the same
/// panel.
class PDASimulationPanel extends ConsumerStatefulWidget {
  const PDASimulationPanel({super.key});

  @override
  ConsumerState<PDASimulationPanel> createState() => _PDASimulationPanelState();
}

class _PDASimulationPanelState extends ConsumerState<PDASimulationPanel> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _initialStackController = TextEditingController(text: 'Z');

  bool _isSimulating = false;
  PDASimulationResult? _simulationResult;
  String? _errorMessage;
  bool _stepByStep = true;

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

  // Presents the input fields, including the `_stepByStep` switch that toggles
  // whether the simulator collects the detailed transition trace.
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
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Record step-by-step trace'),
            value: _stepByStep,
            onChanged: (value) {
              setState(() {
                _stepByStep = value;
              });
            },
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

  // Provides the execute button, reflecting the loading state while the
  // simulation runs and delegating to `_simulatePDA` with the current
  // `_stepByStep` selection.
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

  // Shows the results container, falling back to placeholder or error
  // messaging when `_simulationResult` is empty due to validation or runtime
  // failures.
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
          constraints: const BoxConstraints(maxHeight: 220),
          child: _simulationResult == null && _errorMessage == null
              ? _buildEmptyResults(context)
              : _buildResults(context),
        ),
      ],
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    // Placeholder shown before any simulation has been run or when errors clear
    // previous output.
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
    final result = _simulationResult;
    final isAccepted = result?.accepted ?? false;
    final hasResult = result != null;
    final color = isAccepted ? Colors.green : Colors.red;
    final message = hasResult
        ? (isAccepted ? 'Accepted' : 'Rejected')
        : 'Simulation failed';
    final errorText = _errorMessage ?? result?.errorMessage;

    // Displays either the simulator error (if available) or the last
    // validation error bubbled up via `_showError` when no results can be
    // produced.

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
                message,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (hasResult)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Time: ${result!.executionTime.inMilliseconds} ms',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

          if (errorText != null && errorText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                errorText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),

          if (hasResult && result!.steps.isNotEmpty) ...[
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
              itemCount: result.steps.length,
              itemBuilder: (context, index) {
                final step = result.steps[index];
                final remainingInput =
                    step.remainingInput.isEmpty ? 'λ' : step.remainingInput;
                final stack = step.stackContents.isEmpty ? 'λ' : step.stackContents;
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
                          'State ${step.currentState} | Remaining: $remainingInput | Stack: $stack${step.usedTransition != null ? ' | Transition: ${step.usedTransition}' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
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

    final editorState = ref.read(pdaEditorProvider);
    final currentPda = editorState.pda;

    if (currentPda == null) {
      _showError('Create a PDA on the canvas before simulating.');
      return;
    }

    setState(() {
      _isSimulating = true;
      _simulationResult = null;
      _errorMessage = null;
    });

    final stackAlphabet = {...currentPda.stackAlphabet};
    stackAlphabet.add(initialStack);

    final simulationPda = currentPda.copyWith(
      stackAlphabet: stackAlphabet,
      initialStackSymbol: initialStack,
    );

    final simulator = ref.read(pdaSimulatorRunnerProvider);
    final Result<PDASimulationResult> result = simulator(
      simulationPda,
      inputString,
      stepByStep: _stepByStep,
      timeout: const Duration(seconds: 5),
    );

    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _isSimulating = false;
        _simulationResult = result.data;
        _errorMessage = result.data?.errorMessage?.isNotEmpty == true
            ? result.data!.errorMessage
            : null;
      });
    } else {
      setState(() {
        _isSimulating = false;
        _simulationResult = null;
        _errorMessage = result.error;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _simulationResult = null;
    });
    // Surface the validation issue in both the snackbar and results section so
    // the UI clarifies why no simulation output is currently available.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
