# JFlutter 🚀

**A modern, mobile-first Flutter application for learning formal language theory and automata**

JFlutter is a complete port of the classic JFLAP educational tool, rebuilt from the ground up with Flutter for modern mobile devices. It provides an interactive, touch-optimized interface for creating, editing, and simulating finite automata, context-free grammars, and other formal language constructs.

## ✅ Current Status

**🎉 FULLY FUNCTIONAL - READY FOR USE**

The project has been successfully fixed and is now fully functional on all supported platforms. All major compilation errors, runtime issues, and UI layout problems have been resolved.

**Latest Updates**:
- ✅ All compilation errors fixed
- ✅ Runtime errors resolved (Riverpod state management)
- ✅ UI layout issues fixed (responsive design)
- ✅ Grammar screen working properly
- ✅ Settings screen fully functional
- ✅ TM Canvas layout optimized
- ✅ Pumping Lemma Game responsive
- ✅ All screens tested on iPhone 17 Pro Max

## ✨ Key Features

### 🎯 **Core Functionality**
- **Interactive Automaton Creation** - Touch-optimized canvas for drawing states and transitions
- **Real-time Simulation** - Test strings against automata with step-by-step visualization
- **Algorithm Integration** - 13 core algorithms fully integrated with the UI
- **Mobile-First Design** - Optimized for smartphones and tablets
- **Modern UI/UX** - Material 3 design with dark/light theme support
- **Responsive Layout** - All screens adapt to different screen sizes

### 🔧 **Implemented Algorithms**
- **NFA to DFA Conversion** - Convert non-deterministic to deterministic automata
- **DFA Minimization** - Minimize deterministic finite automata
- **Regex to NFA** - Convert regular expressions to automata
- **FA to Regex** - Convert automata to regular expressions
- **Automaton Simulation** - Real-time string testing and validation
- **Grammar Parsing** - Context-free grammar analysis
- **Pumping Lemma** - Interactive educational game
- **PDA Simulation** - Pushdown automata simulation
- **Turing Machine** - Single-tape Turing machine simulation

### 📱 **Mobile Experience**
- **Touch Gestures** - Pinch-to-zoom, pan, tap-to-add states
- **Responsive Layout** - Adapts to different screen sizes
- **Collapsible Panels** - Space-efficient mobile interface
- **Bottom Navigation** - Mobile-optimized navigation
- **Visual Feedback** - Real-time algorithm execution feedback
- **Overflow Prevention** - All UI elements handle small screens gracefully

## 🏗️ Architecture

### **Clean Architecture Implementation**
```
┌─────────────────────────────────────┐
│        Presentation Layer           │
│  (UI Components, Pages, Providers)  │
├─────────────────────────────────────┤
│         Core Layer                  │
│  (Algorithms, Models, Business)     │
├─────────────────────────────────────┤
│          Data Layer                 │
│  (Services, Repositories, Storage)  │
└─────────────────────────────────────┘
```

### **Project Structure**
```
lib/
├── app.dart                        # Root widget and global configuration
├── core/                           # Core business logic
│   ├── algorithms/                 # Automata algorithms and utilities
│   ├── entities/                   # Domain entities shared across layers
│   ├── models/                     # Immutable data models and value objects
│   ├── parsers/                    # File/grammar parsing helpers
│   ├── repositories/               # Repository contracts
│   ├── use_cases/                  # Application-specific business rules
│   ├── algo_log.dart               # Algorithm execution logging
│   ├── error_handler.dart          # Error handling helpers
│   └── result.dart                 # Result/Either pattern implementation
├── data/                           # Data layer implementations
│   ├── data_sources/               # Concrete data sources (e.g., file system)
│   ├── models/                     # DTOs and serialization helpers
│   ├── repositories/               # Repository implementations
│   └── services/                   # High-level services used by the app
├── features/                       # Cross-cutting feature modules
│   └── layout/                     # Layout helpers and view-specific configs
├── injection/                      # Dependency injection setup
│   └── dependency_injection.dart   # Service registration and bootstrap
├── main.dart                       # Application entry point
└── presentation/                   # UI layer and state management
    ├── pages/                      # Screens and navigation flows
    ├── providers/                  # Riverpod providers
    ├── theme/                      # App theming (Material 3)
    └── widgets/                    # Reusable UI components
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.16+ 
- Dart SDK 3.0+
- Android Studio / VS Code (recommended)

### Installation

```bash
# Clone the repository
git clone https://github.com/ThalesMMS/jflutter.git
cd jflutter

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Android release signing

