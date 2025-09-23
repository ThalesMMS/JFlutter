# Data Model: JFlutter Core Automata & Grammar Layer

**Last updated**: 2025-01-20  
**Scope**: Mirrors the concrete implementations that live under `lib/core/models`.

## Overview

The core models are organised around three pillars:

1. **Shared graph primitives** – `State`, `Transition` and `Automaton` define the common surface for every automaton-like structure. Their data includes spatial metadata (`Vector2`, `math.Rectangle`) that powers the mobile canvas, lifecycle timestamps and convenience accessors for derived analytics (reachability, counts, etc.).
2. **Domain specialisations** – `FSA`, `PDA`, `TM` and their transition variants extend the base types with alphabet constraints, stack/tape semantics and domain validation rules. Grammar parsing relies on `Grammar`, `Production`, `ParseTable` and two flavours of `ParseAction`.
3. **Support models** – Simulation (`SimulationStep`, `SimulationResult`), gameplay (`PumpingLemmaGame`, `PumpingAttempt`), analysis (`TMAnalysis`), interaction (`TouchInteraction`, `LayoutSettings`) and persistence preferences (`SettingsModel`) round out the UX-centric behaviour.

All classes favour immutable fields with `copyWith` helpers and JSON factories where serialisation is necessary.

## Shared graph primitives

### `State`
*File*: `lib/core/models/state.dart`

- **Properties**
  - `id`, `label` (`String` – label is mirrored as `name`), `position` (`Vector2`), `isInitial`, `isAccepting` (`bool`), `type` (`StateType`), `properties` (`Map<String, dynamic>`).
- **Validation** (`validate()`)
  - ID must not be empty.
  - Positions must be non-negative on both axes.
- **Notable helpers**
  - `copyWith`, JSON `toJson`/`fromJson`, spatial helpers (`distanceTo`, `overlapsWith`, `isWithinBounds`).
  - `StateType` enum + extension expose rich descriptions and semantic checks (e.g. `canBeAccepting`).

### `Transition`
*File*: `lib/core/models/transition.dart`

- **Properties**
  - `id`, `fromState`, `toState`, `label`, optional `controlPoint` (`Vector2.zero()` default), `type` (`TransitionType`).
- **Validation**
  - ID and label are required.
  - Self-loops must carry a non-zero control point.
- **Helpers**
  - Common geometry utilities (`arcLength`, `midpoint`, `angle`), `isSelfLoop`, convenience metrics for UI layouts.
  - Factory `Transition.fromJson` delegates to specialised subclasses.

### `Automaton`
*File*: `lib/core/models/automaton.dart`

- **Properties**
  - Identity & metadata: `id`, `name`, `type` (`AutomatonType`), `created`, `modified`.
  - Structure: `states`, `transitions`, `alphabet`, `initialState`, `acceptingStates`.
  - Canvas context: `bounds` (`math.Rectangle`), `zoomLevel` (default `1.0`, clamped 0.5–3.0), `panOffset` (`Vector2.zero()` default).
- **Validation** (`validate()`)
  - Non-empty ID/name/states.
  - `initialState`, `acceptingStates`, `transitions` must reference members of `states`.
  - `zoomLevel` constrained to `[0.5, 3.0]`.
- **Helpers**
  - Derived getters for counts, sets (e.g. `unreachableStates`, `deadStates`, `getTransitionsFrom`/`To`/`Between`).
  - Reachability analytics (`getReachableStates`, `isEmpty`, `isUniversal`).
  - `copyWith` contract enforced via subclass overrides; JSON handled by specific automata classes.
- **Enums**
  - `AutomatonType` (`fsa`, `pda`, `tm`) and descriptive extension (`description`, `shortName`).

## Automata specialisations

### Finite State Automata (`FSA`)
*File*: `lib/core/models/fsa.dart`

