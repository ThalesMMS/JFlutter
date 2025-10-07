
# Implementation Plan: UI Improvement Taskforce

**Branch**: `003-ui-improvement-taskforce` | **Date**: 2025-10-01 | **Spec**: [`specs/003-ui-improvement-taskforce/spec.md`](./spec.md)
**Input**: Feature specification from [`specs/003-ui-improvement-taskforce/spec.md`](./spec.md)

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Confirm feature fits Constitution scope (see Constitution Check)
   → Capture reference algorithms/files from `References/`
3. Populate the Constitution Check section using current constitution v2.0.0
4. Evaluate Constitution Check section below
   → If violations exist: document in Complexity Tracking with mitigation
   → If non-negotiable guardrails breached: ERROR "Revise proposal to satisfy constitution"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md (focus on reference alignment and constraints)
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 8. Subsequent phases are delegated to other commands.

## Summary
Garantir funcionamento perfeito da UI do JFlutter através de testes de widget abrangentes, correção de canvases (FSA/PDA/TM) para renderização touch-optimized, eliminação de bloqueios de layout em todas as resoluções de tela, implementação de componentes de erro (banner inline, diálogo de importação, botão retry), e estabelecimento de infraestrutura de golden tests para regressão visual cross-platform.

## Technical Context
**Language/Version**: Flutter 3.22+/Dart 3.x  
**Primary Dependencies**: flutter_test, golden_toolkit, flutter_riverpod 2.6.1, freezed, vector_math, petitparser  
**Storage**: Local sandbox (manual save snapshots), no auto-save  
**Testing**: Widget tests (11 failing → fix), golden tests (new infrastructure), integration tests (existing)  
**Target Platform**: iOS, Android, Web, Desktop (mobile-first priority)  
**Project Type**: mobile-first Flutter  
**Performance Goals**: ≥60fps canvas rendering, p95 frame time <20ms, memory <400MB, support >10k simulation steps  
**Constraints**: Offline-first, no telemetry, sandboxed storage, manual saves only, best-effort accessibility (Flutter guidelines, no formal WCAG)  
**Scope/Scale**: Widget tests validate up to 20 states and 50 transitions (focus on correctness over scale)  
**CI/CD Policy**: Widget test failures warn but allow merge (manual review before deployment)

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Mobile-First Didactic Delivery**: ✅ Feature enhances mobile learning experience with touch-optimized canvases, responsive layouts, and offline usability
- **Curricular Scope Fidelity**: ✅ UI improvements support existing syllabus (FA/PDA/TM/CFG); no new educational content introduced
- **Reference-Led Algorithm Port**: ✅ Canvas rendering and widget behavior align with JFLAP visual specifications where applicable; no algorithmic changes
- **Layered Architecture & Immutability**: ✅ Widgets in `lib/presentation/widgets/`, state via Riverpod providers in `lib/presentation/providers/`, painters for rendering, no architecture violations
- **Quality/Performance/Licensing Assurance**: ✅ Comprehensive widget tests planned, golden tests for visual regression, `flutter analyze` enforcement, 60fps target, Apache-2.0 licensing
- **Scope & Interoperability Standards**: ✅ Canvas supports `.jff` import rendering, SVG export preservation, immutable trace visualization maintained
- **Architecture & Implementation Requirements**: ✅ Widgets remain in presentation layer, test selectors adapt to current structure, DTOs unchanged, no layer boundary violations

**All checks PASS** - No constitutional violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)
```
specs/003-ui-improvement-taskforce/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 findings (current widget issues, test infrastructure gaps)
├── data-model.md        # Phase 1 domain models (UI component models, test fixtures)
├── quickstart.md        # Phase 1 manual UI validation script
├── contracts/           # Phase 1 widget contracts and test expectations
└── tasks.md             # Phase 2 output (/tasks command)
```

### Source Code (Flutter project)
```
lib/
├── presentation/
│   ├── widgets/
│   │   ├── automaton_canvas.dart          # FSA canvas (fix multi-CustomPaint structure)
│   │   ├── pda_canvas.dart                # PDA canvas (verify stack rendering)
│   │   ├── tm_canvas.dart                 # TM canvas (verify tape rendering)
│   │   ├── simulation_panel.dart          # Simulation UI (update structure)
│   │   ├── error_banner.dart              # NEW: Inline error banner
│   │   ├── import_error_dialog.dart       # NEW: Import error dialog
│   │   └── retry_button.dart              # NEW: Retry button widget
│   └── providers/
│       ├── fsa_provider.dart              # FSA state management
│       ├── pda_provider.dart              # PDA state management
│       └── tm_provider.dart               # TM state management
test/
├── widget/
│   └── presentation/
│       ├── immutable_traces_visualization_test.dart  # Fix 8 failures
│       ├── ux_error_handling_test.dart              # Fix 3 failures (missing widgets)
│       └── visualizations_test.dart                 # Implement golden tests
└── integration/
    └── io/
        └── interoperability_roundtrip_test.dart     # Existing (19 failures - separate issue)
```

