/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/providers/pda_editor_provider.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Administra o autômato de pilha editado no canvas e metadados derivados como transições lambda ou não determinísticas. Garante que alterações interativas sejam refletidas em modelos consistentes com o domínio.
/// Contexto: Utiliza um StateNotifier para consolidar mutações de estados, transições e configurações básicas do PDA. Serve de ponte entre eventos de interface e os objetos imutáveis usados por simuladores e exportadores.
/// Observações: Fornece operações utilitárias para criação, movimentação e remoção de elementos mantendo integridade referencial. Atualiza conjuntos auxiliares que alimentam destaques visuais e diagnósticos pedagógicos.
/// ---------------------------------------------------------------------------
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/state.dart';
import '../../core/models/transition.dart';

/// Holds the current PDA being edited in the canvas together with
/// metadata used by other widgets (e.g. highlighting information).
class PDAEditorState {
  /// The PDA built from the canvas contents.
  final PDA? pda;

  /// Identifiers of transitions that participate in nondeterministic choices.
  final Set<String> nondeterministicTransitionIds;

  /// Identifiers of transitions that involve at least one lambda operation.
  final Set<String> lambdaTransitionIds;

  const PDAEditorState({
    this.pda,
    this.nondeterministicTransitionIds = const {},
    this.lambdaTransitionIds = const {},
  });

  PDAEditorState copyWith({
    PDA? pda,
    Set<String>? nondeterministicTransitionIds,
    Set<String>? lambdaTransitionIds,
  }) {
    return PDAEditorState(
      pda: pda ?? this.pda,
      nondeterministicTransitionIds:
          nondeterministicTransitionIds ?? this.nondeterministicTransitionIds,
      lambdaTransitionIds: lambdaTransitionIds ?? this.lambdaTransitionIds,
    );
  }
}

/// Riverpod notifier responsible for maintaining the PDA that is edited by
/// the PDA canvas.
class PDAEditorNotifier extends StateNotifier<PDAEditorState> {
  PDAEditorNotifier() : super(const PDAEditorState());

  PDA _createEmptyPda() {
    final now = DateTime.now();
    return PDA(
      id: 'editor-pda',
      name: 'Canvas PDA',
      states: {},
      transitions: {},
      alphabet: {},
      initialState: null,
      acceptingStates: {},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: const {'Z'},
      initialStackSymbol: 'Z',
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );
  }

  PDA? _mutatePda(PDA Function(PDA current) transform) {
    final current = state.pda ?? _createEmptyPda();
    final updated = transform(current);
    if (identical(updated, current)) {
      return state.pda;
    }
    _updateStateWithPda(updated);
    return updated;
  }

  PDA? addOrUpdateState({
    required String id,
    required String label,
    required double x,
    required double y,
  }) {
    return _mutatePda((current) {
      final states = current.states.toList();
      final index = states.indexWhere((state) => state.id == id);
      final position = Vector2(x, y);

      if (index >= 0) {
        states[index] = states[index].copyWith(
          label: label,
          position: position,
        );
      } else {
        states.add(
          State(
            id: id,
            label: label,
            position: position,
            isInitial: states.isEmpty,
            isAccepting: false,
          ),
        );
      }

      final statesById = {
        for (final state in states) state.id: state,
      };

      final updated = _finalisePda(
        base: current,
        statesById: statesById,
        transitions: current.pdaTransitions,
      );

      return updated;
    });
  }

  PDA? moveState({
    required String id,
    required double x,
    required double y,
  }) {
    return _mutatePda((current) {
      final states = current.states
          .map(
            (state) => state.id == id
                ? state.copyWith(position: Vector2(x, y))
                : state,
          )
          .toList();

      final statesById = {
        for (final state in states) state.id: state,
      };

      return _finalisePda(
        base: current,
        statesById: statesById,
        transitions: current.pdaTransitions,
      );
    });
  }

  PDA? updateStateLabel({
    required String id,
    required String label,
  }) {
    return _mutatePda((current) {
      final states = current.states
          .map(
            (state) => state.id == id ? state.copyWith(label: label) : state,
          )
          .toList();

      final statesById = {
        for (final state in states) state.id: state,
      };

      return _finalisePda(
        base: current,
        statesById: statesById,
        transitions: current.pdaTransitions,
      );
    });
  }

  PDA? updateStateFlags({
    required String id,
    bool? isInitial,
    bool? isAccepting,
  }) {
    if (isInitial == null && isAccepting == null) {
      return state.pda;
    }

    return _mutatePda((current) {
      final statesById = {
        for (final state in current.states) state.id: state,
      };
      if (!statesById.containsKey(id)) {
        return current;
      }

      final updatedStates = <String, State>{};
      statesById.forEach((key, value) {
        var newInitial = value.isInitial;
        var newAccepting = value.isAccepting;

        if (key == id) {
          newInitial = isInitial ?? value.isInitial;
          newAccepting = isAccepting ?? value.isAccepting;
        } else if (isInitial == true) {
          newInitial = false;
        }

        updatedStates[key] = value.copyWith(
          isInitial: newInitial,
          isAccepting: newAccepting,
        );
      });

      return _finalisePda(
        base: current,
        statesById: updatedStates,
        transitions: current.pdaTransitions,
      );
    });
  }

