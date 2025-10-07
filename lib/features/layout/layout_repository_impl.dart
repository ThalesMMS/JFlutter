//
//  layout_repository_impl.dart
//  JFlutter
//
//  Implementação do LayoutRepository que aplica diferentes heurísticas de
//  posicionamento automático para autômatos, incluindo distribuições radiais,
//  grade balanceada, padrões compactos em espiral e organização hierárquica.
//  O repositório calcula áreas seguras, mescla estados reposicionados e retorna
//  resultados encapsulados em AutomatonResult.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../core/result.dart';

class LayoutRepositoryImpl implements LayoutRepository {
  static final Vector2 _canvasSize = Vector2(800, 600);
  static const double _canvasPadding = 60;
  static const double _minLayoutSize = 160;
  static final double _goldenAngle = math.pi * (3 - math.sqrt(5));

  static Vector2 get _canvasCenter =>
      Vector2(_canvasSize.x / 2, _canvasSize.y / 2);

  @override
  Future<AutomatonResult> applyAutoLayout(AutomatonEntity automaton) async {
    final states = automaton.states;
    if (states.isEmpty) {
      return Success(automaton);
    }

    final center = Vector2(400, 300); // Assuming a canvas center
    final radius = math.min(center.x, center.y) - 50;
    final angleStep = (2 * math.pi) / states.length;

    final newStates = <StateEntity>[];
    for (int i = 0; i < states.length; i++) {
      final angle = i * angleStep;
      final x = center.x + radius * math.cos(angle);
      final y = center.y + radius * math.sin(angle);
      newStates.add(states[i].copyWith(x: x, y: y));
    }

    final positionedStates = _mergeStates(states, newStates);
    return Success(automaton.copyWith(states: positionedStates));
  }

  @override
  Future<AutomatonResult> applyBalancedLayout(AutomatonEntity automaton) async {
    final states = automaton.states;
    if (states.isEmpty) {
      return Success(automaton);
    }

    final area = _computeLayoutArea(states);
    final columns = area.columns;
    int rows = (states.length / columns).ceil();
    if (rows < 1) rows = 1;

    final newStates = <StateEntity>[];
    final double top = area.center.y - area.height / 2;
    final double verticalSpacing = rows > 1 ? area.height / (rows - 1) : 0;

    int index = 0;
    for (int row = 0; row < rows; row++) {
      if (index >= states.length) break;
      final remaining = states.length - index;
      final itemsInRow = row == rows - 1
          ? remaining
          : (remaining < columns ? remaining : columns);

      final horizontalSpacing = itemsInRow > 1
          ? area.width / (itemsInRow - 1)
          : 0;
      final effectiveWidth = horizontalSpacing * (itemsInRow - 1);
      final startX = itemsInRow > 1
          ? area.center.x - effectiveWidth / 2
          : area.center.x;

      for (int col = 0; col < itemsInRow; col++) {
        if (index >= states.length) break;
        final state = states[index];
        final x = startX + col * horizontalSpacing;
        final y = rows == 1 ? area.center.y : top + row * verticalSpacing;
        newStates.add(state.copyWith(x: x, y: y));
        index++;
      }
    }

    final positionedStates = _mergeStates(states, newStates);
    return Success(automaton.copyWith(states: positionedStates));
  }

  @override
  Future<AutomatonResult> applyCompactLayout(AutomatonEntity automaton) async {
    final states = automaton.states;
    if (states.isEmpty) {
      return Success(automaton);
    }

    final area = _computeLayoutArea(states, scaleX: 0.8, scaleY: 0.8);
    final center = area.center;
    final maxRadiusX = area.width / 2;
    final maxRadiusY = area.height / 2;
    final maxRadius = math.min(maxRadiusX, maxRadiusY);
    final spacing =
        maxRadius / math.max(1, math.sqrt(states.length.toDouble()));

    final newStates = <StateEntity>[];
    for (int i = 0; i < states.length; i++) {
      final angle = i * _goldenAngle;
      final radius = spacing * math.sqrt(i + 1);
      final target = Vector2(
        center.x + math.cos(angle) * radius,
        center.y + math.sin(angle) * radius,
      );
      final clamped = _clampToArea(target, center, maxRadiusX, maxRadiusY);
      newStates.add(states[i].copyWith(x: clamped.x, y: clamped.y));
    }

    final positionedStates = _mergeStates(states, newStates);
    return Success(automaton.copyWith(states: positionedStates));
  }

