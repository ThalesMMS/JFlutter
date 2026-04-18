part of 'regex_to_nfa_converter.dart';

/// Validates the regular expression
Result<void> _validateRegex(String regex) {
  if (regex.isEmpty) {
    return ResultFactory.failure('Regular expression cannot be empty');
  }

  // Check for balanced parentheses
  int parenCount = 0;
  var escaped = false;
  var inCharClass = false;
  for (int i = 0; i < regex.length; i++) {
    final char = regex[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (char == '\\') {
      escaped = true;
      continue;
    }
    if (char == '[') {
      inCharClass = true;
      continue;
    }
    if (char == ']') {
      inCharClass = false;
      continue;
    }
    if (inCharClass) {
      continue;
    }
    if (char == '(') {
      parenCount++;
    } else if (char == ')') {
      parenCount--;
      if (parenCount < 0) {
        return ResultFactory.failure(
          'Unbalanced parentheses in regular expression',
        );
      }
    }
  }

  if (parenCount != 0) {
    return ResultFactory.failure(
      'Unbalanced parentheses in regular expression',
    );
  }

  // Check operator placement (reject repeated quantifiers and leading quantifiers)
  // Disallow patterns like '**', '++', '??', '*+', '+*', '?*', etc., and starting with quantifier
  const quantifiers = {'*', '+', '?'};
  if (regex.isNotEmpty && quantifiers.contains(regex[0])) {
    return ResultFactory.failure('Regex cannot start with a quantifier');
  }
  inCharClass = false;
  for (int i = 1; i < regex.length; i++) {
    final curr = regex[i];
    if (curr == '[') {
      inCharClass = true;
      continue;
    }
    if (curr == ']') {
      inCharClass = false;
      continue;
    }
    if (inCharClass || regex[i - 1] == '\\') {
      continue;
    }
    final prev = regex[i - 1];
    if (quantifiers.contains(prev) && quantifiers.contains(curr)) {
      return ResultFactory.failure('Consecutive quantifiers are not allowed');
    }
    if (curr == '|' && (i == 0 || i == regex.length - 1)) {
      return ResultFactory.failure('Union operator cannot be at ends');
    }
    if (curr == ')' && (i == 0 || regex[i - 1] == '(')) {
      return ResultFactory.failure('Empty parentheses are not allowed');
    }
  }

  return ResultFactory.success(null);
}

/// Parses the regular expression into an abstract syntax tree
RegexNode? _parseRegex(String regex) {
  try {
    final tokens = _tokenize(regex);
    return _parseExpression(tokens);
  } catch (e) {
    return null;
  }
}

/// Tokenizes the regular expression
List<RegexToken> _tokenize(String regex) {
  final tokens = <RegexToken>[];
  int i = 0;

  while (i < regex.length) {
    final char = regex[i];

    switch (char) {
      case '(':
        tokens.add(
          RegexToken(type: TokenType.leftParen, value: char, position: i),
        );
        break;
      case ')':
        tokens.add(
          RegexToken(type: TokenType.rightParen, value: char, position: i),
        );
        break;
      case '|':
        tokens.add(RegexToken(type: TokenType.union, value: char, position: i));
        break;
      case '*':
        tokens.add(
          RegexToken(type: TokenType.kleeneStar, value: char, position: i),
        );
        break;
      case '+':
        tokens.add(RegexToken(type: TokenType.plus, value: char, position: i));
        break;
      case '?':
        tokens.add(
          RegexToken(type: TokenType.question, value: char, position: i),
        );
        break;
      case '.':
        tokens.add(RegexToken(type: TokenType.dot, value: char, position: i));
        break;
      case '[':
        // Character class until ']'
        int j = i + 1;
        final buf = StringBuffer();
        while (j < regex.length && regex[j] != ']') {
          // handle escaped chars inside class
          if (regex[j] == '\\' && j + 1 < regex.length && regex[j + 1] != ']') {
            buf.write(regex[j + 1]);
            j += 2;
            continue;
          }
          buf.write(regex[j]);
          j++;
        }
        if (j >= regex.length || regex[j] != ']') {
          // Unclosed class → treat '[' literal
          tokens.add(
            RegexToken(type: TokenType.symbol, value: char, position: i),
          );
        } else {
          tokens.add(
            RegexToken(
              type: TokenType.charClass,
              value: buf.toString(),
              position: i,
            ),
          );
          i = j; // will be incremented by i++ at end
        }
        break;
      case '\\':
        if (i + 1 < regex.length) {
          final next = regex[i + 1];
          // common shortcuts
          if ('dDsSwW'.contains(next)) {
            tokens.add(
              RegexToken(
                  type: TokenType.charShortcut, value: next, position: i),
            );
            i++;
            break;
          }
          // escaped metachar -> literal
          tokens.add(
            RegexToken(type: TokenType.symbol, value: next, position: i),
          );
          i++;
        } else {
          tokens.add(
            RegexToken(type: TokenType.symbol, value: char, position: i),
          );
        }
        break;
      default:
        if (char == 'ε') {
          tokens.add(
            RegexToken(type: TokenType.epsilon, value: char, position: i),
          );
        } else {
          tokens.add(
            RegexToken(type: TokenType.symbol, value: char, position: i),
          );
        }
        break;
    }

    i++;
  }

  return tokens;
}

/// Parses the expression from tokens
RegexNode? _parseExpression(List<RegexToken> tokens) {
  if (tokens.isEmpty) return null;

  final node = _parseUnion(tokens);
  return node;
}

/// Parses union expressions (|)
RegexNode? _parseUnion(List<RegexToken> tokens) {
  var node = _parseConcatenation(tokens);

  while (tokens.isNotEmpty && tokens.first.type == TokenType.union) {
    final token = tokens.removeAt(0); // Remove |
    final right = _parseConcatenation(tokens);
    if (right == null) return null;
    node = UnionNode(left: node!, right: right, position: token.position);
  }

  return node;
}

/// Parses concatenation expressions
RegexNode? _parseConcatenation(List<RegexToken> tokens) {
  var node = _parseUnary(tokens);

  while (tokens.isNotEmpty &&
      tokens.first.type != TokenType.union &&
      tokens.first.type != TokenType.rightParen) {
    final right = _parseUnary(tokens);
    if (right == null) return null;
    node = ConcatenationNode(
      left: node!,
      right: right,
    );
  }

  return node;
}

/// Parses unary expressions (*, +, ?)
RegexNode? _parseUnary(List<RegexToken> tokens) {
  var node = _parsePrimary(tokens);

  while (tokens.isNotEmpty) {
    final token = tokens.first;
    switch (token.type) {
      case TokenType.kleeneStar:
        tokens.removeAt(0);
        node = KleeneStarNode(child: node!, position: token.position);
        break;
      case TokenType.plus:
        tokens.removeAt(0);
        node = PlusNode(child: node!, position: token.position);
        break;
      case TokenType.question:
        tokens.removeAt(0);
        node = QuestionNode(child: node!, position: token.position);
        break;
      default:
        return node;
    }
  }

  return node;
}

/// Parses primary expressions (symbols, parentheses)
RegexNode? _parsePrimary(List<RegexToken> tokens) {
  if (tokens.isEmpty) return null;

  final token = tokens.removeAt(0);

  switch (token.type) {
    case TokenType.symbol:
      return SymbolNode(symbol: token.value, position: token.position);
    case TokenType.dot:
      return DotNode(position: token.position);
    case TokenType.epsilon:
      return EpsilonNode(position: token.position);
    case TokenType.charClass:
      return SetNode(
        symbols: _parseCharClass(token.value),
        position: token.position,
      );
    case TokenType.charShortcut:
      return ShortcutNode(code: token.value, position: token.position);
    case TokenType.leftParen:
      final node = _parseExpression(tokens);
      if (tokens.isEmpty || tokens.removeAt(0).type != TokenType.rightParen) {
        return null;
      }
      return node;
    default:
      return null;
  }
}
