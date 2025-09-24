# Índice de estruturas e algoritmos — Turing Machine Generator

## Modelagem da máquina de Turing
- **`TuringMachine` (`lib/models/TuringMachines.dart`)**: encapsula o autômato hipotético, mantendo fita, configuração atual e descrição. Constrói um `LinkedHashMap` ordenado de pares configuração→comportamento, itera com `stepIntoConfig()` (valida comodins `ANY`, aciona ações e progride contagem de iterações), além de rotinas de reinicialização (`reset` e `softReset`) e manutenção (`addEntry`, `deleteEntry`).
- **`Tape` (`lib/models/Tape.dart`)**: representa a fita mutável, com fábrica `fromString`, ponteiro de leitura e buffer expansível. Implementa o algoritmo `process()` que interpreta ações elementares (mover, imprimir, apagar), expande a fita à direita dinamicamente e lança exceções quando operações são inválidas. Inclui utilidades de reset, clonagem e serialização textual da fita.
- **`Actions` & `ActionType` (`lib/models/Actions.dart`)**: define o conjunto de operações atômicas sobre a fita e expõe o parser `parseActions()` para converter strings em sequências tipadas, validando tokens e disparando `ActionParserException` em erros. Oferece também `printableListFrom()` para serializar listas de ações.
- **`Configuration` (`lib/models/Configuration.dart`)**: modelo imutável de par m-config/símbolo, com fábricas a partir de string/JSON e comparador customizado que aceita curingas `ANY`. Funções auxiliares `parseSymbolInput`/`parseSymbolOutput` tratam convenções (`NONE`↔`""`).
- **`Behaviour` (`lib/models/Behaviour.dart`)**: associa uma lista de ações a uma m-config de destino, com suporte a igualdade estrutural e serialização Hive/JSON.
- **`TuringMachineModel` (`lib/models/TuringMachineModel.dart`)**: camada de persistência responsável por converter entre o modelo em memória (`TuringMachine`) e estruturas serializáveis (Hive/JSON), preservando descrição, configurações, comportamentos e configuração inicial. Disponibiliza `fromMachine()` e `actuateMachine()` para ida e volta.
- **`Targets` (`lib/models/Targets.dart`)**: enumera plataformas de destino para adaptar layout/comportamento da UI.

## Construção e cenários de teste
- **`StandardMachines` (`lib/testing.dart`)**: fábrica de máquinas de exemplo, incluindo um cenário que imprime zeros continuamente e uma máquina vazia, úteis para testes rápidos ou inicialização da UI.

## Tratamento de exceções
- **`ActionParserException`, `TapeOperationException`, `InvalidLookupException` (`lib/exceptions/action_exceptions.dart`)**: exceções especializadas usadas para sinalizar erros de parsing de ações, operações inválidas na fita e consultas de transições inexistentes.

## Fluxos de interface e ferramentas
- **`WelcomeScreen` (`lib/screens/WelcomeScreen.dart`)**: ponto de entrada da experiência, oferecendo atalhos para máquinas vazias, máquinas padrão e carregamento de modelos persistidos.
- **`TableScreen` (`lib/screens/TableScreen.dart`)**: editor tabular da função de transição. Oferece validação de formulários para novos pares configuração→comportamento, seleção de configuração inicial, remoção de entradas, reset da máquina, exportação JSON (`_showJsonSheet()`), edição da descrição (`_showInfoSheet()`), armazenamento via Hive e navegação para simulação da fita.
- **`TapeScreen` (`lib/screens/TapeScreen.dart`)**: visualizador e controlador da execução. Exibe estado corrente (ponteiro, m-config, símbolo, iteração), permite passos manuais, automação temporizada, reset suave e segue o ponteiro na visualização através de `TapeWidget`.
- **`LoadMachineScreen` (`lib/screens/LoadMachineScreen.dart`)**: gerencia persistência Hive de máquinas, listando, excluindo, importando via JSON (com validação) e reconstituindo máquinas com `TuringMachineModel.actuateMachine()`.
- **`TapeWidget` (`lib/widgets/TapeWidget.dart`)**: componente reutilizável para renderização horizontal da fita com destaque no ponteiro.
- **`main.dart` (`lib/main.dart`)**: inicializa Hive, registra adapters de serialização e detecta plataforma (`MyApp.detectPlatform()`) para configurar o restante da aplicação.

Este índice prioriza componentes reutilizáveis no JFlutter, destacando onde encontrar algoritmos de simulação, parsing, serialização e gerenciamento de interface relacionados às máquinas de Turing.
