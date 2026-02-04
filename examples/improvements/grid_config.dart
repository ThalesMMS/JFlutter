/// Configuração do sistema de grid para o canvas
///
/// Este arquivo demonstra como implementar um sistema de grid com snap-to-grid
/// para melhorar o posicionamento de estados no canvas.
library;

import 'package:flutter/material.dart';

/// Configuração do grid do canvas
class GridConfig {
  /// Se o grid está habilitado
  final bool enabled;

  /// Tamanho de cada célula do grid em pixels
  final double gridSize;

  /// Se as linhas do grid devem ser mostradas
  final bool showGrid;

  /// Se os estados devem se alinhar automaticamente ao grid
  final bool snapToGrid;

  /// Cor das linhas do grid
  final Color gridColor;

  /// Opacidade das linhas do grid
  final double gridOpacity;

  /// Espessura das linhas do grid
  final double gridLineWidth;

  const GridConfig({
    this.enabled = false,
    this.gridSize = 50.0,
    this.showGrid = true,
    this.snapToGrid = true,
    this.gridColor = Colors.grey,
    this.gridOpacity = 0.2,
    this.gridLineWidth = 1.0,
  });

  GridConfig copyWith({
    bool? enabled,
    double? gridSize,
    bool? showGrid,
    bool? snapToGrid,
    Color? gridColor,
    double? gridOpacity,
    double? gridLineWidth,
  }) {
    return GridConfig(
      enabled: enabled ?? this.enabled,
      gridSize: gridSize ?? this.gridSize,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridColor: gridColor ?? this.gridColor,
      gridOpacity: gridOpacity ?? this.gridOpacity,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
    );
  }
}

/// Painter para desenhar o grid no canvas
class GridPainter extends CustomPainter {
  final GridConfig config;
  final Size canvasSize;

  GridPainter({required this.config, required this.canvasSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (!config.enabled || !config.showGrid) return;

    final paint = Paint()
      ..color = config.gridColor.withValues(alpha: config.gridOpacity)
      ..strokeWidth = config.gridLineWidth
      ..style = PaintingStyle.stroke;

    // Desenhar linhas verticais
    for (double x = 0; x <= canvasSize.width; x += config.gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, canvasSize.height), paint);
    }

    // Desenhar linhas horizontais
    for (double y = 0; y <= canvasSize.height; y += config.gridSize) {
      canvas.drawLine(Offset(0, y), Offset(canvasSize.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.canvasSize != canvasSize;
  }
}

/// Utilidades para trabalhar com grid
class GridUtils {
  /// Ajusta uma posição para o grid mais próximo
  static Offset snapToGrid(Offset position, GridConfig config) {
    if (!config.enabled || !config.snapToGrid) {
      return position;
    }

    final x = (position.dx / config.gridSize).round() * config.gridSize;
    final y = (position.dy / config.gridSize).round() * config.gridSize;

    return Offset(x.toDouble(), y.toDouble());
  }

  /// Calcula a distância até o ponto de grid mais próximo
  static double distanceToNearestGridPoint(Offset position, GridConfig config) {
    final snapped = snapToGrid(position, config);
    return (position - snapped).distance;
  }

  /// Verifica se uma posição está "próxima" de um ponto do grid
  static bool isNearGridPoint(
    Offset position,
    GridConfig config, {
    double threshold = 10.0,
  }) {
    return distanceToNearestGridPoint(position, config) < threshold;
  }
}

/// Widget de controle do grid
class GridControls extends StatelessWidget {
  final GridConfig config;
  final ValueChanged<GridConfig> onConfigChanged;

  const GridControls({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grid', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Habilitar Grid'),
              value: config.enabled,
              dense: true,
              onChanged: (value) {
                onConfigChanged(config.copyWith(enabled: value));
              },
            ),
            if (config.enabled) ...[
              SwitchListTile(
                title: const Text('Mostrar Linhas'),
                value: config.showGrid,
                dense: true,
                onChanged: (value) {
                  onConfigChanged(config.copyWith(showGrid: value));
                },
              ),
              SwitchListTile(
                title: const Text('Snap to Grid'),
                value: config.snapToGrid,
                dense: true,
                onChanged: (value) {
                  onConfigChanged(config.copyWith(snapToGrid: value));
                },
              ),
              ListTile(
                title: const Text('Tamanho da Célula'),
                dense: true,
                subtitle: Slider(
                  value: config.gridSize,
                  min: 20,
                  max: 100,
                  divisions: 8,
                  label: '${config.gridSize.toInt()}px',
                  onChanged: (value) {
                    onConfigChanged(config.copyWith(gridSize: value));
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Exemplo de uso em um canvas
class GridEnabledCanvas extends StatefulWidget {
  const GridEnabledCanvas({super.key});

  @override
  State<GridEnabledCanvas> createState() => _GridEnabledCanvasState();
}

class _GridEnabledCanvasState extends State<GridEnabledCanvas> {
  GridConfig _gridConfig = const GridConfig(enabled: true);
  final List<Offset> _points = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grid Example')),
      body: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                setState(() {
                  final position = details.localPosition;
                  final snapped = GridUtils.snapToGrid(position, _gridConfig);
                  _points.add(snapped);
                });
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: GridPainter(
                  config: _gridConfig,
                  canvasSize: const Size(800, 600),
                ),
                foregroundPainter: _PointsPainter(points: _points),
              ),
            ),
          ),
          SizedBox(
            width: 250,
            child: GridControls(
              config: _gridConfig,
              onConfigChanged: (config) {
                setState(() {
                  _gridConfig = config;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsPainter extends CustomPainter {
  final List<Offset> points;

  _PointsPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 5, paint);
    }
  }

  @override
  bool shouldRepaint(_PointsPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
