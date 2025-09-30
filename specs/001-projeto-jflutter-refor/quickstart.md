# Quickstart: JFlutter Core Reinforcement Initiative

**Date**: 2025-09-29 | **Branch**: `001-projeto-jflutter-refor` | **Status**: Complete

## Executive Summary

Este guia fornece um roteiro completo para usar o JFlutter reforçado em ambiente offline, cobrindo desde a primeira execução até validações avançadas. Destinado a estudantes e educadores de Teoria da Computação, o quickstart enfatiza fluxos hands-on sem dependências externas.

## Prerequisites

### 1. Installation Requirements
- **Flutter SDK 3.16+** instalado
- **Android Studio** ou **Xcode** para emulação
- **JFlutter** baixado do repositório oficial
- **Conexão inicial** para download de dependências (offline após primeira execução)

### 2. Device Setup
- **Dispositivo móvel** (iOS 17+, Android 14+) ou emulador
- **Espaço disponível**: ~100MB para aplicação + assets
- **Modo avião habilitado** para validação offline completa

## First Launch Experience

### 1. Application Startup

```bash
# 1. Instalar dependências (primeira vez)
flutter pub get

# 2. Executar em dispositivo
flutter run -d <device_id>

# 3. Aceitar permissões (arquivos, câmera opcional)
```

**Expected Behavior**:
- ✅ Tela inicial carrega em < 3 segundos
- ✅ Biblioteca "Examples v1" disponível offline
- ✅ Canvas responsivo (60fps) para visualizações
- ✅ Menu principal com módulos organizados

### 2. Interface Overview

```
┌─────────────────────────────────────┐
│  JFlutter - Teoria da Computação    │
├─────────────────────────────────────┤
│ 📚 EXEMPLOS     🔧 FERRAMENTAS     │
│ 📖 APRENDIZADO  ⚙️ CONFIGURAÇÕES  │
├─────────────────────────────────────┤
│ Módulos Disponíveis:                │
│ • Autômatos Finitos (AF)           │
│ • Autômatos de Pilha (AP)          │
│ • Gramáticas Livres de Contexto    │
│ • Máquinas de Turing (MT)          │
│ • Expressões Regulares             │
│ • Jogos dos Lemas                  │
└─────────────────────────────────────┘
```

## Core Workflow: Import → Simulate → Convert → Validate

### 1. Import & Load (5 minutes)

#### Import from .jff File
```dart
// 1. Acesse módulo de Autômatos Finitos
tap("Autômatos Finitos");

// 2. Selecione opção de importação
tap("📁 Importar");

// 3. Escolha arquivo .jff do dispositivo
selectFile("binary_divisible_by_3.jff");

// 4. Visualize autômato importado
// Expected: DFA com 3 estados, 6 transições
```

**Success Criteria**:
- ✅ Arquivo parseado sem erros
- ✅ Estados e transições exibidos corretamente
- ✅ Canvas responsivo (zoom, pan, seleção)
- ✅ Informações básicas exibidas (tipo, alfabeto)

#### Load from Examples v1
```dart
// 1. Acesse biblioteca de exemplos
tap("📚 EXEMPLOS");

// 2. Navegue por categorias
tap("Teoria dos Números");
tap("Divisível por 3 (Binário)");

// 3. Carregue exemplo
tap("CARREGAR");

// 4. Compare com implementação de referência
// Expected: Visualização idêntica ao arquivo .jff
```

**Success Criteria**:
- ✅ Exemplo carrega em < 2 segundos
- ✅ Metadados educacionais exibidos
- ✅ Casos de teste disponíveis para execução
- ✅ Referência verificada automaticamente

### 2. Simulation & Execution (10 minutes)

#### Finite Automaton Simulation
```dart
// 1. Selecione autômato carregado
selectAutomaton("binary_divisible_by_3");

// 2. Entre no modo de simulação
tap("▶️ SIMULAR");

// 3. Execute casos de teste
input("11");   // 3 em binário
run();        // Expected: ACEITO ✓

input("10");   // 2 em binário
run();        // Expected: REJEITADO ✗

input("110");  // 6 em binário
run();        // Expected: ACEITO ✓
```

**Advanced Features**:
- **Step-by-step execution**: Visualização de cada transição
- **Trace folding**: Navegação por estados visitados
- **Performance metrics**: Tempo de execução, passos utilizados
- **Error diagnostics**: Mensagens claras para transições inválidas

#### Pushdown Automaton Simulation
```dart
// 1. Carregue exemplo de parênteses balanceados
loadExample("balanced_parentheses");

// 2. Configure modo de aceitação
selectAcceptanceMode("Empty Stack");

// 3. Teste strings
input("()");      // Expected: ACEITO
input("())");     // Expected: REJEITADO (não balanceado)
input("(())");    // Expected: ACEITO

// 4. Observe stack operations
// Expected: Stack trace showing push/pop operations
```

