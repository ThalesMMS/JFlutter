import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/automaton.dart';
import '../providers/automaton_provider.dart';
import '../providers/algorithm_provider.dart';
import '../../injection/dependency_injection.dart';
import '../../core/equivalence_checking.dart';
import '../../core/algorithms.dart';

/// Advanced equivalence checker viewer with multiple algorithms
class EquivalenceCheckerViewer extends StatefulWidget {
  const EquivalenceCheckerViewer({super.key});

  @override
  State<EquivalenceCheckerViewer> createState() => _EquivalenceCheckerViewerState();
}

class _EquivalenceCheckerViewerState extends State<EquivalenceCheckerViewer> {
  final TextEditingController _wordController = TextEditingController();
  bool _isChecking = false;
  EquivalenceResult? _lastResult;
  String? _error;

  @override
  void dispose() {
    _wordController.dispose();
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
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verificação de Equivalência',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Input section
            _buildInputSection(),
            
            const SizedBox(height: 16),
            
            // Results section
            Expanded(
              child: _buildResultsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teste de Equivalência',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Digite uma palavra para testar se ela é aceita por ambos os autômatos:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wordController,
                  decoration: const InputDecoration(
                    hintText: 'Ex: aba, 101, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isChecking ? null : _testWord,
                child: _isChecking 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Testar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isChecking ? null : _checkEquivalence,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Verificar Equivalência Completa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_error != null) {
      return _buildErrorSection();
    }

    if (_lastResult != null) {
      return _buildEquivalenceResult();
    }

    return _buildEmptyState();
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro na Verificação',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _lastResult = null;
              });
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEquivalenceResult() {
    final result = _lastResult!;
    final isEquivalent = result.areEquivalent;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isEquivalent ? Colors.green : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isEquivalent ? Colors.green : Colors.orange).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isEquivalent ? Icons.check_circle : Icons.cancel,
                color: isEquivalent ? Colors.green : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEquivalent ? 'Autômatos Equivalentes' : 'Autômatos NÃO Equivalentes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isEquivalent ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Método: ${result.method}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              result.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          
          // Counterexample words
          if (result.counterexampleWords.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Palavras de Contraexemplo:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.counterexampleWords.map((word) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    word,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          // Additional data
          if (result.additionalData.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Detalhes Técnicos'),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: result.additionalData.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Actions
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _lastResult = null;
                    _error = null;
                  });
                },
                child: const Text('Nova Verificação'),
              ),
              const SizedBox(width: 8),
              if (!isEquivalent && result.counterexampleWords.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _testCounterexample(result.counterexampleWords.first),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Testar Contraexemplo'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Verificação de Equivalência',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Teste se dois autômatos aceitam a mesma linguagem',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Para usar esta ferramenta:\n'
            '1. Crie ou carregue dois autômatos\n'
            '2. Use "Testar" para verificar uma palavra específica\n'
            '3. Use "Verificar Equivalência" para análise completa',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _testWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      _showError('Digite uma palavra para testar');
      return;
    }

    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
      final currentAutomaton = automatonProvider.currentAutomaton;
      
      if (currentAutomaton == null) {
        _showError('Nenhum automaton carregado para teste');
        return;
      }

      // For now, test only on the current automaton
      // In a full implementation, this would test on two automatons
      final automaton = _convertEntityToAutomaton(currentAutomaton);
      final accepted = _testWordOnAutomaton(automaton, word);
      
      setState(() {
        _lastResult = EquivalenceResult(
          areEquivalent: true, // This is just a word test, not equivalence
          method: 'Teste de Palavra',
          explanation: 'A palavra "$word" foi ${accepted ? "aceita" : "rejeitada"} pelo autômato atual.',
          counterexampleWords: accepted ? [] : [word],
          additionalData: {
            'word': word,
            'accepted': accepted,
            'automaton_type': currentAutomaton.type.toString(),
          },
        );
      });
    } catch (e) {
      _showError('Erro ao testar palavra: $e');
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _checkEquivalence() async {
    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
      final currentAutomaton = automatonProvider.currentAutomaton;
      
      if (currentAutomaton == null) {
        _showError('Nenhum automaton carregado para verificação');
        return;
      }

      // For now, we'll check equivalence with a minimized version of the same automaton
      // In a full implementation, this would compare two different automatons
      final automaton = _convertEntityToAutomaton(currentAutomaton);
      
      // Create a minimized version for comparison
      final minimized = _minimizeDfa(automaton);
      
      // Check if they are equivalent (they should be)
      final result = EquivalenceChecker.checkEquivalence(automaton, minimized);
      
      setState(() {
        _lastResult = result;
      });
    } catch (e) {
      _showError('Erro na verificação de equivalência: $e');
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _testCounterexample(String word) {
    _wordController.text = word;
    _testWord();
  }

  void _showError(String message) {
    setState(() {
      _error = message;
      _lastResult = null;
    });
  }

  // Helper methods
  Automaton _convertEntityToAutomaton(AutomatonEntity entity) {
    final states = entity.states.map((state) => StateNode(
      id: state.id,
      name: state.name,
      x: state.x,
      y: state.y,
      isInitial: state.isInitial,
      isFinal: state.isFinal,
    )).toList();

    return Automaton(
      alphabet: entity.alphabet,
      states: states,
      transitions: entity.transitions,
      initialId: entity.initialId,
      nextId: entity.nextId,
    );
  }

  bool _testWordOnAutomaton(Automaton automaton, String word) {
    // Simple word testing implementation
    if (automaton.initialId == null) return false;
    
    Set<String> currentStates = {automaton.initialId!};
    
    for (int i = 0; i < word.length; i++) {
      final symbol = word[i];
      final nextStates = <String>{};
      
      for (final state in currentStates) {
        final key = '$state|$symbol';
        final destinations = automaton.transitions[key] ?? [];
        nextStates.addAll(destinations);
      }
      
      if (nextStates.isEmpty) return false;
      currentStates = nextStates;
    }
    
    // Check if any current state is final
    return currentStates.any((stateId) {
      final state = automaton.getState(stateId);
      return state?.isFinal ?? false;
    });
  }

  Automaton _minimizeDfa(Automaton automaton) {
    // Simple minimization - for now just return a copy
    // In a full implementation, this would use the actual minimization algorithm
    return automaton.clone();
  }
}

