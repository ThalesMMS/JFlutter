# Feature Specification: JFlutter Core Expansion and Interoperability

**Feature Branch**: `003-jflutter-core-expansion`  
**Created**: 2025-01-27  
**Status**: Draft  
**Input**: User description: "Projeto: JFlutter — Expansão de núcleo + interoperabilidade + gramáticas + TMs. Contexto: Status atual: app funcional (Android/iOS/Web/Desktop), 13 algoritmos integrados, UI Material 3, testes amplos, export SVG pronto. Oportunidades mapeadas: (1) FA "set-complete" (operações de linguagem + propriedades + traços ricos), (2) PDA robusto (aceitação múltipla, ND branching, diagnósticos), (3) Regex/CFG com padrão PetitParser (AST unificada, conversões), (4) TM avançado (ND/multi-fita, traces, building blocks), (5) *Unified Modeling Blueprint* (pacotes Dart puros), (6) Interop (.jff, JSON schema, exemplos canônicos), (7) Testes & rollout incremental."

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY (educational value)
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for educators and students, not developers
- 📱 Mobile-first user experience requirements
- 🎯 Educational alignment with formal language theory curriculum

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "automaton editor" without touch gestures), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas for educational tools**:
   - Educational level and learning objectives
   - Mobile interaction patterns (gestures, screen sizes)
   - Algorithm visualization requirements
   - File format compatibility (.jff, JSON, etc.)
   - Performance targets for simulations
   - Accessibility requirements for students
   - Export/import capabilities

---

## Clarifications

### Session 2025-01-27
- Q: What regex operators should be supported in the Regex→AST→Thompson NFA pipeline? → A: Basic operators only (union |, concatenation, Kleene star *, parentheses)
- Q: What is the maximum number of tapes supported for multi-tape Turing machines? → A: Single-tape only (no multi-tape support)
- Q: How should non-deterministic trace folding be implemented? → A: Collapse identical states, show only unique paths
- Q: What should be the scope of the "Examples v1" canonical library? → A: 10-20 examples covering basic FA, PDA, TM, CFG cases
- Q: What types of Turing machine building blocks should be provided? → A: Basic operations only (copy, erase, move, compare)

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a computer science student learning formal language theory, I want to use JFlutter to explore advanced automata concepts through comprehensive language operations, robust PDA simulation, advanced regex parsing, single-tape Turing machines, and seamless interoperability with existing JFLAP files, so that I can gain deep understanding of theoretical computer science concepts with modern mobile-first tools.

### Acceptance Scenarios
1. **Given** I have a finite automaton, **When** I perform language operations (union, intersection, complement, concatenation, star, reverse, shuffle), **Then** I can see step-by-step execution traces with ε-closure diagnostics
2. **Given** I create a pushdown automaton, **When** I configure multiple acceptance modes (final state, empty stack, both), **Then** I can run non-deterministic simulations with trace folding and clear error messages
3. **Given** I write a regular expression, **When** I convert it through AST to Thompson NFA, **Then** I can visualize the complete parsing pipeline with basic operator support
4. **Given** I design a Turing machine, **When** I configure non-deterministic transitions, **Then** I can execute with time-travel debugging and building blocks
5. **Given** I have a JFLAP file, **When** I import it into JFlutter, **Then** I can work with the automaton seamlessly and export back to .jff format

### Edge Cases
- What happens when language operations result in empty or infinite languages?
- How does the system handle non-deterministic branching with exponential state spaces?
- What occurs when importing malformed .jff files or unsupported automaton types?
- How does the system manage memory for large Turing machine simulations with complex tape configurations?
- What happens when regex parsing encounters ambiguous or invalid expressions?

## Requirements *(mandatory)*

### Functional Requirements

#### O1 - Finite Automata Core+ (FA Core+)
- **FR-001**: System MUST support all language operations: union (∪), intersection (∩), complement (¬), difference (\), concatenation (·), Kleene star (*), reverse, and shuffle
- **FR-002**: System MUST provide property checking for emptiness, finiteness, and equivalence with detailed diagnostics
- **FR-003**: System MUST generate rich execution traces with ε-closure visualization and step-by-step diagnostics
- **FR-004**: System MUST maintain stable serialization format for all FA operations and results
- **FR-005**: System MUST support equivalence checking that validates minimization algorithms

