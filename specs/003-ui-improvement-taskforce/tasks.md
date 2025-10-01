# Tasks: UI Improvement Taskforce

**Input**: Design documents from `/Users/thales/Documents/GitHub/jflutter/specs/003-ui-improvement-taskforce/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/, quickstart.md

## Execution Flow (main)
```
1. Load plan.md; if missing: ERROR "No implementation plan found"
   → Extract constitution compliance notes, reference mappings, architecture targets
2. Load optional design documents:
   → data-model.md: Immutable entities → model/service tasks
   → contracts/: Widget contracts → validation & implementation tasks
   → research.md: Test failure analysis → correctness tasks
   → quickstart.md: Manual validation → QA tasks
3. Generate tasks by category respecting constitution:
   → Setup: dependencies, golden_toolkit, test infrastructure
   → Tests: widget tests (fix failing), golden tests (new infrastructure)
   → Core: missing widgets implementation in `lib/presentation/widgets/`
   → State/UI: Canvas rendering validation, responsive layouts
   → Accessibility: Semantic labels, touch targets, screen reader support
   → Performance & QA: 60fps validation, quickstart execution, flutter analyze
4. Apply task rules:
   → Tests precede implementation (TDD where applicable)
   → Fix existing tests before new features
   → Each task cites target file path(s) under `lib/` or `test/`
   → Respect layered architecture boundaries (presentation layer focus)
5. Enforce constitution compliance gates:
   → Widget test failures warn but allow merge (manual review before deployment)
6. Number tasks sequentially (T001, T002...)
7. Generate dependency graph and parallel task guidance
8. Validate checklists before returning
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no shared state)
- Always include precise file paths

## Phase T1: Setup & Infrastructure

- [ ] T001 [P] Configure golden_toolkit in `test/flutter_test_config.dart`
  - Create file: `test/flutter_test_config.dart`
  - Add golden_toolkit configuration with device presets (mobile 375x667, tablet 768x1024, desktop 1280x800)
  - Configure `loadAppFonts()` for consistent rendering
  - Set `skipGoldenAssertion: () => false`
  - Ref: `contracts/golden_test_contract.md` infrastructure section

- [ ] T002 [P] Create widget test fixtures and helpers in `test/widget/helpers/`
  - Create directory: `test/widget/helpers/`
  - Implement `test_fixtures.dart` with TestFixtures class:
    - `simpleDFA`: 2 states, 1 transition
    - `simpleNFAEpsilon`: 2 states, epsilon transition
    - `pdaBalancedParens`: 3 states, stack operations
    - `tmBinaryIncrement`: 4 states, tape operations
  - Implement `widget_test_utils.dart` with selector helpers (descendant navigation)
  - All fixtures respect ≤20 states, ≤50 transitions bound
  - Ref: `data-model.md` TestAutomatonFixture section

- [ ] T003 [P] Update CI/CD configuration for warning-only widget tests
  - Update `.github/workflows/test.yml` (if exists) or document CI requirements
  - Configure widget tests to `continue-on-error: true`
  - Add test report generation as warning, not error
  - Document: Widget test failures don't block PR merge (manual review required)
  - Ref: `contracts/widget_test_contract.md` CI/CD integration section

## Phase T2: Fix Existing Widget Tests ⚠️ Sequential by Priority

- [ ] T004 Fix AutomatonCanvas test selectors in `test/widget/presentation/immutable_traces_visualization_test.dart`
  - Update file: `test/widget/presentation/immutable_traces_visualization_test.dart`
  - Replace `find.byType(CustomPaint)` with descendant navigation pattern
  - Use `find.descendant(of: find.byType(AutomatonCanvas), matching: find.byType(CustomPaint))`
  - Access AutomatonPainter via widget list (last item for rendering layer)
  - Fix 3 AutomatonCanvas rendering tests (empty, DFA, NFA)
  - Ref: `contracts/widget_test_contract.md` Pattern 1, `research.md` failure analysis

- [ ] T005 Fix SimulationPanel test selectors in `test/widget/presentation/immutable_traces_visualization_test.dart`
  - Update file: `test/widget/presentation/immutable_traces_visualization_test.dart`
  - Update SimulationPanel widget structure selectors
  - Use descendant navigation for nested text/widgets
  - Fix 3 SimulationPanel tests (no result, accepted, rejected)
  - Ref: `contracts/widget_test_contract.md` Pattern 2

