# Exemplos de Melhorias para JFlutter

Este diretório contém exemplos de implementação para as melhorias propostas no documento `PROPOSTAS_MELHORIAS.md`.

## Arquivos de Exemplo

### 1. `grid_config.dart`
Implementação completa do sistema de grid com snap-to-grid.

**Características:**
- Configuração de grid (tamanho, visibilidade, etc.)
- Painter para desenhar o grid no canvas
- Utilitários para snap-to-grid
- Widget de controles de grid
- Exemplo funcional

**Como usar:**
```dart
import 'grid_config.dart';

// Criar configuração
final gridConfig = GridConfig(
  enabled: true,
  gridSize: 50.0,
  snapToGrid: true,
);

// Snap de posição
final snappedPosition = GridUtils.snapToGrid(
  position,
  gridConfig,
);
```

### 2. `zoom_controls.dart`
Controles visuais de zoom e navegação.

**Características:**
- Configuração de zoom (min, max, step)
- Widget de controles (botões + porcentagem)
- Slider de zoom alternativo
- Mini-mapa para navegação
- Barra de ferramentas flutuante completa

**Como usar:**
```dart
import 'zoom_controls.dart';

// Usar controles
ZoomControls(
  config: zoomConfig,
  onZoomChanged: (newConfig) {
    // Atualizar zoom
  },
  onFitToContent: () {
    // Ajustar para mostrar todo o conteúdo
  },
)
```

### 3. `pda_stack_panel.dart`
Painel de visualização de pilha para PDAs.

**Características:**
- Visualização animada da pilha
- Destaque do topo
- Histórico de operações
- Preview de operações (ao passar mouse em transições)
- Animações suaves

**Como usar:**
```dart
import 'pda_stack_panel.dart';

// Criar estado da pilha
var stack = StackState(symbols: ['Z']);

// Operações
stack = stack.push('A');
stack = stack.pop();

// Usar painel
PdaStackPanel(
  stackState: stack,
  initialStackSymbol: 'Z',
  stackAlphabet: {'A', 'B', 'Z'},
)
```

### 4. `layout_algorithms.dart`
Algoritmos de layout automático.

**Características:**
- Interface base para algoritmos
- **CircularLayout**: Estados em círculo
- **HierarchicalLayout**: Níveis usando BFS
- **GridLayout**: Grade regular
- **ForceDirectedLayout**: Simulação física
- Widget de seleção de algoritmo
- Preview de layout

**Como usar:**
```dart
import 'layout_algorithms.dart';

final algorithm = CircularLayout();
final positions = algorithm.computeLayout(
  stateIds: ['q0', 'q1', 'q2'],
  transitions: {'q0': ['q1'], 'q1': ['q2']},
  initialStateId: 'q0',
  finalStateIds: {'q2'},
  canvasSize: Size(800, 600),
);
```

### 5. `fsa_specialized_canvas.dart`
Canvas especializado para Autômatos Finitos.

**Características:**
- Análise de determinismo (DFA/NFA/ε-NFA)
- Badge de tipo de autômato
- Painel detalhado de não-determinismo
- Estilos diferenciados para transições epsilon
- Agrupamento de transições
- Overlay especializado

**Como usar:**
```dart
import 'fsa_specialized_canvas.dart';

// Analisar determinismo
final info = DeterminismInfo(
  isDeterministic: false,
  hasEpsilonTransitions: true,
  nonDeterministicStates: ['q0', 'q1'],
  nonDeterministicSymbols: ['a', 'b'],
);

// Usar overlay
FSACanvasOverlay(determinismInfo: info)
```

## Integrando com JFlutter

Para integrar esses exemplos na JFlutter:

### 1. Copiar para estrutura do projeto

```bash
# Grid
cp examples/improvements/grid_config.dart lib/core/models/

# Zoom
cp examples/improvements/zoom_controls.dart lib/presentation/widgets/canvas/tools/

# Stack Panel
cp examples/improvements/pda_stack_panel.dart lib/presentation/widgets/pda/

# Layouts
cp examples/improvements/layout_algorithms.dart lib/presentation/utils/

# FSA Canvas
cp examples/improvements/fsa_specialized_canvas.dart lib/presentation/widgets/canvas/specialized/
```

### 2. Integrar com canvas existente

