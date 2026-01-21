/// Algoritmos de layout automático para autômatos
///
/// Este arquivo demonstra como implementar algoritmos de layout automático
/// para organizar estados de forma visualmente agradável.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interface base para algoritmos de layout
abstract class LayoutAlgorithm {
  /// Calcula posições para os estados do autômato
  /// Retorna um Map de ID do estado para sua posição no canvas
  Map<String, Offset> computeLayout({
    required List<String> stateIds,
    required Map<String, List<String>> transitions,
    required String? initialStateId,
    required Set<String> finalStateIds,
    required Size canvasSize,
  });

  /// Nome do algoritmo (para UI)
  String get name;

  /// Descrição do algoritmo
  String get description;
}

/// Layout circular - distribui estados em círculo
class CircularLayout implements LayoutAlgorithm {
  @override
  String get name => 'Circular';

  @override
  String get description => 'Distribui estados uniformemente em um círculo';

  @override
  Map<String, Offset> computeLayout({
    required List<String> stateIds,
    required Map<String, List<String>> transitions,
    required String? initialStateId,
    required Set<String> finalStateIds,
    required Size canvasSize,
  }) {
    final positions = <String, Offset>{};
    final count = stateIds.length;

    if (count == 0) return positions;

    // Centro do canvas
    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;

    // Raio do círculo (80% da menor dimensão)
    final radius = math.min(centerX, centerY) * 0.7;

    // Se houver apenas 1 estado, colocar no centro
    if (count == 1) {
      positions[stateIds[0]] = Offset(centerX, centerY);
      return positions;
    }

    // Distribuir estados em círculo
    for (var i = 0; i < count; i++) {
      final angle =
          (2 * math.pi * i / count) - (math.pi / 2); // Começar no topo
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      positions[stateIds[i]] = Offset(x, y);
    }

    return positions;
  }
}

/// Layout hierárquico - organiza em níveis usando BFS
class HierarchicalLayout implements LayoutAlgorithm {
  final double levelHeight;
  final double nodeSpacing;

  HierarchicalLayout({this.levelHeight = 100.0, this.nodeSpacing = 80.0});

  @override
  String get name => 'Hierárquico';

  @override
  String get description =>
      'Organiza estados em níveis a partir do estado inicial';

  @override
  Map<String, Offset> computeLayout({
    required List<String> stateIds,
    required Map<String, List<String>> transitions,
    required String? initialStateId,
    required Set<String> finalStateIds,
    required Size canvasSize,
  }) {
    final positions = <String, Offset>{};

    if (stateIds.isEmpty) return positions;

    // Se não houver estado inicial, usar o primeiro
    final startState = initialStateId ?? stateIds.first;

    // BFS para determinar níveis
    final levels = <int, List<String>>{};
    final visited = <String>{};
    final queue = <({String id, int level})>[];

    queue.add((id: startState, level: 0));
    visited.add(startState);

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      levels.putIfAbsent(current.level, () => []).add(current.id);

      // Adicionar vizinhos
      final neighbors = transitions[current.id] ?? [];
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add((id: neighbor, level: current.level + 1));
        }
      }
    }

    // Adicionar estados não visitados (desconectados) em nível separado
    final unvisited = stateIds.where((id) => !visited.contains(id)).toList();
    if (unvisited.isNotEmpty) {
      final maxLevel = levels.keys.isEmpty ? 0 : levels.keys.reduce(math.max);
      levels[maxLevel + 2] = unvisited;
    }

    // Calcular posições
    final maxLevel = levels.keys.isEmpty ? 0 : levels.keys.reduce(math.max);
    const startY = 50.0;

    for (final entry in levels.entries) {
      final level = entry.key;
      final nodesInLevel = entry.value;
      final count = nodesInLevel.length;

      // Calcular espaçamento horizontal
      final totalWidth = count * nodeSpacing;
      final startX = (canvasSize.width - totalWidth) / 2 + nodeSpacing / 2;

      for (var i = 0; i < count; i++) {
        final x = startX + i * nodeSpacing;
        final y = startY + level * levelHeight;
        positions[nodesInLevel[i]] = Offset(x, y);
      }
    }

    return positions;
  }
}

/// Layout em grade - organiza estados em uma grade regular
class GridLayout implements LayoutAlgorithm {
  final int columns;
  final double cellWidth;
  final double cellHeight;

  GridLayout({
    this.columns = 4,
    this.cellWidth = 120.0,
    this.cellHeight = 100.0,
  });

  @override
  String get name => 'Grade';

  @override
  String get description => 'Organiza estados em uma grade regular';

