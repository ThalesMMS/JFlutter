# Data Model: Mobile-Optimized JFlutter Core Features

**Date**: 2024-12-19  
**Feature**: Mobile-Optimized JFlutter Core Features  
**Branch**: 002-title-mobile-optimized

## Core Entities

### 1. FeatureTab
**Purpose**: Represents one of the six core automata/formal language features  
**Fields**:
- `id`: String (unique identifier: "finite_automaton", "pushdown_automaton", etc.)
- `displayName`: String (full name for display)
- `abbreviation`: String (short label used on mobile navigation, e.g., "FSA", "Grammar", "PDA", "TM", "Regex", "Pumping")
- `icon`: String (icon identifier)
- `isActive`: Boolean (currently selected tab)
- `workspace`: Workspace (associated workspace instance)

**Relationships**:
- One-to-One with Workspace
- Part of TabCollection

**Validation Rules**:
- id must be one of: finite_automaton, pushdown_automaton, turing_machine, grammar, regular_expression, pumping_lemma
- displayName cannot be empty
- abbreviation must match one of the approved navigation labels (FSA, Grammar, PDA, TM, Regex, Pumping)
- Only one tab can be active at a time

### 2. Workspace
**Purpose**: Main interaction area for each feature tab  
**Fields**:
- `id`: String (matches FeatureTab id)
- `content`: Map<String, dynamic> (feature-specific data)
- `lastModified`: DateTime
- `isDirty`: Boolean (has unsaved changes)
- `viewSettings`: ViewSettings (zoom, pan, etc.)

**Relationships**:
- One-to-One with FeatureTab
- Contains AutomatonData (for automata features)

**Validation Rules**:
- content must be valid JSON
- lastModified must be current or past
- viewSettings must be valid

### 3. AutomatonData
**Purpose**: Base class for automata-specific data structures  
**Fields**:
- `states`: List<State>
- `transitions`: List<Transition>
- `alphabet`: Set<String>
- `initialState`: String?
- `finalStates`: Set<String>
- `metadata`: Map<String, dynamic>

**Relationships**:
- Used by FiniteAutomaton, PushdownAutomaton, TuringMachine
- Contains States and Transitions

**Validation Rules**:
- states cannot be empty
- transitions must reference valid states
- alphabet cannot be empty
- initialState must be in states
- finalStates must be subset of states

### 4. State
**Purpose**: Represents a state in an automaton  
**Fields**:
- `id`: String (unique identifier)
- `label`: String (display name)
- `position`: Point (x, y coordinates)
- `isInitial`: Boolean
- `isFinal`: Boolean
- `isSelected`: Boolean (UI state)

**Relationships**:
- Part of AutomatonData
- Referenced by Transitions

**Validation Rules**:
- id cannot be empty
- label cannot be empty
- position must be within workspace bounds
- Only one state can be initial per automaton

### 5. Transition
**Purpose**: Represents a transition between states  
**Fields**:
- `id`: String (unique identifier)
- `fromState`: String (source state id)
- `toState`: String (target state id)
- `label`: String (transition symbol/condition)
- `controlPoints`: List<Point> (bezier curve control points)
- `isSelected`: Boolean (UI state)

**Relationships**:
- References two States
- Part of AutomatonData

**Validation Rules**:
- fromState and toState must exist in states
- label cannot be empty
- controlPoints must be valid for curve rendering

### 6. GrammarData
**Purpose**: Represents context-free grammar data  
**Fields**:
- `variables`: Set<String> (non-terminals)
- `terminals`: Set<String> (terminals)
- `productions`: List<Production>
- `startVariable`: String
- `metadata`: Map<String, dynamic>

**Relationships**:
- Used by Grammar workspace
- Contains Productions

**Validation Rules**:
- variables and terminals must be disjoint
- startVariable must be in variables
- productions must be valid

### 7. Production
**Purpose**: Represents a grammar production rule  
**Fields**:
- `id`: String (unique identifier)
- `leftSide`: String (non-terminal)
- `rightSide`: String (terminal/non-terminal sequence)
- `isSelected`: Boolean (UI state)

**Relationships**:
- Part of GrammarData

**Validation Rules**:
- leftSide must be in variables
- rightSide can contain variables and terminals only

### 8. RegularExpressionData
**Purpose**: Represents regular expression data  
**Fields**:
- `expression`: String (regex string)
- `alphabet`: Set<String>
- `testStrings`: List<String>
- `metadata`: Map<String, dynamic>

**Relationships**:
- Used by RegularExpression workspace

**Validation Rules**:
- expression must be valid regex
- alphabet must match expression symbols

### 9. PumpingLemmaData
**Purpose**: Represents pumping lemma exercise data  
**Fields**:
- `language`: String (language description)
- `pumpingLength`: int?
- `decomposition`: Map<String, String> (x, y, z parts)
- `testCases`: List<TestCase>
- `metadata`: Map<String, dynamic>

**Relationships**:
- Used by PumpingLemma workspace
- Contains TestCases

**Validation Rules**:
- pumpingLength must be positive if set
- decomposition must be valid if provided

### 10. TestCase
**Purpose**: Represents a test case for pumping lemma  
**Fields**:
- `id`: String (unique identifier)
- `string`: String (test string)
- `expectedResult`: Boolean (should be accepted/rejected)
- `actualResult`: Boolean? (user's answer)
- `isCorrect`: Boolean? (validation result)

**Relationships**:
- Part of PumpingLemmaData

**Validation Rules**:
- string cannot be empty
- expectedResult must be set

### 11. ViewSettings
**Purpose**: UI view configuration for workspaces  
**Fields**:
- `zoomLevel`: double (1.0 = 100%)
- `panOffset`: Point (x, y offset)
- `showGrid`: Boolean
- `gridSize`: double
- `showLabels`: Boolean
- `theme`: String (light/dark)

**Relationships**:
- Used by Workspace

**Validation Rules**:
- zoomLevel must be between 0.1 and 5.0
- gridSize must be positive

### 12. MenuState
**Purpose**: Tracks expandable menu states  
**Fields**:
- `isExpanded`: Boolean
- `selectedItem`: String?
- `lastExpanded`: DateTime?

**Relationships**:
- Used by UI components

**Validation Rules**:
- selectedItem must be valid menu option if set

## State Transitions

### Workspace State Flow
```
Empty → Loading → Ready → Modified → Saving → Ready
  ↓       ↓        ↓        ↓         ↓        ↓
Error ← Error ← Error ← Error ← Error ← Error
```

### Automaton Creation Flow
```
Empty → Adding States → Adding Transitions → Complete
  ↓           ↓                ↓              ↓
Error ← Error ← Error ← Error
```

## Data Persistence

### Local Storage Schema
```json
{
  "workspaces": {
    "finite_automaton": { /* AutomatonData */ },
    "pushdown_automaton": { /* AutomatonData */ },
    "turing_machine": { /* AutomatonData */ },
    "grammar": { /* GrammarData */ },
    "regular_expression": { /* RegularExpressionData */ },
    "pumping_lemma": { /* PumpingLemmaData */ }
  },
  "viewSettings": { /* ViewSettings */ },
  "appState": {
    "activeTab": "finite_automaton",
    "lastModified": "2024-12-19T10:30:00Z"
  }
}
```

### Serialization Rules
- All entities implement `toJson()` and `fromJson()` methods
- DateTime objects stored as ISO 8601 strings
- Sets converted to Lists for JSON compatibility
- Custom objects serialized as Maps with type information
