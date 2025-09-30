# Feature Specification: Auditoria de algoritmos vs referências e validação de UI

**Feature Branch**: `002-dois-objetivos-principais`  
**Created**: 2025-09-29  
**Status**: Draft  
**Input**: User description: "Dois objetivos principais: conferir implementação dos algoritmos em relação às referências (ver pasta References) e garantir que a UI está funcionando"

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

## Clarifications
### Session 2025-09-29
- Q: Canonical test set and sources for algorithm validation? → A: Use `References/automata-main` as primary; include `jflutter_js/examples`.
- Q: Mínimo de casos canônicos por tipo de algoritmo? → A: 5 por tipo cobrindo aceitação/rejeição e bordas.
 - Q: Comportamento de UI para importações inválidas? → A: Banner de erro inline com retry; permanecer na mesma tela.
 - Q: UI performance metrics além de FPS? → A: p95 < 20ms; sem GC > 50ms; memória < 400MB.
 - Q: Escopo de confiabilidade para esta feature? → A: Best-effort; recuperar erros comuns; sem uptime target.

## User Scenarios & Testing *(mandatory)*

### Primary Learning Journey
Estudante/docente abre o app offline, carrega/cria autômatos/gramáticas/TMs, executa simulações e compara resultados com as implementações de referência mantidas em `References/`. Mantendo foco mobile-first, a pessoa navega pelas páginas principais (home, criação/edição, simulação, visualização de traços) verificando que a UI responde e renderiza corretamente, enquanto o sistema oferece um relatório de conformidade algoritmo‑a‑algoritmo.

### Acceptance Scenarios
1. **Given** um DFA/NFA/GRAMMAR/TM válido da biblioteca de exemplos, **When** o usuário executar a simulação no app, **Then** o resultado deve coincidir com a saída da referência correspondente em `References/` e registrar “conforme”.
2. **Given** um caso que diverge da referência, **When** a simulação terminar, **Then** o sistema deve registrar “desvio”, detalhar diferença (estado final, palavra aceita/rejeitada, passos) e apontar arquivos/linhas da referência.
3. **Given** o app iniciado offline, **When** o usuário navegar entre as páginas principais, **Then** a UI deve permanecer funcional, com FPS estável e sem erros de runtime.
4. **Given** um traço gerado por simulação, **When** o usuário revisá‑lo, **Then** o traço deve ser imutável, navegável passo‑a‑passo e exportável (JSON/SVG se aplicável).
5. **Given** um arquivo `.jff`/JSON inválido, **When** o usuário tentar importar, **Then** o sistema deve rejeitar o arquivo com diagnóstico claro mantendo a sandbox.

### Edge Cases
- Importações inválidas: rejeitar preservando sandbox e diagnósticos, exibindo banner de erro inline com ação de tentar novamente; permanecer na mesma tela.
- Como garantimos desempenho ≥60fps em simulações prolongadas (>10k passos)?
- Como mantemos modo jogo/visualizações dentro do escopo curricular?
- Diferenças legítimas de implementação (ex.: ordenação de transições) não devem sinalizar falso negativo; normalizar antes de comparar.
- Variações de plataforma (fontes/rasterização) não podem afetar a verificação de UI e devem ser abstraídas nos checks.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: Validar resultados de DFAs/NFAs/GLCs/TMs usando `References/automata-main` como fonte primária e exemplos em `jflutter_js/examples`, cobrindo um conjunto de casos canônicos.
- **FR-002**: Registrar relatório de conformidade por algoritmo com lista de cenários, “conforme/desvio” e diffs relevantes.
- **FR-003**: Garantir funcionamento offline de ponta a ponta para criação, simulação e revisão de traços.
- **FR-004**: Assegurar que traços de simulação sejam imutáveis, exploráveis e persistíveis.
- **FR-005**: Suportar importação/exportação `.jff`/JSON/SVG onde aplicável, respeitando interoperabilidade definida.
- **FR-006**: Reutilizar tipos compartilhados (`Alphabet`, `State`, `Transition`, `Configuration<T>`, `Trace`) nas camadas `lib/core`, `lib/data`, `lib/presentation`, `lib/injection`.
- **FR-007**: Exibir diagnósticos claros para entradas inválidas, sem quebrar a sandbox, via banner de erro inline com ação de tentar novamente nas importações.
- **FR-008**: Manter desempenho estável (alvo ≥60fps) durante simulações e visualizações.
- **FR-009**: Integrar checagem via `flutter analyze` sem erros antes de concluir a feature.
- **FR-010**: Documentar e versionar desvios das referências em `docs/reference-deviations.md`.
- **FR-011**: Cobrir no mínimo 5 casos canônicos por tipo (DFA, NFA, GLC, TM), incluindo aceitação/rejeição e bordas.

Use [NEEDS CLARIFICATION: ...] para pontos ambíguos.

### Key Entities *(include when data involved)*
- **Alphabet**: conjunto de símbolos de entrada.
- **State**: identificadores e marcações (inicial, finais).
- **Transition**: relação de transição entre estados com rótulos.
- **Configuration<Trace>**: configuração instantânea durante simulação.
- **Trace**: sequência imutável de configurações e ações.
- **Automaton/Grammar/TuringMachine**: estruturas principais a validar.
- **SimulationResult**: aceita/rejeita, passos executados, estado final.
- **ValidationReport**: por algoritmo, lista de casos, status e diffs.

---

## Constitution Check & Compliance Notes *(mandatory)*
- **Scope**: avanço de aprendizado offline sobre autômatos, gramáticas e TMs; sem itens vetados; foco mobile-first.
- **References**: fonte primária `References/automata-main/`; complementar com `jflutter_js/examples` e, quando necessário, `References/AutomataTheory-master/`, `References/nfa_2_dfa-main/`, `References/turing-machine-generator-main/`. Registrar divergências em `docs/reference-deviations.md`.
- **Architecture Fit**: Manter lógica em `lib/` (core/data/presentation/injection) com imutabilidade e Riverpod
- **Quality**: Testes planejados (unit/integration/widget/golden/property), `flutter analyze`
 - **Performance**: ≥60fps, ≥10k passos, validações offline; p95 < 20ms frame time; sem pausas de GC > 50ms; memória < 400MB
 - **Reliability**: best-effort local; recuperar erros comuns; sem alvo de uptime
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
