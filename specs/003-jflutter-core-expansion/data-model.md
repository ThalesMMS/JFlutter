# Data Model: JFlutter Core Expansion

## Core Modeling Entities

### FiniteAutomaton
**Purpose**: Represents deterministic and non-deterministic finite automata with states, transitions, and acceptance criteria

**Fields**:
- `id: String` - Unique identifier for the automaton
- `name: String` - User-defined name for the automaton
- `states: Set<State>` - Collection of states in the automaton
- `transitions: Set<Transition>` - Collection of transitions between states
- `initialState: StateId?` - Initial state (nullable for empty automata)
- `acceptingStates: Set<StateId>` - Set of accepting states
- `alphabet: Alphabet<String>` - Input alphabet symbols
- `isDeterministic: bool` - Whether the automaton is deterministic
- `metadata: AutomatonMetadata` - Creation date, author, description

**Relationships**:
- Contains multiple `State` entities
- Contains multiple `Transition` entities
- References `Alphabet` for symbol validation
- Associated with `Trace` entities for execution history

**Validation Rules**:
- All states must have unique IDs within the automaton
- All transitions must reference valid states
- Initial state must be in the states set
- Accepting states must be in the states set
- Transition symbols must be in the alphabet

**State Transitions**:
- `draft` → `validated` (when all validation rules pass)
- `validated` → `executing` (during simulation)
- `executing` → `completed` (simulation finished)

### PushdownAutomaton
**Purpose**: Extends automaton concept with stack operations and multiple acceptance modes

**Fields**:
- `id: String` - Unique identifier for the PDA
- `name: String` - User-defined name for the PDA
- `states: Set<State>` - Collection of states in the PDA
- `transitions: Set<PDATransition>` - Collection of PDA transitions
- `initialState: StateId?` - Initial state
- `acceptingStates: Set<StateId>` - Set of accepting states
- `stackAlphabet: Alphabet<String>` - Stack symbol alphabet
- `inputAlphabet: Alphabet<String>` - Input symbol alphabet
- `acceptanceMode: AcceptanceMode` - final state, empty stack, or both
- `initialStackSymbol: String?` - Initial stack symbol
- `metadata: AutomatonMetadata` - Creation metadata

**Relationships**:
- Inherits from `FiniteAutomaton` structure
- Contains `PDATransition` entities with stack operations
- Associated with `Configuration` entities for execution state

**Validation Rules**:
- Stack alphabet and input alphabet must be disjoint
- All stack operations must use valid stack symbols
- Initial stack symbol must be in stack alphabet
- Acceptance mode must be valid enum value

**State Transitions**:
- `draft` → `validated` (when PDA-specific validation passes)
- `validated` → `executing` (during simulation with stack tracking)
- `executing` → `completed` (simulation finished)

### TuringMachine
**Purpose**: Single-tape computational model with immutable configurations and execution traces

**Fields**:
- `id: String` - Unique identifier for the TM
- `name: String` - User-defined name for the TM
- `states: Set<State>` - Collection of states in the TM
- `transitions: Set<TMTransition>` - Collection of TM transitions
- `initialState: StateId?` - Initial state
- `acceptingStates: Set<StateId>` - Set of accepting states
- `rejectingStates: Set<StateId>` - Set of rejecting states
- `tapeAlphabet: Alphabet<String>` - Tape symbol alphabet
- `inputAlphabet: Alphabet<String>` - Input symbol alphabet
- `blankSymbol: String` - Blank tape symbol
- `isDeterministic: bool` - Whether the TM is deterministic
- `metadata: AutomatonMetadata` - Creation metadata

**Relationships**:
- Contains `TMTransition` entities with tape operations
- Associated with `Configuration` entities for tape state
- Uses `BuildingBlock` entities for common operations

**Validation Rules**:
- Tape alphabet must include input alphabet and blank symbol
- All tape operations must use valid tape symbols
- Transitions must specify valid tape read/write/move operations
- Accepting and rejecting states must be disjoint

**State Transitions**:
- `draft` → `validated` (when TM-specific validation passes)
- `validated` → `executing` (during simulation with tape tracking)
- `executing` → `completed` (simulation finished)

### ContextFreeGrammar
**Purpose**: Production rule system with non-terminals, terminals, and derivation trees

**Fields**:
- `id: String` - Unique identifier for the CFG
- `name: String` - User-defined name for the CFG
- `startSymbol: String` - Start symbol for derivations
- `nonTerminals: Set<String>` - Set of non-terminal symbols
- `terminals: Set<String>` - Set of terminal symbols
- `productions: Set<Production>` - Collection of production rules
- `isInCNF: bool` - Whether grammar is in Chomsky Normal Form
- `metadata: AutomatonMetadata` - Creation metadata

**Relationships**:
- Contains multiple `Production` entities
- Associated with `DerivationTree` entities for parsing
- Can be converted to/from `PushdownAutomaton`

**Validation Rules**:
- Start symbol must be a non-terminal
- Non-terminals and terminals must be disjoint
- All production rules must use valid symbols
- Grammar must be context-free (left side single non-terminal)

