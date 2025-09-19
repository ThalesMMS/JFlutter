# Claude Code Assistant Context - JFlutter Project

**Last Updated**: 2024-12-19  
**Feature**: 001-description-port-jflap

## Project Overview
JFlutter is a Flutter mobile port of JFLAP (Java Formal Languages and Automata Package), optimized for mobile devices with touch-optimized interface and same section divisions as desktop JFLAP.

## Technical Stack
- **Language**: Dart 3.0+, Flutter 3.16+
- **Platform**: iOS 12+, Android API 21+
- **Architecture**: Clean Architecture with Provider/Riverpod state management
- **Storage**: Local file system (JSON/XML), SharedPreferences
- **Testing**: Flutter test framework, widget tests, integration tests

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
- Mealy machine simulation
- Turing machine with building blocks

## Mobile-Specific Considerations
- Touch-optimized UI with 44dp minimum touch targets
- Pinch-to-zoom and pan gestures for automaton viewing
- Responsive layout adapting to screen sizes
- Offline operation with local file storage
- Performance optimization for mobile devices (200 state limit)

## Recent Changes
- Created comprehensive feature specification
- Designed mobile-optimized data models
- Established API contracts for local services
- Defined testing strategy and quickstart scenarios

## Development Priorities
1. **Phase 1**: Mobile UI foundation with basic FSA operations
2. **Phase 2**: Core algorithms (NFA→DFA, minimization, regex conversion)
3. **Phase 3**: Grammar-automaton conversions (LL, LR, SLR)
4. **Phase 4**: Advanced features (PDA, TM with building blocks, Mealy machines)
5. **Phase 5**: Interactive features (pumping lemma games)
6. **Phase 6**: Performance optimization and testing

## Code Standards
- Follow Flutter/Dart best practices
- Use clean architecture principles
- Implement comprehensive testing
- Maintain accessibility standards (WCAG 2.1 AA)
- Optimize for mobile performance and battery life

## Key Files
- `/specs/001-description-port-jflap/spec.md` - Feature specification
- `/specs/001-description-port-jflap/plan.md` - Implementation plan
- `/specs/001-description-port-jflap/data-model.md` - Data structures
- `/JFLAP_source/` - Original Java reference implementation