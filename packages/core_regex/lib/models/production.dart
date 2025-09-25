import 'package:freezed_annotation/freezed_annotation.dart';

part 'production.freezed.dart';
part 'production.g.dart';

/// Production rule for grammars using freezed
@freezed
class Production with _$Production {
  const factory Production({
    required String id,
    required List<String> leftSide,
    required List<String> rightSide,
    @Default(false) bool isLambda,
    @Default(0) int order,
  }) = _Production;

  factory Production.fromJson(Map<String, dynamic> json) => _$ProductionFromJson(json);
}

/// Extension methods for Production to provide grammar-specific functionality
extension ProductionExtension on Production {
  /// Validates the production properties
  List<String> validate() {
    final errors = <String>[];
    
    if (id.isEmpty) {
      errors.add('Production ID cannot be empty');
    }
    
    if (leftSide.isEmpty) {
      errors.add('Production left side cannot be empty');
    }
    
    if (isLambda && rightSide.isNotEmpty) {
      errors.add('Lambda production must have empty right side');
    }
    
    if (!isLambda && rightSide.isEmpty) {
      errors.add('Non-lambda production must have non-empty right side');
    }
    
    for (final symbol in leftSide) {
      if (symbol.isEmpty) {
        errors.add('Left side symbol cannot be empty');
      }
    }
    
    for (final symbol in rightSide) {
      if (symbol.isEmpty) {
        errors.add('Right side symbol cannot be empty');
      }
    }
    
    return errors;
  }

  /// Checks if the production is valid
  bool get isValid => validate().isEmpty;

  /// Gets the production as a string representation
  String get stringRepresentation {
    if (isLambda) {
      return '${leftSide.join(' ')} → ε';
    }
    return '${leftSide.join(' ')} → ${rightSide.join(' ')}';
  }

  /// Gets the production as a compact string representation
  String get compactRepresentation {
    if (isLambda) {
      return '${leftSide.join()} → ε';
    }
    return '${leftSide.join()} → ${rightSide.join()}';
  }

  /// Checks if this is a terminal production (right side contains only terminals)
  bool isTerminalProduction(Set<String> terminals) {
    if (isLambda) return true;
    return rightSide.every((symbol) => terminals.contains(symbol));
  }

  /// Checks if this is a non-terminal production (right side contains non-terminals)
  bool isNonTerminalProduction(Set<String> nonterminals) {
    if (isLambda) return false;
    return rightSide.any((symbol) => nonterminals.contains(symbol));
  }

  /// Checks if this production generates the given symbol
  bool generatesSymbol(String symbol) {
    if (isLambda) return false;
    return rightSide.contains(symbol);
  }

  /// Checks if this production consumes the given symbol
  bool consumesSymbol(String symbol) {
    return leftSide.contains(symbol);
  }

  /// Gets the length of the right side
  int get rightSideLength => isLambda ? 0 : rightSide.length;

  /// Gets the length of the left side
  int get leftSideLength => leftSide.length;

  /// Checks if this is a unit production (right side has exactly one non-terminal)
  bool isUnitProduction(Set<String> nonterminals) {
    if (isLambda) return false;
    return rightSide.length == 1 && nonterminals.contains(rightSide.first);
  }

  /// Checks if this is a chain production (right side has exactly one symbol, same as left side)
  bool isChainProduction() {
    if (isLambda) return false;
    return rightSide.length == 1 && leftSide.length == 1 && rightSide.first == leftSide.first;
  }

  /// Checks if this production is productive (right side can derive terminals)
  bool isProductive(Set<String> terminals) {
    if (isLambda) return true;
    return rightSide.any((symbol) => terminals.contains(symbol));
  }

  /// Gets the first symbol of the right side
  String? get firstRightSymbol => isLambda ? null : rightSide.isNotEmpty ? rightSide.first : null;

  /// Gets the last symbol of the right side
  String? get lastRightSymbol => isLambda ? null : rightSide.isNotEmpty ? rightSide.last : null;

  /// Checks if this production starts with the given symbol
  bool startsWithSymbol(String symbol) {
    if (isLambda) return false;
    return rightSide.isNotEmpty && rightSide.first == symbol;
  }

  /// Checks if this production ends with the given symbol
  bool endsWithSymbol(String symbol) {
    if (isLambda) return false;
    return rightSide.isNotEmpty && rightSide.last == symbol;
  }
}

/// Factory methods for creating common production patterns
class ProductionFactory {
  /// Creates a simple production rule
  static Production simple({
    required String id,
    required String leftSide,
    required String rightSide,
    int order = 0,
  }) {
    return Production(
      id: id,
      leftSide: [leftSide],
      rightSide: rightSide.isEmpty ? [] : [rightSide],
      isLambda: rightSide.isEmpty,
      order: order,
    );
  }

  /// Creates a lambda production rule
  static Production lambda({
    required String id,
    required String leftSide,
    int order = 0,
  }) {
    return Production(
      id: id,
      leftSide: [leftSide],
      rightSide: [],
      isLambda: true,
      order: order,
    );
  }

  /// Creates a production with multiple right-side symbols
  static Production multiSymbol({
    required String id,
    required String leftSide,
    required List<String> rightSide,
    int order = 0,
  }) {
    return Production(
      id: id,
      leftSide: [leftSide],
      rightSide: rightSide,
      isLambda: false,
      order: order,
    );
  }

  /// Creates a production with multiple left-side symbols (for unrestricted grammars)
  static Production multiLeft({
    required String id,
    required List<String> leftSide,
    required List<String> rightSide,
    int order = 0,
  }) {
    return Production(
      id: id,
      leftSide: leftSide,
      rightSide: rightSide,
      isLambda: rightSide.isEmpty,
      order: order,
    );
  }
}
