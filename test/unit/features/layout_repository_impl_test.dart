import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/lib/core/entities/automaton_entity.dart';
import 'package:jflutter/lib/features/layout/layout_repository_impl.dart';

void main() {
  late LayoutRepositoryImpl repository;

  setUp(() {
    repository = LayoutRepositoryImpl();
  });

  AutomatonEntity buildAutomaton() {
    return const AutomatonEntity(
      id: 'auto',
      name: 'Test',
      alphabet: {'0', '1'},
      states: [
        StateEntity(
          id: 'q0',
          name: 'q0',
          x: 60,
          y: 80,
          isInitial: true,
          isFinal: false,
        ),
        StateEntity(
          id: 'q1',
          name: 'q1',
          x: 280,
          y: 120,
          isInitial: false,
          isFinal: false,
        ),
        StateEntity(
          id: 'q2',
          name: 'q2',
          x: 520,
          y: 160,
          isInitial: false,
          isFinal: false,
        ),
        StateEntity(
          id: 'q3',
          name: 'q3',
          x: 140,
          y: 360,
          isInitial: false,
          isFinal: false,
        ),
        StateEntity(
          id: 'q4',
          name: 'q4',
          x: 420,
          y: 380,
          isInitial: false,
          isFinal: false,
        ),
        StateEntity(
          id: 'q5',
          name: 'q5',
          x: 660,
          y: 420,
          isInitial: false,
          isFinal: true,
        ),
      ],
      transitions: {
        'q0|0': ['q1', 'q2'],
        'q1|1': ['q3'],
        'q2|0': ['q3'],
        'q3|1': ['q4'],
        'q4|0': ['q5'],
      },
      initialId: 'q0',
      nextId: 6,
      type: AutomatonType.dfa,
    );
  }

  test('balanced layout arranges states in grid within canvas bounds', () async {
    final automaton = buildAutomaton();
    final result = await repository.applyBalancedLayout(automaton);

    expect(result.isSuccess, isTrue);
    final laidOut = result.data!;
    expect(laidOut.states, hasLength(automaton.states.length));

    final bounds = _boundsOf(laidOut.states);
    expect(bounds.width, greaterThan(0));
    expect(bounds.height, greaterThan(0));
    expect(_withinCanvas(bounds), isTrue);
  });

  test('compact layout keeps automaton tighter than original bounds', () async {
    final automaton = buildAutomaton();
    final originalBounds = _boundsOf(automaton.states);

    final result = await repository.applyCompactLayout(automaton);

    expect(result.isSuccess, isTrue);
    final laidOut = result.data!;
    final bounds = _boundsOf(laidOut.states);

    expect(bounds.width <= originalBounds.width + 1e-6, isTrue);
    expect(bounds.height <= originalBounds.height + 1e-6, isTrue);
    expect(_withinCanvas(bounds), isTrue);
  });

  test('hierarchical layout places successors on lower levels', () async {
    final automaton = buildAutomaton();
    final result = await repository.applyHierarchicalLayout(automaton);

    expect(result.isSuccess, isTrue);
    final laidOut = result.data!;
    final yById = {for (final state in laidOut.states) state.id: state.y};

    expect(yById['q0']! <= yById['q1']!, isTrue);
    expect(yById['q0']! <= yById['q2']!, isTrue);
    expect(yById['q1']! <= yById['q3']!, isTrue);
    expect(yById['q3']! <= yById['q4']!, isTrue);
    expect(yById['q4']! <= yById['q5']!, isTrue);

    final bounds = _boundsOf(laidOut.states);
    expect(_withinCanvas(bounds), isTrue);
  });

  test('spread layout expands positions compared to compact layout', () async {
    final automaton = buildAutomaton();
    final compact = await repository.applyCompactLayout(automaton);
    final spread = await repository.applySpreadLayout(automaton);

    expect(compact.isSuccess, isTrue);
    expect(spread.isSuccess, isTrue);

    final compactBounds = _boundsOf(compact.data!.states);
    final spreadBounds = _boundsOf(spread.data!.states);

    expect(spreadBounds.width + 1e-6, greaterThanOrEqualTo(compactBounds.width));
    expect(spreadBounds.height + 1e-6, greaterThanOrEqualTo(compactBounds.height));
    expect(_withinCanvas(spreadBounds), isTrue);
  });

  test('center automaton recenters centroid on canvas', () async {
    final automaton = buildAutomaton();
    final result = await repository.centerAutomaton(automaton);

    expect(result.isSuccess, isTrue);
    final laidOut = result.data!;

    final centroid = _centroidOf(laidOut.states);
    expect(centroid.$1, closeTo(400, 1e-6));
    expect(centroid.$2, closeTo(300, 1e-6));
  });
}

class _BoundsData {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const _BoundsData(this.minX, this.minY, this.maxX, this.maxY);

  double get width => maxX - minX;
  double get height => maxY - minY;
}

_BoundsData _boundsOf(List<StateEntity> states) {
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

  return _BoundsData(minX, minY, maxX, maxY);
}

bool _withinCanvas(_BoundsData bounds) {
  const double padding = 60;
  const double width = 800;
  const double height = 600;
  return bounds.minX >= padding - 1e-6 &&
      bounds.maxX <= width - padding + 1e-6 &&
      bounds.minY >= padding - 1e-6 &&
      bounds.maxY <= height - padding + 1e-6;
}

(double, double) _centroidOf(List<StateEntity> states) {
  double sumX = 0;
  double sumY = 0;
  for (final state in states) {
    sumX += state.x;
    sumY += state.y;
  }
  return (sumX / states.length, sumY / states.length);
}
