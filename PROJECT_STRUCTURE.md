# JFlutter Project Structure

## Overview

JFlutter follows Clean Architecture principles with clear separation of concerns across three main layers: Core, Presentation, and Data. The project is organized to support mobile-first development with Flutter while maintaining educational value and code maintainability.

## Directory Structure

```
jflutter/
├── lib/                           # Main application code
│   ├── core/                      # Core business logic
│   │   ├── algorithms/            # Core algorithm implementations
│   │   ├── models/                # Domain models and entities
│   │   ├── entities/              # Business entities
│   │   ├── parsers/               # File parsing utilities
│   │   ├── repositories/          # Repository interfaces
│   │   ├── use_cases/             # Business use cases
│   │   ├── algo_log.dart          # Algorithm logging
│   │   ├── error_handler.dart     # Error handling utilities
│   │   └── result.dart            # Result pattern implementation
│   ├── data/                      # Data layer
│   │   ├── data_sources/          # Data source implementations
│   │   ├── models/                # Data transfer objects
│   │   ├── repositories/          # Repository implementations
│   │   ├── services/              # Business services
│   │   └── storage/               # Persistence adapters (SharedPreferences, etc.)
│   ├── presentation/              # Presentation layer
│   │   ├── pages/                 # Application pages/screens
│   │   ├── widgets/               # Reusable UI components
│   │   ├── providers/             # State management
│   │   └── theme/                 # App theming
│   ├── features/                  # Feature-specific modules
│   │   └── canvas/graphview/      # GraphView-powered canvas controllers
│   ├── injection/                 # Dependency injection
│   ├── app.dart                   # App configuration
│   └── main.dart                  # Application entry point
├── test/                          # Automated tests (unit, widget, integration, feature, core)
├── android/                       # Android-specific files
├── ios/                           # iOS-specific files
├── web/                           # Web-specific files
├── windows/                       # Windows-specific files
├── linux/                         # Linux-specific files
├── macos/                         # macOS-specific files
├── docs/                          # Additional architecture notes and guides
├── jflutter_js/                   # Shared JS runtime assets and examples
├── References/                    # Implementações de referência (Dart + Python) usadas como base na migração
├── screenshots/                   # UI captures and visual references
├── tool/                          # Repo tooling and helper scripts
├── build.yaml                     # Build orchestration for CI/scripts
├── fix_compilation.sh             # Helper script for resolving build issues
├── pubspec.yaml                   # Project dependencies
├── analysis_options.yaml          # Static analysis configuration
├── pubspec.lock                   # Locked dependency versions
├── README.md                      # Project documentation
├── API_DOCUMENTATION.md           # API reference
├── USER_GUIDE                     # User instructions
├── QUICKSTART_EVIDENCE.md         # Audit evidence for onboarding
├── PHASE2_COMPLETION_SUMMARY.md   # Milestone change summary
├── PROJECT_STRUCTURE.md           # This file
├── Requisitos.md                  # Requisitos funcionais (PT-BR)
├── LICENSE.txt                    # License information
├── LICENSE_JFLAP.txt              # Upstream JFLAP license
├── icon.png                       # App icon source
└── AGENTS.md                      # Repository-specific contribution guide
```

## Core Layer (`lib/core/`)

The core layer contains the business logic and domain models. It's independent of external frameworks and can be tested in isolation.

### Algorithms (`lib/core/algorithms/`)

The algorithms package now covers automata analysis, grammar tooling, and
conversions, organised into focused modules plus shared helpers:

