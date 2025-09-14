# JFlutter

Um simulador interativo de autômatos e gramáticas desenvolvido em Flutter, derivado do JFLAP original. Oferece uma interface moderna e responsiva para trabalhar com autômatos finitos, gramáticas livres de contexto, máquinas de Turing, parsing LL/LR e muito mais.

## 🚀 Funcionalidades Implementadas

### Autômatos Finitos
- **AFD (Autômatos Finitos Determinísticos)**: Criação, edição e simulação
- **AFN (Autômatos Finitos Não-determinísticos)**: Suporte a transições lambda
- **Conversões**: AFN → AFD, AFD → ER, ER → AFN
- **Operações Básicas**: União, interseção, complemento, produto, reverso
- **Operações Avançadas**: Homomorfismo, quociente à direita/esquerda, diferença
- **Minimização**: Algoritmo de minimização de AFD com interface interativa
- **Verificação de equivalência**: Comparação entre autômatos com contraexemplos
- **Fechos**: Prefixos, sufixos e operações avançadas
- **Completar AFD**: Adição automática de estado de armadilha
- **ε-fecho**: Cálculo de fecho epsilon para AFNλ

### Gramáticas e Parsing
- **Gramáticas Regulares**: Conversão GR ↔ AF
- **Gramáticas Livres de Contexto**: Edição, análise e validação
- **Parsing LL(1)**: Análise descendente com tabelas de parsing interativas
- **Parsing LR(1)**: Análise ascendente com autômatos LR
- **Forma Normal de Chomsky**: Conversão para CNF
- **Algoritmo CYK**: Parsing para gramáticas em CNF
- **Lema do Bombeamento**: Demonstração interativa para linguagens regulares e context-free

### Autômatos Avançados
- **PDA (Autômatos com Pilha)**: Simulação, validação e conversão para CFG
- **Máquinas de Turing**: Suporte multi-fita (1-5 fitas) com simulação visual
- **Máquinas de Mealy/Moore**: Autômatos com saída e conversão entre tipos
- **Conversões**: Mealy ↔ Moore, TM → CSG, PDA → CFG

### Interface e Visualização
- **Canvas Interativo**: Edição visual com gestos touch e multi-seleção
  - Multi-seleção com box-select e Shift-click
  - Movimento conjunto de estados selecionados
  - Edição inline de rótulos de transições
  - Múltiplas arestas curvas entre mesmo par de estados
  - Loops com curvatura ajustável e hit-test preciso
  - Pinch-to-zoom com controles de zoom dedicados
  - Pan e drag para navegação no canvas
- **Simulação Passo-a-passo**: Visualização detalhada de execução
  - Controles de execução (play/pause/step/reset)
  - Controle de velocidade de execução
  - Log de algoritmos em tempo real
  - Visualização de estados ativos
- **Layout Automático**: Presets de posicionamento de estados
  - Compacto, Balanceado, Espalhar, Hierárquico, Automático
  - Auto-centro e centralização manual
  - Posicionamento inteligente com detecção de sobreposição
- **Interface Responsiva**: Otimizada para mobile, tablet e desktop
  - Navegação híbrida (tabs desktop / bottom nav mobile)
  - Breakpoint responsivo em 800px
  - Tabelas responsivas com scroll horizontal/vertical
  - Menu contextual mobile com ações rápidas
- **Sistema de Ajuda**: Tooltips e guias contextuais integrados
  - Ajuda contextual por hover/toque
  - Painel de ajuda completo
  - Conteúdo específico para cada funcionalidade
- **Atalhos de Teclado**: Sistema completo de atalhos
  - Arquivo (Ctrl+N, Ctrl+O, Ctrl+S)
  - Edição (Ctrl+Z, Ctrl+C, Ctrl+V)
  - Navegação (setas, Alt+1/2/3)
  - Simulação (Ctrl+R, F9, F10)
  - Operações (Ctrl+M, Ctrl+F, Ctrl+G)
- **Exportação Avançada**: Múltiplos formatos de saída
  - PNG de alta qualidade com captura de canvas
  - SVG vetorial para gráficos escaláveis
  - LaTeX com TikZ para documentos acadêmicos
  - LaTeX CFG para gramáticas livres de contexto
  - Suporte mobile com compartilhamento de arquivos
- **Importação JFLAP**: Suporte completo a arquivos .jff
  - Parser XML robusto para todos os tipos de autômatos
  - Validação completa com mensagens de erro detalhadas
  - Compatibilidade total com formatos JFLAP existentes

### Ferramentas Educativas
- **Interface de Minimização Interativa**: Baseada no JFLAP
  - Árvore de minimização visual com nós clicáveis
  - Expansão passo-a-passo de grupos distinguíveis
  - Verificação interativa de decomposições
  - Aplicação direta do resultado minimizado