**Structure Decision**: Fix existing widget structure issues without architectural changes; add missing error handling widgets in `lib/presentation/widgets/`; establish golden test infrastructure in `test/widget/`.

## Phase 0: Outline & Research

### Objectives
1. Document current widget test failures and root causes
2. Identify gaps in UI component implementation (missing error widgets)
3. Map canvas rendering issues (FSA/PDA/TM specific problems)
4. Survey golden test infrastructure requirements
5. Review Flutter/Riverpod testing best practices from existing codebase

### Research Areas

**Current Widget Test Status** (from README.md):
- 11 widget tests failing total
- `immutable_traces_visualization_test.dart`: 8 failures
  - Issue: Multiple CustomPaint widgets found (expects exactly one)
  - Affected: AutomatonCanvas, SimulationPanel rendering tests
- `ux_error_handling_test.dart`: 3 failures
  - Issue: Missing widgets (error_banner.dart, import_error_dialog.dart, retry_button.dart)
- `visualizations_test.dart`: Golden test infrastructure not implemented

**Canvas Architecture Review**:
- AutomatonCanvas uses TouchGestureHandler wrapping CustomPaint
- Multiple CustomPaint layers for gestures, rendering, trace overlay
- Widget test selectors need hierarchical navigation (find.descendant)

**References**:
- Flutter widget testing docs: https://docs.flutter.dev/testing/overview#widget-tests
- Golden toolkit: https://pub.dev/packages/golden_toolkit
- Existing test patterns in `test/unit/` for reference
- JFLAP visual specifications (where applicable for canvas rendering)

**Output**: research.md documenting test failures, missing widgets, canvas structure issues, and golden test setup requirements.

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

### Objectives
1. Define immutable widget test fixture models
2. Specify error handling widget contracts (ErrorBanner, ImportErrorDialog, RetryButton)
3. Design golden test expectations for each canvas type
4. Plan widget test selector strategies for multi-CustomPaint structures
5. Create quickstart manual UI validation script

### Deliverables

**data-model.md**: Widget component models
- TestFixtureAutomaton (FSA/PDA/TM variants with ≤20 states, ≤50 transitions)
- ErrorUIState (banner, dialog, button states)
- GoldenTestExpectation (canvas snapshots, responsive breakpoints)
- WidgetTestContext (selector strategies, navigation patterns)