- Inherits the automaton surface; no extra stored fields.
- Overrides `copyWith`, `toJson`, `fromJson` to enforce the `'FSA'` discriminator and to instantiate `FSATransition`.
- **Validation** extends the base rules by asserting:
  - Every transition is an `FSATransition`.
  - Transitions validate individually (`FSATransition.validate`).
  - Deterministic conflicts are flagged when two outgoing edges from the same state share input symbols.
- Helpers group transitions (`fsaTransitions`, `epsilonTransitions`, `deterministicTransitions`, etc.) and provide lookup utilities (`getTransitionsFromStateOnSymbol`).

### `FSATransition`
*File*: `lib/core/models/fsa_transition.dart`

- Adds `inputSymbols` (`Set<String>`) and optional `lambdaSymbol`.
- `symbol` getter prioritises `lambdaSymbol` then first `inputSymbols` entry.
- **Validation** ensures mutually exclusive epsilon/input usage and non-empty symbols.
- Provides semantic checks (`isEpsilonTransition`, `acceptsSymbol`, determinism helpers) and dedicated factory `FSATransition.epsilon`.

### Pushdown Automata (`PDA`)
*File*: `lib/core/models/pda.dart`

- Extra fields: `stackAlphabet` (`Set<String>`), `initialStackSymbol` (default `'Z'`).
- **Validation** adds stack alphabet presence, initial stack symbol membership and stack symbol integrity across transitions.
- Helpers categorise transitions (`pdaTransitions`, `epsilonTransitions`, `inputTransitions`, `stackOnlyTransitions`) and provide filtered retrieval (e.g. `getTransitionsFromStateOnInput`).

### `PDATransition`
*File*: `lib/core/models/pda_transition.dart`

- Adds `inputSymbol`, `popSymbol`, `pushSymbol`, boolean flags `isLambdaInput/pop/push`.
- Offers alias getters (`readSymbol`, `stackPop`, `stackPush`).
- **Validation** enforces consistency between lambda flags and provided symbols.
- Behaviour helpers: `acceptsInput`, `canPop`, `canPush`, symbolic views (`symbolToPush`, `symbolToPop`, `effectiveInputSymbol`), `isEpsilonTransition`, plus factory constructors (`epsilon`, `readAndStack`, `readOnly`, `stackOnly`).

### Turing Machines (`TM`)
*File*: `lib/core/models/tm.dart`

- Additional properties: `tapeAlphabet` (`Set<String>`), `blankSymbol` (default `'B'`), `tapeCount` (default `1`).
- **Validation**
  - Tape alphabet non-empty; blank symbol present in alphabet.
  - `tapeCount >= 1`.
  - Transitions must be `TMTransition`, validate individually and respect alphabet/tape constraints.
- Helpers expose subsets (`tmTransitions`, `getTransitionsForTape`).

### `TMTransition`
*File*: `lib/core/models/tm_transition.dart`

- Adds `readSymbol`, `writeSymbol`, `direction` (`TapeDirection`), optional `tapeNumber` (default `0`).
- **Validation** enforces non-empty symbols and non-negative tape index.
- Convenience: `canRead`, `symbolToWrite`, directional booleans, factory `TMTransition.readWrite`.
- `TapeDirection` extension exposes motion semantics.

### `TMAnalysis`
*File*: `lib/core/models/tm_analysis.dart`

- Aggregates analytics across states (`TMStateAnalysis`), transitions (`TMTransitionAnalysis`), tape operations (`TapeAnalysis`) and reachability (`TMReachabilityAnalysis`), plus a runtime `executionTime`.
- Focused on structural reporting; no validation/JSON helpers yet.

## Grammar & parsing models

### `Grammar`
*File*: `lib/core/models/grammar.dart`

- Stores `id`, `name`, `terminals`, `nonterminals`, `startSymbol`, `productions`, `type` (`GrammarType`), timestamps.
- Provides `nonTerminals` getter for compatibility, plus metrics (`productionCount`, `terminalCount`, etc.).
- **Validation** checks ID/name/start symbol presence, start symbol membership, non-empty productions and symbol membership across productions.
- JSON serialisation supported via `toJson`/`fromJson`.

