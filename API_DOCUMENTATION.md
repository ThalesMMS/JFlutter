# JFlutter API Documentation

## Overview

JFlutter provides a comprehensive API for working with finite automata, context-free grammars, and formal language theory constructs. The API is organized into several packages following clean architecture principles.

## Package Structure

```
packages/
├── core_fa/          # Finite Automata models and algorithms
├── core_pda/          # Pushdown Automata models and algorithms  
├── core_tm/           # Turing Machine models and algorithms
├── core_regex/        # Regular Expressions and Context-Free Grammars
├── conversions/       # Algorithm implementations and conversions
├── serializers/       # File I/O and data serialization
├── viz/               # Visualization and rendering
└── playground/        # Interactive examples and demonstrations
```

## Core Models

### Finite Automaton

```dart
import 'package:core_fa/models/finite_automaton.dart';

// Create a finite automaton
final automaton = FiniteAutomaton(
  id: 'my-automaton',
  name: 'My Automaton',
  states: [
    State(id: 'q0', name: 'q0', position: Position(x: 100, y: 100), isInitial: true),
    State(id: 'q1', name: 'q1', position: Position(x: 200, y: 100), isAccepting: true),
  ],
  transitions: [
    Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
  ],
  alphabet: Alphabet(symbols: ['a', 'b']),
  metadata: AutomatonMetadata(
    createdAt: DateTime.now(),
    createdBy: 'user',
  ),
);
```

### Pushdown Automaton

```dart
import 'package:core_pda/models/pushdown_automaton.dart';

// Create a pushdown automaton
final pda = PushdownAutomaton(
  id: 'my-pda',
  name: 'My PDA',
  states: [/* states */],
  transitions: [/* PDA transitions */],
  inputAlphabet: Alphabet(symbols: ['a', 'b']),
  stackAlphabet: Alphabet(symbols: ['Z', 'A', 'B']),
  initialState: 'q0',
  finalStates: ['qf'],
  acceptanceMode: AcceptanceMode.finalState,
  metadata: AutomatonMetadata(/* metadata */),
);
```

### Turing Machine

```dart
import 'package:core_tm/models/turing_machine.dart';

// Create a Turing machine
final tm = TuringMachine(
  id: 'my-tm',
  name: 'My TM',
  states: [/* states */],
  transitions: [/* TM transitions */],
  alphabet: Alphabet(symbols: ['0', '1']),
  initialState: 'q0',
  finalStates: ['qf'],
  blankSymbol: 'B',
  metadata: AutomatonMetadata(/* metadata */),
);
```

## Algorithms

### NFA to DFA Conversion

```dart
import 'package:conversions/algorithms/nfa_to_dfa.dart';

final converter = NfaToDfaConverter();
final dfa = converter.convert(nfa);
```

### DFA Minimization

```dart
import 'package:conversions/algorithms/dfa_minimization.dart';

final minimizer = DfaMinimizer();
final minimizedDfa = minimizer.minimize(dfa);
```

### FA to Regex Conversion

```dart
import 'package:conversions/algorithms/fa_to_regex.dart';

final converter = FaToRegexConverter();
final regex = converter.convert(fa);
```

### Regex to NFA Conversion

```dart
import 'package:conversions/algorithms/regex_to_nfa.dart';

final converter = RegexToNfaConverter();
final nfa = converter.convert('(a+b)*ab');
```

## Simulation

### Automaton Simulation

```dart
import 'package:core_fa/models/automaton_simulator.dart';

final simulator = AutomatonSimulator();
final result = await simulator.simulate(automaton, 'input_string');

if (result.isAccepted) {
  print('String accepted');
  print('Steps: ${result.steps.length}');
} else {
  print('String rejected');
}
```

### Step-by-Step Execution

```dart
// Get detailed execution trace
final trace = result.trace;
for (final step in trace.steps) {
  print('State: ${step.state}, Symbol: ${step.symbol}, Next: ${step.nextState}');
}
```

## File I/O

### JSON Serialization

```dart
import 'package:serializers/serializers/json_serializer.dart';

final serializer = JsonSerializer();

// Serialize automaton to JSON
final json = serializer.serializeAutomaton(automaton);

// Deserialize JSON to automaton
final automaton = serializer.deserializeAutomaton(json);
```

### JFLAP File Format

```dart
import 'package:serializers/serializers/jff_serializer.dart';

final jffSerializer = JffSerializer();

// Export to JFLAP format
final jffData = jffSerializer.exportToJff(automaton);

// Import from JFLAP format
final automaton = jffSerializer.importFromJff(jffData);
```

## Visualization

### Canvas Rendering

