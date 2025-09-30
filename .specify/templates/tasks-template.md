# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/, quickstart.md

## Execution Flow (main)
```
1. Load plan.md; if missing: ERROR "No implementation plan found"
   → Extract constitution compliance notes, reference mappings, architecture targets
2. Load optional design documents:
   → data-model.md: Immutable entities → model/service tasks
   → contracts/: Serialization schemas → validation & export tasks
   → research.md: Reference alignment → correctness tasks
   → quickstart.md: Manual validation → QA tasks
3. Generate tasks by category respecting constitution:
   → Setup: dependencies, analyzers, reference validation plan
   → Tests: unit, integration, widget, golden, property-based (fail first)
   → Core: algorithms, conversions, immutable models within `lib/core`
   → State/UI: Riverpod providers, Flutter widgets in `lib/presentation`
   → Interoperability: .jff/JSON/SVG import-export, trace persistence
   → Performance & QA: 60fps canvas checks, >10k step throttling, offline validation
4. Apply task rules:
   → Tests precede implementation (TDD)
   → Reference parity tasks before UI polish
   → Each task cites target file path(s) under `lib/`
   → Respect layered architecture boundaries (core/data/presentation/injection)
5. Enforce constitution compliance gates:
   → If scope violation detected: ERROR "Task plan violates constitution"
6. Number tasks sequentially (T001, T002...)
7. Generate dependency graph and parallel task guidance (respect immutable data constraints)
8. Validate checklists before returning
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no shared state)
- Always include precise file paths and package references within `lib/`

## Phase 3.1: Setup
- [ ] T001 Confirm cobertura de referências em `References/` e registrar plano de verificação em `/docs/references-alignment.md`
- [ ] T002 Atualizar `pubspec.yaml` com dependências necessárias e garantir compatibilidade com ferramentas (`flutter analyze`, `freezed`, `json_serializable`)
- [ ] T003 Configurar scripts e tooling (`build_runner`, lints) coerentes com a arquitetura em `lib/`

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
- [ ] T004 [P] Testes unit/integration falhos cobrindo algoritmos e simuladores em `lib/core/`
- [ ] T005 [P] Testes de interoperabilidade e round-trip `.jff`/JSON/SVG`
- [ ] T006 [P] Testes widget/golden falhos para visualizações e traces
- [ ] T007 [P] Testes para modos educacionais (pumping lemma, CYK, etc.)

## Phase 3.3: Core Implementation (ONLY after tests fail)
- [ ] T008 [P] Implementar algoritmos/conversões em `lib/core/algorithms/`
- [ ] T009 [P] Implementar modelos/entidades imutáveis em `lib/core/models/`
- [ ] T010 Atualizar serviços e repositórios em `lib/data/` seguindo DTOs `json_serializable`
- [ ] T011 Atualizar providers e estado Riverpod em `lib/presentation/providers/`
- [ ] T012 Atualizar UI/canvas/visualizações em `lib/presentation/widgets/`
- [ ] T013 Garantir trace/replay imutáveis compartilhados entre simuladores

## Phase 3.4: Interoperability & Performance
- [ ] T014 Validar import/export `.jff`/JSON e SVG conforme constituição
- [ ] T015 Assegurar desempenho ≥60fps e ≥10k passos com throttling/batching
- [ ] T016 Revisar mensagens de erro, validações e diagnósticos amigáveis

## Phase 3.5: QA & Documentation
- [ ] T017 [P] Rodar `flutter analyze`, testes completos e formatadores
- [ ] T018 [P] Executar quickstart offline e documentar evidências
- [ ] T019 [P] Atualizar `README`/docs com novos recursos e restrições
- [ ] T020 Documentar desvios/referências em `/docs/reference-deviations.md`

## Dependencies
- Setup antes de testes; testes falhos antes de implementação
- Core depende de modelos/testes; interoperabilidade/performance após núcleo
- QA/Documentação após concluir as demais fases

## Parallel Execution Guidance
```
/spec_task run T004
/spec_task run T005
/spec_task run T006
```
Assegure que tarefas [P] não compartilham arquivos ou estados mutáveis.

## Notes
- Desenvolvimento restrito à arquitetura existente (`lib/core`, `lib/data`, `lib/presentation`, `lib/injection`)
- Registre qualquer desvio de referência imediatamente
- Commits pequenos seguindo TDD e `flutter analyze`