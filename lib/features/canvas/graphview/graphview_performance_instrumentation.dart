//
//  graphview_performance_instrumentation.dart
//  JFlutter
//
//  Lightweight performance instrumentation helpers for the GraphView canvas.
//
//  Design goals:
//  - Zero/near-zero overhead in release builds.
//  - Easy to use around hot paths (paint, hit testing, routing).
//  - No hard dependency on DevTools; integrates via `dart:developer` Timeline.
//
//  Usage:
//    GraphViewPerf.timeline('hitTest', () {
//      ...
//    });
//
//  Notes:
//  - This is assert-only so it is stripped in release builds.
//
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class GraphViewPerf {
  GraphViewPerf._();

  /// Wraps [body] in a synchronous Timeline event.
  static T timeline<T>(String name, T Function() body) {
    T? result;
    var executed = false;
    assert(() {
      result = developer.Timeline.timeSync(name, body);
      executed = true;
      return true;
    }());
    return executed ? result as T : body();
  }

  /// Emits an instantaneous Timeline event.
  static void instant(String name) {
    assert(() {
      developer.Timeline.instantSync(name);
      return true;
    }());
  }

  /// Optional debug logging for quick local profiling.
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[GraphViewPerf] $message');
    }
  }
}