#### Turing Machine Simulation
```dart
// 1. Carregue máquina de incremento binário
loadExample("binary_increment");

// 2. Configure fita inicial
setTape("101");  // 5 em binário

// 3. Execute simulação
run();           // Expected: "110" (6 em binário)

// 4. Use time-travel para debug
rewind();        // Volta um passo
stepForward();   // Avança um passo
```

**Performance Requirements**:
- ✅ Simulações de até 10k passos em < 5 segundos
- ✅ Canvas mantém 60fps durante execução
- ✅ Memory usage < 50MB para simulações grandes

### 3. Conversions & Transformations (15 minutes)

#### NFA → DFA Conversion
```dart
// 1. Carregue NFA com ε-transições
loadExample("nfa_with_epsilon");

// 2. Execute conversão automática
tap("🔄 NFA → DFA");

// 3. Visualize resultado
// Expected: DFA equivalente sem ε-transições

// 4. Compare propriedades
// Expected: Mesmo comportamento de aceitação
```

#### Grammar → PDA Conversion
```dart
// 1. Carregue gramática de expressões aritméticas
loadExample("arithmetic_expressions");

// 2. Converta para autômato de pilha
tap("📚 → AP");

// 3. Teste equivalência
input("a+b*c");  // Expected: ACEITO por ambos

// 4. Compare traces de execução
// Expected: PDA simula derivação da gramática
```

#### Regex → NFA Conversion
```dart
// 1. Entre no módulo de expressões regulares
tap("Expressões Regulares");

// 2. Digite expressão
input("a*b|c");

// 3. Visualize NFA de Thompson
// Expected: NFA com ε-transições para concatenação/alternação

// 4. Converta para DFA
tap("🔄 → DFA");

// 5. Teste linguagem gerada
testStrings(["ab", "b", "c", "aab"]);
// Expected: "ab", "b", "c" aceitos; "aab" rejeitado
```

### 4. Ground-Truth Validation (10 minutes)

#### Reference Verification
```dart
// 1. Execute validação automática
tap("✅ VERIFICAR REFERÊNCIA");

// 2. Compare com implementação Python
// Expected: Comportamento idêntico para todos casos de teste

// 3. Visualize diferenças (se houver)
// Expected: Nenhuma diferença significativa

// 4. Gere relatório de validação
// Expected: Relatório detalhado com métricas de equivalência
```

#### Property Validation
```dart
// 1. Analise propriedades do autômato
tap("🔍 ANÁLISE");

// 2. Verifique propriedades automáticas
// Expected:
// • Linguagem vazia: false
// • Linguagem finita: false
// • Estados alcançáveis: 100%
// • Estados produtivos: 100%

// 3. Compare com referência
// Expected: Propriedades idênticas
```

#### Performance Validation
```dart
// 1. Execute benchmarks internos
tap("⚡ BENCHMARKS");

// 2. Meça métricas críticas
// Expected:
// • Canvas rendering: 60fps ✓
// • Simulação 10k passos: < 5s ✓
// • Memory usage: < 50MB ✓
// • Battery impact: mínimo ✓

// 3. Compare com baselines
// Expected: Performance dentro de parâmetros
```

## Advanced Workflows

### 1. Custom Automaton Creation

#### Visual Editor
```dart
// 1. Crie novo autômato
tap("➕ NOVO");

// 2. Adicione estados
addState("q0", initial: true, final: true);
addState("q1");
addState("q2");

// 3. Configure alfabeto
setAlphabet(["0", "1"]);

// 4. Adicione transições
addTransition("q0", "q0", "0");
addTransition("q0", "q1", "1");
addTransition("q1", "q2", "0");
addTransition("q2", "q2", "1");

// 5. Teste criação
simulate("010"); // Expected: ACEITO (q2 final)
```

#### Text-based Creation
```dart
// 1. Use editor de texto
tap("📝 EDITOR");

// 2. Digite especificação formal
input("""
DFA:
Alphabet: {0,1}
States: {q0, q1, q2}
Initial: q0
Final: {q2}
Transitions:
q0,0 -> q0
q0,1 -> q1
q1,0 -> q2
q2,1 -> q2
""");

// 3. Parse e visualize
// Expected: Autômato equivalente ao visual
```

### 2. Grammar Operations

#### CNF Conversion
```dart
// 1. Carregue gramática com ε-produções
loadExample("grammar_with_epsilon");

// 2. Execute transformação CNF
tap("🔄 → CNF");

// 3. Visualize passos
// Expected: Processo passo-a-passo mostrado

// 4. Verifique equivalência
// Expected: Mesma linguagem gerada
```

#### CYK Parser
```dart
// 1. Carregue gramática em CNF
loadExample("cnf_grammar");

// 2. Entre no modo CYK
tap("🔍 CYK PARSER");

// 3. Teste pertinência
input("abc");    // Expected: ACEITO com árvore

// 4. Visualize árvore de derivação
// Expected: Árvore completa mostrada
```

### 3. Turing Machine Programming

