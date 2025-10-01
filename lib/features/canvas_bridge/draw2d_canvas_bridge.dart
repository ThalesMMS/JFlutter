import 'dart:convert';
import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/state.dart';

/// Clock signature used for deterministic testing.
typedef BridgeClock = DateTime Function();

/// Contract used to send serialized commands to the embedded WebView.
abstract class BridgeMessenger {
  Future<void> postMessage(BridgeCommand command);
}

/// Messenger implementation that ignores all outgoing commands.
class NoopBridgeMessenger implements BridgeMessenger {
  const NoopBridgeMessenger();

  @override
  Future<void> postMessage(BridgeCommand command) async {}
}

/// Command sent from Flutter to the Draw2D runtime.
class BridgeCommand {
  BridgeCommand({required this.type, required this.payload});

  final String type;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {'type': type, 'payload': payload};

  factory BridgeCommand.loadAutomaton(Map<String, dynamic> payload) {
    return BridgeCommand(type: 'loadAutomaton', payload: payload);
  }
}

/// Supported event types emitted by the Draw2D runtime.
enum BridgeEventType { nodeAdded, nodeMoved, edgeLinked }

/// Event payload emitted by the Draw2D runtime.
class BridgeEvent {
  BridgeEvent({required this.type, required this.payload});

  final BridgeEventType type;
  final Map<String, dynamic> payload;

  factory BridgeEvent.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? '';
    final payload =
        (json['payload'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return BridgeEvent(type: _parseEventType(rawType), payload: payload);
  }

  static BridgeEventType _parseEventType(String value) {
    switch (value) {
      case 'node:add':
      case 'nodeAdded':
        return BridgeEventType.nodeAdded;
      case 'node:move':
      case 'nodeMoved':
        return BridgeEventType.nodeMoved;
      case 'edge:link':
      case 'edgeLinked':
        return BridgeEventType.edgeLinked;
      default:
        throw ArgumentError('Unknown bridge event type: $value');
    }
  }
}

/// Serializable node description shared with the Draw2D runtime.
class BridgeNode {
  BridgeNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.isInitial,
    required this.isAccepting,
  });

  final String id;
  final String label;
  final double x;
  final double y;
  final bool isInitial;
  final bool isAccepting;

  factory BridgeNode.fromJson(Map<String, dynamic> json) {
    return BridgeNode(
      id: json['id'] as String,
      label: json['label'] as String? ?? json['id'] as String,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      isInitial: json['isInitial'] as bool? ?? false,
      isAccepting: json['isAccepting'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'x': x,
      'y': y,
      'isInitial': isInitial,
      'isAccepting': isAccepting,
    };
  }
}

/// Serializable edge description shared with the Draw2D runtime.
class BridgeEdge {
  BridgeEdge({
    required this.id,
    required this.fromStateId,
    required this.toStateId,
    required this.symbols,
  });

  final String id;
  final String fromStateId;
  final String toStateId;
  final List<String> symbols;

  factory BridgeEdge.fromJson(Map<String, dynamic> json) {
    final rawSymbols = json['symbols'];
    final symbols = rawSymbols is List
        ? rawSymbols.cast<String>()
        : (rawSymbols is String && rawSymbols.isNotEmpty)
        ? rawSymbols.split(',')
        : <String>[];

    return BridgeEdge(
      id: json['id'] as String,
      fromStateId: json['from'] as String,
      toStateId: json['to'] as String,
      symbols: symbols,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'from': fromStateId, 'to': toStateId, 'symbols': symbols};
  }
}

/// Converts between [FSA] instances and bridge-friendly payloads.
class BridgeAutomatonMapper {
  static Map<String, dynamic> toBridgeAutomaton(FSA? automaton) {
    if (automaton == null) {
      return const {
        'nodes': <Map<String, dynamic>>[],
        'edges': <Map<String, dynamic>>[],
        'metadata': <String, dynamic>{},
      };
    }

    final nodes = automaton.states.map((state) {
      final isInitial = automaton.initialState?.id == state.id;
      final isAccepting = automaton.acceptingStates.any(
        (accepting) => accepting.id == state.id,
      );
      return BridgeNode(
        id: state.id,
        label: state.label,
        x: state.position.x,
        y: state.position.y,
        isInitial: isInitial,
        isAccepting: isAccepting,
      ).toJson();
    }).toList();

    final edges = automaton.fsaTransitions.map((transition) {
      return BridgeEdge(
        id: transition.id,
        fromStateId: transition.fromState.id,
        toStateId: transition.toState.id,
        symbols: transition.inputSymbols.toList(),
      ).toJson();
    }).toList();

    return {
      'nodes': nodes,
      'edges': edges,
      'metadata': {
        'id': automaton.id,
        'name': automaton.name,
        'alphabet': automaton.alphabet.toList(),
      },
    };
  }

