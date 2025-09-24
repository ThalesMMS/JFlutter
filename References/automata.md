# Índice da biblioteca `automata-main`

## Visão geral
- O projeto oferece implementações otimizadas de autômatos finitos, autômatos com pilha e máquinas de Turing, com suporte a visualização e manipulação de expressões regulares, pensado tanto para pesquisa quanto para ensino de teoria da computação.【F:References/automata-main/README.md†L18-L26】

## Infraestrutura base
- `automata.base.automaton.Automaton` define a fundação imutável para todos os autômatos, incluindo validação automática, leitura de entrada passo a passo e utilitários de serialização.【F:References/automata-main/automata/base/automaton.py†L56-L213】
- `automata.base.config` expõe sinalizadores globais para ativar/desativar validações e imutabilidade durante experimentos.【F:References/automata-main/automata/base/config.py†L1-L6】
- `automata.base.utils` reúne funções auxiliares: congelamento profundo de estruturas, criação/salvamento de grafos de visualização, particionamento incremental de conjuntos e busca de nós alcançáveis em grafos de transições.【F:References/automata-main/automata/base/utils.py†L53-L249】
- `automata.base.animation` fornece integrações com Manim/Graphviz para animar autômatos, incluindo objetos de cena para estados e transições coloridos dinamicamente.【F:References/automata-main/automata/base/animation.py†L14-L197】
- `automata.base.exceptions` padroniza erros compartilhados (estados/símbolos inválidos, linguagens vazias/infinita, falhas de diagrama) e erros específicos de regex/lexer.【F:References/automata-main/automata/base/exceptions.py†L6-L95】

## Autômatos finitos
### Núcleo `FA`
- A classe abstrata `FA` provê iteração sobre transições e geração de diagramas Graphviz com destaque de trajetórias de entrada, reutilizada por DFA, NFA e GNFA.【F:References/automata-main/automata/fa/fa.py†L42-L205】

### `automata.fa.dfa.DFA`
- Algoritmos de minimização combinam remoção de estados inalcançáveis com refinamento de partições (Hopcroft) e criação automática de armadilhas para DFAs parciais.【F:References/automata-main/automata/fa/dfa.py†L558-L656】
- Operações de conjunto (união, interseção, diferença, diferença simétrica e complemento) são construídas por produtos cartesianos com expansão preguiçosa e opcional minificação do resultado.【F:References/automata-main/automata/fa/dfa.py†L746-L939】
- Consultas sobre a linguagem incluem verificações de vazio/finito, contagem e enumeração de palavras por comprimento, geração de palavras aleatórias e cálculo de comprimentos mínimo/máximo aceitos.【F:References/automata-main/automata/fa/dfa.py†L1233-L1748】
- Geradores diretos criam DFAs mínimos para linguagens definidas por prefixos, sufixos, substrings/subsequências, restrições de comprimento ou conjuntos finitos, e incluem a construção a partir de NFAs (subconjuntos + minificação).【F:References/automata-main/automata/fa/dfa.py†L1751-L2508】

### `automata.fa.nfa.NFA`
- Construtores aceitam regexes diretamente, validando símbolos reservados antes de usar o parser interno para gerar transições equivalentes.【F:References/automata-main/automata/fa/nfa.py†L190-L240】
- O módulo implementa operações clássicas como união, concatenação, fecho de Kleene/opcional, reversão e produtos de interleaving, reutilizando mapeamentos de estados para combinar autômatos.【F:References/automata-main/automata/fa/nfa.py†L471-L767】
- Também oferece quocientes à direita/esquerda, equivalência via Hopcroft-Karp estendido e construção de autômatos de distância de edição parametrizáveis (Levenshtein/Hamming/LCS).【F:References/automata-main/automata/fa/nfa.py†L816-L1158】

