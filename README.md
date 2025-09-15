# JFlutter (Work in Progress)

An interactive automata and grammars simulator developed in Flutter, derived from the original JFLAP. Offers a modern and responsive interface for working with finite automata, context-free grammars, Turing machines, LL/LR parsing, and much more.

## 🚀 Implemented Features

### Finite Automata

- **DFA (Deterministic Finite Automata)**: Creation, editing, and simulation
- **NFA (Nondeterministic Finite Automata)**: Support for lambda transitions
- **Conversions**: NFA → DFA, DFA → RE, RE → NFA
- **Basic Operations**: Union, intersection, complement, product, reverse
- **Advanced Operations**: Homomorphism, right/left quotient, difference
- **Minimization**: DFA minimization algorithm with interactive interface
- **Equivalence checking**: Comparison between automata with counterexamples
- **Closures**: Prefixes, suffixes, and advanced operations
- **Complete DFA**: Automatic addition of trap state
- **ε-closure**: Epsilon closure calculation for NFAλ

### Grammars and Parsing

- **Regular Grammars**: RG ↔ FA conversion
- **Context-Free Grammars**: Editing, analysis, and validation
- **LL(1) Parsing**: Top-down analysis with interactive parsing tables
- **LR(1) Parsing**: Bottom-up analysis with LR automata
- **Chomsky Normal Form**: Conversion to CNF
- **CYK Algorithm**: Parsing for grammars in CNF
- **Pumping Lemma**: Interactive demonstration for regular and context-free languages

### Advanced Automata

- **PDA (Pushdown Automata)**: Simulation, validation, and conversion to CFG
- **Turing Machines**: Multi-tape support (1-5 tapes) with visual simulation
- **Mealy/Moore Machines**: Output automata and conversion between types
- **Conversions**: Mealy ↔ Moore, TM → CSG, PDA → CFG

### Interface and Visualization

- **Interactive Canvas**: Visual editing with touch gestures and multi-selection
  - Multi-selection with box-select and Shift-click
  - Joint movement of selected states
  - Inline editing of transition labels
  - Multiple curved edges between same pair of states
  - Loops with adjustable curvature and precise hit-test
  - Pinch-to-zoom with dedicated zoom controls
  - Pan and drag for canvas navigation
- **Step-by-step Simulation**: Detailed execution visualization
  - Execution controls (play/pause/step/reset)
  - Execution speed control
  - Real-time algorithm logging
  - Active states visualization
- **Auto Layout**: State positioning presets
  - Compact, Balanced, Spread, Hierarchical, Automatic
  - Auto-center and manual centering
  - Smart positioning with overlap detection
- **Responsive Interface**: Optimized for mobile, tablet, and desktop
  - Hybrid navigation (desktop tabs / mobile bottom nav)
  - 800px responsive breakpoint
  - Responsive tables with horizontal/vertical scroll
  - Mobile context menu with quick actions
- **Help System**: Integrated contextual tooltips and guides
  - Contextual help on hover/touch
  - Complete help panel
  - Feature-specific content
- **Keyboard Shortcuts**: Complete shortcut system
  - File (Ctrl+N, Ctrl+O, Ctrl+S)
  - Edit (Ctrl+Z, Ctrl+C, Ctrl+V)
  - Navigation (arrows, Alt+1/2/3)
  - Simulation (Ctrl+R, F9, F10)
  - Operations (Ctrl+M, Ctrl+F, Ctrl+G)
- **Advanced Export**: Multiple output formats
  - High-quality PNG with canvas capture
  - Vector SVG for scalable graphics
  - LaTeX with TikZ for academic documents
  - LaTeX CFG for context-free grammars
  - Mobile support with file sharing
- **JFLAP Import**: Complete support for .jff files
  - Robust XML parser for all automata types
  - Complete validation with detailed error messages
  - Full compatibility with existing JFLAP formats

### Educational Tools

- **Interactive Minimization Interface**: Based on JFLAP
  - Visual minimization tree with clickable nodes
  - Step-by-step expansion of distinguishable groups
  - Interactive verification of decompositions
  - Direct application of minimized result
