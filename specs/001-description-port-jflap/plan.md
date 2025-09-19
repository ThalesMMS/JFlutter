# Implementation Plan: Port JFLAP to Flutter as JFlutter

**Branch**: `001-description-port-jflap` | **Date**: 2024-12-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-description-port-jflap/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, or `GEMINI.md` for Gemini CLI).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Port JFLAP desktop application to Flutter mobile app (JFlutter) with fully mobile-optimized layout maintaining same section divisions. Implement comprehensive formal language theory functionality including grammar-automaton conversions (LL, LR, SLR), pumping lemma games, L-systems, Turing machines with building blocks, and advanced parsing algorithms (CYK, brute force). Prioritize basic functions first, then advanced features with touch-optimized user interactions.

## Technical Context
**Language/Version**: Dart 3.0+, Flutter 3.16+  
**Primary Dependencies**: Flutter SDK, flutter_gesture_detector, path_provider, shared_preferences, vector_math, collection  
**Storage**: Local file system (JSON/XML), SharedPreferences for settings, JFLAP file format compatibility  
**Testing**: Flutter test framework, widget tests, integration tests, performance tests  
**Target Platform**: iOS 12+, Android API 21+ (mobile-first, responsive design)  
**Project Type**: mobile (Flutter app with local storage)  
**Performance Goals**: 60fps UI, <500ms algorithm execution for automata <50 states, <2s for <100 states, <5s for <200 states  
**Constraints**: Offline operation, <150MB app size, touch-optimized (44dp minimum touch targets), memory efficient for mobile devices  
**Scale/Scope**: Single-user educational app, support automata with up to 200 states/nodes, 10MB file size limit

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Mobile App Constraints
- ✅ Single Flutter project (no multiple apps)
- ✅ Local storage only (no backend complexity)
- ✅ Focus on core algorithms first (avoid feature creep)
- ✅ Touch-optimized UI (mobile-specific requirements)

### Complexity Justification
- ✅ Flutter framework handles cross-platform complexity
- ✅ Local file storage reduces infrastructure complexity
- ✅ Prioritizing basic functions prevents overwhelming scope

## Project Structure

### Documentation (this feature)
```
specs/001-description-port-jflap/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
lib/
├── core/                # Core algorithms and data structures
│   ├── automata/        # FSA, PDA, TM implementations
│   ├── grammar/         # Grammar parsing and transformations
│   ├── algorithms/      # NFA→DFA, minimization, parsing
│   └── models/          # Data models and entities
├── presentation/        # UI layer
│   ├── pages/           # Main screens (same sections as JFLAP)
│   ├── widgets/         # Reusable UI components
│   └── providers/       # State management
├── data/                # Data layer
│   ├── repositories/    # Data access
│   └── data_sources/    # File I/O, persistence
└── injection/           # Dependency injection

test/
├── unit/                # Algorithm and model tests
├── widget/              # UI component tests
└── integration/         # End-to-end tests
```

**Structure Decision**: Single Flutter project with clean architecture layers

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - Mobile accessibility requirements → research Flutter accessibility best practices
   - Performance limits for large automata → research mobile memory constraints
   - File format compatibility → research JFLAP file formats and parsing

2. **Generate and dispatch research agents**:
   ```
   Task: "Research Flutter accessibility features for educational apps"
   Task: "Research mobile performance optimization for graph algorithms"
   Task: "Research JFLAP file format specifications and parsing libraries"
   Task: "Research touch gesture patterns for graph editing on mobile"
   Task: "Research Flutter state management patterns for complex UI"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Automaton, State, Transition, Grammar, Production entities
   - Mobile-specific properties (touch bounds, zoom levels)
   - Validation rules from requirements

2. **Generate API contracts** from functional requirements:
   - Local file operations (save/load automata)
   - Algorithm execution interfaces
   - Touch interaction contracts
   - Output to `/contracts/`

3. **Generate contract tests** from contracts:
   - File I/O tests
   - Algorithm correctness tests
   - Touch interaction tests

4. **Extract test scenarios** from user stories:
   - Create FSA → integration test
   - Convert NFA to DFA → algorithm test
   - Save/load automaton → file I/O test

5. **Update agent file incrementally**:
   - Run `.specify/scripts/bash/update-agent-context.sh cursor`
   - Add Flutter/Dart specific context
   - Update mobile development patterns

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract → contract test task [P]
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Models before algorithms before UI
- Mobile priority: Basic FSA operations first, then PDA/TM
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 30-35 numbered, ordered tasks in tasks.md covering:
1. Core data models (Automaton, State, Transition)
2. Basic FSA algorithms (NFA→DFA, minimization)
3. Mobile-optimized UI components
4. Touch interaction handling
5. File I/O operations
6. Advanced features (PDA, TM, grammars)

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Multiple automaton types | Educational completeness | Students need to learn all types, not just FSA |
| Complex algorithms | Academic accuracy | Incorrect algorithms would mislead students |
| Touch gesture system | Mobile usability | Desktop mouse interactions don't work on mobile |

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [ ] Phase 0: Research complete (/plan command)
- [ ] Phase 1: Design complete (/plan command)
- [ ] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*