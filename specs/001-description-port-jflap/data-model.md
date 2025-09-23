# Data Model: JFlutter

**Date**: 2025-01-18  
**Purpose**: Keep the conceptual data dictionary aligned with the implementations under `lib/core/models` after the latest weekly merges.

## Core Automata Layer

### Automaton
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Immutable unique identifier used across persistence and services. |
| `name` | `String` | Required display name. Empty names are rejected during validation. |
| `states` | `Set<State>` | Complete set of states belonging to the automaton. |
| `transitions` | `Set<Transition>` | All transitions between states (specialised per automaton subtype). |
| `alphabet` | `Set<String>` | Input alphabet; must not be empty. |
| `initialState` | `State?` | Nullable start state; when present it must belong to `states`. |
| `acceptingStates` | `Set<State>` | Final states; each entry must exist in `states`. |
| `type` | `AutomatonType` | Discriminator (`fsa`, `pda`, `tm`). |
| `created` / `modified` | `DateTime` | Timestamps maintained by persistence. |
| `bounds` | `math.Rectangle<double>` | Canvas rectangle used by the mobile layout engine. |
| `zoomLevel` | `double` | Defaults to `1.0`; validation enforces the inclusive range `[0.5, 3.0]`. |
| `panOffset` | `Vector2` | Defaults to `Vector2.zero()`; stores the current pan delta. |

**Validation** (see `Automaton.validate()`):
- ID and name must be non-empty.
- At least one state is required.
- `initialState`, when defined, must belong to `states`.
- Every state listed in `acceptingStates` must belong to `states`.
- Each transition must reference valid `fromState` and `toState` members.
- `zoomLevel` must be between `0.5` and `3.0` inclusive.

**Helper getters** (non-exhaustive): `isValid`, `stateCount`, `transitionCount`, `acceptingStateCount`, `hasInitialState`, `hasAcceptingStates`, `nonAcceptingStates`, `nonInitialStates`, `getTransitionsFrom`, `getTransitionsTo`.

### AutomatonType
| Value | Meaning | Convenience |
| --- | --- | --- |
| `fsa` | Finite State Automaton | `shortName` → `FSA` |
| `pda` | Pushdown Automaton | `hasStack` → `true` |
| `tm` | Turing Machine | `hasTape`/`hasOutput` → `true` |

### State
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Unique within the parent automaton. |
| `label` / `name` | `String` | User-visible label; `name` mirrors `label`. |
| `position` | `Vector2` | Canvas coordinates (>= 0 on both axes). |
| `isInitial` | `bool` | Marks the unique initial state. |
| `isAccepting` | `bool` | Marks accepting/final states. |
| `type` | `StateType` | Semantic hint (`normal`, `trap`, `accepting`, `initial`, `dead`). |
| `properties` | `Map<String, dynamic>` | Extension hook for automaton-specific metadata. |

**Validation**: `id` cannot be empty; `position` coordinates must be non-negative.

### StateType
- `normal`, `trap`, `accepting`, `initial`, `dead` with helper getters for `description`, `canBeAccepting`, and `canBeInitial`.

### Transition
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Unique per automaton. |
| `fromState` / `toState` | `State` | Source and destination states. |
| `label` | `String` | Rendered caption for UI. |
| `controlPoint` | `Vector2` | Defaults to `Vector2.zero()`; offsets curved edges/self-loops. |
| `type` | `TransitionType` | Defaults to `TransitionType.deterministic`. |

**Validation**: ID and label must be non-empty; self-loops require a non-zero `controlPoint`.

### TransitionType
- `deterministic`, `nondeterministic`, `epsilon` with helpers `description` and `allowsMultipleSymbols`.

### FSATransition
| Field | Type | Notes |
| --- | --- | --- |
| `inputSymbols` | `Set<String>` | Symbols that trigger the transition. |
| `lambdaSymbol` | `String?` | Marks epsilon transitions when set. |

**Derived**: `symbol`, `isEpsilonTransition`, `isDeterministic`, `isNondeterministic`, `acceptedSymbols`, symbol matching helpers.

