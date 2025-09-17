# Requisitos

## Requisitos Funcionais:

### Conversão entre Gramáticas e Autômatos
1. **Conversão de Gramática Livre de Contexto para Autômato de Pilha (AP) - Método LL**
   - Implementação do método LL para conversão de CFG para APN
   - Empilhamento automático das produções da gramática
   - Tratamento de variáveis e terminais na pilha
   - Suporte a produções lambda (ε)
   - Interface visual mostrando a correspondência entre produções e transições
   - Verificação automática de completude da conversão
   - Exportação do autômato de pilha gerado
   - Teste de múltiplas cadeias para validação
   - Comparação com análise por força bruta
   - Suporte a gramáticas ambíguas e não-ambíguas

2. **Conversão de Autômato de Pilha Não-Determinístico (APN) para Gramática Livre de Contexto**
   - Transformação de transições de APN em produções gramaticais
   - Geração de regras para movimentos que empilham/desempilham
   - Tratamento de transições com manipulação de pilha (pop/push)
   - Suporte a múltiplos estados e transições não-determinísticas
   - Interface interativa para seleção de transições a converter
   - Visualização em tempo real das produções geradas
   - Exportação da gramática resultante
   - Verificação automática de completude da conversão
   - Identificação de produções inúteis
   - Validação da equivalência entre o APN original e a gramática gerada

3. **Conversão de Gramática Livre de Contexto para Autômato de Pilha (AP) - Método LR**
   - Implementação do método SLR(1) para conversão de CFG para AP
   - Suporte a análise ascendente (bottom-up) de gramáticas
   - Geração automática de transições baseadas em reduções
   - Tratamento de conflitos shift-reduce e reduce-reduce
   - Visualização do processo de redução na pilha
   - Suporte a múltiplas derivações possíveis
   - Teste interativo com execução passo a passo
   - Feedback visual sobre as operações de shift e reduce
   - Exportação do autômato de pilha resultante
   - Comparação com outros métodos de análise (LL, LR, etc.)

4. **Conversão de Gramática Linear à Direita para Autômato Finito (AF)**
   - Suporte a gramáticas lineares à direita com no máximo uma variável no lado direito
   - Conversão automática de cada produção em transições do autômato
   - Geração de estado final para produções sem variáveis no lado direito
   - Interface visual mostrando a correspondência entre produções e transições
   - Verificação automática de conclusão da conversão
   - Exportação do autômato gerado
   - Suporte a múltiplos símbolos terminais e não-terminais
   - Visualização em tempo real das alterações
   - Feedback sobre produções já convertidas
   - Opção de preenchimento automático de transições

### Análise de Gramáticas
1. **Transformação para Forma Normal de Chomsky (CNF)**
   - Remoção automática de produções lambda (ε)
   - Eliminação de produções unitárias
   - Identificação e remoção de produções inúteis
   - Conversão para CNF com produções no formato A→BC ou A→a
   - Visualização gráfica das dependências entre variáveis
   - Interface interativa para acompanhamento de cada etapa
   - Feedback visual sobre as transformações aplicadas
   - Exportação da gramática resultante em CNF
   - Suporte a gramáticas ambíguas e não-ambíguas
   - Verificação automática de conformidade com CNF

2. **Lema do Bombeamento para Linguagens Regulares**
   - Implementação do lema para provar que linguagens não são regulares
   - Interface de jogo interativa com dois modos:
     - Usuário primeiro: tenta encontrar decomposição xyz válida
     - Computador primeiro: tenta refutar decomposições propostas
   - Restrições automáticas |xy| ≤ m e |y| ≥ 1
   - Validação em tempo real de decomposições
   - Feedback visual sobre erros nas tentativas
   - Histórico de tentativas com detalhes completos
   - Animações mostrando o processo de bombeamento
   - Suporte a múltiplos exemplos de linguagens regulares e não-regulares
   - Explicações detalhadas sobre estratégias vencedoras

3. **Lema do Bombeamento para Linguagens Livres de Contexto**
   - Implementação do lema para provar que linguagens não são livres de contexto
   - Interface de jogo interativa com dois modos:
     - Usuário primeiro: tenta encontrar decomposição uvxyz válida
     - Computador primeiro: tenta refutar decomposições
   - Restrições automáticas |vxy| ≤ m e |vy| ≥ 1
   - Suporte a múltiplos casos de teste
   - Gerenciamento de casos com painel interativo
   - Feedback detalhado sobre tentativas de bombeamento
   - Exemplos de linguagens livres e não-livres de contexto
   - Ferramentas para adicionar/substituir casos de teste
   - Verificação de completude de casos