- **Pumping Lemma Interface**: Educational demonstration
  - Regular and context-free lemmas with appropriate decompositions
  - Step-by-step animation of pumping process
  - String testing with configurable parameters
  - Attempt history for learning tracking
- **Educational Examples Library**: Collection of learning examples
  - Categories organized by type (DFA, NFA, Grammar, CFG, PDA, Turing)
  - Search system and category filters
  - Difficulty levels (Easy, Medium, Hard)
  - Learning concepts and objectives for each example
  - Direct loading to canvas for experimentation
- **Advanced Equivalence Checking**: Educational tool
  - Word testing in automata
  - Complete equivalence verification
  - Counterexample display when not equivalent
  - Multiple verification algorithms
  - Expandable technical details

### Persistence Features

- **Local Storage**: Automatic persistence with SharedPreferences
- **JSON Serialization**: Compatibility with original web version
- **Clipboard**: Copy/paste of automata and grammars
- **Clipboard Support**: Copy results (regex, grammars)

## 📱 Supported Platforms

- **Web**: Chrome, Firefox, Safari, Edge
- **Mobile**: iOS and Android
- **Desktop**: Windows, macOS, and Linux

## 🛠️ Installation and Execution

### Prerequisites

- Flutter SDK (version 3.9.2 or higher)
- Dart SDK (included with Flutter)

### Installation

```bash
# Clone the repository
git clone https://github.com/ThalesMMS/jflutter.git
cd jflutter

# Install dependencies
flutter pub get
```

### Execution

```bash
# Web (recommended for development)
flutter run -d chrome

# Mobile
flutter run -d ios      # iOS
flutter run -d android  # Android

# Desktop
flutter run -d macos    # macOS
flutter run -d windows  # Windows
flutter run -d linux    # Linux
```

### Production Build

```bash
# Web
flutter build web

# Mobile
flutter build apk       # Android
flutter build ipa       # iOS

# Desktop
flutter build macos     # macOS
flutter build windows   # Windows
flutter build linux     # Linux
```

## 🧪 Testing

```bash
# Run all tests
flutter test -r expanded

# Specific tests by category
flutter test test/core_algorithms_test.dart        # Fundamental algorithms
flutter test test/examples_roundtrip_test.dart     # Web version compatibility
flutter test test/ll_lr_parsing_test.dart          # LL/LR parsing
flutter test test/dfa_minimization_test.dart       # DFA minimization
flutter test test/nfa_to_dfa_test.dart             # NFA→DFA conversions
flutter test test/regex_to_nfa_test.dart           # Regular expressions
flutter test test/nfa_reversal_test.dart           # Advanced operations

# Static analysis
flutter analyze
```

## 📚 How to Use

### Creating an Automaton

1. Open the “DFA” or “NFA” tab
1. Define the alphabet in the sidebar
1. Add states by clicking on the canvas (double-click to rename)
1. Connect states by dragging between them
1. Mark initial and final states using sidebar buttons
1. Use layout presets to automatically organize

### Simulating a Word

1. Type the word in the input field
1. Click “Simulate” for automatic execution
1. Use “Step-by-step” for detailed visualization
1. View the execution log in the algorithms panel

### Grammar Analysis

1. Go to the “CFG” tab for context-free grammars
1. Type a grammar or use predefined examples
1. Use the “LL/LR” tab for parsing analysis
1. View interactive LL(1) and LR(1) tables
1. Test parsing with input strings

### Advanced Automata

1. **PDA**: Use the “PDA” tab for pushdown automata
1. **Turing**: Use the “Turing” tab for multi-tape machines
1. **Mealy/Moore**: Use the “Mealy/Moore” tab for output automata

### Advanced Tools

1. **Interactive Minimization**: Use minimization interface with visual tree
1. **Pumping Lemma**: Interactive demonstration in CFG tab
1. **Equivalence Checking**: Compare automata with counterexamples
1. **Examples Library**: Explore educational examples by category
1. **Advanced Export**: Export to PNG, SVG, LaTeX, or LaTeX CFG
1. **JFLAP Import**: Load .jff files from original JFLAP
1. **Keyboard Shortcuts**: Use shortcuts for quick operations
1. **Help System**: Access contextual help anytime