**contracts/** directory:
- `error_handling_contract.md`: ErrorBanner, ImportErrorDialog, RetryButton API specs
- `widget_test_contract.md`: Test selector patterns, fixture constraints, assertion strategies
- `golden_test_contract.md`: Snapshot naming conventions, breakpoints (mobile <600px, tablet <1024px, desktop ≥1024px), update procedures
- `canvas_rendering_contract.md`: CustomPaint hierarchy expectations, trace overlay specifications

**quickstart.md**: Manual UI validation workflow
1. Launch app on physical device (iOS/Android) and simulator
2. Test FSA canvas: create states, add transitions, simulate with trace visualization
3. Test PDA canvas: stack rendering, push/pop visualization, acceptance modes
4. Test TM canvas: tape rendering, head movement, halt states
5. Test error handling: import invalid .jff, verify banner/dialog/retry flow
6. Test responsive layouts: verify no blocked buttons at 375px, 320px widths
7. Verify accessibility: screen reader labels, touch target sizes
8. Performance check: canvas renders at 60fps with 20-state automaton

**Agent context update**: Run `.specify/scripts/bash/update-agent-context.sh cursor` to refresh AI context with new widget architecture

**Output**: data-model.md, contracts/*.md, quickstart.md, updated agent context

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

### Task Generation Strategy
- **TDD-First**: Write failing widget tests before fixing widgets
- **Priority Order**: FSA canvas → PDA canvas → TM canvas (per clarifications)
- **Parallel Opportunities**: Missing error widgets can be implemented in parallel; golden test infrastructure separate from functional fixes
- **Test Fixture Bounds**: All tests use small fixtures (≤20 states, ≤50 transitions)

### Task Categories

**Setup & Infrastructure** (3-5 tasks):
- Configure golden_toolkit and test infrastructure
- Create widget test fixtures and helpers
- Set up CI/CD widget test warning (non-blocking)

**Widget Test Fixes** (8-10 tasks):
- Fix AutomatonCanvas test selectors (find.descendant for multi-CustomPaint)
- Fix SimulationPanel widget structure tests
- Update trace visualization widget tests
- Fix performance test helpers

**Missing Widgets Implementation** (3-4 tasks):
- Implement ErrorBanner widget + tests
- Implement ImportErrorDialog widget + tests
- Implement RetryButton widget + tests
- Integration: wire error widgets into existing flows

**Canvas Rendering Validation** (6-8 tasks):
- Validate FSA canvas rendering (states, transitions, traces)
- Validate PDA canvas rendering (stack, push/pop visualization)
- Validate TM canvas rendering (tape, head, halt states)
- Fix layout blocking issues at small screen sizes

**Golden Test Infrastructure** (4-6 tasks):
- Implement golden test infrastructure
- Create golden files for FSA/PDA/TM canvases
- Create golden files for simulation panels
- Create golden files for error dialogs

**Accessibility & Polish** (3-4 tasks):
- Validate Flutter accessibility guidelines compliance
- Add semantic labels and touch targets
- Test keyboard/switch control navigation
- Visual unsaved work indicators

**Documentation & Validation** (2-3 tasks):
- Run `flutter analyze` and fix issues
- Execute quickstart manual validation
- Document test coverage and remaining issues

### Ordering Strategy
```
Phase T1: Setup (parallel setup tasks)
  → T001: Configure golden_toolkit
  → T002: Create test fixtures
  → T003: Update CI/CD for warning-only widget tests

Phase T2: Fix Existing Tests (sequential by priority)
  → T004: Fix AutomatonCanvas test selectors
  → T005: Fix SimulationPanel tests
  → T006: Fix trace visualization tests

Phase T3: Missing Widgets (parallel implementation)
  → T007: ErrorBanner implementation + tests
  → T008: ImportErrorDialog implementation + tests
  → T009: RetryButton implementation + tests

Phase T4: Canvas Validation (sequential FSA→PDA→TM)
  → T010: FSA canvas rendering validation
  → T011: PDA canvas rendering validation
  → T012: TM canvas rendering validation
  → T013: Fix layout blocking issues

Phase T5: Golden Tests (parallel by component)
  → T014: Golden infrastructure setup
  → T015: FSA/PDA/TM canvas goldens
  → T016: Simulation panel goldens
  → T017: Error dialog goldens

Phase T6: Accessibility (parallel with Phase T5)
  → T018: Accessibility compliance validation
  → T019: Semantic labels and touch targets

Phase T7: QA & Documentation
  → T020: flutter analyze + fixes
  → T021: Manual quickstart validation
  → T022: Document coverage report
```

**Estimated Output**: 22-25 tasks covering setup, test fixes, widget implementation, canvas validation, golden tests, accessibility, and QA.

**Parallel Execution Guidance**:
- Phase T1 tasks run in parallel (different setup areas)
- Phase T3 tasks run in parallel (independent widgets)
- Phase T5 tasks run in parallel (independent golden files)
- Phase T2, T4 follow priority order (FSA→PDA→TM)

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: /tasks generates tasks.md with 22-25 concrete tasks  
**Phase 4**: Execute tasks following TDD and constitution  
**Phase 5**: Validate via widget tests (all passing), quickstart (manual), golden tests (visual regression), flutter analyze (clean)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

No constitutional violations detected. No entries required.

## Progress Tracking
*Update during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) ✅
- [x] Phase 1: Design complete (/plan command) ✅
- [x] Phase 2: Task planning approach documented (/plan command) ✅
- [x] Phase 3: Tasks generated (/tasks command) ✅ → 23 tasks ready for execution
- [ ] Phase 4: Implementation complete → Execute tasks T001-T023
- [ ] Phase 5: Validation passed → Run quickstart, verify all tests pass

**Gate Status**:
- [x] Initial Constitution Check: PASS ✅
- [x] Post-Design Constitution Check: PASS ✅
- [x] All NEEDS CLARIFICATION resolved (10 Q&A in spec) ✅
- [x] Complexity deviations documented (none - no violations) ✅

**Artifacts Generated**:
- [x] research.md - Widget test failures, canvas architecture, golden test requirements
- [x] data-model.md - UI component models, test fixtures, golden expectations
- [x] contracts/error_handling_contract.md - ErrorBanner, ImportErrorDialog, RetryButton specs
- [x] contracts/widget_test_contract.md - Test selectors, patterns, fixture constraints
- [x] contracts/golden_test_contract.md - Visual regression infrastructure, naming, procedures
- [x] contracts/canvas_rendering_contract.md - Rendering specs, hierarchy, performance
- [x] quickstart.md - Manual UI validation workflow

---
*Based on Constitution v2.0.0 - See `.specify/memory/constitution.md`*
