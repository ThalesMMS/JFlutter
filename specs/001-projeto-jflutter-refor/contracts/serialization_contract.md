# Serialization Contract: JFlutter Core Reinforcement Initiative

**Date**: 2025-09-29 | **Branch**: `001-projeto-jflutter-refor` | **Status**: Complete

## Executive Summary

Este documento estabelece os contratos de serialização para interoperabilidade completa entre JFlutter e formatos externos (`.jff`, JSON, SVG). Define padrões estáveis para round-trip, validação e transformação entre formatos.

## Core Principles

### 1. Stability & Versioning
- **Version-aware**: Todos os formatos incluem versão para compatibilidade futura
- **Lossless round-trip**: Transformações preservam semântica completa
- **Error recovery**: Validação robusta com mensagens acionáveis

### 2. Format Hierarchy
```
Internal JSON ──┬──> JFLAP XML (.jff)
                ├──> SVG (Visualization)
                └──> Canonical JSON (Examples v1)
```

### 3. Validation Strategy
- **Schema validation** para todos os formatos
- **Semantic validation** além da estrutura
- **Ground-truth verification** contra referências

## 1. JFLAP XML Format Contract (.jff)

### Structure Definition

```xml
<?xml version="1.0" encoding="UTF-8"?>
<structure type="[fa|pda|tm]">
  <automaton>
    <!-- States -->
    <state id="[string]" name="[string]">
      <initial/> <!-- Optional -->
      <final/>   <!-- Optional -->
      <label x="[double]" y="[double]"/> <!-- Optional -->
    </state>

    <!-- Transitions -->
    <transition>
      <from>[state_id]</from>
      <to>[state_id]</to>
      <read>[symbol]</read>
      <pop>[symbol]</pop>    <!-- PDA only -->
      <push>[symbols]</push> <!-- PDA only -->
    </transition>

    <!-- Turing Machine specific -->
    <tape>
      <left>[symbols]</left>
      <current>[symbol]</current>
      <right>[symbols]</right>
    </tape>
  </automaton>
</structure>
```

### Supported Automaton Types

| Type | Description | Transitions | States |
|------|-------------|-------------|--------|
| `fa` | Finite Automaton | `<from>`, `<to>`, `<read>` | `<initial>`, `<final>` |
| `pda` | Pushdown Automaton | `<from>`, `<to>`, `<read>`, `<pop>`, `<push>` | `<initial>`, `<final>` |
| `tm` | Turing Machine | `<from>`, `<to>`, `<read>`, `<write>`, `<direction>` | `<initial>`, `<final>`, `<halt>` |

### Validation Rules

#### Structural Validation
- ✅ XML válido com encoding UTF-8
- ✅ Elemento raiz `<structure>` com atributo `type`
- ✅ Pelo menos um elemento `<state>`
- ✅ Pelo menos uma transição (exceto para autômatos vazios)
- ✅ Estados referenciados em transições devem existir
- ✅ Estado inicial único (exceto para NFA/TM)
- ✅ Símbolos consistentes com alfabetos declarados

#### Semantic Validation
- ✅ DFA: Determinístico (no máximo uma transição por símbolo por estado)
- ✅ PDA: Stack alphabet separado do input alphabet
- ✅ TM: Tape alphabet inclui blank symbol
- ✅ Estados finais distintos de iniciais (convenção)
- ✅ Transições ε válidas (λ ou vazio)

### Round-trip Requirements

#### Export (JFlutter → .jff)
```dart
Future<String> exportToJflap({
  required AutomatonEntity automaton,
  required SerializationOptions options,
}) async {
  // 1. Convert unified model to JFLAP XML
  // 2. Apply formatting options
  // 3. Include metadata (version, timestamp)
  // 4. Validate output before returning
}
```

#### Import (.jff → JFlutter)
```dart
Future<Result<AutomatonEntity>> importFromJflap({
  required String jflapXml,
  required ImportOptions options,
}) async {
  // 1. Parse and validate XML structure
  // 2. Convert to unified model
  // 3. Validate semantic correctness
  // 4. Generate stable IDs if missing
  // 5. Return with error details on failure
}
```

## 2. Internal JSON Format Contract

### Canonical Structure

```json
{
  "formatVersion": "1.0.0",
  "metadata": {
    "id": "unique-identifier",
    "name": "Human readable name",
    "type": "dfa|nfa|nfa_lambda|pda|cfg|tm|regex",
    "description": "Optional description",
    "tags": ["category1", "category2"],
    "created": "2025-09-29T10:00:00Z",
    "modified": "2025-09-29T10:00:00Z",
    "version": 1
  },
  "content": {
    // Automaton-specific content
  },
  "visualization": {
    "layout": "force_directed|hierarchical|circular",
    "theme": "light|dark|auto",
    "positions": {
      "state_id": {"x": 100.0, "y": 200.0}
    }
  }
}
```

### Automaton-Specific Schemas

