part of 'regex_to_nfa_converter.dart';

/// Validates the regular expression
Result<void> _validateRegex(String regex) {
  final validation = _validateRegexSyntax(regex);
  return validation.isValid
      ? ResultFactory.success(null)
      : ResultFactory.failure(validation.diagnostic!.displayMessage);
}

Result<void> _validateContextAlphabet(
  String regex,
  Set<String>? contextAlphabet,
) {
  final requiresAlphabet = _tokenize(regex).any(
    (token) =>
        token.type == TokenType.dot ||
        (token.type == TokenType.charShortcut &&
            const {'D', 'W', 'S'}.contains(token.value)),
  );
  if (requiresAlphabet &&
      (contextAlphabet == null || contextAlphabet.isEmpty)) {
    return ResultFactory.failure(
      'This expression uses . or a complemented shortcut and requires a '
      'non-empty alphabet universe.',
    );
  }
  return ResultFactory.success(null);
}

RegexValidationResult _validateRegexSyntax(String regex) {
  if (regex.isEmpty) {
    return const RegexValidationResult.invalid(
      RegexValidationDiagnostic(
        message: 'Regular expression cannot be empty',
        position: 0,
        length: 0,
        category: RegexValidationCategory.emptyExpression,
      ),
    );
  }

  RegexValidationResult invalid(
    String message,
    int position,
    RegexValidationCategory category, {
    int length = 1,
  }) {
    return RegexValidationResult.invalid(
      RegexValidationDiagnostic(
        message: message,
        position: position,
        length: length,
        category: category,
      ),
    );
  }

  final openParentheses = <int>[];
  var expectsOperand = true;
  var previousWasQuantifier = false;
  for (int i = 0; i < regex.length; i++) {
    final char = regex[i];

    if (char == '\\') {
      if (i + 1 >= regex.length) {
        return invalid(
          'Escape character must be followed by a symbol',
          i,
          RegexValidationCategory.escape,
        );
      }
      i++;
      expectsOperand = false;
      previousWasQuantifier = false;
      continue;
    }

    if (char == '[') {
      final classStart = i;
      final contentStart = i + 1;
      var escapedInClass = false;
      i++;
      while (i < regex.length) {
        if (escapedInClass) {
          escapedInClass = false;
        } else if (regex[i] == '\\') {
          escapedInClass = true;
        } else if (regex[i] == ']') {
          break;
        }
        i++;
      }
      if (i >= regex.length || regex[i] != ']') {
        return invalid(
          'Character class is not closed',
          classStart,
          RegexValidationCategory.characterClass,
          length: regex.length - classStart,
        );
      }
      if (escapedInClass) {
        return invalid(
          'Escape character in class must be followed by a symbol',
          i - 1,
          RegexValidationCategory.escape,
        );
      }
      final content = regex.substring(contentStart, i);
      if (content.isEmpty) {
        return invalid(
          'Character class cannot be empty',
          classStart,
          RegexValidationCategory.characterClass,
          length: 2,
        );
      }
      for (var offset = 1; offset + 1 < content.length; offset++) {
        if (content[offset] == '-' &&
            content[offset - 1].codeUnitAt(0) >
                content[offset + 1].codeUnitAt(0)) {
          return invalid(
            'Character class range must be in ascending order',
            contentStart + offset - 1,
            RegexValidationCategory.characterClass,
            length: 3,
          );
        }
      }
      expectsOperand = false;
      previousWasQuantifier = false;
      continue;
    }

    if (char == ']') {
      return invalid(
        'Closing bracket has no matching opening bracket',
        i,
        RegexValidationCategory.delimiter,
      );
    }

    if (char == '(') {
      openParentheses.add(i);
      expectsOperand = true;
      previousWasQuantifier = false;
      continue;
    }
    if (char == ')') {
      if (openParentheses.isEmpty) {
        return invalid(
          'Unbalanced parentheses: closing parenthesis has no matching opening parenthesis',
          i,
          RegexValidationCategory.delimiter,
        );
      }
      if (expectsOperand) {
        return invalid(
          'Parenthesized expression is missing an operand',
          i,
          RegexValidationCategory.operatorPlacement,
        );
      }
      openParentheses.removeLast();
      expectsOperand = false;
      previousWasQuantifier = false;
      continue;
    }

    if (char == '|') {
      if (expectsOperand) {
        return invalid(
          'Union operator is missing a left operand',
          i,
          RegexValidationCategory.operatorPlacement,
        );
      }
      expectsOperand = true;
      previousWasQuantifier = false;
      continue;
    }

    if (char == '*' || char == '+' || char == '?') {
      if (expectsOperand) {
        return invalid(
          'A quantifier must follow an expression',
          i,
          RegexValidationCategory.operatorPlacement,
        );
      }
      if (previousWasQuantifier) {
        return invalid(
          'Consecutive quantifiers are not allowed',
          i,
          RegexValidationCategory.operatorPlacement,
        );
      }
      previousWasQuantifier = true;
      continue;
    }

    expectsOperand = false;
    previousWasQuantifier = false;
  }

  if (openParentheses.isNotEmpty) {
    return invalid(
      'Unbalanced parentheses: opening parenthesis is not closed',
      openParentheses.last,
      RegexValidationCategory.delimiter,
    );
  }

  if (expectsOperand) {
    return invalid(
      'Union operator is missing a right operand',
      regex.length - 1,
      RegexValidationCategory.operatorPlacement,
    );
  }

  if (_parseRegex(regex) == null) {
    return invalid(
      'Invalid regular expression syntax',
      regex.length - 1,
      RegexValidationCategory.syntax,
    );
  }

  return const RegexValidationResult.valid();
}

/// Parses the regular expression into an abstract syntax tree
RegexNode? _parseRegex(String regex) {
  try {
    final tokens = _tokenize(regex);
    final parsed = _parseExpression(tokens);
    return tokens.isEmpty ? parsed : null;
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
