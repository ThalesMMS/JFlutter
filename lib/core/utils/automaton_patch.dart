import 'package:vector_math/vector_math_64.dart';

import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/state.dart';
import '../models/transition.dart';

/// Applies a structural patch sent from the JavaScript editor to the provided
/// finite-state automaton and returns the updated instance. The patch format
/// mirrors the structure produced by the web editor and supports incremental
/// updates to states, transitions and viewport metadata.
FSA applyAutomatonPatchToFsa(
  FSA automaton,
  Map<String, dynamic> patch,
) {
  final states = <String, State>{
    for (final state in automaton.states) state.id: state,
  };

  final transitions = <String, FSATransition>{
    for (final transition in automaton.transitions)
      if (transition is FSATransition) transition.id: transition,
  };

  _applyStatePatch(states, transitions, patch['states']);
  _applyTransitionPatch(states, transitions, patch['transitions']);

  final viewportPatch = patch['viewport'];
  final panOffset = viewportPatch is Map<String, dynamic>
      ? _parsePanOffset(viewportPatch['pan'], automaton.panOffset)
      : automaton.panOffset;
  final zoomLevel = viewportPatch is Map<String, dynamic>
      ? _parseZoom(viewportPatch['zoom'], automaton.zoomLevel)
      : automaton.zoomLevel;

  final alphabetPatch = patch['alphabet'];
  final updatedAlphabet = alphabetPatch is Iterable
      ? alphabetPatch.map((symbol) => symbol.toString()).toSet()
      : <String>{...automaton.alphabet};

  if (alphabetPatch == null) {
    // Ensure the alphabet keeps track of symbols referenced in transitions.
    for (final transition in transitions.values) {
      updatedAlphabet.addAll(transition.inputSymbols);
      if (transition.lambdaSymbol != null) {
        updatedAlphabet.add(transition.lambdaSymbol!);
      }
    }
  }

  final newStates = states.values.toSet();
  State? initialState = automaton.initialState;

  for (final state in newStates) {
    if (state.isInitial) {
      initialState = state;
      break;
    }
  }

  final acceptingStates = newStates.where((s) => s.isAccepting).toSet();

  return automaton.copyWith(
    states: newStates,
    transitions: transitions.values.toSet(),
    initialState: initialState,
    acceptingStates: acceptingStates,
    alphabet: updatedAlphabet,
    modified: DateTime.now(),
    panOffset: panOffset,
    zoomLevel: zoomLevel,
  );
}