#### Finite Automaton (FA)
```json
{
  "content": {
    "alphabet": {
      "input": ["a", "b", "c"],
      "type": "input|stack|tape"
    },
    "states": [
      {
        "id": "q0",
        "label": "q0",
        "type": "initial|final|normal|accept_by_empty_stack",
        "position": {"x": 100.0, "y": 100.0}
      }
    ],
    "transitions": [
      {
        "id": "t1",
        "source": "q0",
        "target": "q1",
        "label": {
          "type": "symbol|epsilon|range",
          "value": "a"
        }
      }
    ],
    "initialState": "q0",
    "finalStates": ["q1"]
  }
}
```

#### Pushdown Automaton (PDA)
```json
{
  "content": {
    "alphabets": {
      "input": ["a", "b"],
      "stack": ["A", "B", "Z"]
    },
    "states": [/* same as FA */],
    "transitions": [
      {
        "id": "t1",
        "source": "q0",
        "target": "q1",
        "inputSymbol": "a",
        "popSymbol": "A",
        "pushSymbols": ["B", "A"]
      }
    ],
    "initialState": "q0",
    "finalStates": ["q1"],
    "acceptanceMode": "final_state|empty_stack|both"
  }
}
```

#### Context-Free Grammar (CFG)
```json
{
  "content": {
    "terminals": ["a", "b", "c"],
    "nonTerminals": ["S", "A", "B"],
    "productions": [
      {
        "id": "p1",
        "left": ["S"],
        "right": ["a", "A", "b"]
      },
      {
        "id": "p2",
        "left": ["A"],
        "right": [] // epsilon
      }
    ],
    "startSymbol": "S"
  }
}
```

#### Turing Machine (TM)
```json
{
  "content": {
    "alphabets": {
      "input": ["a", "b"],
      "tape": ["a", "b", "_"] // includes blank
    },
    "states": [/* same as FA */],
    "transitions": [
      {
        "id": "t1",
        "source": "q0",
        "target": "q1",
        "readSymbol": "a",
        "writeSymbol": "b",
        "direction": "left|right|stay"
      }
    ],
    "initialState": "q0",
    "finalStates": ["q1"],
    "haltStates": ["qhalt"],
    "tapeCount": 1
  }
}
```

#### Regular Expression (Regex)
```json
{
  "content": {
    "expression": {
      "type": "concatenation|alternation|kleene_star|literal|character_class|epsilon",
      "value": "a*b|c",
      "children": [/* recursive structure */]
    },
    "alphabet": ["a", "b", "c"]
  }
}
```

### Validation Rules

#### JSON Schema Validation
- ✅ Valid JSON syntax
- ✅ Required fields presentes
- ✅ Type constraints respeitados
- ✅ Reference integrity (estados existem, símbolos válidos)

#### Semantic Validation
- ✅ Estados iniciais únicos (exceto NFA/TM)
- ✅ Transições válidas para o tipo de autômato
- ✅ Alfabetos consistentes com símbolos usados
- ✅ Gramáticas livres de contexto válidas (sem símbolos não terminais na direita de produções terminais)

## 3. SVG Export Contract

### Structure Definition

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg width="[width]" height="[height]" viewBox="0 0 [width] [height]">
  <defs>
    <!-- Styles and markers -->
    <style>
      .state { fill: [color]; stroke: [color]; }
      .transition { stroke: [color]; fill: none; }
      .initial { fill: none; stroke: [color]; stroke-dasharray: 5,5; }
      .final { fill: none; stroke: [color]; stroke-width: 2; }
    </style>
  </defs>

  <!-- States -->
  <g class="states">
    <circle class="state [type]" cx="[x]" cy="[y]" r="[radius]">
      <title>[state_label]</title>
    </circle>
    <!-- Labels -->
    <text x="[x]" y="[y+radius+15]" text-anchor="middle">[label]</text>
  </g>

  <!-- Transitions -->
  <g class="transitions">
    <path class="transition" d="[svg_path]">
      <title>[transition_label]</title>
    </path>
    <!-- Arrow markers -->
    <polygon points="[arrow_points]"/>
    <!-- Labels -->
    <text x="[midpoint_x]" y="[midpoint_y]">[label]</text>
  </g>

  <!-- Metadata -->
  <metadata>
    <jflutter version="[version]" type="[automaton_type]" exported="[timestamp]"/>
  </metadata>
