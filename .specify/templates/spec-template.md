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
- Architecture respects `lib/core`, `lib/data`, `lib/presentation`, `lib/injection` boundaries; no package migrations implied without future amendment

---

## User Scenarios & Testing *(mandatory)*

### Primary Learning Journey
[Describe the main educational interaction in plain language, emphasizing mobile/offline usage]

### Acceptance Scenarios
1. **Given** [initial state], **When** [user performs automata/grammar action], **Then** [expected outcome supports learning goal]
2. **Given** [initial state], **When** [user reviews simulation trace], **Then** [immutable trace remains consistent and explorable]

### Edge Cases
- Como rejeitamos arquivos inválidos preservando sandbox e diagnósticos?
- Como garantimos desempenho ≥60fps em simulações prolongadas (>10k passos)?
- Como mantemos modo jogo/visualizações dentro do escopo curricular?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: Sistema MUST [deliver syllabus-aligned capability]
- **FR-002**: Sistema MUST [respeitar fluxo mobile/offline]
- **FR-003**: Usuários MUST [observar traces imutáveis e diagnósticos]
- **FR-004**: Sistema MUST interagir com `.jff`/JSON/SVG conforme constituição
- **FR-005**: Sistema MUST reutilizar tipos compartilhados (`Alphabet`, `State`, `Transition`, `Configuration<T>`, `Trace`) dentro da arquitetura em `lib/`
- **FR-006**: Sistema MUST validar contra referências (`References/`) e registrar desvios

Use [NEEDS CLARIFICATION: ...] para pontos ambíguos.

### Key Entities *(include when data involved)*
- **Alphabet**: ...
- **State**: ...
- **Transition**: ...
- **Configuration<Trace>**: ...

---

## Constitution Check & Compliance Notes *(mandatory)*
- **Scope**: ...
- **References**: ...
- **Architecture Fit**: Manter lógica em `lib/` (core/data/presentation/injection) com imutabilidade e Riverpod
- **Quality**: Testes planejados (unit/integration/widget/golden/property), `flutter analyze`
- **Performance**: ≥60fps, ≥10k passos, validações offline
- **Licensing**: Apache-2.0 + JFLAP 7.1
- **Interoperability**: `.jff`/JSON/SVG, traces imutáveis

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
- [ ] Success criteria cover performance, interoperability, trace immutability
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
