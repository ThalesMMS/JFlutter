# Examples v1 Contract: JFlutter Core Reinforcement Initiative

**Date**: 2025-09-29 | **Branch**: `001-projeto-jflutter-refor` | **Status**: Complete

## Executive Summary

Este documento define o contrato para a biblioteca "Examples v1" - coleção canônica de artefatos de teoria da computação para validação ground-truth, testes de regressão e aprendizado. Estabelece estrutura, curadoria e distribuição offline.

## Core Principles

### 1. Canonical Authority
- **Referência oficial** para algoritmos e estruturas
- **Ground-truth** para validação on-device
- **Curadoria rigorosa** baseada em referências acadêmicas

### 2. Offline-First Design
- **Asset embarcado** (read-only durante execução)
- **Atualização por releases** (não downloads dinâmicos)
- **Tamanho otimizado** para distribuição mobile

### 3. Pedagogical Structure
- **Dificuldade progressiva** (básico → avançado)
- **Categorias temáticas** (teoria de linguagens, processamento, etc.)
- **Casos de teste abrangentes** para cada exemplo

## Library Structure

### 1. Asset Organization

```
assets/examples_v1/
├── index.json              # Catálogo principal
├── finite_automata/
│   ├── binary_divisible_by_3.json
│   ├── ends_with_a.json
│   └── parity_checker.json
├── pushdown_automata/
│   ├── balanced_parentheses.json
│   └── palindrome_checker.json
├── context_free_grammars/
│   ├── arithmetic_expressions.json
│   └── palindrome_grammar.json
├── turing_machines/
│   ├── binary_increment.json
│   └── busy_beaver.json
└── regular_expressions/
    ├── email_pattern.json
    └── url_pattern.json
```

### 2. Index Format

```json
{
  "libraryVersion": "1.0.0",
  "metadata": {
    "name": "Examples v1",
    "description": "Canonical automata theory examples for JFlutter",
    "license": "Apache-2.0 + JFLAP 7.1 attribution",
    "created": "2025-09-29T10:00:00Z",
    "totalArtifacts": 47,
    "categories": {
      "finite_automata": 12,
      "pushdown_automata": 8,
      "context_free_grammars": 10,
      "turing_machines": 9,
      "regular_expressions": 8
    }
  },
  "artifacts": [
    {
      "id": "binary_divisible_by_3",
      "name": "Binary Strings Divisible by 3",
      "type": "finite_automaton",
      "subtype": "dfa",
      "category": "number_theory",
      "difficulty": "intermediate",
      "filePath": "finite_automata/binary_divisible_by_3.json",
      "fileSize": 2847,
      "checksum": "sha256:abc123...",
      "reference": {
        "source": "automata-main",
        "path": "examples/binary_divisible_by_3.py",
        "verified": true,
        "lastChecked": "2025-09-29T10:00:00Z"
      },
      "testCases": [
        {
          "input": "0",
          "expected": true,
          "description": "Empty string is divisible by 3"
        },
        {
          "input": "11",
          "expected": true,
          "description": "3 in binary (11₂ = 3₁₀)"
        },
        {
          "input": "10",
          "expected": false,
          "description": "2 in binary (10₂ = 2₁₀)"
        }
      ],
      "educationalNotes": {
        "concept": "Modular arithmetic in automata",
        "keyInsight": "States represent remainder modulo 3",
        "commonMistakes": ["Confusing binary and decimal"]
      }
    }
  ]
}
```

## Artifact Categories

### 1. Finite Automata (12 artifacts)

#### Basic Language Recognition
- **Empty Language**: ∅ (DFA/NFA)
- **Single Symbol**: {a} (DFA)
- **All Strings**: Σ* (NFA-λ)
- **No Strings Ending in a**: (a|b)*b (DFA)

#### Pattern Recognition
- **Binary Divisible by 3**: {w | w ∈ {0,1}* ∧ w₂ ≡ 0 mod 3}
- **Parity Checker**: {w | |w|_1 even}
- **Ends with ab**: (a|b)*ab
- **Contains aba**: Complex NFA

#### Number Theory
- **Divisible by n**: General modulo automata
- **Prime Recognition**: Complex automata (demonstration)
- **Fibonacci Strings**: Fibonacci word patterns

#### String Processing
- **Palindrome Detection**: aba^R a (NFA)
- **Substring Search**: Contains pattern (NFA)

