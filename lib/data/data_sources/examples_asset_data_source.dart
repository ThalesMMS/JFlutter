//
//  examples_asset_data_source.dart
//  JFlutter
//
//  Disponibiliza exemplos enriquecidos a partir de assets, combinando metadados de categoria com validação por tipo de máquina para montar AutomatonDto coerentes.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../converters/asset_example_converters.dart';
import '../models/asset_example.dart';
import '../models/automaton_dto.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/tm.dart';
import '../../core/result.dart';
import '../../core/repositories/automaton_repository.dart';

export '../models/asset_example.dart' show AssetExample, ExampleCategory;

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
          'NFA com ramificação ε para explorar "ab" e transição explícita de "a" para aceitação imediata.',
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
    'APD - Parênteses Balanceados': ExampleMetadata(
      fileName: 'apda_balanced_parentheses.json',
      category: ExampleCategory.pda,
      subcategory: 'Stack Verification',
      difficulty: DifficultyLevel.medium,
      description:
          'Autômato de pilha que reconhece cadeias de parênteses balanceados usando a pilha para rastrear aberturas pendentes.',
      tags: ['pda', 'parentheses', 'balanced', 'stack'],
      estimatedComplexity: ComplexityLevel.medium,
    ),
    'APD - a^n b^n': ExampleMetadata(
      fileName: 'apda_anbn.json',
      category: ExampleCategory.pda,
      subcategory: 'Language Recognition',
      difficulty: DifficultyLevel.hard,
      description:
          'Autômato de pilha que reconhece a linguagem a^n b^n ao empilhar símbolos para cada a e desempilhar para cada b.',
      tags: ['pda', 'anbn', 'stack', 'context-free'],
      estimatedComplexity: ComplexityLevel.high,
    ),
    'APD - Palíndromo': ExampleMetadata(
      fileName: 'apda_palindrome.json',
      category: ExampleCategory.pda,
      subcategory: 'Stack Verification',
      difficulty: DifficultyLevel.hard,
      description:
          'Autômato de pilha não determinístico que empilha a primeira metade da palavra e desempilha a segunda para validar palíndromos.',
      tags: ['pda', 'palindrome', 'stack', 'non-deterministic', 'mirroring'],
      estimatedComplexity: ComplexityLevel.high,
    ),

    // Turing Machine Examples - Computational power
    'MT - a^n b^n': ExampleMetadata(
      fileName: 'tm_anbn.json',
      category: ExampleCategory.tm,
      subcategory: 'Language Recognition',
      difficulty: DifficultyLevel.hard,
      description:
          'Máquina de Turing que reconhece a linguagem a^n b^n marcando pares correspondentes de a e b na fita.',
      tags: ['tm', 'anbn', 'language', 'recognition'],
      estimatedComplexity: ComplexityLevel.high,
    ),
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
    'MT - Cópia de string': ExampleMetadata(
      fileName: 'tm_copy_string.json',
      category: ExampleCategory.tm,
      subcategory: 'Tape Manipulation',
      difficulty: DifficultyLevel.hard,
      description:
          'Máquina de Turing que copia uma string binária para uma nova região da fita.',
      tags: ['tm', 'copy', 'string', 'tape'],
      estimatedComplexity: ComplexityLevel.high,
    ),
    'MT - Incremento binário': ExampleMetadata(
      fileName: 'tm_increment.json',
      category: ExampleCategory.tm,
      subcategory: 'Arithmetic',
      difficulty: DifficultyLevel.medium,
      description:
          'Máquina de Turing que incrementa um número binário em uma unidade.',
      tags: ['tm', 'binary', 'increment', 'arithmetic'],
      estimatedComplexity: ComplexityLevel.medium,
    ),
    'MT - Verificador de palíndromo': ExampleMetadata(
      fileName: 'tm_palindrome.json',
      category: ExampleCategory.tm,
      subcategory: 'String Analysis',
      difficulty: DifficultyLevel.hard,
      description:
          'Máquina de Turing que verifica se uma string binária é um palíndromo.',
      tags: ['tm', 'palindrome', 'binary', 'verification'],
      estimatedComplexity: ComplexityLevel.high,
    ),
  };

  /// Loads all available examples with metadata
  Future<ListResult<ExampleEntity>> loadAllExamples() async {
    try {
      final examples = <ExampleEntity>[];

      for (final entry in _exampleMetadata.entries) {
        final result = await _loadExampleWithMetadata(entry.key, entry.value);
        if (result.isFailure) {
          return Failure(result.error!);
        }
        examples.add(result.data!);
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
    ExampleCategory category,
  ) async {
    try {
      final examples = <ExampleEntity>[];

      for (final entry in _exampleMetadata.entries) {
        if (entry.value.category == category) {
          final result = await _loadExampleWithMetadata(entry.key, entry.value);
          if (result.isFailure) {
            return Failure(result.error!);
          }
          examples.add(result.data!);
        }
      }

      examples.sort(
        (a, b) => a.difficultyLevel.index.compareTo(b.difficultyLevel.index),
      );

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

  Future<Result<AssetExample<FSA>>> loadTypedFsaExample(String name) {
    return _loadTypedExample(
      name,
      {ExampleCategory.dfa, ExampleCategory.nfa},
      convertAssetJsonToFsa,
    );
  }

  Future<Result<AssetExample<Grammar>>> loadTypedCfgExample(String name) {
    return _loadTypedExample(
      name,
      {ExampleCategory.cfg},
      convertAssetJsonToGrammar,
    );
  }

  Future<Result<AssetExample<PDA>>> loadTypedPdaExample(String name) {
    return _loadTypedExample(
      name,
      {ExampleCategory.pda},
      convertAssetJsonToPda,
    );
  }

  Future<Result<AssetExample<TM>>> loadTypedTmExample(String name) {
    return _loadTypedExample(
      name,
      {ExampleCategory.tm},
      convertAssetJsonToTm,
    );
  }

  Future<ListResult<AssetExample<FSA>>> loadAllTypedFsaExamples() {
    return _loadAllTypedExamples(
      {ExampleCategory.dfa, ExampleCategory.nfa},
      loadTypedFsaExample,
    );
  }

  Future<ListResult<AssetExample<Grammar>>> loadAllTypedCfgExamples() {
    return _loadAllTypedExamples(
      {ExampleCategory.cfg},
      loadTypedCfgExample,
    );
  }

  Future<ListResult<AssetExample<PDA>>> loadAllTypedPdaExamples() {
    return _loadAllTypedExamples(
      {ExampleCategory.pda},
      loadTypedPdaExample,
    );
  }

  Future<ListResult<AssetExample<TM>>> loadAllTypedTmExamples() {
    return _loadAllTypedExamples(
      {ExampleCategory.tm},
      loadTypedTmExample,
    );
  }

  Future<ListResult<AssetExample<T>>> _loadAllTypedExamples<T extends Object>(
    Set<ExampleCategory> categories,
    Future<Result<AssetExample<T>>> Function(String name) load,
  ) async {
    final examples = <AssetExample<T>>[];

    for (final entry in _exampleMetadata.entries) {
      if (!categories.contains(entry.value.category)) {
        continue;
      }

      final result = await load(entry.key);
      if (result.isFailure) {
        return Failure(result.error!);
      }
      examples.add(result.data!);
    }

    return Success(examples);
  }

  Future<Result<AssetExample<T>>> _loadTypedExample<T extends Object>(
    String name,
    Set<ExampleCategory> categories,
    Result<T> Function(Map<String, dynamic> json, String exampleName) convert,
  ) async {
    final metadata = _exampleMetadata[name];
    if (metadata == null) {
      return Failure('Example not found: $name');
    }

    if (!categories.contains(metadata.category)) {
      return Failure(
        'Example "$name" belongs to ${metadata.category.displayName}, not ${categories.map((category) => category.displayName).join('/')}',
      );
    }

    final assetPath = 'jflutter_js/examples/${metadata.fileName}';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return Failure(
          'Example $name has invalid JSON structure. Expected an object.',
        );
      }

      final conversionResult = convert(decoded, name);
      if (conversionResult.isFailure) {
        return Failure(conversionResult.error!);
      }

      return Success(
        AssetExample<T>(
          name: name,
          description: metadata.description,
          category: metadata.category,
          difficultyLevel: metadata.difficulty,
          complexityLevel: metadata.estimatedComplexity,
          tags: metadata.tags,
          payload: conversionResult.data!,
        ),
      );
    } on FlutterError catch (e) {
      final message = e.message;
      if (message.contains('Unable to load asset')) {
        return Failure(
          'Example asset not found for $name. Expected at $assetPath',
        );
      }
      return Failure('Error loading example $name: $message');
    } on PlatformException catch (e) {
      final message = e.message ?? e.toString();
      if (message.contains('Unable to load asset')) {
        return Failure(
          'Example asset not found for $name. Expected at $assetPath',
        );
      }
      return Failure('Error loading example $name: $e');
    } on FormatException catch (e) {
      return Failure('Invalid JSON for example $name: ${e.message}');
    } on TypeError catch (e) {
      return Failure('Example $name has invalid data: ${e.toString()}');
    }
  }

  /// Internal method to load example with metadata
  Future<Result<ExampleEntity>> _loadExampleWithMetadata(
    String name,
    ExampleMetadata metadata,
  ) async {
    final assetPath = 'jflutter_js/examples/${metadata.fileName}';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final json = jsonDecode(jsonString);
      if (json is! Map<String, dynamic>) {
        return Failure(
          'Example $name has invalid JSON structure. Expected an object.',
        );
      }

      final conversionResult = _convertExampleJson(
        json,
        metadata,
        exampleName: name,
      );
      if (conversionResult.isFailure) {
        return Failure(conversionResult.error!);
      }

      final automatonDto = conversionResult.data;
      final automaton = automatonDto?.toEntity();

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
    } on FlutterError catch (e) {
      final message = e.message;
      if (message.contains('Unable to load asset')) {
        return Failure(
          'Example asset not found for $name. Expected at $assetPath',
        );
      }
      return Failure('Error loading example $name: $message');
    } on PlatformException catch (e) {
      final message = e.message ?? e.toString();
      if (message.contains('Unable to load asset')) {
        return Failure(
          'Example asset not found for $name. Expected at $assetPath',
        );
      }
      return Failure('Error loading example $name: $e');
    } on FormatException catch (e) {
      return Failure('Invalid JSON for example $name: ${e.message}');
    } on TypeError catch (e) {
      return Failure('Example $name has invalid data: ${e.toString()}');
    }
  }

  /// Converts JSON format to AutomatonDto
  Result<AutomatonDto?> _convertExampleJson(
    Map<String, dynamic> json,
    ExampleMetadata metadata, {
    required String exampleName,
  }) {
    switch (metadata.category) {
      case ExampleCategory.dfa:
      case ExampleCategory.nfa:
        return _convertFiniteAutomaton(json, metadata, exampleName);
      case ExampleCategory.cfg:
        return _validateCfgExample(json, exampleName);
      case ExampleCategory.pda:
        return _validatePdaExample(json, exampleName);
      case ExampleCategory.tm:
        return _validateTmExample(json, exampleName);
    }
  }

  Result<AutomatonDto?> _convertFiniteAutomaton(
    Map<String, dynamic> json,
    ExampleMetadata metadata,
    String exampleName,
  ) {
    final statesResult = _parseStates(
      json['states'],
      exampleName,
      metadata.category,
    );
    if (statesResult.isFailure) {
      return Failure(statesResult.error!);
    }

    final transitionsResult = _parseTransitions(
      json['transitions'],
      exampleName,
      metadata.category,
    );
    if (transitionsResult.isFailure) {
      return Failure(transitionsResult.error!);
    }

    final alphabetResult = _parseStringList(
      json['alphabet'],
      'alphabet',
      exampleName,
      allowEmpty: true,
    );
    if (alphabetResult.isFailure) {
      return Failure(alphabetResult.error!);
    }

    final states = statesResult.data!;
    final transitions = transitionsResult.data!;
    final alphabet = alphabetResult.data!;

    final nextIdRaw = json['nextId'];
    final nextId = nextIdRaw is int
        ? nextIdRaw
        : nextIdRaw is String
            ? int.tryParse(nextIdRaw) ?? states.length
            : states.length;

    final type = (json['type'] as String?) ?? metadata.category.name;

    return Success(
      AutomatonDto(
        id: json['id'] as String? ??
            'example_${exampleName.toLowerCase().replaceAll(' ', '_')}',
        name: json['name'] as String? ?? exampleName,
        alphabet: alphabet,
        states: states,
        transitions: transitions,
        initialId: json['initialId'] as String?,
        nextId: nextId,
        type: type,
      ),
    );
  }

  Result<AutomatonDto?> _validateCfgExample(
    Map<String, dynamic> json,
    String exampleName,
  ) {
    final variablesResult = _parseStringList(
      json['variables'],
      'variables',
      exampleName,
    );
    if (variablesResult.isFailure) {
      return Failure(variablesResult.error!);
    }

    final alphabetResult = _parseStringList(
      json['alphabet'],
      'alphabet',
      exampleName,
      allowEmpty: true,
    );
    if (alphabetResult.isFailure) {
      return Failure(alphabetResult.error!);
    }

    final initialSymbol = json['initialSymbol'];
    if (initialSymbol is! String || initialSymbol.isEmpty) {
      return Failure(
        'Example "$exampleName" must define an "initialSymbol" for CFG data.',
      );
    }

    if (!variablesResult.data!.contains(initialSymbol)) {
      return Failure(
        'Example "$exampleName" references unknown initial symbol "$initialSymbol".',
      );
    }

    final productionsRaw = json['productions'];
    if (productionsRaw is! Map) {
      return Failure(
        'Example "$exampleName" must define "productions" as an object.',
      );
    }

    final productions = Map<String, dynamic>.from(productionsRaw);
    if (productions.isEmpty) {
      return Failure(
        'Example "$exampleName" must include at least one production rule.',
      );
    }

    for (final entry in productions.entries) {
      final alternatives = entry.value;
      if (alternatives is! List) {
        return Failure(
          'Production for non-terminal "${entry.key}" in example "$exampleName" must be a list of strings.',
        );
      }

      final invalid = alternatives.any((option) => option is! String);
      if (invalid) {
        return Failure(
          'Example "$exampleName" contains invalid production values for non-terminal "${entry.key}".',
        );
      }
    }

    return const Success<AutomatonDto?>(null);
  }

  Result<AutomatonDto?> _validatePdaExample(
    Map<String, dynamic> json,
    String exampleName,
  ) {
    final statesResult = _parseStates(
      json['states'],
      exampleName,
      ExampleCategory.pda,
    );
    if (statesResult.isFailure) {
      return Failure(statesResult.error!);
    }

    final transitionsResult = _parseTransitions(
      json['transitions'],
      exampleName,
      ExampleCategory.pda,
    );
    if (transitionsResult.isFailure) {
      return Failure(transitionsResult.error!);
    }

    final stackAlphabetResult = _parseStringList(
      json['stackAlphabet'],
      'stackAlphabet',
      exampleName,
      allowEmpty: false,
    );
    if (stackAlphabetResult.isFailure) {
      return Failure(stackAlphabetResult.error!);
    }

    final initialStack = json['initialStack'];
    if (initialStack is! List || initialStack.isEmpty) {
      return Failure(
        'Example "$exampleName" must define "initialStack" as a non-empty list.',
      );
    }

    final initialId = json['initialId'];
    if (initialId is! String || initialId.isEmpty) {
      return Failure(
        'Example "$exampleName" must define an "initialId" for PDA data.',
      );
    }

    final finalStates = json['finalStates'];
    if (finalStates is! List) {
      return Failure(
        'Example "$exampleName" must define "finalStates" as a list.',
      );
    }

    return const Success<AutomatonDto?>(null);
  }

  Result<AutomatonDto?> _validateTmExample(
    Map<String, dynamic> json,
    String exampleName,
  ) {
    final statesResult = _parseStates(
      json['states'],
      exampleName,
      ExampleCategory.tm,
    );
    if (statesResult.isFailure) {
      return Failure(statesResult.error!);
    }

    final transitionsResult = _parseTransitions(
      json['transitions'],
      exampleName,
      ExampleCategory.tm,
    );
    if (transitionsResult.isFailure) {
      return Failure(transitionsResult.error!);
    }

    final alphabetResult = _parseStringList(
      json['alphabet'],
      'alphabet',
      exampleName,
      allowEmpty: false,
    );
    if (alphabetResult.isFailure) {
      return Failure(alphabetResult.error!);
    }

    final tapeAlphabetResult = _parseStringList(
      json['tapeAlphabet'],
      'tapeAlphabet',
      exampleName,
      allowEmpty: false,
    );
    if (tapeAlphabetResult.isFailure) {
      return Failure(tapeAlphabetResult.error!);
    }

    final initialId = json['initialId'];
    if (initialId is! String || initialId.isEmpty) {
      return Failure(
        'Example "$exampleName" must define an "initialId" for TM data.',
      );
    }

    final finalStates = json['finalStates'];
    if (finalStates is! List) {
      return Failure(
        'Example "$exampleName" must define "finalStates" as a list.',
      );
    }

    return const Success<AutomatonDto?>(null);
  }

  Result<List<StateDto>> _parseStates(
    dynamic statesRaw,
    String exampleName,
    ExampleCategory category,
  ) {
    if (statesRaw == null) {
      return Failure(
        'Example "$exampleName" is missing the "states" section required for ${category.displayName} examples.',
      );
    }

    if (statesRaw is! List) {
      return Failure(
        'Example "$exampleName" has invalid "states" data; expected a list of objects.',
      );
    }

    final states = <StateDto>[];
    for (var i = 0; i < statesRaw.length; i++) {
      final state = statesRaw[i];
      if (state is! Map) {
        return Failure(
          'Example "$exampleName" has an invalid state entry at index $i; expected an object.',
        );
      }
      states.add(StateDto.fromJson(Map<String, dynamic>.from(state)));
    }

    return Success(states);
  }

  Result<Map<String, List<String>>> _parseTransitions(
    dynamic transitionsRaw,
    String exampleName,
    ExampleCategory category,
  ) {
    if (transitionsRaw == null) {
      return Failure(
        'Example "$exampleName" is missing the "transitions" section required for ${category.displayName} examples.',
      );
    }

    if (transitionsRaw is! Map) {
      return Failure(
        'Example "$exampleName" has invalid "transitions" data; expected an object.',
      );
    }

    final transitions = <String, List<String>>{};
    final rawMap = Map<dynamic, dynamic>.from(transitionsRaw);
    for (final entry in rawMap.entries) {
      final key = entry.key;
      if (key is! String) {
        return Failure(
          'Example "$exampleName" has a transition with a non-string key.',
        );
      }

      final value = entry.value;
      if (value is List) {
        transitions[key] = value.map((item) => item.toString()).toList();
      } else if (value == null) {
        transitions[key] = <String>[];
      } else {
        transitions[key] = [value.toString()];
      }
    }

    return Success(transitions);
  }

  Result<List<String>> _parseStringList(
    dynamic raw,
    String fieldName,
    String exampleName, {
    bool allowEmpty = true,
  }) {
    if (raw == null) {
      return const Success(<String>[]);
    }

    if (raw is! List) {
      return Failure(
        'Example "$exampleName" must define "$fieldName" as a list of strings.',
      );
    }

    final list = raw.map((item) => item.toString()).toList();
    if (!allowEmpty && list.isEmpty) {
      return Failure(
        'Example "$exampleName" must define "$fieldName" with at least one entry.',
      );
    }

    return Success(list);
  }

  @visibleForTesting
  Result<AutomatonDto?> convertJsonForTesting(
    Map<String, dynamic> json,
    ExampleMetadata metadata,
    String exampleName,
  ) {
    return _convertExampleJson(json, metadata, exampleName: exampleName);
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
          entry.value.tags.any(
            (tag) => tag.toLowerCase().contains(lowerQuery),
          )) {
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