Android release builds are signed with the `dev.jflutter.app` application ID. The Gradle script loads release keystore
credentials from `android/key.properties`, which can now be generated from environment variables using
`android/scripts/create_key_properties.sh`.

1. Generate or obtain a release keystore (for example `android/keystores/jflutter-release.jks`). Keep this file out of
   version control.
2. Export the following environment variables before building or running the helper script:
   - `JFLUTTER_KEYSTORE_PASSWORD`
   - `JFLUTTER_KEY_ALIAS`
   - `JFLUTTER_KEY_PASSWORD`
   - *(optional)* `JFLUTTER_KEYSTORE_PATH` (defaults to `keystores/jflutter-release.jks`, relative to `android/`)
3. Run `./android/scripts/create_key_properties.sh` to generate `android/key.properties` from the exported values.

For CI/CD, store the keystore and credential values as encrypted secrets. During the workflow, recreate the keystore file
and call the helper script before `flutter build`. Example (GitHub Actions):

```bash
mkdir -p android/keystores
echo "$JFLUTTER_KEYSTORE_BASE64" | base64 --decode > android/keystores/jflutter-release.jks
export JFLUTTER_KEYSTORE_PASSWORD="$JFLUTTER_KEYSTORE_PASSWORD"
export JFLUTTER_KEY_ALIAS="$JFLUTTER_KEY_ALIAS"
export JFLUTTER_KEY_PASSWORD="$JFLUTTER_KEY_PASSWORD"
./android/scripts/create_key_properties.sh
```

### Platform Support
- ✅ **Android** - Full support with touch optimization
- ✅ **iOS** - Full support with native feel (tested on iPhone 17 Pro Max)
- ✅ **Web** - Responsive web interface
- ✅ **Desktop** - Windows, macOS, Linux support

## 📱 How to Use

### Creating an Automaton
1. Open the **FSA** tab
2. Tap the **"+"** button to add states
3. Tap the **arrow** button to add transitions
4. Tap on states to mark them as initial/final
5. Use the **algorithms panel** to convert or minimize

### Testing Strings
1. Enter a string in the **simulation panel**
2. Tap **"Simulate"** to test acceptance
3. View **step-by-step execution** results
4. See **visual feedback** on the canvas

### Using Algorithms
1. **Regex to NFA**: Enter a regular expression
2. **NFA to DFA**: Convert non-deterministic automata
3. **Minimize DFA**: Reduce state count
4. **FA to Regex**: Generate regular expressions

### Working with Grammars
1. Open the **Grammar** tab
2. Enter grammar name and start symbol
3. Add production rules using the editor
4. Test strings with the simulation panel
5. Use algorithms to convert between formats

## 🧪 Testing

```bash
# Run the full automated test suite (contract, integration, widget, and unit tests)
flutter test

# Run targeted suites
flutter test test/contract/                # Service contract coverage
flutter test test/integration/             # End-to-end feature workflows
flutter test test/unit/                    # Model/algorithm/service units
flutter test test/widget/                  # Widget-level regressions

# Generate coverage data (stored under coverage/lcov.info)
flutter test --coverage

# Static analysis
flutter analyze
```

## 📊 Project Status

### ✅ **Completed Features**
- **Core Algorithms** - 13 algorithms fully implemented and tested
- **Data Models** - Complete model library with mobile extensions
- **UI Components** - Modern, responsive interface
- **State Management** - Riverpod-based reactive state
- **Mobile Optimization** - Touch-first design
- **Error Handling** - Comprehensive error management
- **Testing** - Full test coverage for core functionality
- **Responsive Design** - All screens adapt to different screen sizes
- **Grammar Editor** - Visual context-free grammar editing
- **Turing Machine Canvas** - Interactive TM interface
- **Pumping Lemma Game** - Interactive educational game
- **Settings Screen** - Comprehensive configuration options

