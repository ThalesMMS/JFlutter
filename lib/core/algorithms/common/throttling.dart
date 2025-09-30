import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';

/// Frame-synced scheduler to limit UI updates to ~60fps.
class FrameThrottler {
  final Duration frameBudget;
  bool _scheduled = false;
  VoidCallback? _pending;

  FrameThrottler({Duration? frameBudget})
    : frameBudget = frameBudget ?? const Duration(milliseconds: 16);

  /// Schedule [callback] to run on the next frame. If multiple calls happen within
  /// the same frame, only the last callback is executed.
  void schedule(VoidCallback callback) {
    _pending = callback;
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final task = _pending;
      _pending = null;
      if (task != null) task();
    });
  }
}

/// Debounce calls; only the latest call within [duration] will run.
class Debouncer {
  Debouncer(this.duration);
  final Duration duration;
  Timer? _timer;

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() => _timer?.cancel();
}

/// Simple throttle: allows an action at most once per [interval].
class Throttle {
  Throttle(this.interval);
  final Duration interval;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  bool _pending = false;

  void call(VoidCallback action) {
    final now = DateTime.now();
    if (now.difference(_last) >= interval) {
      _last = now;
      action();
    } else if (!_pending) {
      _pending = true;
      final wait = interval - now.difference(_last);
      Timer(wait, () {
        _last = DateTime.now();
        _pending = false;
        action();
      });
    }
  }
}

/// Batch iterator: processes items in chunks per frame to keep UI smooth.
Future<void> processInBatches<T>({
  required Iterable<T> items,
  required void Function(T item) process,
  int itemsPerBatch = 500,
}) async {
  var processed = 0;
  for (final item in items) {
    process(item);
    processed++;
    if (processed % itemsPerBatch == 0) {
      // Yield to next frame
      final completer = Completer<void>();
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => completer.complete(),
      );
      await completer.future;
    }
  }
}

/// Utility to compute how many iterations can run within a time budget.
int iterationsForBudget(
  Duration elapsed,
  Duration budget, {
  int minPerBatch = 1,
  int maxPerBatch = 10000,
}) {
  final remaining = budget.inMicroseconds - elapsed.inMicroseconds;
  if (remaining <= 0) return minPerBatch;
  // Heuristic: assume ~150ns per light op ⇒ ~6666 ops/ms; clamp conservatively
  final estimated = (remaining / 300.0).floor();
  return math.max(minPerBatch, math.min(maxPerBatch, estimated));
}
