part of 'automaton_provider.dart';

Set<FSATransition> _rebindTransitions(
  Iterable<FSATransition> transitions,
  Map<String, State> statesById,
) {
  return transitions
      .map(
        (transition) => transition.copyWith(
          fromState:
              statesById[transition.fromState.id] ?? transition.fromState,
          toState: statesById[transition.toState.id] ?? transition.toState,
        ),
      )
      .toSet();
}

({Set<String> symbols, String? lambdaSymbol}) _parseTransitionLabel(
  String label,
) {
  final trimmed = label.trim();
  if (isEpsilonSymbol(trimmed)) {
    return (symbols: <String>{}, lambdaSymbol: kEpsilonSymbol);
  }

  final normalized = trimmed.replaceAll(RegExp(r'\s+'), '');
  if (isEpsilonSymbol(normalized)) {
    return (symbols: <String>{}, lambdaSymbol: kEpsilonSymbol);
  }

  final parts = normalized
      .split(',')
      .map((symbol) => symbol.trim())
      .where((symbol) => symbol.isNotEmpty)
      .toSet();
  return (symbols: parts, lambdaSymbol: null);
}

String _formatTransitionLabel(
  String rawLabel,
  ({Set<String> symbols, String? lambdaSymbol}) metadata,
) {
  if (metadata.lambdaSymbol != null) {
    return kEpsilonSymbol;
  }

  final collapsed = rawLabel.trim().replaceAll(RegExp(r'\s+'), '');
  if (collapsed.isNotEmpty) {
    final normalized = normalizeToEpsilon(collapsed);
    return normalized;
  }

  if (metadata.symbols.isNotEmpty) {
    final parts = metadata.symbols
        .map((symbol) => normalizeToEpsilon(symbol))
        .where((symbol) => symbol.isNotEmpty && !isEpsilonSymbol(symbol))
        .toList();
    if (parts.isNotEmpty) {
      return parts.join(',');
    }
  }

  return kEpsilonSymbol;
}

Vector2 _defaultLoopControlPoint(State state) {
  const radius = kAutomatonStateDiameter / 2;
  return Vector2(state.position.x + radius, state.position.y - radius);
}

bool _isZeroVector(Vector2 vector) {
  const epsilon = 1e-3;
  return vector.x.abs() < epsilon && vector.y.abs() < epsilon;
}

Set<String> _mergeAlphabet(Set<String> alphabet, Set<String> additions) {
  final filtered = additions
      .map((symbol) => symbol.trim())
      .where((symbol) => symbol.isNotEmpty && !isEpsilonSymbol(symbol))
      .toSet();
  return {...alphabet, ...filtered};
}

FSA _createEmptyAutomaton() {
  final now = DateTime.now();
  return FSA(
    id: 'automaton_${now.microsecondsSinceEpoch}',
    name: 'Untitled Automaton',
    states: <State>{},
    transitions: <Transition>{},
    alphabet: <String>{},
    initialState: null,
    acceptingStates: <State>{},
    created: now,
    modified: now,
    bounds: const Rectangle<double>(0, 0, 800, 600),
    panOffset: Vector2.zero(),
    zoomLevel: 1.0,
  );
}

/// Simulates the current automaton with input string

AutomatonEntity _convertFsaToEntity(FSA fsa) {
  final states = fsa.states
      .map(
        (s) => StateEntity(
          id: s.id,
          name: s.label,
          x: s.position.x,
          y: s.position.y,
          isInitial: s.isInitial,
          isFinal: s.isAccepting,
        ),
      )
      .toList();

  // Build transitions map from FSA transitions
  final transitions = <String, List<String>>{};
  for (final transition in fsa.transitions) {
    if (transition is FSATransition) {
      final symbols =
          transition.inputSymbols.isEmpty && transition.lambdaSymbol != null
              ? <String>{normalizeToEpsilon(transition.lambdaSymbol)}
              : transition.inputSymbols;
      for (final symbol in symbols) {
        final key = '${transition.fromState.id}|$symbol';
        if (!transitions.containsKey(key)) {
          transitions[key] = [];
        }
        transitions[key]!.add(transition.toState.id);
      }
    }
  }

  return AutomatonEntity(
    id: fsa.id,
    name: fsa.name,
    alphabet: fsa.alphabet,
    states: states,
    transitions: transitions,
    initialId: fsa.initialState?.id,
    nextId: states.length + 1,
    type: _inferAutomatonType(transitions),
  );
}

AutomatonType _inferAutomatonType(Map<String, List<String>> transitions) {
  var hasEpsilonTransition = false;
  var hasNondeterminism = false;

  for (final entry in transitions.entries) {
    final symbol = extractSymbolFromTransitionKey(entry.key);
    if (isEpsilonSymbol(symbol)) {
      hasEpsilonTransition = true;
      break;
    }
    if (entry.value.toSet().length > 1) {
      hasNondeterminism = true;
    }
  }

  if (hasEpsilonTransition) {
    return AutomatonType.nfaLambda;
  }
  if (hasNondeterminism) {
    return AutomatonType.nfa;
  }
  return AutomatonType.dfa;
}

/// Converts AutomatonEntity to FSA
FSA _convertEntityToFsa(AutomatonEntity entity) {
  final states = entity.states
      .map(
        (s) => State(
          id: s.id,
          label: s.name,
          position: Vector2(s.x, s.y),
          isInitial: s.isInitial,
          isAccepting: s.isFinal,
        ),
      )
      .toSet();

  final initialState = states.where((s) => s.isInitial).firstOrNull;
  final acceptingStates = states.where((s) => s.isAccepting).toSet();

  // Build FSA transitions from transitions map
  final transitions = <FSATransition>{};
  int transitionId = 1;

  for (final entry in entity.transitions.entries) {
    final parts = entry.key.split('|');
    if (parts.length == 2) {
      final fromStateId = parts[0];
      final symbol = parts[1];
      final fromState = states.firstWhereOrNull((s) => s.id == fromStateId);
      if (fromState == null) {
        continue;
      }

      for (final toStateId in entry.value) {
        final toState = states.firstWhereOrNull((s) => s.id == toStateId);
        if (toState == null) {
          continue;
        }
        final isLambda = isEpsilonSymbol(symbol);
        final lambdaSymbol = isLambda ? normalizeToEpsilon(symbol) : null;
        transitions.add(
          FSATransition(
            id: 't${transitionId++}',
            fromState: fromState,
            toState: toState,
            label: lambdaSymbol ?? symbol,
            inputSymbols: isLambda ? const <String>{} : {symbol},
            lambdaSymbol: lambdaSymbol,
          ),
        );
      }
    }
  }

  return FSA(
    id: entity.id,
    name: entity.name,
    states: states,
    transitions: transitions,
    alphabet: entity.alphabet,
    initialState: initialState,
    acceptingStates: acceptingStates,
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const Rectangle(0, 0, 800, 600),
  );
}
