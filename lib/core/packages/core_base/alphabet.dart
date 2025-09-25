/// Minimal interface representing an immutable alphabet of symbols.
abstract class Alphabet<SymbolT> {
  /// All symbols that belong to the alphabet.
  Set<SymbolT> get symbols;

  /// Checks if [symbol] belongs to this alphabet.
  bool contains(SymbolT symbol) => symbols.contains(symbol);

  /// Creates a new alphabet that also contains [symbol].
  Alphabet<SymbolT> add(SymbolT symbol);

  /// Creates a new alphabet with all symbols from this and [other].
  Alphabet<SymbolT> merge(Alphabet<SymbolT> other) => addAll(other.symbols);

  /// Creates a new alphabet that contains [extra] symbols in addition to this.
  Alphabet<SymbolT> addAll(Iterable<SymbolT> extra);
}

/// Basic immutable implementation for [Alphabet].
class ImmutableAlphabet<SymbolT> implements Alphabet<SymbolT> {
  ImmutableAlphabet(Iterable<SymbolT> symbols)
      : _symbols = Set<SymbolT>.unmodifiable(symbols);

  final Set<SymbolT> _symbols;

  @override
  Set<SymbolT> get symbols => _symbols;

  @override
  bool contains(SymbolT symbol) => _symbols.contains(symbol);

  @override
  Alphabet<SymbolT> add(SymbolT symbol) {
    if (_symbols.contains(symbol)) {
      return this;
    }
    return ImmutableAlphabet<SymbolT>([..._symbols, symbol]);
  }

  @override
  Alphabet<SymbolT> addAll(Iterable<SymbolT> extra) {
    if (extra.isEmpty) {
      return this;
    }
    return ImmutableAlphabet<SymbolT>({..._symbols, ...extra});
  }

  @override
  Alphabet<SymbolT> merge(Alphabet<SymbolT> other) {
    if (identical(this, other)) {
      return this;
    }
    return ImmutableAlphabet<SymbolT>({..._symbols, ...other.symbols});
  }
}
