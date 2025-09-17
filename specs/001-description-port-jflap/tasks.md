# Tasks: Port JFLAP to Flutter as JFlutter

**Input**: Design documents from `/specs/001-description-port-jflap/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

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
- **Mobile Flutter app**: `lib/`, `test/` at repository root
- Paths based on Flutter project structure from plan.md

## Phase 3.1: Setup
- [ ] T001 Create Flutter project structure per implementation plan
- [ ] T002 Initialize Flutter project with dependencies (flutter_gesture_detector, path_provider, shared_preferences, riverpod)
- [ ] T003 [P] Configure linting and formatting tools (analysis_options.yaml, dart format)
- [ ] T004 [P] Setup dependency injection with GetIt in lib/injection/dependency_injection.dart

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T005 [P] Contract test automaton CRUD operations in test/contract/test_automaton_contract.dart
- [ ] T006 [P] Contract test simulation operations in test/contract/test_simulation_contract.dart
- [ ] T007 [P] Contract test conversion algorithms in test/contract/test_conversion_contract.dart
- [ ] T008 [P] Integration test FSA creation and simulation in test/integration/test_fsa_creation.dart
- [ ] T009 [P] Integration test NFA to DFA conversion in test/integration/test_nfa_to_dfa.dart
- [ ] T010 [P] Integration test grammar creation and parsing in test/integration/test_grammar_parsing.dart
- [ ] T011 [P] Integration test file operations in test/integration/test_file_operations.dart
- [ ] T012 [P] Integration test mobile UI interactions in test/integration/test_mobile_ui.dart

## Phase 3.3: Core Implementation (ONLY after tests are failing)
### Data Models
- [ ] T013 [P] State model in lib/core/models/state.dart
- [ ] T014 [P] Transition model in lib/core/models/transition.dart
- [ ] T015 [P] FSATransition model in lib/core/models/fsa_transition.dart
- [ ] T016 [P] PDATransition model in lib/core/models/pda_transition.dart
- [ ] T017 [P] TMTransition model in lib/core/models/tm_transition.dart
- [ ] T018 [P] Automaton abstract model in lib/core/models/automaton.dart
- [ ] T019 [P] FSA model in lib/core/models/fsa.dart
- [ ] T020 [P] PDA model in lib/core/models/pda.dart
- [ ] T021 [P] TM model in lib/core/models/tm.dart
- [ ] T022 [P] Grammar model in lib/core/models/grammar.dart
- [ ] T023 [P] Production model in lib/core/models/production.dart
- [ ] T024 [P] SimulationResult model in lib/core/models/simulation_result.dart
- [ ] T025 [P] SimulationStep model in lib/core/models/simulation_step.dart
- [ ] T026 [P] ParseTable model in lib/core/models/parse_table.dart
- [ ] T027 [P] TouchInteraction model in lib/core/models/touch_interaction.dart
- [ ] T028 [P] LayoutSettings model in lib/core/models/layout_settings.dart

### Core Algorithms
- [ ] T029 [P] NFA to DFA conversion algorithm in lib/core/algorithms/nfa_to_dfa_converter.dart
- [ ] T030 [P] DFA minimization algorithm in lib/core/algorithms/dfa_minimizer.dart
- [ ] T031 [P] Regular expression to NFA algorithm in lib/core/algorithms/regex_to_nfa_converter.dart
- [ ] T032 [P] FA to Regular Expression algorithm in lib/core/algorithms/fa_to_regex_converter.dart
- [ ] T033 [P] Automaton simulator in lib/core/algorithms/automaton_simulator.dart
- [ ] T034 [P] Grammar parser (LL) in lib/core/algorithms/ll_parser.dart
- [ ] T035 [P] Grammar parser (LR/SLR) in lib/core/algorithms/lr_parser.dart
- [ ] T036 [P] CYK parser in lib/core/algorithms/cyk_parser.dart
- [ ] T037 [P] Brute force parser for unrestricted grammars in lib/core/algorithms/brute_force_parser.dart
- [ ] T038 [P] Grammar transformer (CNF) in lib/core/algorithms/grammar_transformer.dart
- [ ] T039 [P] CFG to PDA converter (LL method) in lib/core/algorithms/cfg_to_pda_ll.dart
- [ ] T040 [P] PDA to CFG converter in lib/core/algorithms/pda_to_cfg.dart
- [ ] T041 [P] CFG to PDA converter (LR method) in lib/core/algorithms/cfg_to_pda_lr.dart
- [ ] T042 [P] Right-linear grammar to FA converter in lib/core/algorithms/right_linear_to_fa.dart
- [ ] T043 [P] Pumping lemma game engine for regular languages in lib/core/algorithms/pumping_lemma_regular.dart
- [ ] T044 [P] Pumping lemma game engine for context-free languages in lib/core/algorithms/pumping_lemma_cfg.dart
- [ ] T045 [P] L-system interpreter and visualizer in lib/core/algorithms/lsystem_interpreter.dart

### Services
- [ ] T046 [P] AutomatonService CRUD in lib/data/services/automaton_service.dart
- [ ] T047 [P] GrammarService CRUD in lib/data/services/grammar_service.dart
- [ ] T048 [P] FileService for persistence in lib/data/services/file_service.dart
- [ ] T049 [P] SimulationService in lib/data/services/simulation_service.dart
- [ ] T050 [P] ConversionService for algorithms in lib/data/services/conversion_service.dart
- [ ] T051 [P] LSystemService for L-system management in lib/data/services/lsystem_service.dart
- [ ] T052 [P] BuildingBlockService for Turing machine blocks in lib/data/services/building_block_service.dart
- [ ] T053 [P] PumpingLemmaGameService for interactive games in lib/data/services/pumping_lemma_game_service.dart
- [ ] T054 [P] MealyMachineService for Mealy machine operations in lib/data/services/mealy_machine_service.dart

## Phase 3.4: Presentation Layer (UI Implementation)
### Widgets
- [ ] T055 [P] StateWidget for displaying states in lib/presentation/widgets/state_widget.dart
- [ ] T056 [P] TransitionWidget for displaying transitions in lib/presentation/widgets/transition_widget.dart
- [ ] T057 [P] AutomatonCanvas for rendering automata in lib/presentation/widgets/automaton_canvas.dart
- [ ] T058 [P] TouchGestureHandler for mobile interactions in lib/presentation/widgets/touch_gesture_handler.dart
- [ ] T059 [P] GrammarTable for editing grammars in lib/presentation/widgets/grammar_table.dart
- [ ] T060 [P] SimulationPanel for displaying results in lib/presentation/widgets/simulation_panel.dart
- [ ] T061 [P] ConversionDialog for algorithm operations in lib/presentation/widgets/conversion_dialog.dart
- [ ] T062 [P] PumpingLemmaGameWidget for interactive games in lib/presentation/widgets/pumping_lemma_game_widget.dart
- [ ] T063 [P] LSystemVisualizer for fractal visualization in lib/presentation/widgets/lsystem_visualizer.dart
- [ ] T064 [P] BuildingBlockEditor for Turing machine blocks in lib/presentation/widgets/building_block_editor.dart
- [ ] T065 [P] MealyMachineWidget for Mealy machine display in lib/presentation/widgets/mealy_machine_widget.dart
- [ ] T066 [P] ParseTableWidget for parsing table visualization in lib/presentation/widgets/parse_table_widget.dart
- [ ] T067 [P] DerivationTreeWidget for grammar derivation trees in lib/presentation/widgets/derivation_tree_widget.dart

### Pages
- [ ] T068 [P] HomePage with navigation in lib/presentation/pages/home_page.dart
- [ ] T069 [P] AutomatonEditorPage in lib/presentation/pages/automaton_editor_page.dart
- [ ] T070 [P] GrammarEditorPage in lib/presentation/pages/grammar_editor_page.dart
- [ ] T071 [P] SimulationPage in lib/presentation/pages/simulation_page.dart
- [ ] T072 [P] LSystemPage for L-system creation and visualization in lib/presentation/pages/lsystem_page.dart
- [ ] T073 [P] TuringMachinePage for TM with building blocks in lib/presentation/pages/turing_machine_page.dart
- [ ] T074 [P] MealyMachinePage for Mealy machine editing in lib/presentation/pages/mealy_machine_page.dart
- [ ] T075 [P] PumpingLemmaPage for interactive games in lib/presentation/pages/pumping_lemma_page.dart
- [ ] T076 [P] HelpPage with documentation in lib/presentation/pages/help_page.dart
- [ ] T077 [P] SettingsPage for app configuration in lib/presentation/pages/settings_page.dart

### Providers (State Management)
- [ ] T078 [P] AutomatonProvider with Riverpod in lib/presentation/providers/automaton_provider.dart
- [ ] T079 [P] GrammarProvider with Riverpod in lib/presentation/providers/grammar_provider.dart
- [ ] T080 [P] SimulationProvider with Riverpod in lib/presentation/providers/simulation_provider.dart
- [ ] T081 [P] NavigationProvider with Riverpod in lib/presentation/providers/navigation_provider.dart
- [ ] T082 [P] LayoutProvider for mobile layout in lib/presentation/providers/layout_provider.dart
- [ ] T083 [P] LSystemProvider for L-system state management in lib/presentation/providers/lsystem_provider.dart
- [ ] T084 [P] BuildingBlockProvider for Turing machine blocks in lib/presentation/providers/building_block_provider.dart
- [ ] T085 [P] PumpingLemmaGameProvider for game state in lib/presentation/providers/pumping_lemma_game_provider.dart
- [ ] T086 [P] MealyMachineProvider for Mealy machine state in lib/presentation/providers/mealy_machine_provider.dart

## Phase 3.5: Integration
- [ ] T087 Connect AutomatonService to FileService
- [ ] T088 Connect GrammarService to FileService
- [ ] T089 Connect SimulationService to AutomatonService
- [ ] T090 Connect ConversionService to AutomatonService
- [ ] T091 Connect LSystemService to FileService
- [ ] T092 Connect BuildingBlockService to FileService
- [ ] T093 Connect PumpingLemmaGameService to FileService
- [ ] T094 Connect MealyMachineService to FileService
- [ ] T095 Mobile gesture recognition integration
- [ ] T096 Accessibility features integration (WCAG 2.1 AA)
- [ ] T097 File format compatibility with JFLAP desktop
- [ ] T098 Performance optimization for large automata
- [ ] T099 L-system rendering performance optimization
- [ ] T100 Interactive game responsiveness optimization

## Phase 3.6: Polish
- [ ] T101 [P] Unit tests for all models in test/unit/models/
- [ ] T102 [P] Unit tests for all algorithms in test/unit/algorithms/
- [ ] T103 [P] Unit tests for all services in test/unit/services/
- [ ] T104 [P] Widget tests for all UI components in test/widget/
- [ ] T105 Performance tests for large automata (<500ms for <50 states)
- [ ] T106 Performance tests for L-systems (<2s for 1000 iterations)
- [ ] T107 Performance tests for pumping lemma games (<100ms response)
- [ ] T108 [P] Update documentation in README.md
- [ ] T109 [P] Create user manual in docs/user_manual.md
- [ ] T110 [P] Create developer guide in docs/developer_guide.md
- [ ] T111 [P] Create algorithm documentation in docs/algorithms.md
- [ ] T112 Remove code duplication and optimize
- [ ] T113 Run quickstart.md validation scenarios
- [ ] T114 Final integration testing and bug fixes

## Dependencies
- Tests (T005-T012) before implementation (T013-T114)
- T013-T028 (models) before T046-T054 (services)
- T029-T045 (algorithms) before T055-T067 (UI)
- T046-T054 (services) before T087-T100 (integration)
- T087-T100 (integration) before T101-T114 (polish)
- T013 blocks T019-T021 (automaton types)
- T014 blocks T015-T017 (transition types)
- T055-T057 blocks T068-T077 (pages)
- T078-T086 blocks T095-T096 (mobile features)

## Parallel Examples
```
# Launch T005-T012 together (Contract and Integration Tests):
Task: "Contract test automaton CRUD operations in test/contract/test_automaton_contract.dart"
Task: "Contract test simulation operations in test/contract/test_simulation_contract.dart"
Task: "Contract test conversion algorithms in test/contract/test_conversion_contract.dart"
Task: "Integration test FSA creation and simulation in test/integration/test_fsa_creation.dart"
Task: "Integration test NFA to DFA conversion in test/integration/test_nfa_to_dfa.dart"
Task: "Integration test grammar creation and parsing in test/integration/test_grammar_parsing.dart"
Task: "Integration test file operations in test/integration/test_file_operations.dart"
Task: "Integration test mobile UI interactions in test/integration/test_mobile_ui.dart"

