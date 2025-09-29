import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/automaton_model.dart';
import '../../core/result.dart';
import '../../core/repositories/automaton_repository.dart';

/// Enhanced data source for loading example automatons from assets (Examples v1)
class ExamplesAssetDataSource {
  static const Map<String, ExampleMetadata> _exampleMetadata = {
    // DFA Examples - Basic Concepts
    'AFD - Termina com A': ExampleMetadata(
      fileName: 'afd_ends_with_a.json',
      category: ExampleCategory.dfa,
      subcategory: 'Basic Patterns',
      difficulty: DifficultyLevel.easy,
      description:
          'DFA que reconhece palavras terminando com "a". Demonstra conceitos básicos de estados finais.',
      tags: ['dfa', 'basic', 'patterns', 'ending'],
      estimatedComplexity: ComplexityLevel.low,
    ),
    'AFD - Binário divisível por 3': ExampleMetadata(
      fileName: 'afd_binary_divisible_by_3.json',
      category: ExampleCategory.dfa,
      subcategory: 'Number Theory',
      difficulty: DifficultyLevel.medium,
      description:
          'DFA que reconhece números binários divisíveis por 3. Usa aritmética modular.',
      tags: ['dfa', 'modular', 'binary', 'division'],
      estimatedComplexity: ComplexityLevel.medium,
    ),
    'AFD - Paridade AB': ExampleMetadata(
      fileName: 'afd_parity_AB.json',
      category: ExampleCategory.dfa,
      subcategory: 'Counting',
      difficulty: DifficultyLevel.medium,
      description:
          'DFA que verifica se há número par de "a"s e "b"s. Demonstra contagem simultânea.',
      tags: ['dfa', 'parity', 'counting', 'multiple-counters'],
      estimatedComplexity: ComplexityLevel.medium,
    ),

    // NFA Examples - Non-deterministic concepts
    'AFNλ - A ou AB': ExampleMetadata(
      fileName: 'afn_lambda_a_or_ab.json',
      category: ExampleCategory.nfa,
      subcategory: 'Epsilon Transitions',
      difficulty: DifficultyLevel.medium,
      description:
          'NFA com transições ε que reconhece "a" ou "ab". Introduz não-determinismo.',
      tags: ['nfa', 'epsilon', 'choice', 'non-deterministic'],
      estimatedComplexity: ComplexityLevel.medium,
    ),

    // Grammar Examples - Context-Free concepts
    'GLC - Palíndromo': ExampleMetadata(
      fileName: 'glc_palindrome.json',
      category: ExampleCategory.cfg,
      subcategory: 'Recursive Structures',
      difficulty: DifficultyLevel.hard,
      description:
          'Gramática livre de contexto para palíndromos. Demonstra recursão.',
      tags: ['cfg', 'palindrome', 'recursion', 'context-free'],
      estimatedComplexity: ComplexityLevel.high,
    ),
    'GLC - Parênteses balanceados': ExampleMetadata(
      fileName: 'glc_balanced_parentheses.json',
      category: ExampleCategory.cfg,
      subcategory: 'Stack Simulation',
      difficulty: DifficultyLevel.medium,
      description:
          'GLC que gera strings de parênteses balanceados. Simula comportamento de pilha.',
      tags: ['cfg', 'parentheses', 'balanced', 'stack'],
      estimatedComplexity: ComplexityLevel.medium,
    ),

    // PDA Examples - Pushdown concepts
    'APD - Palíndromo': ExampleMetadata(
      fileName: 'apda_palindrome.json',
      category: ExampleCategory.pda,
      subcategory: 'Stack Verification',
      difficulty: DifficultyLevel.hard,
      description:
          'Autômato de pilha que reconhece palíndromos. Usa pilha para verificar simetria.',
      tags: ['pda', 'palindrome', 'stack', 'verification'],
      estimatedComplexity: ComplexityLevel.high,
    ),

    // Turing Machine Examples - Computational power
    'MT - Binário para unário': ExampleMetadata(
      fileName: 'tm_binary_to_unary.json',
      category: ExampleCategory.tm,
      subcategory: 'Number Conversion',
      difficulty: DifficultyLevel.hard,
      description:
          'Máquina de Turing que converte números binários para unários.',
      tags: ['tm', 'conversion', 'binary', 'unary'],
      estimatedComplexity: ComplexityLevel.high,
    ),
  };

  /// Loads all available examples with metadata
  Future<ListResult<ExampleEntity>> loadAllExamples() async {
    try {
      final examples = <ExampleEntity>[];

      for (final entry in _exampleMetadata.entries) {
        final result = await _loadExampleWithMetadata(entry.key, entry.value);
        result.onSuccess((example) => examples.add(example));
      }

      // Sort examples by category and difficulty for better organization
      examples.sort((a, b) {
        final categoryCompare = a.category.compareTo(b.category);
        if (categoryCompare != 0) return categoryCompare;
        return a.difficultyLevel.index.compareTo(b.difficultyLevel.index);
      });

      return Success(examples);
    } catch (e) {
      return Failure('Error loading examples: $e');
    }
  }

