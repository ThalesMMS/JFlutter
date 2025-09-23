# Data Model: JFlutter Core Automata & Grammar Layer

**Last updated**: 2025-01-20  
**Scope**: Mirrors the concrete implementations that live under `lib/core/models`.

## Overview

The core models are organised around three pillars:

1. **Shared graph primitives** – `State`, `Transition` and `Automaton` define the common surface for every automaton-like structure. Their data includes spatial metadata (`Vector2`, `math.Rectangle`) that powers the mobile canvas, lifecycle timestamps and convenience accessors for derived analytics (reachability, counts, etc.).

2. **Domain specialisations** – `FSA`, `PDA`, `TM` and their transition variants extend the base types with alphabet constraints, stack/tape semantics and domain validation rules. Grammar parsing relies on `Grammar`, `Production`, `ParseTable` and two flavours of `ParseAction`.

3. **Support models** – Simulation (`SimulationStep`, `SimulationResult`), gameplay (`PumpingLemmaGame`, `PumpingAttempt`), analysis (`TMAnalysis`), interaction (`TouchInteraction`, `LayoutSettings`) and persistence preferences (`SettingsModel`) round out the UX-centric behaviour.

All classes favour immutable fields with `copyWith` helpers and JSON factories where serialisation is necessary.

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

### State
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Unique within the parent automaton. |
| `label` | `String` | User-visible label; `name` mirrors `label`. |
| `position` | `Vector2` | Canvas coordinates (>= 0 on both axes). |
| `isInitial` | `bool` | Marks the unique initial state. |
| `isAccepting` | `bool` | Marks accepting/final states. |
| `type` | `StateType` | Semantic hint (`normal`, `trap`, `accepting`, `initial`, `dead`). |
| `properties` | `Map<String, dynamic>` | Extension hook for automaton-specific metadata. |

### Transition
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Unique per automaton. |
| `fromState` / `toState` | `State` | Source and destination states. |
| `label` | `String` | Rendered caption for UI. |
| `controlPoint` | `Vector2` | Defaults to `Vector2.zero()`; offsets curved edges/self-loops. |
| `type` | `TransitionType` | Defaults to `TransitionType.deterministic`. |

## Specialised Automata Models

### FSA / FSATransition
- **FSA** inherits `Automaton` without extra fields
- **FSATransition** adds:
  - `inputSymbols` (`Set<String>`) - Symbols that trigger the transition
  - `lambdaSymbol` (`String?`) - Marks epsilon transitions when set

### PDA / PDATransition  
- **PDA** extends `Automaton` with:
  - `stackAlphabet` (`Set<String>`)
  - `initialStackSymbol` (`String`, default `'Z'`)
- **PDATransition** adds:
  - `inputSymbol`, `popSymbol`, `pushSymbol` (`String`)
  - `isLambdaInput`, `isLambdaPop`, `isLambdaPush` (`bool`)

### TM / TMTransition
- **TM** extends `Automaton` with:
  - `tapeAlphabet` (`Set<String>`)
  - `blankSymbol` (`String`, default `'B'`)
  - `tapeCount` (`int`, default `1`)
- **TMTransition** adds:
  - `readSymbol`, `writeSymbol` (`String`)
  - `direction` (`TapeDirection`)
  - `tapeNumber` (`int`, default `0`)

## Grammar Layer

### Grammar
| Field | Type | Notes |
| --- | --- | --- |
| `id`, `name` | `String` | Required identifiers |
| `terminals` | `Set<String>` | Terminal alphabet |
| `nonterminals` | `Set<String>` | Non-terminal alphabet |
| `startSymbol` | `String` | Must belong to `nonterminals` |
| `productions` | `Set<Production>` | Complete production set |
| `type` | `GrammarType` | `regular`, `contextFree`, `contextSensitive`, or `unrestricted` |

### Production
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Unique per grammar |
| `leftSide` | `List<String>` | Supports multi-symbol left-hand sides |
| `rightSide` | `List<String>` | Empty when `isLambda` is `true` |
| `isLambda` | `bool` | Indicates λ-production |
| `order` | `int` | Used for UI ordering |

### ParseTable
| Field | Type | Notes |
| --- | --- | --- |
| `actionTable` | `Map<String, Map<String, ParseAction>>` | LR/LL action matrix |
| `gotoTable` | `Map<String, Map<String, String>>` | Non-terminal transitions |
| `grammar` | `Grammar` | Grammar on which the table is built |
| `type` | `ParseType` | Parsing strategy |