### Mobile Features

1. **Touch Gestures**: Pinch-to-zoom, pan, double-tap to add states
1. **Context Menu**: Long press for quick actions
1. **Mobile Navigation**: Bottom navigation bar for mobile
1. **Responsive Layout**: Interface adapts to screen size
1. **Sharing**: Export and share files easily

## 🏗️ Architecture

### Project Structure

```
lib/
├── core/                           # Algorithms and data models
│   ├── automaton.dart              # Base automaton model
│   ├── algorithms.dart             # Fundamental algorithms
│   ├── automaton_analysis.dart     # Automaton analysis
│   ├── cfg.dart                    # Context-free grammars
│   ├── cfg_algorithms.dart         # CFG algorithms
│   ├── dfa_algorithms.dart         # DFA-specific algorithms
│   ├── equivalence_checking.dart   # Equivalence verification
│   ├── grammar.dart                # Regular grammars
│   ├── grammar_transformations.dart # Grammar transformations
│   ├── layout_algorithms.dart      # Layout algorithms
│   ├── ll_parsing.dart             # LL(1) parsing
│   ├── lr_parsing.dart             # LR(1) parsing
│   ├── mealy_moore.dart            # Output automata
│   ├── mealy_moore_algorithms.dart # Mealy/Moore algorithms
│   ├── nfa_algorithms.dart         # NFA-specific algorithms
│   ├── pda.dart                    # Pushdown automata
│   ├── pda_algorithms.dart         # PDA algorithms
│   ├── pumping_lemmas.dart         # Pumping lemma
│   ├── regex.dart                  # Regular expressions
│   ├── run.dart                    # Automaton simulation
│   ├── turing.dart                 # Turing machines
│   ├── turing_algorithms.dart      # Turing algorithms
│   ├── algo_log.dart               # Algorithm logging
│   ├── error_handler.dart          # Error handling
│   ├── result.dart                 # Operation results
│   ├── entities/                   # Domain entities
│   │   └── automaton_entity.dart
│   ├── parsers/                    # File parsers
│   │   └── jflap_xml_parser.dart
│   ├── repositories/               # Repository interfaces
│   │   └── automaton_repository.dart
│   └── use_cases/                  # Use cases
│       ├── algorithm_use_cases.dart
│       └── automaton_use_cases.dart
├── presentation/                   # User interface
│   ├── pages/                      # Main pages
│   │   ├── cfg_page.dart           # CFG page
│   │   ├── home_page.dart          # Home page
│   │   ├── mealy_moore_page.dart   # Mealy/Moore page
│   │   ├── parsing_page.dart       # Parsing page
│   │   ├── pda_page.dart           # PDA page
│   │   └── turing_page.dart        # Turing page
│   ├── providers/                  # State management
│   │   ├── algorithm_execution_provider.dart
│   │   ├── algorithm_provider.dart
│   │   └── automaton_provider.dart
│   └── widgets/                    # Reusable components
│       ├── advanced_export_tools.dart
│       ├── algorithm_panel.dart
│       ├── automaton_canvas.dart
│       ├── automaton_controls.dart
│       ├── cfg_canvas.dart
│       ├── cfg_controls.dart
│       ├── contextual_help.dart
│       ├── equivalence_checker_viewer.dart
│       ├── examples_library.dart
│       ├── keyboard_shortcuts.dart
│       ├── layout_tools.dart
│       ├── mealy_moore_canvas.dart
│       ├── mealy_moore_controls.dart
│       ├── minimization_interface.dart
│       ├── mobile_navigation.dart
│       ├── pda_canvas.dart
│       ├── pda_controls.dart
│       ├── pumping_lemma_interface.dart
│       ├── turing_canvas.dart
│       ├── turing_controls.dart
│       └── [other specialized widgets]
├── data/                           # Data management
│   ├── data_sources/               # Data sources
│   │   ├── examples_data_source.dart
│   │   └── local_storage_data_source.dart
│   ├── models/                     # Data models
│   │   └── automaton_model.dart
│   └── repositories/               # Repository implementations
│       ├── algorithm_repository_impl.dart
│       ├── automaton_repository_impl.dart
│       └── examples_repository_impl.dart
├── injection/                      # Dependency injection
│   └── dependency_injection.dart
├── app.dart                        # Application configuration
└── main.dart                       # Entry point

test/                               # Tests
├── core/                           # Core algorithm tests
│   ├── nfa_from_regex_test.dart
│   ├── nfa_to_dfa_test.dart
│   └── regex_test.dart
├── core_algorithms_test.dart       # Fundamental algorithm tests
├── dfa_minimization_test.dart      # Minimization tests
├── examples_roundtrip_test.dart    # Compatibility tests
├── ll_lr_parsing_test.dart         # Parsing tests
├── presentation_automaton_provider_test.dart # Provider tests
└── [other specialized tests]
```

