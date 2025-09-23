# JFlutter API Documentation

## Overview

JFlutter provides a comprehensive API for working with formal language theory concepts including finite automata, context-free grammars, and various algorithms. This documentation covers the core APIs, data models, and integration patterns.

**Highlights of the latest architecture changes:**
- Automaton flows are coordinated by specialised controllers that plug into a
  shared `AutomatonProvider` for Riverpod-driven state management.【F:lib/presentation/providers/automaton_provider.dart†L1-L194】
- Application settings now use a dedicated repository, storage abstraction, and
  `SettingsViewModel` to deliver robust persistence and UI feedback.【F:lib/presentation/providers/settings_view_model.dart†L1-L109】【F:lib/data/repositories/settings_repository_impl.dart†L1-L59】

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

Recent refactors split the monolithic automaton provider into focused
controllers that coordinate creation, simulation, conversion, and layout
concerns. `AutomatonProvider` now composes these controllers while exposing a
single Riverpod state notifier to the UI.

### AutomatonState

```dart
class AutomatonState {
  final FSA? currentAutomaton;
  final SimulationResult? simulationResult;
  final String? regexResult;
  final Grammar? grammarResult;
  final bool? equivalenceResult;
  final String? equivalenceDetails;
  final bool isLoading;
  final String? error;

  const AutomatonState({ ... });

  AutomatonState copyWith({ ... });
}
```

**Highlights:**
- Holds the current automaton plus derived results (simulation, regex,
  grammar conversion, and equivalence feedback).【F:lib/presentation/providers/automaton/automaton_state.dart†L1-L52】
- Provides a `copyWith` helper that lets controllers update individual fields
  while preserving the rest of the state.【F:lib/presentation/providers/automaton/automaton_state.dart†L23-L51】

### AutomatonCreationController

```dart
class AutomatonCreationController {
  Future<AutomatonState> createAutomaton(
    AutomatonState state, {
    required String name,
    required List<String> alphabet,
  });

  AutomatonState updateAutomaton(AutomatonState state, FSA automaton);
  AutomatonState clearAutomaton(AutomatonState state);
  AutomatonState clearError(AutomatonState state);
}
```

Responsible for provisioning new automata and resetting state while delegating
to use cases such as `CreateAutomatonUseCase` and `AddStateUseCase`. Each
method returns an updated `AutomatonState` so that orchestration remains pure
and testable.【F:lib/presentation/providers/automaton/automaton_creation_controller.dart†L1-L74】

### AutomatonConversionController

```dart
class AutomatonConversionController {
  Future<AutomatonState> convertNfaToDfa(AutomatonState state);
  Future<AutomatonState> minimizeDfa(AutomatonState state);
  Future<AutomatonState> completeDfa(AutomatonState state);
  Future<AutomatonState> convertRegexToNfa(
    AutomatonState state,
    String regex,
  );
  Future<AutomatonState> convertFsaToGrammar(AutomatonState state);
  Future<AutomatonState> convertFaToRegex(AutomatonState state);
  Future<AutomatonState> compareEquivalence(
    AutomatonState state,
    FSA other,
  );
}
```

Wraps the suite of algorithmic conversion use cases, maps entities back to UI
models, and normalises error handling. Every branch funnels through
`AutomatonState.copyWith` to clear loading flags and populate results or
messages.【F:lib/presentation/providers/automaton/automaton_conversion_controller.dart†L1-L136】

### AutomatonSimulationController

```dart
class AutomatonSimulationController {
  Future<AutomatonState> simulate(
    AutomatonState state,
    String inputString,
  );
}
```

Executes word simulations through `SimulateWordUseCase` and records the latest
`SimulationResult` while handling common loading/error flows.【F:lib/presentation/providers/automaton/automaton_simulation_controller.dart†L1-L45】

### AutomatonLayoutController

```dart
class AutomatonLayoutController {
  Future<AutomatonState> applyAutoLayout(AutomatonState state);
}
```

Applies automatic layout strategies by delegating to `ApplyAutoLayoutUseCase`
and refreshing the state with the updated automaton geometry.【F:lib/presentation/providers/automaton/automaton_layout_controller.dart†L1-L33】

### AutomatonProvider

