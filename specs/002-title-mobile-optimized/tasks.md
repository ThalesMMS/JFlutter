# Tasks: Mobile-Optimized JFlutter Core Features

**Input**: Design documents from `/specs/002-title-mobile-optimized/`
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
- **Models**: `lib/core/models/`
- **Services**: `lib/core/services/`
- **UI**: `lib/presentation/`
- **Tests**: `test/contract/`, `test/integration/`, `test/unit/`

## Phase 3.1: Setup
- [ ] T001 Create Flutter project structure with mobile-optimized directories
- [ ] T002 Initialize Flutter project with Provider, CustomPainter, SharedPreferences dependencies
- [ ] T003 [P] Configure Flutter linting, formatting, and analysis options

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T004 [P] Contract test workspace API in test/contract/workspace_api_test.dart
- [ ] T005 [P] Integration test finite automaton creation in test/integration/test_finite_automaton.dart
- [ ] T006 [P] Integration test pushdown automaton simulation in test/integration/test_pushdown_automaton.dart
- [ ] T007 [P] Integration test turing machine execution in test/integration/test_turing_machine.dart
- [ ] T008 [P] Integration test grammar derivation in test/integration/test_grammar.dart
- [ ] T009 [P] Integration test regular expression matching in test/integration/test_regular_expression.dart
- [ ] T010 [P] Integration test pumping lemma proof in test/integration/test_pumping_lemma.dart
- [ ] T011 [P] Widget test mobile navigation in test/widget/test_navigation.dart
- [ ] T012 [P] Widget test expandable menus in test/widget/test_expandable_menus.dart
- [ ] T013 [P] Widget test compact toolbars in test/widget/test_compact_toolbars.dart

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T014 [P] Point model in lib/core/models/point.dart
- [ ] T015 [P] State model in lib/core/models/state.dart
- [ ] T016 [P] Transition model in lib/core/models/transition.dart
- [ ] T017 [P] AutomatonData model in lib/core/models/automaton_data.dart
- [ ] T018 [P] GrammarData model in lib/core/models/grammar_data.dart
- [ ] T019 [P] Production model in lib/core/models/production.dart
- [ ] T020 [P] RegularExpressionData model in lib/core/models/regular_expression_data.dart
- [ ] T021 [P] PumpingLemmaData model in lib/core/models/pumping_lemma_data.dart
- [ ] T022 [P] TestCase model in lib/core/models/test_case.dart
- [ ] T023 [P] ViewSettings model in lib/core/models/view_settings.dart
- [ ] T024 [P] MenuState model in lib/core/models/menu_state.dart
- [ ] T025 [P] FeatureTab model in lib/core/models/feature_tab.dart
- [ ] T026 [P] Workspace model in lib/core/models/workspace.dart
- [ ] T027 [P] AppState model in lib/core/models/app_state.dart
- [ ] T028 WorkspaceService implementation in lib/core/services/workspace_service.dart
- [ ] T029 FiniteAutomatonService implementation in lib/core/services/finite_automaton_service.dart
- [ ] T030 PushdownAutomatonService implementation in lib/core/services/pushdown_automaton_service.dart
- [ ] T031 TuringMachineService implementation in lib/core/services/turing_machine_service.dart
- [ ] T032 GrammarService implementation in lib/core/services/grammar_service.dart
- [ ] T033 RegularExpressionService implementation in lib/core/services/regular_expression_service.dart
- [ ] T034 PumpingLemmaService implementation in lib/core/services/pumping_lemma_service.dart
- [ ] T035 StorageService implementation in lib/core/services/storage_service.dart

## Phase 3.4: UI Implementation
- [ ] T036 [P] CustomPainter for automata rendering in lib/presentation/widgets/automata_painter.dart
- [ ] T037 [P] Bottom navigation widget in lib/presentation/widgets/bottom_navigation.dart
- [ ] T038 [P] Expandable menu widget in lib/presentation/widgets/expandable_menu.dart
- [ ] T039 [P] Compact toolbar widget in lib/presentation/widgets/compact_toolbar.dart
- [ ] T040 [P] State widget for automata in lib/presentation/widgets/state_widget.dart
- [ ] T041 [P] Transition widget for automata in lib/presentation/widgets/transition_widget.dart
- [ ] T042 [P] Canvas widget for automata in lib/presentation/widgets/automata_canvas.dart
- [ ] T043 [P] Simulation dialog widget in lib/presentation/widgets/simulation_dialog.dart
- [ ] T044 [P] Grammar editor widget in lib/presentation/widgets/grammar_editor.dart
- [ ] T045 [P] Regular expression tester widget in lib/presentation/widgets/regex_tester.dart
- [ ] T046 [P] Pumping lemma exercise widget in lib/presentation/widgets/pumping_lemma_widget.dart
- [ ] T047 Finite Automaton screen in lib/presentation/screens/finite_automaton_screen.dart
- [ ] T048 Pushdown Automaton screen in lib/presentation/screens/pushdown_automaton_screen.dart
- [ ] T049 Turing Machine screen in lib/presentation/screens/turing_machine_screen.dart
- [ ] T050 Grammar screen in lib/presentation/screens/grammar_screen.dart
- [ ] T051 Regular Expression screen in lib/presentation/screens/regular_expression_screen.dart
- [ ] T052 Pumping Lemma screen in lib/presentation/screens/pumping_lemma_screen.dart
- [ ] T053 Main app widget with navigation in lib/presentation/screens/main_screen.dart

