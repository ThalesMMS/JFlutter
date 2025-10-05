# Plano de adoção do GraphView

## 1. Estado atual do canvas

- O canvas unificado (`AutomatonGraphViewCanvas`, `TMCanvasGraphView`, `PDACanvasGraphView`) opera inteiramente com GraphView e Riverpod, substituindo os bridges Draw2D e o antigo editor nativo enquanto mantém overlays, destaques e histórico de ações em Flutter puro.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L26-L626】【F:lib/presentation/widgets/tm_canvas_graphview.dart†L5-L210】【F:lib/presentation/widgets/pda_canvas_graphview.dart†L5-L204】
- Controladores especializados (`GraphViewCanvasController`, `GraphViewTmCanvasController`, `GraphViewPdaCanvasController`) convertem estados de domínio em snapshots GraphView e aplicam mutações de volta aos provedores de forma transacional.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L13-L219】【F:lib/features/canvas/graphview/graphview_tm_canvas_controller.dart†L4-L166】【F:lib/features/canvas/graphview/graphview_pda_canvas_controller.dart†L4-L184】
- O mixin `GraphViewViewportHighlightMixin` centraliza zoom, fit/reset e sincronização de destaques de simulação, expondo `ValueNotifier`s observados pelas camadas de UI.【F:lib/features/canvas/graphview/graphview_viewport_highlight_mixin.dart†L5-L128】

## 2. Capacidades da API GraphView

- `GraphView` expõe `Graph`, `Node`, `Edge` e algoritmos de layout (Sugiyama, Buchheim-Walker, Fruchterman-Reingold, etc.). A integração atual utiliza Sugiyama customizado com heurísticas próprias para sobreposições e alocação de rótulos.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L409-L626】
- Panning/zoom são delegados ao `InteractiveViewer` interno controlado por `BaseGraphViewCanvasController`, permitindo zoom incremental, fit e reset com undo/redo integrados.【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L107-L220】
- A biblioteca não fornece gestos de edição, por isso implementamos camada própria com `GestureDetector` que projeta coordenadas de tela em mundo e gerencia overlays de transição via `OverlayEntry`.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L254-L626】

## 3. Mapeamento requisito → solução aplicada

| Requisito | Implementação atual | Observações |
| --- | --- | --- |
| Prototipagem de nós e editor inline | Widgets customizados para estados/arestas, com `GraphViewCanvasNode/Edge` mantendo metadados e `TransitionLabelEditor` renderizado via overlay.| Ainda avaliamos variantes para suportar multi-linhas e ícones adicionais.【F:lib/features/canvas/graphview/graphview_canvas_models.dart†L5-L210】【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L333-L626】 |
| Criação/remoção interativa de nós/arestas | Gestos de toque/clique acionam `addStateAt`, `addOrUpdateTransition`, `removeTransition`, sincronizando imediatamente com Riverpod.| Conectores temporários podem ser adicionados em futuros refinamentos para feedback visual durante o arraste.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L106-L186】 |
| Undo/redo e snapshots | `BaseGraphViewCanvasController` guarda histórico antes de cada mutação e expõe comandos à toolbar.| Precisamos expandir cobertura de testes para validar cenários de undo em PDA/TM com metadados extras.【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L107-L220】 |
| Destaques de simulação | `GraphViewSimulationHighlightChannel` alimenta `SimulationHighlightService`, que colore nós/arestas e limpa automaticamente ao final da simulação.| Continuar monitorando performance em autômatos densos com múltiplos destaques simultâneos.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L41-L84】【F:lib/features/canvas/graphview/graphview_highlight_channel.dart†L5-L19】 |
| Ajuste de viewport | Métodos `zoomIn`, `zoomOut`, `fitToContent`, `resetView` calculam bounding boxes a partir dos caches e atualizam `TransformationController`.| Avaliar heurísticas alternativas para grafos extremamente assimétricos.【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L143-L220】 |
| Sobreposições e menus | `GraphViewLinkOverlayUtils` projeta coordenadas para posicionar editores/menus sobre o canvas, garantindo alinhamento com o layout atual.| Preparar fallback responsivo para telas muito pequenas.【F:lib/features/canvas/graphview/graphview_link_overlay_utils.dart†L5-L148】 |
| Metadados TM/PDA | Mapeadores específicos convertem operações de fita/pilha e mantêm rótulos customizados nos overlays.| Manter sincronização com validadores de domínio ao adicionar novos campos.【F:lib/features/canvas/graphview/graphview_tm_mapper.dart†L7-L144】【F:lib/features/canvas/graphview/graphview_pda_mapper.dart†L7-L160】 |

## 4. Próximos passos

- Expandir a suíte de testes cobrindo controladores GraphView, incluindo undo/redo, sincronização de destaques e projeção de overlays.
- Avaliar algoritmos de layout alternativos para grafos densos e suportar hints de posicionamento manual persistentes.
- Documentar atalhos de teclado/gestos padronizados e revisar acessibilidade em dispositivos móveis e web.

## 5. Follow-up tickets

| ID | Descrição | Status | Observações |
| --- | --- | --- | --- |
| GV-FU-01 | Investigar troca dinâmica de algoritmos de layout (Sugiyama ↔ Fruchterman-Reingold) exposta na toolbar para grafos densos. | Aberto | Instrumentação recém-adicionada em `GraphViewCanvasController` e `BaseGraphViewCanvasController` facilita medir tempos de sincronização por layout.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L14-L214】【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L17-L290】 |
| GV-FU-02 | Cachear projeções de `GraphViewCanvasEdge`/`Node` para reduzir recomputações em drag contínuo. | Aberto | Utilizar contadores `_graphViewMutationCounter` em `AutomatonProvider` para validar ganhos e detectar regressões de sincronização.【F:lib/presentation/providers/automaton_provider.dart†L25-L377】 |
| GV-FU-03 | Adicionar coleta opcional de métricas (por exemplo, duração de `dispatch` de destaques e número de iterações) ao painel de diagnósticos. | Aberto | `SimulationHighlightService` expõe `dispatchCount`/`lastHighlight`, servindo como fonte para futuros painéis ou eventos telemetry.【F:lib/core/services/simulation_highlight_service.dart†L8-L126】 |

## Notas para QA

- O `AutomatonGraphViewCanvas` agora marca o `GestureDetector` raiz como translúcido para capturar taps mesmo quando o fundo está vazio. Quando a ferramenta de adicionar estado estiver ativa, tocar em qualquer área vazia deve criar um novo estado ao delegar para `GraphViewCanvasController.addStateAt`. Validar que outras ferramentas continuam priorizando interações com nós/arestas existentes.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L728-L778】