#### Grid:
```dart
// Em AutomatonGraphViewCanvas
class _AutomatonGraphViewCanvasState extends State<AutomatonGraphViewCanvas> {
  GridConfig _gridConfig = const GridConfig(enabled: true);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grid layer
        CustomPaint(
          painter: GridPainter(
            config: _gridConfig,
            canvasSize: widget.size,
          ),
        ),
        // Canvas existente
        _buildExistingCanvas(),
      ],
    );
  }

  // Ao arrastar estado
  void _onStateDragged(Offset position) {
    final snapped = GridUtils.snapToGrid(position, _gridConfig);
    // Usar posição snapped
  }
}
```

#### Zoom Controls:
```dart
// Em FSAPage, PDAPage, TMPage
class FSAPageState extends State<FSAPage> {
  ZoomConfig _zoomConfig = const ZoomConfig();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Canvas
        _buildCanvas(),

        // Zoom controls
        FloatingCanvasToolbar(
          zoomConfig: _zoomConfig,
          onZoomChanged: (config) {
            setState(() => _zoomConfig = config);
            _controller.setZoom(config.currentZoom);
          },
          onFitToContent: _controller.fitToContent,
          onCenter: _controller.centerViewport,
        ),
      ],
    );
  }
}
```

#### Stack Panel (PDA):
```dart
// Em PDAPage
class PDAPageState extends State<PDAPage> {
  StackState _currentStack = StackState(symbols: ['Z']);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCanvas()),
        PdaStackPanel(
          stackState: _currentStack,
          initialStackSymbol: widget.pda.initialStackSymbol,
          stackAlphabet: widget.pda.stackAlphabet,
          isSimulating: _isSimulating,
        ),
      ],
    );
  }

  // Atualizar durante simulação
  void _onSimulationStep(PDAConfiguration config) {
    setState(() {
      _currentStack = StackState(symbols: config.stack);
    });
  }
}
```

#### Layout Algorithms:
```dart
// Adicionar menu de layout
void _showLayoutMenu() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: LayoutAlgorithmSelector(
        algorithms: [
          CircularLayout(),
          HierarchicalLayout(),
          GridLayout(),
          ForceDirectedLayout(),
        ],
        onApply: (algorithm, positions) {
          _applyLayout(positions);
        },
      ),
    ),
  );
}

void _applyLayout(Map<String, Offset> positions) {
  for (final entry in positions.entries) {
    final state = _findState(entry.key);
    if (state != null) {
      _controller.updateStatePosition(state, entry.value);
    }
  }
}
```

#### FSA Specialized Canvas:
```dart
// Em FSAPage
class FSAPageState extends State<FSAPage> {
  DeterminismInfo _analyzeDeterminism() {
    final fsa = widget.automaton as FSA;
    return DeterminismInfo(
      isDeterministic: fsa.isDeterministic,
      hasEpsilonTransitions: fsa.hasEpsilonTransitions,
      nonDeterministicStates: _findNonDeterministicStates(fsa),
      nonDeterministicSymbols: _findNonDeterministicSymbols(fsa),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildCanvas(),
        FSACanvasOverlay(
          determinismInfo: _analyzeDeterminism(),
        ),
      ],
    );
  }
}
```

## Exemplos Executáveis

Cada arquivo contém um exemplo funcional no final. Para executar:

1. Copie o arquivo para um projeto Flutter
2. Importe no `main.dart`
3. Execute o exemplo

```dart
// main.dart
import 'package:flutter/material.dart';
import 'examples/improvements/grid_config.dart';

void main() {
  runApp(MaterialApp(
    home: GridEnabledCanvas(),
  ));
}
```

## Próximos Passos

1. **Testar** cada componente isoladamente
2. **Integrar** gradualmente na JFlutter
3. **Adicionar testes** (unit, widget, integration)
4. **Documentar** APIs públicas
5. **Otimizar** performance se necessário
6. **Coletar feedback** de usuários

## Dependências

Todos os exemplos usam apenas dependências padrão do Flutter:
- `flutter/material.dart`
- `dart:math` (para layouts)

Nenhuma dependência externa adicional é necessária.

## Contribuindo

Para adicionar novos exemplos:

1. Crie um arquivo descritivo (ex: `tm_tape_panel.dart`)
2. Inclua documentação completa
3. Adicione exemplo de uso no final do arquivo
4. Atualize este README

## Licença

Estes exemplos seguem a mesma licença da JFlutter.