  @override
  Future<AutomatonResult> applyHierarchicalLayout(
    AutomatonEntity automaton,
  ) async {
    final states = automaton.states;
    if (states.isEmpty) {
      return Success(automaton);
    }

    final stateById = {for (final s in states) s.id: s};
    final adjacency = <String, Set<String>>{};
    for (final entry in automaton.transitions.entries) {
      final from = entry.key.split('|').first;
      adjacency.putIfAbsent(from, () => <String>{}).addAll(entry.value);
    }

    final visited = <String>{};
    final layers = <List<StateEntity>>[];
    final queue = Queue<(String, int)>();

    if (automaton.initialId != null &&
        stateById.containsKey(automaton.initialId)) {
      queue.add((automaton.initialId!, 0));
    }

    for (final state in states) {
      if (queue.any((entry) => entry.$1 == state.id)) continue;
      if (state.id == automaton.initialId) continue;
      queue.add((state.id, 0));
    }

    while (queue.isNotEmpty) {
      final (id, depth) = queue.removeFirst();
      if (visited.contains(id)) {
        continue;
      }
      final state = stateById[id];
      if (state == null) {
        continue;
      }
      visited.add(id);
      while (layers.length <= depth) {
        layers.add(<StateEntity>[]);
      }
      layers[depth].add(state);

      for (final neighbor in adjacency[id] ?? const <String>{}) {
        if (!visited.contains(neighbor) && stateById.containsKey(neighbor)) {
          queue.add((neighbor, depth + 1));
        }
      }
    }

    final remaining = states.where((s) => !visited.contains(s.id));
    for (final state in remaining) {
      layers.add([state]);
    }

    final area = _computeLayoutArea(states, scaleX: 1.1, scaleY: 1.3);
    final newStates = <StateEntity>[];
    final left = area.center.x - area.width / 2;
    final top = area.center.y - area.height / 2;
    final verticalSpacing = layers.length > 1
        ? area.height / (layers.length - 1)
        : 0;

    for (int i = 0; i < layers.length; i++) {
      final layerStates = layers[i];
      if (layerStates.isEmpty) continue;
      final y = layers.length == 1 ? area.center.y : top + i * verticalSpacing;
      final count = layerStates.length;
      final horizontalSpacing = count > 1 ? area.width / (count - 1) : 0;
      final startX = count > 1 ? left : area.center.x;

      for (int j = 0; j < layerStates.length; j++) {
        final state = layerStates[j];
        final x = count > 1 ? startX + j * horizontalSpacing : startX;
        newStates.add(state.copyWith(x: x, y: y));
      }
    }

    final positionedStates = _mergeStates(states, newStates);
    return Success(automaton.copyWith(states: positionedStates));
  }

  @override
  Future<AutomatonResult> applySpreadLayout(AutomatonEntity automaton) async {
    final states = automaton.states;
    if (states.isEmpty) {
      return Success(automaton);
    }

    if (states.length == 1) {
      final area = _computeLayoutArea(states, scaleX: 1.2, scaleY: 1.2);
      return Success(
        automaton.copyWith(
          states: [states.first.copyWith(x: area.center.x, y: area.center.y)],
        ),
      );
    }

    final area = _computeLayoutArea(states, scaleX: 1.2, scaleY: 1.2);
    final maxRadiusX = area.width / 2;
    final maxRadiusY = area.height / 2;
    final rings = math.max(1, math.sqrt(states.length).ceil());
    final perRing = (states.length / rings).ceil();

    final newStates = <StateEntity>[];
    int processed = 0;
    for (int ring = 0; ring < rings && processed < states.length; ring++) {
      final remaining = states.length - processed;
      final ringSize = ring == rings - 1
          ? remaining
          : math.min(perRing, remaining);
      final ringFactor = rings == 1 ? 1.0 : (ring + 1) / rings;
      final radiusX = maxRadiusX * ringFactor;
      final radiusY = maxRadiusY * ringFactor;

      for (int i = 0; i < ringSize; i++) {
        final state = states[processed + i];
        final angle = (2 * math.pi * i) / ringSize;
        final x = area.center.x + math.cos(angle) * radiusX;
        final y = area.center.y + math.sin(angle) * radiusY;
        newStates.add(state.copyWith(x: x, y: y));
      }
      processed += ringSize;
    }

    final positionedStates = _mergeStates(states, newStates);
    return Success(automaton.copyWith(states: positionedStates));
  }