### 2. Pushdown Automata (8 artifacts)

#### Basic Stack Operations
- **Balanced Parentheses**: (), (()), ()() with proper nesting
- **Multiple Bracket Types**: (), [], {} matching
- **Arithmetic Expressions**: Operator precedence

#### Language Palindromes
- **Odd-Length Palindromes**: Stack-based reversal
- **Even-Length Palindromes**: Two-stack approach

#### Context-Free Patterns
- **a^n b^n**: Classic CFL not regular
- **Dyck Words**: Balanced parentheses variants
- **Arithmetic with Variables**: Expression evaluation

### 3. Context-Free Grammars (10 artifacts)

#### Chomsky Hierarchy Demonstrations
- **Regular Grammar**: Right-linear, generates regular language
- **Context-Free Grammar**: Classic examples
- **Context-Sensitive Grammar**: a^n b^n c^n (demonstration)

#### Expression Grammars
- **Arithmetic Expressions**: +, *, parentheses
- **Logical Expressions**: ∧, ∨, ¬ with precedence
- **Programming Languages**: Mini-language parsers

#### Natural Language Patterns
- **Palindrome Sentences**: Sentence-level palindromes
- **Nested Structures**: Recursive structures

#### Grammar Transformations
- **CNF Conversion**: Examples before/after conversion
- **Useless Removal**: Demonstrating cleanup algorithms

### 4. Turing Machines (9 artifacts)

#### Basic Computation
- **Binary Increment**: Adds 1 to binary number
- **String Reversal**: Reverses input string
- **Palindrome Recognition**: TM equivalent of PDA

#### Universal Computation
- **Busy Beaver**: Maximal activity machines
- **Collatz Conjecture**: 3n+1 computation
- **Prime Generation**: Generates primes (slow)

#### Multi-Tape Demonstrations
- **Tape Sorting**: Sorts symbols on tape
- **Language Intersection**: Intersection of two languages
- **Universal TM**: Interprets other TMs

### 5. Regular Expressions (8 artifacts)

#### Pattern Matching
- **Email Addresses**: RFC-compliant patterns
- **URLs**: Web address recognition
- **Phone Numbers**: International formats
- **Postal Codes**: Country-specific patterns

#### Text Processing
- **HTML Tags**: Tag matching with nesting
- **CSV Parser**: Comma-separated values
- **Log Parser**: Structured log analysis

#### Advanced Patterns
- **Balanced Tags**: XML/HTML tag matching
- **Mathematical Expressions**: Formula parsing

## Artifact Content Structure

### 1. Finite Automaton Artifact

```json
{
  "id": "binary_divisible_by_3",
  "name": "Binary Strings Divisible by 3",
  "type": "finite_automaton",
  "subtype": "dfa",
  "category": "number_theory",
  "difficulty": "intermediate",
  "description": "DFA that accepts binary strings representing numbers divisible by 3",
  "content": {
    "alphabet": {
      "type": "input",
      "symbols": ["0", "1"]
    },
    "states": [
      {
        "id": "q0",
        "label": "0 mod 3",
        "type": "initial|final",
        "position": {"x": 100, "y": 100}
      },
      {
        "id": "q1",
        "label": "1 mod 3",
        "type": "normal",
        "position": {"x": 200, "y": 100}
      },
      {
        "id": "q2",
        "label": "2 mod 3",
        "type": "normal",
        "position": {"x": 300, "y": 100}
      }
    ],
    "transitions": [
      {
        "id": "t1",
        "source": "q0",
        "target": "q0",
        "label": {"type": "symbol", "value": "0"}
      },
      {
        "id": "t2",
        "source": "q0",
        "target": "q1",
        "label": {"type": "symbol", "value": "1"}
      }
      // ... more transitions
    ]
  },
  "testCases": [
    {
      "input": "",
      "expected": true,
      "description": "Empty string (0) is divisible by 3"
    },
    {
      "input": "0",
      "expected": true,
      "description": "0 in binary is divisible by 3"
    },
    {
      "input": "11",
      "expected": true,
      "description": "3 in binary (11₂ = 3₁₀) is divisible by 3"
    },
    {
      "input": "10",
      "expected": false,
      "description": "2 in binary (10₂ = 2₁₀) is not divisible by 3"
    }
  ],
  "properties": {
    "isMinimal": true,
    "stateCount": 3,
    "transitionCount": 6,
    "languageSize": "infinite",
    "isEmpty": false,
    "isFinite": false
  }
}
```

