# Repository Guidelines

## Project Structure & Module Organization
- `lib/` hosts production code. Core logic lives in `lib/core/`, while UI and state management sit in `lib/presentation/`. Services and repositories reside in `lib/data/`.  
- `References/` contains the authoritative implementations (Dart and Python) used to validate every algorithm during the migration—consult them before modifying core behaviour.  
- Platform-specific folders (`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`) keep native configuration. Auxiliary documentation stays in the repo root (README, API docs, specs).

## Build, Test, and Development Commands
- `flutter pub get` – install dependencies.  
- `flutter run -d <device>` – launch the app on a simulator or connected device (e.g., `flutter run -d macos`).  
- `flutter build <platform>` – produce release artifacts (`flutter build apk`, `flutter build macos`).  
- `flutter analyze` – lint the entire project. Use this as the default verification step until the new test suite is reinstated.

## Coding Style & Naming Conventions
- Follow Dart best practices: 2‑space indentation, `lowerCamelCase` variables, `UpperCamelCase` types, `SCREAMING_SNAKE_CASE` constants.  
- Keep one top-level declaration per file and prefer descriptive filenames (`automaton_service.dart`, `tm_canvas.dart`).  
- Run `dart format .` before committing. Riverpod providers should remain immutable and favour explicit state models.

## Testing Guidelines
- Historical tests were removed for the algorithm migration. New modules must reintroduce targeted tests under a rebuilt `test/` tree mirroring `lib/`.  
- Use `flutter test` once new suites exist and document any coverage thresholds in the related PR.  
- Until then, rely on manual verification plus `flutter analyze` and note tested flows in pull requests.

## Commit & Pull Request Guidelines
- Commit messages typically follow `<scope>: <summary>` (e.g., `core: add dfa minimizer`); mention the origin reference when porting logic.  
- Pull requests should: describe the change, cite the reference implementation (path + repo inside `References/`), list verification steps, and attach UI captures when relevant.  
- Keep branches rebased on `main` and ensure `flutter analyze` passes before requesting review.

## Reference Implementation Workflow
- Every algorithm or structure modification must be cross‑checked against the corresponding project in `References/` (for example, `References/dart-petitparser-examples-main/` or `References/automata-main/`).  
- Record deviations from the reference in code comments or PR notes, explaining platform constraints or optimizations.  
- Update documentation when a reference is superseded or deemed insufficient.