- **Interface do Lema do Bombeamento**: Demonstração educativa
  - Lemas regulares e context-free com decomposições apropriadas
  - Animação passo-a-passo do processo de bombeamento
  - Teste de strings com parâmetros configuráveis
  - Histórico de tentativas para acompanhamento do aprendizado
- **Biblioteca de Exemplos Educativos**: Coleção de exemplos para aprendizado
  - Categorias organizadas por tipo (DFA, NFA, Gramática, CFG, PDA, Turing)
  - Sistema de busca e filtros por categoria
  - Níveis de dificuldade (Fácil, Médio, Difícil)
  - Conceitos e objetivos de aprendizado para cada exemplo
  - Carregamento direto no canvas para experimentação
- **Verificação de Equivalência Avançada**: Ferramenta educativa
  - Teste de palavras em autômatos
  - Verificação completa de equivalência
  - Exibição de contraexemplos quando não equivalentes
  - Múltiplos algoritmos de verificação
  - Detalhes técnicos expandíveis

### Funcionalidades de Persistência
- **Armazenamento Local**: Persistência automática com SharedPreferences
- **Serialização JSON**: Compatibilidade com versão web original
- **Área de Transferência**: Cópia/cola de autômatos e gramáticas
- **Suporte a Clipboard**: Cópia de resultados (regex, gramáticas)

## 📱 Plataformas Suportadas

- **Web**: Chrome, Firefox, Safari, Edge
- **Mobile**: iOS e Android
- **Desktop**: Windows, macOS e Linux

## 🛠️ Instalação e Execução

### Pré-requisitos
- Flutter SDK (versão 3.9.2 ou superior)
- Dart SDK (incluído com Flutter)

### Instalação
```bash
# Clone o repositório
git clone https://github.com/ThalesMMS/jflutter.git
cd jflutter

# Instale as dependências
flutter pub get
```

### Execução
```bash
# Web (recomendado para desenvolvimento)
flutter run -d chrome

# Mobile
flutter run -d ios      # iOS
flutter run -d android  # Android

# Desktop
flutter run -d macos    # macOS
flutter run -d windows  # Windows
flutter run -d linux    # Linux
```

### Build para Produção
```bash
# Web
flutter build web

# Mobile
flutter build apk       # Android
flutter build ipa       # iOS

# Desktop
flutter build macos     # macOS
flutter build windows   # Windows
flutter build linux     # Linux
```

## 🧪 Testes

```bash
# Executar todos os testes
flutter test -r expanded

# Testes específicos por categoria
flutter test test/core_algorithms_test.dart        # Algoritmos fundamentais
flutter test test/examples_roundtrip_test.dart     # Compatibilidade com versão web
flutter test test/ll_lr_parsing_test.dart          # Parsing LL/LR
flutter test test/dfa_minimization_test.dart       # Minimização de AFD
flutter test test/nfa_to_dfa_test.dart             # Conversões NFA→DFA
flutter test test/regex_to_nfa_test.dart           # Expressões regulares
flutter test test/nfa_reversal_test.dart           # Operações avançadas

# Análise estática
flutter analyze
```

## 📚 Como Usar

### Criando um Autômato
1. Abra a aba "AFD" ou "AFN"
2. Defina o alfabeto na barra lateral
3. Adicione estados clicando no canvas (duplo-clique para renomear)
4. Conecte estados arrastando entre eles
5. Marque estados iniciais e finais usando os botões na barra lateral
6. Use os presets de layout para organizar automaticamente

### Simulando uma Palavra
1. Digite a palavra no campo de entrada
2. Clique em "Simular" para execução automática
3. Use "Passo-a-passo" para visualização detalhada
4. Visualize o log de execução no painel de algoritmos

### Análise de Gramáticas
1. Vá para a aba "CFG" para gramáticas livres de contexto
2. Digite uma gramática ou use os exemplos pré-definidos
3. Use a aba "LL/LR" para análise de parsing
4. Visualize as tabelas LL(1) e LR(1) interativas
5. Teste o parsing com strings de entrada

### Autômatos Avançados
1. **PDA**: Use a aba "PDA" para autômatos com pilha
2. **Turing**: Use a aba "Turing" para máquinas multi-fita
3. **Mealy/Moore**: Use a aba "Mealy/Moore" para autômatos com saída