## Simulation & Results

### SimulationResult
| Field | Type | Notes |
| --- | --- | --- |
| `inputString` | `String` | Input evaluated during simulation |
| `accepted` | `bool` | Outcome flag |
| `steps` | `List<SimulationStep>` | Detailed execution trace |
| `errorMessage` | `String` | Populated for failure/timeout/infinite-loop |
| `executionTime` | `Duration` | Total runtime |

### SimulationStep
| Field | Type | Notes |
| --- | --- | --- |
| `currentState` | `String` | Identifier of the active state |
| `remainingInput` | `String` | Unconsumed input suffix |
| `stackContents` | `String` | PDA stack snapshot |
| `tapeContents` | `String` | TM tape snapshot |
| `usedTransition` | `String?` | Applied transition identifier |
| `stepNumber` | `int` | 1-based index |

## Interaction & Layout

### TouchInteraction
| Field | Type | Notes |
| --- | --- | --- |
| `type` | `InteractionType` | Gesture classification |
| `position` | `Vector2` | Touch point |
| `selectedStates` | `Set<String>` | IDs of highlighted states |
| `selectedTransitions` | `Set<String>` | IDs of highlighted transitions |
| `timestamp` | `DateTime` | Interaction time |

### LayoutSettings
| Field | Type | Notes |
| --- | --- | --- |
| `nodeRadius` | `double` | Defaults to `20.0` |
| `edgeThickness` | `double` | Defaults to `2.0` |
| `colorScheme` | `ColorScheme` | Serialized by RGBA components |
| `showGrid` / `snapToGrid` | `bool` | UI toggles |
| `gridSize` | `double` | Grid spacing (default `20.0`) |

### SettingsModel
| Field | Type | Notes |
| --- | --- | --- |
| `emptyStringSymbol` | `String` | Defaults to `'λ'` |
| `epsilonSymbol` | `String` | Defaults to `'ε'` |
| `themeMode` | `String` | `'system'`, `'light'`, or `'dark'` |
| `showGrid` / `showCoordinates` | `bool` | Canvas preferences |
| `autoSave` | `bool` | Autosave toggle |
| `showTooltips` | `bool` | Tooltip visibility |
| `gridSize` | `double` | Defaults to `20.0` |
| `nodeSize` | `double` | Defaults to `30.0` |
| `fontSize` | `double` | Defaults to `14.0` |

## Educational Games

### PumpingLemmaGame
| Field | Type | Notes |
| --- | --- | --- |
| `automaton` | `FSA` | Machine underpinning the challenge |
| `pumpingLength` | `int` | The pumping constant |
| `challengeString` | `String` | Word chosen for the exercise |
| `attempts` | `List<PumpingAttempt>` | Attempt history |
| `isCompleted` | `bool` | Whether the game concluded |
| `score` / `maxScore` | `int` | Progress tracking (default max = 100) |

### PumpingAttempt
| Field | Type | Notes |
| --- | --- | --- |
| `x` / `y` / `z` | `String?` | Decomposition parts |
| `isCorrect` | `bool` | Outcome flag |
| `errorMessage` | `String?` | Explanation for incorrect attempts |
| `timestamp` | `DateTime` | Creation time |

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

## Validation Summary
1. **Automata**: must define at least one state, maintain consistent state references, respect zoom limits, and keep transition endpoints valid.
2. **FSA**: transitions must be `FSATransition` objects with coherent symbol sets; duplicate outgoing symbols indicate non-determinism.
3. **PDA**: require non-empty stack alphabets, valid initial stack symbols, and lambda flag consistency across transitions.
4. **TM**: enforce non-empty tape alphabets, valid blank symbols, minimum tape counts, and transition tape indices within range.
5. **Transitions**: IDs/labels must be non-empty; self-loops require explicit control points; epsilon settings must not conflict with symbol values.
6. **Grammars**: start symbols must be declared non-terminals, productions must reference declared symbols only, and each production must satisfy lambda/arity constraints.
7. **Simulation records**: maintain chronological steps with consistent identifiers and summarise execution metadata for reporting.

---
*This document reflects the concrete contracts available in `lib/core/models` so that feature work and external integrations stay aligned with the evolving code.*