import 'package:flutter/foundation.dart';

class AlgoEvent {
  const AlgoEvent({required this.algo, required this.step, this.data = const {}});
  final String algo; // e.g., removeLambda, nfaToDfa, dfaToRegex, run
  final String step; // e.g., start, transition, newState, closure, eliminate, final
  final Map<String, dynamic> data;
}

class AlgoLog {
  // Plain text lines (back-compat and quick logs)
  static final ValueNotifier<List<String>> lines = ValueNotifier<List<String>>(<String>[]);

  // Structured events (Algoview mapping)
  static final ValueNotifier<List<AlgoEvent>> events = ValueNotifier<List<AlgoEvent>>(<AlgoEvent>[]);

  // Highlight set for canvas (updated by algorithms while emitting events)
  static final ValueNotifier<Set<String>> highlights = ValueNotifier<Set<String>>(<String>{});

  // Start a generic log section (e.g., Simulation)
  static void start(String title) {
    lines.value = [title];
  }

  // Start an algorithm section with a known code and title (resets events and highlights)
  static void startAlgo(String algo, String title) {
    lines.value = [title];
    events.value = <AlgoEvent>[];
    highlights.value = <String>{};
  }

  static void clear() {
    lines.value = <String>[];
    events.value = <AlgoEvent>[];
    highlights.value = <String>{};
  }

  static void add(String message) {
    final next = List<String>.from(lines.value)..add(message);
    lines.value = next;
  }

  static void step(String algo, String step, {Map<String, dynamic> data = const {}, Set<String>? highlight}) {
    final next = List<AlgoEvent>.from(events.value)..add(AlgoEvent(algo: algo, step: step, data: data));
    events.value = next;
    if (highlight != null) {
      highlights.value = highlight;
    }
  }

  static void setHighlight(Iterable<String> ids) {
    highlights.value = ids.toSet();
  }
}