**Validation**: either `inputSymbols` or `lambdaSymbol` must be set, not both; symbols cannot be empty strings.

### PDATransition
| Field | Type | Notes |
| --- | --- | --- |
| `inputSymbol` | `String` | Consumed input (alias getters `readSymbol`). |
| `popSymbol` | `String` | Stack symbol to pop (`stackPop`). |
| `pushSymbol` | `String` | Stack symbol to push (`stackPush`). |
| `isLambdaInput`/`isLambdaPop`/`isLambdaPush` | `bool` | Flags epsilon operations.

**Validation**: for each component either the symbol is non-empty or the corresponding lambda flag must be `true`; lambda flags and non-empty symbols are mutually exclusive.

### TMTransition
| Field | Type | Notes |
| --- | --- | --- |
| `readSymbol` | `String` | Symbol read from tape. |
| `writeSymbol` | `String` | Symbol written to tape. |
| `direction` | `TapeDirection` | Movement of the tape head. |
| `tapeNumber` | `int` | Defaults to `0`; non-negative. |

**Validation**: `readSymbol`/`writeSymbol` must be non-empty; `tapeNumber` must be ≥ 0.

### TapeDirection
Values: `left`, `right`, `stay` with helpers for `description`, `symbol`, and `opposite` direction.

### FSA / PDA / TM
- **FSA** inherits `Automaton` without extra fields. Validation ensures all transitions are `FSATransition` instances and flags repeated input symbols that make the machine non-deterministic.
- **PDA** extends `Automaton` with:
  - `stackAlphabet` (`Set<String>`) and `initialStackSymbol` (`String`, default `'Z'`).
  - Validation requires a non-empty stack alphabet, the initial stack symbol to belong to it, and every transition to be a valid `PDATransition`.
- **TM** extends `Automaton` with:
  - `tapeAlphabet` (`Set<String>`), `blankSymbol` (`String`, default `'B'`), and `tapeCount` (`int`, default `1`).
  - Validation enforces non-empty tape alphabet, blank symbol membership, `tapeCount ≥ 1`, transition type safety, valid tape symbols, and tape indices.

## Grammar Layer

### Grammar
| Field | Type | Notes |
| --- | --- | --- |
| `id`, `name` | `String` | Required identifiers; names cannot be empty. |
| `terminals` | `Set<String>` | Terminal alphabet. |
| `nonterminals` | `Set<String>` | Non-terminal alphabet (`nonTerminals` getter mirrors this). |
| `startSymbol` | `String` | Must belong to `nonterminals`. |
| `productions` | `Set<Production>` | Complete production set. |
| `type` | `GrammarType` | `regular`, `contextFree`, `contextSensitive`, or `unrestricted`. |
| `created` / `modified` | `DateTime` | Persistence metadata. |

**Validation**: IDs and names must be non-empty, the start symbol must belong to `nonterminals`, at least one production is required, and every production must reference only declared terminals/non-terminals. Production validation errors are prefixed with the production ID.

### GrammarType
Provides helpers for `description`, `shortName`, Chomsky hierarchy level, and capabilities (`supportsLeftRecursion`, `supportsLambdaProductions`).

### Production
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Unique per grammar. |
| `leftSide` | `List<String>` | Supports multi-symbol left-hand sides. |
| `rightSide` | `List<String>` | Empty when `isLambda` is `true`. |
| `isLambda` | `bool` | Indicates λ-production. |
| `order` | `int` | Used for UI ordering. |

**Validation**: ID and `leftSide` must be non-empty; lambda productions require empty `rightSide`, while non-lambda productions require non-empty `rightSide`; no empty symbols are permitted on either side.

**Derived helpers**: `isUnitProduction`, `isTerminalProduction`, `isBinaryProduction`, recursion checks, `stringRepresentation`, and `compactRepresentation`.

## Parsing Structures

### ParseTable
| Field | Type | Notes |
| --- | --- | --- |
| `actionTable` | `Map<String, Map<String, ParseAction>>` | LR/LL action matrix indexed by parser state and terminal. |
| `gotoTable` | `Map<String, Map<String, String>>` | Non-terminal transitions. |
| `grammar` | `Grammar` | Grammar on which the table is built. |
| `type` | `ParseType` | Parsing strategy. |

