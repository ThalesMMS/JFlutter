//
//  simulation_panel.dart
//  JFlutter
//
//  Constrói o painel de simulação de autômatos com entrada textual, botões de
//  execução e modos passo a passo que descrevem cada transição realizada e o
//  restante da cadeia processada.
//  Gerencia timers, destaques compartilhados com o canvas e renderização de
//  resultados aceitos ou rejeitados, permitindo alternar entre reprodução
//  automática e navegação manual pelas etapas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/simulation_step.dart';
import '../../core/services/simulation_highlight_service.dart';
import 'base_simulation_panel.dart';

/// Panel for automaton simulation
class SimulationPanel extends StatefulWidget {
  final Function(String) onSimulate;
  final SimulationResult? simulationResult;
  final String? regexResult;
  final SimulationHighlightService highlightService;

  SimulationPanel({
    super.key,
    required this.onSimulate,
    this.simulationResult,
    this.regexResult,
    SimulationHighlightService? highlightService,
  }) : highlightService = highlightService ?? SimulationHighlightService();

  @override
  State<SimulationPanel> createState() => _SimulationPanelState();
}

class _SimulationPanelState extends BaseSimulationPanelState<SimulationPanel> {
  @override
  SimulationHighlightService get highlightService => widget.highlightService;
  bool _isStepByStep = false;
  int _currentStepIndex = 0;
  List<SimulationStep> _simulationSteps = [];
  bool _isPlaying = false;

  @override
  void didUpdateWidget(covariant SimulationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.simulationResult != oldWidget.simulationResult) {
      setState(() {
        isSimulating = false;
      });
      if (_isStepByStep) {
        _loadSimulationSteps();
      }
    }
  }

  @override
  void simulate() {
    final inputString = inputController.text.trim();
    if (inputString.isNotEmpty) {
      setState(() {
        isSimulating = true;
        _currentStepIndex = 0;
        _simulationSteps.clear();
      });

      highlightService.clear();

      widget.onSimulate(inputString);

      // Safety timeout in case no result is produced
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && isSimulating) {
          setState(() {
            isSimulating = false;
          });
        }
      });
    }
  }

  void _loadSimulationSteps() {
    if (!_isStepByStep) {
      setState(() {
        _simulationSteps.clear();
        _currentStepIndex = 0;
        _isPlaying = false;
      });
      highlightService.clear();
      return;
    }

    final result = widget.simulationResult;
    if (result == null) {
      setState(() {
        _simulationSteps.clear();
        _currentStepIndex = 0;
        _isPlaying = false;
      });
      highlightService.clear();
      return;
    }

    setState(() {
      _simulationSteps = List<SimulationStep>.from(result.steps);
      _currentStepIndex = 0;
      _isPlaying = false;
    });

    _emitHighlightForCurrentStep();
  }

  String _describeStep(int index) {
    if (index < 0 || index >= _simulationSteps.length) {
      return '';
    }
    final step = _simulationSteps[index];

    if (index == 0) {
      final input = step.remainingInput.isEmpty
          ? 'ε'
          : '"${step.remainingInput}"';
      return 'Start at ${formatState(step.currentState)} with input $input.';
    }

    final bool isFinal = index == _simulationSteps.length - 1;
    if (isFinal) {
      final accepted = widget.simulationResult?.isAccepted ?? false;
      final verdict = accepted ? 'accepted' : 'rejected';
      return 'Final configuration ${formatState(step.currentState)} – input $verdict.';
    }

    final consumed =
        step.usedTransition ??
        (_simulationSteps[index - 1].remainingInput.isNotEmpty
            ? _simulationSteps[index - 1].remainingInput[0]
            : 'ε');
    final remaining = step.remainingInput.isEmpty
        ? 'no input remaining'
        : 'remaining "${step.remainingInput}"';
    final nextState = _nextStateFor(index) ?? step.currentState;

    return 'Read "$consumed" from ${formatState(step.currentState)} → ${formatState(nextState)} with $remaining.';
  }

  String? _nextStateFor(int index) {
    if (index + 1 >= _simulationSteps.length) return null;
    return _simulationSteps[index + 1].currentState;
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
                'Simulation',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Input field
              buildInputField(context: context),

              const SizedBox(height: 12),

              // Simulate button
              buildSimulateButton(context: context),

              const SizedBox(height: 12),

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
                buildResultCard(
                  context: context,
                  isAccepted: widget.simulationResult!.isAccepted,
                  errorMessage: widget.simulationResult!.errorMessage,
                  additionalInfo: widget.simulationResult!.steps.isNotEmpty
                      ? Text(
                          'Steps: ${widget.simulationResult!.steps.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                ),
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
      ),
    );
  }

  Widget _buildRegexResultCard(BuildContext context, String regex) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: colorScheme.primary, size: 20),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Switch(
                value: _isStepByStep,
                onChanged: (value) {
                  setState(() {
                    _isStepByStep = value;
                    if (!value) {
                      _currentStepIndex = 0;
                      _isPlaying = false;
                      _simulationSteps.clear();
                      highlightService.clear();
                    }
                  });
                  if (value) {
                    _loadSimulationSteps();
                  }
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step-by-Step Execution',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'Step ${_currentStepIndex + 1} of ${_simulationSteps.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
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
    final bool isFinal = _currentStepIndex == _simulationSteps.length - 1;
    final bool accepted = widget.simulationResult?.isAccepted ?? false;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isFinal
        ? (accepted ? colorScheme.tertiary : colorScheme.error)
        : colorScheme.primary;
    final icon = isFinal
        ? (accepted ? Icons.check_circle : Icons.cancel)
        : Icons.play_circle;
    final description = _describeStep(_currentStepIndex);
    final consumed = _currentStepIndex == 0 ? null : step.usedTransition;
    final nextState = _nextStateFor(_currentStepIndex);
    final remaining = step.remainingInput;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Step ${_currentStepIndex + 1}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          if (consumed != null) ...[
            const SizedBox(height: 4),
            Text(
              'Consumed: "$consumed"',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ],
          if (nextState != null) ...[
            const SizedBox(height: 4),
            Text(
              'Next state: ${formatState(nextState)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Remaining input: ${remaining.isEmpty ? 'ε' : '"$remaining"'}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
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
          onPressed: _currentStepIndex < _simulationSteps.length - 1
              ? _nextStep
              : null,
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
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListView.builder(
        itemCount: _simulationSteps.length,
        itemBuilder: (context, index) {
          final isCurrentStep = index == _currentStepIndex;
          final isFinal = index == _simulationSteps.length - 1;
          final isAcceptedStep = isFinal
              ? (widget.simulationResult?.isAccepted ?? false)
              : false;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrentStep
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCurrentStep
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                  child: Text(
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _describeStep(index),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAcceptedStep)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.tertiary,
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
      _emitHighlightForCurrentStep();
    }
  }

  void _nextStep() {
    if (_currentStepIndex < _simulationSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _emitHighlightForCurrentStep();
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
          _emitHighlightForCurrentStep();
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
    highlightService.clear();
  }

  void _emitHighlightForCurrentStep() {
    if (!_isStepByStep || _simulationSteps.isEmpty) {
      highlightService.clear();
      return;
    }

    highlightService.emitFromSteps(_simulationSteps, _currentStepIndex);
  }
}
