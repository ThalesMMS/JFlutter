# Plano de migração para GraphView

## 1. Funcionalidades hoje dependentes de `fl_nodes`

### Controladores e modelos
- `BaseFlNodesCanvasController` registra protótipos de nós/campos, escuta o `eventBus` do `FlNodeEditorController` e mantém caches de nós/arestas com histórico de undo/redo antes de cada mutação.【F:lib/features/canvas/fl_nodes/base_fl_nodes_canvas_controller.dart†L35-L220】
- O mesmo controlador reconstrói instantâneos completos (nós, arestas, seleção, destaque) e força o `FlNodeEditorController` a refletir as mudanças vindas dos provedores Riverpod, além de atualizar os destaques de simulação compartilhados.【F:lib/features/canvas/fl_nodes/base_fl_nodes_canvas_controller.dart†L265-L444】
- Handlers derivados mapeiam eventos do editor (`AddNodeEvent`, `NodeFieldEvent`, `AddLinkEvent`, `LinkGeometryEvent`) para mutações de domínio e atualizam o cache local, inclusive geometria de curvas e destaques ativos.【F:lib/features/canvas/fl_nodes/base_fl_nodes_canvas_controller.dart†L484-L688】
- `FlNodesCanvasController`, `FlNodesTmCanvasController` e `FlNodesPdaCanvasController` convertem snapshots em entidades de domínio e vice-versa, mantendo lógica específica (rótulos únicos, pontos de controle, metadados de fitas/pilha, sincronização com `AutomatonProvider`, `TMEditorNotifier` e `PDAEditorNotifier`).【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L16-L308】【F:lib/features/canvas/fl_nodes/fl_nodes_tm_canvas_controller.dart†L14-L187】【F:lib/features/canvas/fl_nodes/fl_nodes_pda_canvas_controller.dart†L13-L200】
- O mixin `FlNodesViewportHighlightMixin` centraliza zoom, fit/reset de viewport e sincronização de destaques de simulação, expondo `ValueNotifier`s consumidos pelas camadas de UI.【F:lib/features/canvas/fl_nodes/fl_nodes_viewport_highlight_mixin.dart†L9-L91】

### Widgets de canvas
- `AutomatonCanvas` injeta o controlador, aplica estilos de tema ao `FlNodeEditorWidget`, pinta setas personalizadas e coordena toolbars/gestos avançados: pan com múltiplos ponteiros, duplo toque para fit/reset, menus de contexto e criação de estados posicionados no mundo.【F:lib/presentation/widgets/automaton_canvas_native.dart†L318-L925】【F:lib/presentation/widgets/automaton_canvas_native.dart†L959-L1275】
- O widget também projeta seleções de arestas para sobreposições (editor inline ou bottom sheet) e alinha destaques de simulação com nós/arestas renderizados.【F:lib/presentation/widgets/automaton_canvas_native.dart†L580-L1158】
- `TMCanvasNative` e `PDACanvasNative` repetem o padrão: ligam-se ao serviço de destaque, projetam overlays específicos (operações de fita/pilha), reagem ao `eventBus` para seguir seleções e expõem gestos equivalentes para adicionar estados e ajustar viewport.【F:lib/presentation/widgets/tm_canvas_native.dart†L30-L386】【F:lib/presentation/widgets/pda_canvas_native.dart†L22-L200】
- O `FlNodesSimulationHighlightChannel` leva eventos de simulação para os controladores, enquanto utilitários como `link_overlay_utils.dart` e `node_editor_event_shims.dart` traduzem payloads privados de `fl_nodes` para a nossa camada de apresentação.【F:lib/features/canvas/fl_nodes/fl_nodes_highlight_channel.dart†L1-L17】【F:lib/features/canvas/fl_nodes/node_editor_event_shims.dart†L1-L178】

