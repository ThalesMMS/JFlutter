//
//  tm_simulation_panel.dart
//  JFlutter
//
//  Realiza a simulação de Máquinas de Turing para o autômato ativo, oferecendo
//  campos de entrada, controles de execução e apresentação de resultados com
//  histórico de passos e mensagens de aceitação.
//  Dialoga com o TMEditorProvider e com o SimulationHighlightService para manter
//  sincronização com o canvas, limpando controladores e destaques conforme o
//  ciclo de vida do widget.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/tm_simulator.dart';
import '../../core/models/simulation_step.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../providers/tm_editor_provider.dart';
import 'tm/tape_drawer.dart';
import 'trace_viewers/tm_trace_viewer.dart';

/// Panel for Turing Machine simulation and string testing
class TMSimulationPanel extends ConsumerStatefulWidget {
  final SimulationHighlightService highlightService;

  TMSimulationPanel({super.key, SimulationHighlightService? highlightService})
    : highlightService = highlightService ?? SimulationHighlightService();

  @override
  ConsumerState<TMSimulationPanel> createState() => _TMSimulationPanelState();
}

class _TMSimulationPanelState extends ConsumerState<TMSimulationPanel>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();

  bool _isSimulating = false;
  bool _hasSimulationResult = false;
  bool? _isAccepted;
  String? _statusMessage;
  List<SimulationStep> _simulationSteps = const [];
  TMSimulationResult? _result;
  int _currentStepIndex = 0;
  TapeState _currentTapeState = TapeState.initial();

  // Animation controllers for smooth transitions
  late AnimationController _stepTransitionController;
  late Animation<double> _stepFadeAnimation;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _stepTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _stepFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _stepTransitionController,
        curve: Curves.easeInOut,
      ),
    );
    _stepTransitionController.value = 1.0;
  }

  @override
  void dispose() {
    _stepTransitionController.dispose();
    _inputController.dispose();
    widget.highlightService.clear();
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
          'TM Simulation',
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
              hintText: 'e.g., 101, 1100, 111',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Examples: 101 (binary), 1100 (palindrome), 111 (counting)',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Simulation Results',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _hasSimulationResult
            ? _buildResults(context)
            : _buildEmptyResults(context),
        if (_hasSimulationResult && _result != null) ...[
          const SizedBox(height: 12),
          _buildTapePanel(context),
        ],
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
    if (_isAccepted == null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error, color: colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusMessage ?? 'Simulation error',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isAccepted = _isAccepted!;
    final color = isAccepted ? Colors.green : Colors.red;
    final message = _statusMessage ?? (isAccepted ? 'Accepted' : 'Rejected');

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
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_simulationSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Simulation Steps:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_hasSimulationResult && _result != null)
              FadeTransition(
                opacity: _stepFadeAnimation,
                child: TMTraceViewer(
                  result: _result!,
                  highlightService: widget.highlightService,
                  onStepChanged: _handleStepChanged,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _simulateTM() async {
    final inputString = _inputController.text.trim();

    if (inputString.isEmpty) {
      // Allow empty string — TMs can legitimately accept/reject ε
    }

    final tm = ref.read(tmEditorProvider).tm;
    if (tm == null) {
      _showError('Create a Turing machine on the canvas before simulating');
      return;
    }

    setState(() {
      _isSimulating = true;
      _hasSimulationResult = false;
      _isAccepted = null;
      _statusMessage = null;
      _simulationSteps = const [];
      _result = null;
      _currentStepIndex = 0;
      _currentTapeState = TapeState.initial();
    });

    widget.highlightService.clear();

    final result = await Future(
      () => TMSimulator.simulate(tm, inputString, stepByStep: true),
    );

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      final message = result.error ?? 'Simulation failed';
      setState(() {
        _isSimulating = false;
        _hasSimulationResult = true;
        _isAccepted = null;
        _statusMessage = message;
        _simulationSteps = const [];
        _result = null;
      });
      widget.highlightService.clear();
      _showError(message);
      return;
    }

    final simulation = result.data!;

    setState(() {
      _isSimulating = false;
      _hasSimulationResult = true;
      _isAccepted = simulation.accepted;
      _statusMessage = simulation.accepted
          ? 'Accepted'
          : (simulation.errorMessage?.isNotEmpty ?? false
                ? 'Rejected: ${simulation.errorMessage}'
                : 'Rejected');
      _simulationSteps = simulation.steps;
      _result = simulation;
      _currentStepIndex = 0;
      _currentTapeState = simulation.steps.isNotEmpty
          ? _convertStepToTapeState(simulation.steps[0])
          : TapeState.initial();
    });

    if (simulation.steps.isNotEmpty) {
      widget.highlightService.emitFromSteps(simulation.steps, 0);
    } else {
      widget.highlightService.clear();
    }
  }

  void _showError(String message) {
    widget.highlightService.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handleStepChanged(int stepIndex) async {
    if (_result == null || stepIndex >= _result!.steps.length) return;
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
    });

    // Fade out current step
    await _stepTransitionController.reverse();

    // Update state with new step
    if (mounted) {
      setState(() {
        _currentStepIndex = stepIndex;
        _currentTapeState = _convertStepToTapeState(_result!.steps[stepIndex]);
      });
    }

    // Fade in new step
    await _stepTransitionController.forward();

    if (mounted) {
      setState(() {
        _isTransitioning = false;
      });
    }
  }

  TapeState _convertStepToTapeState(SimulationStep step) {
    final tm = ref.read(tmEditorProvider).tm;
    final blankSymbol = tm?.blankSymbol ?? '□';

    // Parse tape contents
    final cells = step.tapeContents.isEmpty
        ? <String>[]
        : step.tapeContents.split('');

    // Get head position from step (now available)
    final headPos = step.headPosition ?? 0;

    // Parse last operation from transition
    String? lastRead;
    String? lastWrite;
    String? lastOp;

    if (step.usedTransition != null) {
      // Format: "state,readSymbol → nextState,writeSymbol,direction"
      final parts = step.usedTransition!.split(' → ');
      if (parts.length == 2) {
        final before = parts[0].split(',');
        final after = parts[1].split(',');
        if (before.length >= 2) {
          lastRead = before[1];
        }
        if (after.length >= 2) {
          lastWrite = after[1];
        }
        if (after.length >= 3) {
          lastOp = after[2];
        }
      }
    }

    return TapeState(
      cells: cells,
      headPosition: headPos,
      blankSymbol: blankSymbol,
      lastOperation: lastOp,
      lastReadSymbol: lastRead,
      lastWriteSymbol: lastWrite,
    );
  }

  Widget _buildTapePanel(BuildContext context) {
    final editorState = ref.watch(tmEditorProvider);
    final tapeAlphabet = editorState.tapeSymbols;

    return FadeTransition(
      opacity: _stepFadeAnimation,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: TMTapePanel(
          tapeState: _currentTapeState,
          tapeAlphabet: tapeAlphabet,
          isSimulating: true,
        ),
      ),
    );
  }
}