```dart
class AutomatonProvider extends StateNotifier<AutomatonState> {
  AutomatonProvider({
    required AutomatonCreationController creationController,
    required AutomatonSimulationController simulationController,
    required AutomatonConversionController conversionController,
    required AutomatonLayoutController layoutController,
  });

  Future<void> createAutomaton({
    required String name,
    required List<String> alphabet,
  });
  void updateAutomaton(FSA automaton);
  Future<void> simulateAutomaton(String inputString);
  Future<void> convertNfaToDfa();
  Future<void> minimizeDfa();
  Future<void> completeDfa();
  Future<Grammar?> convertFsaToGrammar();
  Future<void> applyAutoLayout();
  Future<void> convertRegexToNfa(String regex);
  Future<String?> convertFaToRegex();
  Future<bool?> compareEquivalence(FSA other);
  void clearAutomaton();
  void clearError();
}
```

`AutomatonProvider` stitches the specialised controllers together. Riverpod
providers expose concrete controller instances and the state notifier in a
composable way:

```dart
final automatonProvider =
    StateNotifierProvider<AutomatonProvider, AutomatonState>((ref) {
  final creation = ref.watch(automatonCreationControllerProvider);
  final simulation = ref.watch(automatonSimulationControllerProvider);
  final conversion = ref.watch(automatonConversionControllerProvider);
  final layout = ref.watch(automatonLayoutControllerProvider);
  return AutomatonProvider(
    creationController: creation,
    simulationController: simulation,
    conversionController: conversion,
    layoutController: layout,
  );
});
```
【F:lib/presentation/providers/automaton_provider.dart†L1-L134】【F:lib/presentation/providers/automaton_provider.dart†L137-L194】

**Usage Example:**

```dart
class AutomatonActionsBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(automatonProvider);
    final controller = ref.watch(automatonProvider.notifier);

    return Row(children: [
      ElevatedButton(
        onPressed: state.isLoading
            ? null
            : () => controller.convertNfaToDfa(),
        child: const Text('Convert NFA → DFA'),
      ),
      ElevatedButton(
        onPressed: state.currentAutomaton == null
            ? null
            : () => controller.simulateAutomaton('abba'),
        child: const Text('Simulate'),
      ),
    ]);
  }
}
```

### SettingsViewModel

```dart
class SettingsViewModel extends StateNotifier<AsyncValue<SettingsModel>> {
  SettingsViewModel(SettingsRepository repository);

  Future<String?> load();
  Future<String?> save();
  Future<String?> reset();
  void updateEmptyStringSymbol(String value);
  void updateEpsilonSymbol(String value);
  void updateThemeMode(String value);
  void updateShowGrid(bool value);
  void updateShowCoordinates(bool value);
  void updateGridSize(double value);
  void updateNodeSize(double value);
  void updateFontSize(double value);
  void updateAutoSave(bool value);
  void updateShowTooltips(bool value);
}
```

Manages asynchronous loading and persistence of user settings, exposing
optimistic updates with detailed error messages for UI presentation.
【F:lib/presentation/providers/settings_view_model.dart†L1-L109】

### Settings Providers

```dart
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('settingsRepositoryProvider must be overridden');
});

final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, AsyncValue<SettingsModel>>(
  (ref) => SettingsViewModel(ref.watch(settingsRepositoryProvider)),
);
```

These providers make it easy to inject the repository implementation at the
app root while offering a strongly typed view model to widgets.
【F:lib/presentation/providers/settings_providers.dart†L1-L16】

## UI Components

### AutomatonCanvas

Interactive canvas for drawing automata:

```dart
class AutomatonCanvas extends StatefulWidget {
  final FSA? automaton;
  final GlobalKey canvasKey;
  final ValueChanged<FSA> onAutomatonChanged;
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

### SettingsRepository

```dart
abstract class SettingsRepository {
  Future<SettingsModel> loadSettings();
  Future<void> saveSettings(SettingsModel settings);
}
```

Defines the contract for persisting user preferences; implementations provide
asynchronous loading and saving semantics.【F:lib/core/repositories/settings_repository.dart†L1-L10】

### SharedPreferencesSettingsRepository

```dart
class SharedPreferencesSettingsRepository implements SettingsRepository {
  Future<SettingsModel> loadSettings();
  Future<void> saveSettings(SettingsModel settings);
}
```

Backs the repository contract with `SharedPreferences`, mapping every setting
to a dedicated key and ensuring batch writes succeed before resolving.
【F:lib/data/repositories/settings_repository_impl.dart†L1-L59】

### SettingsStorage

```dart
abstract class SettingsStorage {
  Future<String?> readString(String key);
  Future<bool?> readBool(String key);
  Future<double?> readDouble(String key);
  Future<bool> writeString(String key, String value);
  Future<bool> writeBool(String key, bool value);
  Future<bool> writeDouble(String key, double value);
}
```

`SharedPreferencesSettingsStorage` offers a production-ready implementation,
while `InMemorySettingsStorage` powers tests with synchronous in-memory
behaviour.【F:lib/data/storage/settings_storage.dart†L1-L71】【F:lib/data/storage/settings_storage.dart†L73-L103】

### FileOperationsService

```dart
class FileOperationsService {
  Future<StringResult> saveAutomatonToJFLAP(FSA automaton, String filePath);
  Future<Result<FSA>> loadAutomatonFromJFLAP(String filePath);
  Future<StringResult> saveGrammarToJFLAP(Grammar grammar, String filePath);
  Future<Result<Grammar>> loadGrammarFromJFLAP(String filePath);
  Future<StringResult> exportAutomatonToPNG(FSA automaton, String filePath);
  Future<StringResult> exportAutomatonToSVG(FSA automaton, String filePath);
  Future<StringResult> getDocumentsDirectory();
  Future<StringResult> createUniqueFile(String baseName, String extension);
  Future<ListResult<String>> listFiles(String extension);
  Future<BoolResult> deleteFile(String filePath);
}
```

Refined this week to rely on async iteration for directory traversal while
providing comprehensive import/export utilities for automata and grammars.
All operations surface typed `Result` wrappers for consistent error handling.
【F:lib/data/services/file_operations_service.dart†L1-L114】

### AutomatonService

`AutomatonService` centralises CRUD, persistence and validation flows for in-memory automata collections:

```dart
class AutomatonService {
  Result<FSA> createAutomaton(CreateAutomatonRequest request);
  Result<FSA> getAutomaton(String id);
  Result<FSA> updateAutomaton(String id, CreateAutomatonRequest request);
  Result<FSA> saveAutomaton(String id, CreateAutomatonRequest request);
  Result<void> deleteAutomaton(String id);
  Result<List<FSA>> listAutomata();
  Result<void> clearAutomata();
  Result<String> exportAutomaton(FSA automaton);
  Result<FSA> importAutomaton(String jsonString);
  Result<bool> validateAutomaton(FSA automaton);
}
```

### SimulationService

`SimulationService` delegates to `AutomatonSimulator` for both deterministic and nondeterministic execution paths:

```dart
class SimulationService {
  Result<SimulationResult> simulate(SimulationRequest request);
  Result<SimulationResult> simulateNFA(SimulationRequest request);
  Result<bool> accepts(SimulationRequest request);
  Result<bool> rejects(SimulationRequest request);
  Result<Set<String>> findAcceptedStrings(SimulationRequest request);
  Result<Set<String>> findRejectedStrings(SimulationRequest request);
}
```

### ConversionService

`ConversionService` fronts a suite of algorithms spanning automata, regexes, and grammars:

```dart
class ConversionService {
  Result<FSA> convertNfaToDfa(ConversionRequest request);
  Result<FSA> minimizeDfa(ConversionRequest request);
  Result<FSA> convertRegexToNfa(ConversionRequest request);
  Result<String> convertFaToRegex(ConversionRequest request);
  Result<dynamic> convertGrammarToPda(ConversionRequest request);
  Result<dynamic> convertGrammarToPdaStandard(ConversionRequest request);
  Result<dynamic> convertGrammarToPdaGreibach(ConversionRequest request);
  Result<FSA> convertGrammarToFsa(ConversionRequest request);
}
```

### Data Transfer Objects

#### CreateAutomatonRequest

Encapsulates the payload necessary to materialise an `FSA`, including layout metadata used by the editor canvas.

**Fields**

- `String name` – human readable label (non-empty requirement enforced).
- `String? description` – optional long-form description.
- `List<StateData> states` – declarative set of state descriptors.
- `List<TransitionData> transitions` – declared transition edges.
- `List<String> alphabet` – symbol set validated against transitions.
- `Rect bounds` – drawing canvas extents (left, top, right, bottom).

```dart
const CreateAutomatonRequest({
  required String name,
  String? description,
  required List<StateData> states,
  required List<TransitionData> transitions,
  required List<String> alphabet,
  required Rect bounds,
});
```

#### StateData

Defines the lightweight state blueprint consumed by the service layer.

**Fields**

- `String id` – unique identifier.
- `String name` – display label persisted into `State.label`.
- `Point position` – cartesian coordinates for layout.
- `bool isInitial` – marks the unique start state.
- `bool isAccepting` – indicates terminal/accepting semantics.

```dart
const StateData({
  required String id,
  required String name,
  required Point position,
  required bool isInitial,
  required bool isAccepting,
});
```

#### TransitionData

Carries adjacency information linking state identifiers to input symbols.

**Fields**

- `String fromStateId`
- `String toStateId`
- `String symbol` – supports ε/λ style markers for lambda transitions.

```dart
const TransitionData({
  required String fromStateId,
  required String toStateId,
  required String symbol,
});
```

#### SimulationRequest

Used to configure simulation runs regardless of deterministic or nondeterministic strategy.

**Fields**

- `FSA? automaton`
- `String? inputString`
- `bool? stepByStep`
- `Duration? timeout`
- `int? maxLength`
- `int? maxResults`

**Factories**

- `SimulationRequest.forInput({required FSA automaton, required String inputString, bool stepByStep = false, Duration? timeout})`
- `SimulationRequest.forFinding({required FSA automaton, int maxLength = 10, int maxResults = 100})`

```dart
const SimulationRequest({
  FSA? automaton,
  String? inputString,
  bool? stepByStep,
  Duration? timeout,
  int? maxLength,
  int? maxResults,
});
```

#### ConversionRequest

Represents a normalised conversion intent with type-safe helpers for every supported transformation.

**Fields**

- `FSA? automaton`
- `Grammar? grammar`
- `String? regex`
- `ConversionType conversionType`

**Factories**

- `ConversionRequest.nfaToDfa({required FSA automaton})`
- `ConversionRequest.dfaMinimization({required FSA automaton})`
- `ConversionRequest.regexToNfa({required String regex})`
- `ConversionRequest.faToRegex({required FSA automaton})`
- `ConversionRequest.grammarToPda({required Grammar grammar})`
- `ConversionRequest.grammarToPdaStandard({required Grammar grammar})`
- `ConversionRequest.grammarToPdaGreibach({required Grammar grammar})`
- `ConversionRequest.grammarToFsa({required Grammar grammar})`

```dart
const ConversionRequest({
  FSA? automaton,
  Grammar? grammar,
  String? regex,
  required ConversionType conversionType,
});
```

## Integration Patterns

### Using Algorithms in UI

```dart
final automatonService = AutomatonService();
final simulationService = SimulationService();
final conversionService = ConversionService();

