# Data Model: JFlutter

**Date**: 2024-12-19  
**Purpose**: Define core data structures for automata and grammars

## Core Entities

### Automaton
```dart
abstract class Automaton {
  String id;
  String name;
  Set<State> states;
  Set<Transition> transitions;
  Set<String> alphabet;
  State? initialState;
  Set<State> acceptingStates;
  AutomatonType type;
  DateTime created;
  DateTime modified;
  Rectangle bounds; // For mobile layout
  double zoomLevel;
  Point panOffset;
}
```

**Properties**:
- `id`: Unique identifier for persistence
- `name`: User-defined name
- `states`: Set of all states in the automaton
- `transitions`: Set of all transitions between states
- `alphabet`: Input alphabet symbols
- `initialState`: Starting state (can be null)
- `acceptingStates`: Set of accepting/final states
- `type`: FSA, PDA, or TM
- `bounds`: Bounding rectangle for mobile display
- `zoomLevel`: Current zoom level (0.5 to 3.0)
- `panOffset`: Pan offset for mobile navigation

**Validation Rules**:
- Must have at least one state
- Initial state must be in states set
- All accepting states must be in states set
- Transitions must reference valid states

### State
```dart
class State {
  String id;
  String label;
  Point position; // Mobile-optimized positioning
  bool isInitial;
  bool isAccepting;
  StateType type;
  Map<String, dynamic> properties; // For extensions
}
```

**Properties**:
- `id`: Unique identifier within automaton
- `label`: Display label (can be empty)
- `position`: Screen position for mobile layout
- `isInitial`: Whether this is the initial state
- `isAccepting`: Whether this is an accepting state
- `type`: State type (normal, trap, etc.)
- `properties`: Additional properties for different automaton types

**Validation Rules**:
- Position must be within automaton bounds
- Label must be unique within automaton (if not empty)
- Only one initial state per automaton

### Transition
```dart
abstract class Transition {
  String id;
  State fromState;
  State toState;
  String label;
  Point controlPoint; // For curved transitions on mobile
  TransitionType type;
}
```

**Properties**:
- `id`: Unique identifier within automaton
- `fromState`: Source state
- `toState`: Destination state
- `label`: Input symbol(s) or operation
- `controlPoint`: Control point for curved rendering
- `type`: Type of transition (deterministic, nondeterministic)

**Validation Rules**:
- fromState and toState must be in automaton states
- Label must be valid for automaton type
- Control point must be reasonable for display

### FSATransition
```dart
class FSATransition extends Transition {
  Set<String> inputSymbols; // Can be multiple for NFA
  String? lambdaSymbol; // For lambda transitions
}
```

### PDATransition
```dart
class PDATransition extends Transition {
  String inputSymbol;
  String popSymbol;
  String pushSymbol;
  bool isLambdaInput;
  bool isLambdaPop;
  bool isLambdaPush;
}
```

### TMTransition
```dart
class TMTransition extends Transition {
  String readSymbol;
  String writeSymbol;
  TapeDirection direction; // LEFT, RIGHT, STAY
  int tapeNumber; // For multi-tape machines
}
```

### MealyTransition
```dart
class MealyTransition extends Transition {
  String inputSymbol;
  String outputSymbol;
}
```

### Grammar
```dart
class Grammar {
  String id;
  String name;
  Set<String> terminals;
  Set<String> nonterminals;
  String startSymbol;
  Set<Production> productions;
  GrammarType type;
  DateTime created;
  DateTime modified;
}
```

**Properties**:
- `id`: Unique identifier for persistence
- `name`: User-defined name
- `terminals`: Terminal symbols
- `nonterminals`: Non-terminal symbols
- `startSymbol`: Grammar start symbol
- `productions`: Set of production rules
- `type`: Regular, Context-Free, or Unrestricted

**Validation Rules**:
- Start symbol must be in nonterminals
- Productions must use only defined symbols
- Must have at least one production

### Production
```dart
class Production {
  String id;
  List<String> leftSide; // Support multiple symbols for unrestricted grammars
  List<String> rightSide;
  bool isLambda; // For lambda productions
  int order; // For display ordering
}
```

**Properties**:
- `id`: Unique identifier within grammar
- `leftSide`: Left-hand side symbol
- `rightSide`: List of right-hand side symbols
- `isLambda`: Whether this is a lambda production
- `order`: Display order in UI

**Validation Rules**:
- Left side must be non-terminal
- Right side symbols must be terminals or non-terminals
- Lambda productions must have empty right side

