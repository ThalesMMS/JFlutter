# JFlutter API Documentation

## Overview

JFlutter provides a comprehensive API for working with formal language theory
concepts including finite automata, context-free grammars, and various
algorithms. This documentation covers the core APIs, data models, and
integration patterns.

> **Nota importante**: durante a reescrita dos algoritmos, cada contrato
> descrito aqui é conferido contra os projetos que vivem em `References/`
> (principalmente as bases em Dart e o repositório Python `automata-main`).
> Essas referências balizam as alterações até que novos testes automatizados
> estejam disponíveis.

## Core Architecture

### Clean Architecture Layers

```text
┌──────────────────────────────────────────────┐
│            Presentation Layer                │
│  (UI Components, Pages, Providers            │
│   e.g., AutomatonProvider,                   │
│         UnifiedTraceNotifier)                │
├──────────────────────────────────────────────┤
│               Core Layer                     │
│  (Algorithms, Models, Business Rules,        │
│   Repositories e.g., LayoutRepository,       │
│   Services e.g., TracePersistenceService)    │
├──────────────────────────────────────────────┤
│                Data Layer                    │
│  (Services, Persistence, Storage             │
│   e.g., TracePersistenceService data,        │
│   SharedPreferences adapters)                │
└──────────────────────────────────────────────┘
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

#### Key methods

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
  // Simulate a DFA with input string (deterministic, no epsilon)
  static Future<Result<SimulationResult>> simulateDFA(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  });

  // Simulate an NFA, handling nondeterminism and epsilon transitions
  static Future<Result<SimulationResult>> simulateNFA(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  });

  // Generic entry point that dispatches to DFA/NFA simulators
  static Future<Result<SimulationResult>> simulate(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  });

  // Test if automaton accepts string
  static Future<Result<bool>> accepts(FSA automaton, String inputString);

  // Test if automaton rejects string
  static Future<Result<bool>> rejects(FSA automaton, String inputString);

  // Find accepted strings
  static Future<Result<Set<String>>> findAcceptedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  });

  // Find rejected strings
  static Future<Result<Set<String>>> findRejectedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  });
}
```

> **Async usage**: All `AutomatonSimulator` methods return `Future<Result<…>>`. Use
> `await` (or equivalent Future handling) and inspect the resulting `Result`
> before dereferencing `data`; asynchronous failures surface via the `error`
> payload just like synchronous validation issues.

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
  static Result<FSA> convert(
    String regex, {
    Set<String>? contextAlphabet,
  });
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

Riverpod `StateNotifier<AutomatonState>` responsible for orchestrating
automaton editing, GraphView synchronisation, and algorithm execution.

#### Constructor dependencies

- `AutomatonService automatonService` – persistence and CRUD bridge for
  FSAs.
- `LayoutRepository layoutRepository` – supplies layout helpers for the
  GraphView canvas.
- `TracePersistenceService? tracePersistenceService` – optional storage for
  simulation traces.

#### Key responsibilities

- **Automaton lifecycle** – `createAutomaton`, `updateAutomaton`,
  `replaceCurrentAutomaton`, `clearAutomaton`, and `clearAll` keep the active
  machine and metadata consistent.
- **GraphView canvas mutations** – `addState`, `moveState`, `removeState`,
  `addOrUpdateTransition`, `removeTransition`, `updateStateLabel`,
  `updateStateFlags`, `updateTransitionLabel`, and `_mutateAutomaton` integrate
  GraphView edits with the persisted automaton model.
- **Algorithm workflows** – methods such as `simulateAutomaton`,
  `convertNfaToDfa`, `minimizeDfa`, `completeDfa`, `convertRegexToNfa`,
  `convertFaToRegex`, `convertFsaToGrammar`, and `compareEquivalence` execute
  domain algorithms while updating state and histories.
- **History & tracing** – maintains `automatonHistory` and
  `simulationHistory`, persists traces via `_addSimulationToHistory`, and
  exposes accessors like `getAutomatonFromHistory` and
  `getSimulationFromHistory`.
- **Canvas utilities** – `applyAutoLayout` and the
  `graphViewCanvasControllerProvider` helper ensure GraphView controllers stay
  synchronised with `AutomatonState`.

### UnifiedTraceNotifier

StateNotifier responsável por unificar o ciclo de vida dos traços de simulação
vindos de qualquer simulador disponível (AFD, AFN, gramáticas, PDA, etc.). O
notificador mantém histórico, estado atual e estatísticas persistidas em
`SharedPreferences`, expondo provedores Riverpod e integrações via GetIt para
uso fora da árvore de widgets.