  /// Hydrates an [FSA] template with data received from the bridge.
  static FSA mergeIntoTemplate(Map<String, dynamic> payload, FSA template) {
    final nodeMaps =
        (payload['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final edgeMaps =
        (payload['edges'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    final nodes = nodeMaps.map(BridgeNode.fromJson).toList();
    final edges = edgeMaps.map(BridgeEdge.fromJson).toList();

    final states = nodes
        .map(
          (node) => State(
            id: node.id,
            label: node.label,
            position: Vector2(node.x, node.y),
            isInitial: node.isInitial,
            isAccepting: node.isAccepting,
          ),
        )
        .toSet();

    final stateMap = {for (final state in states) state.id: state};

    final transitions = edges.map((edge) {
      final fromState = stateMap[edge.fromStateId];
      final toState = stateMap[edge.toStateId];
      if (fromState == null || toState == null) {
        throw StateError('Edge references missing state: ${edge.toJson()}');
      }
      return FSATransition(
        id: edge.id,
        fromState: fromState,
        toState: toState,
        inputSymbols: edge.symbols.toSet(),
        label: edge.symbols.join(','),
      );
    }).toSet();

    BridgeNode? initialNode;
    for (final node in nodes) {
      if (node.isInitial) {
        initialNode = node;
        break;
      }
    }

    final acceptingStates = {
      for (final node in nodes.where((node) => node.isAccepting))
        stateMap[node.id]!,
    };

    final alphabet = <String>{
      ...template.alphabet,
      for (final edge in edges) ...edge.symbols,
    }..removeWhere((symbol) => symbol.isEmpty);

    return template.copyWith(
      states: states,
      transitions: transitions,
      acceptingStates: acceptingStates,
      initialState: initialNode != null
          ? stateMap[initialNode.id]
          : template.initialState,
      alphabet: alphabet,
    );
  }
}

/// High-level orchestrator that keeps Flutter's [FSA] in sync with Draw2D.
class Draw2dCanvasBridge {
  Draw2dCanvasBridge({
    required BridgeMessenger messenger,
    required void Function(FSA) onAutomatonChanged,
    BridgeClock? clock,
  }) : _messenger = messenger,
       _onAutomatonChanged = onAutomatonChanged,
       _clock = clock ?? DateTime.now;

  BridgeMessenger _messenger;
  void Function(FSA) _onAutomatonChanged;
  final BridgeClock _clock;
  FSA? _automaton;

  /// Updates the listener invoked when the automaton changes.
  void setOnAutomatonChanged(void Function(FSA) listener) {
    _onAutomatonChanged = listener;
  }

  /// Replaces the messenger implementation (used when the WebView initializes).
  void attachMessenger(BridgeMessenger messenger) {
    _messenger = messenger;
  }

  /// Sends the latest automaton snapshot to the Draw2D runtime.
  Future<void> synchronize(FSA? automaton) async {
    _automaton = automaton;
    final payload = BridgeAutomatonMapper.toBridgeAutomaton(automaton);
    await _messenger.postMessage(BridgeCommand.loadAutomaton(payload));
  }

  /// Applies an event emitted by the Draw2D runtime.
  void handleRawMessage(String rawMessage) {
    if (rawMessage.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(rawMessage) as Map<String, dynamic>;
      final event = BridgeEvent.fromJson(decoded);
      switch (event.type) {
        case BridgeEventType.nodeAdded:
          _handleNodeAdded(event.payload);
          break;
        case BridgeEventType.nodeMoved:
          _handleNodeMoved(event.payload);
          break;
        case BridgeEventType.edgeLinked:
          _handleEdgeLinked(event.payload);
          break;
      }
    } catch (_) {
      // Ignore malformed messages to keep the bridge resilient.
    }
  }

  void _handleNodeAdded(Map<String, dynamic> payload) {
    final node = BridgeNode.fromJson(payload);
    final base = _ensureAutomaton();
    final updatedStates = base.states
        .where((state) => state.id != node.id)
        .map(
          (state) => node.isInitial && state.isInitial
              ? state.copyWith(isInitial: false)
              : state,
        )
        .toSet();

    final newState = State(
      id: node.id,
      label: node.label,
      position: Vector2(node.x, node.y),
      isInitial: node.isInitial,
      isAccepting: node.isAccepting,
    );
    updatedStates.add(newState);

    final updated = _rebuildAutomaton(
      base: base,
      states: updatedStates,
      explicitInitialState: node.isInitial ? newState : null,
    );
    _emit(updated);
  }

  void _handleNodeMoved(Map<String, dynamic> payload) {
    final node = BridgeNode.fromJson(payload);
    final base = _ensureAutomaton();
    final updatedStates = base.states.map((state) {
      if (state.id == node.id) {
        return state.copyWith(position: Vector2(node.x, node.y));
      }
      return state;
    }).toSet();

    final updated = _rebuildAutomaton(base: base, states: updatedStates);
    _emit(updated);
  }

  void _handleEdgeLinked(Map<String, dynamic> payload) {
    final edge = BridgeEdge.fromJson(payload);
    final base = _ensureAutomaton();
    final states = base.states.toSet();
    final stateMap = {for (final state in states) state.id: state};
    final fromState = stateMap[edge.fromStateId];
    final toState = stateMap[edge.toStateId];
    if (fromState == null || toState == null) {
      return;
    }

    final transitions =
        base.fsaTransitions
            .where((transition) => transition.id != edge.id)
            .toSet()
          ..add(
            FSATransition(
              id: edge.id,
              fromState: fromState,
              toState: toState,
              inputSymbols: edge.symbols.toSet(),
              label: edge.symbols.join(','),
            ),
          );

    final alphabet = <String>{
      ...base.alphabet,
      ...edge.symbols.where((symbol) => symbol.isNotEmpty),
    };

    final updated = _rebuildAutomaton(
      base: base,
      states: states,
      transitions: transitions,
      alphabet: alphabet,
    );
    _emit(updated);
  }

  FSA _ensureAutomaton() {
    final existing = _automaton;
    if (existing != null) {
      return existing;
    }

    final now = _clock();
    final created = FSA(
      id: 'bridge_${now.microsecondsSinceEpoch}',
      name: 'Untitled Automaton',
      states: {},
      transitions: {},
      alphabet: {},
      initialState: null,
      acceptingStates: {},
      created: now,
      modified: now,
      bounds: const math.Rectangle<double>(0, 0, 800, 600),
    );
    _automaton = created;
    return created;
  }

  FSA _rebuildAutomaton({
    required FSA base,
    required Set<State> states,
    Set<FSATransition>? transitions,
    Set<String>? alphabet,
    State? explicitInitialState,
  }) {
    final stateMap = {for (final state in states) state.id: state};

    final initialState =
        explicitInitialState ??
        (base.initialState != null
            ? stateMap[base.initialState!.id] ?? base.initialState
            : null);

    final acceptingStates = {
      for (final state in states.where((state) => state.isAccepting)) state,
    };

    final updatedTransitions = (transitions ?? base.fsaTransitions).map((
      transition,
    ) {
      final fromState =
          stateMap[transition.fromState.id] ?? transition.fromState;
      final toState = stateMap[transition.toState.id] ?? transition.toState;
      return transition.copyWith(fromState: fromState, toState: toState);
    }).toSet();

    return base.copyWith(
      states: states,
      transitions: updatedTransitions,
      acceptingStates: acceptingStates,
      initialState: initialState,
      alphabet: alphabet ?? base.alphabet,
      modified: _clock(),
    );
  }

  void _emit(FSA automaton) {
    _automaton = automaton;
    _onAutomatonChanged(automaton);
  }
}
