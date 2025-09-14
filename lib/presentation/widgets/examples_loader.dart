import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/result.dart';

class ExampleAutomaton {
  ExampleAutomaton({
    required this.name,
    required this.description,
    required this.category,
    required this.automaton,
  });

  final String name;
  final String description;
  final String category;
  final AutomatonEntity automaton;
}

class ExamplesLoader {
  static const Map<String, String> _exampleFiles = {
    'AFD - Termina com A': 'afd_ends_with_a.json',
    'AFD - Binário divisível por 3': 'afd_binary_divisible_by_3.json',
    'AFD - Paridade AB': 'afd_parity_AB.json',
    'AFNλ - A ou AB': 'afn_lambda_a_or_ab.json',
  };

  static Future<Result<List<ExampleAutomaton>>> loadExamples() async {
    final examples = <ExampleAutomaton>[];

    for (final entry in _exampleFiles.entries) {
      try {
        final jsonString = await rootBundle.loadString('jflutter_js/examples/${entry.value}');
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        
        // Convert to AutomatonEntity (this would need proper conversion logic)
        final automaton = _convertToAutomatonEntity(jsonData);
        
        examples.add(ExampleAutomaton(
          name: entry.key,
          description: _getDescription(entry.key),
          category: _getCategory(entry.key),
          automaton: automaton,
        ));
      } catch (e) {
        // Skip examples that fail to load
        continue;
      }
    }

    return Success(examples);
  }
  
  /// Converts JSON data to AutomatonEntity
  /// This is a simplified conversion - in a real implementation,
  /// you'd want a proper converter
  static AutomatonEntity _convertToAutomatonEntity(Map<String, dynamic> json) {
    // This is a placeholder - you'd need to implement proper conversion
    // from the old Automaton format to AutomatonEntity
    return AutomatonEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Example',
      alphabet: (json['alphabet'] as List?)?.map((e) => e.toString()).toSet() ?? {},
      states: [],
      transitions: {},
      nextId: 0,
      type: AutomatonType.dfa,
    );
  }

  static String _getDescription(String name) {
    switch (name) {
      case 'AFD - Termina com A':
        return 'Reconhece palavras que terminam com a letra A';
      case 'AFD - Binário divisível por 3':
        return 'Reconhece números binários divisíveis por 3';
      case 'AFD - Paridade AB':
        return 'Reconhece palavras com número par de A e B';
      case 'AFNλ - A ou AB':
        return 'Reconhece a palavra "a" ou "ab" usando AFNλ';
      default:
        return 'Exemplo de automaton';
    }
  }

  static String _getCategory(String name) {
    if (name.startsWith('AFD')) return 'AFD';
    if (name.startsWith('AFN')) return 'AFN';
    return 'Outros';
  }
}

class ExamplesLoaderWidget extends StatefulWidget {
  const ExamplesLoaderWidget({
    super.key,
    this.onExampleSelected,
  });

  final void Function(ExampleAutomaton)? onExampleSelected;

  @override
  State<ExamplesLoaderWidget> createState() => _ExamplesLoaderWidgetState();
}

class _ExamplesLoaderWidgetState extends State<ExamplesLoaderWidget> {
  List<ExampleAutomaton> _examples = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExamples();
  }

  Future<void> _loadExamples() async {
    try {
      final examples = await ExamplesLoader.loadExamples();
      setState(() {
        _examples = examples;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exemplos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Column(
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erro ao carregar exemplos: $_error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  for (final category in _getCategories())
                    _buildCategorySection(context, category),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<String> _getCategories() {
    return _examples
        .map((e) => e.category)
        .toSet()
        .toList()
      ..sort();
  }

  Widget _buildCategorySection(BuildContext context, String category) {
    final categoryExamples = _examples
        .where((e) => e.category == category)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        for (final example in categoryExamples)
          _buildExampleTile(context, example),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExampleTile(BuildContext context, ExampleAutomaton example) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(example.name),
        subtitle: Text(example.description),
        trailing: ElevatedButton(
          onPressed: () {
            if (widget.onExampleSelected != null) {
              widget.onExampleSelected!(example);
            }
          },
          child: const Text('Carregar'),
        ),
        onTap: () {
          if (widget.onExampleSelected != null) {
            widget.onExampleSelected!(example);
          }
        },
      ),
    );
  }
}

class ExamplesDropdown extends StatefulWidget {
  const ExamplesDropdown({
    super.key,
    this.onExampleSelected,
  });

  final void Function(ExampleAutomaton)? onExampleSelected;

  @override
  State<ExamplesDropdown> createState() => _ExamplesDropdownState();
}

class _ExamplesDropdownState extends State<ExamplesDropdown> {
  List<ExampleAutomaton> _examples = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExamples();
  }

  Future<void> _loadExamples() async {
    try {
      final examples = await ExamplesLoader.loadExamples();
      setState(() {
        _examples = examples;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exemplos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Text(
                'Erro ao carregar exemplos',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ExampleAutomaton>(
                      decoration: const InputDecoration(
                        labelText: 'Escolha um exemplo...',
                        border: OutlineInputBorder(),
                      ),
                      items: _examples.map((example) {
                        return DropdownMenuItem<ExampleAutomaton>(
                          value: example,
                          child: Text(example.name),
                        );
                      }).toList(),
                      onChanged: (example) {
                        if (example != null && widget.onExampleSelected != null) {
                          widget.onExampleSelected!(example);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // This will be handled by the dropdown onChanged
                    },
                    child: const Text('Carregar'),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              'Carrega um AF/AFD de exemplos prontos desta biblioteca.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