```
algorithms/
├── automata/                      # DFA/NFA/TM helpers (builders, tracers, validators)
├── cfg/                           # Context-free grammar utilities and analyzers
├── common/                        # Shared math, graph, and parser utilities
├── pda/                           # Pushdown automata specific operations
├── regex/                         # Regular expression parsing helpers
├── algorithm_operations.dart      # High-level algorithm orchestration entrypoints
├── automaton_analyzer.dart        # Aggregate automaton statistics and metrics
├── automaton_simulator.dart       # DFA/NFA simulation core with step tracing
├── dfa_completer.dart             # Automates completion of partial DFAs
├── dfa_minimizer.dart             # Hopcroft-based DFA minimization
├── dfa_operations.dart            # Set and language operations across DFAs
├── equivalence_checker.dart       # DFA language equivalence checking
├── fa_to_regex_converter.dart     # FA to regular expression conversion
├── fsa_to_grammar_converter.dart  # Grammar conversion entrypoints for FSAs
├── grammar_analyzer.dart          # Grammar consistency and diagnostics
├── grammar_parser.dart            # Hand-rolled parser façade
├── grammar_parser_earley.dart     # Earley parser implementation
├── grammar_parser_petit.dart      # PetitParser-based parser integration
├── grammar_parser_simple.dart     # Simplified recursive-descent parser
├── grammar_parser_simple_recursive.dart # Alternate recursive parser prototype
├── grammar_to_fsa_converter.dart  # Convert grammars to FSAs
├── grammar_to_pda_converter.dart  # Convert grammars to PDAs
├── nfa_to_dfa_converter.dart      # Subset construction converter
├── pumping_lemma_game.dart        # Interactive pumping lemma simulation
├── pumping_lemma_prover.dart      # Pumping lemma proof assistant
├── pda_simulator.dart             # PDA execution engine
├── pda_to_cfg_converter.dart      # PDA to CFG transformer
├── regex_to_nfa_converter.dart    # Thompson-style regex conversion
└── tm_simulator.dart              # Deterministic TM simulation
```

### Models (`lib/core/models/`)

Domain models representing automata, grammars, UI layout, and simulator state:

```
models/
├── automaton.dart                 # Abstract automaton base class
├── fsa.dart                       # Finite state automaton aggregate
├── fsa_transition.dart            # FSA transition model
├── grammar.dart                   # Context-free grammar definition
├── layout_settings.dart           # Canvas/grid layout configuration
├── parse_action.dart              # LR parse action representation
├── parse_table.dart               # Parsing table structure
├── pda.dart                       # Pushdown automaton definition
├── pda_transition.dart            # PDA transition metadata
├── production.dart                # Grammar production rule
├── pumping_attempt.dart           # Pumping lemma attempt state
├── pumping_lemma_game.dart        # Pumping lemma game session
├── settings_model.dart            # Persisted user preference values
├── simulation_highlight.dart      # Highlight overlays for simulations
├── simulation_result.dart         # Result payload returned by simulators
├── simulation_step.dart           # Individual simulation step details
├── state.dart                     # Automaton state node
├── tm.dart                        # Turing machine aggregate
├── tm_analysis.dart               # TM tape/run inspection helpers
├── tm_transition.dart             # TM transition representation
├── touch_interaction.dart         # Pointer/gesture metadata
└── transition.dart                # Shared transition abstraction
```

### Entities (`lib/core/entities/`)

Business entities for domain logic:

```
entities/
├── automaton_entity.dart          # Shared automaton entity contract
├── grammar_entity.dart            # Grammar entity definition
└── turing_machine_entity.dart     # Turing machine entity representation
```

### Other Core Files

- `algo_log.dart` - Centralized algorithm logging
- `error_handler.dart` - Global error handling
- `result.dart` - Result pattern for error handling
- `services/` - Runtime diagnostics and highlighting utilities such as
  `diagnostic_service.dart`, `diagnostics_service.dart`,
  `simulation_highlight_service.dart`, and the platform-aware
  `trace_persistence_service*.dart` shims used by the UI layer

## Data Layer (`lib/data/`)

The data layer handles data persistence, external services, and data transformation.

### Services (`lib/data/services/`)

Business services for data operations:

