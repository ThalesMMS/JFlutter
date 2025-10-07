/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/widgets/tm_simulation_panel.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Componente de interface que executa simulações de Máquinas de Turing a partir do autômato ativo. Exibe campos de entrada, botões de controle e resultados para orientar o usuário durante a análise.
/// Contexto: Interage com o TMEditorProvider para obter configurações atuais e utiliza serviços de destaque para sincronizar o canvas. Organiza visualizações como histórico de passos e mensagens de aceitação dentro de um painel responsivo.
/// Observações: Gerencia ciclo de vida de controladores locais e limpa realces quando desmontado para evitar estados residuais. Pode ser embutido em páginas maiores compartilhando a instância de SimulationHighlightService entre widgets.
/// ---------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/tm_simulator.dart';
import '../../core/models/simulation_step.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../providers/tm_editor_provider.dart';
import 'trace_viewers/tm_trace_viewer.dart';

/// Panel for Turing Machine simulation and string testing
class TMSimulationPanel extends ConsumerStatefulWidget {
  final SimulationHighlightService highlightService;

  TMSimulationPanel({
    super.key,
    SimulationHighlightService? highlightService,
  }) : highlightService = highlightService ?? SimulationHighlightService();

  @override
  ConsumerState<TMSimulationPanel> createState() => _TMSimulationPanelState();
}

class _TMSimulationPanelState extends ConsumerState<TMSimulationPanel> {
  final TextEditingController _inputController = TextEditingController();

  bool _isSimulating = false;
  bool _hasSimulationResult = false;
  bool? _isAccepted;
  String? _statusMessage;
  List<SimulationStep> _simulationSteps = const [];
  TMSimulationResult? _result;

  @override
  void dispose() {
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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulation Results',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _hasSimulationResult
                ? _buildResults(context)
                : _buildEmptyResults(context),
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
              TMTraceViewer(
                result: _result!,
                highlightService: widget.highlightService,
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _simulateTM() async {
    final inputString = _inputController.text.trim();

    if (inputString.isEmpty) {
      _showError('Please enter an input string');
      return;
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
}
