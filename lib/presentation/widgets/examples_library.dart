import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/entities/automaton_entity.dart';
import '../../data/models/automaton_model.dart';
import '../providers/automaton_provider.dart';
import 'contextual_help.dart';

/// Interactive examples library for educational purposes
/// Provides a collection of pre-built automatons and grammars for learning
class ExamplesLibrary extends StatefulWidget {
  const ExamplesLibrary({super.key});

  @override
  State<ExamplesLibrary> createState() => _ExamplesLibraryState();
}

class _ExamplesLibraryState extends State<ExamplesLibrary> {
  String _selectedCategory = 'DFA';
  String _searchQuery = '';
  ExampleItem? _selectedExample;

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
                Text(
                  'Biblioteca de Exemplos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                ContextualHelp(
                  helpContent: HelpContent.examplesLibrary,
                  title: 'Biblioteca de Exemplos',
                  icon: Icons.library_books,
                  child: Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search and filter
            _buildSearchAndFilter(),
            const SizedBox(height: 16),
            
            // Main content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use responsive layout based on screen width
                  if (constraints.maxWidth < 800) {
                    // Mobile layout: Stack panels vertically
                    return Column(
                      children: [
                        // Examples list
                        Expanded(
                          flex: 1,
                          child: _buildExamplesList(),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Example details
                        Expanded(
                          flex: 1,
                          child: _buildExampleDetails(),
                        ),
                      ],
                    );
                  } else {
                    // Desktop layout: Side by side panels
                    return Row(
                      children: [
                        // Left panel - Examples list
                        Expanded(
                          flex: 1,
                          child: _buildExamplesList(),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Right panel - Example details
                        Expanded(
                          flex: 1,
                          child: _buildExampleDetails(),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        // Search field
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar exemplos',
              hintText: 'Ex: paridade, divisível, etc.',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Category filter
        DropdownButton<String>(
          value: _selectedCategory,
          items: const [
            DropdownMenuItem(value: 'DFA', child: Text('DFA')),
            DropdownMenuItem(value: 'NFA', child: Text('NFA')),
            DropdownMenuItem(value: 'Grammar', child: Text('Gramática')),
            DropdownMenuItem(value: 'CFG', child: Text('CFG')),
            DropdownMenuItem(value: 'PDA', child: Text('PDA')),
            DropdownMenuItem(value: 'Turing', child: Text('Turing')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
                _selectedExample = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildExamplesList() {
    final examples = _getFilteredExamples();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exemplos ($_selectedCategory)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: examples.length,
                itemBuilder: (context, index) {
                  final example = examples[index];
                  final isSelected = _selectedExample == example;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      leading: Icon(
                        _getCategoryIcon(example.category),
                        color: isSelected 
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        example.title,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        example.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                              : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (example.difficulty != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(example.difficulty!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                example.difficulty!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedExample = example;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleDetails() {
    if (_selectedExample == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecione um exemplo para ver os detalhes',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(_selectedExample!.category),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedExample!.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_selectedExample!.difficulty != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(_selectedExample!.difficulty!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedExample!.difficulty!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Descrição',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedExample!.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            if (_selectedExample!.concepts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Conceitos Envolvidos',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedExample!.concepts.map((concept) => Chip(
                  label: Text(concept),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                )).toList(),
              ),
            ],
            
            if (_selectedExample!.learningObjectives.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Objetivos de Aprendizado',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ..._selectedExample!.learningObjectives.map((objective) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        objective,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            const Spacer(),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _loadExample(_selectedExample!),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Carregar Exemplo'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showExampleInfo(_selectedExample!),
                  icon: const Icon(Icons.info),
                  label: const Text('Mais Info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<ExampleItem> _getFilteredExamples() {
    final allExamples = _getAllExamples();
    
    return allExamples.where((example) {
      final matchesCategory = example.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || 
          example.title.toLowerCase().contains(_searchQuery) ||
          example.description.toLowerCase().contains(_searchQuery) ||
          example.concepts.any((concept) => concept.toLowerCase().contains(_searchQuery));
      
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<ExampleItem> _getAllExamples() {
    return [
      // DFA Examples
      ExampleItem(
        title: 'Paridade de A e B',
        description: 'DFA que aceita strings com número par de A\'s e B\'s',
        category: 'DFA',
        difficulty: 'Fácil',
        concepts: ['Estados', 'Transições', 'Estados finais'],
        learningObjectives: [
          'Entender como contar símbolos em um DFA',
          'Aprender a usar estados para rastrear paridade',
          'Praticar construção de DFA simples',
        ],
        automatonData: _getParityAutomatonData(),
      ),
      
      ExampleItem(
        title: 'Divisível por 3 (Binário)',
        description: 'DFA que aceita números binários divisíveis por 3',
        category: 'DFA',
        difficulty: 'Médio',
        concepts: ['Aritmética modular', 'Estados de resto', 'Processamento de bits'],
        learningObjectives: [
          'Aprender aritmética modular em autômatos',
          'Entender como processar números em diferentes bases',
          'Praticar construção de DFA com múltiplos estados',
        ],
        automatonData: _getDivisibleBy3AutomatonData(),
      ),
      
      ExampleItem(
        title: 'Termina com "ab"',
        description: 'DFA que aceita strings que terminam com "ab"',
        category: 'DFA',
        difficulty: 'Fácil',
        concepts: ['Padrões de sufixo', 'Estados de memória'],
        learningObjectives: [
          'Entender como reconhecer padrões de sufixo',
          'Aprender a usar estados para lembrar caracteres anteriores',
        ],
        automatonData: _getEndsWithAbAutomatonData(),
      ),
      
      // NFA Examples
      ExampleItem(
        title: 'a* ou b*',
        description: 'NFA que aceita strings de apenas a\'s ou apenas b\'s',
        category: 'NFA',
        difficulty: 'Fácil',
        concepts: ['Não-determinismo', 'Múltiplas transições', 'Transições ε'],
        learningObjectives: [
          'Entender o conceito de não-determinismo',
          'Aprender a usar transições ε',
          'Comparar NFA com DFA',
        ],
        automatonData: _getAStarOrBStarAutomatonData(),
      ),
      
      // Grammar Examples
      ExampleItem(
        title: 'a^n b^n',
        description: 'Gramática que gera strings com igual número de a\'s e b\'s',
        category: 'Grammar',
        difficulty: 'Médio',
        concepts: ['Gramáticas regulares', 'Produções', 'Recursão'],
        learningObjectives: [
          'Entender gramáticas regulares',
          'Aprender a usar produções recursivas',
          'Praticar conversão de gramática para autômato',
        ],
        automatonData: _getAnBnGrammarData(),
      ),
      
      // CFG Examples
      ExampleItem(
        title: 'Palíndromos',
        description: 'CFG que gera palíndromos sobre {a, b}',
        category: 'CFG',
        difficulty: 'Médio',
        concepts: ['Gramáticas livres de contexto', 'Recursão central', 'Simetria'],
        learningObjectives: [
          'Entender gramáticas livres de contexto',
          'Aprender recursão central',
          'Praticar construção de CFG',
        ],
        automatonData: _getPalindromeCFGData(),
      ),
      
      ExampleItem(
        title: 'a^n b^n c^n',
        description: 'CFG que gera strings com igual número de a\'s, b\'s e c\'s',
        category: 'CFG',
        difficulty: 'Difícil',
        concepts: ['Gramáticas livres de contexto', 'Contagem múltipla', 'Recursão'],
        learningObjectives: [
          'Entender limitações de CFG',
          'Aprender técnicas avançadas de construção',
          'Praticar análise de linguagens complexas',
        ],
        automatonData: _getAnBnCnCFGData(),
      ),
    ];
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'DFA':
        return Icons.account_tree;
      case 'NFA':
        return Icons.account_tree_outlined;
      case 'Grammar':
        return Icons.text_fields;
      case 'CFG':
        return Icons.code;
      case 'PDA':
        return Icons.storage;
      case 'Turing':
        return Icons.memory;
      default:
        return Icons.help_outline;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Fácil':
        return Colors.green;
      case 'Médio':
        return Colors.orange;
      case 'Difícil':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _loadExample(ExampleItem example) {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    
    // Convert example data to AutomatonEntity
    final model = AutomatonModel.fromJson(example.automatonData);
    final automaton = model.toEntity();
    automatonProvider.setAutomaton(automaton);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exemplo "${example.title}" carregado com sucesso!'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showExampleInfo(ExampleItem example) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(example.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Descrição:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(example.description),
              const SizedBox(height: 16),
              
              if (example.concepts.isNotEmpty) ...[
                Text(
                  'Conceitos:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(example.concepts.join(', ')),
                const SizedBox(height: 16),
              ],
              
              if (example.learningObjectives.isNotEmpty) ...[
                Text(
                  'Objetivos:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                ...example.learningObjectives.map((objective) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $objective'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadExample(example);
            },
            child: const Text('Carregar'),
          ),
        ],
      ),
    );
  }

  // Example data generators
  Map<String, dynamic> _getParityAutomatonData() {
    return {
      'type': 'dfa',
      'alphabet': ['a', 'b'],
      'states': [
        {'id': 'q0', 'name': 'q0', 'x': 100, 'y': 100, 'isFinal': true},
        {'id': 'q1', 'name': 'q1', 'x': 200, 'y': 100, 'isFinal': false},
        {'id': 'q2', 'name': 'q2', 'x': 100, 'y': 200, 'isFinal': false},
        {'id': 'q3', 'name': 'q3', 'x': 200, 'y': 200, 'isFinal': false},
      ],
      'transitions': {
        'q0|a': ['q1'],
        'q0|b': ['q2'],
        'q1|a': ['q0'],
        'q1|b': ['q3'],
        'q2|a': ['q3'],
        'q2|b': ['q0'],
        'q3|a': ['q2'],
        'q3|b': ['q1'],
      },
      'initialId': 'q0',
      'nextId': 4,
    };
  }

  Map<String, dynamic> _getDivisibleBy3AutomatonData() {
    return {
      'type': 'dfa',
      'alphabet': ['0', '1'],
      'states': [
        {'id': 'q0', 'name': 'q0', 'x': 100, 'y': 100, 'isFinal': true},
        {'id': 'q1', 'name': 'q1', 'x': 200, 'y': 100, 'isFinal': false},
        {'id': 'q2', 'name': 'q2', 'x': 300, 'y': 100, 'isFinal': false},
      ],
      'transitions': {
        'q0|0': ['q0'],
        'q0|1': ['q1'],
        'q1|0': ['q2'],
        'q1|1': ['q0'],
        'q2|0': ['q1'],
        'q2|1': ['q2'],
      },
      'initialId': 'q0',
      'nextId': 3,
    };
  }

  Map<String, dynamic> _getEndsWithAbAutomatonData() {
    return {
      'type': 'dfa',
      'alphabet': ['a', 'b'],
      'states': [
        {'id': 'q0', 'name': 'q0', 'x': 100, 'y': 100, 'isFinal': false},
        {'id': 'q1', 'name': 'q1', 'x': 200, 'y': 100, 'isFinal': false},
        {'id': 'q2', 'name': 'q2', 'x': 300, 'y': 100, 'isFinal': true},
      ],
      'transitions': {
        'q0|a': ['q1'],
        'q0|b': ['q0'],
        'q1|a': ['q1'],
        'q1|b': ['q2'],
        'q2|a': ['q1'],
        'q2|b': ['q0'],
      },
      'initialId': 'q0',
      'nextId': 3,
    };
  }

  Map<String, dynamic> _getAStarOrBStarAutomatonData() {
    return {
      'type': 'nfa',
      'alphabet': ['a', 'b'],
      'states': [
        {'id': 'q0', 'name': 'q0', 'x': 100, 'y': 100, 'isFinal': true},
        {'id': 'q1', 'name': 'q1', 'x': 200, 'y': 100, 'isFinal': true},
        {'id': 'q2', 'name': 'q2', 'x': 100, 'y': 200, 'isFinal': true},
      ],
      'transitions': {
        'q0|λ': ['q1', 'q2'],
        'q1|a': ['q1'],
        'q2|b': ['q2'],
      },
      'initialId': 'q0',
      'nextId': 3,
    };
  }

  Map<String, dynamic> _getAnBnGrammarData() {
    return {
      'type': 'grammar',
      'alphabet': ['a', 'b'],
      'productions': [
        {'left': 'S', 'right': 'aSb'},
        {'left': 'S', 'right': 'ab'},
      ],
      'startSymbol': 'S',
    };
  }

  Map<String, dynamic> _getPalindromeCFGData() {
    return {
      'type': 'cfg',
      'alphabet': ['a', 'b'],
      'productions': [
        {'left': 'S', 'right': 'aSa'},
        {'left': 'S', 'right': 'bSb'},
        {'left': 'S', 'right': 'a'},
        {'left': 'S', 'right': 'b'},
        {'left': 'S', 'right': 'λ'},
      ],
      'startSymbol': 'S',
    };
  }

  Map<String, dynamic> _getAnBnCnCFGData() {
    return {
      'type': 'cfg',
      'alphabet': ['a', 'b', 'c'],
      'productions': [
        {'left': 'S', 'right': 'aSbC'},
        {'left': 'S', 'right': 'abC'},
        {'left': 'Cb', 'right': 'bC'},
        {'left': 'C', 'right': 'c'},
      ],
      'startSymbol': 'S',
    };
  }
}

/// Example item data structure
class ExampleItem {
  final String title;
  final String description;
  final String category;
  final String? difficulty;
  final List<String> concepts;
  final List<String> learningObjectives;
  final Map<String, dynamic> automatonData;

  ExampleItem({
    required this.title,
    required this.description,
    required this.category,
    this.difficulty,
    required this.concepts,
    required this.learningObjectives,
    required this.automatonData,
  });
}

/// Help content for examples library
class ExamplesLibraryHelpContent {
  static const String examplesLibrary = '''
Biblioteca de Exemplos

Esta biblioteca contém uma coleção de exemplos educativos para aprender teoria dos autômatos e linguagens formais.

Como usar:
1. Selecione uma categoria (DFA, NFA, Gramática, etc.)
2. Use a busca para encontrar exemplos específicos
3. Clique em um exemplo para ver os detalhes
4. Use "Carregar Exemplo" para abrir no canvas
5. Use "Mais Info" para ver informações detalhadas

Os exemplos incluem:
• Dificuldade (Fácil, Médio, Difícil)
• Conceitos envolvidos
• Objetivos de aprendizado
• Dados prontos para uso

Perfeito para estudantes e educadores!
''';
}
