import 'dart:collection';

const _configurationCount = 50000;
const _graphNodeCount = 50000;

void main() {
  _compare('NTM-like branching configurations', _runListNtm, _runQueueNtm);
  _compare('wide graph traversal', _runListGraph, _runQueueGraph);
}

void _compare(
  String name,
  void Function() listImplementation,
  void Function() queueImplementation,
) {
  listImplementation();
  queueImplementation();

  final listTime = _measure(listImplementation);
  final queueTime = _measure(queueImplementation);
  final speedup = listTime.inMicroseconds / queueTime.inMicroseconds;
  print(
    '$name: List.removeAt(0)=${listTime.inMilliseconds}ms, '
    'Queue.removeFirst()=${queueTime.inMilliseconds}ms, '
    'speedup=${speedup.toStringAsFixed(1)}x',
  );
}

Duration _measure(void Function() operation) {
  final stopwatch = Stopwatch()..start();
  operation();
  return stopwatch.elapsed;
}

void _runListNtm() {
  final queue = <int>[0];
  var explored = 0;
  while (explored < _configurationCount) {
    final depth = queue.removeAt(0);
    queue
      ..add(depth + 1)
      ..add(depth + 1);
    explored++;
  }
}

void _runQueueNtm() {
  final queue = Queue<int>()..add(0);
  var explored = 0;
  while (explored < _configurationCount) {
    final depth = queue.removeFirst();
    queue
      ..add(depth + 1)
      ..add(depth + 1);
    explored++;
  }
}

void _runListGraph() {
  final queue = List<int>.generate(_graphNodeCount, (index) => index);
  var checksum = 0;
  while (queue.isNotEmpty) {
    checksum += queue.removeAt(0);
  }
  if (checksum == -1) throw StateError('unreachable');
}

void _runQueueGraph() {
  final queue = Queue<int>.of(
    List<int>.generate(_graphNodeCount, (index) => index),
  );
  var checksum = 0;
  while (queue.isNotEmpty) {
    checksum += queue.removeFirst();
  }
  if (checksum == -1) throw StateError('unreachable');
}