### `Production`
*File*: `lib/core/models/production.dart`

- Fields: `id`, `leftSide`, `rightSide`, `isLambda`, `order`.
- **Validation** ensures ID and `leftSide` exist, lambda semantics respected, no empty symbols.
- Provides numerous classification helpers (`isUnitProduction`, `hasLeftRecursion`, `stringRepresentation`, etc.) and JSON support.

### `ParseTable`
*File*: `lib/core/models/parse_table.dart`

- Holds `actionTable` (`Map<String, Map<String, ParseAction>>`), `gotoTable` (`Map<String, Map<String, String>>`), associated `Grammar`, `type` (`ParseType`).
- JSON serialisation available (`toJson`/`fromJson`).
- Derived metrics: counts (`stateCount`, `terminalCount`, `nonterminalCount`), convenience selectors (`getAction`, `getGoto`, `hasConflicts`, `conflicts`, `formattedTable`).
- Factory `ParseTable.empty` seeds placeholder instances.

#### Parse-table `ParseAction`
- Defined within `parse_table.dart` with fields `type`, `stateNumber`, `production`, `errorMessage`.
- Provides `copyWith`, JSON helpers, convenience factories (`shift`, `reduce`, `accept`, `error`).
- `ParseActionType` enum + extension yield textual descriptions and shorthand symbols.

#### Legacy `ParseAction`
*File*: `lib/core/models/parse_action.dart`

- Alternative representation used for algorithm prototyping: fields `type`, `state`, optional `symbol`, `production`, `nextState`.
- Convenience factories (`shift`, `reduce`, `accept`, `error`) mirror the parse-table version but without JSON serialization.
- Retained for parity with earlier parsing tasks; consolidate with the parse-table version before reuse to avoid naming collisions.

#### `ParseConflict`
- Encapsulates conflicting entries with `state`, `terminal`, `type` (`ConflictType`) and `actions`.
- `ConflictType` extension maps to human-readable labels.

## Simulation models

### `SimulationStep`
*File*: `lib/core/models/simulation_step.dart`

- Captures per-step state: `currentState`, `remainingInput`, `stackContents`, `tapeContents`, optional `usedTransition`, `description`, `isAccepted`, `inputSymbol`, `nextState`, plus `stepNumber` and `consumedInput`.
- JSON round-tripping supported.
- Helpers cover introspection (`hasTransition`, `hasStackOperations`, `summary`, etc.).

### `SimulationResult`
*File*: `lib/core/models/simulation_result.dart`

- Wraps an input run: `inputString`, `accepted`, `steps`, optional `errorMessage`, `executionTime`.
- Factory constructors for success/failure/timeout/infinite-loop scenarios standardise messaging.
- Derived insights include `stepCount`, `finalState`, `remainingInput`, classification flags (`isSuccessful`, `isTimeout`, etc.), and trace extraction (`visitedStates`, `transitionSequence`).
- JSON `toJson`/`fromJson` maintain compatibility with persistence.

## Pumping lemma gameplay

### `PumpingLemmaGame`
*File*: `lib/core/models/pumping_lemma_game.dart`

- Fields: `automaton` (`FSA`), `pumpingLength`, `challengeString`, `attempts`, `isCompleted`, `score`, `maxScore`.
- Factories: `create` initialises new sessions.
- Helpers compute attempt counts, remaining attempts, score percentage, status (`GameStatus` with extensions), segmentation of correct/incorrect attempts and `copyWith`.

### `PumpingAttempt`
*File*: `lib/core/models/pumping_attempt.dart`

- Fields: optional `x`, `y`, `z` substrings, `isCorrect`, optional `errorMessage`, `timestamp`.
- Factories `correct`/`incorrect` stamp attempts with `DateTime.now()`.
- Utilities: `decomposition`, `getPumpedString`, `isValid`, `xyLength`, `yLength`, `copyWith`.