## Phase 3.5: Integration
- [ ] T054 Provider state management setup in lib/core/providers/app_provider.dart
- [ ] T055 Provider state management for workspaces in lib/core/providers/workspace_provider.dart
- [ ] T056 Provider state management for UI state in lib/core/providers/ui_provider.dart
- [ ] T057 Touch gesture handling in lib/core/gestures/automata_gestures.dart
- [ ] T058 Responsive layout system in lib/core/layout/responsive_layout.dart
- [ ] T059 Local storage integration in lib/core/storage/local_storage.dart
- [ ] T060 App initialization and routing in lib/main.dart

## Phase 3.6: Polish
- [ ] T061 [P] Unit tests for all models in test/unit/test_models.dart
- [ ] T062 [P] Unit tests for all services in test/unit/test_services.dart
- [ ] T063 [P] Unit tests for gesture handling in test/unit/test_gestures.dart
- [ ] T064 [P] Unit tests for storage in test/unit/test_storage.dart
- [ ] T065 Performance optimization for 60fps rendering
- [ ] T066 Memory optimization for mobile devices
- [ ] T067 Accessibility improvements (44pt touch targets, screen reader support)
- [ ] T068 Error handling and user feedback
- [ ] T069 [P] Update API documentation in docs/api.md
- [ ] T070 [P] Update user guide in docs/user_guide.md
- [ ] T071 Remove any remaining Moore/Multi-Tape/L-System code
- [ ] T072 Run quickstart validation scenarios

## Dependencies
- Tests (T004-T013) before implementation (T014-T035)
- Models (T014-T027) before services (T028-T035)
- Services (T028-T035) before UI (T036-T053)
- UI widgets (T036-T046) before screens (T047-T053)
- Core implementation before integration (T054-T060)
- Integration before polish (T061-T072)

## Parallel Execution Examples

### Phase 3.2: Contract and Integration Tests (T004-T013)
```bash
# Launch all tests in parallel:
flutter test test/contract/workspace_api_test.dart
flutter test test/integration/test_finite_automaton.dart
flutter test test/integration/test_pushdown_automaton.dart
flutter test test/integration/test_turing_machine.dart
flutter test test/integration/test_grammar.dart
flutter test test/integration/test_regular_expression.dart
flutter test test/integration/test_pumping_lemma.dart
flutter test test/widget/test_navigation.dart
flutter test test/widget/test_expandable_menus.dart
flutter test test/widget/test_compact_toolbars.dart
```

### Phase 3.3: Model Creation (T014-T027)
```bash
# Create all models in parallel:
# T014: lib/core/models/point.dart
# T015: lib/core/models/state.dart
# T016: lib/core/models/transition.dart
# T017: lib/core/models/automaton_data.dart
# T018: lib/core/models/grammar_data.dart
# T019: lib/core/models/production.dart
# T020: lib/core/models/regular_expression_data.dart
# T021: lib/core/models/pumping_lemma_data.dart
# T022: lib/core/models/test_case.dart
# T023: lib/core/models/view_settings.dart
# T024: lib/core/models/menu_state.dart
# T025: lib/core/models/feature_tab.dart
# T026: lib/core/models/workspace.dart
# T027: lib/core/models/app_state.dart
```

### Phase 3.4: UI Widgets (T036-T046)
```bash
# Create all UI widgets in parallel:
# T036: lib/presentation/widgets/automata_painter.dart
# T037: lib/presentation/widgets/bottom_navigation.dart
# T038: lib/presentation/widgets/expandable_menu.dart
# T039: lib/presentation/widgets/compact_toolbar.dart
# T040: lib/presentation/widgets/state_widget.dart
# T041: lib/presentation/widgets/transition_widget.dart
# T042: lib/presentation/widgets/automata_canvas.dart
# T043: lib/presentation/widgets/simulation_dialog.dart
# T044: lib/presentation/widgets/grammar_editor.dart
# T045: lib/presentation/widgets/regex_tester.dart
# T046: lib/presentation/widgets/pumping_lemma_widget.dart
```

### Phase 3.6: Unit Tests (T061-T064)
```bash
# Run all unit tests in parallel:
flutter test test/unit/test_models.dart
flutter test test/unit/test_services.dart
flutter test test/unit/test_gestures.dart
flutter test test/unit/test_storage.dart
```

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - workspace-api.yaml → contract test task T004 [P]
   - workspace-api-test.dart → contract test task T004 [P]
   
2. **From Data Model**:
   - 12 entities → 12 model creation tasks T014-T027 [P]
   - Relationships → service layer tasks T028-T035
   
3. **From User Stories**:
   - 6 feature walkthroughs → 6 integration tests T005-T010 [P]
   - Quickstart scenarios → validation tasks T072

4. **Ordering**:
   - Setup → Tests → Models → Services → UI → Integration → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [x] All contracts have corresponding tests (T004)
- [x] All entities have model tasks (T014-T027)
- [x] All tests come before implementation (T004-T013 before T014+)
- [x] Parallel tasks truly independent (different files)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Mobile-first design principles throughout
- Maintain JFLAP algorithmic consistency
- Focus on touch interaction and responsive design
- Remove unnecessary features (Moore, Multi-Tape, L-System)
