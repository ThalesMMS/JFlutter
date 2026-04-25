part of '../file_operations_panel.dart';

extension _FileOperationsPanelConverters on _FileOperationsPanelState {
  Future<Result<FSA>> _loadAutomatonJsonFromPlatformFile(
    PlatformFile file,
  ) async {
    if (file.bytes != null) {
      return _fileService.loadAutomatonFromJsonBytes(file.bytes!);
    }

    final normalizedPath = _normalizedJsonPath(file.path);
    if (normalizedPath != null) {
      return _fileService.loadAutomatonFromJson(normalizedPath);
    }

    return const Failure<FSA>(_kJsonUnreadableFileMessage);
  }

  GrammarEntity _convertGrammarToEntity(Grammar grammar) {
    return GrammarEntity(
      id: grammar.id,
      name: grammar.name,
      terminals: grammar.terminals,
      nonTerminals: grammar.nonterminals,
      startSymbol: grammar.startSymbol,
      productions: grammar.productions
          .map(
            (production) => ProductionEntity(
              id: production.id,
              leftSide: List<String>.from(production.leftSide),
              rightSide: List<String>.from(production.rightSide),
            ),
          )
          .toList(),
    );
  }

  AutomatonEntity _convertPdaToAutomatonEntity(PDA pda) {
    final transitions = <String, List<String>>{};

    for (final transition in pda.pdaTransitions) {
      final label = _formatPdaTransitionLabel(transition);
      final key = '${transition.fromState.id}|$label';
      transitions.putIfAbsent(key, () => <String>[]).add(transition.toState.id);
    }

    return AutomatonEntity(
      id: pda.id,
      name: pda.name,
      alphabet: pda.alphabet.map(normalizeToEpsilon).toSet(),
      states: pda.states
          .map(
            (state) => StateEntity(
              id: state.id,
              name: state.label,
              x: state.position.x,
              y: state.position.y,
              isInitial: state.isInitial,
              isFinal: state.isAccepting,
            ),
          )
          .toList(),
      transitions: transitions,
      initialId: pda.initialState?.id,
      nextId: pda.states.length,
      type: AutomatonType.nfa,
    );
  }

  TuringMachineEntity _convertTmToEntity(TM tm) {
    return TuringMachineEntity(
      id: tm.id,
      name: tm.name,
      inputAlphabet: tm.alphabet,
      tapeAlphabet: tm.tapeAlphabet,
      blankSymbol: tm.blankSymbol,
      states: tm.states
          .map(
            (state) => TuringStateEntity(
              id: state.id,
              name: state.label,
              isInitial: state.isInitial,
              isAccepting: state.isAccepting,
            ),
          )
          .toList(),
      transitions: tm.tmTransitions
          .map(
            (transition) => TuringTransitionEntity(
              id: transition.id,
              fromStateId: transition.fromState.id,
              toStateId: transition.toState.id,
              readSymbol: transition.readSymbol,
              writeSymbol: transition.writeSymbol,
              moveDirection: _convertTapeDirection(transition.direction),
            ),
          )
          .toList(),
      initialStateId: tm.initialState?.id ?? '',
      acceptingStateIds: tm.acceptingStates.map((state) => state.id).toSet(),
      rejectingStateIds: const <String>{},
      nextStateIndex: tm.states.length,
    );
  }

  String _formatPdaTransitionLabel(PDATransition transition) {
    final read = normalizeToEpsilon(
      transition.isLambdaInput ? '' : transition.inputSymbol,
    );
    final pop = normalizeToEpsilon(
      transition.isLambdaPop ? '' : transition.popSymbol,
    );
    final push = normalizeToEpsilon(
      transition.isLambdaPush ? '' : transition.pushSymbol,
    );
    return '$read,$pop->$push';
  }

  TuringMoveDirection _convertTapeDirection(TapeDirection direction) {
    switch (direction) {
      case TapeDirection.left:
        return TuringMoveDirection.left;
      case TapeDirection.right:
        return TuringMoveDirection.right;
      case TapeDirection.stay:
        return TuringMoveDirection.stay;
    }
  }
}
