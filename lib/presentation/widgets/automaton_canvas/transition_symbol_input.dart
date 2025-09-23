/// Parses user provided transition symbols, keeping an ordered label and
/// exposing the optional epsilon marker when present.
class TransitionSymbolInput {
  final String label;
  final Set<String> inputSymbols;
  final String? lambdaSymbol;

  const TransitionSymbolInput({
    required this.label,
    required this.inputSymbols,
    required this.lambdaSymbol,
  });

  /// Parses a comma-separated list of symbols, recognizing aliases for the
  /// epsilon transition (e.g. "ε", "epsilon", "lambda"). Tokens are trimmed
  /// and empty entries are ignored while preserving the original ordering of
  /// unique symbols.
  static TransitionSymbolInput? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return null;
    }

    final tokens = text
        .split(',')
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return null;
    }

    var containsEpsilon = false;
    final orderedSymbols = <String>[];

    for (final token in tokens) {
      // Treat the token as epsilon when it matches any known alias.
      if (_isEpsilonToken(token)) {
        containsEpsilon = true;
      } else {
        orderedSymbols.add(token);
      }
    }

    if (containsEpsilon && orderedSymbols.isEmpty) {
      return const TransitionSymbolInput(
        label: 'ε',
        inputSymbols: <String>{},
        lambdaSymbol: 'ε',
      );
    }

    if (orderedSymbols.isEmpty) {
      return null;
    }

    final uniqueSymbols = <String>{};
    final preservedOrder = <String>[];
    for (final symbol in orderedSymbols) {
      // Retain the original appearance order while removing duplicates.
      if (uniqueSymbols.add(symbol)) {
        preservedOrder.add(symbol);
      }
    }

    final label = preservedOrder.join(', ');
    return TransitionSymbolInput(
      label: label,
      inputSymbols: uniqueSymbols,
      lambdaSymbol: null,
    );
  }

  /// Returns `true` when [token] represents epsilon. Accepted aliases include
  /// "ε", "epsilon", "eps" and "lambda" (case-insensitive).
  static bool _isEpsilonToken(String token) {
    final normalized = token.toLowerCase();
    return normalized == 'ε' ||
        normalized == 'epsilon' ||
        normalized == 'eps' ||
        normalized == 'lambda';
  }
}
