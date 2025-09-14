import 'package:flutter/material.dart';
import '../../core/automaton.dart';
import '../../core/algorithms.dart';

/// A widget that visualizes the NFA to DFA conversion process.
class NfaToDfaViewer extends StatefulWidget {
  final Automaton nfa;
  final ValueChanged<Automaton> onConverted;

  const NfaToDfaViewer({
    Key? key,
    required this.nfa,
    required this.onConverted,
  }) : super(key: key);

  @override
  _NfaToDfaViewerState createState() => _NfaToDfaViewerState();
}

class _NfaToDfaViewerState extends State<NfaToDfaViewer> {
  final List<Map<String, dynamic>> _steps = [];
  int _currentStep = 0;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _initializeSteps();
  }

  void _initializeSteps() {
    _steps.add({
      'title': 'NFA Original',
      'description': 'Este é o autômato não-determinístico original que será convertido.',
      'automaton': widget.nfa,
    });
  }

  Future<void> _startConversion() async {
    setState(() {
      _isConverting = true;
      _steps.clear();
      _currentStep = 0;
    });

    try {
      // Add a small delay to show loading state
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Run the conversion algorithm with step callbacks
      final result = nfaToDfaIfValid(widget.nfa);
      
      if (result != null) {
        // Add the result as a step
        setState(() {
          _steps.add({
            'title': 'AFD Resultante',
            'description': 'Este é o autômato determinístico resultante da conversão.',
            'automaton': result.dfa,
          });
          _currentStep = _steps.length - 1;
        });
        
        widget.onConverted(result.dfa);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Não foi possível converter o AFN para AFD'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na conversão: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStep < _steps.length ? _steps[_currentStep] : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step title and description
        if (currentStep != null) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStep['title'],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(currentStep['description']),
              ],
            ),
          ),
          
          // Visual representation (automaton or partitions)
          Expanded(
            child: currentStep['automaton'] != null
                ? _buildAutomatonView(currentStep['automaton'])
                : currentStep['partitions'] != null
                    ? _buildPartitionsView(currentStep['partitions'])
                    : Center(
                        child: Text(
                          'Visualização não disponível para esta etapa',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
          ),
        ],
        
        // Controls
        Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isConverting)
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Convertendo...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else if (_steps.isEmpty)
                FilledButton.icon(
                  onPressed: _startConversion,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Iniciar Conversão'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                )
              else
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _currentStep > 0
                          ? () => setState(() => _currentStep--)
                          : null,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Anterior'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentStep + 1} de ${_steps.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _currentStep < _steps.length - 1
                          ? () => setState(() => _currentStep++)
                          : null,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Próximo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              
              if (_steps.isNotEmpty && _currentStep == _steps.length - 1)
                FilledButton.icon(
                  onPressed: () {
                    final dfa = _steps.last['automaton'] as Automaton?;
                    if (dfa != null) {
                      widget.onConverted(dfa);
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Concluir'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPartitionsView(List<dynamic> partitions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: partitions.length,
      itemBuilder: (context, index) {
        final partition = Map<String, dynamic>.from(partitions[index]);
        final states = (partition['states'] as List<dynamic>).cast<String>();
        final isFinal = partition['isFinal'] as bool;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFinal ? Colors.green.shade100 : Colors.grey.shade200,
                        border: Border.all(
                          color: isFinal ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            color: isFinal ? Colors.green.shade800 : Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isFinal ? 'Estados Finais' : 'Estados Não-Finais',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isFinal ? Colors.green.shade800 : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: states.map((state) {
                    final isInitial = state == widget.nfa.initialId;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isInitial 
                            ? Colors.blue.shade100 
                            : (isFinal ? Colors.green.shade50 : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isInitial 
                              ? Colors.blue.shade300 
                              : (isFinal ? Colors.green.shade200 : Colors.grey.shade300),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isInitial) ...[
                            Icon(Icons.play_arrow, size: 16, color: Colors.blue.shade800),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            state,
                            style: TextStyle(
                              color: isInitial 
                                  ? Colors.blue.shade900 
                                  : (isFinal ? Colors.green.shade900 : Colors.grey.shade900),
                              fontWeight: isInitial ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAutomatonView(Automaton? automaton) {
    if (automaton == null) return const Center(child: CircularProgressIndicator());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // States
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estados (${automaton.states.length}):', 
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: automaton.states.map((s) {
                  final isInitial = s.isInitial;
                  final isFinal = s.isFinal;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isInitial 
                          ? Colors.blue.shade50 
                          : (isFinal ? Colors.green.shade50 : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isInitial 
                            ? Colors.blue.shade300 
                            : (isFinal ? Colors.green.shade300 : Colors.grey.shade300),
                        width: isInitial ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isInitial) ...[
                          Icon(Icons.play_arrow, size: 16, color: Colors.blue.shade800),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          s.id,
                          style: TextStyle(
                            color: isInitial 
                                ? Colors.blue.shade900 
                                : (isFinal ? Colors.green.shade900 : Colors.grey.shade900),
                            fontWeight: isInitial ? FontWeight.bold : null,
                          ),
                        ),
                        if (isFinal) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.flag, size: 14, color: Colors.green.shade800),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        
        // Transitions
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transições (${automaton.transitions.length}):', 
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.5),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1.5),
                        },
                        border: TableBorder.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                            ),
                            children: [
                              _buildTableHeader('De'),
                              _buildTableHeader('Símbolo'),
                              _buildTableHeader('Para'),
                            ],
                          ),
                          ...automaton.transitions.entries.expand((e) {
                            final parts = e.key.split('|');
                            final from = parts[0];
                            final symbol = parts[1];
                            
                            return e.value.map((to) => TableRow(
                              decoration: const BoxDecoration(
                                border: Border.symmetric(
                                  horizontal: BorderSide(
                                    color: Color(0xFFEEEEEE),
                                    width: 1,
                                  ),
                                ),
                              ),
                              children: [
                                _buildTableCell(from),
                                _buildTableCell(symbol),
                                _buildTableCell(to),
                              ],
                            ));
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
  
  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Text(text),
    );
  }
}
