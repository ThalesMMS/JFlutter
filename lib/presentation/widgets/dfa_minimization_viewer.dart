import 'package:flutter/material.dart';
import '../../core/automaton.dart';
import '../../core/dfa_algorithms.dart';

class DfaMinimizationViewer extends StatefulWidget {
  final Automaton dfa;
  final ValueChanged<Automaton> onMinimized;

  const DfaMinimizationViewer({
    super.key,
    required this.dfa,
    required this.onMinimized,
  });

  @override
  State<DfaMinimizationViewer> createState() => _DfaMinimizationViewerState();
}

class _DfaMinimizationViewerState extends State<DfaMinimizationViewer> {
  int _currentStep = 0;
  List<Map<String, dynamic>> _steps = [];
  bool _isMinimizing = false;

  @override
  void initState() {
    super.initState();
    _initializeSteps();
  }

  void _initializeSteps() {
    _steps = [
      {
        'title': 'AFD Original',
        'description': 'Este é o autômato original que será minimizado.',
        'automaton': widget.dfa,
      },
    ];
  }

  Future<void> _startMinimization() async {
    setState(() {
      _isMinimizing = true;
      _steps = []; // Clear initial steps
      _currentStep = 0;
    });

    // Create a copy of the DFA to work with
    final dfa = widget.dfa.clone();
    
    // Run the minimization algorithm with step callbacks
    final minimizedDfa = minimizeDfa(
      dfa,
      onStep: (title, description, {automaton, partitions}) {
        // Add the step to our list
        setState(() {
          _steps.add({
            'title': title,
            'description': description,
            'automaton': automaton,
            'partitions': partitions,
            'isFinal': title == 'AFD Minimizado',
          });
          _currentStep = _steps.length - 1;
        });
        // Optional small delay for better visualization (fire-and-forget)
        Future.delayed(const Duration(milliseconds: 250));
      },
    );
    
    // Final update with the minimized DFA
    setState(() {
      _isMinimizing = false;
      widget.onMinimized(minimizedDfa);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStep];
    final hasPartitions = currentStep['partitions'] != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          margin: const EdgeInsets.all(16.0),
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
            padding: const EdgeInsets.all(20.0),
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
                        Icons.compress,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentStep['title'],
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
                  currentStep['description'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Content
        Expanded(
          child: hasPartitions
              ? _buildPartitionsView(currentStep['partitions'])
              : _buildAutomatonView(currentStep['automaton']),
        ),
        
        // Navigation
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
              OutlinedButton.icon(
                onPressed: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Anterior'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              
              if (_currentStep == 0)
                FilledButton.icon(
                  onPressed: _isMinimizing ? null : _startMinimization,
                  icon: _isMinimizing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Iniciar Minimização'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                )
              else if (_currentStep < _steps.length - 1)
                FilledButton.icon(
                  onPressed: () => setState(() => _currentStep++),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Próximo'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
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
                    final isInitial = state == widget.dfa.initialId;
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
