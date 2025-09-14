import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/automaton.dart';
import '../../core/algorithms.dart' as algo;
// AlgoLog steps omitted in this simplified viewer.

class RegexConversionViewer extends StatefulWidget {
  final Automaton automaton;

  const RegexConversionViewer({
    super.key,
    required this.automaton,
  });

  @override
  State<RegexConversionViewer> createState() => _RegexConversionViewerState();
}

class _RegexConversionViewerState extends State<RegexConversionViewer> {
  String _regex = '';
  bool _isConverting = false;
  final List<String> _steps = const [];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _convertToRegex();
  }

  Future<void> _convertToRegex() async {
    if (!widget.automaton.isDfa) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O autômato deve ser um AFD para conversão')),
      );
      return;
    }

    setState(() {
      _isConverting = true;
      _steps.clear();
      _currentStep = 0;
    });

    try {
      // Convert to regex
      final regex = algo.dfaToRegex(widget.automaton, allowLambda: true);
      setState(() {
        _regex = regex;
        _isConverting = false;
      });
    } catch (e) {
      setState(() {
        _isConverting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na conversão: $e')),
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
                          'Conversão AFD → Expressão Regular',
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
                    'Convertendo autômato com ${widget.automaton.states.length} estados',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Result section
        if (_regex.isNotEmpty) ...[
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100,
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
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Expressão Regular Resultante',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SelectableText(
                        _regex,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _regex));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Expressão copiada para a área de transferência'),
                                backgroundColor: Colors.green.shade600,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copiar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_regex.length} caracteres',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Steps omitted in simplified viewer

        // Loading indicator
        if (_isConverting) ...[
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
                    Text('Convertendo autômato para expressão regular...'),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Error state
        if (!_isConverting && _regex.isEmpty && _steps.isEmpty) ...[
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Não foi possível converter o autômato'),
                  Text('Verifique se é um AFD válido'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Step details omitted

  IconData _getStepIcon(String type) {
    switch (type) {
      case 'eliminate':
        return Icons.remove_circle_outline;
      case 'transition':
        return Icons.arrow_forward;
      case 'final':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getStepTitle(String type) {
    switch (type) {
      case 'eliminate':
        return 'Eliminando Estado';
      case 'transition':
        return 'Atualizando Transições';
      case 'final':
        return 'Expressão Final';
      default:
        return 'Passo';
    }
  }
}