4. **Análise SLR(1)**
   - Construção de tabela de análise SLR(1)
   - Geração automática de autômato finito determinístico (DFA) para análise
   - Visualização de itens LR(0) e conjuntos de itens
   - Cálculo automático de conjuntos FIRST e FOLLOW
   - Interface interativa para construção passo a passo da tabela SLR(1)
   - Suporte a ações de shift, reduce, accept e goto
   - Visualização da pilha de análise durante o parsing
   - Destaque de produções e transições durante a execução
   - Feedback detalhado sobre conflitos na tabela de análise
   - Exportação da tabela de análise gerada

5. **Parser CYK (Cocke-Younger-Kasami)**
   - Algoritmo eficiente para verificação de pertinência em gramáticas livres de contexto
   - Conversão automática para Forma Normal de Chomsky (CNF)
   - Visualização da tabela de análise CYK
   - Interface interativa com controle de execução passo a passo
   - Suporte a múltiplas execuções
   - Desempenho significativamente superior ao parser de força bruta
   - Visualização da árvore de derivação
   - Tabela de derivação detalhada
   - Feedback imediato sobre aceitação/rejeição da cadeia
   - Suporte a gramáticas complexas com múltiplas produções

6. **Parser por Força Bruta para Gramáticas Irrestritas (Brute Force Parser)**
   - Suporte a derivação passo a passo
   - Visualização em árvore não invertida
   - Tabela de derivação detalhada
   - Capacidade de processar produções com múltiplos símbolos no lado esquerdo
   - Interface interativa para acompanhamento do processo de derivação
   - Suporte a gramáticas irrestritas complexas (ex: anbncn)
   - Visualização da aplicação de regras de produção
   - Controle de execução (iniciar, pausar, avançar passo a passo)
   - Feedback visual durante o processo de parsing
   - Exportação dos resultados da análise

### Interface e Usabilidade
1. Zoom na área de edição
2. Botão de desfazer ações
3. Salvamento em vários formatos de imagem (SVG, PNG, etc.)
4. Visualização de múltiplas janelas
5. Personalização de cores e estilos
6. Adição automática de estado de rejeição (trap state) em DFAs
7. Leitura de cadeias de entrada a partir de arquivo
8. Visualização em árvore para minimização de DFA
9. Interface interativa para processo de minimização passo a passo
10. Suporte a faixas de valores em transições (ex: [0-9])
11. Modo Building Block para Máquinas de Turing
12. Conversão entre diferentes tipos de autômatos (ex: NFA para DFA)
13. Personalização de transições:
    - Ajuste de curvatura das transições
    - Seleção individual de transições
    - Manipulação de múltiplos rótulos em uma única transição
    - Visualização clara da transição selecionada
    - Suporte a arrastar e soltar para ajuste de posição
    - Destaque visual da transição atualmente selecionada
    - Suporte a duplo clique para edição de rótulos
13. Visualização de árvores de derivação
14. Análise de entrada em autômatos não-determinísticos

### Linguagens Regulares
1. Criar Autômatos Finitos Determinísticos (DFA)
2. Criar Autômatos Finitos Não-Determinísticos (NFA)
3. Criar gramáticas regulares
4. Criar expressões regulares
5. Realizar conversões entre representações:
   - NFA para DFA
     - Algoritmo de construção de subconjuntos
     - Visualização passo a passo da conversão
     - Identificação automática de estados equivalentes
     - Suporte a transições ε (épsilon)
     - Geração automática de estados do DFA
     - Identificação de estados finais no DFA resultante
   - DFA para DFA Mínimo
     - Algoritmo de minimização de estados
     - Visualização do processo de partição de estados
     - Identificação de estados equivalentes
   - FA para Expressão Regular
     - Algoritmo de eliminação de estados
     - Suporte a múltiplos estados finais
     - Colapso de múltiplas transições entre estados
     - Exportação da expressão regular resultante
   - Expressão Regular para FA
   - NFA para Gramática Regular e vice-versa
6. Experimentar com o Lema do Bombeamento para linguagens regulares

### Análise e Processamento
1. Parser CYK (mais rápido que o método de força bruta)
2. Parser controlado pelo usuário (escolha de regras de derivação)
3. Identificação automática de tipos de gramáticas
4. Jogos de Lema do Bombeamento para linguagens regulares e livres de contexto
5. Múltiplas execuções para gramáticas
6. Sistema de avaliação para múltiplos arquivos

### Linguagens Livres de Contexto
7. Criar Autômatos de Pilha (PDA)
8. Criar Gramáticas Livres de Contexto (CFG)
9. Experimentar com o Lema do Bombeamento para linguagens livres de contexto
10. Realizar transformações:
    - PDA para CFG
    - CFG para PDA (analisador LL)
    - CFG para PDA (analisador SLR)
    - CFG para Forma Normal de Chomsky (CNF)
    - Gerar tabela de análise LL
    - Gerar tabela de análise SLR
    - Análise por força bruta