### Main Components

- **Interactive Canvas**: Visualization and editing with touch gestures and multi-selection
- **Core Algorithms**: Complete implementations of automata theory algorithms
- **Providers**: State management with Provider pattern
  - AlgorithmProvider: Algorithmic operations
  - AutomatonProvider: Automaton management
  - AlgorithmExecutionProvider: Algorithm execution and visualization
- **Responsive Widgets**: Adaptive components for mobile/desktop
- **Persistence System**: Local storage with SharedPreferences
- **Dependency Injection**: Modular architecture with GetIt
- **Logging System**: Real-time algorithm step visualization
- **Layout Tools**: Automatic positioning presets
- **Help System**: Integrated contextual help
- **Keyboard Shortcuts**: Complete shortcut system
- **Advanced Export**: Multiple output formats
- **JFLAP Import**: Robust XML parser for .jff files

## 🤝 Contributing

1. Fork the project
1. Create a feature branch (`git checkout -b feature/new-feature`)
1. Follow code guidelines (see `analysis_options.yaml`)
1. Run tests (`flutter test`)
1. Commit your changes (`git commit -m 'Add new feature'`)
1. Push to the branch (`git push origin feature/new-feature`)
1. Open a Pull Request

### Development Guidelines

- Maintain clean architecture (core/presentation/data)
- Optimize for mobile devices
- Use JFLAP files as reference for algorithms
- Add tests for new features
- Follow Flutter naming conventions

## 📄 License

This project is derived from JFLAP and is licensed under the same license terms. See the LICENSE file for complete details.

**JFLAP License Summary:**

- You may distribute unmodified copies of JFLAP
- You may distribute modified copies under certain conditions
- You may not charge fees for products that include any part of JFLAP
- You must include a copy of the license text
- The author’s name may not be used to endorse derived products without specific permission

### Special Credits

- **Susan H. Rodger** (Duke University) - Original JFLAP creator
- **JFLAP Team** - Thomas Finley, Ryan Cavalcante, Stephen Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) Lee, Jonathan Su, and Henry Qin

## 📊 Project Status

### Fully Implemented Features ✅

- **Finite Automata**: DFA, NFA, conversions, operations, minimization
- **Grammars and Parsing**: CFG, LL(1), LR(1), CNF, CYK, pumping lemma
- **PDA and Turing**: Pushdown automata and multi-tape machines
- **Mealy/Moore**: Output automata and conversion between types
- **Mobile Interface**: Complete optimization for mobile devices
- **Export/Import**: PNG, SVG, LaTeX, JFLAP files
- **Educational Tools**: Interactive minimization, pumping lemma
- **Help System**: Integrated contextual help
- **Keyboard Shortcuts**: Complete shortcut system
- **Persistence**: Local storage and JSON serialization
- **Examples Library**: Educational examples organized by category

-----

**JFlutter** - Simulating automata in a modern and interactive way! 🎯

*Derived from the original JFLAP - An educational tool for automata theory and formal languages*