# Reference Alignment: JFlutter Core Reinforcement Initiative

## Purpose
This document pairs each algorithm, simulator, and interoperability feature from the JFlutter reinforcement effort with the authoritative implementation kept in `References/`. It also records how we will validate our Dart/Flutter port against those sources during development.

## Reference Catalog
| Domain | Reference Source (absolute path) | Notes |
| --- | --- | --- |
| Finite Automata (DFA/NFA/λ-NFA) | /Users/thales/Documents/GitHub/jflutter/References/automata-main/automata/dfa/dfa.py<br>/Users/thales/Documents/GitHub/jflutter/References/automata-main/automata/nfa/nfa.py<br>/Users/thales/Documents/GitHub/jflutter/References/automata-main/automata/fa.py | Python implementations for conversions, Hopcroft minimization, closure properties; exposes deterministic checks and state/transition models. |
| FA Conversions (NFA→DFA UI sample) | /Users/thales/Documents/GitHub/jflutter/References/nfa_2_dfa-main/lib | Flutter demo showing state/transition modeling and conversion flows used for UI parity checks. |
| Regex → AST → Thompson NFA | /Users/thales/Documents/GitHub/jflutter/References/dart-petitparser-examples-main/lib/src/regex | PetitParser grammars and AST builders used to validate parser structure and Thompson construction. |
| CFG Toolkit & CYK | /Users/thales/Documents/GitHub/jflutter/References/automata-main/automata/cfg/cfg.py<br>/Users/thales/Documents/GitHub/jflutter/References/automata-main/automata/grammar/ | CNF transforms, useless symbol elimination, and CYK membership checks. |
| PDA Simulation & Determinism Checks | /Users/thales/Documents/GitHub/jflutter/References/automata-main/automata/pda/pda.py | Acceptance by final state, empty stack, or both; determinism validation and configuration stepping. |
| Turing Machine Simulation | /Users/thales/Documents/GitHub/jflutter/References/automata-main/automata/tm/tm.py<br>/Users/thales/Documents/GitHub/jflutter/References/turing-machine-generator-main/lib | Deterministic/Nondeterministic TM models and generator utilities for building traces and editing primitives. |
| Pumping Lemma Game & Automata Visualizations | /Users/thales/Documents/GitHub/jflutter/References/AutomataTheory-master/lib | Dart teaching library with canonical pumping lemma challenges and canvas interaction patterns. |
| Examples Library & Round-trip Artifacts | /Users/thales/Documents/GitHub/jflutter/References/automata-main/tests/data<br>/Users/thales/Documents/GitHub/jflutter/References/nfa_2_dfa-main/assets | Source `.jff`, JSON, and SVG artifacts for regression and interoperability tests. |

## Validation Plan
### Finite Automata
- **Scope**: Conversions (NFA→DFA, λ-NFA closure), Hopcroft minimization, regex↔automaton conversions, language operations (union, intersection, complement, concatenation, Kleene/star, reverse), property diagnostics (emptiness, finiteness, equivalence).
- **Reference usage**:
  1. Mirror the acceptance and minimization scenarios from `/Users/thales/Documents/GitHub/jflutter/References/automata-main/tests/automata/test_dfa.py` and `test_nfa.py` inside new Dart unit tests (see T004, T012).
  2. For each Dart algorithm implementation, generate `.dot`/transition representations and compare against serialized outputs from the Python library using golden fixtures.
  3. Use the Flutter sample in `/Users/thales/Documents/GitHub/jflutter/References/nfa_2_dfa-main/lib` to cross-check UI interaction constraints (state naming, epsilon handling) during widget tests (T010, T019).
- **Validation checkpoints**:
  - `test/unit/core/automata/fa_algorithms_test.dart` fails prior to implementation, then passes with identical traces as Python reference.
  - Determinism and language property checks verified against Python outputs via JSON traces stored in `test/fixtures/automata/` (new).

### Pushdown Automata
- **Scope**: Immutable PDA simulator, nondeterministic branching with trace folding, acceptance by final state / empty stack / both, determinism warnings.
- **Reference usage**:
  1. Replicate PDA acceptance scenarios from `/Users/thales/Documents/GitHub/jflutter/References/automata-main/tests/automata/test_pda.py` for stack discipline and deterministic edge cases.
  2. Leverage configuration stepping logic from `/Users/thales/Documents/GitHub/jflutter/References/automata-main/automata/pda/pda.py` to validate stack snapshots and transition guards.
