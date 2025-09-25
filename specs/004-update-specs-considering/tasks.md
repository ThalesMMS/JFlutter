# Tasks: Update Specs to Align with Requisitos.md

**Input**: Design documents from `/specs/004-update-specs-considering/`

## Phase 3.1: Documentation Update
- [x] T001: [P] Update `CHANGELOG.md` to remove `LSystemGenerator` from the v1.0.0 release notes.
- [x] T002: [P] Update `specs/001-description-port-jflap/spec.md` to remove the L-Systems section and the brute-force parser requirement.
- [x] T003: [P] Update `specs/003-jflutter-core-expansion/spec.md` to remove requirements and acceptance criteria related to LR/SLR parsing and the brute-force parser.

## Phase 3.2: Code Refactoring
- [x] T004: Refactor `lib/core/models/parse_table.dart` to remove `lr`, `slr`, and `lalr` from the `ParseType` enum and any related logic.
- [x] T005: Refactor `lib/core/algorithms/grammar_parser.dart` to remove the brute-force and LR parsing strategies.

## Phase 3.3: Verification
- [ ] T006: Manually verify the removal of all features by following the steps in `specs/004-update-specs-considering/quickstart.md`.
- [ ] T007: Run `flutter test --coverage` to ensure that the refactoring has not introduced any regressions and analyze the results.

## Dependencies
- Verification (T006-T007) must be performed after all documentation (T001-T003) and code refactoring (T004-T005) tasks are complete.

## Parallel Example
```
# The following tasks can be run in parallel:
Task: "T001: [P] Update `CHANGELOG.md` to remove `LSystemGenerator` from the v1.0.0 release notes."
Task: "T002: [P] Update `specs/001-description-port-jflap/spec.md` to remove the L-Systems section and the brute-force parser requirement."
Task: "T003: [P] Update `specs/003-jflutter-core-expansion/spec.md` to remove requirements and acceptance criteria related to LR/SLR parsing and the brute-force parser."
Task: "T004: Refactor `lib/core/models/parse_table.dart` to remove `lr`, `slr`, and `lalr` from the `ParseType` enum and any related logic."
Task: "T005: Refactor `lib/core/algorithms/grammar_parser.dart` to remove the brute-force and LR parsing strategies."
```