  /// Loads examples filtered by category
  Future<ListResult<ExampleEntity>> loadExamplesByCategory(
      ExampleCategory category) async {
    try {
      final examples = <ExampleEntity>[];

      for (final entry in _exampleMetadata.entries) {
        if (entry.value.category == category) {
          final result = await _loadExampleWithMetadata(entry.key, entry.value);
          result.onSuccess((example) => examples.add(example));
        }
      }

      examples.sort(
          (a, b) => a.difficultyLevel.index.compareTo(b.difficultyLevel.index));

      return Success(examples);
    } catch (e) {
      return Failure('Error loading examples for category $category: $e');
    }
  }

  /// Loads a specific example by name with full metadata
  Future<Result<ExampleEntity>> loadExample(String name) async {
    final metadata = _exampleMetadata[name];
    if (metadata == null) {
      return Failure('Example not found: $name');
    }

    return _loadExampleWithMetadata(name, metadata);
  }

  /// Internal method to load example with metadata
  Future<Result<ExampleEntity>> _loadExampleWithMetadata(
      String name, ExampleMetadata metadata) async {
    final assetPath = 'jflutter_js/examples/${metadata.fileName}';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Convert JSON format to automaton model
      final automatonModel = _convertJsonToAutomatonModel(json, name);
      final automaton = automatonModel.toEntity();

      final example = ExampleEntity(
        name: name,
        description: metadata.description,
        category: metadata.category.displayName,
        subcategory: metadata.subcategory,
        difficultyLevel: metadata.difficulty,
        tags: metadata.tags,
        estimatedComplexity: metadata.estimatedComplexity,
        automaton: automaton,
      );

      return Success(example);
    } on PlatformException catch (e) {
      final message = e.message ?? e.toString();
      if (message.contains('Unable to load asset')) {
        return Failure(
          'Example asset not found for $name. Expected at $assetPath',
        );
      }
      return Failure('Error loading example $name: $e');
    }
  }

  /// Converts JSON format to AutomatonModel
  AutomatonModel _convertJsonToAutomatonModel(
      Map<String, dynamic> json, String exampleName) {
    final states = (json['states'] as List)
        .map((s) => StateModel.fromJson(s as Map<String, dynamic>))
        .toList();

    final transitions = <String, List<String>>{};
    if (json['transitions'] != null) {
      final transData = json['transitions'] as Map<String, dynamic>;
      for (final entry in transData.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is List) {
          transitions[key] = List<String>.from(value);
        } else {
          transitions[key] = [value.toString()];
        }
      }
    }

    final type = json['type'] as String? ?? 'dfa';

    return AutomatonModel(
      id: json['id'] as String? ??
          'example_${exampleName.toLowerCase().replaceAll(' ', '_')}',
      name: json['name'] as String? ?? exampleName,
      alphabet: List<String>.from(json['alphabet'] ?? []),
      states: states,
      transitions: transitions,
      initialId: json['initialId'] as String?,
      nextId: json['nextId'] as int? ?? states.length,
      type: type,
    );
  }

  /// Gets all available categories
  List<ExampleCategory> getAvailableCategories() {
    return ExampleCategory.values;
  }

  /// Gets examples count by category
  Map<ExampleCategory, int> getExamplesCountByCategory() {
    final counts = <ExampleCategory, int>{};
    for (final category in ExampleCategory.values) {
      counts[category] = _exampleMetadata.values
          .where((meta) => meta.category == category)
          .length;
    }
    return counts;
  }

  /// Search examples by tags or description
  List<String> searchExamples(String query) {
    final results = <String>[];
    final lowerQuery = query.toLowerCase();

    for (final entry in _exampleMetadata.entries) {
      if (entry.key.toLowerCase().contains(lowerQuery) ||
          entry.value.description.toLowerCase().contains(lowerQuery) ||
          entry.value.tags
              .any((tag) => tag.toLowerCase().contains(lowerQuery))) {
        results.add(entry.key);
      }
    }

    return results;
  }
}

/// Metadata for an example
class ExampleMetadata {
  final String fileName;
  final ExampleCategory category;
  final String subcategory;
  final DifficultyLevel difficulty;
  final String description;
  final List<String> tags;
  final ComplexityLevel estimatedComplexity;

  const ExampleMetadata({
    required this.fileName,
    required this.category,
    required this.subcategory,
    required this.difficulty,
    required this.description,
    required this.tags,
    required this.estimatedComplexity,
  });
}

/// Categories of examples
enum ExampleCategory {
  dfa('DFA', 'Deterministic Finite Automaton'),
  nfa('NFA', 'Nondeterministic Finite Automaton'),
  cfg('CFG', 'Context-Free Grammar'),
  pda('PDA', 'Pushdown Automaton'),
  tm('TM', 'Turing Machine');

  const ExampleCategory(this.displayName, this.fullName);

  final String displayName;
  final String fullName;
}
