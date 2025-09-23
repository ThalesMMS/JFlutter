# Claude Code Assistant Context - JFlutter Project

**Last Updated**: 2025-09-23
**Feature**: 001-description-port-jflap

## Project Overview
JFlutter is a Flutter mobile port of JFLAP (Java Formal Languages and Automata Package), optimized for mobile devices with touch-optimized interface and same section divisions as desktop JFLAP.

## Technical Stack
- **Language**: Dart 3.0+, Flutter 3.16+
- **Platform**: iOS 12+, Android API 21+
- **Architecture**: Clean Architecture (Presentation/Core/Data) with Riverpod & Provider orchestrated through GetIt
- **Storage**: Local file system (JSON/XML), SharedPreferences
- **Testing**: flutter_test suite (unit, widget, integration, contract)

## Key Technologies
- Flutter SDK for cross-platform mobile development
- Provider pattern with Riverpod for state management
- Custom gesture recognizers for automaton editing
- JSON serialization for file persistence
- Canvas-based rendering for automaton visualization

## Project Structure
```
lib/
├── core/                # Core algorithms and data structures
│   ├── automata/        # FSA, PDA, TM implementations
│   ├── grammar/         # Grammar parsing and transformations
│   ├── algorithms/      # NFA→DFA, minimization, parsing
│   └── models/          # Data models and entities
├── presentation/        # UI layer
│   ├── pages/           # Main screens (same sections as JFLAP)
│   ├── widgets/         # Reusable UI components
│   └── providers/       # State management
├── data/                # Data layer
│   ├── repositories/    # Data access
│   └── data_sources/    # File I/O, persistence
└── injection/           # Dependency injection
```

## Core Algorithms (from JFLAP_source)
- NFA to DFA conversion (subset construction)
- DFA minimization (Hopcroft's algorithm)
- Regular expression to NFA (Thompson's construction)
- FA to Regular Expression (state elimination)
- LL/LR/SLR parsing with parse table generation
- CYK parsing with dynamic programming
- Brute force parser for unrestricted grammars
- Grammar transformations (Chomsky NF, lambda removal)
- CFG to PDA conversion (LL and LR methods)
- PDA to CFG conversion
- Right-linear grammar to FA conversion
- Pumping lemma games for regular and context-free languages
- L-system interpretation and visualization
- Turing machine with building blocks

## Mobile-Specific Considerations
- Touch-optimized UI with 44dp minimum touch targets
- Pinch-to-zoom and pan gestures for automaton viewing
- Responsive layout adapting to screen sizes
- Offline operation with local file storage
- Performance optimization for mobile devices (200 state limit)

## Weekly Snapshot (2025-09-23)
- **Architecture**: Clean Architecture layering reaffirmed; dependency injection consolidated via GetIt to simplify wiring between presentation providers and data services.
- **Completed Areas**: Full mobile UI implementation (all primary pages and reusable widgets), touch gesture handler, comprehensive file operations service with JFLAP XML + SVG support, expanded integration and contract test suites.
- **Quality Status**: UI feature set considered feature-complete; automated tests cover end-to-end workflows, while granular unit coverage remains outstanding.

## Current Priorities
1. **High** – Expand unit test coverage across core models, algorithms, services, and widgets.
2. **Medium** – Profile and optimize performance for large automata (memory + rendering).
3. **Low** – Implement accessibility enhancements (screen readers, keyboard navigation, high-contrast themes).

## In Progress / Upcoming Tasks
- Execute Phase 1 testing push (unit coverage and targeted performance validations).
- Prepare accessibility roadmap once testing milestones are met.

## Code Standards
- Follow Flutter/Dart best practices
- Use clean architecture principles
- Implement comprehensive testing
- Maintain accessibility standards (WCAG 2.1 AA)
- Optimize for mobile performance and battery life

## Key Files & References
- `/specs/001-description-port-jflap/spec.md` – Feature specification
- `/specs/001-description-port-jflap/plan.md` – Implementation plan
- `/specs/001-description-port-jflap/data-model.md` – Data structures
- `/DEVELOPMENT_LOG.md` – Weekly progress + remaining work
- `/PROJECT_STRUCTURE.md` – Architecture breakdown
- `/JFLAP_source/` – Original Java reference implementation