### SimulationResult
```dart
class SimulationResult {
  String inputString;
  bool accepted;
  List<SimulationStep> steps;
  String errorMessage;
  Duration executionTime;
}
```

### SimulationStep
```dart
class SimulationStep {
  State currentState;
  String remainingInput;
  String stackContents; // For PDA
  String tapeContents; // For TM
  Transition? usedTransition;
  int stepNumber;
}
```

### ParseTable
```dart
class ParseTable {
  Map<String, Map<String, ParseAction>> actionTable;
  Map<String, Map<String, String>> gotoTable;
  Grammar grammar;
  ParseType type; // LL or LR
}
```

### ParseAction
```dart
enum ParseActionType { SHIFT, REDUCE, ACCEPT, ERROR }

class ParseAction {
  ParseActionType type;
  int? stateNumber; // For shift
  Production? production; // For reduce
  String? errorMessage;
}
```

## Mobile-Specific Extensions

### TouchInteraction
```dart
class TouchInteraction {
  InteractionType type;
  Point position;
  Set<String> selectedStates;
  Set<String> selectedTransitions;
  DateTime timestamp;
}
```

### LayoutSettings
```dart
class LayoutSettings {
  double nodeRadius;
  double edgeThickness;
  ColorScheme colorScheme;
  bool showGrid;
  bool snapToGrid;
  double gridSize;
}
```

### L-System
```dart
class LSystem {
  String id;
  String name;
  String axiom;
  Map<String, String> productions; // Symbol -> replacement string
  int iterations;
  LSystemParameters parameters;
  DateTime created;
  DateTime modified;
}

class LSystemParameters {
  double angle;
  double distance;
  double lineWidth;
  Color lineColor;
  Color fillColor;
  double lineWidthIncrement;
  double hueVariation;
}
```

### TurtleState
```dart
class TurtleState {
  Point position;
  double angle;
  double lineWidth;
  Color lineColor;
  Color fillColor;
  bool penDown;
  Stack<TurtleState> stateStack; // For save/restore operations
}
```

### BuildingBlock
```dart
class BuildingBlock {
  String id;
  String name;
  String description;
  Automaton automaton;
  List<String> inputParameters;
  List<String> outputParameters;
  bool isSystemBlock;
  DateTime created;
  DateTime modified;
}
```

### PumpingLemmaGame
```dart
class PumpingLemmaGame {
  String id;
  String language;
  GameType type; // REGULAR or CONTEXT_FREE
  GameMode mode; // USER_FIRST or COMPUTER_FIRST
  int pumpingConstant;
  List<PumpingAttempt> attempts;
  GameState state;
}

class PumpingAttempt {
  String decomposition;
  String pumpedString;
  bool isValid;
  String explanation;
  DateTime timestamp;
}

enum GameType { REGULAR, CONTEXT_FREE }
enum GameMode { USER_FIRST, COMPUTER_FIRST }
enum GameState { ACTIVE, COMPLETED, FAILED }
```

## Data Relationships

```
Automaton (1) ──→ (many) State
Automaton (1) ──→ (many) Transition
State (1) ──→ (many) Transition [as fromState]
State (1) ──→ (many) Transition [as toState]
Grammar (1) ──→ (many) Production
Automaton ──→ SimulationResult [1:many]
Grammar ──→ ParseTable [1:many]
```

## State Transitions

### Automaton States
- `CREATING` → `EDITING` → `VALIDATING` → `READY`
- `READY` → `SIMULATING` → `READY`
- `READY` → `SAVING` → `READY`

### Grammar States  
- `CREATING` → `EDITING` → `VALIDATING` → `READY`
- `READY` → `PARSING` → `READY`
- `READY` → `TRANSFORMING` → `READY`

## Validation Rules Summary

1. **Automaton Validation**:
   - Must have at least one state
   - Initial state must exist and be unique
   - All transitions must reference valid states
   - Alphabet must be non-empty

2. **State Validation**:
   - Position must be within bounds
   - Labels must be unique (if not empty)
   - Only one initial state per automaton

3. **Transition Validation**:
   - Input symbols must be in alphabet
   - Stack operations must be valid for PDA
   - Tape operations must be valid for TM

4. **Grammar Validation**:
   - Start symbol must be non-terminal
   - All symbols in productions must be defined
   - Must have at least one production

## Performance Considerations

- Use `Set` for states and transitions for O(1) lookup
- Cache simulation results for repeated inputs
- Limit automaton size to 200 states for mobile performance
- Use lazy loading for large parse tables
- Implement efficient layout algorithms for mobile screens
