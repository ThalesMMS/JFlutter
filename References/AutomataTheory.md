# AutomataTheory Reference Index

Este índice resume as estruturas de dados e algoritmos oferecidos pelo projeto [`automata-main`](automata-main/README.md), destacando componentes potencialmente reutilizáveis no JFlutter.

## Infraestrutura Base (`automata/base`)
- **`Automaton`**: classe abstrata com validação pós-construção, imutabilidade opcional e geradores passo a passo de leitura de entrada para qualquer autômato.【F:References/automata-main/automata/base/automaton.py†L17-L118】【F:References/automata-main/automata/base/automaton.py†L186-L229】
- **Configuração global**: flags `should_validate_automata` e `allow_mutable_automata` controlam validação automática e congelamento das estruturas.【F:References/automata-main/automata/base/config.py†L1-L6】
- **Utilidades comuns**: funções de congelamento/renomeação, criação/salvamento de grafos para visualização, detecção de dependências e estrutura `PartitionRefinement` usada em algoritmos de minimização e refino de partições.【F:References/automata-main/automata/base/utils.py†L1-L116】【F:References/automata-main/automata/base/utils.py†L118-L203】
- **Suporte visual/animação**: módulos opcionais permitem diagramas (Graphviz) e animações (Manim) compartilhados pelos autômatos finitos.【F:References/automata-main/automata/base/utils.py†L18-L37】【F:References/automata-main/automata/fa/animation.py†L19-L256】

## Autômatos Finitos (`automata/fa`)
### Componentes centrais
- **`FA`**: base para DFAs/NFAs/GNFAs com utilitários de diagramação e iteração de transições, reaproveitando a infraestrutura gráfica.【F:References/automata-main/automata/fa/fa.py†L1-L134】【F:References/automata-main/automata/fa/fa.py†L135-L216】
- **`animation`**: geração de gráficos e animações específicos para DFAs/NFAs, útil para visualizações educacionais.【F:References/automata-main/automata/fa/animation.py†L19-L256】

### `DFA`
- Operações de conjunto sobre linguagens: diferença, união, interseção, xor, complemento e comparações (`issubset`, `issuperset`, `isdisjoint`).【F:References/automata-main/automata/fa/dfa.py†L217-L246】【F:References/automata-main/automata/fa/dfa.py†L746-L1217】
- Algoritmos de minimização e conversão entre formas parciais/completas, com suporte a estado armadilha automático.【F:References/automata-main/automata/fa/dfa.py†L265-L325】【F:References/automata-main/automata/fa/dfa.py†L558-L868】
- Ferramentas de exploração da linguagem: geração/enumeração de palavras (`random_word`, `words_of_length`, `cardinality`, comprimentos mínimo/máximo) e contagens modulares.【F:References/automata-main/automata/fa/dfa.py†L1249-L2148】
- Construtores utilitários: geradores a partir de prefixos, sufixos, substrings, subsequências, linguagens finitas e conversão `from_nfa`.【F:References/automata-main/automata/fa/dfa.py†L1751-L2528】

### `NFA`
- Construções com fecho-λ e eliminação de transições ε, leitura passo a passo e validação de símbolos/transições.【F:References/automata-main/automata/fa/nfa.py†L90-L420】
- Operações de linguagem: união, concatenação, estrela de Kleene, opção, reversão, interseção, produto embaralhado (shuffle) e quocientes à direita/esquerda.【F:References/automata-main/automata/fa/nfa.py†L471-L932】
- Algoritmos de distância de edição e comparação de equivalência entre NFAs, além de construção `from_regex` e conversão `from_dfa`.【F:References/automata-main/automata/fa/nfa.py†L161-L1216】

### `GNFA`
- Conversões `from_dfa` e `from_nfa`, validação de transições generalizadas e transformação para expressões regulares via eliminação de estados.【F:References/automata-main/automata/fa/gnfa.py†L86-L347】

## Autômatos com Pilha (`automata/pda`)
- **`PDA` base**: diagramas com pilha, validação de símbolos de entrada/pilha e rastreamento de configurações durante a leitura.【F:References/automata-main/automata/pda/pda.py†L54-L415】
- **`DPDA`**: garante determinismo checando transições exclusivas, fornecendo iteração e execução passo a passo determinística.【F:References/automata-main/automata/pda/dpda.py†L86-L242】
- **`NPDA`**: suporta múltiplas transições possíveis, retornando todas as configurações seguintes em cada passo.【F:References/automata-main/automata/pda/npda.py†L107-L232】
- **Estruturas auxiliares**: `PDAConfiguration` e `PDAStack` implementam pilhas imutáveis com operações de topo/pop/substituição para manipulação funcional das pilhas.【F:References/automata-main/automata/pda/configuration.py†L1-L62】【F:References/automata-main/automata/pda/stack.py†L1-L62】

## Máquinas de Turing (`automata/tm`)
- **`TM` base**: valida conjuntos de símbolos, símbolo em branco e estado inicial, servindo de base para variantes determinísticas, não determinísticas e multitape.【F:References/automata-main/automata/tm/tm.py†L1-L31】
- **Fitas e configurações**: `TMTape` fornece operações imutáveis de leitura/escrita/movimento, enquanto `TMConfiguration` e `MTMConfiguration` encapsulam estados e múltiplas fitas com impressão amigável.【F:References/automata-main/automata/tm/tape.py†L1-L83】【F:References/automata-main/automata/tm/configuration.py†L1-L62】
- **`DTM`**: leitura determinística com validação de transições, detecção de aceitação e geração passo a passo de configurações.【F:References/automata-main/automata/tm/dtm.py†L90-L222】
- **`NTM`**: ramificação de execuções, recuperando todos os próximos estados possíveis por passo e validando transições não determinísticas.【F:References/automata-main/automata/tm/ntm.py†L92-L222】
- **`MNTM`**: suporte a múltiplas fitas, sincronização de cabeças de leitura e conversão para um NTM equivalente (`read_input_as_ntm`).【F:References/automata-main/automata/tm/mntm.py†L88-L325】
- **Ferramentas**: `tm.tools.print_configs` imprime sequências de configurações para depuração/análise.【F:References/automata-main/automata/tm/tools.py†L1-L17】

## Expressões Regulares (`automata/regex`)
- **Validação**: checagem sintática e léxica das expressões com tokens reservados e alfabetos dinâmicos.【F:References/automata-main/automata/regex/regex.py†L1-L62】
- **Comparação e relações de inclusão**: converte regex em NFAs para verificar equivalência, subconjunto e superconjunto linguístico.【F:References/automata-main/automata/regex/regex.py†L64-L114】

## Como reutilizar no JFlutter
- Diagramas e animações podem ser acoplados à camada de visualização do JFlutter para material didático interativo.
- Algoritmos de fechamento, minimização e construção de linguagens em DFAs/NFAs oferecem um núcleo robusto para simulações e geração automática de exercícios.
- Estruturas imutáveis (pilhas, fitas, configurações) facilitam integrações funcionais e visualizações passo a passo sem efeitos colaterais.
