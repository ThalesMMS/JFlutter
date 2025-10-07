//
//  grammar_provider.dart
//  JFlutter
//
//  Administra a edição de gramáticas formais no workspace, mantendo produções,
//  símbolo inicial, tipo selecionado e resultados recentes de conversões enquanto
//  integra serviços de transformação para gerar autômatos e PDAs consumidos por
//  widgets e feedback visual.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/production.dart';
import '../../core/result.dart';
import '../../data/services/conversion_service.dart';
import '../../injection/dependency_injection.dart';

/// Types of conversions that can be triggered from the grammar workspace.
enum GrammarConversionType {
  grammarToFsa,
  grammarToPda,
  grammarToPdaStandard,
  grammarToPdaGreibach,
}

/// State for managing grammar editing and conversions.
class GrammarState {
  final String name;
  final String startSymbol;
  final List<Production> productions;
  final GrammarType type;
  final bool isConverting;
  final String? error;
  final int nextProductionId;
  final GrammarConversionType? activeConversion;
  final Result<PDA>? lastPdaResult;

  const GrammarState({
    required this.name,
    required this.startSymbol,
    required this.productions,
    required this.type,
    required this.isConverting,
    required this.nextProductionId,
    this.activeConversion,
    this.lastPdaResult,
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
      activeConversion: null,
      lastPdaResult: null,
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
    Object? activeConversion = _noActiveConversionUpdate,
    Object? lastPdaResult = _noPdaResultUpdate,
  }) {
    return GrammarState(
      name: name ?? this.name,
      startSymbol: startSymbol ?? this.startSymbol,
      productions: productions ?? this.productions,
      type: type ?? this.type,
      isConverting: isConverting ?? this.isConverting,
      error: error == _noErrorUpdate ? this.error : error as String?,
      nextProductionId: nextProductionId ?? this.nextProductionId,
      activeConversion: activeConversion == _noActiveConversionUpdate
          ? this.activeConversion
          : activeConversion as GrammarConversionType?,
      lastPdaResult: lastPdaResult == _noPdaResultUpdate
          ? this.lastPdaResult
          : lastPdaResult as Result<PDA>?,
    );
  }
}

const _noErrorUpdate = Object();
const _noActiveConversionUpdate = Object();
const _noPdaResultUpdate = Object();

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

    state = state.copyWith(productions: productions, error: null);
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
      lastPdaResult: null,
    );
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Resets the grammar editor to a fresh grammar definition.
  void createNewGrammar({
    String? name,
    String? startSymbol,
    GrammarType? type,
  }) {
    state = GrammarState(
      name: name ?? 'My Grammar',
      startSymbol: startSymbol ?? 'S',
      productions: const [],
      type: type ?? GrammarType.regular,
      isConverting: false,
      nextProductionId: 1,
      error: null,
      activeConversion: null,
      lastPdaResult: null,
    );
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
      final result = ResultFactory.failure<FSA>(
        'Add at least one production before converting.',
      );
      state = state.copyWith(error: result.error, lastPdaResult: null);
      return result;
    }

    final grammar = buildGrammar();
    state = state.copyWith(
      isConverting: true,
      error: null,
      activeConversion: GrammarConversionType.grammarToFsa,
      lastPdaResult: null,
    );

    final result = _conversionService.convertGrammarToFsa(
      ConversionRequest.grammarToFsa(grammar: grammar),
    );

    if (result.isSuccess) {
      state = state.copyWith(
        isConverting: false,
        error: null,
        activeConversion: null,
      );
    } else {
      state = state.copyWith(
        isConverting: false,
        error: result.error,
        activeConversion: null,
      );
    }

    return result;
  }

  Future<Result<PDA>> convertToPda() {
    return _performPdaConversion(
      requestBuilder: ConversionRequest.grammarToPda,
      converter: _conversionService.convertGrammarToPda,
      conversionType: GrammarConversionType.grammarToPda,
    );
  }

  Future<Result<PDA>> convertToPdaStandard() {
    return _performPdaConversion(
      requestBuilder: ConversionRequest.grammarToPdaStandard,
      converter: _conversionService.convertGrammarToPdaStandard,
      conversionType: GrammarConversionType.grammarToPdaStandard,
    );
  }

  Future<Result<PDA>> convertToPdaGreibach() {
    return _performPdaConversion(
      requestBuilder: ConversionRequest.grammarToPdaGreibach,
      converter: _conversionService.convertGrammarToPdaGreibach,
      conversionType: GrammarConversionType.grammarToPdaGreibach,
    );
  }

  Future<Result<PDA>> _performPdaConversion({
    required ConversionRequest Function({required Grammar grammar})
        requestBuilder,
    required Result<dynamic> Function(ConversionRequest request) converter,
    required GrammarConversionType conversionType,
  }) async {
    if (state.productions.isEmpty) {
      final result = ResultFactory.failure<PDA>(
        'Add at least one production before converting.',
      );
      state = state.copyWith(
        error: result.error,
        lastPdaResult: result,
        activeConversion: null,
        isConverting: false,
      );
      return result;
    }

    final grammar = buildGrammar();
    state = state.copyWith(
      isConverting: true,
      error: null,
      activeConversion: conversionType,
    );

    final serviceResult = converter(
      requestBuilder(grammar: grammar),
    );

    final result = _mapDynamicResultToPda(serviceResult);

    state = state.copyWith(
      isConverting: false,
      error: result.error,
      activeConversion: null,
      lastPdaResult: result,
    );

    return result;
  }

  Result<PDA> _mapDynamicResultToPda(Result<dynamic> result) {
    if (result is Success<dynamic>) {
      final data = result.data;
      if (data is PDA) {
        return ResultFactory.success<PDA>(data);
      }
      return ResultFactory.failure<PDA>(
        'Unexpected result type returned from conversion.',
      );
    }

    if (result is Failure<dynamic>) {
      return ResultFactory.failure<PDA>(result.message);
    }

    return ResultFactory.failure<PDA>('Unknown conversion result.');
  }

  bool _isLambda(String symbol) =>
      symbol == 'ε' || symbol == 'λ' || symbol.toLowerCase() == 'lambda';

  bool _looksLikeNonTerminal(String symbol) {
    final uppercaseRegex = RegExp(r'^[A-Z]$');
    return uppercaseRegex.hasMatch(symbol);
  }
}

/// Global grammar provider instance.
final grammarProvider = StateNotifierProvider<GrammarProvider, GrammarState>((
  ref,
) {
  return getIt<GrammarProvider>();
});
