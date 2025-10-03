# JFlutter API Documentation

## Overview

JFlutter provides a comprehensive API for working with formal language theory concepts including finite automata, context-free grammars, and various algorithms. This documentation covers the core APIs, data models, and integration patterns.

> **Nota importante**: durante a reescrita dos algoritmos, cada contrato descrito aqui é conferido contra os projetos que vivem em `References/` (principalmente as bases em Dart e o repositório Python `automata-main`). Essas referências balizam as alterações até que novos testes automatizados estejam disponíveis.

## Core Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│        Presentation Layer           │
│  (UI Components, Pages, Providers)  │
├─────────────────────────────────────┤
│         Core Layer                  │
│  (Algorithms, Models, Business)     │
├─────────────────────────────────────┤
│          Data Layer                 │
│  (Services, Repositories, Storage)  │
└─────────────────────────────────────┘
```

## Core Models

### FSA (Finite State Automaton)

```dart
class FSA extends Automaton {
  final Set<State> states;
  final Set<String> alphabet;
  final State initialState;
  final Set<State> acceptingStates;
  final Set<FSATransition> transitions;
  final Rect bounds;
  final DateTime created;
  final DateTime modified;
}
```

**Key Methods:**
- `copyWith()` - Create a copy with modified properties
- `isValid()` - Validate automaton structure
- `getStateById()` - Find state by ID
- `getTransitionsFrom()` - Get outgoing transitions

### State

```dart
class State {
  final String id;
  final String name;
  final Offset position;
  final bool isInitial;
  final bool isAccepting;
}
```

### FSATransition

```dart
class FSATransition extends Transition {
  final State fromState;
  final State toState;
  final String symbol;
}
```

## Core Algorithms

### AutomatonSimulator

```dart
class AutomatonSimulator {
  // Simulate automaton with input string
  static Result<SimulationResult> simulate(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  });
  
  // Test if automaton accepts string
  static Result<bool> accepts(FSA automaton, String inputString);
  
  // Test if automaton rejects string
  static Result<bool> rejects(FSA automaton, String inputString);
  
  // Find accepted strings
  static Result<Set<String>> findAcceptedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  });
}
```

### NFAToDFAConverter

```dart
class NFAToDFAConverter {
  // Convert NFA to equivalent DFA
  static Result<FSA> convert(FSA nfa);
}
```

### DFAMinimizer

```dart
class DFAMinimizer {
  // Minimize DFA using Hopcroft's algorithm
  static Result<FSA> minimize(FSA dfa);
}
```

### RegexToNFAConverter

```dart
class RegexToNFAConverter {
  // Convert regular expression to NFA
  static Result<FSA> convert(String regex);
}
```

### FAToRegexConverter

```dart
class FAToRegexConverter {
  // Convert finite automaton to regular expression
  static Result<String> convert(FSA fa);
}
```

## Result Pattern

All algorithms return a `Result<T>` type for consistent error handling:

```dart
sealed class Result<T> {
  const Result();
  
  bool get isSuccess;
  bool get isFailure;
  T? get data;
  String? get error;
}

class Success<T> extends Result<T> {
  final T data;
}

class Failure<T> extends Result<T> {
  final String message;
}
```

## Presentation Layer

### AutomatonProvider

State management using Riverpod:

```dart
class AutomatonProvider extends StateNotifier<AutomatonState> {
  // Create new automaton
  Future<void> createAutomaton({
    required String name,
    String? description,
    required List<String> alphabet,
  });
  
  // Update current automaton
  void updateAutomaton(FSA automaton);
  
  // Simulate automaton
  Future<void> simulateAutomaton(String inputString);
  
  // Convert NFA to DFA
  Future<void> convertNfaToDfa();
  
  // Minimize DFA
  Future<void> minimizeDfa();
  
  // Convert regex to NFA
  Future<void> convertRegexToNfa(String regex);
  
