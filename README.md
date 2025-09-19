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
├── core/                           # Core business logic
│   ├── algorithms/                 # 13 core algorithms
│   │   ├── automaton_simulator.dart
│   │   ├── nfa_to_dfa_converter.dart
│   │   ├── dfa_minimizer.dart
│   │   ├── regex_to_nfa_converter.dart
│   │   ├── fa_to_regex_converter.dart
│   │   └── [8 more algorithms]
│   ├── models/                     # Data models
│   │   ├── fsa.dart
│   │   ├── state.dart
│   │   ├── transition.dart
│   │   └── [12 more models]
│   └── result.dart                 # Error handling
├── presentation/                   # User interface
│   ├── pages/                      # Main application pages
│   │   ├── home_page.dart          # Main navigation
│   │   ├── fsa_page.dart           # Finite state automata
│   │   ├── grammar_page.dart       # Context-free grammars
│   │   ├── pda_page.dart           # Pushdown automata
│   │   ├── tm_page.dart            # Turing machines
│   │   ├── regex_page.dart         # Regular expressions
│   │   └── pumping_lemma_page.dart # Pumping lemma game
│   ├── widgets/                    # Reusable UI components
│   │   ├── automaton_canvas.dart   # Interactive drawing canvas
│   │   ├── algorithm_panel.dart    # Algorithm controls
│   │   ├── simulation_panel.dart   # Simulation interface
│   │   ├── grammar_editor.dart     # Grammar editing interface
│   │   ├── tm_canvas.dart          # Turing machine canvas
│   │   └── pumping_lemma_game.dart # Interactive game
│   ├── providers/                  # State management
│   │   ├── automaton_provider.dart # Riverpod state management
│   │   ├── algorithm_provider.dart # Algorithm state management
│   │   └── grammar_provider.dart   # Grammar state management
│   └── theme/                      # App theming
│       └── app_theme.dart          # Material 3 themes
├── data/                           # Data management
│   └── services/                   # Business services
│       ├── automaton_service.dart  # CRUD operations
│       ├── simulation_service.dart # Simulation operations
│       └── conversion_service.dart # Algorithm operations
├── injection/                      # Dependency injection
│   └── dependency_injection.dart   # Service registration
├── app.dart                        # App configuration
└── main.dart                       # Entry point
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

Android release builds are signed with the `dev.jflutter.app` application ID. The Gradle script reads release keystore
credentials from `android/key.properties`, so make sure the file exists before building a release artifact.

1. Generate or obtain a release keystore (for example `android/keystores/jflutter-release.jks`). Keep this file out of
   version control.
2. Copy `android/key.properties.example` to `android/key.properties`.
3. Replace the placeholder passwords and alias information with the values that match your keystore. The `storeFile`
   entry can be an absolute path or a path relative to the project root.

For CI/CD, store the keystore and credential values as encrypted secrets. During the workflow, recreate the keystore file
and write `key.properties` before calling `flutter build`. Example (GitHub Actions):

```bash
mkdir -p android/keystores
echo "$JFLUTTER_KEYSTORE_BASE64" | base64 --decode > android/keystores/jflutter-release.jks
cat <<'EOF' > android/key.properties
storeFile=keystores/jflutter-release.jks
storePassword=$JFLUTTER_KEYSTORE_PASSWORD
keyAlias=$JFLUTTER_KEY_ALIAS
keyPassword=$JFLUTTER_KEY_PASSWORD
EOF
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
# Run all tests
flutter test

# Run specific test categories
flutter test test/core/                    # Core algorithm tests
flutter test test/integration/             # Integration tests
flutter test test/contract/                # Contract tests

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

This project is derived from JFLAP and maintains compatibility with the original educational goals. See [LICENSE.txt](LICENSE.txt) for details.

## 🙏 Acknowledgments

- **Susan H. Rodger** (Duke University) - Original JFLAP creator
- **JFLAP Team** - For the foundational educational tool
- **Flutter Team** - For the excellent mobile framework
- **Open Source Community** - For inspiration and support

---

**JFlutter** - Bringing automata theory to your fingertips! 📱✨

*Modern, mobile-first, and educational - the future of formal language learning*