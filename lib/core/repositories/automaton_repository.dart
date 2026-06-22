//
//  automaton_repository.dart
//  JFlutter
//
//  Declara contratos de repositório responsáveis por persistir autômatos e
//  mantém tipos compartilhados de metadados dos exemplos embarcados.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import '../entities/automaton_entity.dart';
import '../result.dart';

/// Repository interface for automaton operations
/// This defines the contract that all automaton repositories must implement
abstract class AutomatonRepository {
  /// Saves an automaton
  Future<AutomatonResult> saveAutomaton(AutomatonEntity automaton);

  /// Loads an automaton by ID
  Future<AutomatonResult> loadAutomaton(String id);

  /// Loads all saved automatons
  Future<ListResult<AutomatonEntity>> loadAllAutomatons();

  /// Deletes an automaton by ID
  Future<BoolResult> deleteAutomaton(String id);

  /// Exports an automaton to JSON string
  Future<StringResult> exportAutomaton(AutomatonEntity automaton);

  /// Imports an automaton from JSON string
  Future<AutomatonResult> importAutomaton(String jsonString);

  /// Validates an automaton
  Future<BoolResult> validateAutomaton(AutomatonEntity automaton);
}

/// Enhanced example entity with metadata for Examples v1
class ExampleEntity {
  final String name;
  final String description;
  final String category;
  final String subcategory;
  final DifficultyLevel difficultyLevel;
  final List<String> tags;
  final ComplexityLevel estimatedComplexity;
  final AutomatonEntity? automaton;

  const ExampleEntity({
    required this.name,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.difficultyLevel,
    required this.tags,
    required this.estimatedComplexity,
    this.automaton,
  });
}

/// Difficulty levels for examples
enum DifficultyLevel {
  easy('Fácil', 'Conceitos básicos, adequado para iniciantes'),
  medium('Médio', 'Conceitos intermediários, requer algum conhecimento prévio'),
  hard('Difícil', 'Conceitos avançados, recomendado para estudantes avançados');

  const DifficultyLevel(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// Complexity estimation for examples
enum ComplexityLevel {
  low('Baixa', 'Poucos estados e transições simples'),
  medium('Média', 'Número moderado de estados e transições'),
  high('Alta', 'Muitos estados e transições complexas');

  const ComplexityLevel(this.displayName, this.description);

  final String displayName;
  final String description;
}
