# Tasks: Auditoria de algoritmos vs referências e validação de UI

**Input**: Design documents from `/specs/002-dois-objetivos-principais/`
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
- [ ] T001 Atualizar `/docs/references-alignment.md` com plano de verificação usando `References/automata-main` e `jflutter_js/examples`
- [ ] T002 Validar `pubspec.yaml` para Flutter 3.22+/Dart 3.x; confirmar `freezed`, `json_serializable`, `riverpod` configurados
- [ ] T003 Configurar `build_runner` e lints; garantir `flutter analyze` limpo

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
- [ ] T004 [P] Escrever testes de comparação DFA em `test/unit/dfa_validation_test.dart` contra `References/automata-main` (5 casos: aceitação, rejeição, cadeia vazia, ciclo, complementação)
- [ ] T005 [P] Escrever testes de comparação NFA em `test/unit/nfa_validation_test.dart` contra `References/automata-main` (5 casos: não-determinismo, ε-transições, aceitação, rejeição, beira do alfabeto)
- [ ] T006 [P] Escrever testes de comparação GLC em `test/unit/glc_validation_test.dart` contra `References/automata-main` (5 casos: derivação válida, inválida, CNF/CYK, recursão esquerda, ambiguidades)
- [ ] T007 [P] Escrever testes de comparação TM em `test/unit/tm_validation_test.dart` contra `References/automata-main` (5 casos: aceita, rejeita, laço detectável, transformação, limites de fita)
- [ ] T008 [P] Escrever testes de comparação REGEX em `test/unit/regex_validation_test.dart` contra `References/automata-main` (regex→NFA, FA→regex, equivalência)
- [ ] T009 [P] Escrever testes de comparação PDA em `test/unit/pda_validation_test.dart` contra `References/automata-main` (simulação, conversão GLC→PDA)
- [ ] T010 [P] Escrever testes de comparação Pumping Lemma em `test/unit/pumping_lemma_validation_test.dart` contra `References/automata-main` (prova, disproof, regularidade)
- [ ] T011 [P] Escrever testes de comparação CYK em `test/unit/cyk_validation_test.dart` contra `References/automata-main` (parsing CNF, derivação)
- [ ] T012 [P] Escrever testes de comparação NFA→DFA em `test/unit/nfa_to_dfa_validation_test.dart` contra `References/automata-main` (conversão, equivalência)
- [ ] T013 [P] Escrever testes de comparação DFA Minimization em `test/unit/dfa_minimization_validation_test.dart` contra `References/automata-main` (minimização, equivalência)
- [ ] T014 [P] Escrever testes de comparação Equivalence Checker em `test/unit/equivalence_validation_test.dart` contra `References/automata-main` (DFA≡DFA, NFA≡NFA)
- [ ] T015 [P] Escrever testes de interoperabilidade e round-trip para `.jff`/JSON/SVG em `test/integration/`
- [ ] T016 [P] Escrever testes widget/golden para traços imutáveis e visualizações em `test/widget/`
- [ ] T017 [P] Escrever testes de UX de erro (import inválido → banner inline com retry)