  PDA? removeState({required String id}) {
    return _mutatePda((current) {
      final statesById = {
        for (final state in current.states) state.id: state,
      };
      final removed = statesById.remove(id);
      if (removed == null) {
        return current;
      }

      final remainingTransitions = current.pdaTransitions
          .where(
            (transition) =>
                transition.fromState.id != id && transition.toState.id != id,
          )
          .toList();

      return _finalisePda(
        base: current,
        statesById: statesById,
        transitions: remainingTransitions,
      );
    });
  }

  PDA? upsertTransition({
    required String id,
    String? fromStateId,
    String? toStateId,
    String? label,
    String? readSymbol,
    String? popSymbol,
    String? pushSymbol,
    bool? isLambdaInput,
    bool? isLambdaPop,
    bool? isLambdaPush,
    Vector2? controlPoint,
  }) {
    return _mutatePda((current) {
      final statesById = {
        for (final state in current.states) state.id: state,
      };
      final transitions = current.pdaTransitions.toList();
      final index = transitions.indexWhere((transition) => transition.id == id);

      PDATransition base;
      if (index >= 0) {
        base = transitions[index];
      } else {
        if (fromStateId == null || toStateId == null) {
          return current;
        }
        final fromState = statesById[fromStateId];
        final toState = statesById[toStateId];
        if (fromState == null || toState == null) {
          return current;
        }
        base = PDATransition(
          id: id,
          fromState: fromState,
          toState: toState,
          label: '',
          controlPoint: (controlPoint ?? Vector2.zero()).clone(),
          type: TransitionType.deterministic,
          inputSymbol: '',
          popSymbol: '',
          pushSymbol: '',
          isLambdaInput: true,
          isLambdaPop: true,
          isLambdaPush: true,
        );
        transitions.add(base);
      }

      final effectiveFrom = fromStateId != null && statesById.containsKey(fromStateId)
          ? statesById[fromStateId]!
          : base.fromState;
      final effectiveTo = toStateId != null && statesById.containsKey(toStateId)
          ? statesById[toStateId]!
          : base.toState;

      final lambdaInput = isLambdaInput ?? base.isLambdaInput;
      final lambdaPop = isLambdaPop ?? base.isLambdaPop;
      final lambdaPush = isLambdaPush ?? base.isLambdaPush;

      final updatedTransition = base.copyWith(
        fromState: effectiveFrom,
        toState: effectiveTo,
        inputSymbol: lambdaInput
            ? ''
            : (readSymbol ?? base.inputSymbol),
        popSymbol:
            lambdaPop ? '' : (popSymbol ?? base.popSymbol),
        pushSymbol:
            lambdaPush ? '' : (pushSymbol ?? base.pushSymbol),
        isLambdaInput: lambdaInput,
        isLambdaPop: lambdaPop,
        isLambdaPush: lambdaPush,
        controlPoint: (controlPoint ?? base.controlPoint).clone(),
      );

      final resolvedLabel = label ?? _formatTransitionLabel(updatedTransition);
      final finalTransition =
          updatedTransition.copyWith(label: resolvedLabel.trim());

      if (index >= 0) {
        transitions[index] = finalTransition;
      } else {
        transitions[transitions.length - 1] = finalTransition;
      }

      return _finalisePda(
        base: current,
        statesById: statesById,
        transitions: transitions,
      );
    });
  }

  PDA? removeTransition({required String id}) {
    return _mutatePda((current) {
      final transitions = current.pdaTransitions
          .where((transition) => transition.id != id)
          .toList(growable: false);
      if (transitions.length == current.pdaTransitions.length) {
        return current;
      }

      final statesById = {
        for (final state in current.states) state.id: state,
      };

      return _finalisePda(
        base: current,
        statesById: statesById,
        transitions: transitions,
      );
    });
  }