### 2. Pushdown Automaton Artifact

```json
{
  "id": "balanced_parentheses",
  "name": "Balanced Parentheses",
  "type": "pushdown_automaton",
  "subtype": "dpda",
  "category": "context_free_languages",
  "difficulty": "beginner",
  "description": "PDA that accepts balanced parentheses strings",
  "content": {
    "alphabets": {
      "input": ["(", ")"],
      "stack": ["(", "Z"]
    },
    "states": [
      {
        "id": "q0",
        "label": "Start",
        "type": "initial",
        "position": {"x": 100, "y": 100}
      },
      {
        "id": "q1",
        "label": "Accept",
        "type": "final",
        "position": {"x": 200, "y": 100}
      }
    ],
    "transitions": [
      {
        "id": "t1",
        "source": "q0",
        "target": "q0",
        "inputSymbol": "(",
        "popSymbol": "Z",
        "pushSymbols": ["(", "Z"]
      },
      {
        "id": "t2",
        "source": "q0",
        "target": "q0",
        "inputSymbol": "(",
        "popSymbol": "(",
        "pushSymbols": ["(", "("]
      },
      {
        "id": "t3",
        "source": "q0",
        "target": "q1",
        "inputSymbol": ")",
        "popSymbol": "(",
        "pushSymbols": []
      }
    ],
    "acceptanceMode": "empty_stack"
  }
}
```

### 3. Context-Free Grammar Artifact

```json
{
  "id": "arithmetic_expressions",
  "name": "Arithmetic Expressions",
  "type": "context_free_grammar",
  "category": "expression_parsing",
  "difficulty": "intermediate",
  "description": "Grammar for arithmetic expressions with +, *, parentheses",
  "content": {
    "terminals": ["+", "*", "(", ")", "id"],
    "nonTerminals": ["E", "T", "F"],
    "productions": [
      {
        "id": "p1",
        "left": ["E"],
        "right": ["E", "+", "T"]
      },
      {
        "id": "p2",
        "left": ["E"],
        "right": ["T"]
      },
      {
        "id": "p3",
        "left": ["T"],
        "right": ["T", "*", "F"]
      },
      {
        "id": "p4",
        "left": ["T"],
        "right": ["F"]
      },
      {
        "id": "p5",
        "left": ["F"],
        "right": ["(", "E", ")"]
      },
      {
        "id": "p6",
        "left": ["F"],
        "right": ["id"]
      }
    ],
    "startSymbol": "E",
    "isInChomskyNormalForm": false,
    "hasEpsilonProductions": false,
    "hasUnitProductions": false,
    "hasUselessSymbols": false
  }
}
```

## Quality Assurance

### 1. Reference Verification

Cada artefato deve ser verificado contra implementação de referência:

```dart
class ReferenceVerification {
  final String referenceSource; // "automata-main", "petitparser", etc.
  final String referencePath;   // Path within reference
  final bool verified;          // Verification status
  final DateTime lastChecked;   // Last verification timestamp
  final Map<String, dynamic> verificationResults;

  // Verification process
  Future<bool> verifyAgainstReference() async {
    // 1. Load reference implementation
    // 2. Run equivalent computation
    // 3. Compare results
    // 4. Update verification status
  }
}
```

### 2. Test Case Coverage

Cada artefato deve incluir casos de teste abrangentes:

- **Casos básicos**: Entradas mínimas válidas/inválidas
- **Casos extremos**: Strings vazias, símbolos únicos, repetição máxima
- **Casos de borda**: Transições ε, estados finais, loops infinitos
- **Casos de erro**: Entradas inválidas, estados inalcançáveis

### 3. Educational Metadata

Cada artefato deve incluir contexto educacional:

```json
{
  "educationalNotes": {
    "concept": "Primary concept demonstrated",
    "keyInsight": "Main takeaway for students",
    "commonMistakes": [
      "Frequent student errors",
      "Conceptual pitfalls"
    ],
    "relatedTopics": [
      "Prerequisite topics",
      "Follow-up concepts"
    ],
    "difficulty": "beginner|intermediate|advanced",
    "estimatedTime": "5-10 minutes",
    "prerequisites": ["Basic automata", "Modular arithmetic"]
  }
}
```