### `automata.fa.gnfa.GNFA`
- GNFAs podem ser derivados automaticamente de DFAs/NFAs ajustando transições para expressões regulares parciais, com estados inicial/final auxiliares.【F:References/automata-main/automata/fa/gnfa.py†L110-L232】
- Um algoritmo de eliminação converte o GNFA em uma expressão regular equivalente, escolhendo nós com menor grau para reduzir gradualmente o grafo.【F:References/automata-main/automata/fa/gnfa.py†L327-L355】

## Ferramentas de expressões regulares
- O lexer genérico registra fábricas de tokens por regex e produz listas em notação infixa, com tratamento de espaços e erros léxicos dedicados.【F:References/automata-main/automata/regex/lexer.py†L1-L145】
- Utilitários de notação pós-fixa validam sequências tokenizadas, aplicam precedência/associatividade via pilha (estilo Shunting-Yard) e avaliam expressões em pós-fixa.【F:References/automata-main/automata/regex/postfix.py†L1-L192】
- O parser constrói NFAs incrementais com operações de união, interseção, concatenação, repetição parametrizada, produto embaralhado, curingas e tokens de Kleene/quantificadores prontos para uso.【F:References/automata-main/automata/regex/parser.py†L34-L445】

## Autômatos com pilha
- A classe base `PDA` controla validações de símbolos de entrada/pilha, modo de aceitação (`final_state`, `empty_stack`, `both`) e suporte visual semelhante a FA.【F:References/automata-main/automata/pda/pda.py†L363-L413】
- `PDAConfiguration` e `PDAStack` representam estados de execução imutáveis, com operações de pilha (top, pop, replace) usadas pelos simuladores.【F:References/automata-main/automata/pda/configuration.py†L10-L40】【F:References/automata-main/automata/pda/stack.py†L9-L89】
- `DPDA` reforça determinismo verificando conflitos com transições lambda, calcula próximos estados únicos e produz trilhas de processamento para visualização.【F:References/automata-main/automata/pda/dpda.py†L110-L240】
- `NPDA` gera múltiplas configurações sucessoras, aceitando interleaving de transições lambda e armazenando caminhos aceitos para reconstrução posterior.【F:References/automata-main/automata/pda/npda.py†L131-L219】
- Exceções específicas de PDA sinalizam modos de aceitação inválidos e introdução inadvertida de não determinismo em DPDAs.【F:References/automata-main/automata/pda/exceptions.py†L6-L21】

## Máquinas de Turing
- A classe abstrata `TM` estende `Automaton` com alfabeto de fita, símbolo branco e validações de consistência entre alfabetos.【F:References/automata-main/automata/tm/tm.py†L13-L40】
- `TMTape` e `TMConfiguration` (incluindo variantes multitape) encapsulam o estado da fita, operações de leitura/escrita/movimento e impressão legível das configurações.【F:References/automata-main/automata/tm/tape.py†L11-L135】【F:References/automata-main/automata/tm/configuration.py†L10-L59】
- `tools.print_configs` facilita depuração imprimindo sequências de configurações geradas pelos simuladores.【F:References/automata-main/automata/tm/tools.py†L1-L19】
- Exceções especializadas tratam direções inválidas, inconsistências de fitas multitape e erros na representação de fitas estendidas.【F:References/automata-main/automata/tm/exceptions.py†L6-L29】
- `DTM` implementa validações completas das transições, rejeição explícita de configurações sem saída e iteração determinística sobre entradas.【F:References/automata-main/automata/tm/dtm.py†L90-L220】
- `NTM` mantém conjuntos de configurações paralelas, aplicando todas as transições compatíveis a cada passo durante a leitura.【F:References/automata-main/automata/tm/ntm.py†L194-L239】
- `MNTM` gerencia múltiplas fitas, checa consistência de transições, realiza busca em largura das configurações e pode simular-se como NTM via fita estendida com separadores/caretas virtuais.【F:References/automata-main/automata/tm/mntm.py†L170-L360】