#### O2 - Pushdown Automata+ (PDA+)
- **FR-006**: System MUST support three acceptance modes: final state only, empty stack only, and both final state and empty stack
- **FR-007**: System MUST provide deterministic checking with clear diagnostic messages
- **FR-008**: System MUST handle non-deterministic branching with trace folding that collapses identical states and shows only unique paths
- **FR-009**: System MUST generate consistent error messages for PDA simulation failures
- **FR-010**: System MUST support step-by-step PDA execution with stack visualization

#### O3 - Regular Expressions and Context-Free Grammars (Regex/CFG)
- **FR-011**: System MUST implement Regex→AST→Thompson NFA pipeline with basic operators (union |, concatenation, Kleene star *, parentheses)
- **FR-012**: System MUST provide comprehensive CFG toolkit with production rule management
- **FR-013**: System MUST support bidirectional conversions between CFG and PDA (LL and SLR parsing)
- **FR-014**: System MUST implement CFG→CNF conversion with Chomsky Normal Form validation
- **FR-015**: System MUST provide SLR(1) table generation and parser implementation
- **FR-016**: System MUST support CYK algorithm for context-free language recognition
- **FR-017**: System MUST include Brute Force Parser for unrestricted grammars
- **FR-018**: System MUST implement Pumping Lemmas for both regular and context-free languages

#### O4 - Advanced Turing Machines (TM+)
- **FR-019**: System MUST support immutable tape configurations with time-travel execution capability
- **FR-020**: System MUST implement non-deterministic Turing machines with branching visualization
- **FR-021**: System MUST support single-tape Turing machines with comprehensive tape operations
- **FR-022**: System MUST provide building blocks for basic TM operations (copy, erase, move, compare)
- **FR-023**: System MUST generate comprehensive execution traces with configuration snapshots
- **FR-024**: System MUST support basic performance benchmarks for TM simulations

#### O5 - Unified Modeling Blueprint
- **FR-025**: System MUST extract core functionality into pure Dart packages: core_fa, core_pda, core_tm, core_regex, conversions, serializers, viz, playground
- **FR-026**: System MUST maintain clean APIs between packages with clear separation of concerns
- **FR-027**: System MUST provide visualization engine (viz) decoupled from core algorithms
- **FR-028**: System MUST include playground package demonstrating package integration
- **FR-029**: System MUST support monorepo structure with path dependencies

#### O6 - Interoperability and Standards
- **FR-030**: System MUST provide faithful .jff import/export with regression test validation
- **FR-031**: System MUST publish public JSON schemas for FA, PDA, TM, and CFG formats
- **FR-032**: System MUST include canonical example library (Examples v1) with 10-20 examples covering basic FA, PDA, TM, CFG cases
- **FR-033**: System MUST support round-trip testing (model→JSON→model) for all serialization formats
- **FR-034**: System MUST maintain backward compatibility with existing JFlutter automaton files

#### O7 - Quality and Testing
- **FR-035**: System MUST implement regression testing based on canonical examples
- **FR-036**: System MUST include property-based testing where applicable for algorithm validation
- **FR-037**: System MUST provide golden UI tests for all major visualization components
- **FR-038**: System MUST generate execution reports with performance metrics and trace analysis
- **FR-039**: System MUST maintain comprehensive documentation and contribution guidelines

#### UI and User Experience
- **FR-040**: System MUST support zoom functionality with smooth canvas scaling
- **FR-041**: System MUST provide undo/redo capability for all editing operations
- **FR-042**: System MUST support export to SVG and PNG formats with high-quality rendering
- **FR-043**: System MUST support multiple windows for side-by-side automaton comparison
- **FR-044**: System MUST provide UI customization options for personal preferences
- **FR-045**: System MUST implement step-by-step visualization for minimization and non-deterministic trace algorithms
- **FR-046**: System MUST support range notation in transitions (e.g., a-z, 0-9)
- **FR-047**: System MUST provide unified simulators for FA, PDA, TM, and CFG with consistent interface
- **FR-048**: System MUST operate in offline mode with friendly error messages when file system access is unavailable

