//
//  pda_simulation_panel.dart
//  JFlutter
//
//  Responsável pela simulação de autômatos de pilha no aplicativo, permitindo
//  configurar cadeia de entrada, símbolo inicial da pilha, gravação de traço e
//  visualizar resultados aceitos ou rejeitados com mensagens de erro.
//  Integra-se ao PDAEditorProvider e ao serviço de destaque para sincronizar o
//  canvas, administrando controladores e estado local a fim de preservar
//  interações entre execuções.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/pda_simulator.dart' as pda_core;
import '../../core/models/simulation_step.dart';
import '../../core/result.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../providers/pda_editor_provider.dart';
import '../providers/pda_simulation_provider.dart';
import 'trace_viewers/pda_trace_viewer.dart';
import 'pda/stack_drawer.dart';

/// Panel for PDA simulation and string testing
class PDASimulationPanel extends ConsumerStatefulWidget {
  final SimulationHighlightService highlightService;
  final ValueChanged<StackState>? onStackChanged;
  final VoidCallback? onSimulationStart;
  final VoidCallback? onSimulationEnd;

  PDASimulationPanel({
    super.key,
    SimulationHighlightService? highlightService,
    this.onStackChanged,
    this.onSimulationStart,
    this.onSimulationEnd,
  }) : highlightService = highlightService ?? SimulationHighlightService();

  @override
  ConsumerState<PDASimulationPanel> createState() => _PDASimulationPanelState();
}