# Launch T013-T028 together (Data Models):
Task: "State model in lib/core/models/state.dart"
Task: "Transition model in lib/core/models/transition.dart"
Task: "FSATransition model in lib/core/models/fsa_transition.dart"
Task: "PDATransition model in lib/core/models/pda_transition.dart"
Task: "TMTransition model in lib/core/models/tm_transition.dart"
Task: "Automaton abstract model in lib/core/models/automaton.dart"
Task: "FSA model in lib/core/models/fsa.dart"
Task: "PDA model in lib/core/models/pda.dart"
Task: "TM model in lib/core/models/tm.dart"
Task: "Grammar model in lib/core/models/grammar.dart"
Task: "Production model in lib/core/models/production.dart"
Task: "SimulationResult model in lib/core/models/simulation_result.dart"
Task: "SimulationStep model in lib/core/models/simulation_step.dart"
Task: "ParseTable model in lib/core/models/parse_table.dart"
Task: "TouchInteraction model in lib/core/models/touch_interaction.dart"
Task: "LayoutSettings model in lib/core/models/layout_settings.dart"

# Launch T029-T045 together (Core Algorithms):
Task: "NFA to DFA conversion algorithm in lib/core/algorithms/nfa_to_dfa_converter.dart"
Task: "DFA minimization algorithm in lib/core/algorithms/dfa_minimizer.dart"
Task: "Regular expression to NFA algorithm in lib/core/algorithms/regex_to_nfa_converter.dart"
Task: "FA to Regular Expression algorithm in lib/core/algorithms/fa_to_regex_converter.dart"
Task: "Automaton simulator in lib/core/algorithms/automaton_simulator.dart"
Task: "Grammar parser (LL) in lib/core/algorithms/ll_parser.dart"
Task: "Grammar parser (LR/SLR) in lib/core/algorithms/lr_parser.dart"
Task: "CYK parser in lib/core/algorithms/cyk_parser.dart"
Task: "Brute force parser for unrestricted grammars in lib/core/algorithms/brute_force_parser.dart"
Task: "Grammar transformer (CNF) in lib/core/algorithms/grammar_transformer.dart"
Task: "CFG to PDA converter (LL method) in lib/core/algorithms/cfg_to_pda_ll.dart"
Task: "PDA to CFG converter in lib/core/algorithms/pda_to_cfg.dart"
Task: "CFG to PDA converter (LR method) in lib/core/algorithms/cfg_to_pda_lr.dart"
Task: "Right-linear grammar to FA converter in lib/core/algorithms/right_linear_to_fa.dart"
Task: "Pumping lemma game engine for regular languages in lib/core/algorithms/pumping_lemma_regular.dart"
Task: "Pumping lemma game engine for context-free languages in lib/core/algorithms/pumping_lemma_cfg.dart"
Task: "L-system interpreter and visualizer in lib/core/algorithms/lsystem_interpreter.dart"