### Key Entities *(include if feature involves data)*

#### Core Modeling Entities
- **FiniteAutomaton**: Represents deterministic and non-deterministic finite automata with states, transitions, and acceptance criteria
- **PushdownAutomaton**: Extends automaton concept with stack operations and multiple acceptance modes
- **TuringMachine**: Single-tape computational model with immutable configurations and execution traces
- **ContextFreeGrammar**: Production rule system with non-terminals, terminals, and derivation trees
- **RegularExpression**: Pattern matching system with AST representation and operator support

#### Execution and Trace Entities
- **Configuration**: Immutable snapshot of automaton state during execution (states, stack contents, tape contents)
- **Trace**: Complete execution record with time-travel capability and step-by-step analysis
- **ExecutionReport**: Performance metrics, algorithm analysis, and diagnostic information
- **AlgorithmResult**: Output of language operations, conversions, and property checking with proof validation

#### Serialization and Interop Entities
- **AutomatonSchema**: JSON schema definitions for FA, PDA, TM, and CFG serialization formats
- **JFLAPFile**: Import/export format maintaining compatibility with original JFLAP tool
- **ExampleLibrary**: Canonical test cases and educational examples with version control
- **PackageAPI**: Clean interface definitions for core_fa, core_pda, core_tm, core_regex packages

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous  
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---

## Acceptance Criteria Matrix

### O1 - FA Core+ Acceptance Criteria
- [ ] All language operations (∪, ∩, ¬, \, ·, *, reverse, shuffle) implemented with proof validation
- [ ] Property checking (emptiness, finiteness, equivalence) with detailed diagnostics
- [ ] Rich execution traces with ε-closure visualization
- [ ] Stable serialization with round-trip testing
- [ ] Equivalence checking validates minimization algorithms

### O2 - PDA+ Acceptance Criteria  
- [ ] Three acceptance modes (final, empty stack, both) fully functional
- [ ] Non-deterministic branching with trace folding (collapse identical states, show unique paths)
- [ ] Deterministic checking with explanatory error messages
- [ ] Comprehensive test coverage for ND cases
- [ ] Step-by-step execution with stack visualization

### O3 - Regex/CFG Acceptance Criteria
- [ ] Regex→AST→NFA pipeline with basic operator support
- [ ] CFG toolkit with production rule management
- [ ] CFG↔PDA conversions (LL and SLR) validated
- [ ] CNF conversion and SLR(1) parsing working
- [ ] CYK and Brute Force parsers implemented
- [ ] Pumping Lemmas for regular and CFL languages

### O4 - TM+ Acceptance Criteria
- [ ] Single-tape and ND Turing machines with traces
- [ ] Building blocks for basic TM operations (copy, erase, move, compare)
- [ ] Time-travel debugging capability
- [ ] Basic performance benchmarks established
- [ ] Immutable configuration snapshots

### O5 - Unified Modeling Acceptance Criteria
- [ ] Core packages (core_fa, core_pda, core_tm, core_regex) published in monorepo
- [ ] Clean APIs with path dependencies
- [ ] Visualization engine (viz) decoupled from core
- [ ] Playground demonstrating package integration
- [ ] App successfully dependent on packages

### O6 - Interoperability Acceptance Criteria
- [ ] .jff import/export with regression test approval
- [ ] Public JSON schemas for all automaton types
- [ ] Examples v1 canonical library published (10-20 basic examples)
- [ ] Round-trip testing (model→JSON→model) passing
- [ ] Backward compatibility maintained

### O7 - Quality Acceptance Criteria
- [ ] Regression testing pipeline stable
- [ ] Property-based testing implemented
- [ ] Golden UI tests for major components
- [ ] Execution reports with metrics generation
- [ ] Documentation and contribution guidelines complete

