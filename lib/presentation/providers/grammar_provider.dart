import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/production.dart';
import '../../core/result.dart';
import '../../data/services/conversion_service.dart';

/// State for managing grammar editing and conversions.
class GrammarState {
  final String name;
  final String startSymbol;
  final List<Production> productions;
  final GrammarType type;
  final bool isConverting;
  final String? error;
  final int nextProductionId;

  const GrammarState({
    required this.name,
    required this.startSymbol,
    required this.productions,
    required this.type,
    required this.isConverting,
    required this.nextProductionId,
    this.error,
  });

  factory GrammarState.initial() {
    return const GrammarState(
      name: 'My Grammar',
      startSymbol: 'S',
      productions: [],
      type: GrammarType.regular,
      isConverting: false,
      nextProductionId: 1,
    );
  }

  GrammarState copyWith({
    String? name,
    String? startSymbol,
    List<Production>? productions,
    GrammarType? type,
    bool? isConverting,
    Object? error = _noErrorUpdate,
    int? nextProductionId,
  }) {
    return GrammarState(
      name: name ?? this.name,
      startSymbol: startSymbol ?? this.startSymbol,
      productions: productions ?? this.productions,
      type: type ?? this.type,
      isConverting: isConverting ?? this.isConverting,
      error: error == _noErrorUpdate ? this.error : error as String?,
      nextProductionId: nextProductionId ?? this.nextProductionId,
    );
  }
}

const _noErrorUpdate = Object();

/// Provider notifier responsible for updating grammar state and running conversions.
class GrammarProvider extends StateNotifier<GrammarState> {
  GrammarProvider({ConversionService? conversionService})
      : _conversionService = conversionService ?? ConversionService(),
        super(GrammarState.initial());

  final ConversionService _conversionService;

  void updateName(String value) {
    state = state.copyWith(name: value, error: null);
  }

  void updateStartSymbol(String value) {
    if (value.isEmpty) {
      return;
    }
    state = state.copyWith(startSymbol: value, error: null);
  }

  void addProduction({
    required List<String> leftSide,
    required List<String> rightSide,
    bool isLambda = false,
  }) {
    final production = Production(
      id: 'p${state.nextProductionId}',
      leftSide: leftSide,
      rightSide: rightSide,
      isLambda: isLambda,
      order: state.productions.length,
    );

    state = state.copyWith(
      productions: [...state.productions, production],
      nextProductionId: state.nextProductionId + 1,
      error: null,
    );
  }

  void updateProduction(
    String id, {
    required List<String> leftSide,
    required List<String> rightSide,
    bool isLambda = false,
  }) {
    final index = state.productions.indexWhere((p) => p.id == id);
    if (index == -1) {
      return;
    }

    final updated = state.productions[index].copyWith(
      leftSide: leftSide,
      rightSide: rightSide,
      isLambda: isLambda,
    );

    final productions = [...state.productions];
    productions[index] = updated;

    state = state.copyWith(
      productions: productions,
      error: null,
    );
  }

  void deleteProduction(String id) {
    state = state.copyWith(
      productions: state.productions.where((p) => p.id != id).toList(),
      error: null,
    );
  }

  void clearProductions() {
    state = state.copyWith(
      productions: const <Production>[],
      nextProductionId: 1,
      error: null,
    );
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  Grammar buildGrammar() {
    final now = DateTime.now();
    final nonTerminals = <String>{state.startSymbol};
    final terminals = <String>{};

    for (final production in state.productions) {
      if (production.leftSide.isNotEmpty) {
        nonTerminals.add(production.leftSide.first);
      }
    }

    for (final production in state.productions) {
      if (production.isLambda) {
        continue;
      }

      for (final symbol in production.rightSide) {
        if (_isLambda(symbol)) {
          continue;
        }

        if (nonTerminals.contains(symbol) || _looksLikeNonTerminal(symbol)) {
          nonTerminals.add(symbol);
        } else {
          terminals.add(symbol);
        }
      }
    }

    terminals.removeWhere(_isLambda);

    return Grammar(
      id: 'grammar_${now.microsecondsSinceEpoch}',
      name: state.name,
      terminals: terminals,
      nonterminals: nonTerminals,
      startSymbol: state.startSymbol,
      productions: state.productions.toSet(),
      type: state.type,
      created: now,
      modified: now,
    );
  }

  Future<Result<FSA>> convertToAutomaton() async {
    if (state.productions.isEmpty) {
      return ResultFactory.failure('Add at least one production before converting.');
    }

    final grammar = buildGrammar();
    state = state.copyWith(isConverting: true, error: null);

    final result = _conversionService.convertGrammarToFsa(
      ConversionRequest.grammarToFsa(grammar: grammar),
    );

    if (result.isSuccess) {
      state = state.copyWith(isConverting: false, error: null);
    } else {
      state = state.copyWith(
        isConverting: false,
        error: result.error,
      );
    }

    return result;
  }

  bool _isLambda(String symbol) =>
      symbol == 'ε' || symbol == 'λ' || symbol.toLowerCase() == 'lambda';

  bool _looksLikeNonTerminal(String symbol) {
    final uppercaseRegex = RegExp(r'^[A-Z]$');
    return uppercaseRegex.hasMatch(symbol);
  }
}

/// Global grammar provider instance.
final grammarProvider =
    StateNotifierProvider<GrammarProvider, GrammarState>((ref) {
  return GrammarProvider();
});