### Ferramentas Avançadas
1. **Minimização Interativa**: Use a interface de minimização com árvore visual
2. **Lema do Bombeamento**: Demonstração interativa na aba CFG
3. **Verificação de Equivalência**: Compare autômatos com contraexemplos
4. **Biblioteca de Exemplos**: Explore exemplos educativos por categoria
5. **Exportação Avançada**: Exporte para PNG, SVG, LaTeX ou LaTeX CFG
6. **Importação JFLAP**: Carregue arquivos .jff do JFLAP original
7. **Atalhos de Teclado**: Use atalhos para operações rápidas
8. **Sistema de Ajuda**: Acesse ajuda contextual em qualquer momento

### Recursos Mobile
1. **Gestos Touch**: Pinch-to-zoom, pan, duplo-toque para adicionar estados
2. **Menu Contextual**: Pressionar e segurar para ações rápidas
3. **Navegação Mobile**: Bottom navigation bar para mobile
4. **Layout Responsivo**: Interface que se adapta ao tamanho da tela
5. **Compartilhamento**: Exporte e compartilhe arquivos facilmente

## 🏗️ Arquitetura

### Estrutura do Projeto
```
lib/
├── core/                           # Algoritmos e modelos de dados
│   ├── automaton.dart              # Modelo base de autômatos
│   ├── algorithms.dart             # Algoritmos fundamentais
│   ├── automaton_analysis.dart     # Análise de autômatos
│   ├── cfg.dart                    # Gramáticas livres de contexto
│   ├── cfg_algorithms.dart         # Algoritmos para CFG
│   ├── dfa_algorithms.dart         # Algoritmos específicos para DFA
│   ├── equivalence_checking.dart   # Verificação de equivalência
│   ├── grammar.dart                # Gramáticas regulares
│   ├── grammar_transformations.dart # Transformações de gramáticas
│   ├── layout_algorithms.dart      # Algoritmos de layout
│   ├── ll_parsing.dart             # Parsing LL(1)
│   ├── lr_parsing.dart             # Parsing LR(1)
│   ├── mealy_moore.dart            # Autômatos com saída
│   ├── mealy_moore_algorithms.dart # Algoritmos Mealy/Moore
│   ├── nfa_algorithms.dart         # Algoritmos específicos para NFA
│   ├── pda.dart                    # Autômatos com pilha
│   ├── pda_algorithms.dart         # Algoritmos para PDA
│   ├── pumping_lemmas.dart         # Lema do bombeamento
│   ├── regex.dart                  # Expressões regulares
│   ├── run.dart                    # Simulação de autômatos
│   ├── turing.dart                 # Máquinas de Turing
│   ├── turing_algorithms.dart      # Algoritmos para Turing
│   ├── algo_log.dart               # Log de algoritmos
│   ├── error_handler.dart          # Tratamento de erros
│   ├── result.dart                 # Resultados de operações
│   ├── entities/                   # Entidades de domínio
│   │   └── automaton_entity.dart
│   ├── parsers/                    # Parsers de arquivos
│   │   └── jflap_xml_parser.dart
│   ├── repositories/               # Interfaces de repositórios
│   │   └── automaton_repository.dart
│   └── use_cases/                  # Casos de uso
│       ├── algorithm_use_cases.dart
│       └── automaton_use_cases.dart
├── presentation/                   # Interface de usuário
│   ├── pages/                      # Páginas principais
│   │   ├── cfg_page.dart           # Página de CFG
│   │   ├── home_page.dart          # Página inicial
│   │   ├── mealy_moore_page.dart   # Página Mealy/Moore
│   │   ├── parsing_page.dart       # Página de parsing
│   │   ├── pda_page.dart           # Página de PDA
│   │   └── turing_page.dart        # Página de Turing
│   ├── providers/                  # Gerenciamento de estado
│   │   ├── algorithm_execution_provider.dart
│   │   ├── algorithm_provider.dart
│   │   └── automaton_provider.dart
│   └── widgets/                    # Componentes reutilizáveis
│       ├── advanced_export_tools.dart
│       ├── algorithm_panel.dart
│       ├── automaton_canvas.dart
│       ├── automaton_controls.dart
│       ├── cfg_canvas.dart
│       ├── cfg_controls.dart
│       ├── contextual_help.dart
│       ├── equivalence_checker_viewer.dart
│       ├── examples_library.dart
│       ├── keyboard_shortcuts.dart
│       ├── layout_tools.dart
│       ├── mealy_moore_canvas.dart
│       ├── mealy_moore_controls.dart
│       ├── minimization_interface.dart
│       ├── mobile_navigation.dart
│       ├── pda_canvas.dart
│       ├── pda_controls.dart
│       ├── pumping_lemma_interface.dart
│       ├── turing_canvas.dart
│       ├── turing_controls.dart
│       └── [outros widgets especializados]
├── data/                           # Gerenciamento de dados
│   ├── data_sources/               # Fontes de dados
│   │   ├── examples_data_source.dart
│   │   └── local_storage_data_source.dart
│   ├── models/                     # Modelos de dados
│   │   └── automaton_model.dart
│   └── repositories/               # Implementações de repositórios
│       ├── algorithm_repository_impl.dart
│       ├── automaton_repository_impl.dart
│       └── examples_repository_impl.dart
├── injection/                      # Injeção de dependência
│   └── dependency_injection.dart
├── app.dart                        # Configuração da aplicação
└── main.dart                       # Ponto de entrada

test/                               # Testes
├── core/                           # Testes dos algoritmos core
│   ├── nfa_from_regex_test.dart
│   ├── nfa_to_dfa_test.dart
│   └── regex_test.dart
├── core_algorithms_test.dart       # Testes de algoritmos fundamentais
├── dfa_minimization_test.dart      # Testes de minimização
├── examples_roundtrip_test.dart    # Testes de compatibilidade
├── ll_lr_parsing_test.dart         # Testes de parsing
├── presentation_automaton_provider_test.dart # Testes de providers
└── [outros testes especializados]
```