- [ ] T006 Fix trace visualization and performance tests in `test/widget/presentation/immutable_traces_visualization_test.dart`
  - Update file: `test/widget/presentation/immutable_traces_visualization_test.dart`
  - Fix "Simulation steps render correctly" test (update step selectors)
  - Fix "AutomatonCanvas handles large automatons efficiently" test (update helper function)
  - Verify test fixtures use ≤20 states, ≤50 transitions (per clarifications)
  - Ref: `contracts/widget_test_contract.md` Pattern 4 (performance)

## Phase T3: Missing Widgets Implementation (Parallel)

- [ ] T007 [P] Implement ErrorBanner widget in `lib/presentation/widgets/error_banner.dart`
  - Create file: `lib/presentation/widgets/error_banner.dart`
  - Implement ErrorBanner widget per contract:
    - Props: message (required), severity (error/warning/info), showRetryButton, showDismissButton, onRetry, onDismiss
    - Visual: Red/orange/blue backgrounds, icon + message + buttons layout
    - Responsive: Stack vertically on mobile (<600px)
  - Create widget test: `test/widget/presentation/error_banner_test.dart`
  - Verify semantic labels, touch targets ≥44x44px
  - Ref: `contracts/error_handling_contract.md` ErrorBanner section

- [ ] T008 [P] Implement ImportErrorDialog widget in `lib/presentation/widgets/import_error_dialog.dart`
  - Create file: `lib/presentation/widgets/import_error_dialog.dart`
  - Implement ImportErrorDialog widget per contract:
    - Props: fileName, errorType (enum), detailedMessage, technicalDetails, onRetry, onCancel
    - Visual: Modal dialog, max width 400px (mobile) / 500px (tablet+)
    - Actions: Cancel + Retry buttons, optional technical details expander
  - Create widget test: `test/widget/presentation/import_error_dialog_test.dart`
  - Verify focus trap, escape key triggers cancel
  - Ref: `contracts/error_handling_contract.md` ImportErrorDialog section

- [ ] T009 [P] Implement RetryButton widget in `lib/presentation/widgets/retry_button.dart`
  - Create file: `lib/presentation/widgets/retry_button.dart`
  - Implement RetryButton widget per contract:
    - Props: onPressed (required), isLoading, isEnabled, label (default "Retry"), icon (default refresh)
    - States: Normal, Loading (animated icon), Disabled
    - Touch target: Minimum 44x44px
  - Create widget test: `test/widget/presentation/retry_button_test.dart`
  - Verify accessibility (semantic label, button role, focusable)
  - Ref: `contracts/error_handling_contract.md` RetryButton section

- [ ] T010 Integrate error widgets into existing flows
  - Update import error handling in relevant files (identify via code search)
  - Wire ErrorBanner for recoverable import errors
  - Wire ImportErrorDialog for critical import errors
  - Ensure RetryButton used consistently in error UIs
  - Test error recovery flows manually (use invalid .jff file)
  - Ref: `contracts/error_handling_contract.md` integration points, error recovery flows

## Phase T4: Canvas Rendering Validation (Sequential: FSA → PDA → TM)

- [ ] T011 Validate FSA canvas rendering in `lib/presentation/widgets/automaton_canvas.dart`
  - Review file: `lib/presentation/widgets/automaton_canvas.dart`
  - Verify AutomatonPainter renders per contract:
    - States: 30px radius, double circle for accepting, initial arrow
    - Transitions: Bezier curves for multiples, arrow heads, labels
    - Trace overlay: Green for visited, blue for current, dotted path
  - Test with TestFixtures.simpleDFA (2 states, 1 transition)
  - Verify viewport culling and LOD for performance
  - Create canvas rendering test if not exists
  - Ref: `contracts/canvas_rendering_contract.md` AutomatonPainter section

- [ ] T012 Validate PDA canvas rendering (if separate file, or in automaton_canvas.dart)
  - Identify PDA canvas file (likely `lib/presentation/widgets/pda_canvas.dart` or integrated)
  - Verify PDA-specific rendering:
    - Stack panel: 300px width, right side, symbols grow upward
    - Top symbol highlighted (light blue)
    - Push/pop animations (200ms)
    - Transition labels: "symbol / pop → push" format
  - Test with TestFixtures.pdaBalancedParens
  - Ref: `contracts/canvas_rendering_contract.md` PDA section