  @override
  Map<String, Offset> computeLayout({
    required List<String> stateIds,
    required Map<String, List<String>> transitions,
    required String? initialStateId,
    required Set<String> finalStateIds,
    required Size canvasSize,
  }) {
    final positions = <String, Offset>{};
    final count = stateIds.length;

    if (count == 0) return positions;

    // Calcular número de linhas necessárias
    final rows = (count / columns).ceil();

    // Centralizar a grade no canvas
    final totalWidth = columns * cellWidth;
    final totalHeight = rows * cellHeight;
    final startX = (canvasSize.width - totalWidth) / 2 + cellWidth / 2;
    final startY = (canvasSize.height - totalHeight) / 2 + cellHeight / 2;

    for (var i = 0; i < count; i++) {
      final row = i ~/ columns;
      final col = i % columns;
      final x = startX + col * cellWidth;
      final y = startY + row * cellHeight;
      positions[stateIds[i]] = Offset(x, y);
    }

    return positions;
  }
}

/// Layout Force-Directed (simulação física)
class ForceDirectedLayout implements LayoutAlgorithm {
  final int iterations;
  final double repulsionStrength;
  final double attractionStrength;
  final double damping;

  ForceDirectedLayout({
    this.iterations = 100,
    this.repulsionStrength = 5000.0,
    this.attractionStrength = 0.01,
    this.damping = 0.9,
  });

  @override
  String get name => 'Force-Directed';

  @override
  String get description => 'Usa simulação física para organizar estados';

  @override
  Map<String, Offset> computeLayout({
    required List<String> stateIds,
    required Map<String, List<String>> transitions,
    required String? initialStateId,
    required Set<String> finalStateIds,
    required Size canvasSize,
  }) {
    final positions = <String, Offset>{};
    final velocities = <String, Offset>{};

    if (stateIds.isEmpty) return positions;

    // Inicializar posições aleatórias
    final random = math.Random(42); // Seed fixo para consistência
    for (final id in stateIds) {
      positions[id] = Offset(
        random.nextDouble() * canvasSize.width,
        random.nextDouble() * canvasSize.height,
      );
      velocities[id] = Offset.zero;
    }

    // Simulação
    for (var iteration = 0; iteration < iterations; iteration++) {
      final forces = <String, Offset>{};

      // Inicializar forças
      for (final id in stateIds) {
        forces[id] = Offset.zero;
      }

      // Força de repulsão entre todos os pares de nós
      for (var i = 0; i < stateIds.length; i++) {
        for (var j = i + 1; j < stateIds.length; j++) {
          final id1 = stateIds[i];
          final id2 = stateIds[j];
          final pos1 = positions[id1]!;
          final pos2 = positions[id2]!;

          final delta = pos1 - pos2;
          final distance = math.max(delta.distance, 1.0);
          final force =
              delta / distance * (repulsionStrength / (distance * distance));

          forces[id1] = forces[id1]! + force;
          forces[id2] = forces[id2]! - force;
        }
      }

      // Força de atração entre nós conectados
      for (final entry in transitions.entries) {
        final from = entry.key;
        final targets = entry.value;

        for (final to in targets) {
          if (!positions.containsKey(to)) continue;

          final pos1 = positions[from]!;
          final pos2 = positions[to]!;

          final delta = pos2 - pos1;
          final distance = delta.distance;
          final force = delta * attractionStrength * distance;

          forces[from] = forces[from]! + force;
          forces[to] = forces[to]! - force;
        }
      }

      // Atualizar velocidades e posições
      for (final id in stateIds) {
        velocities[id] = (velocities[id]! + forces[id]!) * damping;
        positions[id] = positions[id]! + velocities[id]!;

        // Manter dentro dos limites
        final pos = positions[id]!;
        positions[id] = Offset(
          pos.dx.clamp(50.0, canvasSize.width - 50.0),
          pos.dy.clamp(50.0, canvasSize.height - 50.0),
        );
      }
    }

    return positions;
  }
}

/// Widget de seleção de algoritmo de layout
class LayoutAlgorithmSelector extends StatelessWidget {
  final List<LayoutAlgorithm> algorithms;
  final LayoutAlgorithm? selectedAlgorithm;
  final ValueChanged<LayoutAlgorithm>? onAlgorithmSelected;
  final VoidCallback? onApply;