**Helpers**: `stateCount`, `terminalCount`, `nonterminalCount`, `states`, `terminals`, `nonterminals`, `getAction`, `getGoto`, `hasConflicts`, `conflicts`, `isValid`, formatted output, and factories (`empty`).

### ParseType
Values: `ll`, `lr`, `slr`, `lalr` with helpers for `description` and `shortName`.

### ParseAction
| Field | Type | Notes |
| --- | --- | --- |
| `type` | `ParseActionType` | `shift`, `reduce`, `accept`, or `error`. |
| `stateNumber` | `int?` | Shift target state. |
| `production` | `Production?` | Reduce production. |
| `errorMessage` | `String?` | Populated for error actions. |

Factory helpers: `shift(int)`, `reduce(Production)`, `accept()`, `error(String)` with JSON serialization support.

### ParseActionType
Provides human-readable `description` and short `symbol` (`s`, `r`, `acc`, `err`).

### ParseConflict
| Field | Type | Notes |
| --- | --- | --- |
| `state` | `String` | Parser state identifier. |
| `terminal` | `String` | Terminal symbol causing the conflict. |
| `type` | `ConflictType` | `shiftReduce`, `reduceReduce`, or `shiftShift`. |
| `actions` | `List<ParseAction>` | Conflicting actions. |

## Simulation Results

### SimulationResult
| Field | Type | Notes |
| --- | --- | --- |
| `inputString` | `String` | Input evaluated during simulation. |
| `accepted` | `bool` | Outcome flag; `isAccepted` getter mirrors it. |
| `steps` | `List<SimulationStep>` | Detailed execution trace. |
| `errorMessage` | `String` | Populated for failure/timeout/infinite-loop factories. |
| `executionTime` | `Duration` | Total runtime; exposed via `executionTimeMs`/`executionTimeSeconds`. |

Factory constructors: `success`, `failure`, `timeout`, `infiniteLoop`. Helpers expose `isSuccessful`, `isFailed`, `isTimeout`, `isInfiniteLoop`, trace aggregations (`visitedStates`, `usedTransitions`, `path`, `transitionSequence`, `inputSequence`).

### SimulationStep
| Field | Type | Notes |
| --- | --- | --- |
| `currentState` | `String` | Identifier of the active state. |
| `remainingInput` | `String` | Unconsumed input suffix. |
| `stackContents` | `String` | PDA stack snapshot. |
| `tapeContents` | `String` | TM tape snapshot. |
| `usedTransition` | `String?` | Identifier of the applied transition (when any). |
| `stepNumber` | `int` | 1-based index supplied by the simulator. |
| `description` | `String?` | Optional textual explanation. |
| `isAccepted` | `bool?` | Optional acceptance marker per step. |
| `inputSymbol` | `String?` | Symbol consumed during the step. |
| `nextState` | `String?` | Follow-up state identifier. |
| `consumedInput` | `String` | Portion of input consumed in this step. |

Helpers compute selection predicates (`isFirstStep`, `hasTransition`, etc.), string summaries, and accessors for stack/tape operations.

## Interaction & Layout Models

### TouchInteraction
| Field | Type | Notes |
| --- | --- | --- |
| `type` | `InteractionType` | Gesture classification. |
| `position` | `Vector2` | Touch point. |
| `selectedStates` | `Set<String>` | IDs of highlighted states. |
| `selectedTransitions` | `Set<String>` | IDs of highlighted transitions. |
| `timestamp` | `DateTime` | Interaction time; used to derive `age`, `isRecent`, `isOld`. |

Factory constructors exist for `tap`, `longPress`, `drag`, `pinch`, `pan`, `doubleTap`.

### InteractionType
Values: `tap`, `longPress`, `drag`, `pinch`, `pan`, `doubleTap` with helpers describing gestures, whether they require multiple fingers, and duration thresholds.

