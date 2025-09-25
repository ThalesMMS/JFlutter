# Feature Specification: JFlutter Core Expansion and Interoperability

**Feature Branch**: `feature/jflutter-expansion`
**Created**: 2025-09-24
**Status**: Draft
**Input**: User description: "Projeto: JFlutter — Expansão de núcleo + interoperabilidade + gramáticas + TMs..."

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a computer science student or educator, I want to use a comprehensive and mobile-friendly tool to learn and teach automata theory, including advanced features for Finite Automata, Pushdown Automata, Turing Machines, and grammars, with robust import/export capabilities and a clear, well-tested architecture.

### Acceptance Scenarios
1. **Given** a complex regular expression, **When** I input it into JFlutter, **Then** the system generates the corresponding NFA using Thompson's construction and allows me to simulate it.
2. **Given** a non-deterministic PDA, **When** I run a simulation, **Then** the system shows a clear trace of all possible branches (trace folding).
3. **Given** a JFLAP file (`.jff`), **When** I import it, **Then** the corresponding automaton is correctly loaded in JFlutter for simulation and editing.

### Edge Cases
- What happens when an imported `.jff` file contains unsupported features? The system should display a clear warning specifying what is not supported.
- How does the system handle extremely large automata or long simulations? The UI must remain responsive (60fps), and simulations should use techniques like throttling and batched paints.

## Scope Constraints
The application's scope MUST NOT exceed the content of the "Fundamentos Teóricos da Computação" discipline.

### Syllabus
**UNIDADE 1- Nivelamento e Conceitos Básicos (10 ha):**
1.1. Conceitos matemáticos preliminares.
1.2. Alfabetos, sentenças e linguagens.
1.3. Operações com linguagens.
1.4. Expressôes regulares (ER).

**UNIDADE 2 - Autômatos Finitos e Linguagens Regulares (24 ha):**
2.1. Máquinas de estado finito: reconhecedores e transdutores.
2.2. Autômatos finitos (AF).
2.2.1.Autômato finito determinístico (AFD).
2.2.2. Autômato finito não-determinístico (AFN).
2.2.3. Autômato finito não-determ. com transição-lambda (AFN-L).
2.2.4. Conversão de autômatos: AFNL -> AFN -> AFD.
2.3. Linguagens Regulares (LReg).
2.4. Gramáticas lineares e gramáticas regulares (GRJ).
2.5. Conversão de GR em AF / Conversão de AF em GR.
2.6. Conversão de ER em AF / Conversão de AF em ER.
2.7. Propriedades de fechamento das LRegs.
2.8. Lema do bombeamento para LRegs.

**UNIDADE 3 - Autômatos com Pilha e Linguagens Livres de Contexto (20 ha):**
3.1. Introdução.
3.2. Autômatos com pilha (AP).
3.2.1. Autômato com pilha determinístico (APD).
3.2.2. Autômato com pilha não-determinístico (APN).
3.3. Linguagens Livres de Contexto (LLC).
3.4. Gramáticas livres de contexto (GLC).
3.4.1. Árvore de derivação e ambiguidade.
3.4.2. Conversão de GLC em AP / Conversão de AP em GLC.
3.4.3. Introdução à formas normais - Forma Normal de Chomsky.
3.5. Propriedades de fechamento das LLCs.
3.6. Lema do bombeamento para LLCs.

**UNIDADE 4 - Máquinas de Turing e suas Linguagens (14 ha):**
4.1. Introdução.
4.2. Máquidas de Turing (MT).
4.2.1.Máquina de Turing determinística (MTD).
4.2.2 Máquina de Turing não-determinística (MTN).
4.2.3 Variações das máquinas de Turing.
4.3. Linguagens reconhecidas por uma MT.
4.3.1. Linguagens recursivamente enumeráveis (LRE).
4.3.2. Linguagens recursivas (LRec).
4.4. Gramáticas irrestrita (GI).
4.4.1. Equivalência entre GIs e LREs.
4.5. Propriedades de fechamento das LREs e LRecs.
4.6. Autômato linearmente limitado (ALL).
4.6.1. Gramáticas sensíveis ao contexto (GSC).
4.6.2. Linguagens sensíveis ao contexto (LSC).
4.7. Hierarquia de Chomsky.



## Requirements *(mandatory)*

### Functional Requirements
- **FR-O1 (FA Core+):**
    - System MUST implement set-complete language operations for FAs: {∪, ∩, ¬, \, concat, star, reverse, shuffle}.
    - System MUST implement properties for FAs: {emptiness, finiteness, equivalence}.
    - System MUST provide rich simulation traces with ε-closure details.
- **FR-O2 (PDA+):**
    - System MUST support multiple acceptance modes for PDAs: final state, empty stack, or both.
    - System MUST include a determinism checker for PDAs.
    - System MUST visualize non-deterministic branching with trace folding.
- **FR-O3 (Regex/CFG):**
    - System MUST provide a Regex→AST→Thompson NFA conversion pipeline.
    - System MUST include a CFG toolkit for transformations (e.g., to CNF).
    - System MUST support CFG↔PDA conversions.
- **FR-O4 (TM+):**
    - System MUST model Turing Machines with immutable tape and configuration states.
    - System MUST support non-deterministic and multi-tape TM variants.
    - System MUST provide a "building blocks" feature for composing TMs.
    - System MUST allow for "time-travel" debugging of TM executions.
- **FR-O5 (Unified Modeling):**
    - System MUST extract core logic into pure Dart packages (`core_fa`, `core_pda`, etc.).
    - The main application MUST depend on these packages via path references.
- **FR-O6 (Interop):**
    - System MUST support reliable import and export of the `.jff` format.
    - System MUST publish a public `schema.json` for all supported automaton types.
    - System MUST include a versioned library of canonical example files.
- **FR-O7 (Quality):**
    - System MUST use regression tests based on the canonical examples.
    - System MUST generate execution reports.
- **FR-UI:**
    - UI MUST support zoom, undo/redo, and export to SVG/PNG.
    - UI MUST allow for step-by-step algorithm visualization.
    - UI MUST provide a friendly offline mode.

### Non-Functional Requirements
- **NFR-Arch:** System MUST follow Clean Architecture principles.
- **NFR-Test:** System MUST have extensive tests (unit, integration, widget, golden) with evolving coverage minimums.
- **NFR-Perf:** Canvas rendering MUST maintain 60fps on modern hardware.
- **NFR-Doc:** System MUST have extensive documentation for users and contributors.
- **NFR-Platform:** System MUST be compatible with Android, iOS, Web, and Desktop.

### Key Entities *(include if feature involves data)*
- **Automaton:** Represents a generic automaton (FA, PDA, TM).
- **Grammar:** Represents a formal grammar (e.g., CFG).
- **Trace:** An immutable record of a simulation execution.
- **Configuration:** An immutable snapshot of a model's state at a point in time.
- **Alphabet, State, Transition:** Core building blocks of automata.

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [X] No implementation details (languages, frameworks, APIs)
- [X] Focused on user value and business needs
- [X] Written for non-technical stakeholders
- [X] All mandatory sections completed

### Requirement Completeness
- [X] No [NEEDS CLARIFICATION] markers remain
- [X] Requirements are testable and unambiguous
- [X] Success criteria are measurable
- [X] Scope is clearly bounded
- [X] Dependencies and assumptions identified

---

## Execution Status
*Updated by main() during processing*

- [X] User description parsed
- [X] Key concepts extracted
- [X] Ambiguities marked
- [X] User scenarios defined
- [X] Requirements generated
- [X] Entities identified
- [X] Review checklist passed

---
