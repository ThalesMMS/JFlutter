# Reference Alignment: JFlutter Core Reinforcement Initiative

## Purpose
This document pairs each algorithm, simulator, and interoperability feature from the JFlutter reinforcement effort with the authoritative implementation kept in `References/`. It also records how we will validate our Dart/Flutter port against those sources during development.

## Reference Catalog
| Domain | Reference Source | Notes |
| --- | --- | --- |
| Finite Automata (DFA/NFA/λ-NFA) | [References/automata-main/automata/dfa/dfa.py](../References/automata-main/automata/dfa/dfa.py)<br>[References/automata-main/automata/nfa/nfa.py](../References/automata-main/automata/nfa/nfa.py)<br>[References/automata-main/automata/fa.py](../References/automata-main/automata/fa.py) | Python implementations for conversions, Hopcroft minimization, closure properties; exposes deterministic checks and state/transition models. |
| FA Conversions (NFA→DFA UI sample) | [References/nfa_2_dfa-main/lib](../References/nfa_2_dfa-main/lib) | Flutter demo showing state/transition modeling and conversion flows used for UI parity checks. |
| Regex → AST → Thompson NFA | [References/dart-petitparser-examples-main/lib/src/regex](../References/dart-petitparser-examples-main/lib/src/regex) | PetitParser grammars and AST builders used to validate parser structure and Thompson construction. |
| CFG Toolkit & CYK | [References/automata-main/automata/cfg/cfg.py](../References/automata-main/automata/cfg/cfg.py)<br>[References/automata-main/automata/grammar/](../References/automata-main/automata/grammar) | CNF transforms, useless symbol elimination, and CYK membership checks. |
| PDA Simulation & Determinism Checks | [References/automata-main/automata/pda/pda.py](../References/automata-main/automata/pda/pda.py) | Acceptance by final state, empty stack, or both; determinism validation and configuration stepping. |
| Turing Machine Simulation | [References/automata-main/automata/tm/tm.py](../References/automata-main/automata/tm/tm.py)<br>[References/turing-machine-generator-main/lib](../References/turing-machine-generator-main/lib) | Deterministic/Nondeterministic TM models and generator utilities for building traces and editing primitives. |
| Pumping Lemma Game & Automata Visualizations | [References/AutomataTheory-master/lib](../References/AutomataTheory-master/lib) | Dart teaching library with canonical pumping lemma challenges and canvas interaction patterns. |
| Examples Library & Round-trip Artifacts | [References/automata-main/tests/data](../References/automata-main/tests/data)<br>[References/nfa_2_dfa-main/assets](../References/nfa_2_dfa-main/assets) | Source `.jff`, JSON, and SVG artifacts for regression and interoperability tests. |

## Validation Plan

### Phase 1: Setup and Reference Mapping
- **Scope**: Establish verification framework using `References/automata-main` (primary) and `jflutter_js/examples` (supporting cases)
- **Reference usage**:
  1. Map 5 canonical test cases per algorithm type from Python reference tests
  2. Cross-reference with `jflutter_js/examples/` JSON artifacts for UI/export validation
  3. Create golden fixtures for deterministic comparison between Python and Dart implementations

### Finite Automata (DFA/NFA/λ-NFA)
- **Scope**: Conversions (NFA→DFA, λ-NFA closure), Hopcroft minimization, regex↔automaton conversions, language operations (union, intersection, complement, concatenation, Kleene/star, reverse), property diagnostics (emptiness, finiteness, equivalence).
- **Reference usage**:
  1. **Primary**: Mirror acceptance and minimization scenarios from [References/automata-main/tests/test_dfa.py](../References/automata-main/tests/test_dfa.py) and [References/automata-main/tests/test_nfa.py](../References/automata-main/tests/test_nfa.py) inside new Dart unit tests (T004, T005, T012, T013).
  2. **Supporting**: Validate against `jflutter_js/examples/` artifacts:
     - `afd_binary_divisible_by_3.json` - DFA divisibility by 3 (binary)
     - `afd_ends_with_a.json` - DFA string ending validation
     - `afd_parity_AB.json` - DFA parity checking
     - `afn_lambda_a_or_ab.json` - NFA with epsilon transitions
  3. **UI Integration**: Use Flutter sample in [References/nfa_2_dfa-main/lib](../References/nfa_2_dfa-main/lib) for UI interaction constraints (state naming, epsilon handling) during widget tests (T016).
- **Validation checkpoints**:
  - `test/unit/dfa_validation_test.dart` fails prior to implementation, then passes with identical traces as Python reference
  - `test/unit/nfa_validation_test.dart` validates epsilon closure and nondeterministic branching
  - Determinism and language property checks verified against Python outputs via JSON traces stored in `test/fixtures/automata/`
  - Round-trip validation: Dart → JSON → Python → JSON → Dart produces identical results