// Create or update an automaton with geometry metadata
final createRequest = CreateAutomatonRequest(
  name: 'Example DFA',
  description: 'Accepts strings ending with 01',
  alphabet: ['0', '1'],
  states: const [
    StateData(
      id: 'q0',
      name: 'q0',
      position: Point(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    StateData(
      id: 'q1',
      name: 'q1',
      position: Point(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  ],
  transitions: const [
    TransitionData(fromStateId: 'q0', toStateId: 'q0', symbol: '0'),
    TransitionData(fromStateId: 'q0', toStateId: 'q1', symbol: '1'),
    TransitionData(fromStateId: 'q1', toStateId: 'q0', symbol: '0'),
    TransitionData(fromStateId: 'q1', toStateId: 'q1', symbol: '1'),
  ],
  bounds: const Rect(-50, -50, 200, 100),
);

final automaton = automatonService.createAutomaton(createRequest).data!;

// Simulate deterministically (DFA)
final simulation = simulationService.simulate(
  SimulationRequest.forInput(
    automaton: automaton,
    inputString: '0101',
    stepByStep: true,
  ),
);

// Simulate nondeterministically (NFA with epsilon transitions)
final nfaSimulation = simulationService.simulateNFA(
  SimulationRequest.forInput(
    automaton: automaton,
    inputString: '0101',
  ),
);

// Explore language bounds
final accepted = simulationService.findAcceptedStrings(
  SimulationRequest.forFinding(automaton: automaton, maxLength: 4),
);
final rejected = simulationService.findRejectedStrings(
  SimulationRequest.forFinding(automaton: automaton, maxLength: 4),
);

// Convert NFA to DFA and minimise
final dfaResult = conversionService.convertNfaToDfa(
  ConversionRequest.nfaToDfa(automaton: automaton),
);
final minimized = conversionService.minimizeDfa(
  ConversionRequest.dfaMinimization(automaton: dfaResult.data!),
);

// Convert DFA to regex
final regexResult = conversionService.convertFaToRegex(
  ConversionRequest.faToRegex(automaton: minimized.data!),
);
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
- Use `flutter test` for automated testing
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