- **Validation checkpoints**:
  - `test/unit/core/pda/pda_simulator_test.dart` asserts identical configuration sequences and acceptance results.
  - Trace-folding logic compares aggregated branches with Python reference outputs exported as JSON fixtures.

### Regex, Grammars, and CYK
- **Scope**: Regex parsing to AST, Thompson NFA construction, CFG normalization (ε, unit, useless removals), CFG↔PDA conversions, CYK parse trees.
- **Reference usage**:
  1. Use PetitParser grammars from `/Users/thales/Documents/GitHub/jflutter/References/dart-petitparser-examples-main/lib/src/regex` as baseline for parser structure and AST node taxonomy.
  2. Validate Thompson NFA edges by comparing with Python automata library conversions (exported from `/Users/thales/Documents/GitHub/jflutter/References/automata-main/automata/regex` if available) and with handcrafted fixtures from the spec.
  3. For CFG work, reuse CNF transformation tests in `/Users/thales/Documents/GitHub/jflutter/References/automata-main/tests/automata/test_cfg.py` and CYK acceptance data from `/Users/thales/Documents/GitHub/jflutter/References/automata-main/tests/automata/test_cyk.py`.
- **Validation checkpoints**:
  - Unit tests under `test/unit/core/regex/` and `test/unit/core/cfg/` assert structural equality with reference outputs.
  - Parse trees serialized as JSON are compared against Python-generated derivations for the same grammars.

### Turing Machines
- **Scope**: Deterministic and nondeterministic single-tape TM simulation, immutable configuration traces, time-travel UI hooks, editing building blocks.
- **Reference usage**:
  1. Adopt transition semantics and halting criteria from `/Users/thales/Documents/GitHub/jflutter/References/automata-main/automata/tm/tm.py`.
  2. Use generator blueprints in `/Users/thales/Documents/GitHub/jflutter/References/turing-machine-generator-main/lib` to validate tape editing primitives and ensure exported formats stay compatible.
  3. Import canonical machines from `/Users/thales/Documents/GitHub/jflutter/References/automata-main/tests/automata/test_tm.py` for integration tests.
- **Validation checkpoints**:
  - `test/unit/core/tm/tm_simulator_test.dart` reproduces step-by-step traces delivered by the Python reference.
  - UI/widget tests confirm trace navigation matches generator expectations (no state mutation outside providers).

### Pumping Lemma & Visualizations
- **Scope**: Interactive pumping lemma challenges for regular and context-free languages, canvas visualizations (FA/PDA/TM) with ≥60fps target.
- **Reference usage**:
  1. Use predefined language challenges and decomposition strategies from `/Users/thales/Documents/GitHub/jflutter/References/AutomataTheory-master/lib/implementations/pumping_lemma`.
  2. Carry over canvas interaction baselines from the same project to calibrate gesture and layout behaviour.
- **Validation checkpoints**:
  - `test/unit/presentation/pumping_lemma_game_test.dart` compares challenge progression and feedback messages with the reference definitions.
  - Golden tests assert canvas layout parity for the state diagrams provided by the reference assets.

### Interoperability & Examples Library
- **Scope**: `.jff`/JSON/SVG round-trip, offline "Examples v1" catalog, reference verifier service integrating Python outputs.
- **Reference usage**:
  1. Import `.jff` fixtures from `/Users/thales/Documents/GitHub/jflutter/References/automata-main/tests/data` to seed round-trip tests (T009, T021, T023).
  2. Reuse assets from `/Users/thales/Documents/GitHub/jflutter/References/nfa_2_dfa-main/assets` for UI smoke tests and to ensure examples render consistently across platforms.
  3. Implement the on-device verifier (T022) by invoking the Python algorithms through embedded fixtures and comparing hashed traces.
- **Validation checkpoints**:
  - Integration tests under `test/integration/io/examples_roundtrip_test.dart` confirm lossless serialization.
  - `lib/core/services/reference_verifier.dart` produces the same acceptance verdicts and traces as the Python sources for the shared fixture set.

## Maintenance
- Re-run upstream reference test suites (`pytest` in `automata-main`, `flutter test` in Dart projects) whenever references are updated to detect breaking changes before porting.
- Record any intentional deviations (e.g., performance optimizations, UI-driven constraints) in `/docs/reference-deviations.md` during implementation tasks (T029).
- Update this file if new reference repositories are added or existing paths change.
