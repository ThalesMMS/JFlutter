import 'package:freezed_annotation/freezed_annotation.dart';

part 'alphabet.freezed.dart';
part 'alphabet.g.dart';

/// Represents an alphabet of symbols for an automaton
@freezed
class Alphabet with _$Alphabet {
  const factory Alphabet({
    required Set<String> symbols,
    @Default(false) bool isCaseSensitive,
  }) = _Alphabet;

  factory Alphabet.fromJson(Map<String, dynamic> json) => _$AlphabetFromJson(json);

  /// Creates an alphabet from a list of symbols
  factory Alphabet.fromList(List<String> symbols, {bool isCaseSensitive = false}) {
    return Alphabet(
      symbols: symbols.toSet(),
      isCaseSensitive: isCaseSensitive,
    );
  }

  /// Creates an alphabet from a set of symbols
  factory Alphabet.fromSet(Set<String> symbols, {bool isCaseSensitive = false}) {
    return Alphabet(
      symbols: symbols,
      isCaseSensitive: isCaseSensitive,
    );
  }

  /// Returns true if the symbol is in the alphabet
  bool contains(String symbol) {
    if (isCaseSensitive) {
      return symbols.contains(symbol);
    } else {
      return symbols.any((s) => s.toLowerCase() == symbol.toLowerCase());
    }
  }

  /// Returns the alphabet as a list
  List<String> toList() => symbols.toList()..sort();

  /// Returns the size of the alphabet
  int get size => symbols.length;

  /// Returns true if the alphabet is empty
  bool get isEmpty => symbols.isEmpty;

  /// Returns true if the alphabet is not empty
  bool get isNotEmpty => symbols.isNotEmpty;

  /// Creates a new alphabet with an additional symbol
  Alphabet add(String symbol) {
    return Alphabet(
      symbols: {...symbols, symbol},
      isCaseSensitive: isCaseSensitive,
    );
  }

  /// Creates a new alphabet with additional symbols
  Alphabet addAll(Iterable<String> newSymbols) {
    return Alphabet(
      symbols: {...symbols, ...newSymbols},
      isCaseSensitive: isCaseSensitive,
    );
  }

  /// Creates a new alphabet by merging with another alphabet
  Alphabet merge(Alphabet other) {
    return Alphabet(
      symbols: {...symbols, ...other.symbols},
      isCaseSensitive: isCaseSensitive || other.isCaseSensitive,
    );
  }
}