- [ ] T013 Validate TM canvas rendering (if separate file, or in automaton_canvas.dart)
  - Identify TM canvas file (likely `lib/presentation/widgets/tm_canvas.dart` or integrated)
  - Verify TM-specific rendering:
    - Tape panel: Top of canvas, 80px height, 11 visible cells (60x60px each)
    - Current cell highlighted yellow (#FFF9C4)
    - Head indicator: Red triangle pointing down
    - Halt states: Green (accept), red (reject), orange (halt)
  - Test with TestFixtures.tmBinaryIncrement
  - Ref: `contracts/canvas_rendering_contract.md` TM section

- [ ] T014 Fix layout blocking issues at small screen sizes
  - Audit all canvas files for responsive layout issues
  - Test at breakpoints: 375px (mobile), 320px (minimum), 768px (tablet)
  - Ensure canvas controls (Add State, Add Transition, etc.) not blocked
  - Implement collapsible panels for mobile (<600px)
  - Verify all buttons accessible, no overlaps
  - Manual test using quickstart Section 5 (Responsive Layouts)
  - Ref: `quickstart.md` Section 5, `contracts/canvas_rendering_contract.md` responsive behavior

## Phase T5: Golden Test Infrastructure (Parallel by Component)

- [ ] T015 [P] Implement golden test infrastructure and FSA canvas goldens
  - Create directory: `test/widget/presentation/goldens/automaton_canvas/`
  - Create file: `test/widget/presentation/golden_tests/automaton_canvas_golden_test.dart`
  - Implement golden tests for FSA:
    - `empty_mobile.png` - Empty canvas
    - `dfa_simple_mobile.png` - Simple DFA (2 states, 1 transition)
    - `nfa_epsilon_mobile.png` - NFA with epsilon
    - `trace_visualization_mobile.png` - Active simulation trace
  - Use `testGoldens`, `screenMatchesGolden`, and `multiScreenGolden`
  - Ref: `contracts/golden_test_contract.md` patterns and naming conventions

- [ ] T016 [P] Create simulation panel golden tests
  - Create directory: `test/widget/presentation/goldens/simulation_panel/`
  - Create file: `test/widget/presentation/golden_tests/simulation_panel_golden_test.dart`
  - Implement golden tests:
    - `no_result_mobile.png` - Initial state
    - `accepted_mobile.png` - Accepted result
    - `rejected_mobile.png` - Rejected result
    - `step_by_step_mobile.png` - Trace steps visible
  - Ref: `contracts/golden_test_contract.md`

- [ ] T017 [P] Create error component golden tests
  - Create directory: `test/widget/presentation/goldens/error_components/`
  - Create file: `test/widget/presentation/golden_tests/error_components_golden_test.dart`
  - Implement golden tests:
    - `error_banner_critical_mobile.png` - Error severity banner
    - `error_banner_warning_mobile.png` - Warning severity
    - `import_dialog_malformed_mobile.png` - Import error dialog
    - `retry_button_normal.png`, `retry_button_loading.png`, `retry_button_disabled.png`
  - Test multiple states/variants per Pattern 3
  - Ref: `contracts/golden_test_contract.md` Pattern 3 (multiple variants)

- [ ] T018 [P] Create PDA and TM canvas golden tests
  - Create directories: `test/widget/presentation/goldens/pda_canvas/`, `tm_canvas/`
  - Create files: `pda_canvas_golden_test.dart`, `tm_canvas_golden_test.dart`
  - PDA goldens: `stack_visualization_mobile.png`, `push_pop_operations_mobile.png`
  - TM goldens: `tape_rendering_mobile.png`, `head_position_mobile.png`, `halt_states_mobile.png`
  - Ref: `contracts/golden_test_contract.md`, `contracts/canvas_rendering_contract.md`

## Phase T6: Accessibility & Polish (Parallel with Phase T5)

- [ ] T019 [P] Validate Flutter accessibility guidelines compliance
  - Audit all interactive widgets for accessibility:
    - Canvas controls (Add State, Add Transition, etc.)
    - Error widgets (ErrorBanner, ImportErrorDialog, RetryButton)
    - Simulation controls
  - Add semantic labels to widgets missing them
  - Verify touch targets ≥44x44px (measure in widget tests)
  - Test with screen reader (iOS VoiceOver or Android TalkBack) per quickstart Section 6
  - Document compliance in accessibility report (create if needed)
  - Best-effort compliance (no formal WCAG, per clarifications)
  - Ref: `quickstart.md` Section 6, `contracts/canvas_rendering_contract.md` accessibility

- [ ] T020 [P] Implement visual unsaved work indicators
  - Identify save state management (likely in Riverpod provider)
  - Add unsaved work indicator to app bar or status area:
    - Visual: Dot, asterisk, or "Unsaved changes" text
    - Appears when automaton modified, clears on save
  - Implement SaveStateIndicatorState model (from data-model.md)
  - Test manual save workflow per quickstart Section 8
  - Ref: `data-model.md` SaveStateIndicatorState, `quickstart.md` Section 8

## Phase T7: QA & Documentation

- [ ] T021 [P] Run `flutter analyze` and fix all issues
  - Execute: `flutter analyze`
  - Fix all errors, warnings, and info messages
  - Ensure code formatting: `dart format .`
  - Verify no linting violations
  - Document any suppressed warnings with justification
  - Ref: Constitution compliance requirement

- [ ] T022 Execute quickstart manual validation and document results
  - Follow complete quickstart workflow in `quickstart.md`
  - Test on physical device (iOS or Android) and simulator
  - Complete all 8 validation sections:
    - Section 1: FSA Canvas (11 checks)
    - Section 2: PDA Canvas (3 checks)
    - Section 3: TM Canvas (3 checks)
    - Section 4: Error Handling (3 checks)
    - Section 5: Responsive Layouts (4 checks)
    - Section 6: Accessibility (5 checks)
    - Section 7: Performance (3 checks)
    - Section 8: Manual Save (3 checks)
  - Document results in `QUICKSTART_VALIDATION_RESULTS.md`
  - Attach screenshots/videos for any failures
  - Ref: `quickstart.md` complete workflow

- [ ] T023 Document test coverage and update README
  - Run all widget tests: `flutter test test/widget/`
  - Collect test results (expect all passing after fixes)
  - Update README.md with:
    - Widget test status (should be 0 failures after all fixes)
    - Golden test infrastructure (new section)
    - Error handling widgets (new features)
    - Accessibility compliance (best-effort)
  - Update docs/reference-deviations.md if any UI deviations from JFLAP specs
  - List any remaining known issues or technical debt
  - Ref: README.md existing test section, constitution documentation requirement

## Dependencies

**Setup → Tests → Implementation → Validation → QA**

```
Phase T1 (Setup)
  ↓
Phase T2 (Fix Existing Tests) - Sequential: T004 → T005 → T006
  ↓
Phase T3 (Missing Widgets) - Parallel: T007, T008, T009 → T010 (Integration)
  ↓
Phase T4 (Canvas Validation) - Sequential: T011 → T012 → T013 → T014
  ↓
Phases T5 & T6 (Golden Tests + Accessibility) - Parallel: T015, T016, T017, T018, T019, T020
  ↓
Phase T7 (QA & Documentation) - Parallel: T021, T022 → T023
```

**Critical Path**: T001-T003 → T004 → T005 → T006 → T011 → T012 → T013 → T014 → T021 → T022 → T023

## Parallel Execution Guidance

### Setup (All Parallel)
```
/spec_task run T001  # Golden toolkit config
/spec_task run T002  # Test fixtures
/spec_task run T003  # CI/CD config
```

### Missing Widgets (Parallel, then Integration)
```
/spec_task run T007  # ErrorBanner
/spec_task run T008  # ImportErrorDialog
/spec_task run T009  # RetryButton
# After all complete:
/spec_task run T010  # Integration
```

### Golden Tests + Accessibility (All Parallel)
```
/spec_task run T015  # FSA canvas goldens
/spec_task run T016  # Simulation panel goldens
/spec_task run T017  # Error component goldens
/spec_task run T018  # PDA/TM canvas goldens
/spec_task run T019  # Accessibility validation
/spec_task run T020  # Unsaved work indicators
```

### QA (T021 and T022 parallel, T023 depends on both)
```
/spec_task run T021  # flutter analyze
/spec_task run T022  # Quickstart validation
# After both complete:
/spec_task run T023  # Documentation
```

Assegure que tarefas [P] não compartilham arquivos ou estados mutáveis.

## Notes

- **Architecture**: All widgets in `lib/presentation/widgets/`, tests in `test/widget/presentation/`
- **Test Complexity Bound**: All test fixtures ≤20 states, ≤50 transitions (per clarifications)
- **CI/CD Policy**: Widget test failures warn but don't block merge (manual review before deployment)
- **Accessibility**: Best-effort Flutter guidelines, no formal WCAG compliance required
- **Performance**: Target ≥60fps canvas rendering, verify with Flutter DevTools
- **Golden Tests**: Run `flutter test --update-goldens` to regenerate after intentional UI changes
- **Manual Save Only**: No auto-save, visual indicators for unsaved work

---

**Tasks Complete**: 23 tasks covering setup, test fixes, widget implementation, canvas validation, golden tests, accessibility, and QA

**Estimated Effort**: 
- Setup: 1-2 days
- Test Fixes: 2-3 days  
- Missing Widgets: 2-3 days
- Canvas Validation: 3-4 days
- Golden Tests + Accessibility: 2-3 days
- QA & Documentation: 1-2 days

**Total**: ~11-17 days (with parallel execution: ~8-12 days)