**State Transitions**:
- `draft` → `validated` (when CFG validation passes)
- `validated` → `parsing` (during string recognition)
- `parsing` → `completed` (parsing finished)

### RegularExpression
**Purpose**: Pattern matching system with AST representation and operator support

**Fields**:
- `id: String` - Unique identifier for the regex
- `name: String` - User-defined name for the regex
- `pattern: String` - Regular expression pattern string
- `ast: RegexAST?` - Abstract syntax tree representation
- `supportedOperators: Set<RegexOperator>` - Basic operators (union, concatenation, star, parentheses)
- `metadata: AutomatonMetadata` - Creation metadata

**Relationships**:
- Contains `RegexAST` entity for tree representation
- Can be converted to `FiniteAutomaton` via Thompson construction
- Associated with `RegexMatch` entities for pattern matching

**Validation Rules**:
- Pattern must be valid regex syntax
- Only basic operators are supported (union |, concatenation, Kleene star *, parentheses)
- AST must be constructible from pattern
- Pattern must be parseable by PetitParser

**State Transitions**:
- `draft` → `parsed` (when AST construction succeeds)
- `parsed` → `converted` (when NFA conversion succeeds)
- `converted` → `simulating` (during string matching)

## Execution and Trace Entities

### Configuration
**Purpose**: Immutable snapshot of automaton state during execution

**Fields**:
- `id: String` - Unique configuration identifier
- `automatonId: String` - Reference to parent automaton
- `currentState: StateId` - Current state in execution
- `inputPosition: int` - Current position in input string
- `remainingInput: String` - Remaining input to process
- `stackContents: List<String>?` - Stack state (for PDA)
- `tapeContents: String?` - Tape contents (for TM)
- `tapePosition: int?` - Current tape head position (for TM)
- `timestamp: DateTime` - When configuration was created
- `stepNumber: int` - Execution step number

**Relationships**:
- Belongs to one `Automaton` entity
- Part of `Trace` entity sequence
- References `State` entity for current state

**Validation Rules**:
- Input position must be within bounds
- Stack contents must be valid for PDA
- Tape position must be within tape bounds for TM
- Step number must be non-negative

**Immutability**: All fields are final and immutable for time-travel debugging

### Trace
**Purpose**: Complete execution record with time-travel capability and step-by-step analysis

**Fields**:
- `id: String` - Unique trace identifier
- `automatonId: String` - Reference to parent automaton
- `inputString: String` - Original input string
- `configurations: List<Configuration>` - Ordered sequence of configurations
- `executionResult: ExecutionResult` - Final execution outcome
- `executionTime: Duration` - Total execution time
- `isAccepting: bool` - Whether input was accepted
- `errorMessage: String?` - Error message if execution failed
- `metadata: TraceMetadata` - Execution metadata

**Relationships**:
- Contains ordered sequence of `Configuration` entities
- Belongs to one `Automaton` entity
- Associated with `ExecutionReport` entity

**Validation Rules**:
- Configurations must be in chronological order
- First configuration must be initial state
- Execution result must be consistent with final configuration
- Trace must be serializable for persistence

**Time-Travel Capability**: Immutable configurations enable stepping back to any execution point

### ExecutionReport
**Purpose**: Performance metrics, algorithm analysis, and diagnostic information

**Fields**:
- `id: String` - Unique report identifier
- `traceId: String` - Reference to execution trace
- `algorithmType: AlgorithmType` - Type of algorithm executed
- `performanceMetrics: PerformanceMetrics` - Execution performance data
- `diagnostics: List<Diagnostic>` - Algorithm-specific diagnostics
- `memoryUsage: MemoryUsage` - Memory consumption data
- `generatedAt: DateTime` - Report generation timestamp

**Relationships**:
- Belongs to one `Trace` entity
- Contains multiple `Diagnostic` entities
- Associated with `PerformanceBenchmark` entities

**Validation Rules**:
- Performance metrics must be non-negative
- Diagnostics must be relevant to algorithm type
- Memory usage must be reasonable
- Report must be generated after trace completion

### AlgorithmResult
**Purpose**: Output of language operations, conversions, and property checking with proof validation

**Fields**:
- `id: String` - Unique result identifier
- `algorithmType: AlgorithmType` - Type of algorithm executed
- `inputAutomata: List<String>` - Input automaton IDs
- `outputAutomaton: String?` - Output automaton ID (if applicable)
- `result: AlgorithmResultType` - Success, failure, or partial success
- `proof: Proof?` - Mathematical proof of correctness (if applicable)
- `executionTrace: String?` - Reference to execution trace
- `metadata: AlgorithmMetadata` - Algorithm-specific metadata

**Relationships**:
- References multiple input `Automaton` entities
- References output `Automaton` entity (if applicable)
- Associated with `Proof` entity for correctness validation

**Validation Rules**:
- Input automata must exist and be valid
- Output automaton must be valid (if present)
- Proof must be mathematically sound (if present)
- Result must be consistent with algorithm type

## Serialization and Interop Entities

### AutomatonSchema
**Purpose**: JSON schema definitions for FA, PDA, TM, and CFG serialization formats

