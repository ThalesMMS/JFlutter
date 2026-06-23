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

/// Difficulty levels for bundled examples.
enum DifficultyLevel {
  easy('Fácil', 'Conceitos básicos, adequado para iniciantes'),
  medium('Médio', 'Conceitos intermediários, requer algum conhecimento prévio'),
  hard('Difícil', 'Conceitos avançados, recomendado para estudantes avançados');

  const DifficultyLevel(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// Complexity estimation for bundled examples.
enum ComplexityLevel {
  low('Baixa', 'Poucos estados e transições simples'),
  medium('Média', 'Número moderado de estados e transições'),
  high('Alta', 'Muitos estados e transições complexas');

  const ComplexityLevel(this.displayName, this.description);

  final String displayName;
  final String description;
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