#### Responsabilidades centrais

- **Contexto ativo** – `setAutomatonContext` fixa tipo e identificador do
  autômato em edição antes de consultar históricos segmentados.
- **Navegação de traço** – métodos como `navigateToStep`, `nextStep`,
  `previousStep`, `firstStep` e `lastStep` atualizam o passo atual e disparam o
  salvamento incremental.
- **Persistência transparente** – `setTrace`, `saveCurrentTraceToHistory` e
  `clearCurrentTrace` orquestram salvamentos no serviço de dados sem bloquear a
  UI.
- **Gestão de histórico e métricas** – `_loadTraceHistory`,
  `_loadTraceStatistics` e `refreshTraceStatistics` mantêm listas e agregados
  prontos para painéis analíticos.
- **Importação/exportação** – `exportTraceHistory` e `importTraceHistory`
  permitem compartilhar execuções entre dispositivos ou sessões.

#### Métodos e fluxos chave

- `loadTraceFromHistory(traceId)` – restaura uma simulação previamente salva,
  ressincronizando o passo corrente com destaque imediato no canvas.
- `saveCurrentTraceToHistory()` – captura o resultado mais recente da
  simulação e armazena metadados como tipo de autômato e identificador opcional
  para consultas futuras.
- `clearAllTraces()` – limpa histórico global e estado ativo, útil ao alternar
  de contas ou redefinir o laboratório.

#### Exemplo prático – salvar um traço após simular

```dart
final notifier = ref.read(unifiedTraceProvider.notifier);

await provider.simulateAutomaton('abba');
notifier.setAutomatonContext(automatonType: 'dfa', automatonId: 'dfa_001');

final simulation = ref.read(automatonProvider).simulationResult;
if (simulation != null) {
  notifier.setTrace(simulation);
  await notifier.saveCurrentTraceToHistory();
}
```

#### Exemplo prático – retomar um traço salvo

```dart
final notifier = ref.read(unifiedTraceProvider.notifier);
await notifier.loadTraceFromHistory(selectedTraceId);

final step = ref.read(unifiedTraceProvider).currentStep;
if (step != null) {
  highlightCanvas(step);
}
```

### AutomatonState

Immutable snapshot of the automaton workspace.

#### Fields

- `FSA? currentAutomaton` – active machine rendered on the canvas.
- `SimulationResult? simulationResult` – latest simulation outcome.
- `String? regexResult` – most recent FA→regex conversion output.
- `Grammar? grammarResult` – cached grammar generated from the current FSA.
- `bool? equivalenceResult` / `String? equivalenceDetails` – result and
  description from the equivalence checker.
- `bool isLoading` – true while asynchronous work is executing.
- `String? error` – user-visible error message.
- `List<FSA> automatonHistory` – snapshots of previous automatons.
- `List<SimulationResult> simulationHistory` – persisted simulation traces.

#### Helpers

- `copyWith(...)` – selective updates used by the provider.
- `clear()` – resets the entire state back to its initial values.
- `clearError()` – removes the current error message.
- `clearSimulation()` – drops simulation output and history.
- `clearAlgorithmResults()` – clears regex, grammar, and equivalence data.

## UI Components

### AutomatonGraphViewCanvas

GraphView-driven canvas widget used to render and edit automatons while keeping
the provider state in sync.

#### Parameters

- `FSA? automaton` – machine to render.
- `GlobalKey canvasKey` – used for layout and overlay anchoring.
- `GraphViewCanvasController? controller` – optional external controller; the
  widget will create and own one if omitted.
- `AutomatonCanvasToolController? toolController` – manages current editing
  tool (selection, state creation, transitions, etc.).
- `SimulationResult? simulationResult` – supplies simulation highlights.
- `int? currentStepIndex` – active simulation step for trace playback.
- `bool showTrace` – toggles visibility of the highlight trace.

#### Controller lifecycle & highlight integration

- When the widget owns the controller, it wires it to the
  `automatonProvider` through a `GraphViewCanvasController` instance.
- Connects to `SimulationHighlightService` via a
  `GraphViewSimulationHighlightChannel`, ensuring canvas highlights mirror
  simulation progress.
- Responds to GraphView revision notifications to keep transition overlays and
  gesture state consistent.

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

In-memory CRUD and import/export helpers for FSAs.

