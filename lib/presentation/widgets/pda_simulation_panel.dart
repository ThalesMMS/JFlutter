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

import '../../core/algorithms/pda_simulator.dart';
import '../../core/result.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../providers/pda_editor_provider.dart';
import 'base_simulation_panel.dart';
import 'trace_viewers/pda_trace_viewer.dart';

/// Panel for PDA simulation and string testing
class PDASimulationPanel extends ConsumerStatefulWidget {
  final SimulationHighlightService highlightService;

  PDASimulationPanel({
    super.key,
    SimulationHighlightService? highlightService,
  }) : highlightService = highlightService ?? SimulationHighlightService();

  @override
  ConsumerState<PDASimulationPanel> createState() => _PDASimulationPanelState();
}

class _PDASimulationPanelState
    extends BaseConsumerSimulationPanelState<PDASimulationPanel> {
  final TextEditingController _initialStackController = TextEditingController(
    text: 'Z',
  );

  PDASimulationResult? _simulationResult;
  String? _errorMessage;
  bool _stepByStep = true;

  @override
  SimulationHighlightService get highlightService => widget.highlightService;

  @override
  void dispose() {
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
          buildInputField(
            context: context,
            labelText: 'Input String',
            hintText: 'e.g., aabb, abab',
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
                highlightService.clear();
              } else if (_simulationResult?.steps.isNotEmpty == true) {
                highlightService.emitFromSteps(
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
    return buildSimulateButton(
      context: context,
      label: 'Simulate PDA',
      simulatingLabel: 'Simulating...',
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

  @override
  void simulate() {
    final inputString = inputController.text.trim();
    final initialStack = _initialStackController.text.trim();

    if (inputString.isEmpty) {
      showError(context, 'Please enter an input string');
      return;
    }

    if (initialStack.isEmpty) {
      showError(context, 'Please enter an initial stack symbol');
      return;
    }

    final editorState = ref.read(pdaEditorProvider);
    final currentPda = editorState.pda;

    if (currentPda == null) {
      showError(context, 'Create a PDA on the canvas before simulating.');
      return;
    }

    setState(() {
      isSimulating = true;
      _simulationResult = null;
      _errorMessage = null;
    });

    highlightService.clear();

    final stackAlphabet = <String>{...currentPda.stackAlphabet};
    stackAlphabet.add(initialStack);

    final simulationPda = currentPda.copyWith(
      stackAlphabet: stackAlphabet,
      initialStackSymbol: initialStack,
    );

    final Result<PDASimulationResult> result = PDASimulator.simulate(
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
        isSimulating = false;
        _simulationResult = result.data;
        _errorMessage = result.data?.errorMessage?.isNotEmpty == true
            ? result.data!.errorMessage
            : null;
      });
      if (simulation != null && simulation.steps.isNotEmpty) {
        highlightService.emitFromSteps(simulation.steps, 0);
      } else {
        highlightService.clear();
      }
    } else {
      setState(() {
        isSimulating = false;
        _simulationResult = null;
        _errorMessage = result.error;
      });
      highlightService.clear();
    }
  }

  @override
  void clearSimulation() {
    setState(() {
      _errorMessage = null;
      _simulationResult = null;
    });
    super.clearSimulation();
  }
}