class _PDASimulationPanelState extends ConsumerState<PDASimulationPanel> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _initialStackController = TextEditingController(
    text: 'Z',
  );

  bool _isSimulating = false;
  pda_core.PDASimulationResult? _simulationResult;
  String? _errorMessage;
  bool _stepByStep = true;

  @override
  void dispose() {
    _inputController.dispose();
    _initialStackController.dispose();
    widget.highlightService.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(pdaSimulationProvider);
    final hasSteps = simState.result?.steps.isNotEmpty == true;

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
            if (hasSteps && _stepByStep) ...[
              const SizedBox(height: 16),
              _buildStepControls(context, simState),
              const SizedBox(height: 16),
              _buildStackPreview(context, simState),
            ],
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
          'PDA Simulation',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
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
            'Simulation Input',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
              if (!value) {
                widget.highlightService.clear();
              } else if (_simulationResult?.steps.isNotEmpty == true) {
                widget.highlightService.emitFromSteps(
                  _simulationResult!.steps,
                  0,
                );
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Examples: aabb (for balanced parentheses), abab (for palindromes)',
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

  Widget _buildStepControls(BuildContext context, PDASimulationState simState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${simState.currentStepIndex + 1} of ${simState.totalSteps}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'State: ${simState.currentState ?? "—"}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.outlined(
                onPressed: simState.canGoToPreviousStep
                    ? () {
                        ref.read(pdaSimulationProvider.notifier).previousStep();
                        _updateStackFromCurrentStep();
                      }
                    : null,
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Previous Step',
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: simState.currentStepIndex > 0
                    ? () {
                        ref
                            .read(pdaSimulationProvider.notifier)
                            .resetToFirstStep();
                        _updateStackFromCurrentStep();
                      }
                    : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'Reset to First',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: simState.totalSteps > 0
                      ? (simState.currentStepIndex + 1) / simState.totalSteps
                      : 0,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: simState.currentStepIndex < simState.totalSteps - 1
                    ? () {
                        ref.read(pdaSimulationProvider.notifier).goToLastStep();
                        _updateStackFromCurrentStep();
                      }
                    : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'Jump to Last',
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: simState.canGoToNextStep
                    ? () {
                        ref.read(pdaSimulationProvider.notifier).nextStep();
                        _updateStackFromCurrentStep();
                      }
                    : null,
                icon: const Icon(Icons.skip_next),
                tooltip: 'Next Step',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStackPreview(BuildContext context, PDASimulationState simState) {
    final stackContents = simState.currentStackContents;
    final remainingInput = simState.currentRemainingInput ?? '';

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
            'Current Stack State',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stack:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stackContents.isEmpty ? '(empty)' : stackContents,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining Input:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remainingInput.isEmpty ? '(empty)' : remainingInput,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simulation Results',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                message,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (result case final simulationResult?)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Time: ${simulationResult.executionTime.inMilliseconds} ms',
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
          if (result case final simulationResult?
              when simulationResult.steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Simulation Steps:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            PDATraceViewer(
              result: simulationResult,
              highlightService: widget.highlightService,
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

    widget.highlightService.clear();
    widget.onSimulationStart?.call();

    // Initialize stack with initial symbol
    _updateStackState(
      StackState(
        symbols: [initialStack],
        lastOperation: 'initialize',
        operationType: StackOperationType.push,
      ),
    );

    final stackAlphabet = {...currentPda.stackAlphabet};
    stackAlphabet.add(initialStack);

    final simulationPda = currentPda.copyWith(
      stackAlphabet: stackAlphabet,
      initialStackSymbol: initialStack,
    );

    final Result<pda_core.PDASimulationResult> result = pda_core.PDASimulator.simulate(
      simulationPda,
      inputString,
      stepByStep: _stepByStep,
      timeout: const Duration(seconds: 5),
    );

    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      final simulation = result.data;
      setState(() {
        _isSimulating = false;
        _simulationResult = result.data;
        _errorMessage = result.data?.errorMessage?.isNotEmpty == true
            ? result.data!.errorMessage
            : null;
      });
      if (simulation != null && simulation.steps.isNotEmpty) {
        // Sync with simulation provider for step controls
        final simNotifier = ref.read(pdaSimulationProvider.notifier);
        simNotifier.setPda(simulationPda);
        simNotifier.setStepByStep(_stepByStep);
        // Manually set the result since we're using the old simulator
        ref.read(pdaSimulationProvider.notifier).state = ref
            .read(pdaSimulationProvider)
            .copyWith(result: simulation, currentStepIndex: 0);

        widget.highlightService.emitFromSteps(simulation.steps, 0);
        // Update stack to first step for step-by-step mode
        if (_stepByStep) {
          _updateStackFromStep(simulation.steps.first);
        } else {
          _updateStackFromStep(simulation.steps.last);
        }
      } else {
        widget.highlightService.clear();
      }
    } else {
      setState(() {
        _isSimulating = false;
        _simulationResult = null;
        _errorMessage = result.error;
      });
      widget.highlightService.clear();
    }

    widget.onSimulationEnd?.call();
  }

  void _updateStackState(StackState stackState) {
    widget.onStackChanged?.call(stackState);
  }

  void _updateStackFromStep(SimulationStep step) {
    final stackContents = step.stackContents;
    final symbols = stackContents.isEmpty
        ? <String>[]
        : stackContents.split('').toList();

    final operation = step.usedTransition ?? 'step ${step.stepNumber}';
    final operationType = _determineOperationType(step.usedTransition);

    _updateStackState(
      StackState(
        symbols: symbols,
        lastOperation: operation,
        operationType: operationType,
      ),
    );
  }

  /// Determines the stack operation type from a PDA transition label
  /// Format: "input,pop→push" where ε represents epsilon
  StackOperationType _determineOperationType(String? transitionLabel) {
    if (transitionLabel == null || transitionLabel.isEmpty) {
      return StackOperationType.none;
    }

    // Parse transition label: "input,pop→push"
    final parts = transitionLabel.split(',');
    if (parts.length < 2) {
      return StackOperationType.none;
    }

    final stackPart = parts[1]; // "pop→push"
    final stackParts = stackPart.split('→');
    if (stackParts.length < 2) {
      return StackOperationType.none;
    }

    final pop = stackParts[0].trim();
    final push = stackParts[1].trim();

    // Determine operation type based on pop and push symbols
    final isPopEpsilon = pop == 'ε' || pop.isEmpty;
    final isPushEpsilon = push == 'ε' || push.isEmpty;

    if (!isPopEpsilon && !isPushEpsilon) {
      // Both pop and push - replace operation
      return StackOperationType.replace;
    } else if (!isPopEpsilon && isPushEpsilon) {
      // Only pop, no push
      return StackOperationType.pop;
    } else if (isPopEpsilon && !isPushEpsilon) {
      // Only push, no pop
      return StackOperationType.push;
    } else {
      // Both epsilon - no stack operation
      return StackOperationType.none;
    }
  }

  void _updateStackFromCurrentStep() {
    final simState = ref.read(pdaSimulationProvider);
    final currentStep = simState.currentStep;
    if (currentStep != null) {
      _updateStackFromStep(currentStep);
      // Update highlight service to show current step
      if (_stepByStep && simState.result != null) {
        widget.highlightService.emitFromSteps(
          simState.result!.steps,
          simState.currentStepIndex,
        );
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _simulationResult = null;
    });
    widget.highlightService.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
