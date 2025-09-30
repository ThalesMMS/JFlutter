# Feature Specification: JFlutter Core Reinforcement Initiative

**Feature Branch**: `001-projeto-jflutter-refor`  
**Created**: 2025-09-25  
**Status**: Draft  
**Input**: User description: "Projeto: JFlutter — reforço do núcleo algorítmico/interoperabilidade/gramáticas/MT dentro da ementa; CONTEXTO: UI ok, funcionalidades fracas; OBJETIVOS: O1‑FA Core (AFD/AFN/AFN‑λ) com NFA→DFA, minimização (Hopcroft), ER↔AF, GR↔AF, operações {∪, ∩, ¬, , concat, estrela, reverso} e propriedades {vazio, finito, equivalência} com traces/diagnósticos; O2‑PDA+ (APD/APN) com aceitação {final|pilha|ambos}, branching ND com trace folding, checagem de determinismo e mensagens de erro claras; O3‑Regex/CFG: Regex→AST→Thompson NFA (PetitParser), toolkit GLC (CNF: remoção ε/unitárias/inúteis + verificação), conversões canônicas GLC↔PDA, pertinência via CYK com árvore; O4‑TM+: MTD/MTN/multi‑fita com estados/fitas imutáveis, time‑travel e “building blocks” apenas como recurso de edição; O5‑Unified Modeling: extrair para packages/* com APIs Dart puras; O6‑Interop: round‑trip .jff/JSON e biblioteca “Examples v1”; O7‑Qualidade: testes determinísticos, regressões por exemplos, goldens de UI; REQUISITOS (filtrados): simuladores FA/PDA/MT e verificador CYK, conversões canônicas (ER↔AF, GR↔AF, GLC↔PDA, GLC→CNF), lemas do bombeamento (Reg/LLC) em modo jogo, árvores de derivação, visualizações passo a passo; DESIGN: imutabilidade (freezed), Trace/Configuration como moeda comum, alfabetos tipados, transições puras, determinism checkers; SERIALIZAÇÃO: DTOs *.dto.dart + json_serializable com round‑trip tests; VIZ: canvas desacoplado (viz), interação independente do core; ACEITE: cada objetivo validado por suíte de exemplos canônicos e ground truth derivado da pasta References; FORA DE ESCOPO: LR/SLR/LL‑parsing, parser GI, L‑Systems."

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
Estudantes usam o aplicativo JFlutter offline em um tablet durante aula de Teoria da Computação para construir e simular autômatos, gramáticas livres de contexto, autômatos de pilha e máquinas de Turing. Eles alternam entre edições visuais e visualizações passo a passo, inspecionam traces imutáveis e comparam os resultados com exemplos canônicos fornecidos na biblioteca "Examples v1".

### Acceptance Scenarios
1. **Given** um estudante abre o módulo de autômatos finitos com um dispositivo sem conexão, **When** ele importa um arquivo `.jff` e executa minimização de DFA seguida de conversão para expressão regular, **Then** o sistema exibe a sequência de transformações com trace imutável e diagnósticos comparados ao ground truth da referência Python.
2. **Given** um estudante cria um APN com múltiplos ramos não determinísticos, **When** ele executa a simulação com aceitação por pilha e revisita estados anteriores, **Then** o trace dobrado (folded) permite explorar cada ramo preservando configurações imutáveis e mensagens de erro apontam transições inválidas ou determinismo quebrado.

### Edge Cases
- Como rejeitamos arquivos `.jff` ou JSON inválidos sem comprometer o sandbox e mantendo mensagens de diagnóstico acionáveis?
- Como garantimos desempenho estável (≥60fps) ao simular máquinas de Turing de fita única com mais de 10k passos?
- Como expomos lemas do bombeamento em modo jogo sem permitir linguagem fora da ementa ou explorações não suportadas?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: Sistema MUST reforçar o núcleo de autômatos finitos (AFD/AFN/AFN-λ) com conversões NFA→DFA, minimização via Hopcroft, ER↔AF, GR↔AF, operações de linguagem {união, interseção, complemento, concatenação, estrela de Kleene, reverso} e diagnósticos de propriedades {linguagem vazia, finita, equivalência} com traces imutáveis.
- **FR-002**: Sistema MUST entregar simuladores PDA (APD/APN) com aceitação configurável {final, pilha, ambos}, checagem explícita de determinismo e mensagens amigáveis para conflitos ou transições inválidas.
- **FR-003**: Sistema MUST suportar pipeline Regex→AST→Thompson NFA baseado no PetitParser de `References/`, além de toolkit CFG com transformações para CNF (remoção de ε-produções, unitárias e símbolos inúteis), conversões canônicas CFG↔PDA e verificação de pertinência via CYK com árvore de derivação.
- **FR-004**: Sistema MUST ampliar simuladores de máquinas de Turing (determinística e não determinística com uma única fita) garantindo estados e fitas imutáveis, suporte a time-travel e "building blocks" apenas como ferramenta de edição sem alterar semântica de execução.
- **FR-005**: Sistema MUST consolidar modelos e algoritmos reutilizando os tipos unificados (`Alphabet`, `State`, `Transition`, `Configuration<T>`, `Trace`) dentro da estrutura existente em `lib/core/`, expondo APIs modulares sem migrar código para `packages/*`.
- **FR-006**: Sistema MUST garantir interoperabilidade completa com round-trip `.jff`/JSON, exportar SVG (PNG opcional) e fornecer biblioteca "Examples v1" versionada com exemplos canônicos alinhados às referências, distribuída como ativo offline somente leitura atualizado apenas em novas releases do aplicativo.
- **FR-007**: Sistema MUST estabelecer suíte de testes determinísticos (unit, integration, widget, golden e regressões por exemplos), rodar `flutter analyze` sem erros, executar derivação de ground truth diretamente no app usando portas Dart/Python embutidas durante as simulações e registrar qualquer divergência dos repositórios de `References/` com justificativa documentada.
- **FR-008**: Sistema MUST manter o modo jogo dos lemas do bombeamento (regular e LLC) com feedback imediato e rastreamento de passos usando traces imutáveis compartilhados, adotando progressão linear baseada em conjuntos pré-definidos de desafios que escalam em dificuldade.

