# Data Model: JFlutter Core Reinforcement Initiative

**Date**: 2025-09-29 | **Branch**: `001-projeto-jflutter-refor` | **Status**: Complete

## Executive Summary

Este documento define o modelo de dados unificado para o JFlutter reforçado, estabelecendo entidades imutáveis compartilhadas entre FA, PDA, CFG, TM e Regex. Baseado na arquitetura existente e alinhado às referências em `References/`, o modelo enfatiza imutabilidade (Freezed), tipagem forte e interoperabilidade.

## Core Design Principles

### 1. Shared Types Foundation
- **Tipos unificados** (`Alphabet`, `State`, `Transition`, `Configuration<T>`, `Trace`) como moeda comum
- **Imutabilidade obrigatória** via Freezed para todos os modelos
- **Tipagem estrutural** para alfabetos (entrada, pilha, fita) e configurações específicas

### 2. Trace & Configuration Pattern
- **Configuration<T>**: Estado instantâneo imutável (pilha/fita/cabeça de leitura)
- **Trace**: Sequência imutável de configurações com metadados de execução
- **Time-travel**: Capacidade de navegar traces preservando imutabilidade

### 3. Entity Relationships
```
ExampleArtifact ──┬──> AutomatonEntity
                  ├──> GrammarEntity
                  ├──> RegexEntity
                  └──> TuringMachineEntity

Configuration<T> ───> Trace ───> SimulationResult

Alphabet ───> State ───> Transition ───> AutomatonEntity
```

## Unified Type System

### 1. Alphabet (Base Type)

```dart
@freezed
class Alphabet with _$Alphabet {
  const factory Alphabet({
    required String id,
    required AlphabetType type, // input, stack, tape
    required Set<String> symbols,
    required String? epsilonSymbol,
  }) = _Alphabet;

  // Validações e operações
  bool contains(String symbol);
  bool isValidWord(String word);
  Alphabet union(Alphabet other);
  Alphabet intersection(Alphabet other);
}

enum AlphabetType {
  input('Input'),
  stack('Stack'),
  tape('Tape'),
}
```

### 2. State (Enhanced)

```dart
@freezed
class State with _$State {
  const factory State({
    required String id,
    required String label,
    required Point position,
    required StateType type, // initial, final, accept_by_empty_stack, etc.
  }) = _State;

  // Computed properties
  bool get isInitial;
  bool get isFinal;
  bool get isAcceptByEmptyStack;
}

enum StateType {
  normal,
  initial,
  final,
  acceptByEmptyStack,
  acceptByFinalAndEmpty,
}
```

### 3. Transition (Generic)

```dart
@freezed
class Transition with _$Transition {
  const factory Transition({
    required String id,
    required State source,
    required State target,
    required TransitionLabel label,
  }) = _Transition;

  // Specialized constructors
  factory Transition.fsa({
    required State source,
    required State target,
    required String inputSymbol,
  });

  factory Transition.pda({
    required State source,
    required State target,
    required String inputSymbol,
    required String popSymbol,
    required String pushSymbols,
  });

  factory Transition.tm({
    required State source,
    required State target,
    required String tapeSymbol,
    required String replacement,
    required TapeDirection direction,
  });
}

@freezed
class TransitionLabel with _$TransitionLabel {
  const factory TransitionLabel.epsilon() = TransitionLabelEpsilon;
  const factory TransitionLabel.symbol(String symbol) = TransitionLabelSymbol;
  const factory TransitionLabel.range(String start, String end) = TransitionLabelRange;
}

enum TapeDirection {
  left,
  right,
  stay,
}
```

### 4. Configuration<T> (Generic State)

```dart
@freezed
class Configuration<T> with _$Configuration<T> {
  const factory Configuration({
    required T state, // Current state for each automaton type
    required String remainingInput,
    required StackContents stack,
    required TapeContents tape,
    required int stepNumber,
    required String? usedTransition,
  }) = _Configuration;

  // Specialized constructors
  factory Configuration.fsa({
    required State currentState,
    required String remainingInput,
    required int stepNumber,
    String? usedTransition,
  });

  factory Configuration.pda({
    required State currentState,
    required String remainingInput,
    required StackContents stack,
    required int stepNumber,
    String? usedTransition,
  });

  factory Configuration.tm({
    required State currentState,
    required String remainingInput,
    required TapeContents tape,
    required int stepNumber,
    String? usedTransition,
  });
}

// Stack and Tape specialized types
@freezed
class StackContents with _$StackContents {
  const factory StackContents(List<String> symbols) = _StackContents;
  const factory StackContents.empty() = _StackContentsEmpty;

  String get top => symbols.isEmpty ? '' : symbols.first;
  StackContents pop() => StackContents(symbols.skip(1).toList());
  StackContents push(String symbol) => StackContents([symbol, ...symbols]);
}

@freezed
class TapeContents with _$TapeContents {
  const factory TapeContents({
    required List<String> left,
    required String current,
    required List<String> right,
  }) = _TapeContents;

  String get fullTape => [...left, current, ...right].join();
  TapeContents moveHead(TapeDirection direction);
  TapeContents writeAndMove(String symbol, TapeDirection direction);
}
```

