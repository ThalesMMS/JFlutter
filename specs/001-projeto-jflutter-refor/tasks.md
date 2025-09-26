# Tasks: JFlutter Core Reinforcement Initiative

**Input**: Design documents from `/specs/001-projeto-jflutter-refor/`
**Prerequisites**: plan.md (required)

## Execution Flow (main)
```
1. Load plan.md; if missing: ERROR "No implementation plan found"
   → Extract constitution compliance notes, reference mappings, architecture targets
2. Load optional design documents (none available yet)
3. Generate tasks respecting constitution guardrails and TDD order
4. Validate task ordering and dependencies
5. Return actionable tasks.md ready for execution
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no shared state)
- Always include precise file paths and cite reference sources when relevant

## Phase 3.1: Setup
- [X] T001 Map algoritmos/estruturas para referências oficiais (`References/automata-main`, `References/dart-petitparser-examples-main`, etc.) e registrar plano de validação em `/docs/references-alignment.md`
- [X] T002 Atualizar `pubspec.yaml` com dependências necessárias (petitparser, freezed, json_serializable, golden_toolkit) e garantir versões compatíveis com Flutter 3.16+
- [X] T003 Configurar `build_runner`/`freezed`/`json_serializable` e scripts auxiliares em `tool/` para geração de código consistente

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
- [X] T004 [P] Criar testes unitários falhos para conversões e operações de AF (`test/unit/core/automata/fa_algorithms_test.dart`) cobrindo NFA→DFA, Hopcroft, operações de linguagem e diagnósticos de propriedades
- [X] T005 [P] Criar testes unitários falhos para simulador PDA (`test/unit/core/pda/pda_simulator_test.dart`) com aceitação {final, pilha, ambos} e verificação de determinismo
- [X] T006 [P] Criar testes unitários falhos para pipeline Regex→AST→Thompson NFA (`test/unit/core/regex/regex_pipeline_test.dart`) validando equivalência com referências
- [X] T007 [P] Criar testes unitários falhos para toolkit CFG/CYK (`test/unit/core/cfg/cfg_toolkit_test.dart`) cobrindo CNF (ε/unitária/inútil) e árvores CYK
- [X] T008 [P] Criar testes unitários falhos para TM single-tape com traces imutáveis (`test/unit/core/tm/tm_simulator_test.dart`) incluindo time-travel e building blocks de edição
- [X] T009 [P] Criar testes de regressão falhos para biblioteca "Examples v1" e round-trip `.jff`/JSON/SVG (`test/integration/io/examples_roundtrip_test.dart`)
- [X] T010 [P] Criar testes widget/golden falhos para visualizações (canvas FA/PDA/MT, árvores CYK, jogo do bombeamento) em `test/widget/presentation/visualizations_test.dart`
- [X] T011 [P] Criar testes de modo jogo dos lemas do bombeamento (`test/unit/presentation/pumping_lemma_game_test.dart`) garantindo progressão linear e feedback imediato

## Phase 3.3: Core Implementation (ONLY after tests fail)
- [X] T012 Implementar conversões e operações de AF em `lib/core/algorithms/automata/fa_algorithms.dart` com traces/diagnósticos e validações contra referências
- [X] T013 Implementar simulador FA e painel de traces em `lib/core/algorithms/automata/fa_simulator.dart` e `lib/presentation/providers/fa_trace_provider.dart`
- [X] T014 Implementar simulador PDA imutável com folding ND em `lib/core/algorithms/pda/pda_simulator.dart` e provedores em `lib/presentation/providers/pda_simulation_provider.dart`
- [X] T015 Implementar pipeline Regex→AST→Thompson NFA usando petitparser (`lib/core/regex/regex_pipeline.dart`) com pontos de extensão para diagnósticos
- [X] T015.1 Refatorar T012 (FA façade/ops/diagnósticos) alinhando referências: validar alfabetos nas operações, garantir complemento em DFA completo, revisar `isEmpty/isFinite` conforme abordagem de reachability+longest path e documentar contratos
- [X] T015.2 Refatorar T013 (simulador FA/traces) para alinhar semântica com `DFA.read_input_stepwise`: mensagens/erros consistentes, escolha explícita NFA vs DFA, cobertura de rejeição por ausência de transição
- [X] T015.3 Refatorar T014 (PDA simulador) para suportar NPDA: branching/ε-movimentos sobre pilha, modos de aceitação {final, pilha vazia, ambos} e limites de busca; manter DPDA como caso especial
- [X] T015.4 Refatorar T015 (Regex pipeline) consolidando com `algorithms/regex_to_nfa_converter.dart` (evitar duplicidade), generalizar '.' para alfabeto do contexto e ampliar escapes/gramática conforme referências
- [ ] T016 Implementar toolkit CFG (normalização CNF, remoções, verificações) e conversões CFG↔PDA em `lib/core/algorithms/cfg/cfg_toolkit.dart` — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T017 Implementar verificador CYK com geração de árvore de derivação em `lib/core/algorithms/cfg/cyk_parser.dart` — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T018 Implementar simulador de TM determinística/não determinística single-tape com time-travel e building blocks em `lib/core/algorithms/tm/tm_simulator.dart` — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T019 Atualizar módulo visual de traces e folding (FA/PDA/TM) em `lib/presentation/widgets/trace_viewers/` — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T020 Implementar modo jogo dos lemas do bombeamento com progressão linear em `lib/presentation/widgets/pumping_lemma_game/` — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T021 Implementar biblioteca offline "Examples v1" (carregamento via assets) em `lib/data/data_sources/examples_asset_data_source.dart` e serviço em `lib/data/services/examples_service.dart` — Obs.: antes de implementar, estudar as implementações em `References/`


## Phase 3.4: Interoperability & Performance
- [ ] T023 Implementar DTOs `*.dto.dart` e serializadores `.jff`/JSON em `lib/data/models/` com testes de ida e volta — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T024 Implementar exportação SVG das visualizações em `lib/presentation/widgets/export/svg_exporter.dart` — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T025 Otimizar canvas e simuladores para ≥60fps e ≥10k passos (throttling/batching) em `lib/presentation/widgets/canvas/` e `lib/core/algorithms/common/throttling.dart` — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T026 Garantir mensagens de erro claras e saneamento de input (FA/PDA/CFG/TM) em `lib/core/validators/` — Obs.: antes de implementar, estudar as implementações em `References/`

## Phase 3.5: QA & Documentation
- [ ] T027 [P] Rodar `flutter analyze`, `dart format`, e toda suíte de testes garantindo determinismo — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T028 [P] Documentar quickstart offline em `/Users/thales/Documents/GitHub/jflutter/specs/001-projeto-jflutter-refor/quickstart.md` e atualizar README com "Examples v1" e novo escopo — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T029 [P] Registrar resultados de regressão e desvios das referências em `/docs/reference-deviations.md` — Obs.: antes de implementar, estudar as implementações em `References/`
- [ ] T030 Validar manualmente cenários do quickstart (import `.jff`, simulações PDA/TM, jogo do bombeamento) e capturar evidências para revisão — Obs.: antes de implementar, estudar as implementações em `References/`

## Dependencies
- T001 → T002 → T003 (Setup antes dos testes)
- T004-T011 devem falhar antes de executar T012-T021
 - T012 e T013 dependem de T004; T014 depende de T005; T015 depende de T006; T016-T017 dependem de T007; T018 depende de T008; T019-T020 dependem de T010-T011; T021 depende de T009
- T023-T026 dependem dos núcleos correspondentes (T012-T021)
- T027-T030 dependem de todas as fases anteriores

## Parallel Execution Guidance
```
# Exemplo de execução paralela (após Setup):
/spec_task run T004
/spec_task run T005
/spec_task run T006
/spec_task run T009
```
Certifique-se de que tarefas marcadas [P] manipulam arquivos distintos.

## Notes
- Manter todas as implementações dentro de `lib/` (sem criar novos packages)
- Qualquer divergência das referências deve ser documentada imediatamente
- Commits pequenos por tarefa, garantindo TDD e análise estática limpa
