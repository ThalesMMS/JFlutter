<!--
Sync Impact Report
Version change: 0.0.0 → 1.0.0
Modified principles: None (initial publication)
Added sections: Core Principles; Scope & Interoperability Standards; Architecture & Implementation Requirements; Governance
Removed sections: None
Templates requiring updates: ✅ .specify/templates/plan-template.md; ✅ .specify/templates/spec-template.md; ✅ .specify/templates/tasks-template.md
Follow-up TODOs: None
-->
# JFlutter Constitution

## Core Principles

### Mobile-First Didactic Delivery
- MUST deliver a mobile-first, offline-capable learning experience that mirrors the spirit of JFLAP while embracing modern Flutter UX.
- MUST keep all user flows oriented around hands-on exploration, simulation, and visualization of automata and related formalisms in educational settings.
- Rationale: Ensures the project fulfils its non-negotiable purpose as an accessible didactic environment for theoretical computer science.

### Curricular Scope Fidelity
- MUST restrict features to the approved syllabus: ER/AF (AFD, AFN, AFN-λ) with ER↔AF, GR/GRJ↔AF, language operations {union, intersection, complement, concatenation, Kleene star, reverse}, DFA minimization, language properties {emptiness, finiteness, equivalence}, PDA (APD/APN) with canonical conversions and acceptance modes, CFG→CNF with CYK, pumping lemmas (regular and context-free), deterministic/nondeterministic/multi-tape TMs with immutable traces, grammar inference (GI↔LRE), and the hierarchy visualizations (ALL/GSC/LSC).
- MUST refuse out-of-scope additions (e.g., LL/LR/SLR parsing techniques, brute-force GI parsers, L-systems/turtle graphics, invasive telemetry, mandatory external services).
- Rationale: Guards against scope creep and keeps development focused on the agreed academic curriculum.

### Reference-Led Algorithm Port
- MUST derive every algorithm and data structure from the authoritative repositories in `References/`, documenting any intentional deviations with explicit rationale.
- MUST validate conversions and simulations against the reference implementations before marking features as complete.
- Rationale: Maintains behavioural parity with vetted sources during the migration from legacy JFLAP.

### Clean Architecture and Immutability
- MUST implement clean architecture boundaries using pure Dart packages (`core_fa`, `core_pda`, `core_tm`, `core_regex`, `conversions`, `serializers`, `viz`, `playground`) and shared types (`Alphabet`, `State`, `Transition`, `Configuration<T>`, `Trace`).
- MUST enforce immutability via `freezed`/sealed types, inject state with Riverpod providers, and expose functionality through testable, modular APIs.
- Rationale: Preserves maintainability, testability, and clear separation of concerns across the Flutter application.

### Quality, Performance, and Licensing Assurance
- MUST pair every behavioural change with targeted tests (unit, integration, widget, golden, or property-based as suitable) and run `flutter analyze` before review.
- MUST sustain 60fps canvas rendering, support >10k simulation steps with throttling/batched paints, validate `.jff`/JSON inputs, and maintain offline sandboxed storage with no dynamic `eval` usage.
- MUST keep new code under Apache-2.0, respect the JFLAP 7.1 non-commercial license, and update documentation when license contexts shift.
- Rationale: Guarantees reliability, performance, and legal compliance as the project evolves.

## Scope & Interoperability Standards

- Features MUST include import/export for `.jff`, stable JSON schemas, canonical versioned examples, and SVG export (PNG optional).
- Simulations MUST preserve immutable trace logs to enable deterministic replay and time-travel debugging.
- File validation MUST reject malformed automata/grammar assets with actionable diagnostics.
- Educational content MUST surface the Chomsky hierarchy context (visual and theoretical) aligned with the approved syllabus.

## Architecture & Implementation Requirements

- New functionality MUST reside in the appropriate layer under `lib/` (`core`, `data`, `presentation`) and maintain separation of UI, state, and algorithms.
- Services and repositories MUST remain deterministic and testable, avoiding hidden side effects or network requirements unless explicitly approved for offline caching.
- DTOs MUST be generated with `json_serializable`, and cross-layer contracts MUST use shared immutable models.
- Performance-sensitive canvases MUST employ batching/throttling strategies consistent with the reference implementations.
- Any deviation from clean architecture patterns MUST include a documented justification and a plan to return to compliance.

## Governance

- Amendments require consensus among maintainers, explicit citation of affected principles, and verification that updated guidance remains consistent with `References/`.
- Every feature plan and review MUST include a Constitution Check covering each principle and section, with blockers resolved before implementation proceeds.
- Compliance reviews MUST occur at least once per release cycle, ensuring documentation, tests, and licensing remain aligned with this constitution.
- Semantic versioning (MAJOR.MINOR.PATCH) governs constitution changes; MAJOR increments reflect removed or redefined principles, MINOR adds new principles or sections, PATCH captures clarifications.

**Version**: 1.0.0 | **Ratified**: 2025-09-25 | **Last Amended**: 2025-09-25