  @override
  Future<AutomatonResult> centerAutomaton(AutomatonEntity automaton) async {
    final states = automaton.states;
    if (states.isEmpty) {
      return Success(automaton);
    }

    final centroid = _computeCentroid(states);
    final offset = _canvasCenter - centroid;
    final newStates = [
      for (final state in states)
        state.copyWith(x: state.x + offset.x, y: state.y + offset.y),
    ];

    return Success(automaton.copyWith(states: newStates));
  }
}

class _Bounds {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const _Bounds({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  double get width => maxX - minX;
  double get height => maxY - minY;

  Vector2 get center => Vector2((minX + maxX) / 2, (minY + maxY) / 2);

  factory _Bounds.fromStates(List<StateEntity> states) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final state in states) {
      if (state.x < minX) minX = state.x;
      if (state.y < minY) minY = state.y;
      if (state.x > maxX) maxX = state.x;
      if (state.y > maxY) maxY = state.y;
    }

    if (minX == double.infinity) {
      return const _Bounds(minX: 0, minY: 0, maxX: 0, maxY: 0);
    }

    return _Bounds(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }
}

class _LayoutArea {
  final Vector2 center;
  final double width;
  final double height;
  final int columns;

  const _LayoutArea({
    required this.center,
    required this.width,
    required this.height,
    required this.columns,
  });
}

_LayoutArea _computeLayoutArea(
  List<StateEntity> states, {
  double scaleX = 1.0,
  double scaleY = 1.0,
}) {
  final bounds = _Bounds.fromStates(states);
  final baseCenter = bounds.center;
  final width = _scaledDimension(
    bounds.width,
    scaleX,
    LayoutRepositoryImpl._canvasSize.x,
  );
  final height = _scaledDimension(
    bounds.height,
    scaleY,
    LayoutRepositoryImpl._canvasSize.y,
  );
  final center = _adjustCenter(baseCenter, width, height);
  int columns = math.sqrt(states.length).ceil();
  if (columns < 1) {
    columns = 1;
  }

  return _LayoutArea(
    center: center,
    width: width,
    height: height,
    columns: columns,
  );
}

double _scaledDimension(double original, double scale, double canvasDimension) {
  final available = math.max(
    1.0,
    canvasDimension - 2 * LayoutRepositoryImpl._canvasPadding,
  );
  final minSize = math.min(LayoutRepositoryImpl._minLayoutSize, available);
  final base = math.max(original.abs(), LayoutRepositoryImpl._minLayoutSize);
  final scaled = base * scale;
  final clamped = scaled.clamp(minSize, available);
  return clamped.toDouble();
}

Vector2 _adjustCenter(Vector2 desired, double width, double height) {
  final halfWidth = width / 2;
  final halfHeight = height / 2;
  final minX = LayoutRepositoryImpl._canvasPadding + halfWidth;
  final maxX =
      LayoutRepositoryImpl._canvasSize.x -
      LayoutRepositoryImpl._canvasPadding -
      halfWidth;
  final minY = LayoutRepositoryImpl._canvasPadding + halfHeight;
  final maxY =
      LayoutRepositoryImpl._canvasSize.y -
      LayoutRepositoryImpl._canvasPadding -
      halfHeight;

  final x = desired.x.clamp(minX, maxX);
  final y = desired.y.clamp(minY, maxY);
  return Vector2(x.toDouble(), y.toDouble());
}

Vector2 _clampToArea(
  Vector2 point,
  Vector2 center,
  double radiusX,
  double radiusY,
) {
  final minX = center.x - radiusX;
  final maxX = center.x + radiusX;
  final minY = center.y - radiusY;
  final maxY = center.y + radiusY;

  return Vector2(
    point.x.clamp(minX, maxX).toDouble(),
    point.y.clamp(minY, maxY).toDouble(),
  );
}

Vector2 _computeCentroid(List<StateEntity> states) {
  double sumX = 0;
  double sumY = 0;
  for (final state in states) {
    sumX += state.x;
    sumY += state.y;
  }
  return Vector2(sumX / states.length, sumY / states.length);
}

List<StateEntity> _mergeStates(
  List<StateEntity> original,
  Iterable<StateEntity> positioned,
) {
  final positionedById = <String, StateEntity>{
    for (final state in positioned) state.id: state,
  };

  return [for (final state in original) positionedById[state.id] ?? state];
}