### Componentes Principais
- **Canvas Interativo**: Visualização e edição com gestos touch e multi-seleção
- **Algoritmos Core**: Implementações completas dos algoritmos de teoria dos autômatos
- **Providers**: Gerenciamento de estado com Provider pattern
  - AlgorithmProvider: Operações algorítmicas
  - AutomatonProvider: Gerenciamento de autômatos
  - AlgorithmExecutionProvider: Execução e visualização de algoritmos
- **Widgets Responsivos**: Componentes adaptativos para mobile/desktop
- **Sistema de Persistência**: Armazenamento local com SharedPreferences
- **Injeção de Dependência**: Arquitetura modular com GetIt
- **Sistema de Logs**: Visualização de passos dos algoritmos em tempo real
- **Ferramentas de Layout**: Presets automáticos de posicionamento
- **Sistema de Ajuda**: Ajuda contextual integrada
- **Atalhos de Teclado**: Sistema completo de atalhos
- **Exportação Avançada**: Múltiplos formatos de saída
- **Importação JFLAP**: Parser XML robusto para arquivos .jff

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Siga as diretrizes de código (veja `analysis_options.yaml`)
4. Execute os testes (`flutter test`)
5. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
6. Push para a branch (`git push origin feature/nova-funcionalidade`)
7. Abra um Pull Request

### Diretrizes de Desenvolvimento
- Mantenha a arquitetura limpa (core/presentation/data)
- Otimize para dispositivos móveis
- Use os arquivos JFLAP como referência para algoritmos
- Adicione testes para novas funcionalidades
- Siga o padrão de nomenclatura do Flutter

## 📄 Licença

Este projeto é derivado do JFLAP e está licenciado sob os termos da mesma licença. Veja o arquivo LICENCE para detalhes completos.

**Resumo da Licença JFLAP:**
- Você pode distribuir cópias não modificadas do JFLAP
- Você pode distribuir cópias modificadas sob certas condições
- Não é permitido cobrar taxas por produtos que incluam qualquer parte do JFLAP
- Você deve incluir uma cópia do texto da licença
- O nome do autor não pode ser usado para endossar produtos derivados sem permissão específica

### Créditos Especiais
- **Susan H. Rodger** (Duke University) - Criadora original do JFLAP
- **Equipe JFLAP** - Thomas Finley, Ryan Cavalcante, Stephen Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) Lee, Jonathan Su e Henry Qin

## 📊 Status do Projeto

### Funcionalidades Completamente Implementadas ✅
- **Autômatos Finitos**: AFD, AFN, conversões, operações, minimização
- **Gramáticas e Parsing**: CFG, LL(1), LR(1), CNF, CYK, lema do bombeamento
- **PDA e Turing**: Autômatos com pilha e máquinas multi-fita
- **Mealy/Moore**: Autômatos com saída e conversão entre tipos
- **Interface Mobile**: Otimização completa para dispositivos móveis
- **Exportação/Importação**: PNG, SVG, LaTeX, arquivos JFLAP
- **Ferramentas Educativas**: Minimização interativa, lema do bombeamento
- **Sistema de Ajuda**: Ajuda contextual integrada
- **Atalhos de Teclado**: Sistema completo de atalhos
- **Persistência**: Armazenamento local e serialização JSON
- **Biblioteca de Exemplos**: Exemplos educativos organizados por categoria

---

**JFlutter** - Simulando autômatos de forma moderna e interativa! 🎯

*Derivado do JFLAP original - Uma ferramenta educacional para teoria dos autômatos e linguagens formais*