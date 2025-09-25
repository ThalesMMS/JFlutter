# Tasks: JFlutter Core Expansion and Interoperability

**Input**: Design documents from `/specs/003-jflutter-core-expansion/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/, quickstart.md

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Flutter mobile app**: Clean architecture with packages/
- **Core packages**: packages/core_fa, packages/core_pda, packages/core_tm, packages/core_regex
- **Utility packages**: packages/conversions, packages/serializers, packages/viz, packages/playground
- **Main app**: lib/ with presentation/core/data layers

## Phase 3.1: Setup
- [ ] T001 Create Flutter project structure with clean architecture and package organization
- [ ] T002 Initialize Flutter project with Riverpod, freezed, json_serializable, very_good_analysis, PetitParser dependencies
- [ ] T003 [P] Configure linting (very_good_analysis) and formatting tools with pre-commit hooks
- [ ] T004 [P] Set up clean architecture folder structure (presentation/core/data) in lib/
- [ ] T005 [P] Create packages directory structure for core_fa, core_pda, core_tm, core_regex, conversions, serializers, viz, playground

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T006 [P] Contract test GET /automata endpoint in test/contract/test_automata_get.dart
- [ ] T007 [P] Contract test POST /automata endpoint in test/contract/test_automata_post.dart
- [ ] T008 [P] Contract test GET /automata/{id} endpoint in test/contract/test_automata_get_by_id.dart
- [ ] T009 [P] Contract test PUT /automata/{id} endpoint in test/contract/test_automata_put.dart
- [ ] T010 [P] Contract test DELETE /automata/{id} endpoint in test/contract/test_automata_delete.dart
- [ ] T011 [P] Contract test POST /automata/{id}/simulate endpoint in test/contract/test_automata_simulate.dart
- [ ] T012 [P] Contract test POST /automata/{id}/algorithms endpoint in test/contract/test_automata_algorithms.dart
- [ ] T013 [P] Contract test POST /automata/operations endpoint in test/contract/test_automata_operations.dart
- [ ] T014 [P] Contract test POST /import/jff endpoint in test/contract/test_import_jff.dart
- [ ] T015 [P] Contract test GET /export/{id}/jff endpoint in test/contract/test_export_jff.dart
- [ ] T016 [P] Contract test GET /export/{id}/json endpoint in test/contract/test_export_json.dart
- [ ] T017 [P] Integration test finite automata language operations in test/integration/test_fa_language_operations.dart
- [ ] T018 [P] Integration test pushdown automata simulation in test/integration/test_pda_simulation.dart
- [ ] T019 [P] Integration test regex processing pipeline in test/integration/test_regex_processing.dart
- [ ] T020 [P] Integration test Turing machine simulation in test/integration/test_tm_simulation.dart
- [ ] T021 [P] Integration test JFLAP file interoperability in test/integration/test_jflap_interop.dart
- [ ] T022 [P] Widget test automaton canvas in test/widget/test_automaton_canvas.dart

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T023 [P] Core entity models with freezed in packages/core_fa/lib/models/ (State, Transition, Alphabet, AutomatonMetadata)
- [ ] T024 [P] FiniteAutomaton model in packages/core_fa/lib/models/finite_automaton.dart
- [ ] T025 [P] PushdownAutomaton model in packages/core_pda/lib/models/pushdown_automaton.dart
- [ ] T026 [P] TuringMachine model in packages/core_tm/lib/models/turing_machine.dart
- [ ] T027 [P] ContextFreeGrammar model in packages/core_regex/lib/models/context_free_grammar.dart
- [ ] T028 [P] RegularExpression model in packages/core_regex/lib/models/regular_expression.dart
- [ ] T029 [P] Configuration model in packages/core_fa/lib/models/configuration.dart
- [ ] T030 [P] Trace model in packages/core_fa/lib/models/trace.dart
- [ ] T031 [P] ExecutionReport model in packages/core_fa/lib/models/execution_report.dart
- [ ] T032 [P] AlgorithmResult model in packages/core_fa/lib/models/algorithm_result.dart
- [ ] T033 [P] AutomatonSchema model in packages/serializers/lib/models/automaton_schema.dart
- [ ] T034 [P] JFLAPFile model in packages/serializers/lib/models/jflap_file.dart
- [ ] T035 [P] ExampleLibrary model in packages/serializers/lib/models/example_library.dart
- [ ] T036 [P] PackageAPI model in packages/playground/lib/models/package_api.dart
- [ ] T037 [P] JSON serialization with json_serializable in packages/serializers/lib/serializers/
- [ ] T038 [P] Language operation algorithms in packages/conversions/lib/algorithms/language_operations.dart
- [ ] T039 [P] NFA to DFA conversion algorithm in packages/conversions/lib/algorithms/nfa_to_dfa.dart
- [ ] T040 [P] DFA minimization algorithm in packages/conversions/lib/algorithms/dfa_minimization.dart
- [ ] T041 [P] Regex to NFA conversion algorithm in packages/conversions/lib/algorithms/regex_to_nfa.dart
- [ ] T042 [P] FA to Regex conversion algorithm in packages/conversions/lib/algorithms/fa_to_regex.dart
- [ ] T043 [P] CFG to PDA conversion algorithm in packages/conversions/lib/algorithms/cfg_to_pda.dart
- [ ] T044 [P] PDA to CFG conversion algorithm in packages/conversions/lib/algorithms/pda_to_cfg.dart
- [ ] T045 [P] Property checking algorithms in packages/conversions/lib/algorithms/property_checking.dart
- [ ] T046 [P] Pumping lemma algorithms in packages/conversions/lib/algorithms/pumping_lemma.dart

## Phase 3.4: Integration
- [ ] T047 [P] File I/O operations (.jff import/export) in packages/serializers/lib/repositories/
- [ ] T048 [P] Canvas rendering engine in packages/viz/lib/rendering/canvas_renderer.dart
- [ ] T049 [P] Touch gesture handling in packages/viz/lib/interactions/gesture_handler.dart
- [ ] T050 [P] Algorithm visualization and step-by-step execution in packages/viz/lib/visualizations/
- [ ] T051 [P] Mobile responsiveness and accessibility features in lib/presentation/widgets/
- [ ] T052 [P] Riverpod providers for state management in lib/presentation/providers/
- [ ] T053 [P] API service implementations in lib/data/services/
- [ ] T054 [P] Repository implementations in lib/data/repositories/

## Phase 3.5: Polish
- [ ] T055 [P] Golden tests for UI components in test/widget/
- [ ] T056 [P] Performance tests (60fps canvas, >10k simulation steps) in test/performance/
- [ ] T057 [P] Property-based tests for algorithms in test/property/
- [ ] T058 [P] Regression tests based on canonical examples in test/regression/
- [ ] T059 [P] Update README.md and API documentation
- [ ] T060 [P] Code cleanup and remove duplication
- [ ] T061 [P] Run flutter test --coverage and analyze
- [ ] T062 [P] Create Examples v1 canonical library with 10-20 basic examples
- [ ] T063 [P] Generate JSON schemas for all automaton types in packages/serializers/lib/schemas/
- [ ] T064 [P] Create playground demonstrations in packages/playground/lib/examples/

## Dependencies
- Tests (T006-T022) before implementation (T023-T054)
- T023 (core entities) blocks T024-T036 (specific models)
- T037 (JSON serialization) blocks T047 (file I/O)
- T038-T046 (algorithms) block T048-T050 (visualization)
- T052 (providers) blocks T053-T054 (services/repositories)
- Implementation before polish (T055-T064)

## Parallel Example
```
# Launch T006-T022 together (all contract and integration tests):
Task: "Contract test GET /automata endpoint in test/contract/test_automata_get.dart"
Task: "Contract test POST /automata endpoint in test/contract/test_automata_post.dart"
Task: "Contract test GET /automata/{id} endpoint in test/contract/test_automata_get_by_id.dart"
Task: "Contract test PUT /automata/{id} endpoint in test/contract/test_automata_put.dart"
Task: "Contract test DELETE /automata/{id} endpoint in test/contract/test_automata_delete.dart"
Task: "Contract test POST /automata/{id}/simulate endpoint in test/contract/test_automata_simulate.dart"
Task: "Contract test POST /automata/{id}/algorithms endpoint in test/contract/test_automata_algorithms.dart"
Task: "Contract test POST /automata/operations endpoint in test/contract/test_automata_operations.dart"
Task: "Contract test POST /import/jff endpoint in test/contract/test_import_jff.dart"
Task: "Contract test GET /export/{id}/jff endpoint in test/contract/test_export_jff.dart"
Task: "Contract test GET /export/{id}/json endpoint in test/contract/test_export_json.dart"
Task: "Integration test finite automata language operations in test/integration/test_fa_language_operations.dart"
Task: "Integration test pushdown automata simulation in test/integration/test_pda_simulation.dart"
Task: "Integration test regex processing pipeline in test/integration/test_regex_processing.dart"
Task: "Integration test Turing machine simulation in test/integration/test_tm_simulation.dart"
Task: "Integration test JFLAP file interoperability in test/integration/test_jflap_interop.dart"
Task: "Widget test automaton canvas in test/widget/test_automaton_canvas.dart"