</svg>
```

### Visualization Options

#### Layout Algorithms
- **force_directed**: Física-based positioning (default)
- **hierarchical**: Top-down layout
- **circular**: Circular arrangement
- **grid**: Grid-based positioning

#### Styling Themes
- **light**: White background, dark elements
- **dark**: Dark background, light elements
- **auto**: System theme detection

#### Export Parameters
```dart
@freezed
class SvgExportOptions with _$SvgExportOptions {
  const factory SvgExportOptions({
    required int width,
    required int height,
    required LayoutAlgorithm layout,
    required ThemeMode theme,
    required bool includeLabels,
    required bool includeTransitionLabels,
    required double scale,
  }) = _SvgExportOptions;
}
```

### Quality Requirements

#### Visual Fidelity
- ✅ Estados claramente distintos (formas, cores)
- ✅ Transições legíveis com setas direcionais
- ✅ Labels posicionados sem sobreposição
- ✅ Cores acessíveis (contraste WCAG AA)

#### Performance
- ✅ Renderização < 100ms para autômatos médios (< 50 estados)
- ✅ Arquivo SVG < 1MB para visualizações típicas
- ✅ Compatibilidade com browsers modernos

## 4. Canonical Examples Format (Examples v1)

### Structure Definition

```json
{
  "libraryVersion": "1.0.0",
  "metadata": {
    "name": "Examples v1",
    "description": "Canonical automata theory examples",
    "license": "Apache-2.0 + JFLAP attribution",
    "created": "2025-09-29T10:00:00Z"
  },
  "artifacts": [
    {
      "id": "binary_divisible_by_3",
      "name": "Binary Divisible by 3",
      "type": "dfa",
      "category": "number_theory",
      "difficulty": "intermediate",
      "description": "DFA that accepts binary strings divisible by 3",
      "content": { /* Full automaton JSON */ },
      "reference": {
        "source": "automata-main",
        "path": "examples/binary_divisible_by_3.json",
        "verified": true
      }
    }
  ]
}
```

### Artifact Categories

| Category | Description | Examples |
|----------|-------------|----------|
| `language_theory` | Basic language recognition | a*b*, palindromes |
| `number_theory` | Numeric pattern recognition | divisible by n |
| `string_processing` | String manipulation | ends with, contains |
| `grammar_transformations` | CFG to PDA conversions | balanced parentheses |
| `turing_completeness` | Universal computation | busy beaver |

### Validation Requirements

#### Structural
- ✅ Cada artefato tem ID único global
- ✅ Tipo corresponde ao conteúdo
- ✅ Referências externas verificáveis

#### Semantic
- ✅ Autômatos funcionam corretamente para casos de teste
- ✅ Gramáticas geram linguagens esperadas
- ✅ TM computam funções corretas

## Implementation Guidelines

### 1. Serialization Service Architecture

```dart
abstract class SerializationService {
  // Core serialization
  Future<String> serializeToJflap(AutomatonEntity automaton);
  Future<Result<AutomatonEntity>> deserializeFromJflap(String jflapXml);

  Future<String> serializeToJson(AutomatonEntity automaton);
  Future<Result<AutomatonEntity>> deserializeFromJson(String json);

  Future<String> serializeToSvg(AutomatonEntity automaton, SvgExportOptions options);

  // Validation
  Future<List<ValidationError>> validateJflap(String jflapXml);
  Future<List<ValidationError>> validateJson(String json);
  Future<List<ValidationError>> validateSvg(String svg);

  // Round-trip testing
  Future<bool> testRoundTrip(AutomatonEntity original);
}
```

### 2. Error Handling Strategy

```dart
@freezed
class ValidationError with _$ValidationError {
  const factory ValidationError({
    required ErrorSeverity severity,
    required String code,
    required String message,
    required String location,
    required Map<String, dynamic> context,
  }) = _ValidationError;
}

enum ErrorSeverity {
  warning,
  error,
  critical,
}
```

### 3. Version Management

```dart
class SerializationVersion {
  static const String current = '1.0.0';
  static const String jflap = '7.1'; // JFLAP 7.1 compatibility
  static const String json = '1.0.0';
  static const String svg = '1.0.0';
  static const String examples = '1.0.0';
}
```

## Testing Strategy

### 1. Round-trip Tests

```dart
void testJflapRoundTrip() {
  final original = createTestDFA();

  // Export to JFLAP
  final jflapXml = await serializationService.serializeToJflap(original);

  // Import back
  final result = await serializationService.deserializeFromJflap(jflapXml);
  final imported = result.getOrThrow();

  // Verify equivalence
  expect(imported, equalsAutomaton(original));
}
```

### 2. Format Compatibility Tests

```dart
void testFormatCompatibility() {
  // Test against reference implementations
  final referenceOutput = referenceLibrary.generateJflap(testDFA);
  final jflutterOutput = await serializationService.serializeToJflap(testDFA);

  expect(jflutterOutput, isValidJflapXml());
  expect(semanticallyEquivalent(jflutterOutput, referenceOutput), isTrue);
}
```

### 3. Performance Tests

```dart
void testSerializationPerformance() {
  final largeAutomaton = createLargeAutomaton(1000);

  final stopwatch = Stopwatch()..start();

  await serializationService.serializeToJflap(largeAutomaton);

  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
}
```

## Migration Strategy

### 1. Backward Compatibility
- ✅ Manter formatos existentes durante transição
- ✅ Suporte gradual para novos campos obrigatórios
- ✅ Deprecation warnings para campos obsoletos

### 2. Data Migration
- ✅ Scripts para migrar dados existentes
- ✅ Validação automática durante import
- ✅ Rollback automático em caso de falha

---

*Serialization contracts established for stable interoperability and future extensibility.*