- `Result<FSA> createAutomaton(CreateAutomatonRequest request)` – build a new
  automaton snapshot from the provided request.
- `Result<FSA> getAutomaton(String id)` / `Result<List<FSA>> listAutomata()` –
  retrieve stored automatons.
- `Result<FSA> updateAutomaton(String id, CreateAutomatonRequest request)` and
  `Result<FSA> saveAutomaton(String id, CreateAutomatonRequest request)` –
  update existing automatons, preserving timestamps when possible.
- `Result<void> deleteAutomaton(String id)` / `Result<void> clearAutomata()` –
  remove automatons.
- `Result<String> exportAutomaton(FSA automaton)` and
  `Result<FSA> importAutomaton(String jsonString)` – convert between JSON and
  runtime models.
- `Result<bool> validateAutomaton(FSA automaton)` – run structural validation
  checks.

### SimulationService

Asynchronous helpers around `AutomatonSimulator`.

- `Future<Result<SimulationResult>> simulate(SimulationRequest request)` –
  default simulation path with optional step-by-step execution.
- `Future<Result<SimulationResult>> simulateDFA(...)` and
  `simulateNFA(...)` – type-specific simulation entry points.
- `Future<Result<bool>> accepts(...)` / `rejects(...)` – quick acceptance
  checks.
- `Future<Result<Set<String>>> findAcceptedStrings(...)` and
  `findRejectedStrings(...)` – enumerate sample strings up to configurable
  limits.

`SimulationRequest` packages the automaton, input string, optional timeouts,
and enumeration bounds used by the helpers.

### ConversionService

Wraps the suite of conversion algorithms exposed in `core/algorithms`.

- Automaton-focused: `convertNfaToDfa`, `minimizeDfa`, `convertRegexToNfa`,
  `convertFaToRegex`.
- Grammar/PDA integrations: `convertFsaToGrammar`, `convertGrammarToFsa`,
  `convertGrammarToPda`, `convertGrammarToPdaStandard`,
  `convertGrammarToPdaGreibach`, and `convertPdaToCfg` (via
  `ConversionType`-specific request routing).

Each method expects a `ConversionRequest` describing the source artefact and
desired `ConversionType`, returning a `Result` that mirrors success/error
states from the underlying algorithm.

### TracePersistenceService (Data Layer)

Serviço de dados voltado a `SharedPreferences` que grava histórico e metadados
de traços segmentados por tipo e identificador de autômato. Complementa o
notificador unificado oferecendo serialização resiliente e operações de
importação/exportação.

#### Responsabilidades na camada de dados

- **Histórico segmentado** – `getTraceHistory`, `getTracesForType` e
  `getTracesForAutomaton` retornam subconjuntos filtrados para dashboards e
  replays.
- **Traço atual** – `saveCurrentTrace` e `getCurrentTrace` preservam posição do
  passo ativo para retomadas instantâneas no modo passo a passo.
- **Metadados e estatísticas** – `saveTraceMetadata` e
  `getTraceStatistics` sintetizam contagens de execuções aceitas/rejeitadas e
  distribuição por tipo de simulador.
- **Portabilidade** – `exportTraceHistory` e `importTraceHistory` geram JSON
  autocontido com histórico e metadados para backup ou suporte.

#### Métodos principais da camada de dados

- `saveTraceToHistory(trace, automatonType: ..., automatonId: ...)` – adiciona o
  traço ao histórico respeitando o limite máximo de itens.
- `getTraceById(traceId)` – localiza o traço solicitado com metadados completos
  para hidratar o estado do `UnifiedTraceNotifier`.
- `clearAllTraces()` – remove histórico, traço atual e metadados armazenados.

#### Exemplo prático – compilar estatísticas para o painel

```dart
final persistence = ref.read(dataTracePersistenceServiceProvider);
final stats = await persistence.getTraceStatistics();

setState(() {
  totalExecutions = stats['totalTraces'] as int;
  acceptedRatio = stats['acceptedTraces'] / totalExecutions;
});
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

### GraphView Canvas Integration

```dart
// Obtain a GraphView controller scoped to the current provider
final graphController = ref.watch(graphViewCanvasControllerProvider);

// Trigger a fit-to-content after a state mutation
ref.listen<AutomatonState>(automatonProvider, (previous, next) {
  if (previous?.currentAutomaton != next.currentAutomaton) {
    graphController.synchronize(next.currentAutomaton);
    graphController.fitToContent();
  }
});
```

### Aplicando layouts automáticos com LayoutRepository

```dart
final layoutRepository = getIt<LayoutRepository>();
final automaton = ref.read(automatonProvider).currentAutomaton;

