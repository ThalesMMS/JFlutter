# Critical Issues - Quick Reference

## 🆕 Weekly Incident Highlights
- **SVG Export Escaping Fix** (`lib/data/services/file_operations_service.dart`, PR #105): Exported SVGs were emitting raw labels, breaking files that contained characters such as `&` or `<`. A helper now escapes text before serialization, but JFLAP XML builders still write raw labels and remain untested for these cases.
- **File Operations Panel Lifecycle Errors** (`lib/presentation/widgets/file_operations_panel.dart`, PR #107): Repeated user flows triggered `setState` on disposed widgets and surfaced inaccessible file paths when the picker returned `null`. Mounted guards and shared loading helpers were added, signalling similar risks across other panels that call asynchronous services.
- **Turing Machine Page Subscription Leak** (`lib/presentation/pages/tm_page.dart`, PR #108): The metrics controller listener was never closed, causing duplicate updates on rebuild. A `ProviderSubscription` is now tracked and disposed, highlighting the need to audit other pages that listen to editors.
- **TM Canvas Transition Dialog Safety** (`lib/presentation/widgets/tm_canvas.dart`, PR #106): Transition dialogs could resolve after the canvas unmounted, leading to `setState` crashes. New `mounted` checks mitigate this, but other canvases still lack the safeguards.
- **PDA Simulation Panel Regression Tests** (`test/presentation/widgets/pda_simulation_panel_test.dart`, PR #109): New widget coverage captures empty-input and missing-PDA flows. Equivalent regression tests are still absent for DFA/TM simulation panels.

## 🚨 IMMEDIATE PRIORITIES

### 1. File Operations – Data Integrity & Async Safety
SVG export now survives special characters, yet `_buildJFLAPXML` and grammar exports continue to inject unescaped labels, risking corrupt files for users who name states with symbols. The async picker fixes in `FileOperationsPanel` reduced `setState`-after-dispose crashes, but other surfaces (e.g., save dialogs in `lib/presentation/pages/...`) still call `setState` after awaiting I/O. Audit all export/import paths in `FileOperationsService` and the panels that invoke them, add escaping helpers for XML outputs, and extend tests in `test/data/services/` to cover JFLAP round trips with special characters.

### 2. Turing Machine Lifecycle & Metrics Hygiene
`TMPage` now closes its metrics subscription, preventing listener accumulation when hot-reloading or navigating away. Similar `ref.listen` patterns exist on PDA/FSA pages and widgets like algorithm panels—confirm they manage `ProviderSubscription` lifecycles and guard async callbacks in canvases. Add targeted widget tests that mount/unmount these pages and assert that no duplicated updates or crashes occur.

### 3. Automated Test Coverage Expansion
Despite the new PDA simulation tests, `test/unit/models`, `test/unit/algorithms`, `test/unit/services`, and `test/widget/` remain empty. Prioritize fast unit suites for core algorithms and services referenced by the recent bug fixes (file operations, TM metrics). Use `TEST_COVERAGE_ASSESSMENT.md` as the roadmap and elevate high-signal widget tests for other simulation panels to catch parity regressions.

### 4. Settings & Help Regression Sweep
Settings (`lib/presentation/pages/settings_page.dart`) and Help (`lib/presentation/pages/help_page.dart`) flows haven’t changed this week, but they still lack regression tests around persistence, localization, and accessibility. Re-run QA with the updated storage helpers to ensure no regressions slipped in via shared repositories while file I/O code changed.

### 5. Accessibility & Performance Follow-Through
No new fixes landed for semantics or frame pacing. Continue auditing accessibility labels, keyboard navigation, and high-contrast themes while profiling large automata scenarios to confirm recent lifecycle changes did not regress rendering throughput.

## 🔧 QUICK ACTIONS
- **JFLAP Escaping Audit**: Introduce an `_escapeXml` helper for all XML builders and add regression tests that serialize/deserialize automata and grammars containing symbols like `&` and `<`.
- **Async Guard Sweep**: Search for `setState` calls after `await` in panels/widgets and add `mounted` checks or callback cancellers similar to `FileOperationsPanel` and `TMCanvas`.
- **Listener Lifecycle Checks**: Inventory every `ref.listen` usage and wrap them with tracked `ProviderSubscription`s that close in `dispose`.
- **Simulation Panel Parity Tests**: Mirror the new PDA widget tests for DFA and TM simulation panels to exercise success/failure flows and ensure SnackBars render as expected.
- **Settings/Help Regression Scripts**: Extend existing integration tests or add smoke tests that toggle preferences, reset defaults, and navigate Help deep links while asserting localized copy.

## 📋 PRIORITY ORDER
1. Harden file export/import flows for escaping, picker fallbacks, and async state safety.
2. Verify lifecycle management for editor listeners and canvas dialogs across TM/PDA/FSA pages.
3. Build out unit and widget coverage for high-risk services and panels.
4. Re-run Settings and Help QA with new storage and messaging paths.
5. Resume accessibility and performance polish after blockers above stabilize.

## 🎯 SUCCESS METRIC
```bash
flutter test test/data/services/file_operations_service_svg_test.dart
flutter test test/presentation/widgets/pda_simulation_panel_test.dart
flutter test
# Target: Specialized regressions stay green and full test suite passes
# after adding JFLAP escaping + lifecycle audits.
```

## 📊 CURRENT STATUS
- **Core Functionality**: ✅ Complete (85-90%)
- **UI Implementation**: ✅ Complete
- **Mobile Optimization**: ✅ Complete
- **File Operations**: ⚠️ SVG escaping fixed; JFLAP outputs still vulnerable to special characters and picker fallbacks need coverage
- **Test Suite**: ⚠️ Widget/unit coverage improving slowly; large directories remain empty
- **Remaining Focus**: File I/O hardening, listener lifecycle audits, targeted unit/widget tests, followed by Settings/Help QA and accessibility/perf polish