### Linguagens Recursivamente Enumeráveis
11. Criar Máquinas de Turing de 1 fita
12. Criar Máquinas de Turing de múltiplas fitas
13. Trabalhar com blocos de construção de Máquinas de Turing
14. Criar gramáticas irrestritas
15. Converter gramática irrestrita para analisador de força bruta

### Máquinas de Turing
1. **Criação e Edição**
   - Suporte a máquinas de Turing padrão
   - Máquinas de Turing não-determinísticas
   - Múltiplas fitas
   - Fita infinita em ambas as direções
   - Símbolos de fita personalizáveis
   - Estados de aceitação e rejeição explícitos
   - Visualização do estado atual e da fita durante a execução
   - Controle de execução (passo a passo, execução contínua, pausa)
   - Visualização da pilha de execução
   - Suporte a Building Blocks (Blocos de Construção):
     - Criação de blocos reutilizáveis
     - Nomeação de blocos para referência
     - Prevenção de blocos aninhados com o mesmo nome
     - Importação/exportação de blocos individuais
     - Suporte a blocos em máquinas de fita única
     - Verificação de compatibilidade ao importar blocos
     - Interface para edição de blocos
     - Visualização hierárquica de máquinas com blocos do sistema
   - Controle de parâmetros de desenho (ângulo, distância, etc.)
   - Suporte a símbolos especiais para controle da tartaruga
   - Animação das derivações passo a passo
   - Exportação/importação de configurações de L-Systems

### Sistemas-L (L-Systems)
1. **Criação e Visualização de L-Systems**
   - Definição de axiomas e regras de produção
   - Suporte a múltiplos passos de derivação
   - Visualização gráfica da evolução do sistema
   - Controle de parâmetros de desenho (ângulo, distância, etc.)
   - Suporte a símbolos especiais para controle da tartaruga
   - Animação das derivações passo a passo
   - Exportação/importação de configurações de L-Systems

2. **Comandos da Tartaruga**
   - Movimento para frente (com/sem desenho)
   - Rotação nos eixos X, Y e Z
   - Controle de largura da linha
   - Salvamento/recuperação de estado
   - Criação de polígonos preenchidos
   - Controle de cores (linha e preenchimento)
   - Suporte a ramificações

3. **Parâmetros Personalizáveis**
   - Ângulos de rotação
   - Distância do movimento
   - Largura da linha
   - Incremento de largura
   - Variação de matiz (hue)
   - Cores personalizáveis (RGB/HSB)
   - Cores pré-definidas

4. **Exemplos e Aplicações**
   - Geração de fractais
   - Modelagem de plantas e estruturas naturais
   - Padrões recursivos
   - Visualização de processos iterativos

### Máquinas de Mealy
1. **Definição e Propósito**
   - Modelo de máquina de estados finitos com saídas nas transições
   - Definição formal: M = (Q, Σ, Γ, δ, ω, q₀) onde:
     - Q: Conjunto finito de estados
     - Σ: Alfabeto de entrada
     - Γ: Alfabeto de saída
     - δ: Função de transição (Q × Σ → Q)
     - ω: Função de saída (Q × Σ → Γ)
     - q₀: Estado inicial
   - Útil para modelagem de sistemas com entradas e saídas
   - Aplicações em design de circuitos digitais e protocolos de comunicação
   - Diferenciação de máquinas de Moore (saídas nos estados)

2. **Funcionalidades Principais**
   - Definição de alfabetos de entrada e saída distintos
   - Criação de transições no formato "entrada;saída"
   - Visualização clara das transições e saídas
   - Simulação passo a passo com rastreamento de estados
   - Exibição em tempo real da fita de saída
   - Teste com múltiplas entradas simultâneas
   - Verificação automática de não-determinismo
   - Destaque de estados não-determinísticos
   - Restrição a máquinas determinísticas para execução

3. **Exemplos Práticos**
   - **Porta Lógica NOT**
     - Inversão de bits de entrada
     - Transições simples com saídas complementares
     - Demonstração de máquinas de Mealy básicas
   
   - **Máquina de Vendas**
     - Modelagem de máquinas de venda automática
     - Tratamento de diferentes moedas (níquel, dime, quarter)
     - Cálculo automático de troco
     - Estados representando valores acumulados
     - Saídas para dispensar produto e troco

4. **Características Avançadas**
   - Suporte a múltiplos símbolos de entrada/saída
   - Visualização de rastreamento de execução
   - Exportação/importação de definições
   - Testes com múltiplos casos de uso
   - Verificação de completude da máquina

## Requisitos Não Funcionais:
1. Interface gráfica amigável e acessível
2. Documentação abrangente

## Suporte Técnico e Recursos para Desenvolvedores

### Documentação Técnica
1. **Guia do Desenvolvedor**
   - Arquitetura do sistema
   - Guia de estilo de código

2. **API e Extensibilidade**
   - Documentação de classes e métodos

3. **Controle de Versão**
   - Repositório de código-fonte
