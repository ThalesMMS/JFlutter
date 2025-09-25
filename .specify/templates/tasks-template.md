# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
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
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 3.1: Setup
- [ ] T001 Create Flutter project structure per implementation plan
- [ ] T002 Initialize Flutter project with Riverpod, freezed, json_serializable dependencies
- [ ] T003 [P] Configure linting (very_good_analysis) and formatting tools
- [ ] T004 [P] Set up clean architecture folder structure (presentation/core/data)

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T005 [P] Unit test automaton models in test/unit/models/test_automaton.dart
- [ ] T006 [P] Unit test algorithm implementations in test/unit/algorithms/test_conversion.dart
- [ ] T007 [P] Integration test automaton creation workflow in test/integration/test_automaton_creation.dart
- [ ] T008 [P] Widget test main UI components in test/widget/test_automaton_canvas.dart

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T009 [P] Automaton models with freezed in lib/core/models/automaton.dart
- [ ] T010 [P] Algorithm services in lib/core/algorithms/
- [ ] T011 [P] Riverpod providers for state management in lib/presentation/providers/
- [ ] T012 [P] JSON serialization with json_serializable in lib/data/models/
- [ ] T013 [P] Input validation and error handling
- [ ] T014 [P] Mobile-optimized UI components in lib/presentation/widgets/

## Phase 3.4: Integration
- [ ] T015 [P] File I/O operations (.jff import/export) in lib/data/repositories/
- [ ] T016 [P] Canvas rendering and touch gesture handling
- [ ] T017 [P] Algorithm visualization and step-by-step execution
- [ ] T018 [P] Mobile responsiveness and accessibility features

## Phase 3.5: Polish
- [ ] T019 [P] Golden tests for UI components in test/widget/
- [ ] T020 [P] Performance tests (60fps canvas, >10k simulation steps)
- [ ] T021 [P] Update README.md and API documentation
- [ ] T022 [P] Code cleanup and remove duplication
- [ ] T023 [P] Run flutter test --coverage and analyze

## Dependencies
- Tests (T005-T008) before implementation (T009-T014)
- T009 (models) blocks T010 (algorithms), T015 (file I/O)
- T011 (providers) blocks T016 (canvas rendering)
- Implementation before polish (T019-T023)

## Parallel Example
```
# Launch T005-T008 together:
Task: "Unit test automaton models in test/unit/models/test_automaton.dart"
Task: "Unit test algorithm implementations in test/unit/algorithms/test_conversion.dart"
Task: "Integration test automaton creation in test/integration/test_automaton_creation.dart"
Task: "Widget test main UI components in test/widget/test_automaton_canvas.dart"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts

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
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task