void _applyStatePatch(
  Map<String, State> states,
  Map<String, FSATransition> transitions,
  dynamic rawPatch,
) {
  if (rawPatch is! Map) {
    return;
  }

  final patch = rawPatch.cast<dynamic, dynamic>();
  final upserts = patch['upsert'];
  if (upserts is Iterable) {
    for (final entry in upserts) {
      if (entry is! Map) continue;
      final data = entry.cast<dynamic, dynamic>();
      final id = data['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final existing = states[id];
      final label = data.containsKey('label')
          ? data['label']?.toString() ?? existing?.label ?? id
          : existing?.label ?? id;
      final x = _toDouble(
        data.containsKey('x') ? data['x'] : existing?.position.x ?? 0,
      );
      final y = _toDouble(
        data.containsKey('y') ? data['y'] : existing?.position.y ?? 0,
      );
      final isInitial = data.containsKey('isInitial')
          ? _toBool(data['isInitial'])
          : (existing?.isInitial ?? false);
      final isAccepting = data.containsKey('isAccepting')
          ? _toBool(data['isAccepting'])
          : (existing?.isAccepting ?? false);

      final properties = existing?.properties ?? const <String, dynamic>{};
      final type = existing?.type ?? StateType.normal;

      states[id] = State(
        id: id,
        label: label,
        position: Vector2(x, y),
        isInitial: isInitial,
        isAccepting: isAccepting,
        type: type,
        properties: properties,
      );
    }
  }

  final deletes = patch['delete'];
  if (deletes is Iterable) {
    for (final value in deletes) {
      final id = value?.toString();
      if (id == null) continue;
      states.remove(id);
      transitions.removeWhere(
        (key, transition) =>
            transition.fromState.id == id || transition.toState.id == id,
      );
    }
  }

  final meta = patch['meta'];
  final initialId = meta is Map ? meta['initialId']?.toString() : null;
  if (initialId != null && states.containsKey(initialId)) {
    for (final entry in states.entries) {
      final isInitial = entry.key == initialId;
      if (entry.value.isInitial == isInitial) continue;
      states[entry.key] = entry.value.copyWith(isInitial: isInitial);
    }
  } else {
    // Guarantee there is at most one initial state.
    State? primaryInitial;
    for (final entry in states.entries) {
      if (!entry.value.isInitial) continue;
      if (primaryInitial == null) {
        primaryInitial = entry.value;
        continue;
      }
      states[entry.key] = entry.value.copyWith(isInitial: false);
    }
  }
}

void _applyTransitionPatch(
  Map<String, State> states,
  Map<String, FSATransition> transitions,
  dynamic rawPatch,
) {
  if (rawPatch is! Map) {
    return;
  }

  final patch = rawPatch.cast<dynamic, dynamic>();
  final upserts = patch['upsert'];
  if (upserts is Iterable) {
    for (final entry in upserts) {
      if (entry is! Map) continue;
      final data = entry.cast<dynamic, dynamic>();
      final id = data['id']?.toString();
      final fromId = data['from']?.toString() ?? data['fromState']?.toString();
      final toId = data['to']?.toString() ?? data['toState']?.toString();
      if (id == null || fromId == null || toId == null) continue;
      final fromState = states[fromId];
      final toState = states[toId];
      if (fromState == null || toState == null) continue;

      final existing = transitions[id];
      final symbols = <String>{};
      final labels = data['symbols'] ?? data['labels'];
      if (labels is Iterable) {
        for (final symbol in labels) {
          if (symbol == null) continue;
          final text = symbol.toString();
          if (text.isEmpty || text == 'ε') continue;
          symbols.add(text);
        }
      } else if (data['label'] != null) {
        final fromLabel = data['label'].toString();
        if (fromLabel.contains(',')) {
          symbols.addAll(
            fromLabel.split(',').map((entry) => entry.trim()).where(
                  (entry) => entry.isNotEmpty && entry != 'ε',
                ),
          );
        } else if (fromLabel.isNotEmpty && fromLabel != 'ε') {
          symbols.add(fromLabel);
        }
      } else if (existing != null) {
        symbols.addAll(existing.inputSymbols);
      }

      String? lambdaSymbol;
      if (data.containsKey('lambdaSymbol')) {
        final value = data['lambdaSymbol'];
        if (value != null && value.toString().isNotEmpty) {
          lambdaSymbol = value.toString();
        }
      } else if ((data['symbols'] ?? data['labels']) is Iterable) {
        final values = (data['symbols'] ?? data['labels']) as Iterable;
        if (values.any((symbol) => symbol?.toString() == 'ε')) {
          lambdaSymbol = 'ε';
        }
      } else if (existing?.lambdaSymbol != null) {
        lambdaSymbol = existing!.lambdaSymbol;
      }

      final label = data.containsKey('label')
          ? data['label']?.toString() ??
              (lambdaSymbol ?? (symbols.isEmpty ? '' : symbols.join(', ')))
          : existing?.label ??
              (lambdaSymbol ?? (symbols.isEmpty ? '' : symbols.join(', ')));

      final controlData = data['controlPoint'] ?? data['control'];
      Vector2 controlPoint = existing?.controlPoint ?? Vector2.zero();
      if (controlData is Map) {
        controlPoint = Vector2(
          _toDouble(controlData['x'] ?? controlPoint.x),
          _toDouble(controlData['y'] ?? controlPoint.y),
        );
      }

      TransitionType? type;
      if (lambdaSymbol != null) {
        type = TransitionType.epsilon;
      } else if (symbols.length > 1) {
        type = TransitionType.nondeterministic;
      } else if (symbols.isNotEmpty) {
        type = TransitionType.deterministic;
      }

      transitions[id] = FSATransition(
        id: id,
        fromState: fromState,
        toState: toState,
        label: label,
        controlPoint: controlPoint,
        type: type,
        inputSymbols: symbols,
        lambdaSymbol: lambdaSymbol,
      );
    }
  }

  final deletes = patch['delete'];
  if (deletes is Iterable) {
    for (final value in deletes) {
      final id = value?.toString();
      if (id == null) continue;
      transitions.remove(id);
    }
  }
}

Vector2 _parsePanOffset(dynamic value, Vector2 fallback) {
  if (value is Map) {
    final x = _toDouble(value['x'] ?? fallback.x);
    final y = _toDouble(value['y'] ?? fallback.y);
    return Vector2(x, y);
  }
  return fallback;
}

double _parseZoom(dynamic value, double fallback) {
  final parsed = _toDouble(value ?? fallback);
  return parsed <= 0 ? fallback : parsed;
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }
  return 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      default:
        return false;
    }
  }
  return false;
}