### 🔄 **In Progress**
- **Enhanced Visualizations** - Advanced algorithm step visualization
- **File Import/Export** - JFLAP file compatibility
- **Advanced Features** - More complex automata types

### 📋 **Planned Features**
- **PDA Canvas** - Pushdown automata visualization
- **Advanced Grammar Features** - More grammar analysis tools
- **Export Options** - Save automata in various formats
- **Tutorial System** - Guided learning experience

## 🛠️ Development

### Code Quality
- **Clean Architecture** - Separation of concerns
- **Type Safety** - Strong typing throughout
- **Error Handling** - Comprehensive error management
- **Testing** - Unit, integration, and contract tests
- **Documentation** - Inline documentation and examples
- **Responsive Design** - Mobile-first approach

### Contributing
1. Fork the repository
2. Create a feature branch
3. Follow the coding standards
4. Add tests for new features
5. Submit a pull request

### Development Guidelines
- Use **Riverpod** for state management
- Follow **Material 3** design principles
- Optimize for **mobile devices**
- Write **comprehensive tests**
- Document **public APIs**
- Ensure **responsive design** for all screen sizes

## 📚 Educational Value

JFlutter is designed for:
- **Computer Science Students** - Learning automata theory
- **Educators** - Teaching formal languages
- **Researchers** - Prototyping automata
- **Developers** - Understanding regular expressions

### Learning Path
1. **Start with FSA** - Learn finite state automata basics
2. **Explore Algorithms** - Understand conversions and minimization
3. **Practice Simulation** - Test strings and see execution
4. **Advanced Topics** - Move to grammars and parsing
5. **Interactive Games** - Use pumping lemma for deeper understanding

## 🎯 Performance

- **Optimized Rendering** - Custom painters for smooth canvas
- **Efficient State** - Minimal rebuilds with Riverpod
- **Memory Management** - Proper resource disposal
- **Mobile Performance** - 60fps on modern devices
- **Responsive UI** - Smooth adaptation to different screen sizes

## 📄 License

This project is distributed under a dual license structure:

### Port to Flutter
- **License**: Apache License 2.0
- **Copyright**: 2025 Thales Matheus Mendonça Santos
- **Contact**: thalesmmsradio@gmail.com
- **File**: [LICENSE.txt](LICENSE.txt)

### Original JFLAP Code
- **License**: JFLAP 7.1 License (Non-commercial)
- **Copyright**: 2002-2009 Susan H. Rodger (Duke University)
- **File**: [LICENSE_JFLAP.txt](LICENSE_JFLAP.txt)

### License Summary
- The **Flutter port** (all new code) is licensed under Apache 2.0, allowing free use, modification, and distribution with proper attribution
- The **original JFLAP algorithms and concepts** remain under the original JFLAP license, which prohibits commercial use
- This dual structure ensures compliance with the original license while allowing the Flutter port to be freely used and modified

## 🙏 Acknowledgments

### Port Development
- **Thales Matheus Mendonça Santos** - Complete Flutter port development
- **Email**: thalesmmsradio@gmail.com
- **Year**: 2025

### Original Project
- **Susan H. Rodger** (Duke University) - Original JFLAP creator and maintainer
- **JFLAP Team** - Thomas Finley, Ryan Cavalcante, Stephen Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) Lee, Jonathan Su, Henry Qin
- **Duke University** - For the foundational educational tool
- **Website**: http://www.jflap.org

### Technology Stack
- **Flutter Team** - For the excellent mobile framework
- **Dart Team** - For the programming language
- **Open Source Community** - For inspiration and support
- **[@Gaok1](https://github.com/Gaok1)** - Luis Phillip Lemos Martins - For inspiring this Flutter port project

---

**JFlutter** - Bringing automata theory to your fingertips! 📱✨

*Modern, mobile-first, and educational - the future of formal language learning*