## Interaction, layout & preferences

### `LayoutSettings`
*File*: `lib/core/models/layout_settings.dart`

- Controls canvas rendering: `nodeRadius`, `edgeThickness`, `colorScheme`, `showGrid`, `snapToGrid`, `gridSize`.
- Offers `copyWith`, JSON serialisation, geometric helpers (`nodeDiameter`, `gridStep`, `shouldSnapToGrid`, `snapPositionToGrid`).
- Accessibility convenience getters highlight recommended touch targets.

### `TouchInteraction`
*File*: `lib/core/models/touch_interaction.dart`

- Tracks gesture metadata: `type` (`InteractionType`), `position` (`Vector2`), selected IDs (`selectedStates`, `selectedTransitions`), `timestamp`.
- Provides JSON helpers, selection counters, gesture classification, age/recency helpers and convenience constructors (`tap`, `longPress`, `drag`, `pinch`, `pan`, `doubleTap`).
- `InteractionType` extension describes gestures, finger requirements, gesture/tap grouping and duration expectations.

### `SettingsModel`
*File*: `lib/core/models/settings_model.dart`

- Persisted preferences: `emptyStringSymbol`, `epsilonSymbol`, `themeMode`, `showGrid`, `showCoordinates`, `autoSave`, `showTooltips`, `gridSize`, `nodeSize`, `fontSize`.
- All fields default to sensible values for first-run experience and are immutable; `copyWith` allows partial updates.

## Example compositions

### Constructing a deterministic FSA
```dart
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';

final q0 = State(id: 'q0', label: 'q0', position: Vector2.zero(), isInitial: true);
final q1 = State(id: 'q1', label: 'q1', position: Vector2(120, 0), isAccepting: true);

final t0 = FSATransition(
  id: 't0',
  fromState: q0,
  toState: q1,
  label: 'a',
  inputSymbols: const {'a'},
);

final automaton = FSA(
  id: 'even-a',
  name: 'Even number of a',
  states: {q0, q1},
  transitions: {t0},
  alphabet: const {'a'},
  initialState: q0,
  acceptingStates: {q1},
  created: DateTime.now(),
  modified: DateTime.now(),
  bounds: const math.Rectangle(0, 0, 240, 120),
);

assert(automaton.validate().isEmpty);
assert(automaton.isDeterministic);
```

### Capturing a simulation trace
```dart
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';

final steps = [
  const SimulationStep(currentState: 'q0', remainingInput: 'aa', stepNumber: 1, inputSymbol: 'a', nextState: 'q1'),
  const SimulationStep(currentState: 'q1', remainingInput: 'a', stepNumber: 2, inputSymbol: 'a', nextState: 'q0'),
  const SimulationStep(currentState: 'q0', remainingInput: '', stepNumber: 3, isAccepted: true),
];

final result = SimulationResult.success(
  inputString: 'aa',
  steps: steps,
  executionTime: const Duration(milliseconds: 12),
);

assert(result.isSuccessful);
assert(result.visitedStates.contains('q1'));
```

## Validation highlights

- **Graphs**: Automata enforce membership constraints; states guard against negative coordinates; transitions require identifiers and control points for self-loops.
- **Specialisations**: Domain invariants (stack/tape alphabets, epsilon usage, determinism) are enforced through specialised `validate()` overrides.
- **Grammar**: Productions must reference known symbols; parse tables can surface conflicts through `hasConflicts`/`conflicts`.
- **Simulation & gameplay**: Factory constructors ensure consistent failure messaging; pumping lemma scoring stops after 5 attempts or a correct decomposition.
- **UX models**: Layout and interaction models expose helpers to keep gestures accessible and canvas settings consistent across sessions.

This document now reflects the concrete contracts available in `lib/core/models` so that feature work and external integrations stay aligned with the evolving code.