```
services/
├── automaton_service.dart                # In-memory CRUD plus layout helpers for automata
├── conversion_service.dart               # Bridges UI requests to conversion algorithms
├── examples_service.dart                 # Catalog search, filtering, and caching for examples
├── file_operations_service.dart          # Conditional export choosing IO/Web implementations
├── file_operations_service_io.dart       # Platform file reads, exports, and canvas rendering
├── file_operations_service_web.dart      # Web download/export fallback without dart:io
├── import_export_validation_service.dart # Round-trip validators for XML/JSON interchange
├── serialization_service.dart            # JSON/JFLAP XML serialization utilities
├── simulation_service.dart               # Simulator façade with result normalization
└── trace_persistence_service.dart        # SharedPreferences-backed trace history manager
```

### Data Sources (`lib/data/data_sources/`)

Data source implementations:

```
data_sources/
├── examples_asset_data_source.dart  # Rich metadata-backed examples loader
├── examples_data_source.dart        # Legacy asset loader for simple automata
└── local_storage_data_source.dart   # SharedPreferences-powered persistence bridge
```

### Repositories (`lib/data/repositories/`)

Repository pattern implementations:

```
repositories/
├── algorithm_repository_impl.dart # Wraps algorithm metadata and persistence glue
├── automaton_repository_impl.dart # Automaton repository backed by services/data sources
├── examples_repository_impl.dart  # Provides curated example listings and search
└── settings_repository_impl.dart  # SharedPreferences-powered user settings storage
```

### Models (`lib/data/models/`)

Data transfer objects:

```
models/
├── automaton_dto.dart             # Serializes automata payloads for storage/API
├── automaton_model.dart           # Rich automaton model consumed by the UI
├── grammar_dto.dart               # Grammar DTO with production metadata
└── turing_machine_dto.dart        # Turing machine DTO mapping tape/configurations
```

### Storage (`lib/data/storage/`)

Persistence adapters shared across repositories:

```
storage/
└── settings_storage.dart          # SharedPreferences wrapper with typed helpers
```

## Presentation Layer (`lib/presentation/`)

The presentation layer contains all UI components, state management, and user interaction logic.

### Pages (`lib/presentation/pages/`)

Main application screens:

```
pages/
├── fsa_page.dart                  # Finite state automata page
├── grammar_page.dart              # Context-free grammar page
├── help_page.dart                 # In-app help center
├── home_page.dart                 # Main navigation page
├── pda_page.dart                  # Pushdown automata page
├── regex_page.dart                # Regular expression page
├── pumping_lemma_page.dart        # Pumping lemma game page
├── settings_page.dart             # Application preferences page
└── tm_page.dart                   # Turing machine page
```

### Widgets (`lib/presentation/widgets/`)

Reusable UI components:

```
widgets/
├── algorithm_panel.dart             # Shared algorithm control surface
├── grammar_algorithm_panel.dart     # Grammar-specific controls
├── pda_algorithm_panel.dart         # PDA algorithm shortcuts
├── tm_algorithm_panel.dart          # Turing machine tooling
├── automaton_canvas.dart            # Widget-agnostic canvas host
├── automaton_canvas_web.dart        # Web-optimised canvas wrapper
├── automaton_graphview_canvas.dart  # GraphView-backed canvas implementation
├── diagnostics_panel.dart           # Runtime diagnostics and logs
├── file_operations_panel.dart       # Import/export actions
├── desktop_navigation.dart          # Desktop navigation rail
├── mobile_navigation.dart           # Mobile bottom navigation
├── mobile_automaton_controls.dart   # Compact controls for touch devices
├── canvas_actions_sheet.dart        # Quick actions sheet for canvas interactions
├── error_banner.dart                # Inline error messaging
├── import_error_dialog.dart         # Import failure dialog
├── retry_button.dart                # Retry CTA used across error states
├── simulation_panel.dart            # DFA/NFA simulation interface
├── pda_simulation_panel.dart        # PDA simulation controls
├── tm_simulation_panel.dart         # Turing machine simulation controls
├── export/                          # SVG/PNG exporters and dialogs
├── pumping_lemma_game/              # Interactive pumping lemma widgets
├── trace_viewers/                   # Simulation trace renderers
├── transition_editors/              # Editors for transitions across automata types
└── utils/                           # Widget utilities and shared helpers
```

### Providers (`lib/presentation/providers/`)