## Distribution & Updates

### 1. Asset Packaging

```dart
class ExamplesAssetManager {
  // Load index
  Future<ExamplesIndex> loadIndex() async {
    final json = await rootBundle.loadString('assets/examples_v1/index.json');
    return ExamplesIndex.fromJson(jsonDecode(json));
  }

  // Load specific artifact
  Future<ExampleArtifact> loadArtifact(String artifactId) async {
    final index = await loadIndex();
    final artifact = index.getArtifact(artifactId);
    final json = await rootBundle.loadString(artifact.filePath);
    return ExampleArtifact.fromJson(jsonDecode(json));
  }

  // Verify integrity
  Future<bool> verifyIntegrity() async {
    // Check file sizes, checksums, reference verification
  }
}
```

### 2. Version Management

```dart
class ExamplesVersionManager {
  static const String currentVersion = '1.0.0';

  Future<bool> isUpdateAvailable() async {
    // Check against remote version (if online)
    // Return false for offline-first design
  }

  Future<void> updateExamples() async {
    // Download and verify new version
    // Atomic replacement of assets
    // Rollback on verification failure
  }
}
```

## Implementation Guidelines

### 1. Asset Generation Pipeline

```dart
class ExamplesGenerationPipeline {
  Future<void> generateAllArtifacts() async {
    // 1. Create artifacts from reference implementations
    // 2. Generate comprehensive test cases
    // 3. Add educational metadata
    // 4. Verify against references
    // 5. Optimize for size and performance
    // 6. Generate index
  }

  Future<void> verifyArtifact(ExampleArtifact artifact) async {
    // 1. Load reference implementation
    // 2. Test all test cases
    // 3. Verify properties
    // 4. Check educational metadata
  }
}
```

### 2. Loading Strategy

```dart
class ExamplesLoader {
  static const String _assetPath = 'assets/examples_v1/';

  Future<ExamplesIndex> loadIndex() async {
    final jsonString = await rootBundle.loadString('${_assetPath}index.json');
    return ExamplesIndex.fromJson(jsonDecode(jsonString));
  }

  Future<ExampleArtifact> loadArtifact(String artifactId) async {
    final index = await loadIndex();
    final artifact = index.artifacts.firstWhere((a) => a.id == artifactId);
    final jsonString = await rootBundle.loadString('${_assetPath}${artifact.filePath}');
    return ExampleArtifact.fromJson(jsonDecode(jsonString));
  }
}
```

### 3. Performance Optimization

```dart
class ExamplesOptimizer {
  Future<void> optimizeAssets() async {
    // 1. Compress JSON (remove whitespace)
    // 2. Generate binary format for large artifacts
    // 3. Create search index for fast lookup
    // 4. Bundle related artifacts together
  }

  Future<LoadTimeMetrics> measureLoadTimes() async {
    // Measure loading performance on target devices
    // Ensure < 100ms for index, < 50ms per artifact
  }
}
```

## Testing & Validation

### 1. Integration Tests

```dart
void testExamplesIntegration() {
  test('All artifacts load correctly', () async {
    final index = await examplesLoader.loadIndex();
    expect(index.artifacts.length, greaterThan(0));

    for (final artifact in index.artifacts) {
      final loaded = await examplesLoader.loadArtifact(artifact.id);
      expect(loaded.isValid, isTrue);
    }
  });

  test('Ground-truth verification', () async {
    final artifact = await examplesLoader.loadArtifact('binary_divisible_by_3');

    for (final testCase in artifact.testCases) {
      final result = await runDFA(artifact.content, testCase.input);
      expect(result.accepted, equals(testCase.expected));
    }
  });
}
```

### 2. Performance Benchmarks

```dart
void testExamplesPerformance() {
  test('Index loads in < 100ms', () async {
    final stopwatch = Stopwatch()..start();
    await examplesLoader.loadIndex();
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
  });

  test('Artifacts load in < 50ms', () async {
    final index = await examplesLoader.loadIndex();

    for (final artifact in index.artifacts.take(5)) {
      final stopwatch = Stopwatch()..start();
      await examplesLoader.loadArtifact(artifact.id);
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    }
  });
}
```

---

*Examples v1 contract established for canonical reference library with comprehensive test coverage and educational metadata.*
