import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/algo_log.dart';
import '../../core/run.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/automaton.dart';
import '../providers/algorithm_execution_provider.dart';

/// Enhanced algorithm visualization panel with step-by-step execution
class EnhancedAlgoview extends StatefulWidget {
  final List<String> logLines;
  final Set<String> highlightedStates;
  final bool isRunning;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStep;
  final VoidCallback? onReset;
  final void Function(double)? onSpeedChanged;
  final StepByStepRun? stepByStepRun;
  final VoidCallback? onNextStep;
  final VoidCallback? onPreviousStep;
  final bool useProvider;

  const EnhancedAlgoview({
    super.key,
    required this.logLines,
    this.highlightedStates = const {},
    this.isRunning = false,
    this.onPlay,
    this.onPause,
    this.onStep,
    this.onReset,
    this.onSpeedChanged,
    this.stepByStepRun,
    this.onNextStep,
    this.onPreviousStep,
    this.useProvider = false,
  });

  @override
  State<EnhancedAlgoview> createState() => _EnhancedAlgoviewState();
}

class _EnhancedAlgoviewState extends State<EnhancedAlgoview> {
  final ScrollController _scrollController = ScrollController();
  double _playbackSpeed = 1.0;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Auto-scroll to bottom when new log entries are added
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useProvider) {
      return Consumer<AlgorithmExecutionProvider>(
        builder: (context, provider, child) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Visualização do Algoritmo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (provider.highlightedStates.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${provider.highlightedStates.length} estado(s) ativo(s)',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Control panel
                  _buildControlPanelWithProvider(provider),
                  
                  const SizedBox(height: 16),
                  
                  // Step-by-step simulation info
                  if (provider.stepByStepRun != null) ...[
                    _buildStepByStepInfoWithProvider(provider),
                    const SizedBox(height: 16),
                  ],
                  
                  // Log display
                  Expanded(
                    child: _buildLogDisplayWithProvider(provider),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Original implementation without provider
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Visualização do Algoritmo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (widget.highlightedStates.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${widget.highlightedStates.length} estado(s) ativo(s)',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Control panel
            _buildControlPanel(),
            
            const SizedBox(height: 16),
            
            // Step-by-step simulation info
            if (widget.stepByStepRun != null) ...[
              _buildStepByStepInfo(),
              const SizedBox(height: 16),
            ],
            
            // Log display
            SizedBox(
              height: 400,
              child: _buildLogDisplay(),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepByStepInfo() {
    final run = widget.stepByStepRun!;
    final word = run.word;
    final currentStates = run.currentStates;
    final stepIndex = run.stepIndex;
    final isComplete = run.isComplete;
    final accepted = false; // TODO: Implement word testing
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
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
                'Simulação Passo-a-passo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Palavra: '),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Text(
                  word.isEmpty ? 'ε' : word,
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Text('Passo: ${stepIndex + 1}'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isComplete 
                      ? (accepted ? Colors.green : Colors.red).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isComplete 
                        ? (accepted ? Colors.green : Colors.red).withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isComplete 
                      ? (accepted ? 'ACEITA' : 'REJEITA')
                      : 'EM EXECUÇÃO',
                  style: TextStyle(
                    color: isComplete 
                        ? (accepted ? Colors.green : Colors.red)
                        : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (currentStates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estados ativos: '),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: currentStates.map((state) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.withOpacity(0.5)),
                        ),
                        child: Text(
                          state,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlPanelWithProvider(AlgorithmExecutionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause button
              IconButton(
                onPressed: provider.isRunning ? provider.pause : provider.resume,
                icon: Icon(
                  provider.isRunning ? Icons.pause_circle : Icons.play_circle,
                  size: 32,
                ),
                tooltip: provider.isRunning ? 'Pausar' : 'Executar',
              ),
              
              // Step button
              IconButton(
                onPressed: provider.nextStep,
                icon: const Icon(Icons.skip_next, size: 28),
                tooltip: 'Próximo passo',
              ),
              
              // Previous step button (for step-by-step simulation)
              if (provider.stepByStepRun != null)
                IconButton(
                  onPressed: provider.previousStep,
                  icon: const Icon(Icons.skip_previous, size: 28),
                  tooltip: 'Passo anterior',
                ),
              
              // Reset button
              IconButton(
                onPressed: provider.reset,
                icon: const Icon(Icons.refresh, size: 28),
                tooltip: 'Reiniciar',
              ),
              
              const Spacer(),
              
              // Speed control
              Row(
                children: [
                  const Icon(Icons.speed, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Velocidade:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: provider.playbackSpeed,
                      min: 0.1,
                      max: 3.0,
                      divisions: 29,
                      label: '${(provider.playbackSpeed * 100).round()}%',
                      onChanged: (value) {
                        provider.setSpeed(value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Progress indicator
          if (provider.logLines.isNotEmpty || provider.stepByStepRun != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: provider.stepByStepRun != null 
                  ? (provider.stepByStepRun!.stepIndex + 1) / (provider.stepByStepRun!.word.length + 1)
                  : provider.currentStep / provider.logLines.length,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              provider.stepByStepRun != null
                  ? 'Passo ${provider.stepByStepRun!.stepIndex + 1} de ${provider.stepByStepRun!.word.length + 1}'
                  : 'Passo ${provider.currentStep} de ${provider.logLines.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepByStepInfoWithProvider(AlgorithmExecutionProvider provider) {
    final run = provider.stepByStepRun!;
    final word = run.word;
    final currentStates = run.currentStates;
    final stepIndex = run.stepIndex;
    final isComplete = run.isComplete;
    final accepted = false; // TODO: Implement word testing
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
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
                'Simulação Passo-a-passo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Palavra: '),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Text(
                  word.isEmpty ? 'ε' : word,
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Text('Passo: ${stepIndex + 1}'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isComplete 
                      ? (accepted ? Colors.green : Colors.red).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isComplete 
                        ? (accepted ? Colors.green : Colors.red).withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isComplete 
                      ? (accepted ? 'ACEITA' : 'REJEITA')
                      : 'EM EXECUÇÃO',
                  style: TextStyle(
                    color: isComplete 
                        ? (accepted ? Colors.green : Colors.red)
                        : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (currentStates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estados ativos: '),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: currentStates.map((state) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.withOpacity(0.5)),
                        ),
                        child: Text(
                          state,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogDisplayWithProvider(AlgorithmExecutionProvider provider) {
    if (provider.logLines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum algoritmo em execução',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Execute uma operação para ver os passos do algoritmo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: provider.logLines.length,
        itemBuilder: (context, index) {
          final line = provider.logLines[index];
          final isCurrentStep = index == provider.currentStep;
          final isCompleted = index < provider.currentStep;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentStep 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : isCompleted
                      ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
                      : null,
              border: isCurrentStep 
                  ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5))
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step number
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCurrentStep 
                        ? Theme.of(context).colorScheme.primary
                        : isCompleted
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                            : Theme.of(context).colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrentStep || isCompleted
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Step content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentStep 
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      
                      // Highlighted states indicator
                      if (provider.highlightedStates.isNotEmpty && isCurrentStep) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: provider.highlightedStates.map((stateId) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange.withOpacity(0.5)),
                              ),
                              child: Text(
                                stateId,
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status indicator
                if (isCurrentStep)
                  Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  )
                else if (isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    size: 16,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause button
              IconButton(
                onPressed: widget.isRunning ? widget.onPause : widget.onPlay,
                icon: Icon(
                  widget.isRunning ? Icons.pause_circle : Icons.play_circle,
                  size: 32,
                ),
                tooltip: widget.isRunning ? 'Pausar' : 'Executar',
              ),
              
              // Step button
              IconButton(
                onPressed: widget.onStep,
                icon: const Icon(Icons.skip_next, size: 28),
                tooltip: 'Próximo passo',
              ),
              
              // Previous step button (for step-by-step simulation)
              if (widget.stepByStepRun != null)
                IconButton(
                  onPressed: widget.onPreviousStep,
                  icon: const Icon(Icons.skip_previous, size: 28),
                  tooltip: 'Passo anterior',
                ),
              
              // Reset button
              IconButton(
                onPressed: widget.onReset,
                icon: const Icon(Icons.refresh, size: 28),
                tooltip: 'Reiniciar',
              ),
              
              const Spacer(),
              
              // Speed control
              Row(
                children: [
                  const Icon(Icons.speed, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Velocidade:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: _playbackSpeed,
                      min: 0.1,
                      max: 3.0,
                      divisions: 29,
                      label: '${(_playbackSpeed * 100).round()}%',
                      onChanged: (value) {
                        setState(() {
                          _playbackSpeed = value;
                        });
                        widget.onSpeedChanged?.call(value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Progress indicator
          if (widget.logLines.isNotEmpty || widget.stepByStepRun != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: widget.stepByStepRun != null 
                  ? (widget.stepByStepRun!.stepIndex + 1) / (widget.stepByStepRun!.word.length + 1)
                  : _currentStep / widget.logLines.length,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.stepByStepRun != null
                  ? 'Passo ${widget.stepByStepRun!.stepIndex + 1} de ${widget.stepByStepRun!.word.length + 1}'
                  : 'Passo $_currentStep de ${widget.logLines.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogDisplay() {
    if (widget.logLines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum algoritmo em execução',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Execute uma operação para ver os passos do algoritmo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: widget.logLines.length,
        itemBuilder: (context, index) {
          final line = widget.logLines[index];
          final isCurrentStep = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentStep 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : isCompleted
                      ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
                      : null,
              border: isCurrentStep 
                  ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5))
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step number
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCurrentStep 
                        ? Theme.of(context).colorScheme.primary
                        : isCompleted
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                            : Theme.of(context).colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrentStep || isCompleted
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Step content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentStep 
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      
                      // Highlighted states indicator
                      if (widget.highlightedStates.isNotEmpty && isCurrentStep) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: widget.highlightedStates.map((stateId) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange.withOpacity(0.5)),
                              ),
                              child: Text(
                                stateId,
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status indicator
                if (isCurrentStep)
                  Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  )
                else if (isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    size: 16,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Algorithm execution controller for managing step-by-step execution
class AlgorithmController {
  final List<String> _logLines = [];
  final Set<String> _highlightedStates = {};
  bool _isRunning = false;
  int _currentStep = 0;
  double _playbackSpeed = 1.0;
  StepByStepRun? _stepByStepRun;
  
  // Callbacks
  void Function()? onStateChanged;
  void Function(Set<String>)? onHighlightChanged;
  
  List<String> get logLines => List.unmodifiable(_logLines);
  Set<String> get highlightedStates => Set.unmodifiable(_highlightedStates);
  bool get isRunning => _isRunning;
  int get currentStep => _currentStep;
  double get playbackSpeed => _playbackSpeed;
  StepByStepRun? get stepByStepRun => _stepByStepRun;
  
  void startAlgorithm(String algorithmName) {
    _logLines.clear();
    _highlightedStates.clear();
    _currentStep = 0;
    _isRunning = true;
    _logLines.add('Iniciando algoritmo: $algorithmName');
    onStateChanged?.call();
  }
  
  void addStep(String description, {Set<String>? highlights}) {
    _logLines.add(description);
    if (highlights != null) {
      _highlightedStates.clear();
      _highlightedStates.addAll(highlights);
    }
    _currentStep = _logLines.length - 1;
    onStateChanged?.call();
    onHighlightChanged?.call(_highlightedStates);
  }
  
  void pause() {
    _isRunning = false;
    onStateChanged?.call();
  }
  
  void resume() {
    _isRunning = true;
    onStateChanged?.call();
  }
  
  void reset() {
    _logLines.clear();
    _highlightedStates.clear();
    _currentStep = 0;
    _isRunning = false;
    onStateChanged?.call();
    onHighlightChanged?.call(_highlightedStates);
  }
  
  void setSpeed(double speed) {
    _playbackSpeed = speed;
    onStateChanged?.call();
  }
  
  void nextStep() {
    if (_currentStep < _logLines.length - 1) {
      _currentStep++;
      onStateChanged?.call();
    }
  }
  
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      onStateChanged?.call();
    }
  }
  
  void startStepByStepSimulation(StepByStepRun run) {
    _stepByStepRun = run;
    _logLines.clear();
    _highlightedStates.clear();
    _currentStep = 0;
    _isRunning = true;
    _logLines.add('Iniciando simulação passo-a-passo da palavra: ${run.word}');
    onStateChanged?.call();
  }
  
  void nextSimulationStep() {
    if (_stepByStepRun != null && !_stepByStepRun!.isComplete) {
      // This would be implemented to advance the simulation
      // For now, we'll just update the current step
      _currentStep++;
      onStateChanged?.call();
    }
  }
  
  void previousSimulationStep() {
    if (_stepByStepRun != null && _currentStep > 0) {
      _currentStep--;
      onStateChanged?.call();
    }
  }
  
  void clearStepByStepSimulation() {
    _stepByStepRun = null;
    _logLines.clear();
    _highlightedStates.clear();
    _currentStep = 0;
    _isRunning = false;
    onStateChanged?.call();
    onHighlightChanged?.call(_highlightedStates);
  }

}