State management using Riverpod:

```
providers/
├── algorithm_provider.dart              # Coordinates algorithm selection
├── automaton_provider.dart              # Automaton state management
├── fa_trace_provider.dart               # DFA/NFA trace broadcasting
├── grammar_provider.dart                # Grammar editor state
├── home_navigation_provider.dart        # Home shell navigation model
├── pda_editor_provider.dart             # PDA editor state
├── pda_simulation_provider.dart         # PDA simulation controller
├── pda_trace_provider.dart              # PDA trace management
├── pumping_lemma_progress_provider.dart # Pumping lemma tutorial progress
├── settings_provider.dart               # User preference state
├── tm_editor_provider.dart              # Turing machine editor binding
└── unified_trace_provider.dart          # Shared trace selector across automata
```

### GraphView Canvas (`lib/features/canvas/graphview/`)

GraphView-powered canvas controllers, mixins, and mappers live here. The base
controller keeps caches of `GraphViewCanvasNode/Edge`, synchronises with the
domain providers, and now emits structured debug logs (guarded by `kDebugMode`)
for every mutation, undo/redo operation, and highlight update to aid runtime
inspection. Specialised controllers (`graphview_canvas_controller.dart`,
`graphview_tm_canvas_controller.dart`, `graphview_pda_canvas_controller.dart`)
layer on automaton-specific instrumentation, while
`graphview_viewport_highlight_mixin.dart` centralises viewport metrics and
highlight change notifications. Supporting utilities such as
`graphview_highlight_channel.dart`, `graphview_snapshot_codec.dart`, and
`graphview_link_overlay_utils.dart` power cross-platform export, diagnostics,
and selection tooling. When integrating new canvas capabilities, wire them
through these controllers so the logging/metrics remain consistent.

### Theme (`lib/presentation/theme/`)

App theming and styling:

```
theme/
└── app_theme.dart                 # Material 3 theme configuration
```

## Dependency Injection (`lib/injection/`)

Service registration and dependency management:

```
injection/
└── dependency_injection.dart      # GetIt service registration
```

## Test Structure (`test/`)

The test suite is split into focused directories that mirror the production architecture:

```
test/
├── core/                # Low-level unit tests for algorithms and entities
├── features/            # Feature-focused widget/controller tests
├── integration/         # End-to-end flows exercising multiple layers
├── presentation/        # UI flows and provider/widget integration tests
├── unit/                # UI-agnostic unit tests for shared utilities
└── widget/              # Widget tests targeting rendering and interactions
```

## Platform-Specific Directories

### Android (`android/`)

Android-specific configuration and native code:

```
android/
├── app/
│   ├── build.gradle.kts          # Android build configuration
│   └── src/main/
│       ├── kotlin/               # Kotlin native code
│       └── res/                  # Android resources
├── build.gradle.kts              # Project build configuration
└── gradle/                       # Gradle wrapper
```

### iOS (`ios/`)

iOS-specific configuration and native code:

```
ios/
├── Runner/                       # iOS app configuration
├── Podfile                       # CocoaPods dependencies
└── Runner.xcodeproj/             # Xcode project
```

### Web (`web/`)

Web-specific assets and configuration:

```
web/
├── index.html                    # Web app entry point
├── manifest.json                 # Web app manifest
└── icons/                        # Web app icons
```

### Desktop Platforms

- `windows/` - Windows desktop configuration
- `linux/` - Linux desktop configuration  
- `macos/` - macOS desktop configuration

## Configuration Files

### Project Configuration

- `pubspec.yaml` - Flutter project configuration and dependencies
- `analysis_options.yaml` - Static analysis and linting rules
- `README.md` - Project documentation and setup instructions
- `LICENSE.txt` - License information

### Documentation

- `API_DOCUMENTATION.md` - Comprehensive API reference
- `USER_GUIDE` - User instructions and tutorials
- `PROJECT_STRUCTURE.md` - This file
- `PHASE2_COMPLETION_SUMMARY.md` - Snapshot of the latest milestone deliverables
- `QUICKSTART_EVIDENCE.md` - Onboarding and compliance checklist
- `docs/` - Supplemental design notes (`canvas_bridge.md`, QA sheets, reference alignment)