## Phase 3.3: Core Implementation (ONLY after tests fail)
- [ ] T018 [P] Revisar/ajustar algoritmos DFA em `lib/core/algorithms/dfa_operations.dart` conforme desvios identificados
- [ ] T019 [P] Revisar/ajustar algoritmos NFA em `lib/core/algorithms/automaton_simulator.dart` conforme desvios identificados
- [ ] T020 [P] Revisar/ajustar algoritmos GLC em `lib/core/algorithms/grammar_parser.dart` conforme desvios identificados
- [ ] T021 [P] Revisar/ajustar algoritmos TM em `lib/core/algorithms/tm_simulator.dart` conforme desvios identificados
- [ ] T022 [P] Revisar/ajustar algoritmos REGEX em `lib/core/algorithms/regex_to_nfa_converter.dart` e `fa_to_regex_converter.dart` conforme desvios identificados
- [ ] T023 [P] Revisar/ajustar algoritmos PDA em `lib/core/algorithms/pda_simulator.dart` conforme desvios identificados
- [ ] T024 [P] Revisar/ajustar algoritmos Pumping Lemma em `lib/core/algorithms/pumping_lemma_prover.dart` conforme desvios identificados
- [ ] T025 [P] Revisar/ajustar algoritmos CYK em `lib/core/algorithms/cfg/cyk_parser.dart` conforme desvios identificados
- [ ] T026 [P] Revisar/ajustar algoritmos NFA→DFA em `lib/core/algorithms/nfa_to_dfa_converter.dart` conforme desvios identificados
- [ ] T027 [P] Revisar/ajustar algoritmos DFA Minimization em `lib/core/algorithms/dfa_minimizer.dart` conforme desvios identificados
- [ ] T028 [P] Revisar/ajustar algoritmos Equivalence em `lib/core/algorithms/equivalence_checker.dart` conforme desvios identificados
- [ ] T029 [P] Revisar/ajustar algoritmos Grammar→PDA em `lib/core/algorithms/grammar_to_pda_converter.dart` conforme desvios identificados
- [ ] T030 [P] Revisar/ajustar algoritmos Grammar→FSA em `lib/core/algorithms/grammar_to_fsa_converter.dart` conforme desvios identificados
- [ ] T031 [P] Garantir/ajustar modelos imutáveis em `lib/core/models/` e tipos compartilhados
- [ ] T032 Atualizar serviços/repos em `lib/data/` (DTOs `json_serializable`) para import/export
- [ ] T033 Ajustar providers Riverpod em `lib/presentation/providers/` para simulação e relatório
- [ ] T034 Ajustar UI/canvas em `lib/presentation/widgets/` para performance/traços
- [ ] T035 Garantir persistência e navegação de `Trace` (imutável) entre simuladores

## Phase 3.4: Interoperability & Performance
- [ ] T036 Validar import/export `.jff`/JSON e SVG conforme constituição e contratos
- [ ] T037 Implementar throttling/batching para ≥10k passos e confirmar ≥60fps; p95 < 20ms; sem GC > 50ms; memória < 400MB
- [ ] T038 Refinar mensagens de erro e diagnósticos; normalizar diferenças não semânticas (ordem de transições)

## Phase 3.5: QA & Documentation
- [ ] T039 [P] Rodar `flutter analyze`, testes e formatadores
- [ ] T040 [P] Executar quickstart offline e anexar evidências
- [ ] T041 [P] Atualizar `README`/docs; registrar desvios em `docs/reference-deviations.md`

## Dependencies
- Setup antes de testes; testes falhos antes de implementação
- Modelos/serviços antes de UI; interoperabilidade/performance após núcleo
- QA/Documentação após concluir as demais fases

## Parallel Execution Guidance
```
# Testes por tipo de algoritmo (podem rodar em paralelo)
/spec_task run T004  # DFA tests
/spec_task run T005  # NFA tests  
/spec_task run T006  # GLC tests
/spec_task run T007  # TM tests
/spec_task run T008  # REGEX tests
/spec_task run T009  # PDA tests
/spec_task run T010  # Pumping Lemma tests
/spec_task run T011  # CYK tests
/spec_task run T012  # NFA→DFA tests
/spec_task run T013  # DFA Minimization tests
/spec_task run T014  # Equivalence tests

# Implementação por tipo de algoritmo (podem rodar em paralelo)
/spec_task run T018  # DFA algorithms
/spec_task run T019  # NFA algorithms
/spec_task run T020  # GLC algorithms
/spec_task run T021  # TM algorithms
/spec_task run T022  # REGEX algorithms
/spec_task run T023  # PDA algorithms
/spec_task run T024  # Pumping Lemma algorithms
/spec_task run T025  # CYK algorithms
/spec_task run T026  # NFA→DFA algorithms
/spec_task run T027  # DFA Minimization algorithms
/spec_task run T028  # Equivalence algorithms
/spec_task run T029  # Grammar→PDA algorithms
/spec_task run T030  # Grammar→FSA algorithms
```
Assegure que tarefas [P] não compartilham arquivos ou estados mutáveis.

## Notes
- Desenvolvimento restrito à arquitetura existente (`lib/core`, `lib/data`, `lib/presentation`, `lib/injection`)
- Registre qualquer desvio de referência imediatamente
- Commits pequenos seguindo TDD e `flutter analyze`
