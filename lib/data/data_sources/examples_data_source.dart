import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/automaton_model.dart';
import '../../core/result.dart';
import '../../core/repositories/automaton_repository.dart';

/// Data source for loading example automatons from assets
class ExamplesDataSource {
  static const Map<String, String> _exampleFiles = {
    'AFD - Termina com A': 'afd_ends_with_a.json',
    'AFD - Binário divisível por 3': 'afd_binary_divisible_by_3.json',
    'AFD - Paridade AB': 'afd_parity_AB.json',
    'AFNλ - A ou AB': 'afn_lambda_a_or_ab.json',
  };

  /// Loads all available examples
  Future<ListResult<ExampleEntity>> loadExamples() async {
    try {
      final examples = <ExampleEntity>[];

      for (final entry in _exampleFiles.entries) {
        final result = await loadExample(entry.key);
        result.onSuccess((example) => examples.add(example));
      }

      return Success(examples);
    } catch (e) {
      return Failure('Error loading examples: $e');
    }
  }

  /// Loads a specific example by name
  Future<Result<ExampleEntity>> loadExample(String name) async {
    final fileName = _exampleFiles[name];
    if (fileName == null) {
      return Failure('Example not found: $name');
    }

    final assetPath = 'jflutter_js/examples/$fileName';

    try {

      final jsonString = await rootBundle.loadString(assetPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Convert legacy format to new format
      final automatonModel = _convertLegacyFormat(json);
      final automaton = automatonModel.toEntity();

      final example = ExampleEntity(
        name: name,
        description: _getDescription(name),
        category: _getCategory(name),
        automaton: automaton,
      );

      return Success(example);
    } on FlutterError catch (e) {
      final message = e.message ?? e.toString();
      if (message.contains('Unable to load asset')) {
        return Failure(
          'Example asset not found for $name. Expected at $assetPath',
        );
      }
      return Failure('Error loading example $name: $message');
    } catch (e) {
      return Failure('Error loading example $name: $e');
    }
  }

  /// Converts legacy automaton format to new format
  AutomatonModel _convertLegacyFormat(Map<String, dynamic> json) {
    // Legacy format conversion logic
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Example Automaton',
      alphabet: List<String>.from(json['alphabet'] ?? []),
      states: states,
      transitions: transitions,
      initialId: json['initialId'] as String?,
      nextId: json['nextId'] as int? ?? states.length,
      type: type,
    );
  }

  /// Gets description for an example
  String _getDescription(String name) {
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

  /// Gets category for an example
  String _getCategory(String name) {
    if (name.startsWith('AFD')) return 'AFD';
    if (name.startsWith('AFN')) return 'AFN';
    return 'Outros';
  }
}
