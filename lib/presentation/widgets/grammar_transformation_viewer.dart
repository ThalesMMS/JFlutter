import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/grammar_transformations.dart';
import '../core/algo_log.dart';

class GrammarTransformationViewer extends StatefulWidget {
  final String initialGrammar;

  const GrammarTransformationViewer({
    super.key,
    required this.initialGrammar,
  });

  @override
  State<GrammarTransformationViewer> createState() => _GrammarTransformationViewerState();
}

class _GrammarTransformationViewerState extends State<GrammarTransformationViewer> {
  final TextEditingController _grammarController = TextEditingController();
  Grammar? _currentGrammar;
  Grammar? _transformedGrammar;
  String _transformationType = '';
  bool _isTransforming = false;
  List<Map<String, dynamic>> _steps = [];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _grammarController.text = widget.initialGrammar;
    _parseGrammar();
  }

  @override
  void dispose() {
    _grammarController.dispose();
    super.dispose();
  }

  void _parseGrammar() {
    try {
      final grammar = Grammar.fromString(_grammarController.text);
      setState(() {
        _currentGrammar = grammar;
        _transformedGrammar = null;
        _transformationType = '';
        _steps.clear();
        _currentStep = 0;
      });
    } catch (e) {
      setState(() {
        _currentGrammar = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao analisar gramática: $e')),
      );
    }
  }

  Future<void> _transformGrammar(String transformationType) async {
    if (_currentGrammar == null) return;

    setState(() {
      _isTransforming = true;
      _steps.clear();
      _currentStep = 0;
    });

    try {
      // Clear previous logs
      AlgoLog.clear();
      
      Grammar result;
      switch (transformationType) {
        case 'unit':
          result = GrammarTransformations.removeUnitProductions(_currentGrammar!);
          break;
        case 'lambda':
          result = GrammarTransformations.removeLambdaProductions(_currentGrammar!);
          break;
        case 'useless':
          result = GrammarTransformations.removeUselessProductions(_currentGrammar!);
          break;
        case 'cnf':
          result = GrammarTransformations.toChomskyNormalForm(_currentGrammar!);
          break;
        default:
          throw ArgumentError('Unknown transformation type: $transformationType');
      }
      
      // Get the steps (simplified for now)
      final steps = <Map<String, dynamic>>[];
      
      setState(() {
        _transformedGrammar = result;
        _transformationType = transformationType;
        _steps = steps;
        _isTransforming = false;
      });
    } catch (e) {
      setState(() {
        _isTransforming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na transformação: $e')),
      );
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _steps.length) {
      setState(() {
        _currentStep = step;
      });
    }
  }

  String _getTransformationTitle(String type) {
    switch (type) {
      case 'unit':
        return 'Remoção de Produções Unitárias';
      case 'lambda':
        return 'Remoção de Produções Lambda';
      case 'useless':
        return 'Remoção de Produções Inúteis';
      case 'cnf':
        return 'Forma Normal de Chomsky';
      default:
        return 'Transformação';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.transform,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Transformações de Gramática',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Transforme gramáticas regulares e livres de contexto',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Grammar input
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gramática de Entrada:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _grammarController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Ex.:\nS -> aA | b\nA -> a | bS | λ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _parseGrammar(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _parseGrammar,
                      child: const Text('Analisar'),
                    ),
                    const SizedBox(width: 8),
                    if (_currentGrammar != null) ...[
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 4),
                      Text('Gramática válida', style: TextStyle(color: Colors.green)),
                    ] else ...[
                      Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 4),
                      Text('Gramática inválida', style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // Grammar analysis
        if (_currentGrammar != null) ...[
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Análise da Gramática:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildGrammarAnalysis(_currentGrammar!),
                ],
              ),
            ),
          ),
        ],

        // Transformation buttons
        if (_currentGrammar != null) ...[
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Transformações Disponíveis',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _currentGrammar!.hasUnitProductions() && !_isTransforming
                            ? () => _transformGrammar('unit')
                            : null,
                        icon: const Icon(Icons.remove, size: 16),
                        label: const Text('Remover Unitárias'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _currentGrammar!.hasLambdaProductions() && !_isTransforming
                            ? () => _transformGrammar('lambda')
                            : null,
                        icon: const Icon(Icons.remove_circle_outline, size: 16),
                        label: const Text('Remover Lambda'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: !_isTransforming ? () => _transformGrammar('useless') : null,
                        icon: const Icon(Icons.cleaning_services, size: 16),
                        label: const Text('Remover Inúteis'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: !_isTransforming ? () => _transformGrammar('cnf') : null,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Forma Normal de Chomsky'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],

        // Transformation result
        if (_transformedGrammar != null) ...[
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _getTransformationTitle(_transformationType),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Gramática Transformada:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SelectableText(
                      _transformedGrammar!.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _transformedGrammar!.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gramática copiada para a área de transferência')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copiar gramática',
                      ),
                      const SizedBox(width: 8),
                      Text('${_transformedGrammar!.productions.length} produções'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  _buildGrammarAnalysis(_transformedGrammar!),
                ],
              ),
            ),
          ),
        ],

        // Steps section
        if (_steps.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Passos da Transformação:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${_currentStep + 1} de ${_steps.length}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Step navigation
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentStep > 0 ? _previousStep : null,
                        icon: const Icon(Icons.skip_previous),
                        tooltip: 'Passo anterior',
                      ),
                      Expanded(
                        child: Slider(
                          value: _currentStep.toDouble(),
                          min: 0,
                          max: (_steps.length - 1).toDouble(),
                          divisions: _steps.length - 1,
                          onChanged: (value) => _goToStep(value.round()),
                        ),
                      ),
                      IconButton(
                        onPressed: _currentStep < _steps.length - 1 ? _nextStep : null,
                        icon: const Icon(Icons.skip_next),
                        tooltip: 'Próximo passo',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Current step details
                  if (_currentStep < _steps.length) ...[
                    _buildStepDetails(_steps[_currentStep]),
                  ],
                ],
              ),
            ),
          ),
        ],

        // Loading indicator
        if (_isTransforming) ...[
          const SizedBox(height: 16),
          const Center(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Transformando gramática...'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGrammarAnalysis(Grammar grammar) {
    final analysis = GrammarTransformations.analyzeGrammar(grammar);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Variáveis: ${analysis['variables']}'),
        Text('Terminais: ${analysis['terminals']}'),
        Text('Produções: ${analysis['productions']}'),
        Text('Produções unitárias: ${analysis['unit_productions']}'),
        Text('Produções lambda: ${analysis['lambda_productions']}'),
        Text('Símbolo inicial: ${analysis['start_variable']}'),
      ],
    );
  }

  Widget _buildStepDetails(Map<String, dynamic> step) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStepIcon(step['type'] ?? 'info'),
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getStepTitle(step['type'] ?? 'info'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          if (step['data'] != null) ...[
            const SizedBox(height: 8),
            Text(step['data'].toString()),
          ],
          if (step['highlight'] != null && (step['highlight'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (step['highlight'] as List<dynamic>).map<Widget>((item) => 
                Chip(
                  label: Text(item.toString()),
                  backgroundColor: Colors.orange.shade100,
                  labelStyle: TextStyle(color: Colors.orange.shade800),
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStepIcon(String type) {
    switch (type) {
      case 'removeUnitProductions':
        return Icons.remove;
      case 'removeLambdaProductions':
        return Icons.remove_circle_outline;
      case 'removeUselessProductions':
        return Icons.cleaning_services;
      case 'toChomskyNormalForm':
        return Icons.auto_awesome;
      default:
        return Icons.info;
    }
  }

  String _getStepTitle(String type) {
    switch (type) {
      case 'removeUnitProductions':
        return 'Remoção de Produções Unitárias';
      case 'removeLambdaProductions':
        return 'Remoção de Produções Lambda';
      case 'removeUselessProductions':
        return 'Remoção de Produções Inúteis';
      case 'toChomskyNormalForm':
        return 'Forma Normal de Chomsky';
      default:
        return 'Passo';
    }
  }
}
