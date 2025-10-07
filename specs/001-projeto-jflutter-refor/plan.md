
# Implementation Plan: JFlutter Core Reinforcement Initiative

**Branch**: `001-projeto-jflutter-refor` | **Date**: 2025-09-25 | **Spec**: [`specs/001-projeto-jflutter-refor/spec.md`](./spec.md)
**Input**: Feature specification from [`specs/001-projeto-jflutter-refor/spec.md`](./spec.md)

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
Reforçar o núcleo algorítmico do JFlutter dentro da ementa de Teoria da Computação, cobrindo automatos finitos, PDA, regex/CFG e TMs de fita única, garantindo interoperabilidade `.jff`/JSON/SVG, biblioteca "Examples v1" offline, verificações de ground truth embutidas, e suíte robusta de testes e diagnósticos. **Alta prioridade imediata**: produzir `research.md`, `data-model.md`, `contracts/` e `quickstart.md` para destravar execução alinhada à constituição.

## Technical Context
**Language/Version**: Flutter 3.16+ / Dart 3.0+  
**Primary Dependencies**: Riverpod, freezed, json_serializable, petitparser, collection, flutter_test, golden_toolkit  
**Storage**: Sandbox de arquivos local (app documents) + assets embarcados  
**Testing**: flutter analyze, flutter test (unit/integration/widget/property-based), golden tests, testes de round-trip `.jff`/JSON/SVG  
**Target Platform**: iOS 17+, Android 14+, macOS 15, Web moderno (Chrome/Safari), Desktop (Windows/Linux recentes)  
**Project Type**: Aplicativo Flutter mobile-first (suporte multiplataforma secundário)  
**Performance Goals**: ≥60fps no canvas, ≥10k passos por simulação com throttling/batched paints, validação on-device de referências sem travar UI  
**Constraints**: Offline-first, sem telemetria invasiva, sem serviços externos obrigatórios, respeitar licença Apache-2.0 + JFLAP 7.1, arquitetura atual (sem migração para `packages/*`)  
**Scope/Scale**: Cobrir toda ementa (FA, PDA, CFG, TM single-tape, CYK, pumping lemmas) com biblioteca "Examples v1" contendo dezenas de artefatos canônicos; suportar múltiplos artefatos simultaneamente no sandbox single-user

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Mobile-First Didactic Delivery: Feature preserves offline, hands-on learning flow? ✅
- Curricular Scope Fidelity: Remains within syllabus topics and forbidden list respected? ✅
- Reference-Led Algorithm Port: Mapped to sources in `References/` with deviation notes? ✅ (Refs: `References/automata-main/`, `References/dart-petitparser-examples-main/`, outros jflap)
- Clean Architecture & Immutability: Packages, Riverpod state, immutable models respected? ✅ (manter `lib/core`, `lib/data`, `lib/presentation` com `freezed` e providers)
- Quality/Performance/Licensing Assurance: Tests planned, `flutter analyze`, 60fps canvas, Apache-2.0 + JFLAP compliance? ✅
- Scope & Interoperability Standards: `.jff`/JSON/SVG requirements met, immutable traces preserved? ✅
- Architecture & Implementation Requirements: Correct layer placement, deterministic services, DTO strategy? ✅ (DTOs json_serializable em `lib/data/models`)

## Project Structure

### Documentation (this feature)
```
specs/001-projeto-jflutter-refor/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md (gerado pelo /tasks)
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
│   ├── models/ (*.dto.dart + json_serializable)
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
```

**Structure Decision**: Permanecer na arquitetura atual (sem criação de `packages/*`). Qualquer modularização adicional requer aprovação futura específica.

## Phase 0: Outline & Research
1. Levantar referências específicas em `References/`: Hopcroft minimization, Thompson NFA, CYK, PDA conversions, pumping lemmas, TM traces.
2. Mapear gaps vs. estado atual do repositório (UI boa, funcionalidades fracas) e priorizar reforços.
3. Detalhar requisitos de desempenho e estratégias de throttling/batching para canvas e simulações.
4. Documentar implicações de licença (Apache-2.0 + JFLAP 7.1) e restrições de distribuição de exemplos.
5. **Entregar rapidamente** o documento `research.md` consolidando decisões para habilitar as fases seguintes.

**Output**: [`specs/001-projeto-jflutter-refor/research.md`](./research.md)

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. Modelar entidades imutáveis para FA, PDA, CFG, TM, Regex AST, ExampleArtifact em `data-model.md` alinhadas aos tipos compartilhados.
2. Definir contratos de serialização (`contracts/`) para `.jff` e JSON estáveis, além de esquema de exportação SVG.
3. Planejar fluxos Riverpod (providers imutáveis) para simuladores e trace viewers.
4. Elaborar `quickstart.md` com roteiro offline (import, simular, converter, validar exemplos) e validações de 60fps.
5. Rodar `.specify/scripts/bash/update-agent-context.sh cursor` se novas dependências forem adicionadas.
6. **Tratar a criação de `data-model.md`, `contracts/` e `quickstart.md` como tarefas prioritárias antes de iniciar implementação.**

**Output**: [`specs/001-projeto-jflutter-refor/data-model.md`](./data-model.md), [`specs/001-projeto-jflutter-refor/contracts/`](./contracts/), [`specs/001-projeto-jflutter-refor/quickstart.md`](./quickstart.md)

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Derivar tarefas das entidades/contratos/testes planejados, garantindo ordem TDD.
- Incluir tarefas explícitas para testes determinísticos, goldens, regressões com "Examples v1".
- Mapear cada algoritmo/conversão para sua referência e criar tarefas para validar ground truth on-device.

**Ordering Strategy**:
- Setup → Testes (unit/integration/widget/golden/property) → Núcleo (algoritmos, simuladores, trace) → UI/Providers → Interoperabilidade & desempenho → Documentação/licenças.
- Marcar tarefas independentes com [P]; evitar paralelismo em arquivos compartilhados.

**Estimated Output**: 25±5 tarefas numeradas em `tasks.md` cobrindo testes, implementação, verificações de performance e documentação.

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: /tasks gera tasks.md  
**Phase 4**: Execução das tarefas garantindo constituição  
**Phase 5**: Validação (testes, quickstart, performance)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Remediation Plan |
|-----------|------------|------------------|
| — | — | — |

## Progress Tracking
*Update during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning approach documented (/plan command)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented (if any)

---
*Based on Constitution v1.0.0 - See `/memory/constitution.md`*
