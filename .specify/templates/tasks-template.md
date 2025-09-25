# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/, quickstart.md

## Execution Flow (main)
```
1. Load plan.md; if missing: ERROR "No implementation plan found"
   → Extract constitution compliance notes, reference mappings, architecture targets
2. Load optional design documents:
   → data-model.md: Immutable entities → model/service tasks
   → contracts/: Serialization schemas → validation & export tasks
   → research.md: Reference alignment → correctness tasks
   → quickstart.md: Manual validation → QA tasks
3. Generate tasks by category respecting constitution:
   → Setup: packages, analyzers, reference verification harnesses
   → Tests: unit, integration, widget, golden, property-based (fail first)
   → Core: algorithms, conversions, immutable models
   → State/UI: Riverpod providers, Flutter widgets
   → Interoperability: .jff/JSON/SVG import-export, trace persistence
   → Performance & QA: 60fps canvas checks, >10k step throttling, offline validation
4. Apply task rules:
   → Tests precede implementation (TDD)
   → Reference parity tasks before UI polish
   → Each task cites target file path(s) under `lib/` or packages/
   → If task uses shared types, mention specific package (`core_fa`, etc.)
5. Enforce constitution compliance gates:
   → If scope violation detected: ERROR "Task plan violates constitution"
6. Number tasks sequentially (T001, T002...)
7. Generate dependency graph and parallel task guidance (respect immutable data constraints)
8. Validate checklists before returning
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no shared state)
- Always include precise file paths and package names
- Note reference sources where applicable (e.g., `References/automata-main/...`)

## Phase 3.1: Setup
- [ ] T001 Verify references in `References/` for targeted algorithms (document paths)
- [ ] T002 Configure required packages (`freezed`, `json_serializable`, Riverpod) in `pubspec.yaml`
- [ ] T003 [P] Ensure `flutter analyze` and formatting hooks ready (no regressions)

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: Write failing tests before implementation.**
- [ ] T004 [P] Unit tests for new automata/grammar logic in `test/unit/...`
- [ ] T005 [P] Integration tests covering simulations/traces in `test/integration/...`
- [ ] T006 [P] Widget/golden tests for UI surfaces in `test/widget/...`
- [ ] T007 [P] Property-based or regression tests referencing canonical examples when applicable

## Phase 3.3: Core Implementation (ONLY after tests fail)
- [ ] T008 [P] Implement immutable models in `packages/core_*/lib/...`
- [ ] T009 [P] Implement algorithms/services in `lib/core/...` referencing `References/`
- [ ] T010 Implement data layer DTOs with `json_serializable` in `lib/data/models/...`
- [ ] T011 Implement Riverpod providers/state in `lib/presentation/providers/...`
- [ ] T012 Implement UI widgets/pages in `lib/presentation/...`
- [ ] T013 Maintain immutable trace logging and time-travel replay support

## Phase 3.4: Interoperability & Performance
- [ ] T014 Implement/validate `.jff`/JSON/SVG import-export and schema checks
- [ ] T015 Validate offline storage sandbox and input validation diagnostics
- [ ] T016 Ensure canvas performance ≥60fps with throttling/batched paints >10k steps
- [ ] T017 Document deviations from reference implementations (if any) with rationale

## Phase 3.5: QA & Documentation
- [ ] T018 [P] Run `flutter analyze` and ensure zero warnings/errors
- [ ] T019 [P] Execute manual scenarios from quickstart.md (offline)
- [ ] T020 Update documentation (`README`, feature docs) to reflect new capability and references
- [ ] T021 Confirm licensing notes (Apache-2.0 vs JFLAP assets) remain accurate
- [ ] T022 [P] Ensure regression tests and property-based suites cover new behaviour

## Dependencies
- Phase 3.2 tasks block later phases
- Core algorithms (T009) depend on immutable models (T008) and tests (T004-T007)
- UI/state tasks depend on core/data implementation
- Interoperability & performance tasks depend on completed core logic

## Parallel Execution Guidance
```
# Example parallel run respecting immutability:
Task: "Unit tests for DFA minimization in test/unit/core_fa/test_dfa_minimizer.dart"
Task: "Widget tests for simulator UI in test/widget/presentation/simulator_test.dart"
Task: "Import/export schema validation tests in test/integration/io/test_jff_conversion.dart"
```
Ensure parallel tasks touch disjoint files and do not mutate shared state.

## Validation Checklist
- [ ] All syllabus features mapped to constitutional principles
- [ ] Every algorithm task cites reference source
- [ ] Tests precede implementation, fail initially
- [ ] Performance and interoperability tasks present
- [ ] Licensing/documentation tasks included
- [ ] No task introduces forbidden scope or external dependencies

## Notes
- Encourage small commits following constitution guardrails
- Track deviations in Complexity Tracking if constitution checks flagged them
- Ensure final PR references constitution compliance in Summary