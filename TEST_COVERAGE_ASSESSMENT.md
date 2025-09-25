# Test Coverage Assessment - JFlutter

## Latest Coverage Execution
- **Command**: `flutter test --coverage`
- **Execution Time**: 2025-09-23T10:10:08Z (UTC) *(container clock)*
- **Result**: ❌ Failed — Flutter SDK is not available in the current container (`bash: command not found: flutter`). No coverage artefacts were generated. The next run must either install Flutter locally or download the coverage report produced by CI (`make ci` / `scripts/ci_pipeline.sh`) before updating this section with execution metrics.

## Test Suite Inventory (2025-09-23)
The current `test/` tree contains 41 Dart test files (matching the `*_test.dart` pattern). Distribution by domain:

| Domain / Folder | Files | Notes |
| --- | ---: | --- |
| `test/data/` | 2 | Repository/service persistence coverage (SharedPreferences, SVG export). |
| `test/integration/` | 1 | Only the `home_fab_actions_test.dart` end-to-end flow remains after recent refactors. |
| `test/presentation/` | 18 | Riverpod view-models, widgets, and TM page coverage. |
| `test/unit/` | 15 | Core algorithm suites, repositories, and targeted presentation/unit helpers. |
| `test/widget/` | 4 | Legacy widget harnesses (PDA page, pumping lemma progress, settings page, transition dialog). |
| `widget_test.dart` | 1 | Default Flutter counter smoke test (still present). |
| `test/contract/`, `test/test_utils/` | 0 | No executable tests under these directories. |

### Unit Test Breakdown

| Sub-domain | Files | Coverage Focus |
| --- | ---: | --- |
| `unit/algorithms` | 8 | DFA minimizer, automaton simulator, regex/NFA converters, pumping lemma, grammar ↔ PDA, PDA simplification. |
| `unit/core` | 1 | `add_state_use_case`. |
| `unit/data` | 1 | Examples data source. |
| `unit/features` | 1 | Layout repository implementation. |
| `unit/presentation` | 3 | Automaton conversion providers, TM metrics controller. |
| `unit/repositories` | 1 | Automaton repository implementation. |
| `unit/models` | 0 | No discoverable model tests (legacy files exist without the `_test.dart` suffix, so they are ignored by Flutter). |

### Presentation Test Coverage Highlights
- Controllers for automaton conversion/creation/layout/simulation have focused coverage.
- Widget harnesses exist for PDA simulation panel, transition hit testing, regex panes, and TM analysis widgets.
- Settings and regex view models now include regression tests.

## Coverage Gaps and Opportunities
1. **Missing Flutter Coverage Artefact** – Until `flutter test --coverage` runs successfully (locally or via CI artefact), we cannot quantify statement/branch coverage. Prioritize fixing the toolchain so coverage can be tracked sprint-to-sprint.
2. **Model Layer Blind Spot** – `test/unit/models/` is still empty. Core automaton/grammar/TM model behaviour lacks regression protection.
3. **Contract Tests Deprecated** – Legacy contract suites were removed; reintroduce only if service contracts diverge significantly from integration coverage.
4. **Integration Regression Holes** – Only one integration test remains. Recent refactors around navigation, settings persistence, and TM flows are uncovered end-to-end.
5. **Widget Harness Modernisation** – Legacy widget tests (e.g., `pda_page_test.dart`) predate Riverpod migrations and no longer exercise the latest UI state management.

## New Tests Added This Week (since 2025-09-17)
- `test/data/repositories/shared_preferences_settings_repository_test.dart`
- `test/data/services/file_operations_service_svg_test.dart`
- `test/integration/home_fab_actions_test.dart`
- `test/presentation/pages/tm_page_test.dart`
- `test/presentation/providers/automaton/automaton_conversion_controller_test.dart`
- `test/presentation/providers/automaton/automaton_creation_controller_test.dart`
- `test/presentation/providers/automaton/automaton_layout_controller_test.dart`
- `test/presentation/providers/automaton/automaton_simulation_controller_test.dart`
- `test/presentation/providers/automaton_canvas_controller_test.dart`
- `test/presentation/providers/regex_page_view_model_test.dart`
- `test/presentation/providers/settings_view_model_test.dart`
- `test/presentation/providers/tm_algorithm_view_model_test.dart`
- `test/presentation/widgets/automaton_painter_test.dart`
- `test/presentation/widgets/gestures/canvas_transform_controller_test.dart`
- `test/presentation/widgets/gestures/transition_hit_tester_test.dart`
- `test/presentation/widgets/pda_simulation_panel_test.dart`
- `test/presentation/widgets/regex/regex_widgets_test.dart`
- `test/presentation/widgets/tm/analysis_header_test.dart`
- `test/presentation/widgets/tm/analysis_results_test.dart`
- `test/presentation/widgets/tm/focus_selector_test.dart`
- `test/presentation/widgets/tm/tm_algorithm_panel_test.dart`
- `test/unit/algorithms/algorithm_repository_impl_test.dart`
- `test/unit/algorithms/automaton_simulator_test.dart`
- `test/unit/algorithms/dfa_minimizer_test.dart`
- `test/unit/algorithms/fa_to_regex_converter_test.dart`
- `test/unit/algorithms/grammar_to_pda_converter_test.dart`
- `test/unit/algorithms/pda_simplification_test.dart`
- `test/unit/algorithms/pumping_lemma_game_test.dart`
- `test/unit/algorithms/regex_to_nfa_converter_test.dart`
- `test/unit/core/use_cases/add_state_use_case_test.dart`
- `test/unit/data/examples_data_source_test.dart`
- `test/unit/features/layout_repository_impl_test.dart`
- `test/unit/presentation/automaton_provider_conversion_test.dart`
- `test/unit/presentation/automaton_provider_large_conversion_test.dart`
- `test/unit/presentation/providers/tm_metrics_controller_test.dart`
- `test/unit/repositories/automaton_repository_impl_test.dart`
- `test/widget/pda_page_test.dart`
- `test/widget/pumping_lemma_progress_test.dart`
- `test/widget/settings_page_test.dart`
- `test/widget/transition_symbol_dialog_test.dart`
- `test/widget_test.dart`
- *(Support file)* `test/presentation/providers/automaton/test_helpers.dart`

*(Derived from `git log --since="1 week ago" --diff-filter=A -- test/`.)*

## Recommended Next Steps
1. **Restore Automated Coverage Reporting**
   - Install Flutter SDK in the local environment or fetch CI-generated `coverage/lcov.info` before each update cycle.
   - Publish summary metrics (overall %, per-package) once artefacts are available.
2. **Model Regression Suite**
   - Add targeted tests for automaton, state, transition, grammar, PDA, and TM models covering serialization, validation, and edge cases.
3. **Integration Path Smoke Tests**
   - Recreate end-to-end flows for settings persistence, regex workspace, TM analysis, and PDA conversions to guard Riverpod controllers.
4. **Widget Harness Refresh**
   - Replace legacy widget tests with new golden/widget harnesses aligned with current widgets (canvas painter, metrics panels, dialog flows).
5. **Service Layer Coverage**
   - Expand `test/data/` to include negative scenarios (I/O errors, malformed SVG) and coverage for any remaining repositories/services.

---
*Last updated: 2025-09-23*