### Context-Free Grammars (CFG) and CYK
- **Scope**: CFG normalization (ε, unit, useless removals), CFG↔PDA conversions, CYK parse trees, CNF transformations.
- **Reference usage**:
  1. **Primary**: Reuse CNF transformation tests in [References/automata-main/tests/test_cfg.py](../References/automata-main/tests/test_cfg.py) and CYK acceptance data from [References/automata-main/tests/test_cyk.py](../References/automata-main/tests/test_cyk.py).
  2. **Supporting**: Validate against `jflutter_js/examples/` artifacts:
     - `glc_balanced_parentheses.json` - CFG for balanced parentheses
     - `glc_palindrome.json` - CFG for palindrome generation
  3. **Parser Integration**: Use PetitParser grammars from [References/dart-petitparser-examples-main/lib/src/regex](../References/dart-petitparser-examples-main/lib/src/regex) as baseline for parser structure and AST node taxonomy.
- **Validation checkpoints**:
  - `test/unit/glc_validation_test.dart` validates CFG parsing and CYK algorithm
  - `test/unit/cyk_validation_test.dart` ensures CNF parsing and derivation correctness
  - Parse trees serialized as JSON are compared against Python-generated derivations for the same grammars

### Pushdown Automata (PDA)
- **Scope**: Immutable PDA simulator, nondeterministic branching with trace folding, acceptance by final state / empty stack / both, determinism warnings.
- **Reference usage**:
  1. **Primary**: Replicate PDA acceptance scenarios from [References/automata-main/tests/test_pda.py](../References/automata-main/tests/test_pda.py) for stack discipline and deterministic edge cases.
  2. **Supporting**: Validate against `jflutter_js/examples/` artifacts:
     - `apda_palindrome.json` - PDA for palindrome recognition
  3. **Configuration Logic**: Leverage configuration stepping logic from [References/automata-main/automata/pda/pda.py](../References/automata-main/automata/pda/pda.py) to validate stack snapshots and transition guards.
- **Validation checkpoints**:
  - `test/unit/pda_validation_test.dart` asserts identical configuration sequences and acceptance results
  - Trace-folding logic compares aggregated branches with Python reference outputs exported as JSON fixtures

### Turing Machines (TM)
- **Scope**: Deterministic and nondeterministic single-tape TM simulation, immutable configuration traces, time-travel UI hooks, editing building blocks.
- **Reference usage**:
  1. **Primary**: Adopt transition semantics and halting criteria from [References/automata-main/automata/tm/tm.py](../References/automata-main/automata/tm/tm.py).
  2. **Supporting**: Validate against `jflutter_js/examples/` artifacts:
     - `tm_binary_to_unary.json` - TM for binary to unary conversion
  3. **Generator Integration**: Use generator blueprints in [References/turing-machine-generator-main/lib](../References/turing-machine-generator-main/lib) to validate tape editing primitives and ensure exported formats stay compatible.
  4. **Test Integration**: Import canonical machines from [References/automata-main/tests/test_tm.py](../References/automata-main/tests/test_tm.py) for integration tests.
- **Validation checkpoints**:
  - `test/unit/tm_validation_test.dart` reproduces step-by-step traces delivered by the Python reference
  - UI/widget tests confirm trace navigation matches generator expectations (no state mutation outside providers)

### Regex Processing
- **Scope**: Regex parsing to AST, Thompson NFA construction, regex↔automaton conversions.
- **Reference usage**:
  1. **Primary**: Validate Thompson NFA edges by comparing with Python automata library conversions from [References/automata-main/automata/regex](../References/automata-main/automata/regex).
  2. **Parser Integration**: Use PetitParser grammars from [References/dart-petitparser-examples-main/lib/src/regex](../References/dart-petitparser-examples-main/lib/src/regex) as baseline for parser structure and AST node taxonomy.
- **Validation checkpoints**:
  - `test/unit/regex_validation_test.dart` validates regex→NFA, FA→regex, and equivalence conversions
  - Unit tests under `test/unit/core/regex/` assert structural equality with reference outputs

### Pumping Lemma & Visualizations
- **Scope**: Interactive pumping lemma challenges for regular and context-free languages, canvas visualizations (FA/PDA/TM) with ≥60fps target.
- **Reference usage**:
  1. Use predefined language challenges and decomposition strategies from [References/AutomataTheory-master/lib/implementations/pumping_lemma](../References/AutomataTheory-master/lib/implementations/pumping_lemma).
  2. Carry over canvas interaction baselines from the same project to calibrate gesture and layout behaviour.