**Fields**:
- `id: String` - Unique schema identifier
- `version: String` - Schema version number
- `automatonType: AutomatonType` - Type of automaton (FA, PDA, TM, CFG)
- `schemaDefinition: Map<String, dynamic>` - JSON schema definition
- `validationRules: List<ValidationRule>` - Schema validation rules
- `createdAt: DateTime` - Schema creation timestamp
- `isDeprecated: bool` - Whether schema is deprecated

**Relationships**:
- Used by `Automaton` entities for serialization
- Referenced by `JFLAPFile` entities for compatibility
- Associated with `SchemaMigration` entities for versioning

**Validation Rules**:
- Schema definition must be valid JSON Schema
- Version must follow semantic versioning
- Validation rules must be consistent with schema
- Deprecated schemas must have migration path

### JFLAPFile
**Purpose**: Import/export format maintaining compatibility with original JFLAP tool

**Fields**:
- `id: String` - Unique file identifier
- `filename: String` - Original filename
- `fileContent: String` - Raw JFLAP file content
- `automatonType: AutomatonType` - Detected automaton type
- `jflapVersion: String` - JFLAP version compatibility
- `importStatus: ImportStatus` - Success, partial, or failure
- `errorMessages: List<String>` - Import error messages
- `convertedAutomaton: String?` - JFlutter automaton ID (if conversion succeeded)

**Relationships**:
- Converts to JFlutter `Automaton` entities
- References `AutomatonSchema` entities for validation
- Associated with `ImportReport` entities

**Validation Rules**:
- File content must be valid JFLAP format
- Automaton type must be detectable
- Import status must reflect actual conversion result
- Error messages must be helpful for users

### ExampleLibrary
**Purpose**: Canonical test cases and educational examples with version control

**Fields**:
- `id: String` - Unique library identifier
- `version: String` - Library version number
- `name: String` - Library name (e.g., "Examples v1")
- `examples: List<Example>` - Collection of canonical examples
- `categories: Set<String>` - Example categories (FA, PDA, TM, CFG)
- `difficultyLevels: Set<DifficultyLevel>` - Beginner, intermediate, advanced
- `createdAt: DateTime` - Library creation timestamp
- `lastUpdated: DateTime` - Last update timestamp

**Relationships**:
- Contains multiple `Example` entities
- Used by `RegressionTest` entities
- Associated with `EducationalGuide` entities

**Validation Rules**:
- Examples must cover all automaton types
- Difficulty levels must be appropriate
- Examples must be educational and canonical
- Version must be unique and incremental

### PackageAPI
**Purpose**: Clean interface definitions for core_fa, core_pda, core_tm, core_regex packages

**Fields**:
- `id: String` - Unique API identifier
- `packageName: String` - Package name (core_fa, core_pda, etc.)
- `version: String` - API version
- `publicClasses: List<ClassDefinition>` - Public class definitions
- `publicMethods: List<MethodDefinition>` - Public method definitions
- `dependencies: List<String>` - Package dependencies
- `documentation: String` - API documentation
- `lastUpdated: DateTime` - Last update timestamp

**Relationships**:
- Defines interfaces for `Automaton` entities
- Used by `PlaygroundPackage` entities for integration
- Associated with `APIDocumentation` entities

**Validation Rules**:
- Public interfaces must be stable
- Dependencies must be minimal
- Documentation must be comprehensive
- Version changes must follow semantic versioning

## Data Model Relationships

### Entity Relationships
- `Automaton` (1) → (N) `State`: Each automaton contains multiple states
- `Automaton` (1) → (N) `Transition`: Each automaton contains multiple transitions
- `Automaton` (1) → (N) `Trace`: Each automaton can have multiple execution traces
- `Trace` (1) → (N) `Configuration`: Each trace contains multiple configurations
- `Automaton` (1) → (N) `AlgorithmResult`: Each automaton can be input/output of algorithms

### Inheritance Hierarchy
- `FiniteAutomaton` (base class)
- `PushdownAutomaton` extends automaton concepts
- `TuringMachine` extends automaton concepts
- `ContextFreeGrammar` (separate hierarchy)
- `RegularExpression` (separate hierarchy)

### Package Dependencies
- `core_fa` → `core_entities` (shared base classes)
- `core_pda` → `core_fa` (extends FA concepts)
- `core_tm` → `core_fa` (extends FA concepts)
- `core_regex` → `core_fa` (converts to FA)
- `conversions` → all core packages (algorithm implementations)
- `serializers` → all core packages (import/export)
- `viz` → all core packages (visualization)
- `playground` → all packages (integration demo)

## Validation and Constraints

### Cross-Entity Validation
- All automaton references must exist
- All state IDs must be unique within automaton
- All transition references must be valid
- All alphabet symbols must be consistent
- All execution traces must be complete

### Business Rules
- Language operations must preserve automaton validity
- Algorithm results must be mathematically sound
- Import/export must maintain data integrity
- Performance must meet specified budgets
- Educational examples must be pedagogically sound

### Data Integrity
- Immutable configurations for time-travel debugging
- Referential integrity for all entity relationships
- Consistent state transitions for all entities
- Validation at entity and aggregate levels
- Error handling for all invalid states
