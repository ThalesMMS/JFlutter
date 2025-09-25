
# Implementation Plan: JFlutter Core Expansion and Interoperability

**Branch**: `003-jflutter-core-expansion` | **Date**: 2025-01-27 | **Spec**: `/specs/003-jflutter-core-expansion/spec.md`
**Input**: Feature specification from `/specs/003-jflutter-core-expansion/spec.md`

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
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
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
Comprehensive expansion of JFlutter core functionality including complete finite automata language operations, robust pushdown automata simulation, advanced regex/CFG processing, single-tape Turing machine capabilities, unified modeling architecture with pure Dart packages, and seamless interoperability with JFLAP files. Technical approach focuses on clean architecture with progressive package extraction, immutable data models, comprehensive testing, and mobile-first educational UX.

## Technical Context
**Language/Version**: Flutter 3.16+ / Dart 3.0+  
**Primary Dependencies**: Riverpod (state management), freezed (immutability), json_serializable (serialization), very_good_analysis (linting), PetitParser (regex parsing)  
**Storage**: Local file system (.jff import/export), JSON serialization, in-memory automaton models  
**Testing**: flutter test (unit/integration/widget), golden tests, property-based testing, regression testing  
**Target Platform**: Android, iOS, Web, Desktop (Flutter multi-platform)  
**Project Type**: mobile (Flutter app with clean architecture)  
**Performance Goals**: 60fps canvas rendering, >10k simulation steps responsive, <200ms algorithm execution  
**Constraints**: Offline-capable, mobile-first UX, educational focus, no backend dependencies  
**Scale/Scope**: 10-20 canonical examples, 48 functional requirements, 7 core packages, comprehensive automata coverage

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Educational Focus Compliance
- [x] Feature aligns with formal language theory curriculum
- [x] Mobile-first UX design approach
- [x] No backend dependencies required
- [x] Educational value clearly defined

### Technical Standards Compliance
- [x] Flutter 3.16+ / Dart 3.0+ compatibility
- [x] Clean architecture (Presentation/Core/Data) structure
- [x] Riverpod state management approach
- [x] Immutable models with freezed/sealed classes
- [x] JSON serialization for DTOs

### Quality & Testing Compliance
- [x] Comprehensive test coverage planned (unit, integration, widget, golden)
- [x] Static analysis and linting configured
- [x] Performance budgets defined (>60fps, >10k steps responsive)
- [x] Deterministic algorithm testing approach
- [x] Immutable trace recording capability

### Mobile & Accessibility Compliance
- [x] Touch gesture support (pinch, pan, tap)
- [x] Material 3 design principles
- [x] Collapsible panels for space efficiency
- [x] Overflow prevention for small screens
- [x] Basic accessibility (labels, contrast)

### Security & File Handling Compliance
- [x] Sandboxed file operations
- [x] Input validation for external files
- [x] No dynamic code execution
- [x] Path traversal prevention

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure]
```

**Structure Decision**: Option 3 (Mobile + API) - Flutter mobile app with clean architecture packages

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh cursor`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract endpoint → contract test task [P]
- Each entity from data model → model creation task [P] 
- Each user story from quickstart → integration test task
- Package extraction tasks for core_fa, core_pda, core_tm, core_regex
- Algorithm implementation tasks for language operations
- UI component tasks for mobile-first design
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Models → Algorithms → Services → UI
- Package order: core entities → core algorithms → conversions → serializers → viz → playground
- Mark [P] for parallel execution (independent files/packages)

**Estimated Output**: 35-40 numbered, ordered tasks in tasks.md covering:
- 8 contract test tasks (one per API endpoint)
- 15 entity model tasks (core entities + execution/trace entities)
- 12 algorithm implementation tasks (language operations, conversions, property checking)
- 8 package extraction tasks (core packages + utilities)
- 5 integration test tasks (user scenarios from quickstart)

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
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
