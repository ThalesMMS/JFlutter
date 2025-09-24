# references_index.md
Guia consolidado de referências para **JFlutter** — estruturas, algoritmos e APIs para **Autômatos**, **Gramáticas**, **Expressões Regulares** e **Máquinas de Turing**.

> Este índice agrega e organiza o material de referência coletado (Dart/Flutter e Python) para acelerar a implementação das funcionalidades do JFlutter. A curadoria privilegia **lógica pura** (core reutilizável), **algoritmos canônicos** e **padrões de modelagem** que facilitam simulação passo‑a‑passo e visualização.

---

## Sumário
1. [Panorama das referências](#panorama-das-referências)
2. [Autômatos Finitos — DFA/NFA](#autômatos-finitos--dfanfa)
3. [Autômatos de Pilha — PDA](#autômatos-de-pilha--pda)
4. [Expressões Regulares e Gramáticas (PetitParser)](#expressões-regulares-e-gramáticas-petitparser)
5. [Máquinas de Turing](#máquinas-de-turing)
6. [Modelagem unificada de estruturas no JFlutter](#modelagem-unificada-de-estruturas-no-jflutter)
7. [Interoperabilidade: serialização, import/export e formatos](#interoperabilidade-serialização-importexport-e-formatos)
8. [Algoritmos essenciais por categoria](#algoritmos-essenciais-por-categoria)
9. [Plano incremental de implementação no JFlutter](#plano-incremental-de-implementação-no-jflutter)
10. [Matriz “feature → referência(s)”](#matriz-feature--referências)

---

## Panorama das referências

- **Automata (Caleb Evans, Python)** — *automata-main*: biblioteca completa com **FA (DFA/NFA/GNFA)**, **PDA (DPDA/NPDA)**, **TM (DTM/NTM/MNTM)**, **Regex** (lexer/parser/posfixa) e utilitários (minimização, operações de conjunto, generadores de linguagens, visualização/manim/graphviz). Serve como **especificação de algoritmos** maduros para portar ao Dart.
- **AutomataTheory (Dart)** — coleção/índice destacando estruturas e algoritmos de FA/PDA/TM/Regex (inspirada no *automata-main*), útil para mapeamento conceitual e checklist de implementação.
- **nfa_2_dfa (Flutter)** — app educacional com **modelos NFA/DFA** ricos (serialização, métricas, “traces”), **conversão NFA→DFA** (múltiplas estratégias), operações (união/interseção/concatenação/fecho), **minimização** e infra de relatórios/telemetria.
- **PetitParser (Dart, exemplos)** — gramáticas e avaliadores (JSON, BibTeX, Pascal, Dart, Prolog, LISP, Matemática) e um **pipeline Regex→AST→NFA (Thompson)** com simulador de NFA e integração à interface `Pattern` de Dart.
- **Turing Machine Generator (Flutter)** — modelagem e simulação de **Máquinas de Turing** com fita, ações atômicas, parser de ações, serialização JSON/Hive, telas de edição tabular e execução com passo/auto‑run.

> **Uso recomendado**: portar **lógica/algoritmos** para Dart (core do JFlutter), reutilizando **ideias de API** e **testes**; evitar dependência direta de UI de terceiros.

---

## Autômatos Finitos — DFA/NFA

### Capacidades-chave para o JFlutter
- Representação imutável de **estados**, **alfabetos**, **transições** (com ε), **estado inicial** e **finalidades**.
- **Simulação** passo‑a‑passo com *trace* (caminho, fechos‑ε, decisões).
- **Conversões**: NFA→DFA (subset construction), DFA→mínimo (Hopcroft), DFA/NFA→GNFA→Regex.
- **Operações** sobre linguagens: união, interseção, complemento, diferença, concatenação, estrela, reverso, embaralhado (shuffle).
- **Ferramentas**: checagem de vazio, finitude, equivalência; geração de palavras (por comprimento), cardinalidade aproximada/precisa.

### Fontes sugeridas
- *Automata (Caleb)*: DFA/NFA/GNFA completos (minimização, operações, geradores, regex↔autômatos) — **usar como especificação canônica** para Dart.
- *nfa_2_dfa*: modelos pragmáticos com JSON, métricas, traces e minimização por tabela de distinção — **excelente para a API Dart** e integração com a UI do JFlutter.

---

## Autômatos de Pilha — PDA

### Capacidades-chave
- **PDA base** com modos de aceitação (por **estado final**, **pilha vazia** ou **ambos**), **Pilha** imutável (push/pop/replace), **Configuração** imutável.
- **DPDA** com verificação de conflitos (λ-transições vs. símbolo) e **execução determinística**.
- **NPDA** com **ramificação** (várias configurações simultâneas) e coleta de **caminhos aceitos**.

### Fontes sugeridas
- *Automata (Caleb)*: PDA/DPDA/NPDA com estrutura de configuração e pilha imutáveis, exceções específicas e visualização; **modelo direto para portar**.

---

## Expressões Regulares e Gramáticas (PetitParser)

### Capacidades-chave
- **Regex → AST → NFA (Thompson)**, com suporte a literais, alternância, concatenação, quantificadores, grupos e curingas; simulação de NFA com fechos‑ε.
- Conjunto amplo de **gramáticas** (Dart, Pascal, JSON, BibTeX, Smalltalk, Prolog, LISP, Matemática) implementadas com *parser combinators* — útil como **guia de arquitetura** para módulos de gramáticas no JFlutter (ex.: CFGs e futuras conversões).

### Fontes sugeridas
- *PetitParser (exemplos)*: **regex parser/AST/NFA** e gramáticas diversas — **reutilizar o padrão de construção de gramáticas** e o **pipeline Regex→NFA** como referência.

---

## Máquinas de Turing

### Capacidades-chave
- **Modelo de fita** imutável (ou funcional) com leitura/escrita/movimento e símbolo branco.
- **Configuração** (estado, conteúdo de fita, posição da cabeça), variantes **DTM/NTM/Multi‑tape**.
- **Execução** passo‑a‑passo com captura de configurações para visualização e depuração.

### Fontes sugeridas
- *Automata (Caleb)*: TM base + DTM, NTM, MNTM com **estruturas de fita/configuração** e **validações** — **portar semântica para Dart**.
- *Turing Machine Generator (Flutter)*: API prática de **ações** e **parser de ações**, **persistência JSON/Hive** e telas de **edição tabular** — **inspiração de UX e serialização**.

---

## Modelagem unificada de estruturas no JFlutter

### Interfaces mínimas (Dart, esboço)
- `Alphabet<T>` (imutável), `State` (id estável), `Transition<Sym, St>`.
- `Configuration` genérica por máquina (FA/PDA/TM), com **`step()` puro** retornando *next* configs/relatórios.
- `Trace` (lista de `Configuration` + *events*), para visualização e auditoria.
- **Imutabilidade por padrão** (facilita UI reativa e *time travel*); mutabilidade opcional apenas em editores.

### Pacotes sugeridos no monorepo
- `core_fa`, `core_pda`, `core_tm`, `core_regex`, `core_cfg` (futuro), `conversions` (NFA→DFA, DFA→min, GNFA→Regex, CFG→PDA…), `serializers` (JSON/JFF), `viz` (layout/graph), `playground` (golden tests).

---

## Interoperabilidade: serialização, import/export e formatos
- **JFLAP (.jff)**: manter compatibilidade de import/export (DFAs/NFAs, PDAs, TMs) para facilitar migração de exercícios.
- **JSON**: seguir o padrão dos modelos de `nfa_2_dfa` (NFA/DFA/StateSet) para portabilidade; fornecer *schemas* versionados.
- **Projetos**: pacote `references` de exemplos (regex, gramáticas, máquinas canônicas) com metadados e testes.

---

## Algoritmos essenciais por categoria

### DFA/NFA
- **Subset construction** (NFA→DFA); **Hopcroft** (minimização DFA).
- **Operações**: união/interseção/complemento/diferença; concatenação, estrela, reverso, shuffle.
- **Propriedades**: vazio/finito/equivalência; **geração de palavras** (faixas de comprimento).
- **Regex**: parser → pós‑fixa (Shunting‑Yard) → NFA (Thompson) → (opcional) DFA → mínimo.

### PDA
- Simuladores **DPDA/NPDA** com **aceitação** por estado/pilha; **traces** de execuções e coleta de caminhos aceitos.
- (Futuro) **CFG→PDA** canônica (produção por empilhamento/desempilhamento).

### TM
- **DTM/NTM/Multi‑tape**; conversão *multi‑tape → single‑tape* para equivalência; **traces** completos.

---

## Plano incremental de implementação no JFlutter

1) **Core FA (Dart)**: NFA/DFA + subset construction + minimização + operações + traces.  
2) **Regex módulo**: parser (builder), AST, Thompson → NFA; integração com `Pattern`.  
3) **PDA**: base/DPDA/NPDA + traces + modos de aceitação; (fase 2) CFG→PDA.  
4) **TM**: fita/configuração + DTM; (fase 2) NTM/Multi‑tape.  
5) **Serialização**: JSON + JFF; import/export.  
6) **UI**: editores/visualizadores reutilizando traces; relatórios/telemetria.  
7) **Testes**: golden tests reproduzindo exemplos das referências; *property‑based* para invariantes.

---

## Matriz “feature → referência(s)”

| Feature | Onde estudar/espelhar | Observações |
|---|---|---|
| NFA/DFA core + simulação | *Automata (Caleb)*; *nfa_2_dfa* | Especificação completa + API pragmática c/ JSON e traces |
| NFA→DFA (subset) | *Automata (Caleb)*; *nfa_2_dfa* | Considerar versões otimizadas e cache |
| Minimização DFA (Hopcroft) | *Automata (Caleb)*; *nfa_2_dfa* | Tabela de distinção / refino de partições |
| Operações DFA/NFA | *Automata (Caleb)*; *nfa_2_dfa* | Produto cartesiano, pós‑minimização |
| Regex→NFA (Thompson) | *PetitParser (exemplos)* | AST de regex + simulador NFA, integração Pattern |
| Linguagens/gramáticas | *PetitParser (exemplos)* | Uso de parser combinators como base para CFGs |
| PDA (DPDA/NPDA) | *Automata (Caleb)* | Pilha/configuração imutáveis; modos de aceitação |
| TM (DTM/NTM/Multi) | *Automata (Caleb)*; *Turing Machine Generator* | Semântica canônica + UX/serialização do app Flutter |
| Serialização/Projetos | *nfa_2_dfa*; *Turing Machine Generator* | JSON/Hive; schemas versionados; import/export |
| Visualização/Traces | *Automata (Caleb)* (graphviz/manim); *nfa_2_dfa* | Traces detalhados + animações/diagramas |

---

> **Notas finais**: manter o **core 100% Dart puro** (sem dependência de UI) e cobrir cada algoritmo com **testes de regressão** baseados nos exemplos destas referências. A UI do JFlutter deve apenas **consumir traces** e apresentar estados/transições de forma interativa (step, back, auto‑run, breakpoints didáticos).