## 2. Avaliação da API do pacote `graphview`
- O pacote expõe o widget `GraphView`, um `GraphViewController` e o modelo `Graph`/`Node`/`Edge`; as arestas e nós são montados manualmente e renderizados via algoritmos de layout como Buchheim-Walker, Sugiyama, Fruchterman-Reingold, circular, radial e mindmap (vide [README](https://github.com/nabil6391/graphview)).
- Panning/zoom dependem do `InteractiveViewer` de Flutter, sugerido pelo README do projeto para embutir o `GraphView` com controles de navegação (zoom to fit, auto-centering) conforme a documentação pública.
- A biblioteca prioriza visualização: animações de expand/collapse e posicionamento automático estão prontos, porém não há criação/edição de nós/arestas via gestos out-of-the-box e não existe canal de destaque semelhante ao `FlNodesHighlightController`.

## 3. Mapeamento requisito → solução proposta

| Requisito atual | Estratégia com `graphview` | Riscos e extensões planejadas |
| --- | --- | --- |
| Prototipagem de nós (portas, campos, label editor inline) | Construir `Widget`s customizados para cada nó e manter metadados em um modelo próprio sincronizado com `Graph` + estado Riverpod. | Precisaremos reimplementar edição inline/bottom sheet, pois `graphview` não oferece `FieldPrototype`; exige sobreposição manual semelhante ao que já fazemos com `FlNodesLabelFieldEditor`. |
| Criação e remoção interativa de nós/arestas | Usar `Listener`/`GestureDetector` ao redor do `GraphView` para detectar cliques/arrastos e atualizar o `Graph`; ao confirmar, sincronizar com provedores e reconstruir o layout. | Risco: `graphview` não cria arestas sozinho—será necessário desenhar conectores temporários e definir heurísticas para pontos de ancoragem. Planejamos extender `GraphView` com uma camada de interação que desenha previews e valida ligações antes de atualizar o `Graph`. |
| Manutenção do undo/redo e snapshots | Manter o histórico em uma camada de serviço (equivalente ao `_undoHistory`) antes de mutar o modelo `Graph` + domínio. | Sem hooks no `GraphView` para clonar estado; precisaremos serializar nosso modelo próprio antes das mutações. |
| Destaques de simulação | Propagar `SimulationHighlight` para uma coleção de IDs e aplicar estilos customizados nos `Widget`s de nós/arestas (cores, bordas). | Não há API para marcar arestas selecionadas; será necessário guardar os estilos no estado e regenerar o grafo para refletir alterações de destaque. |
| Ajuste de viewport (fit/reset/zoom) | Embutir `GraphView` em um `InteractiveViewer` controlado e expor métodos auxiliares (`zoomIn`, `fitToContent`) que calculem limites via posições dos nós. | O cálculo de `fit` terá de ser manual (derivar bounding box do modelo), pois `graphview` não fornece API pronta. |
| Sobreposições (editores de transição, menus) | Reutilizar o padrão de `OverlayEntry`/`AnimatedBuilder` sobre o `GraphView`, posicionando widgets via projeção de coordenadas calculadas pelo layout atual. | Precisaremos expor utilitários equivalentes a `projectCanvasPointToOverlay`; risco adicional se o layout reposicionar nós durante a edição. |
| Metadados específicos (transições de TM/PDA) | Persistir atributos adicionais nas nossas classes de domínio e refletir rótulos customizados nos `Widget`s de arestas renderizados pelo `Graph`. | `graphview` não carrega `Edge` com dados arbitrários além de `from`/`to`; devemos manter mapas auxiliares para recuperar controles de fita/pilha e remontar o rótulo. |

## 4. Próximos passos
- Prototipar uma camada de interação sobre `GraphView` que traduza gestos em operações de domínio antes de abandonar definitivamente `fl_nodes`.
- Implementar adaptadores para destaque e histórico reutilizando o contrato atual do `SimulationHighlightService`.
- Validar performance/layout para grafos densos, garantindo que os algoritmos escolhidos suportem automatos com loops e múltiplas arestas paralelas.