---

## Deliverables

### Primary Deliverable
- **specs/003-jflutter-core-expansion/spec.md**: This comprehensive specification document

### Supporting Deliverables
- **API Documentation**: Detailed API specifications for FA, PDA, TM, and CFG packages
- **JSON Schemas**: Public schema definitions for all serialization formats
- **Requirement→Module Matrix**: Mapping of functional requirements to implementation modules
- **Example Library**: Canonical test cases and educational examples (Examples v1 - 10-20 basic examples)
- **Performance Benchmarks**: Baseline metrics for algorithm and simulation performance
- **Regression Test Suite**: Comprehensive test cases based on canonical examples

---

## Non-Functional Requirements

### Architecture and Design
- **Clean Architecture**: Strict separation of Presentation, Core, and Data layers
- **Package Structure**: Pure Dart packages with clear APIs and minimal dependencies
- **Immutability**: Default use of `freezed`/sealed classes for all data models
- **Serialization**: DTOs with `json_serializable` and comprehensive round-trip testing
- **Visualization**: Decoupled rendering engines with independent interaction layers

### Performance and Scalability
- **Canvas Performance**: Maintain 60fps rendering on modern mobile hardware
- **Simulation Performance**: Handle >10k simulation steps with responsive UI
- **Memory Management**: Efficient handling of large automaton state spaces and single-tape configurations
- **Algorithm Complexity**: Optimized implementations for exponential algorithms (ND branching)

### Quality and Testing
- **Test Coverage**: Unit, integration, widget, and golden tests with evolving coverage per module
- **Regression Testing**: Automated testing based on canonical examples
- **Property-Based Testing**: Algorithm validation using property-based testing where applicable
- **Performance Testing**: Benchmarking for critical algorithms and simulations

### Compatibility and Standards
- **Multi-Platform**: Full compatibility across Android, iOS, Web, and Desktop
- **File Format Compatibility**: Faithful .jff import/export with validation
- **Backward Compatibility**: Maintain compatibility with existing JFlutter files
- **Standards Compliance**: Follow formal language theory standards and educational best practices

### Documentation and Maintainability
- **Comprehensive Documentation**: Extensive documentation for all public APIs
- **Educational Value**: Clear learning objectives aligned with formal language theory curriculum
- **Contribution Guidelines**: Detailed guidelines for community contributions
- **Code Quality**: Rigorous static analysis and linting with pre-commit hooks

---

## Design Decisions and Guidelines

### Core Design Principles
- **Immutability by Default**: All data models use `freezed`/sealed classes for thread safety and predictability
- **Trace and Configuration as Common Currency**: Standardized execution recording across all automaton types
- **Typed Alphabets**: Generic `Alphabet<TSymbol>` for type-safe symbol handling
- **Identifiable States**: Unique `StateId` system for state management and referencing
- **Pure Transitions with Guards**: Functional transition definitions with condition checking
- **Determinism Checkers**: Built-in determinism validation for FA, PDA, and TM types

### Serialization Strategy
- **DTO Pattern**: Separate `*.dto.dart` files with `json_serializable` for API boundaries
- **Round-Trip Testing**: Comprehensive model→JSON→model validation for all formats
- **Versioned Schemas**: Public JSON schemas with versioning for backward compatibility
- **Format Validation**: Strict validation of imported files with helpful error messages

### Visualization Architecture
- **Decoupled Rendering**: Independent visualization engines in `viz` package
- **Canvas Layers**: Separate interaction layers independent of core algorithm logic
- **Mobile-First Rendering**: Touch-optimized rendering with gesture support
- **Performance Optimization**: Efficient rendering for large automaton visualizations

### Package Organization
- **Core Packages**: `core_fa`, `core_pda`, `core_tm`, `core_regex` with pure Dart implementations
- **Utility Packages**: `conversions`, `serializers` for algorithm and format handling
- **Visualization Package**: `viz` for decoupled rendering and interaction
- **Integration Package**: `playground` demonstrating package integration patterns