### LayoutSettings
| Field | Type | Notes |
| --- | --- | --- |
| `nodeRadius` | `double` | Defaults to `20.0`; `nodeDiameter` helper returns `2 * radius`. |
| `edgeThickness` | `double` | Defaults to `2.0`. |
| `colorScheme` | `ColorScheme` | Serialized by RGBA components. |
| `showGrid` / `snapToGrid` | `bool` | UI toggles; support snapping helpers. |
| `gridSize` | `double` | Grid spacing (default `20.0`). |

Helpers provide accessibility calculations, snap logic, and conversions between positions and grid cells. Factory constructors: `defaultSettings`, `mobileOptimized`, `highContrast` (see implementation for defaults).

### SettingsModel
| Field | Type | Notes |
| --- | --- | --- |
| `emptyStringSymbol` | `String` | Defaults to `'λ'`. |
| `epsilonSymbol` | `String` | Defaults to `'ε'`. |
| `themeMode` | `String` | `'system'`, `'light'`, or `'dark'`. |
| `showGrid` / `showCoordinates` | `bool` | Canvas preferences. |
| `autoSave` | `bool` | Autosave toggle. |
| `showTooltips` | `bool` | Tooltip visibility. |
| `gridSize` | `double` | Defaults to `20.0`. |
| `nodeSize` | `double` | Defaults to `30.0`. |
| `fontSize` | `double` | Defaults to `14.0`. |

## Educational Games

### PumpingLemmaGame
| Field | Type | Notes |
| --- | --- | --- |
| `automaton` | `FSA` | Machine underpinning the challenge. |
| `pumpingLength` | `int` | The pumping constant. |
| `challengeString` | `String` | Word chosen for the exercise. |
| `attempts` | `List<PumpingAttempt>` | Attempt history. |
| `isCompleted` | `bool` | Whether the game concluded. |
| `score` / `maxScore` | `int` | Progress tracking (default max = 100). |

Factory constructor `create` initialises an empty game. Helper getters expose counts, status (`status`, `isGameOver`), score percentage, and subsets of attempts.

### PumpingAttempt
| Field | Type | Notes |
| --- | --- | --- |
| `x` / `y` / `z` | `String?` | Decomposition parts; may be null for incorrect attempts. |
| `isCorrect` | `bool` | Outcome flag. |
| `errorMessage` | `String?` | Explanation for incorrect attempts. |
| `timestamp` | `DateTime` | Creation time. |

Factories: `correct` and `incorrect`. Helpers compute concatenations, pumped strings, lengths (`xyLength`, `yLength`), and provide `isValid` checks.

### GameStatus
Enum with values `inProgress`, `completed`, `failed`; helper `displayName` and `isFinished`.

## Data Relationships
- `Automaton` 1 ──▶ * `State`
- `Automaton` 1 ──▶ * `Transition`
- `FSA` 1 ──▶ * `FSATransition`
- `PDA` 1 ──▶ * `PDATransition`
- `TM` 1 ──▶ * `TMTransition`
- `Grammar` 1 ──▶ * `Production`
- `ParseTable` 1 ──▶ * `ParseAction`
- `SimulationResult` 1 ──▶ * `SimulationStep`
- `PumpingLemmaGame` 1 ──▶ * `PumpingAttempt`
- `TouchInteraction` references state/transition IDs indirectly (no strong foreign keys).

## Validation Summary
1. **Automata**: must define at least one state, maintain consistent state references, respect zoom limits, and keep transition endpoints valid.
2. **FSA**: transitions must be `FSATransition` objects with coherent symbol sets; duplicate outgoing symbols indicate non-determinism.
3. **PDA**: require non-empty stack alphabets, valid initial stack symbols, and lambda flag consistency across transitions.
4. **TM**: enforce non-empty tape alphabets, valid blank symbols, minimum tape counts, and transition tape indices within range.
5. **Transitions**: IDs/labels must be non-empty; self-loops require explicit control points; epsilon settings must not conflict with symbol values.
6. **Grammars**: start symbols must be declared non-terminals, productions must reference declared symbols only, and each production must satisfy lambda/arity constraints.
7. **Simulation records**: maintain chronological steps with consistent identifiers and summarise execution metadata for reporting.