if (automaton != null) {
  final result = await layoutRepository.applyHierarchicalLayout(automaton);
  result.when(
    success: (updated) =>
        ref.read(automatonProvider.notifier).replaceCurrentAutomaton(updated),
    failure: (error) => showError(context, error.message),
  );
}
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

### State Management Guidelines

```dart
// Watch state changes
final state = ref.watch(automatonProvider);

// Listen to specific properties
final automaton = ref.watch(
  automatonProvider.select((s) => s.currentAutomaton),
);
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
- Automated test coverage is temporarily unavailable during the algorithm
  migration; run `flutter analyze` instead until the new suites land.
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

## Core Services

### TracePersistenceService (Core Layer)

Serviço de domínio focado em persistir execuções de simulação com tratamento de
erros explícito e suporte a exportação/importação por arquivo. É utilizado por
camadas que necessitam de maior controle sobre limites de histórico e
reaproveitamento de traços em dispositivos fora de `SharedPreferences`.

#### Responsabilidades na camada de domínio

- **Persistência local** – `saveTrace` mantém histórico circular e traço atual,
  garantindo limpeza automática via `_cleanupHistory`.
- **Recuperação robusta** – `loadCurrentTrace`, `loadTraceHistory` e
  `loadTraceById` retornam objetos `SimulationResult` completos com tratamento
  de exceções dedicadas (`TracePersistenceException`,
  `TraceNotFoundException`).
- **Portabilidade por arquivo** – `exportTraceToFile` cria JSON em diretório de
  documentos e `importTraceFromFile` reidrata traços compartilhados manualmente.
- **Configuração de políticas** – `setMaxHistorySize` expõe ajuste de retenção
  por perfil de uso avançado.

#### Métodos principais na camada de domínio

- `deleteTrace(traceId)` – remove entradas específicas preservando consistência
  do JSON serializado.
- `clearHistory()` – zera histórico e traço atual em uma única chamada.
- `getMaxHistorySize()` – retorna o limite configurado, usando
  `_defaultMaxHistory` como fallback resiliente.

#### Exemplo prático – exportar traço aceito para suporte

```dart
final coreTraceService = TracePersistenceService();
final trace = await coreTraceService.loadCurrentTrace();

if (trace != null && trace.accepted) {
  final path = await coreTraceService.exportTraceToFile(trace);
  await shareTraceFile(path);
}
```

## Core Repositories

### LayoutRepository

Interface do domínio responsável por aplicar heurísticas de posicionamento ao
autômato em edição, sempre retornando `AutomatonResult` para manter tratamento
de sucesso/erro unificado.

#### Responsabilidades de layout

- **Heurísticas variadas** – métodos `applyCompactLayout`,
  `applyBalancedLayout`, `applySpreadLayout` e `applyAutoLayout` organizam os
  estados conforme padrões radial, grade balanceada, anéis concêntricos ou
  espiral dourada.
- **Layout hierárquico** – `applyHierarchicalLayout` percorre o grafo em largura
  a partir do estado inicial para alinhar camadas, útil para máquinas com fluxo
  direcional claro.
- **Centragem geométrica** – `centerAutomaton` reposiciona o autômato sem
  alterar distâncias relativas, preparando o canvas para exportações.

#### Fluxos de uso

- **Aplicação automática** – `applyAutoLayout` é acionado quando o usuário
  seleciona o botão de auto-organização no canvas, atualizando o provider com o
  resultado retornado.
- **Layout hierárquico explícito** – usado em autômatos derivados de gramáticas
  ou PDA para evidenciar níveis de derivação. Após a conversão, o provider chama
  `applyHierarchicalLayout` antes de renderizar.
- **Recentralização** – `centerAutomaton` é empregado após operações de
  importação que trazem coordenadas deslocadas, garantindo visualização dentro
  dos limites do canvas.

#### Exemplo prático – reforçar hierarquia antes de exportar

```dart
final layoutRepository = getIt<LayoutRepository>();
final automaton = ref.read(automatonProvider).currentAutomaton;

if (automaton != null) {
  final layoutResult =
      await layoutRepository.applyHierarchicalLayout(automaton);
  layoutResult.when(
    success: (updated) async {
      await exportAutomaton(updated);
    },
    failure: (error) => showError(context, error.message),
  );
}
```
