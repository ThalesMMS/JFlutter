/// Controles de zoom e navegação para o canvas
///
/// Este arquivo demonstra como implementar controles visuais de zoom
/// e navegação para melhorar a experiência do usuário no canvas.
library;

import 'package:flutter/material.dart';

/// Configuração de zoom do canvas
class ZoomConfig {
  final double minZoom;
  final double maxZoom;
  final double zoomStep;
  final double currentZoom;

  const ZoomConfig({
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
    this.zoomStep = 0.1,
    this.currentZoom = 1.0,
  });

  ZoomConfig copyWith({
    double? minZoom,
    double? maxZoom,
    double? zoomStep,
    double? currentZoom,
  }) {
    return ZoomConfig(
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      zoomStep: zoomStep ?? this.zoomStep,
      currentZoom: currentZoom ?? this.currentZoom,
    );
  }

  /// Aumenta o zoom
  ZoomConfig zoomIn() {
    final newZoom = (currentZoom + zoomStep).clamp(minZoom, maxZoom);
    return copyWith(currentZoom: newZoom);
  }

  /// Diminui o zoom
  ZoomConfig zoomOut() {
    final newZoom = (currentZoom - zoomStep).clamp(minZoom, maxZoom);
    return copyWith(currentZoom: newZoom);
  }

  /// Reset para 100%
  ZoomConfig reset() {
    return copyWith(currentZoom: 1.0);
  }

  /// Define zoom específico
  ZoomConfig setZoom(double zoom) {
    return copyWith(currentZoom: zoom.clamp(minZoom, maxZoom));
  }

  /// Retorna a porcentagem de zoom
  int get zoomPercent => (currentZoom * 100).round();
}

/// Widget de controles de zoom
class ZoomControls extends StatelessWidget {
  final ZoomConfig config;
  final ValueChanged<ZoomConfig> onZoomChanged;
  final VoidCallback? onFitToContent;
  final VoidCallback? onCenter;

  const ZoomControls({
    super.key,
    required this.config,
    required this.onZoomChanged,
    this.onFitToContent,
    this.onCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom Out
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Zoom Out (${config.minZoom * 100}%)',
            onPressed: config.currentZoom > config.minZoom
                ? () => onZoomChanged(config.zoomOut())
                : null,
          ),

          const SizedBox(width: 4),

          // Porcentagem atual (clicável para resetar)
          InkWell(
            onTap: () => onZoomChanged(config.reset()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${config.zoomPercent}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Zoom In
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Zoom In (${config.maxZoom * 100}%)',
            onPressed: config.currentZoom < config.maxZoom
                ? () => onZoomChanged(config.zoomIn())
                : null,
          ),

          if (onFitToContent != null) ...[
            const SizedBox(width: 8),
            const VerticalDivider(width: 1),
            const SizedBox(width: 8),

            // Fit to Content
            IconButton(
              icon: const Icon(Icons.fit_screen),
              tooltip: 'Fit to Content',
              onPressed: onFitToContent,
            ),
          ],

          if (onCenter != null) ...[
            const SizedBox(width: 4),

            // Center
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              tooltip: 'Center',
              onPressed: onCenter,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de slider de zoom (alternativa)
class ZoomSlider extends StatelessWidget {
  final ZoomConfig config;
  final ValueChanged<ZoomConfig> onZoomChanged;

  const ZoomSlider({
    super.key,
    required this.config,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.zoom_out, size: 20),
              Expanded(
                child: Slider(
                  value: config.currentZoom,
                  min: config.minZoom,
                  max: config.maxZoom,
                  divisions:
                      ((config.maxZoom - config.minZoom) / config.zoomStep)
                          .round(),
                  label: '${config.zoomPercent}%',
                  onChanged: (value) {
                    onZoomChanged(config.setZoom(value));
                  },
                ),
              ),
              const Icon(Icons.zoom_in, size: 20),
            ],
          ),
          Text(
            '${config.zoomPercent}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Mini-mapa para navegação
class MiniMap extends StatelessWidget {
  final Size canvasSize;
  final Rect viewport;
  final List<Offset> statePositions;
  final ValueChanged<Offset>? onTap;

  const MiniMap({
    super.key,
    required this.canvasSize,
    required this.viewport,
    this.statePositions = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTapDown: (details) {
          if (onTap != null) {
            // Converter coordenadas do mini-mapa para coordenadas do canvas
            final localPosition = details.localPosition;
            final canvasX = (localPosition.dx / 150) * canvasSize.width;
            final canvasY = (localPosition.dy / 100) * canvasSize.height;
            onTap!(Offset(canvasX, canvasY));
          }
        },
        child: CustomPaint(
          painter: _MiniMapPainter(
            canvasSize: canvasSize,
            viewport: viewport,
            statePositions: statePositions,
          ),
        ),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  final Size canvasSize;
  final Rect viewport;
  final List<Offset> statePositions;

  _MiniMapPainter({
    required this.canvasSize,
    required this.viewport,
    required this.statePositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calcular escala
    final scaleX = size.width / canvasSize.width;
    final scaleY = size.height / canvasSize.height;

    // Desenhar fundo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey[100]!,
    );

    // Desenhar estados
    final statePaint = Paint()
      ..color = Colors.blue[300]!
      ..style = PaintingStyle.fill;

    for (final position in statePositions) {
      canvas.drawCircle(
        Offset(position.dx * scaleX, position.dy * scaleY),
        2,
        statePaint,
      );
    }

    // Desenhar viewport
    final viewportRect = Rect.fromLTWH(
      viewport.left * scaleX,
      viewport.top * scaleY,
      viewport.width * scaleX,
      viewport.height * scaleY,
    );

    canvas.drawRect(
      viewportRect,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRect(
      viewportRect,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_MiniMapPainter oldDelegate) {
    return oldDelegate.viewport != viewport ||
        oldDelegate.statePositions != statePositions;
  }
}

/// Barra de ferramentas flutuante completa
class FloatingCanvasToolbar extends StatelessWidget {
  final ZoomConfig zoomConfig;
  final ValueChanged<ZoomConfig> onZoomChanged;
  final VoidCallback? onFitToContent;
  final VoidCallback? onCenter;
  final bool showMiniMap;
  final Size? canvasSize;
  final Rect? viewport;
  final List<Offset>? statePositions;
  final ValueChanged<Offset>? onMiniMapTap;

  const FloatingCanvasToolbar({
    super.key,
    required this.zoomConfig,
    required this.onZoomChanged,
    this.onFitToContent,
    this.onCenter,
    this.showMiniMap = false,
    this.canvasSize,
    this.viewport,
    this.statePositions,
    this.onMiniMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showMiniMap && canvasSize != null && viewport != null) ...[
            MiniMap(
              canvasSize: canvasSize!,
              viewport: viewport!,
              statePositions: statePositions ?? [],
              onTap: onMiniMapTap,
            ),
            const SizedBox(height: 8),
          ],
          ZoomControls(
            config: zoomConfig,
            onZoomChanged: onZoomChanged,
            onFitToContent: onFitToContent,
            onCenter: onCenter,
          ),
        ],
      ),
    );
  }
}