#### Building Blocks
```dart
// 1. Use biblioteca de blocos
tap("🧱 BUILDING BLOCKS");

// 2. Arraste blocos pré-definidos
addBlock("move_right");
addBlock("write_symbol");
addBlock("goto_state");

// 3. Configure parâmetros
configureBlock("write_symbol", "1");

// 4. Teste máquina criada
// Expected: Execução conforme especificação
```

#### Multi-step Debugging
```dart
// 1. Execute com breakpoints
setBreakpoint("q5");

// 2. Execute passo a passo
step(); step(); step();

// 3. Inspecione fita em cada passo
// Expected: Estado da fita visível

// 4. Use time-travel
rewind(5);     // Volta 5 passos
play();        // Continua execução
```

## Troubleshooting

### 1. Common Issues

#### Import Problems
**Issue**: "Arquivo .jff inválido"
**Solution**:
1. Verifique formato JFLAP 7.1
2. Certifique-se de que estados têm IDs únicos
3. Valide XML com ferramenta externa

**Issue**: "Referências não encontradas"
**Solution**:
1. Execute `flutter pub get`
2. Verifique conectividade inicial
3. Reinicie aplicação

#### Performance Issues
**Issue**: "Canvas lento (< 60fps)"
**Solution**:
1. Feche outras aplicações
2. Reinicie dispositivo se necessário
3. Verifique especificações mínimas

**Issue**: "Simulação trava em 10k passos"
**Solution**:
1. Use throttling para casos extremos
2. Divida entrada em partes menores
3. Verifique se há loops infinitos

### 2. Validation Failures

#### Reference Mismatches
**Issue**: "Resultado diferente da referência"
**Solution**:
1. Verifique versão da referência
2. Compare casos de teste específicos
3. Registre divergência documentada

**Issue**: "Propriedades inconsistentes"
**Solution**:
1. Recalcule propriedades
2. Compare algoritmos de análise
3. Verifique implementação contra especificação

## Educational Integration

### 1. Classroom Usage

#### Lesson Planning
```dart
// 1. Prepare exemplos para aula
prepareLesson("finite_automata_basics");

// 2. Selecione exemplos progressivos
selectExamples([
  "empty_language",        // Básico
  "single_symbol",         // Introdução
  "binary_divisible_by_3", // Aplicação
  "palindrome_nfa"         // Avançado
]);

// 3. Configure exercícios
setExercises([
  "Desenhe DFA equivalente",
  "Execute casos de teste",
  "Compare com implementação manual"
]);
```

#### Student Activities
```dart
// 1. Atividade guiada
startGuidedActivity("nfa_to_dfa_conversion");

// 2. Fornecer feedback imediato
provideHints();     // Dicas contextuais
showProgress();     // Barra de progresso

// 3. Validar compreensão
quizStudent([
  "Qual estado representa 0 mod 3?",
  "Por que ε-transições são necessárias?",
  "Como minimizar este autômato?"
]);
```

### 2. Self-Study Mode

#### Adaptive Learning
```dart
// 1. Avaliar nível inicial
assessSkillLevel();  // Básico/Intermediário/Avançado

// 2. Recomendar caminho de aprendizado
recommendPath([
  "Conceitos básicos de AF",
  "Construção de NFA",
  "Conversão NFA→DFA",
  "Minimização de DFA"
]);

// 3. Adaptar dificuldade
adjustDifficulty();  // Baseado no desempenho
```

#### Progress Tracking
```dart
// 1. Registrar progresso
trackProgress([
  "Exemplos completados": 15,
  "Conversões realizadas": 8,
  "Simulações executadas": 50,
  "Tempo total": "2h 30min"
]);

// 2. Identificar lacunas
identifyGaps([
  "Minimização ainda não dominada",
  "Gramáticas precisam mais prática"
]);

// 3. Sugerir próximos passos
suggestNext([
  "Estudar algoritmos de minimização",
  "Praticar com gramáticas complexas"
]);
```

## Performance Benchmarks

### 1. Startup Performance
- **Cold start**: < 3 segundos
- **Library loading**: < 2 segundos
- **First simulation**: < 1 segundo

### 2. Runtime Performance
- **Canvas rendering**: 60fps constante
- **Simulation throughput**: 10k passos/5s
- **Memory usage**: < 50MB para autômatos médios
- **Battery impact**: < 5% por hora de uso ativo

### 3. Offline Reliability
- **Zero network calls** após instalação inicial
- **Asset integrity**: Checksum validation automático
- **Storage efficiency**: Compressão otimizada

## Next Steps

### 1. Advanced Features
Após dominar o básico:
- Explore algoritmos de minimização avançados
- Experimente com máquinas de Turing multi-fita
- Crie gramáticas complexas e teste com CYK

### 2. Customization
- Personalize temas e layouts
- Crie biblioteca pessoal de exemplos
- Desenvolva exercícios customizados

### 3. Integration
- Exporte visualizações SVG para documentos
- Integre com ferramentas acadêmicas
- Compartilhe autômatos via QR codes

---

*Quickstart guide complete with hands-on workflows, troubleshooting, and educational integration for comprehensive offline automata theory learning.*
