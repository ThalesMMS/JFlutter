# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`  
**Created**: [DATE]  
**Status**: Draft  
**Input**: User description: "$ARGUMENTS"

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Confirm request fits Constitution scope (see Constitution Check)
   → If out of scope: ERROR "Request violates JFlutter constitution"
3. Extract key concepts: actors, automata types, grammar operations, data, constraints
4. For each unclear aspect: mark with [NEEDS CLARIFICATION: question]
5. Fill User Scenarios & Testing (offline, mobile-first focus)
6. Generate Functional Requirements (testable, within syllabus)
7. Identify Key Entities using shared types (Alphabet, State, Transition, etc.) when applicable
8. Run Constitution Check
   → If violations remain: WARN "Spec has constitutional gaps"
9. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT educational value we deliver and WHY it matters for automata theory
- ❌ Avoid implementation details (no Flutter code, packages, APIs)
- 👥 Written for educators and maintainers; ensure alignment with formal language pedagogy
- 🧭 Respect constitution scope, interoperability requirements, and licensing constraints

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- Remove sections that do not apply (no "N/A")

### Constitution Check
Before completing the spec, confirm:
- Feature advances mobile-first, offline learning
- Content fits approved syllabus (automata, grammars, TMs, pumping lemmas, hierarchy)
- No forbidden items (LL/LR parsing, brute-force GI, L-systems, invasive telemetry, mandatory external services)
- Interoperability needs (`.jff`, JSON, SVG, immutable traces) are considered
- References to existing algorithms/data structures link back to `References/`

---

## User Scenarios & Testing *(mandatory)*

### Primary Learning Journey
[Describe the main educational interaction in plain language, emphasizing mobile/offline usage]

### Acceptance Scenarios
1. **Given** [initial state], **When** [user performs automata/grammar action], **Then** [expected outcome supports learning goal]
2. **Given** [initial state], **When** [user reviews simulation trace], **Then** [immutable trace remains consistent and explorable]

### Edge Cases
- How do we handle malformed `.jff`/JSON inputs while preserving sandboxed storage?
- What happens when the canvas reaches >10k simulation steps?
- How does the feature behave offline or when device resources are constrained?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST [deliver specific syllabus-aligned capability]
- **FR-002**: System MUST [respect offline, mobile-first interaction flow]
- **FR-003**: Users MUST be able to [observe immutable traces or conversions]
- **FR-004**: System MUST interoperate with [`.jff`, JSON schema, SVG export as applicable]
- **FR-005**: System MUST validate inputs and surface actionable diagnostics
- **FR-006**: System MUST reference [NAME OF REFERENCE] for algorithm correctness (cite file/path)
- **FR-007**: System MUST document any deviation from reference implementation with rationale

Mark ambiguities explicitly:
- **FR-00X**: System MUST [NEEDS CLARIFICATION: question about automaton size limits, acceptance mode, etc.]

### Key Entities *(include when data involved)*
- **Alphabet**: [Symbols used, link to shared type]
- **State**: [Properties, immutability requirements]
- **Transition**: [Source, destination, symbol stack]
- **Configuration<Trace>**: [Snapshot semantics, replay expectations]

Remove entities that do not apply.

---

## Constitution Check & Compliance Notes *(mandatory)*
- **Scope**: [Explain how feature stays within curriculum]
- **References**: [List relevant `References/` paths]
- **Architecture Fit**: [Describe expected core/data/presentation impact]
- **Quality**: [Planned tests (unit/integration/widget/golden), `flutter analyze`]
- **Performance**: [Expectations for 60fps canvas, >10k steps]
- **Licensing**: [Apache-2.0 compliance, JFLAP asset usage]
- **Interoperability**: [`.jff`/JSON/SVG support, immutable traces]

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [ ] No implementation details (code, packages, architecture decisions)
- [ ] Aligns with JFlutter didactic mission and mobile-first offline mandate
- [ ] Written for stakeholders (educators, maintainers)
- [ ] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [ ] Requirements are testable and constitutionally compliant
- [ ] Success criteria cover performance, interoperability, and trace immutability
- [ ] Scope is clearly bounded and references cited
- [ ] Dependencies/assumptions on reference algorithms documented

---

## Execution Status
*Updated by main() during processing*

- [ ] User description parsed
- [ ] Key concepts extracted
- [ ] Ambiguities marked
- [ ] Constitution Check passed
- [ ] User scenarios defined
- [ ] Requirements generated
- [ ] Entities identified (if applicable)
- [ ] Review checklist passed

---
