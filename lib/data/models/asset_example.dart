import '../../core/repositories/automaton_repository.dart';

/// Typed asset example loaded from jflutter_js/examples.
class AssetExample<TPayload> {
  final String name;
  final String description;
  final ExampleCategory category;
  final DifficultyLevel difficultyLevel;
  final ComplexityLevel complexityLevel;
  final List<String> tags;
  final TPayload payload;

  AssetExample({
    required this.name,
    required this.description,
    required this.category,
    required this.difficultyLevel,
    required this.complexityLevel,
    required List<String> tags,
    required this.payload,
  }) : tags = List<String>.unmodifiable(tags);
}

/// Categories of examples.
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
