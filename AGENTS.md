# Repository Guidelines

## Project Snapshot
- JFlutter is a mobile-first Flutter rebuild of the classic JFLAP tooling, currently **work in progress** but feature-complete for core automata workflows.
- Focus areas: interactive automaton canvas, real-time simulations, 13 validated algorithms, offline examples in `jflutter_js/examples/`, and Material 3 UI with responsive layouts.
- Target platforms: Android, iOS, Web, Windows, macOS, and Linux (touch-optimized where applicable).

## Source Layout & Ownership
- `lib/` contains production code following clean architecture:
  - `lib/core/` algorithms, entities, models, use cases, logging, and error handling.
  - `lib/data/` data sources, DTOs, repositories, and services.
  - `lib/presentation/` pages, widgets, providers, theming, plus supporting features in `lib/features/` and dependency setup in `lib/injection/`.
- `References/` hosts the authoritative Dart and Python implementations that back every algorithm; consult them before altering logic.
- Platform folders (`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`) contain native config. Docs, specs, and screenshots live at the repo root.

## Build & Tooling
- `flutter pub get` – install dependencies.
- `flutter run -d <device>` – start the app (e.g., `flutter run -d macos`).
- `flutter build <platform>` – create release artifacts (`apk`, `macos`, etc.).
- `flutter analyze` – default static analysis gate before review.
- Android signing uses `android/scripts/create_key_properties.sh` fed by `JFLUTTER_KEYSTORE_*` env vars; see README for the release workflow.

## Testing Status & Expectations
- Current suite: **264 / 283 tests passing (93.3% overall)**; core algorithm coverage is 242 / 242 (**100%**).
- Known failures you should not regress:
  - **Import/Export integration tests** – 19 failures tied to JFF epsilon serialization and SVG formatting (viewBox precision, empty automata).
  - **Widget tests** – 11 failures due to missing widgets (`error_banner.dart`, `import_error_dialog.dart`, `retry_button.dart`), outdated finders, and absent golden infra.
- Recommended commands:
  - `flutter test` – full suite (expect the failures above).
  - `flutter test test/unit/` – core algorithms (all passing).
  - `flutter analyze` – always run when touching Dart code.
- Document any additional deviations; avoid introducing new failures within the passing suites.

## Coding Style & Naming
- Follow Dart idioms: 2-space indentation, `lowerCamelCase` variables, `UpperCamelCase` types, `SCREAMING_SNAKE_CASE` constants.
- Prefer one top-level declaration per file with descriptive filenames (`automaton_service.dart`, `tm_canvas.dart`).
- Keep Riverpod providers immutable and model-driven; run `dart format .` before committing.

## Contribution Workflow
- Commits: `<scope>: <summary>` (e.g., `core: add dfa minimizer`). Cite the source repo/path from `References/` when porting logic.
- PRs should summarize changes, list reference touchpoints, call out test/analysis runs, and include UI captures when relevant. Keep branches rebased on `main` and lint-clean.

## Reference Implementation Process
- For any algorithm/data-structure change: cross-check against the paired project in `References/` (`automata-main`, `dart-petitparser-examples`, `AutomataTheory`, `nfa_2_dfa`, `turing-machine-generator`, etc.).
- Validate outputs against reference expectations, benchmark when performance-sensitive, and log intentional deviations in code comments or `docs/reference-deviations.md`.
- Update documentation if a reference is replaced or no longer authoritative.
