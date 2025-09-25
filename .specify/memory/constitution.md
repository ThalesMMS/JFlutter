<!-- 
Sync Impact Report:
Version change: 1.2.0 → 1.2.1
Modified principles: V. Scope & Interoperability (clarified "Out-of-Scope Features" section)
Templates requiring updates: ✅ .specify/templates/plan-template.md
Follow-up TODOs: None
-->

# JFlutter Constitution

## Core Principles

### I. Educational Focus (NON-NEGOTIABLE)
JFlutter MUST serve as a modern, mobile-first educational tool for formal language theory and automata. The primary purpose is academic/educational with UX optimized for touch and small screens. Zero dependency on backend services. All features must align with the Fundamentals of Theoretical Computer Science curriculum, covering: Formal Languages, Regular Expressions, Grammars, Automata, Turing Machines, Chomsky Hierarchy, and Decidability.

### II. Mobile-First Design (NON-NEGOTIABLE)
All UI/UX MUST be designed mobile-first with Material 3, touch gestures (pinch, pan), collapsible panels, and overflow prevention. Visualizations MUST provide step-by-step algorithm execution with "class mode" focusing on traces and explanations. Basic accessibility (labels, contrast) is mandatory. The app MUST maintain 60fps canvas performance on modern hardware.

### III. Clean Architecture (NON-NEGOTIABLE)
MUST implement clean architecture with clear separation: Presentation/Core/Data layers. Progressive extraction to pure Dart packages under `packages/`: `core_fa`, `core_pda`, `core_tm`, `core_regex`, `conversions`, `serializers`, `viz`, `playground`. Unified abstractions: `Alphabet`, `State`, `Transition`, `Configuration<T>`, `Trace`. Riverpod for state management, `freezed`/sealed classes for immutability, `json_serializable` for DTOs.

### IV. Test-First Quality (NON-NEGOTIABLE)
MUST maintain comprehensive testing: unit, integration, widget, golden tests. Regression testing based on canonical examples. Rigorous static analysis and linting (`very_good_analysis` or `lint`). Deterministic tests for algorithms with immutable traces providing time-travel capability. Each execution MUST record configurations, steps, and results (serializable).

### V. Scope & Interoperability
MUST implement core automata features: FA simulation/NFA→DFA, minimization, FA↔Regex, language operations (∪, ∩, ¬, \, ·, *, reverse, shuffle), properties (empty, finite, equivalence). PDA with multiple acceptance modes, CFG↔PDA conversions, Turing Machine simulation with immutable tape configurations. MUST maintain `.jff` compatibility (import/export), stable JSON schemas, versioned example library, SVG/PNG export capabilities.

#### Out-of-Scope Features (NON-NEGOTIABLE)
To maintain alignment with the core curriculum, the following are explicitly excluded:
- **Advanced Parsing Techniques**: Any form of LR or SLR(1) parsing. This includes parsing table generation, shift/reduce conflict resolution, and any associated conversion algorithms.
- **Unrestricted Grammar Parsing**: Brute-force parsers for Unrestricted Grammars (GI) are excluded. Any features, such as algorithm comparisons, that depend on such a parser are also out of scope.
- **L-Systems**: The entire L-Systems module is out of scope, including any features related to turtle graphics or fractals.

## Technology Standards (NON-NEGOTIABLE)

### Flutter & Dart Requirements
- Flutter 3.16+ / Dart 3.0+
- `dart analyze`, `flutter test --coverage`
- Pre-commit hooks for formatting and linting
- Structured logging and error handling
- Performance budgets: >10k simulation steps with responsive UI (throttling and batched paints)

### Security & File Handling
- Sandboxed file operations
- Validation of `.jff`/JSON inputs
- Prevention of path traversal attacks
- No dynamic eval or code execution
- Secure keystore management for Android releases

## Deliverables & Gates

### Minimum Viable Releases
Each release MUST include:
- Validated `.jff` compatibility (import/export regression suite)
- Core FA with language operations and properties
- PDA with multiple acceptance modes
- Regex→AST→NFA pipeline
- TM with immutable traces
- Updated documentation: README, reproduction guides, contribution guidelines, public API docs

### Quality Gates
- All tests passing with coverage reporting
- Static analysis clean (no warnings/errors)
- Performance benchmarks met
- Mobile responsiveness verified
- Accessibility compliance checked

## License & Compliance

### Dual License Structure
- **New Flutter code**: Apache 2.0 (allows free use, modification, distribution)
- **Original JFLAP content**: JFLAP 7.1 License (non-commercial use only)
- `.jff` support is format compatibility only, not code incorporation
- License files MUST be maintained in repository

## Governance

All development MUST verify constitution compliance. Complexity deviations require documented justification. Amendments to this constitution require version increment according to semantic versioning:
- **MAJOR**: Backward incompatible principle changes
- **MINOR**: New principles or materially expanded guidance  
- **PATCH**: Clarifications, wording fixes, non-semantic refinements

The constitution supersedes all other development practices. All PRs/reviews MUST verify compliance with these principles.

**Version**: 1.2.1 | **Ratified**: 2025-01-27 | **Last Amended**: 2025-09-25