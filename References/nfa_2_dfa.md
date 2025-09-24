# Índice de estruturas e algoritmos do projeto `nfa_2_dfa`

## Visão geral
O projeto `nfa_2_dfa` é uma aplicação Flutter focada na modelagem, análise e conversão de autômatos finitos não determinísticos (NFA) para determinísticos (DFA). A seguir listamos os principais módulos, classes e algoritmos reutilizáveis para integrações futuras com o JFlutter.

## Modelos de autômatos (`lib/models`)

### `nfa.dart`
- `NFA`: implementação extensiva de autômatos não determinísticos, incluindo gerenciamento de estados/alfaabetos, transições (com suporte a ε) e metadados.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/nfa.dart†L80-L210】【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/nfa.dart†L320-L449】
- Métodos de conveniência para construção (`factory` de autômatos vazios, universais, regex etc.) e serialização JSON bidirecional.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/nfa.dart†L176-L274】【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/nfa.dart†L274-L319】
- Operações de edição em massa (adição/remoção de estados, símbolos e transições) e controles de estado inicial/finais com rastreamento de modificações.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/nfa.dart†L320-L533】
- Algoritmos de análise: cálculo de `epsilonClosure`, aceitação de cadeias, rastreamento detalhado de execução (`NFATrace` e `NFATraceStep`) e testes em lote.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/nfa.dart†L534-L671】【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/nfa.dart†L640-L719】
- Operações formais prontas: união, concatenação e fecho de Kleene com validação e construção automática de novos autômatos.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/nfa.dart†L720-L887】
- Métricas utilitárias (densidade de transições, contadores ε, validação estruturada) e gerenciamento de metadados/modificações para auditoria.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/nfa.dart†L888-L1025】

### `dfa.dart`
- `DFA`: estrutura determinística que encapsula estados como `StateSet` (subconjuntos de estados NFA) com registro de nomes legíveis e controle de alfabetos/transições.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/dfa.dart†L45-L132】【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/dfa.dart†L208-L288】
- Serialização JSON rica e cópia profunda para reutilização/minimização independente.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/dfa.dart†L134-L207】
- Algoritmos principais: processamento de strings com relatório, geração de cadeias aceitas via DFS limitado, métrica de autômato (`AutomatonMetrics`), validação, minimização (tabela de distinção), complementação e completude (dead state).【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/dfa.dart†L288-L525】【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/dfa.dart†L526-L885】
- Operações de autômatos determinísticos: união/interseção compostas por produto cartesiano e renomeação inteligente de estados, suporte a minimização após operações.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/dfa.dart†L886-L1056】【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/dfa.dart†L960-L1056】

### `state_model.dart`
- `StateModel`: representação básica de estado (nome/finalidade) com utilidades de cópia, (de)serialização e validação de nome.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/state_model.dart†L1-L42】
- `StateSet`: wrapper para conjuntos de `StateModel`, incluindo identificação humanamente legível, checagem de estados finais e operadores de igualdade/hash para uso como chaves de mapas de transições.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/models/state_model.dart†L44-L93】

## Serviços e algoritmos de conversão (`lib/services`)

### `converter_service.dart`
- `NFAToDFAConverter`: fachada de alto nível para conversão com cache de resultados, análise de complexidade, escolha dinâmica entre estratégias sequenciais/paralelas e minimização opcional.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/converter_service.dart†L1-L200】
- Configurações reutilizáveis (`ConverterConfig`, `ConversionOptions`) e telemetria de conversão (`ConversionProgress`, `ConversionMetrics`, `ConversionResult`) que encapsulam relatórios, erros e etapas detalhadas.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/converter_service.dart†L400-L648】
- Utilidades auxiliares: exportação de resultados, minimização pós-processamento e geração de relatórios avançados a partir do DFA convertido.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/converter_service.dart†L648-L720】

### `nfa_to_dfa_converter.dart`
- Conjunto de enums e `AdvancedConversionConfig` para selecionar algoritmos alternativos (subset adaptativo, híbrido, paralelo) e políticas de otimização/memória durante a conversão.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/nfa_to_dfa_converter.dart†L1-L150】
- `EnhancedConversionReport`: estrutura detalhada de métricas (tempos, compressão, uso de memória, otimizações aplicadas) e geração de relatórios textuais/JSON da conversão.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/nfa_to_dfa_converter.dart†L24-L122】

### `automaton_operations.dart`
- `EnhancedAutomatonOperations`: implementação de operações avançadas entre autômatos com suporte a cache (`AutomatonCache`), monitoramento de performance e conversão interna NFA→DFA otimizada.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/automaton_operations.dart†L1-L120】【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/automaton_operations.dart†L300-L404】
- Algoritmos prontos: união/interseção de NFAs com minimização opcional do DFA resultante, concatenação com análise de transições ε e fecho de Kleene com detecção de ciclos.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/automaton_operations.dart†L300-L404】【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/automaton_operations.dart†L404-L520】
- Estruturas de resultados (`UnionResult`, `IntersectionResult`, `ConcatenationResult`, `KleeneStarResult`, `ComplementResult`) para encapsular métricas, tempos de processamento e otimizações aplicadas.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/automaton_operations.dart†L8-L96】

### `file_service.dart`
- Serviço auxiliar para carregar NFAs de arquivos, retornando objetos fortemente tipados (`NFA`) com tratamento de sucesso/erro reutilizável.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/services/file_service.dart†L1-L120】

## Utilidades (`lib/utils`)

- `graph_utils.dart`: rotinas matemáticas/geométricas para visualização de autômatos (distância, ângulos, interseção linha-círculo, geração de cores determinísticas).【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/utils/graph_utils.dart†L1-L120】
- `transition_helpers.dart`: assistentes de UI para edição em massa de transições com suporte ao provedor de NFAs (útil para ferramentas de modelagem).【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/utils/transition_helpers.dart†L1-L120】
- `helpers.dart`: utilitários de interface (snackbars, diálogos) para feedback consistente ao manipular autômatos.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/utils/helpers.dart†L1-L120】

## Gerenciamento de estado (`lib/providers`)

- `NFAProvider`: encapsula um `NFA` ativo, operações CRUD sobre estados/transições e persistência de projetos recentes, facilitando integração com UI ou serviços externos.【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/providers/nfa_provider.dart†L1-L160】
- `conversion_provider.dart` / `settings_provider.dart`: coordenam solicitações de conversão e preferências da aplicação (ver arquivo para detalhes específicos antes da reutilização).【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/providers/conversion_provider.dart†L1-L200】【F:References/nfa_2_dfa-3200c74c3f32067df2d5055eb70cf0e16a183bb8/lib/providers/settings_provider.dart†L1-L160】

## Como reutilizar
- Extraia os modelos `NFA`, `DFA` e `StateSet` para representar autômatos em novas ferramentas do JFlutter, aproveitando os métodos de validação e serialização existentes.
- Reaproveite `NFAToDFAConverter` ou `EnhancedAutomatonOperations` para fornecer conversão, união/interseção e minimização com monitoramento e cache embutidos.
- Utilize `ConversionResult`, `EnhancedConversionReport` e métricas associadas para gerar relatórios auditáveis em pipelines automáticos.
- Adapte utilitários de visualização (`graph_utils.dart`) e edição (`transition_helpers.dart`) para construir editores interativos ou visualizações animadas dos autômatos.

