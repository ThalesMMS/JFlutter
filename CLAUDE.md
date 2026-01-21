# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JFlutter is a Flutter-based educational application reimplementing JFLAP (Java Formal Language and Automata Package). It provides an interactive workspace for creating, analyzing, and simulating finite automata (DFA/NFA), context-free grammars, pushdown automata, Turing machines, and regular expressions.

**Requirements**: Flutter SDK ≥3.24.0, Dart SDK ^3.8.0

## Essential Commands

```bash
flutter pub get              # Install dependencies
flutter run -d <device>      # Run app (macos, android, ios, etc.)
flutter test                 # Full test suite (264/283 passing)
flutter test test/unit/      # Core algorithms only (100% passing)
flutter analyze              # Static analysis (required before commits)
dart format .                # Format code
tool/codegen.sh              # Generate Freezed/JSON code
```

## Architecture

Clean Architecture with three layers:

- **lib/core/** - Business logic: algorithms (13+ validated), models (Freezed immutables), entities, use cases, validators
- **lib/data/** - Persistence: data sources, DTOs, repository implementations, services
- **lib/presentation/** - UI: pages, widgets, Riverpod providers, Material 3 theming
- **lib/features/** - Cross-cutting concerns (canvas/graphview controllers, highlight channels)
- **lib/injection/** - Dependency injection setup

### Key Files

- `lib/core/algorithms/` - All automata algorithms (DFA/NFA, CFG, PDA, TM, regex)
- `lib/presentation/providers/automaton_provider.dart` - Main state manager
- `lib/features/canvas/graphview/graphview_canvas_controller.dart` - Canvas orchestration
- `lib/data/services/trace_persistence_service.dart` - Trace storage

## Testing

- **264/283 tests passing** (93.3% overall)
- **Core algorithms: 100%** (242/242) - run with `flutter test test/unit/`
- Known failures:
  - Import/export: 19 failures (epsilon serialization, SVG formatting)
  - Widget tests: 11 failures (missing design system components)

Run `flutter test` before commits. Do not introduce regressions in passing suites.

## Reference Implementations

The `References/` directory contains authoritative implementations that validate every algorithm. When modifying algorithm logic:

1. Cross-check against paired reference project (`automata-main`, `dart-petitparser-examples`, `AutomataTheory`, `nfa_2_dfa`, `turing-machine-generator`)
2. Validate outputs match reference expectations
3. Log intentional deviations in code comments or `docs/reference-deviations.md`

## Coding Conventions

- 2-space indentation, `lowerCamelCase` variables, `UpperCamelCase` types
- One top-level declaration per file with descriptive names
- Riverpod providers: immutable and model-driven
- Freezed for all domain models
- Run `dart format .` before committing

## Commit Format

`<scope>: <summary>` (e.g., `core: add dfa minimizer`)

Cite the source repo/path from `References/` when porting logic.

## Additional Documentation

- `AGENTS.md` - Contribution guidelines and test status
- `PROJECT_STRUCTURE.md` - Detailed directory breakdown
- `USER_GUIDE` - GraphView canvas working guide
- `docs/` - 53 technical documents covering architecture, canvas system, algorithms
