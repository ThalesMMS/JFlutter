# JFlutter – Assistant Quick Reference

## Current Status
- Core UI, navigation, file operations, and major simulations are complete. Focus new work on test coverage, performance for large automata, and accessibility improvements.【F:COMPILATION_STATUS.md†L12-L86】【F:COMPILATION_STATUS.md†L96-L125】
- Existing integration and contract tests cover critical flows; prioritize adding missing unit and widget tests before extending features.【F:COMPILATION_STATUS.md†L60-L103】

## Build & Validation Flow
1. `flutter pub get` – install/update dependencies.
2. `flutter analyze` – enforce lint rules (`analysis_options.yaml`).
3. `flutter test` – runs integration/contract suites (CI-critical).
4. Use `flutter run` for manual smoke checks on target platform.

## Key Dependencies & Architecture
- Flutter 3.16+/Dart 3.0+ with Clean Architecture layers; Riverpod is the primary state management, complemented by Provider and GetIt for legacy points.【F:pubspec.yaml†L1-L47】【F:pubspec.yaml†L56-L74】
- Platform capabilities rely on `shared_preferences`, `path_provider`, `share_plus`, `xml`, `file_picker`, `vector_math`, and `collection`; verify compatibility when upgrading Flutter SDK or platform targets.【F:pubspec.yaml†L40-L74】

## High-Priority Tasks
- Expand automated unit/widget coverage for models, services, and UI components (see `test/` integration suites for reference patterns).【F:COMPILATION_STATUS.md†L60-L103】【F:DEVELOPMENT_LOG.md†L5-L31】
- Profile large automata scenarios and optimize rendering/algorithms before feature additions.【F:COMPILATION_STATUS.md†L66-L103】
- Begin accessibility enhancements (screen reader, keyboard navigation, contrast modes) alongside UX polish.【F:COMPILATION_STATUS.md†L66-L110】

## Useful References
- [README](README.md) – feature overview & platform notes.
- [PROJECT_STRUCTURE](PROJECT_STRUCTURE.md) – layer breakdown.
- [DEVELOPMENT_LOG](DEVELOPMENT_LOG.md) – latest testing and service additions.
- [COMPILATION_STATUS](COMPILATION_STATUS.md) – prioritized backlog snapshot.

Keep updates concise, prefer targeted fixes/tests over broad refactors, and document notable workflow changes in DEVELOPMENT_LOG.