  const LayoutAlgorithmSelector({
    super.key,
    required this.algorithms,
    this.selectedAlgorithm,
    this.onAlgorithmSelected,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Layout Automático',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...algorithms.map((algorithm) {
              final isSelected = selectedAlgorithm == algorithm;
              return RadioListTile<LayoutAlgorithm>(
                title: Text(algorithm.name),
                subtitle: Text(
                  algorithm.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: algorithm,
                groupValue: selectedAlgorithm,
                onChanged: (value) {
                  if (value != null && onAlgorithmSelected != null) {
                    onAlgorithmSelected!(value);
                  }
                },
                dense: true,
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedAlgorithm != null ? onApply : null,
                child: const Text('Aplicar Layout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview de layout antes de aplicar
class LayoutPreview extends StatelessWidget {
  final Map<String, Offset> positions;
  final Size previewSize;
  final String? initialStateId;
  final Set<String> finalStateIds;

  const LayoutPreview({
    super.key,
    required this.positions,
    this.previewSize = const Size(300, 200),
    this.initialStateId,
    this.finalStateIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: previewSize.width,
      height: previewSize.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _LayoutPreviewPainter(
          positions: positions,
          initialStateId: initialStateId,
          finalStateIds: finalStateIds,
        ),
      ),
    );
  }
}

class _LayoutPreviewPainter extends CustomPainter {
  final Map<String, Offset> positions;
  final String? initialStateId;
  final Set<String> finalStateIds;

  _LayoutPreviewPainter({
    required this.positions,
    this.initialStateId,
    this.finalStateIds = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;

    // Calcular bounds
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final pos in positions.values) {
      minX = math.min(minX, pos.dx);
      minY = math.min(minY, pos.dy);
      maxX = math.max(maxX, pos.dx);
      maxY = math.max(maxY, pos.dy);
    }

    // Calcular escala
    final boundsWidth = maxX - minX;
    final boundsHeight = maxY - minY;
    final scaleX = boundsWidth > 0 ? (size.width - 40) / boundsWidth : 1.0;
    final scaleY = boundsHeight > 0 ? (size.height - 40) / boundsHeight : 1.0;
    final scale = math.min(scaleX, scaleY);

    // Offset para centralizar
    final offsetX = (size.width - boundsWidth * scale) / 2 - minX * scale;
    final offsetY = (size.height - boundsHeight * scale) / 2 - minY * scale;

    // Desenhar estados
    final statePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue[100]!;

    final initialPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green[100]!;

    final finalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.blue;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.blue;

    for (final entry in positions.entries) {
      final id = entry.key;
      final pos = entry.value;
      final scaledPos = Offset(
        pos.dx * scale + offsetX,
        pos.dy * scale + offsetY,
      );

      // Desenhar círculo
      final paint = id == initialStateId ? initialPaint : statePaint;
      canvas.drawCircle(scaledPos, 8, paint);
      canvas.drawCircle(scaledPos, 8, borderPaint);

      // Desenhar círculo duplo para estados finais
      if (finalStateIds.contains(id)) {
        canvas.drawCircle(scaledPos, 11, finalPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_LayoutPreviewPainter oldDelegate) {
    return oldDelegate.positions != positions;
  }
}

/// Exemplo de uso
class LayoutAlgorithmExample extends StatefulWidget {
  const LayoutAlgorithmExample({super.key});

  @override
  State<LayoutAlgorithmExample> createState() => _LayoutAlgorithmExampleState();
}

class _LayoutAlgorithmExampleState extends State<LayoutAlgorithmExample> {
  final List<LayoutAlgorithm> _algorithms = [
    CircularLayout(),
    HierarchicalLayout(),
    GridLayout(),
    ForceDirectedLayout(),
  ];

  LayoutAlgorithm? _selectedAlgorithm;
  Map<String, Offset> _positions = {};

  // Dados de exemplo
  final List<String> _stateIds = ['q0', 'q1', 'q2', 'q3', 'q4'];
  final Map<String, List<String>> _transitions = {
    'q0': ['q1', 'q2'],
    'q1': ['q2', 'q3'],
    'q2': ['q4'],
    'q3': ['q4'],
    'q4': [],
  };
  final String _initialState = 'q0';
  final Set<String> _finalStates = {'q4'};

  void _applyLayout() {
    if (_selectedAlgorithm == null) return;

    setState(() {
      _positions = _selectedAlgorithm!.computeLayout(
        stateIds: _stateIds,
        transitions: _transitions,
        initialStateId: _initialState,
        finalStateIds: _finalStates,
        canvasSize: const Size(600, 400),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Layout Algorithm Example')),
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: LayoutAlgorithmSelector(
              algorithms: _algorithms,
              selectedAlgorithm: _selectedAlgorithm,
              onAlgorithmSelected: (algorithm) {
                setState(() {
                  _selectedAlgorithm = algorithm;
                });
              },
              onApply: _applyLayout,
            ),
          ),
          Expanded(
            child: Center(
              child: _positions.isEmpty
                  ? const Text('Selecione um algoritmo e clique em Aplicar')
                  : LayoutPreview(
                      positions: _positions,
                      previewSize: const Size(600, 400),
                      initialStateId: _initialState,
                      finalStateIds: _finalStates,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