  /// Updates the notifier using the raw state and transition collections
  /// maintained by the canvas.
  void updateFromCanvas({
    required List<State> states,
    required List<PDATransition> transitions,
  }) {
    if (states.isEmpty) {
      state = const PDAEditorState(pda: null);
      return;
    }

    final stateSet = states.toSet();
    final transitionSet = transitions.toSet();

    final initialState = states.firstWhere(
      (s) => s.isInitial,
      orElse: () => states.first,
    );

    final acceptingStates = states.where((s) => s.isAccepting).toSet();

    final alphabet = <String>{};
    final stackAlphabet = <String>{'Z'};

    for (final transition in transitionSet) {
      if (!transition.isLambdaInput && transition.inputSymbol.isNotEmpty) {
        alphabet.add(transition.inputSymbol);
      }

      if (!transition.isLambdaPop && transition.popSymbol.isNotEmpty) {
        stackAlphabet.add(transition.popSymbol);
      }

      if (!transition.isLambdaPush && transition.pushSymbol.isNotEmpty) {
        stackAlphabet.add(transition.pushSymbol);
      }
    }

    if (stackAlphabet.isEmpty) {
      stackAlphabet.add('Z');
    }

    final now = DateTime.now();

    final pda = PDA(
      id: 'editor-pda',
      name: 'Canvas PDA',
      states: stateSet,
      transitions: transitionSet.map<Transition>((t) => t).toSet(),
      alphabet: alphabet,
      initialState: initialState,
      acceptingStates: {
        if (acceptingStates.isEmpty) states.last else ...acceptingStates,
      },
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: stackAlphabet,
      initialStackSymbol: stackAlphabet.first,
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );

    _updateStateWithPda(pda);
  }

  Set<String> _findNondeterministicTransitions(Set<PDATransition> transitions) {
    final grouped = <String, List<PDATransition>>{};

    for (final transition in transitions) {
      final key = [
        transition.fromState.id,
        if (transition.isLambdaInput) 'λ' else transition.inputSymbol,
        if (transition.isLambdaPop) 'λ' else transition.popSymbol,
      ].join('|');

      grouped.putIfAbsent(key, () => []).add(transition);
    }

    return grouped.values
        .where((list) => list.length > 1)
        .expand((list) => list.map((transition) => transition.id))
        .toSet();
  }

  /// Replaces the current PDA with a new instance, recalculating metadata.
  void setPda(PDA pda) {
    _updateStateWithPda(pda);
  }

  /// Clears the editor state, removing any PDA currently rendered on the canvas.
  void clear() {
    state = const PDAEditorState();
  }

  void _updateStateWithPda(PDA pda) {
    final transitions = pda.pdaTransitions;
    final nondeterministicTransitionIds = _findNondeterministicTransitions(
      transitions,
    );
    final lambdaTransitionIds = transitions
        .where((t) => t.isLambdaInput || t.isLambdaPop || t.isLambdaPush)
        .map((t) => t.id)
        .toSet();

    state = state.copyWith(
      pda: pda,
      nondeterministicTransitionIds: nondeterministicTransitionIds,
      lambdaTransitionIds: lambdaTransitionIds,
    );
  }

  PDA _finalisePda({
    required PDA base,
    required Map<String, State> statesById,
    required Iterable<PDATransition> transitions,
  }) {
    final reboundTransitions = transitions
        .map(
          (transition) => transition.copyWith(
            fromState:
                statesById[transition.fromState.id] ?? transition.fromState,
            toState: statesById[transition.toState.id] ?? transition.toState,
          ),
        )
        .toSet();

    final initialState = _ensureInitialState(statesById);
    final acceptingStates =
        statesById.values.where((state) => state.isAccepting).toSet();

    final alphabet = <String>{...base.alphabet};
    final stackAlphabet = <String>{base.initialStackSymbol, ...base.stackAlphabet};

    for (final transition in reboundTransitions) {
      if (!transition.isLambdaInput && transition.inputSymbol.isNotEmpty) {
        alphabet.add(transition.inputSymbol);
      }
      if (!transition.isLambdaPop && transition.popSymbol.isNotEmpty) {
        stackAlphabet.add(transition.popSymbol);
      }
      if (!transition.isLambdaPush && transition.pushSymbol.isNotEmpty) {
        stackAlphabet.add(transition.pushSymbol);
      }
    }

    return base.copyWith(
      states: statesById.values.toSet(),
      transitions: reboundTransitions.map<Transition>((t) => t).toSet(),
      initialState: initialState,
      acceptingStates: acceptingStates,
      alphabet: alphabet,
      stackAlphabet: stackAlphabet,
      modified: DateTime.now(),
    );
  }

  State? _ensureInitialState(Map<String, State> statesById) {
    for (final entry in statesById.values) {
      if (entry.isInitial) {
        return entry;
      }
    }
    if (statesById.isEmpty) {
      return null;
    }
    final firstKey = statesById.keys.first;
    final updated = statesById[firstKey]!.copyWith(isInitial: true);
    statesById[firstKey] = updated;
    return updated;
  }

  String _formatTransitionLabel(PDATransition transition) {
    final input = transition.isLambdaInput ? 'λ' : transition.inputSymbol;
    final pop = transition.isLambdaPop ? 'λ' : transition.popSymbol;
    final push = transition.isLambdaPush ? 'λ' : transition.pushSymbol;
    return '$input, $pop/$push';
  }
}

/// Provider exposing the current PDA editor state.
final pdaEditorProvider =
    StateNotifierProvider<PDAEditorNotifier, PDAEditorState>(
      (ref) => PDAEditorNotifier(),
    );