# Launch T055-T067 together (UI Widgets):
Task: "StateWidget for displaying states in lib/presentation/widgets/state_widget.dart"
Task: "TransitionWidget for displaying transitions in lib/presentation/widgets/transition_widget.dart"
Task: "AutomatonCanvas for rendering automata in lib/presentation/widgets/automaton_canvas.dart"
Task: "TouchGestureHandler for mobile interactions in lib/presentation/widgets/touch_gesture_handler.dart"
Task: "GrammarTable for editing grammars in lib/presentation/widgets/grammar_table.dart"
Task: "SimulationPanel for displaying results in lib/presentation/widgets/simulation_panel.dart"
Task: "ConversionDialog for algorithm operations in lib/presentation/widgets/conversion_dialog.dart"
Task: "PumpingLemmaGameWidget for interactive games in lib/presentation/widgets/pumping_lemma_game_widget.dart"
Task: "LSystemVisualizer for fractal visualization in lib/presentation/widgets/lsystem_visualizer.dart"
Task: "BuildingBlockEditor for Turing machine blocks in lib/presentation/widgets/building_block_editor.dart"
Task: "MealyMachineWidget for Mealy machine display in lib/presentation/widgets/mealy_machine_widget.dart"
Task: "ParseTableWidget for parsing table visualization in lib/presentation/widgets/parse_table_widget.dart"
Task: "DerivationTreeWidget for grammar derivation trees in lib/presentation/widgets/derivation_tree_widget.dart"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts
- Follow Flutter/Dart best practices
- Maintain mobile-first design principles
- Ensure accessibility compliance (WCAG 2.1 AA)
- Optimize for mobile performance and battery life

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - automaton-service.json → contract test tasks (T005-T007)
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P] (T013-T028)
   - Relationships → service layer tasks (T037-T041)
   
3. **From User Stories**:
   - Each story → integration test [P] (T008-T012)
   - Quickstart scenarios → validation tasks (T077)

4. **Ordering**:
   - Setup → Tests → Models → Algorithms → Services → UI → Integration → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [x] All contracts have corresponding tests (T005-T007)
- [x] All entities have model tasks (T013-T028)
- [x] All tests come before implementation
- [x] Parallel tasks truly independent
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] Mobile-specific requirements addressed
- [x] Performance targets included
- [x] Accessibility requirements covered
- [x] L-system functionality included
- [x] Pumping lemma games included
- [x] Building blocks for Turing machines included
- [x] Mealy machines included
- [x] Advanced parsing algorithms included
- [x] Grammar-automaton conversions included