# Launch T023-T036 together (all model creation):
Task: "Core entity models with freezed in packages/core_fa/lib/models/"
Task: "FiniteAutomaton model in packages/core_fa/lib/models/finite_automaton.dart"
Task: "PushdownAutomaton model in packages/core_pda/lib/models/pushdown_automaton.dart"
Task: "TuringMachine model in packages/core_tm/lib/models/turing_machine.dart"
Task: "ContextFreeGrammar model in packages/core_regex/lib/models/context_free_grammar.dart"
Task: "RegularExpression model in packages/core_regex/lib/models/regular_expression.dart"
Task: "Configuration model in packages/core_fa/lib/models/configuration.dart"
Task: "Trace model in packages/core_fa/lib/models/trace.dart"
Task: "ExecutionReport model in packages/core_fa/lib/models/execution_report.dart"
Task: "AlgorithmResult model in packages/core_fa/lib/models/algorithm_result.dart"
Task: "AutomatonSchema model in packages/serializers/lib/models/automaton_schema.dart"
Task: "JFLAPFile model in packages/serializers/lib/models/jflap_file.dart"
Task: "ExampleLibrary model in packages/serializers/lib/models/example_library.dart"
Task: "PackageAPI model in packages/playground/lib/models/package_api.dart"

# Launch T038-T046 together (all algorithm implementations):
Task: "Language operation algorithms in packages/conversions/lib/algorithms/language_operations.dart"
Task: "NFA to DFA conversion algorithm in packages/conversions/lib/algorithms/nfa_to_dfa.dart"
Task: "DFA minimization algorithm in packages/conversions/lib/algorithms/dfa_minimization.dart"
Task: "Regex to NFA conversion algorithm in packages/conversions/lib/algorithms/regex_to_nfa.dart"
Task: "FA to Regex conversion algorithm in packages/conversions/lib/algorithms/fa_to_regex.dart"
Task: "CFG to PDA conversion algorithm in packages/conversions/lib/algorithms/cfg_to_pda.dart"
Task: "PDA to CFG conversion algorithm in packages/conversions/lib/algorithms/pda_to_cfg.dart"
Task: "Property checking algorithms in packages/conversions/lib/algorithms/property_checking.dart"
Task: "Pumping lemma algorithms in packages/conversions/lib/algorithms/pumping_lemma.dart"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Follow Flutter/Dart conventions and clean architecture
- Use Riverpod for state management
- Implement immutable models with freezed
- Maintain 60fps performance and mobile-first design
- All algorithms must be deterministic with immutable traces

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Algorithms → Services → Integration → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [x] All contracts have corresponding tests
- [x] All entities have model tasks
- [x] All tests come before implementation
- [x] Parallel tasks truly independent
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] Package structure follows clean architecture
- [x] Mobile-first and educational focus maintained
- [x] Performance budgets and accessibility requirements included