### 5. Trace (Execution History)

```dart
@freezed
class Trace with _$Trace {
  const factory Trace({
    required List<Configuration<dynamic>> configurations,
    required TraceMetadata metadata,
    required Duration executionTime,
    required TraceResult result,
  }) = _Trace;

  // Navigation
  Configuration<dynamic> get initial => configurations.first;
  Configuration<dynamic> get final => configurations.last;
  Configuration<dynamic>? atStep(int step);
  List<Configuration<dynamic>> getBranch(int branchPoint);

  // Analysis
  bool get isSuccessful;
  bool get hasBranches;
  int get totalSteps;
  Set<String> get visitedStates;
}

@freezed
class TraceMetadata with _$TraceMetadata {
  const factory TraceMetadata({
    required String input,
    required String automatonId,
    required AutomatonType automatonType,
    required DateTime timestamp,
  }) = _TraceMetadata;
}

@freezed
class TraceResult with _$TraceResult {
  const factory TraceResult.accepted() = TraceResultAccepted;
  const factory TraceResult.rejected(String reason) = TraceResultRejected;
  const factory TraceResult.timeout(Duration timeout) = TraceResultTimeout;
  const factory TraceResult.error(String message) = TraceResultError;
}
```

## Automaton-Specific Entities

### 6. Finite Automaton (FA)

```dart
@freezed
class FiniteAutomaton with _$FiniteAutomaton {
  const factory FiniteAutomaton.dfa({
    required String id,
    required String name,
    required Alphabet inputAlphabet,
    required List<State> states,
    required List<Transition> transitions,
    required State initialState,
    required Set<State> finalStates,
  }) = FiniteAutomatonDFA;

  const factory FiniteAutomaton.nfa({
    required String id,
    required String name,
    required Alphabet inputAlphabet,
    required List<State> states,
    required List<Transition> transitions,
    required Set<State> initialStates,
    required Set<State> finalStates,
  }) = FiniteAutomatonNFA;

  const factory FiniteAutomaton.nfaLambda({
    required String id,
    required String name,
    required Alphabet inputAlphabet,
    required List<State> states,
    required List<Transition> transitions,
    required Set<State> initialStates,
    required Set<State> finalStates,
  }) = FiniteAutomatonNFALambda;

  // Common properties
  Alphabet get alphabet;
  List<State> get allStates;
  Set<String> get stateIds;
  bool get isDeterministic;
  bool get hasEpsilonTransitions;
}
```

### 7. Pushdown Automaton (PDA)

```dart
@freezed
class PushdownAutomaton with _$PushdownAutomaton {
  const factory PushdownAutomaton.dpda({
    required String id,
    required String name,
    required Alphabet inputAlphabet,
    required Alphabet stackAlphabet,
    required List<State> states,
    required List<Transition> transitions,
    required State initialState,
    required Set<State> finalStates,
    required AcceptanceMode acceptanceMode,
  }) = PushdownAutomatonDPDA;

  const factory PushdownAutomaton.npda({
    required String id,
    required String name,
    required Alphabet inputAlphabet,
    required Alphabet stackAlphabet,
    required List<State> states,
    required List<Transition> transitions,
    required Set<State> initialStates,
    required Set<State> finalStates,
    required AcceptanceMode acceptanceMode,
  }) = PushdownAutomatonNPDA;

  // Properties
  bool get isDeterministic;
  List<String> getEpsilonTransitions;
  AcceptanceMode get acceptanceMode;
}

enum AcceptanceMode {
  finalState('Final State'),
  emptyStack('Empty Stack'),
  both('Both'),
}
```

### 8. Context-Free Grammar (CFG)

```dart
@freezed
class ContextFreeGrammar with _$ContextFreeGrammar {
  const factory ContextFreeGrammar({
    required String id,
    required String name,
    required Set<String> terminals,
    required Set<String> nonTerminals,
    required List<Production> productions,
    required String startSymbol,
  }) = _ContextFreeGrammar;

  // Analysis
  bool get isInChomskyNormalForm;
  bool get hasEpsilonProductions;
  bool get hasUnitProductions;
  bool get hasUselessSymbols;

  // Conversions
  ContextFreeGrammar toChomskyNormalForm();
  PushdownAutomaton toPushdownAutomaton();
}

@freezed
class Production with _$Production {
  const factory Production({
    required String id,
    required String leftHandSide,
    required List<String> rightHandSide,
  }) = _Production;

  bool get isEpsilon => rightHandSide.isEmpty;
  bool get isUnit => rightHandSide.length == 1 && isNonTerminal(rightHandSide.first);
  bool get isTerminal => rightHandSide.length == 1 && isTerminal(rightHandSide.first);
}
```