### Reference Material & Requirements

- `References/` - Authoritative Dart/Python implementations mirrored from upstream projects
- `Requisitos.md` - Functional requirements in Portuguese
- `LICENSE.txt` / `LICENSE_JFLAP.txt` - Licensing information

## Architecture Principles

### Clean Architecture

The project follows Clean Architecture principles:

1. **Independence** - Core layer is independent of external frameworks
2. **Testability** - Each layer can be tested in isolation
3. **Maintainability** - Clear separation of concerns
4. **Flexibility** - Easy to modify and extend

### Dependency Direction

Dependencies flow inward:

```
Presentation → Core ← Data
```

- Presentation layer depends on Core layer
- Data layer depends on Core layer
- Core layer has no external dependencies

### Design Patterns

- **Repository Pattern** - Data access abstraction
- **Provider Pattern** - State management
- **Result Pattern** - Error handling
- **Dependency Injection** - Service registration
- **Factory Pattern** - Object creation
- **Observer Pattern** - State changes

## Referências para a Migração

O diretório `References/` reúne implementações em Dart e o projeto Python `automata-main`. Eles servem como base de conferência durante a reconstrução das estruturas e algoritmos do JFlutter. Sempre que um módulo é reescrito, seu comportamento é comparado com essas referências até que novos testes automatizados entrem em cena.

## Development Guidelines

### Code Organization

1. **Single Responsibility** - Each class has one reason to change
2. **Open/Closed** - Open for extension, closed for modification
3. **Dependency Inversion** - Depend on abstractions, not concretions
4. **Interface Segregation** - Small, focused interfaces
5. **Liskov Substitution** - Subtypes must be substitutable

### Naming Conventions

- **Files** - snake_case (e.g., `automaton_simulator.dart`)
- **Classes** - PascalCase (e.g., `AutomatonSimulator`)
- **Variables** - camelCase (e.g., `currentAutomaton`)
- **Constants** - UPPER_SNAKE_CASE (e.g., `MAX_STATES`)
- **Private Members** - Leading underscore (e.g., `_privateMethod`)

### File Structure Guidelines

1. **One class per file** - Keep files focused and manageable
2. **Logical grouping** - Related functionality in same directory
3. **Clear naming** - File names should indicate purpose
4. **Consistent structure** - Follow established patterns

## Performance Considerations

### Mobile Optimization

- **Custom Painters** - Efficient canvas rendering
- **State Management** - Minimal rebuilds with Riverpod
- **Memory Management** - Proper resource disposal
- **Touch Optimization** - Responsive touch interactions

### Algorithm Efficiency

- **Time Complexity** - Optimized algorithms for mobile
- **Space Complexity** - Memory-efficient implementations
- **Timeout Mechanisms** - Prevent infinite loops
- **Progress Feedback** - User experience during long operations

## Testing Strategy

### Test Pyramid

1. **Unit Tests** - Individual components (70%)
2. **Integration Tests** - Component interactions (20%)
3. **Contract Tests** - API contracts (10%)

### Test Categories

- **Core Algorithm Tests** - Mathematical correctness
- **UI Component Tests** - User interaction
- **Integration Tests** - End-to-end workflows
- **Performance Tests** - Mobile optimization
- **Accessibility Tests** - Inclusive design

## Future Extensibility

### Plugin Architecture

The project is designed to support:

- **Custom Algorithms** - Plugin system for new algorithms
- **File Format Support** - Extensible import/export
- **Visualization Plugins** - Custom rendering options
- **Educational Content** - Modular learning materials

### Scalability

- **Modular Design** - Easy to add new features
- **Clean Interfaces** - Well-defined extension points
- **Performance Monitoring** - Built-in performance tracking
- **Error Reporting** - Comprehensive error handling

---

This project structure supports the educational goals of JFlutter while maintaining code quality, performance, and extensibility for future development.