  // Convert FA to regex
  Future<void> convertFaToRegex();
}
```

### AutomatonState

```dart
class AutomatonState {
  final FSA? currentAutomaton;
  final SimulationResult? simulationResult;
  final String? regexResult;
  final bool isLoading;
  final String? error;
}
```

## UI Components

### AutomatonCanvas

Interactive canvas for drawing automata:

```dart
class AutomatonCanvas extends StatefulWidget {
  final FSA? automaton;
  final GlobalKey canvasKey;
  final SimulationResult? simulationResult;
  final int? currentStepIndex;
  final bool showTrace;
  final FlNodesCanvasController? controller;
}
```

**Features:**
- Touch-optimized state creation
- Interactive transition drawing
- Visual feedback for selections
- Empty state guidance

### AlgorithmPanel

Control panel for algorithm operations:

```dart
class AlgorithmPanel extends StatefulWidget {
  final VoidCallback? onNfaToDfa;
  final VoidCallback? onMinimizeDfa;
  final VoidCallback? onClear;
  final Function(String)? onRegexToNfa;
  final VoidCallback? onFaToRegex;
}
```

### SimulationPanel

Interface for automaton simulation:

```dart
class SimulationPanel extends StatefulWidget {
  final Function(String) onSimulate;
  final SimulationResult? simulationResult;
  final String? regexResult;
}
```

## Data Services

### AutomatonService

CRUD operations for automata:

```dart
class AutomatonService {
  Result<FSA> createAutomaton(CreateAutomatonRequest request);
  Result<FSA> getAutomaton(String id);
  Result<FSA> updateAutomaton(String id, CreateAutomatonRequest request);
  Result<void> deleteAutomaton(String id);
  Result<List<FSA>> listAutomata();
}
```

### SimulationService

Simulation operations:

```dart
class SimulationService {
  Result<SimulationResult> simulate(SimulationRequest request);
  Result<bool> accepts(SimulationRequest request);
  Result<bool> rejects(SimulationRequest request);
  Result<Set<String>> findAcceptedStrings(SimulationRequest request);
}
```

### ConversionService

Algorithm conversion operations:

```dart
class ConversionService {
  Result<FSA> convertNfaToDfa(ConversionRequest request);
  Result<FSA> minimizeDfa(ConversionRequest request);
  Result<FSA> convertRegexToNfa(ConversionRequest request);
  Result<String> convertFaToRegex(ConversionRequest request);
}
```

## Integration Patterns

### Using Algorithms in UI

```dart
// In a widget
final provider = ref.read(automatonProvider.notifier);

// Convert NFA to DFA
await provider.convertNfaToDfa();

// Simulate automaton
await provider.simulateAutomaton("abab");

// Convert regex to NFA
await provider.convertRegexToNfa("(a|b)*");
```

### Error Handling

```dart
// Check result
final result = NFAToDFAConverter.convert(nfa);
if (result.isSuccess) {
  final dfa = result.data!;
  // Use the DFA
} else {
  final error = result.error!;
  // Handle error
}
```

### State Management

```dart
// Watch state changes
final state = ref.watch(automatonProvider);

// Listen to specific properties
final automaton = ref.watch(automatonProvider.select((s) => s.currentAutomaton));
final isLoading = ref.watch(automatonProvider.select((s) => s.isLoading));
```

## Testing

### Unit Tests

```dart
// Test algorithm
test('NFA to DFA conversion', () {
  final nfa = createTestNFA();
  final result = NFAToDFAConverter.convert(nfa);
  expect(result.isSuccess, true);
  expect(result.data!.states.length, greaterThan(nfa.states.length));
});

// Test provider
testWidgets('Automaton provider simulation', (tester) async {
  final container = ProviderContainer();
  final provider = container.read(automatonProvider.notifier);
  
  await provider.simulateAutomaton("test");
  final state = container.read(automatonProvider);
  
  expect(state.simulationResult, isNotNull);
});
```

### Integration Tests

```dart
// Test full workflow
testWidgets('Complete FSA workflow', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Create automaton
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  
  // Simulate
  await tester.enterText(find.byType(TextField), "ab");
  await tester.tap(find.text('Simulate'));
  await tester.pumpAndSettle();
  
  // Verify result
  expect(find.text('Accepted'), findsOneWidget);
});
```

## Performance Considerations

### Canvas Rendering

- Use `CustomPainter` for efficient rendering
- Implement `shouldRepaint` to minimize redraws
- Use `RepaintBoundary` for complex widgets

### State Management

- Use `select` to watch specific state properties
- Implement proper `dispose` methods
- Use `StateNotifier` for complex state logic

### Algorithm Execution

- Run algorithms in isolates for heavy computation
- Implement timeout mechanisms
- Provide progress feedback for long operations

## Best Practices

### Code Organization

1. **Separation of Concerns** - Keep UI, business logic, and data separate
2. **Dependency Injection** - Use GetIt for service registration
3. **Error Handling** - Use Result pattern consistently
4. **Testing** - Write comprehensive tests for all algorithms

### UI/UX Guidelines

1. **Mobile-First** - Design for touch interfaces
2. **Responsive** - Adapt to different screen sizes
3. **Accessibility** - Include proper semantic labels
4. **Performance** - Optimize for 60fps rendering

### Algorithm Implementation

1. **Correctness** - Ensure mathematical accuracy
2. **Efficiency** - Optimize for mobile performance
3. **Documentation** - Document algorithm complexity
4. **Testing** - Test edge cases and error conditions

## Troubleshooting

### Common Issues

1. **State Not Updating** - Check Riverpod provider setup
2. **Canvas Not Rendering** - Verify CustomPainter implementation
3. **Algorithm Errors** - Check input validation and error handling
4. **Performance Issues** - Profile with Flutter DevTools

### Debug Tools

- Use `flutter analyze` for static analysis
- Use Flutter DevTools for performance profiling
- Automated test coverage is temporarily unavailable during the algorithm migration; run `flutter analyze` instead until the new suites land.
- Use debug prints for algorithm step tracking

## Future Extensions

### Planned APIs

- Grammar editing and parsing
- PDA visualization and simulation
- Turing machine single-tape support
- Interactive pumping lemma game

### Extension Points

- Custom algorithm plugins
- File format import/export
- Educational content integration
- Collaborative features
- Advanced visualizations
