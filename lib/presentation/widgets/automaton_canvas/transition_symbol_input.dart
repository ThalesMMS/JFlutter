class TransitionSymbolInput {
  final String label;
  final Set<String> inputSymbols;
  final String? lambdaSymbol;

  const TransitionSymbolInput({
    required this.label,
    required this.inputSymbols,
    required this.lambdaSymbol,
  });

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

  static bool _isEpsilonToken(String token) {
    final normalized = token.toLowerCase();
    return normalized == 'ε' ||
        normalized == 'epsilon' ||
        normalized == 'eps' ||
        normalized == 'lambda';
  }
}
