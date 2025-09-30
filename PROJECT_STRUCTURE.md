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
│   │   └── services/              # Business services
│   ├── presentation/              # Presentation layer
│   │   ├── pages/                 # Application pages/screens
│   │   ├── widgets/               # Reusable UI components
│   │   ├── providers/             # State management
│   │   └── theme/                 # App theming
│   ├── injection/                 # Dependency injection
│   ├── app.dart                   # App configuration
│   └── main.dart                  # Application entry point
├── test/                          # (Temporarily removed during algorithm migration)
├── specs/                         # Project specifications
├── android/                       # Android-specific files
├── ios/                           # iOS-specific files
├── web/                           # Web-specific files
├── windows/                       # Windows-specific files
├── linux/                         # Linux-specific files
├── macos/                         # macOS-specific files
├── pubspec.yaml                   # Project dependencies
├── analysis_options.yaml          # Static analysis configuration
├── README.md                      # Project documentation
├── API_DOCUMENTATION.md           # API reference
├── USER_GUIDE.md                  # User instructions
├── CHANGELOG.md                   # Change history
├── PROJECT_STRUCTURE.md           # This file
├── References/                    # Implementações de referência (Dart + Python) usadas como base na migração
└── LICENSE.txt                    # License information
```

## Core Layer (`lib/core/`)

The core layer contains the business logic and domain models. It's independent of external frameworks and can be tested in isolation.

### Algorithms (`lib/core/algorithms/`)

Contains 13 core algorithm implementations:

```
algorithms/
├── algorithm_operations.dart      # High-level algorithm operations
├── automaton_simulator.dart       # Automaton simulation
├── dfa_minimizer.dart             # DFA minimization (Hopcroft's algorithm)
├── fa_to_regex_converter.dart     # FA to regular expression conversion
├── grammar_parser.dart             # Context-free grammar parsing
├── grammar_to_pda_converter.dart  # Grammar to PDA conversion
├── nfa_to_dfa_converter.dart      # NFA to DFA conversion
├── pda_simulator.dart             # PDA simulation
├── pumping_lemma_game.dart        # Interactive pumping lemma game
├── pumping_lemma_prover.dart      # Pumping lemma proof
├── regex_to_nfa_converter.dart    # Regex to NFA conversion
└── tm_simulator.dart              # Turing machine simulation
```

### Models (`lib/core/models/`)

Domain models representing core concepts:

```
models/
├── automaton.dart                 # Abstract automaton base class
├── fsa.dart                       # Finite state automaton
├── fsa_transition.dart            # FSA transition
├── grammar.dart                   # Context-free grammar
├── layout_settings.dart           # Layout configuration
├── parse_action.dart              # Parsing action
├── parse_table.dart               # We are using PetitParser for parsing
├── pda.dart                       # Pushdown automaton
├── pda_transition.dart            # PDA transition
├── production.dart                # Grammar production
├── pumping_attempt.dart           # Pumping lemma attempt
├── pumping_lemma_game.dart        # Pumping lemma game state
├── simulation_result.dart         # Simulation result
├── simulation_step.dart           # Simulation step
├── state.dart                     # Automaton state
├── tm.dart                        # Turing machine
├── tm_transition.dart             # TM transition
└── touch_interaction.dart         # Mobile touch data
```

### Entities (`lib/core/entities/`)

Business entities for domain logic:

```
entities/
└── automaton_entity.dart          # Core automaton entity
```

### Other Core Files

- `algo_log.dart` - Centralized algorithm logging
- `error_handler.dart` - Global error handling
- `result.dart` - Result pattern for error handling

## Data Layer (`lib/data/`)

The data layer handles data persistence, external services, and data transformation.

### Services (`lib/data/services/`)

Business services for data operations:

```
services/
├── automaton_service.dart         # Automaton CRUD operations
├── conversion_service.dart        # Algorithm conversion services
└── simulation_service.dart        # Simulation services
```

### Data Sources (`lib/data/data_sources/`)

Data source implementations:

```
data_sources/
├── examples_data_source.dart      # Example data source
└── local_storage_data_source.dart # Local storage implementation
```

### Repositories (`lib/data/repositories/`)

Repository pattern implementations:

```
repositories/
├── algorithm_repository_impl.dart # Algorithm repository
├── automaton_repository_impl.dart # Automaton repository
└── examples_repository_impl.dart  # Examples repository
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

Reusable UI components:

```
widgets/
├── algorithm_panel.dart           # Algorithm control panel
├── automaton_canvas.dart          # Interactive drawing canvas
├── mobile_navigation.dart         # Mobile bottom navigation
└── simulation_panel.dart          # Simulation interface
```

### Providers (`lib/presentation/providers/`)

State management using Riverpod:

```
providers/
└── automaton_provider.dart        # Automaton state management
```

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

The historic automated test suites have been removed while the core algorithms are rewritten. A new hierarchy of unit, integration, and property-based tests will be introduced alongside the migration. Until then the `test/` directory is intentionally empty.

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
- `USER_GUIDE.md` - User instructions and tutorials
- `CHANGELOG.md` - Detailed change history
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