- **Validation checkpoints**:
  - `test/unit/presentation/pumping_lemma_game_test.dart` compares challenge progression and feedback messages with the reference definitions.
  - Golden tests assert canvas layout parity for the state diagrams provided by the reference assets.

### Interoperability & Examples Library
- **Scope**: `.jff`/JSON/SVG round-trip, offline "Examples v1" catalog, reference verifier service integrating Python outputs.
- **Reference usage**:
  1. Import `.jff` fixtures from [References/automata-main/tests/data](../References/automata-main/tests/data) to seed round-trip tests (T009, T021, T023).
  2. Reuse assets from [References/nfa_2_dfa-main/assets](../References/nfa_2_dfa-main/assets) for UI smoke tests and to ensure examples render consistently across platforms.
  3. Implement the on-device verifier (T022) by invoking the Python algorithms through embedded fixtures and comparing hashed traces.
- **Validation checkpoints**:
  - Integration tests under `test/integration/io/examples_roundtrip_test.dart` confirm lossless serialization.
  - `lib/core/services/reference_verifier.dart` produces the same acceptance verdicts and traces as the Python sources for the shared fixture set.

## Verification Matrix

### Test Case Mapping (5 cases per algorithm type)

| Algorithm Type | Python Reference | jflutter_js Examples | Dart Test File | Validation Focus |
|---|---|---|---|---|
| **DFA** | `test_dfa.py` | `afd_binary_divisible_by_3.json`<br>`afd_ends_with_a.json`<br>`afd_parity_AB.json` | `test/unit/dfa_validation_test.dart` | Acceptance, rejection, empty string, cycles, complementation |
| **NFA** | `test_nfa.py` | `afn_lambda_a_or_ab.json` | `test/unit/nfa_validation_test.dart` | Nondeterminism, epsilon transitions, acceptance, rejection, alphabet edge cases |
| **CFG** | `test_cfg.py` | `glc_balanced_parentheses.json`<br>`glc_palindrome.json` | `test/unit/glc_validation_test.dart` | Valid derivation, invalid derivation, CNF/CYK, left recursion, ambiguities |
| **TM** | `test_tm.py` | `tm_binary_to_unary.json` | `test/unit/tm_validation_test.dart` | Accept, reject, detectable loops, transformation, tape limits |
| **PDA** | `test_pda.py` | `apda_palindrome.json` | `test/unit/pda_validation_test.dart` | Simulation, CFG→PDA conversion |
| **Regex** | `test_regex.py` | N/A (algorithmic) | `test/unit/regex_validation_test.dart` | regex→NFA, FA→regex, equivalence |
| **CYK** | `test_cyk.py` | N/A (algorithmic) | `test/unit/cyk_validation_test.dart` | CNF parsing, derivation |
| **NFA→DFA** | `test_fa.py` | N/A (algorithmic) | `test/unit/nfa_to_dfa_validation_test.dart` | Conversion, equivalence |
| **DFA Minimization** | `test_dfa.py` | N/A (algorithmic) | `test/unit/dfa_minimization_validation_test.dart` | Minimization, equivalence |
| **Equivalence** | `test_fa.py` | N/A (algorithmic) | `test/unit/equivalence_validation_test.dart` | DFA≡DFA, NFA≡NFA |
| **Pumping Lemma** | N/A (theoretical) | N/A (theoretical) | `test/unit/pumping_lemma_validation_test.dart` | Proof, disproof, regularity |

### Performance Validation Targets
- **Canvas Performance**: ≥60fps for all visualizations
- **Simulation Performance**: p95 < 20ms for single steps
- **Memory Management**: No GC pauses > 50ms, memory usage < 400MB
- **Large Scale**: Support ≥10k simulation steps with throttling/batching
- **Offline Operation**: All algorithms work without network dependencies

### Round-trip Validation Protocol
1. **Dart → JSON**: Export current implementation to JSON format
2. **JSON → Python**: Import into Python automata library
3. **Python → JSON**: Export Python results to JSON
4. **JSON → Dart**: Import back into Dart implementation
5. **Compare**: Ensure identical traces and acceptance results

## Maintenance
- **Reference Updates**: Re-run upstream reference test suites (`pytest` in `automata-main`, `flutter test` in Dart projects) whenever references are updated to detect breaking changes before porting.
- **Deviation Tracking**: Record any intentional deviations (e.g., performance optimizations, UI-driven constraints) in [`docs/reference-deviations.md`](../docs/reference-deviations.md) during implementation tasks (T029).
- **Documentation Updates**: Update this file if new reference repositories are added or existing paths change.
- **Example Validation**: Regularly validate `jflutter_js/examples/` artifacts against current implementation to ensure UI/export compatibility.