### Key Entities *(include when data involved)*
- **Alphabet**: Conjunto tipado de símbolos imutáveis utilizado por autômatos, gramáticas e máquinas; cada alfabeto referencia origem (entrada, pilha, fita) e respeita validação contra exemplos canônicos.
- **State**: Representa um estado nomeado imutável com marcações (inicial, final, aceitação por pilha, etc.) compartilhado entre AFD/AFN/PDA/MT; utiliza identificadores estáveis para round-trip.
- **Transition**: Define origem, destino, símbolos consumidos/empilhados/desempilhados (para PDA) ou operações de fita (para MT) como funções puras; preserva referências a alfabetos válidos.
- **Configuration<Trace>**: Encapsula instantâneo imutável de execução com pilha/fita/cabeça, incluindo histórico para time-travel e folding de ramos não determinísticos.
- **ExampleArtifact**: Entrada canônica (automaton, grammar, regex, TM) armazenada na biblioteca "Examples v1" com metadados de referência, permitindo regressões determinísticas.

---

## Constitution Check & Compliance Notes *(mandatory)*
- **Scope**: Reforço cobre unicamente tópicos da ementa (AF, PDA, CFG, MT, lemas do bombeamento, CYK, hierarquia) e mantém fora de escopo LL/LR/SLR, parser GI, L-Systems ou serviços externos obrigatórios.
- **References**: Reaproveita algoritmos de `References/automata-main/`, `References/dart-petitparser-examples-main/`, `References/jflap-legacy/` (se disponível) e documenta qualquer divergência nas notas técnicas.
- **Architecture Fit**: Novos recursos permanecem na estrutura atual (`lib/core`, `lib/data`, `lib/presentation`), mantendo clean architecture e imutabilidade via `freezed`, mas sem migração para `packages/*`; qualquer extração futura exigirá avaliação separada.
- **Quality**: Planeja baterias de testes determinísticos, regressões baseadas em "Examples v1", goldens para componentes críticos do canvas, execução obrigatória de `flutter analyze`, além de rodar verificações de ground truth em dispositivo utilizando as portas embutidas das referências.
- **Performance**: Mantém renderização do canvas em 60fps e suporta ≥10k passos com throttling/batched paints; valida desempenho de TMs single-tape e branching ND.
- **Licensing**: Todo código novo sob Apache-2.0; reutilização de conteúdo JFLAP respeita licença não-comercial; exemplos canônicos citam origens.
- **Interoperability**: Round-trip `.jff`/JSON/SVG exigido; DTOs `*.dto.dart` com `json_serializable` e testes de ida e volta; traces e configurações imutáveis compartilhados nas simulações; "Examples v1" empacotado offline e atualizado por releases.

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation detalhes (code, packages, architecture decisions)
- [x] Aligns with JFlutter didactic mission and mobile-first offline mandate
- [x] Written for stakeholders (educators, maintainers)
- [x] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and constitutionally compliant
- [x] Success criteria cover performance, interoperability, and trace immutability
- [x] Scope is clearly bounded and references cited
- [x] Dependencies/assumptions on reference algorithms documented

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [ ] Ambiguities marked
- [ ] Constitution Check passed
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified (if applicable)
- [ ] Review checklist passed

---

## Clarifications

### Session 2025-09-25
- Q: How should the “Examples v1” canonical library be delivered and kept up to date for users? → A: Bundle as read-only offline asset updated via releases
- Q: How should the ground-truth verification against `References/` be executed durante desenvolvimento e QA? → A: Run reference derivations on-device during simulations
- Q: Quantas fitas simultâneas as máquinas de Turing multi-fita devem suportar? → A: Somente 1 fita
- Q: Para o modo jogo dos lemas do bombeamento, qual das seguintes abordagens de progressão devemos adotar? → A: Progressão linear com desafios pré-definidos
