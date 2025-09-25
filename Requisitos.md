## Requisitos Funcionais

### Conversão entre Gramáticas e Autômatos

1.  **CFG → AP (método LL)**
    
    *   **~** Trocar “método LL” por **construção padrão GLC→AP** (sem técnica de parsing específica).
        
    *   **✓** Empilhamento automático, tratamento de variáveis/terminais, ε‑produções, interface visual (produção↔transição), verificação de completude, exportação, teste de múltiplas cadeias, suporte a gramáticas ambíguas.
        
    *   **✂** “Comparação com análise por força bruta” (dependeria de parser que extrapola a ementa).
        
2.  **APN → CFG**
    
    *   **✓** Transformar transições do APN em produções; regras para push/pop; múltiplos estados e não‑determinismo; interface para seleção; visualização em tempo real; exportação; verificação de completude; identificação de produções inúteis; **validação por equivalência experimental**.
        
3.  **CFG → AP (método LR / SLR(1))**
    
    *   **✂** Fora da ementa (técnicas LR/SLR e resolução de conflitos não fazem parte aqui).
        
4.  **Gramática Linear à Direita → AF**
    
    *   **✓** Conversão automática produção↔transição; estados finais; interface visual; verificação de conclusão; exportação; múltiplos terminais/não‑terminais; visualização em tempo real; feedback; preenchimento automático.
        

* * *

### Análise de Gramáticas

1.  **CNF**
    
    *   **✓** Remoção de ε, unitárias e inúteis; conversão para A→BC / A→a; visualização de dependências; interface passo a passo; feedback; exportação; suporte a ambíguas; verificação de conformidade.
        
2.  **Lema do Bombeamento — Regulares**
    
    *   **✓** Implementação com modos “usuário primeiro”/“computador primeiro”; |xy|≤m, |y|≥1; validação em tempo real; feedback; histórico; animações; múltiplos exemplos; explicações estratégicas.
        
3.  **Lema do Bombeamento — LLC**
    
    *   **✓** Implementação com modos; |vxy|≤m, |vy|≥1; casos de teste; painel; feedback; exemplos; adicionar/substituir casos; verificação de completude.
        
4.  **Análise SLR(1)**
    
    *   **✂** Fora da ementa (construção de tabelas LR e conflitos shift/reduce).
        
5.  **Parser CYK**
    
    *   **✓** Verificação de pertinência para GLC (via CNF); visualização da tabela; execução passo a passo; múltiplas execuções; melhor desempenho que busca ingênua; árvore e tabela detalhada; feedback; suporte a gramáticas complexas.
        
6.  **Parser por Força Bruta para Gramáticas Irrestritas (GI)**
    
    *   **✂** Fora da ementa como ferramenta geral de parsing para GI (inexequível em geral e não requerido).
        
    *   *(Obs.: GI permanece no escopo conceitual em MT/LREs — ver seção de MT.)*
        

* * *

### Interface e Usabilidade

*   **✓** Zoom; desfazer; **exportar SVG** (PNG opcional depois); múltiplas janelas; personalização de cores/estilos; **trap state** em DFAs; ler cadeias de arquivo; árvore para minimização de DFA; interface interativa de minimização; faixas \[0–9\]; **building block** visual para MT (como **recurso de edição**, não conteúdo); conversões entre autômatos (NFA→DFA); personalização de transições (curvatura, seleção, rótulos múltiplos, destaque, arrastar/soltar, duplo clique); árvores de derivação; **análise de entrada em autômatos não‑determinísticos**; snackbar quando FS indisponível.
    
*   **✓** Tudo aqui é suporte didático; não extrapola conteúdo.
    

* * *

### Linguagens Regulares

*   **✓** Criar DFA/NFA/GR/ER.
    
*   **✓** Conversões: NFA→DFA (subconjuntos, ε‑fechos), DFA→DFA mínimo (partições), FA→ER (eliminação de estados), ER→FA, NFA↔Gramática Regular.
    
*   **✓** Jogo do Lema do Bombeamento (já coberto acima).
    

* * *

### Análise e Processamento

*   **✓** Parser CYK (redundante com seção anterior, mas útil no menu “Análise”).
    
*   **✓** Parser controlado pelo usuário (guiar derivações em GLC).
    
*   **✓** Identificação automática do **tipo de gramática** (heurísticas e checagens estruturais básicas).
    
*   **✓** Jogos de Lema (Reg/LLC).
    
*   **✓** Execuções múltiplas; **sistema de avaliação** para vários arquivos (didático/testes).
    

* * *

### Linguagens Livres de Contexto

*   **✓** Criar **PDA** (simulação interativa) e **CFG**; Lema do Bombeamento (já listado); transformações **PDA↔CFG**, **CFG→CNF**, **tabela LL/SLR** **✂ não** — manter apenas as **transformações canônicas** e **CYK**; análise por busca ingênua **apenas para GLC pequenas** (sem GI).
    

* * *

### Linguagens Recursivamente Enumeráveis

1.  **Máquinas de Turing (1 fita)** — **✓**
    
2.  **Máquinas de Turing (múltiplas fitas)** — **✓** (variação prevista na ementa).
    
3.  **Building Blocks de MT** — **✓** como **recurso de edição/modularização** (não altera o conteúdo teórico).
    
4.  **Gramáticas Irrestritas (GI)** — **✓** criação/edição e **visualização de derivações finitas** para exemplos didáticos.
    
5.  **Converter GI para analisador de força bruta** — **✂** fora da ementa.
    

* * *

### Máquinas de Turing

*   **✓** Criação/edição; MT não‑determinística; múltiplas fitas; fita infinita; símbolos personalizáveis; estados de aceitação/rejeição; visualização de fita/estado; execução (passo a passo/contínua/pausa); visualização da **configuração instantânea**.
    
*   **✓** Exportar/importar máquinas.
    
*   **✂** Tudo que é “L‑Systems/tartaruga/fractais” (não pertence a MT).
    
*   **✓** Animação de **derivações** (execução) está ok.
    

* * *

### Sistemas‑L (L‑Systems)

*   **✂** Remover a seção inteira (fora da ementa).
    

* * *

## Requisitos Não Funcionais

*   **✓** Interface amigável; documentação abrangente; guia do desenvolvedor; API/extensibilidade; repositório versionado.
    
*   **✓** Sem extrapolar conteúdo.
    

* * *

## Resumo do que saiu (✂)

*   **LR/SLR(1)** em qualquer forma (tabelas, conflitos shift/reduce, conversão “via LR”).
    
*   **Parser “força bruta” para GI** (e comparações que dependam dele).
    
*   **Sistemas‑L / Tartaruga / Fractais**.
    
*   Quaisquer menções a **comparar com “força bruta”** quando essa ferramenta não existir no escopo.
    

## O que ficou (útil e dentro da ementa)

*   **ER, AF (AFD/AFN/AFN‑λ), GR/GLC/GI, PDA (APD/APN), MT (det./não‑det., variações), CNF, CYK, Lemas do Bombeamento (Reg e LLC), propriedades de fechamento, Hierarquia de Chomsky, decidibilidade (LRec vs LRE).**
    
*   Ferramentas didáticas fortes: **conversões canônicas**, **simuladores interativos**, **visualizações (árvores, tabelas CYK, minimização)**, **jogos de bombeamento**, **exportação/importação**, **avaliação em lote**.