### 9. Turing Machine (TM)

```dart
@freezed
class TuringMachine with _$TuringMachine {
  const factory TuringMachine.dtm({
    required String id,
    required String name,
    required Alphabet inputAlphabet,
    required Alphabet tapeAlphabet,
    required List<State> states,
    required List<Transition> transitions,
    required State initialState,
    required Set<State> finalStates,
    required Set<State> haltStates,
  }) = TuringMachineDTM;

  const factory TuringMachine.ntm({
    required String id,
    required String name,
    required Alphabet inputAlphabet,
    required Alphabet tapeAlphabet,
    required List<State> states,
    required List<Transition> transitions,
    required Set<State> initialStates,
    required Set<State> finalStates,
    required Set<State> haltStates,
  }) = TuringMachineNTM;

  // Properties
  bool get isDeterministic;
  int get tapeCount; // Always 1 for single-tape
  bool get hasMultiTape; // Always false for single-tape

  // Execution
  Trace simulate(String input);
  List<Trace> simulateAll(String input); // For NTM branching
}

@freezed
class TuringMachineTransition with _$TuringMachineTransition {
  const factory TuringMachineTransition({
    required String id,
    required State source,
    required State target,
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection direction,
  }) = _TuringMachineTransition;
}
```

### 10. Regular Expression (Regex)

```dart
@freezed
class RegexExpression with _$RegexExpression {
  const factory RegexExpression.literal(String value) = RegexLiteral;
  const factory RegexExpression.concatenation(List<RegexExpression> expressions) = RegexConcatenation;
  const factory RegexExpression.alternation(List<RegexExpression> expressions) = RegexAlternation;
  const factory RegexExpression.kleeneStar(RegexExpression expression) = RegexKleeneStar;
  const factory RegexExpression.characterClass(Set<String> characters) = RegexCharacterClass;
  const factory RegexExpression.epsilon() = RegexEpsilon;

  // Conversion
  FiniteAutomaton toNFA();
  String toString(); // For display
  RegexExpression simplify(); // Basic algebraic simplification
}

@freezed
class RegexParseTree with _$RegexParseTree {
  const factory RegexParseTree({
    required RegexExpression root,
    required List<String> tokens,
    required List<ParseError> errors,
  }) = _RegexParseTree;

  bool get isValid => errors.isEmpty;
  RegexExpression get simplified => root.simplify();
}
```

## Supporting Entities

### 11. Example Artifact (Canonical Examples)

```dart
@freezed
class ExampleArtifact with _$ExampleArtifact {
  const factory ExampleArtifact({
    required String id,
    required String name,
    required ArtifactType type,
    required dynamic content, // AutomatonEntity, GrammarEntity, etc.
    required String description,
    required List<String> tags,
    required Map<String, String> metadata,
  }) = _ExampleArtifact;

  // Validation
  bool get isValid;
  List<String> validate();
}

enum ArtifactType {
  finiteAutomaton,
  pushdownAutomaton,
  contextFreeGrammar,
  turingMachine,
  regularExpression,
}
```

### 12. Simulation & Analysis Results

```dart
@freezed
class AnalysisResult with _$AnalysisResult {
  const factory AnalysisResult.success({
    required Map<String, dynamic> properties,
    required Duration executionTime,
  }) = AnalysisResultSuccess;

  const factory AnalysisResult.failure({
    required String error,
    required Duration executionTime,
  }) = AnalysisResultFailure;

  bool get isSuccessful;
  T? getProperty<T>(String key);
}

@freezed
class PropertyAnalysis with _$PropertyAnalysis {
  const factory PropertyAnalysis({
    required String property,
    required bool holds,
    required String explanation,
    required List<String> evidence,
  }) = _PropertyAnalysis;
}
```

## Integration with Existing Models

### Migration Strategy
1. **Extend existing models** com novos campos usando `copyWith`
2. **Add Freezed annotations** gradualmente
3. **Maintain backward compatibility** durante transição
4. **Update JSON serialization** para novos campos

### Key Extensions Needed
- **SimulationResult**: Add trace folding e branch navigation
- **SimulationStep**: Add configuration snapshots
- **AutomatonEntity**: Add unified alphabet e state types
- **GrammarEntity**: Add CNF conversion metadata

## Architecture Alignment

### Layer Responsibilities
- **Domain (lib/core/entities/)**: Pure business entities (Freezed)
- **Models (lib/core/models/)**: DTOs para serialização
- **Algorithms (lib/core/algorithms/)**: Pure functions operando em entidades
- **Services (lib/data/services/)**: Coordenação e orquestração

### State Management Integration
- **Riverpod providers** para traces imutáveis
- **Configuration<T>** como estado compartilhado
- **Trace folding** para navegação eficiente

---

*Data model designed for immutability, type safety, and reference alignment.*
