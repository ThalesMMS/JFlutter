# JFlutter Project Structure

## Overview

JFlutter follows Clean Architecture principles with clear separation of concerns across three main layers: Core, Presentation, and Data. The project is organized to support mobile-first development with Flutter while maintaining educational value and code maintainability.

## Directory Structure

```
jflutter/
├── lib/                           # Main application source code
│   ├── app.dart                   # App configuration and MaterialApp wiring
│   ├── main.dart                  # Flutter entry point
│   ├── core/                      # Core business logic and domain abstractions
│   │   ├── algorithms/            # Deterministic implementations of automata/grammar algorithms
│   │   ├── entities/              # Domain entities shared across layers
│   │   ├── models/                # Immutable domain models
│   │   ├── parsers/               # JFLAP XML parsing utilities
│   │   ├── repositories/          # Repository contracts
│   │   ├── use_cases/             # Aggregated use cases per bounded context
│   │   ├── utils/                 # Core mappers and helpers
│   │   ├── algo_log.dart          # Algorithm logging helpers
│   │   ├── automaton.dart         # Base automaton definitions
│   │   ├── error_handler.dart     # Global error handling
│   │   └── result.dart            # Result pattern implementation
│   ├── data/                      # Data access and persistence layer
│   │   ├── data_sources/          # Concrete data source adapters
│   │   ├── models/                # Transfer/data models for persistence
│   │   ├── repositories/          # Repository implementations
│   │   ├── services/              # High level data services and orchestrators
│   │   └── storage/               # Local storage bridges (e.g. shared preferences)
│   ├── features/                  # Cross-cutting feature modules
│   │   └── layout/                # Layout persistence implementations
│   ├── injection/                 # Dependency injection configuration
│   └── presentation/              # UI layer and presentation logic
│       ├── pages/                 # Screen widgets
│       ├── providers/             # Riverpod view models and controllers
│       ├── theme/                 # Material 3 theming
│       └── widgets/               # Reusable UI components grouped by feature
│           ├── automaton_canvas/  # Canvas composition and dialog widgets
│           ├── gestures/          # Canvas gesture controllers
│           ├── help/              # In-app contextual help sections
│           ├── regex/             # Regex-specific UI pieces
│           ├── settings/          # Settings cards and toggles
│           └── tm/                # Turing machine layouts and controls
├── test/                          # Automated tests
│   ├── contract/                  # Service contract tests
│   ├── data/                      # Data layer tests (repositories, services)
│   │   ├── repositories/          # Repository behaviour tests
│   │   └── services/              # Service integration tests
│   ├── integration/               # End-to-end workflow coverage
│   ├── presentation/              # Presentation layer unit/widget tests
│   │   ├── pages/                 # Page level rendering tests
│   │   ├── providers/             # View model behaviour tests
│   │   └── widgets/               # Widget logic and painter tests
│   ├── test_utils/                # Shared test helpers
│   ├── unit/                      # Fine grained unit suites grouped by layer
│   │   ├── algorithms/            # Algorithm-focused unit tests
│   │   ├── core/                  # Core utilities and entities tests
│   │   ├── data/                  # Data contracts and mappers
│   │   ├── features/              # Feature module tests
│   │   ├── models/                # Domain model tests
│   │   ├── presentation/          # Presentation utilities tests
│   │   └── repositories/          # Repository contract tests
│   └── widget/                    # Golden/widget regression tests
├── specs/                         # Project specifications and documentation
├── jflutter_js/                   # JavaScript interop experiments and examples
├── android/                       # Android-specific configuration and tooling
│   └── scripts/                   # Gradle helper scripts
├── ios/                           # iOS-specific configuration
├── web/                           # Web platform assets
├── windows/                       # Windows desktop runner
├── linux/                         # Linux desktop runner
├── macos/                         # macOS desktop runner
├── pubspec.yaml                   # Project dependencies and metadata
├── analysis_options.yaml          # Static analysis configuration
├── README.md                      # Project documentation
├── API_DOCUMENTATION.md           # API reference
├── USER_GUIDE.md                  # User instructions
├── CHANGELOG.md                   # Change history
├── DEVELOPMENT_LOG.md             # Weekly development journal
├── PROJECT_STRUCTURE.md           # This file
└── LICENSE.txt                    # License information
```

## Core Layer (`lib/core/`)

The core layer contains the business logic and domain models. It's independent of external frameworks and can be tested in isolation.

### Algorithms (`lib/core/algorithms/`)

Contains the main algorithm implementations that power automaton creation, analysis, and conversion workflows:

```
algorithms/
├── algorithm_operations.dart      # High-level algorithm orchestration
├── automaton_analyzer.dart        # Automaton statistics and metrics
├── automaton_simulator.dart       # Automaton simulation
├── dfa_completer.dart             # DFA completion utilities
├── dfa_minimizer.dart             # DFA minimization (Hopcroft)
├── dfa_operations.dart            # DFA set operations and helpers
├── equivalence_checker.dart       # Automata equivalence checking
├── fa_to_regex_converter.dart     # FA to regular expression conversion
├── fsa_to_grammar_converter.dart  # Automaton to grammar conversion
├── grammar_analyzer.dart          # Grammar metrics and validation
├── grammar_parser.dart            # Context-free grammar parsing
├── grammar_to_fsa_converter.dart  # Grammar to automaton conversion
├── grammar_to_pda_converter.dart  # Grammar to PDA conversion
├── nfa_to_dfa_converter.dart      # NFA to DFA conversion
├── pda_simulator.dart             # PDA simulation
├── pda_to_cfg_converter.dart      # PDA to CFG conversion utilities
├── pumping_lemma_game.dart        # Interactive pumping lemma game logic
├── pumping_lemma_prover.dart      # Pumping lemma proof assistant
├── regex_to_nfa_converter.dart    # Regex to NFA conversion
└── tm_simulator.dart              # Turing machine simulation
```

### Models (`lib/core/models/`)

Domain models representing core concepts:

```
models/
├── automaton.dart                 # Abstract automaton base class
├── fsa.dart                       # Finite state automaton definition
├── fsa_transition.dart            # FSA transition
├── grammar.dart                   # Context-free grammar aggregate
├── layout_settings.dart           # Layout configuration persistence model
├── parse_action.dart              # Parsing action descriptor
├── parse_table.dart               # LL/LR parsing table structure
├── pda.dart                       # Pushdown automaton representation
├── pda_transition.dart            # PDA transition
├── production.dart                # Grammar production rules
├── pumping_attempt.dart           # Pumping lemma attempt snapshot
├── pumping_lemma_game.dart        # Pumping lemma game state
├── settings_model.dart            # Persisted user settings
├── simulation_result.dart         # Simulation output envelope
├── simulation_step.dart           # Simulation step details
├── state.dart                     # Automaton state definition
├── tm.dart                        # Turing machine representation
├── tm_analysis.dart               # TM analysis report
├── tm_transition.dart             # TM transition definition
├── touch_interaction.dart         # Mobile touch interaction data
└── transition.dart                # Shared transition abstraction
```

### Entities (`lib/core/entities/`)

Business entities for domain logic:

```
entities/
├── automaton_entity.dart          # Core automaton entity
└── grammar_entity.dart            # Grammar aggregate root
```

### Utilities and Shared Core Files

- `algo_log.dart` - Centralized algorithm logging
- `automaton.dart` - Base automaton definitions shared by algorithms
- `error_handler.dart` - Global error handling helpers
- `result.dart` - Result pattern for error handling
- `utils/automaton_entity_mapper.dart` - Mapping helpers between entities and models

## Data Layer (`lib/data/`)

The data layer handles data persistence, external services, and data transformation.

### Services (`lib/data/services/`)

Business services for data operations and platform orchestration:

```
services/
├── automaton_service.dart         # Automaton CRUD operations
├── conversion_service.dart        # Algorithm conversion services
├── file_operations_service.dart   # Import/export and file helpers
└── simulation_service.dart        # Simulation services
```

### Data Sources (`lib/data/data_sources/`)

Data source implementations:

```
data_sources/
├── examples_data_source.dart      # Bundled examples data
└── local_storage_data_source.dart # Shared preferences and disk access
```

### Repositories (`lib/data/repositories/`)

Repository pattern implementations:

```
repositories/
├── algorithm_repository_impl.dart # Algorithm repository
├── automaton_repository_impl.dart # Automaton repository
├── examples_repository_impl.dart  # Examples repository
└── settings_repository_impl.dart  # Persisted settings repository
```

### Storage (`lib/data/storage/`)

Persistence adapters that back repositories:

```
storage/
└── settings_storage.dart          # Shared preferences backed storage
```

### Models (`lib/data/models/`)

Data transfer objects:

```
models/
└── automaton_model.dart           # Data model for automata
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

Reusable UI components organized by feature:

```
widgets/
├── algorithm_panel.dart           # Algorithm selection hub
├── file_operations_panel.dart     # Import/export surface
├── grammar_algorithm_panel.dart   # Grammar-specific controls
├── grammar_editor.dart            # Grammar editing surface
├── grammar_simulation_panel.dart  # Grammar simulation controls
├── mobile_automaton_controls.dart # Mobile-friendly automaton controls
├── mobile_navigation.dart         # Bottom navigation for mobile
├── pda_algorithm_panel.dart       # PDA algorithm controls
├── pda_canvas.dart                # PDA editor canvas
├── pda_simulation_panel.dart      # PDA simulation controls
├── pumping_lemma_game.dart        # Pumping lemma interaction widget
├── pumping_lemma_help.dart        # Pumping lemma assistance content
├── pumping_lemma_progress.dart    # Pumping lemma progress tracker
├── simulation_panel.dart          # Shared simulation interface
├── tm_algorithm_panel.dart        # TM algorithm controls
├── tm_canvas.dart                 # TM editor canvas
├── tm_simulation_panel.dart       # TM simulation controls
├── touch_gesture_handler.dart     # Gesture bridge for canvases
├── transition_geometry.dart       # Canvas geometry helpers
├── automaton_canvas/              # Canvas composition widgets and dialogs
├── gestures/                      # Canvas gesture controllers
├── help/                          # In-app help section widgets
├── regex/                         # Regex conversion/test widgets
├── settings/                      # Settings cards and toggles
└── tm/                            # TM layout composites
```

### Providers (`lib/presentation/providers/`)

State management using Riverpod view models and controllers:

```
providers/
├── algorithm_provider.dart             # Algorithm execution orchestrator
├── automaton_canvas_controller.dart    # Canvas transform and gesture state
├── automaton_provider.dart             # Automaton state management
├── grammar_provider.dart               # Grammar editing state
├── home_navigation_provider.dart       # Home page navigation
├── pda_editor_provider.dart            # PDA editing workflow
├── pumping_lemma_progress_provider.dart # Pumping lemma game state
├── regex_page_view_model.dart          # Regex conversion state
├── settings_providers.dart             # Provider definitions for settings
├── settings_view_model.dart            # Settings state management
├── tm_algorithm_view_model.dart        # TM algorithm execution state
├── tm_editor_provider.dart             # TM editor state
└── tm_metrics_controller.dart          # TM metrics aggregation
```

### Theme (`lib/presentation/theme/`)

App theming and styling:

```
theme/
└── app_theme.dart                 # Material 3 theme configuration
```

## Dependency Injection (`lib/injection/`)

Service registration and dependency management with GetIt:

```
injection/
└── dependency_injection.dart      # Registers repositories, services, and use cases
```

## Feature Modules (`lib/features/`)

Cross-cutting feature packages that augment core functionality:

```
features/
└── layout/
    └── layout_repository_impl.dart    # Persists and restores layout preferences
```

## Test Structure (`test/`)

Comprehensive testing across all layers:

### Contract Tests (`test/contract/`)

Service API validation to ensure external behaviour remains stable.

### Data Tests (`test/data/`)

Repository and service level tests, including shared preferences backed settings and SVG export workflows.

### Integration Tests (`test/integration/`)

End-to-end workflow testing that stitches together UI, core, and data layers.

### Presentation Tests (`test/presentation/`)

Focused coverage for Riverpod providers, widgets, and pages to guarantee UI logic.

### Test Utilities (`test/test_utils/`)

Helper classes and fixtures shared across suites.

### Unit Tests (`test/unit/`)

Fine grained unit suites grouped by domain (algorithms, core, data, features, models, presentation, repositories).

### Widget Regression (`test/widget/`)

Widget snapshot and golden tests.

## Platform-Specific Directories

### Android (`android/`)

Android-specific configuration and native code. The `scripts/` directory contains helper shell scripts used by CI to fix Gradle wrappers.

### iOS (`ios/`)

iOS-specific configuration and native code:

```
ios/
├── Runner/                       # iOS app configuration
├── Podfile                       # CocoaPods dependencies
└── Runner.xcodeproj/             # Xcode project
```

### Web (`web/`)

Contains `index.html`, `manifest.json`, and platform icons for Flutter web builds.

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
- `USER_GUIDE.md` - User instructions and tutorials
- `CHANGELOG.md` - Detailed change history
- `DEVELOPMENT_LOG.md` - Weekly merge and progress notes
- `PROJECT_STRUCTURE.md` - This file

### Specifications

- `specs/` - Project specifications and requirements
  - `001-description-port-jflap/` - Original JFLAP port specifications

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