```dart
import 'package:jflutter/presentation/widgets/automaton_canvas/automaton_canvas.dart';

AutomatonCanvas(
  automaton: automaton,
  onStateAdded: (x, y) {
    // Handle state addition
  },
  onTransitionAdded: (from, to, symbol) {
    // Handle transition addition
  },
  onStateUpdated: (state) {
    // Handle state updates
  },
  onTransitionUpdated: (transition) {
    // Handle transition updates
  },
)
```

### Custom Rendering

```dart
import 'package:viz/rendering/canvas_renderer.dart';

final renderer = CanvasRenderer();
await renderer.renderAutomaton(canvas, automaton);
```

## State Management

### Riverpod Providers

```dart
import 'package:jflutter/presentation/providers/automaton_provider.dart';

// Get automaton state
final automatonState = ref.watch(automatonProvider);

// Update automaton
ref.read(automatonProvider.notifier).updateAutomaton(newAutomaton);
```

### Simulation State

```dart
import 'package:jflutter/presentation/providers/simulation_provider.dart';

// Start simulation
ref.read(simulationProvider.notifier).startSimulation(input);

// Step through simulation
ref.read(simulationProvider.notifier).nextStep();

// Reset simulation
ref.read(simulationProvider.notifier).reset();
```

## Error Handling

### Result Pattern

```dart
import 'package:jflutter/core/result.dart';

final result = await someOperation();

if (result.isSuccess) {
  final data = result.data;
  // Use data
} else {
  final error = result.error;
  print('Error: ${error.message}');
}
```

### Exception Handling

```dart
try {
  final result = await simulator.simulate(automaton, input);
  // Handle result
} on AutomatonException catch (e) {
  print('Automaton error: ${e.message}');
} on SimulationException catch (e) {
  print('Simulation error: ${e.message}');
}
```

## Performance Considerations

### Large Automata

```dart
// For automata with 100+ states, use async operations
final result = await simulator.simulateAsync(largeAutomaton, input);

// Monitor performance
final stopwatch = Stopwatch()..start();
final result = await operation();
stopwatch.stop();
print('Operation took: ${stopwatch.elapsedMilliseconds}ms');
```

### Memory Management

```dart
// Dispose of resources when done
await simulator.dispose();
await renderer.dispose();
```

## Testing

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';

test('automaton simulation', () {
  final automaton = createTestAutomaton();
  final simulator = AutomatonSimulator();
  
  expect(simulator.simulate(automaton, 'ab').isAccepted, isTrue);
});
```

### Integration Tests

```dart
testWidgets('automaton canvas interaction', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Test canvas interactions
  await tester.tap(find.byType(AutomatonCanvas));
  await tester.pumpAndSettle();
  
  expect(find.text('State added'), findsOneWidget);
});
```

## Best Practices

### Model Design

- Use immutable models with `freezed`
- Implement proper `==` and `hashCode`
- Include comprehensive validation

### Algorithm Implementation

- Follow functional programming principles
- Use pure functions where possible
- Implement proper error handling

### UI Development

- Use responsive design patterns
- Implement proper accessibility
- Follow Material 3 guidelines

### Testing

- Write comprehensive unit tests
- Include integration tests for workflows
- Use property-based testing for algorithms
- Implement performance benchmarks

## Migration Guide

### From Legacy Models

```dart
// Old way
final automaton = Automaton(/* old parameters */);

// New way
final automaton = FiniteAutomaton(
  id: automaton.id,
  name: automaton.name,
  states: automaton.states.map((s) => State(/* new parameters */)).toList(),
  // ... other fields
);
```

### API Changes

- All models now use `freezed` for immutability
- Simulation results include detailed traces
- File I/O supports multiple formats
- Visualization is component-based

## Troubleshooting

### Common Issues

1. **Compilation Errors**: Ensure all dependencies are properly imported
2. **Runtime Errors**: Check model validation and state consistency
3. **Performance Issues**: Use async operations for large automata
4. **Memory Leaks**: Properly dispose of resources

### Debug Tools

```dart
// Enable debug logging
AutomatonSimulator.debugMode = true;

// Profile performance
final profiler = PerformanceProfiler();
await profiler.measure(() async {
  return await operation();
});
```

## Contributing

### Code Style

- Follow Dart/Flutter conventions
- Use `very_good_analysis` for linting
- Write comprehensive documentation
- Include tests for new features

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Update documentation
5. Submit pull request

## License

This project is licensed under the Apache License 2.0. See [LICENSE.txt](LICENSE.txt) for details.

## Support

For questions and support:

- **Issues**: [GitHub Issues](https://github.com/ThalesMMS/jflutter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ThalesMMS/jflutter/discussions)
- **Email**: thalesmmsradio@gmail.com