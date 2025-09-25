
# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Confirm feature fits Constitution scope (see Constitution Check)
   → Capture reference algorithms/files from `References/`
3. Populate the Constitution Check section using current constitution v1.0.0
4. Evaluate Constitution Check section below
   → If violations exist: document in Complexity Tracking with mitigation
   → If non-negotiable guardrails breached: ERROR "Revise proposal to satisfy constitution"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md (focus on reference alignment and constraints)
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Subsequent phases are delegated to other commands.

## Summary
[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context
**Language/Version**: Flutter 3.16+/Dart 3.0+ (or NEEDS CLARIFICATION)  
**Primary Dependencies**: [Riverpod, freezed, json_serializable, etc. or NEEDS CLARIFICATION]  
**Storage**: [Local file sandbox, in-memory, etc. or N/A]  
**Testing**: [flutter test (planned), widget tests, golden tests or NEEDS CLARIFICATION]  
**Target Platform**: [iOS, Android, Web, Desktop specifics or NEEDS CLARIFICATION]  
**Project Type**: mobile-first Flutter (default) unless override justified  
**Performance Goals**: ≥60fps canvas, >10k simulation steps with throttling (confirm specifics)  
**Constraints**: Offline availability, no invasive telemetry, sandboxed file access  
**Scope/Scale**: [Describe automaton count, grammar size, etc. or NEEDS CLARIFICATION]

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Mobile-First Didactic Delivery: Feature preserves offline, hands-on learning flow? ✅/❌
- Curricular Scope Fidelity: Remains within syllabus topics and forbidden list respected? ✅/❌
- Reference-Led Algorithm Port: Mapped to sources in `References/` with deviation notes? ✅/❌
- Clean Architecture & Immutability: Packages, Riverpod state, immutable models respected? ✅/❌
- Quality/Performance/Licensing Assurance: Tests planned, `flutter analyze`, 60fps canvas, Apache-2.0 + JFLAP compliance? ✅/❌
- Scope & Interoperability Standards: `.jff`/JSON/SVG requirements met, immutable traces preserved? ✅/❌
- Architecture & Implementation Requirements: Correct layer placement, deterministic services, DTO strategy? ✅/❌

Document any ❌ with mitigation or exit plan prior to proceeding.

## Project Structure

### Documentation (this feature)
```
specs/[###-feature-name]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 findings (references, constraints)
├── data-model.md        # Phase 1 domain models (immutable)
├── quickstart.md        # Phase 1 manual validation script
├── contracts/           # Phase 1 API/serialization contracts
└── tasks.md             # Phase 2 output (/tasks command)
```

### Source Code (Flutter project)
```
lib/
├── app.dart
├── core/
│   ├── algorithms/
│   ├── entities/
│   ├── models/
│   ├── parsers/
│   ├── repositories/
│   ├── use_cases/
│   └── shared types (Alphabet, State, Transition, Configuration<T>, Trace)
├── data/
│   ├── data_sources/
│   ├── models/ (DTOs, json_serializable)
│   ├── repositories/
│   └── services/
├── presentation/
│   ├── pages/
│   ├── providers/ (Riverpod)
│   ├── theme/
│   └── widgets/
├── injection/
│   └── dependency_injection.dart
└── main.dart

packages/
├── core_fa/
├── core_pda/
├── core_tm/
├── core_regex/
├── conversions/
├── serializers/
├── viz/
└── playground/
```

**Structure Decision**: Default to Flutter mobile-first; introduce additional packages/modules only with documented justification and constitution sign-off.

## Phase 0: Outline & Research
1. Confirm references in `References/` covering targeted algorithms/structures.
2. Resolve NEEDS CLARIFICATION items from Technical Context.
3. Capture performance considerations (60fps, >10k steps) and offline data constraints.
4. Document license implications (Apache-2.0 vs JFLAP assets) for this feature.

**Output**: research.md with resolved unknowns, reference mappings, and constraint notes.

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. Extract immutable domain models and states into `data-model.md` using shared types.
2. Define serialization contracts (`contracts/`) matching `.jff`/JSON/SVG schema expectations.
3. Draft Riverpod state flows and provider responsibilities (keep immutable, side-effect free).
4. Outline manual validation steps in quickstart.md for offline, mobile-first verification.
5. Update agent file via `.specify/scripts/bash/update-agent-context.sh cursor` if technology set changes.

**Output**: data-model.md, /contracts/*, quickstart.md, planned test scaffolding.

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Derive tasks from Phase 1 docs, ensuring tests precede implementations.
- Include validation tasks for `flutter analyze`, widget/golden tests, and performance checks.
- Map each algorithm task to its reference source.

**Ordering Strategy**:
- Setup → Tests (unit/integration/widget/golden) → Core algorithms/services → UI/state → Performance polish.
- Maintain immutable data flow and offline constraints throughout.
- Mark tasks touching disjoint files as [P] for parallel execution.

**Estimated Output**: 20-30 ordered tasks in tasks.md, covering tests, core logic, UI integration, and documentation.

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (follow constitution principles, ensure tests & `flutter analyze`)  
**Phase 5**: Validation (run tests, quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Remediation Plan |
|-----------|------------|------------------|
| [e.g., temporary mutable cache] | [specific constraint] | [timeline to restore immutability] |

## Progress Tracking
*Update during execution flow*

**Phase Status**:
- [ ] Phase 0: Research complete (/plan command)
- [ ] Phase 1: Design complete (/plan command)
- [ ] Phase 2: Task planning approach documented (/plan command)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented (if any)

---
*Based on Constitution v1.0.0 - See `/memory/constitution.md`*
