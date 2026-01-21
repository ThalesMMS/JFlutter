//
//  regex_simplifier.dart
//  JFlutter
//
//  Implementa simplificação de expressões regulares através da aplicação de
//  identidades algébricas e remoção de parênteses desnecessários. Recebe uma
//  expressão regular gerada pelo algoritmo de eliminação de estados e produz
//  uma versão equivalente mais legível, aplicando regras iterativamente até
//  atingir um ponto fixo.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import '../result.dart';

/// Simplifies regular expressions by applying algebraic identities and removing unnecessary parentheses
class RegexSimplifier {
  /// Simplifies a regular expression to a more readable form
  ///
  /// Applies the following transformations:
  /// - Removes unnecessary parentheses (outer, nested, redundant)
  /// - Applies algebraic identities (∅, ε elimination, idempotence)
  /// - Iterates until a fixed point is reached (no more changes)
  ///
  /// Returns a [Result] containing the simplified regex string on success,
  /// or an error message on failure.
  static Result<String> simplify(String regex) {
    try {
      // Validate input
      final validationResult = _validateInput(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty regex
      if (regex.trim().isEmpty) {
        return ResultFactory.failure('Cannot simplify empty regex');
      }

      // Apply simplification rules iteratively
      String simplified = regex;
      String previous;

      // Iterate until fixed point (no more changes)
      do {
        previous = simplified;
        simplified = _removeRedundantParentheses(simplified);
        simplified = _applyAlgebraicIdentities(simplified);
      } while (simplified != previous);

      return ResultFactory.success(simplified);
    } catch (e) {
      return ResultFactory.failure('Error simplifying regex: $e');
    }
  }

  /// Validates the input regex string
  static Result<void> _validateInput(String regex) {
    if (regex.isEmpty) {
      return ResultFactory.failure('Regex cannot be empty');
    }

    // Check for balanced parentheses
    final balanceResult = _checkBalancedParentheses(regex);
    if (!balanceResult.isSuccess) {
      return balanceResult;
    }

    return ResultFactory.success(null);
  }

  /// Checks if parentheses are balanced in the regex
  static Result<void> _checkBalancedParentheses(String regex) {
    int count = 0;
    for (int i = 0; i < regex.length; i++) {
      if (regex[i] == '(') {
        count++;
      } else if (regex[i] == ')') {
        count--;
        if (count < 0) {
          return ResultFactory.failure(
            'Unbalanced parentheses: closing parenthesis at position $i has no matching opening parenthesis',
          );
        }
      }
    }

    if (count != 0) {
      return ResultFactory.failure(
        'Unbalanced parentheses: $count unclosed opening parenthesis(es)',
      );
    }

    return ResultFactory.success(null);
  }

  /// Removes redundant parentheses from the regex
  ///
  /// Handles three types of redundant parentheses:
  /// 1. Outer parentheses: (a) → a, (a|b) → a|b (when they wrap the entire expression and no operator follows)
  /// 2. Nested parentheses: ((a)) → (a) → a
  /// 3. Redundant parentheses around single symbols in concatenation: (a)(b) → ab
  static String _removeRedundantParentheses(String regex) {
    if (regex.isEmpty) return regex;

    String result = regex;

    // Step 1: Remove outer parentheses if they wrap the entire expression
    // and are not followed by an operator (*, +, ?)
    result = _removeOuterParentheses(result);

    // Step 2: Remove redundant parentheses around single symbols in concatenation
    // Pattern: (x) where x is a single symbol and not followed by *, +, ?
    result = _removeSingleSymbolParentheses(result);

    return result;
  }

  /// Removes outer parentheses if they wrap the entire expression
  /// and are not necessary for grouping
  static String _removeOuterParentheses(String regex) {
    if (regex.length < 2) return regex;
    if (regex[0] != '(') return regex;

    // Check if the first parenthesis matches the last one
    // and they wrap the entire expression
    int depth = 0;
    int matchingIndex = -1;

    for (int i = 0; i < regex.length; i++) {
      if (regex[i] == '(') {
        depth++;
      } else if (regex[i] == ')') {
        depth--;
        if (depth == 0) {
          matchingIndex = i;
          break;
        }
      }
    }

    // If the matching closing parenthesis is the last character
    // and is not followed by an operator, we can remove it
    if (matchingIndex == regex.length - 1) {
      return regex.substring(1, regex.length - 1);
    }

    // If the matching closing parenthesis is followed only by an operator
    // that applies to the whole group, check if we can still remove it
    if (matchingIndex < regex.length - 1) {
      final afterParen = regex[matchingIndex + 1];
      // If followed by *, +, or ?, we need to check the content
      if (afterParen == '*' || afterParen == '+' || afterParen == '?') {
        // Check if the content inside is a single symbol
        final content = regex.substring(1, matchingIndex);
        if (_isSingleSymbol(content)) {
          // (a)* → a*
          return content + afterParen + regex.substring(matchingIndex + 2);
        }
      }
    }

    return regex;
  }

  /// Removes redundant parentheses around single symbols
  /// Example: (a)(b) → ab, a(b) → ab, (a)b → ab
  static String _removeSingleSymbolParentheses(String regex) {
    final buffer = StringBuffer();
    int i = 0;

    while (i < regex.length) {
      if (regex[i] == '(') {
        // Find the matching closing parenthesis
        final closeIndex = _findMatchingCloseParen(regex, i);
        if (closeIndex == -1) {
          // Shouldn't happen if validation passed, but handle gracefully
          buffer.write(regex[i]);
          i++;
          continue;
        }

        final content = regex.substring(i + 1, closeIndex);

        // Check if followed by an operator
        final hasOperatorAfter = closeIndex + 1 < regex.length &&
            (regex[closeIndex + 1] == '*' ||
                regex[closeIndex + 1] == '+' ||
                regex[closeIndex + 1] == '?');

        // Remove parentheses if:
        // 1. Content is a single symbol AND
        // 2. Not followed by an operator (or operator can be applied without parens)
        if (_isSingleSymbol(content) && !hasOperatorAfter) {
          buffer.write(content);
          i = closeIndex + 1;
        } else if (_isSingleSymbol(content) && hasOperatorAfter) {
          // (a)* → a*
          buffer.write(content);
          buffer.write(regex[closeIndex + 1]);
          i = closeIndex + 2;
        } else {
          // Keep the parentheses for complex expressions
          buffer.write(regex.substring(i, closeIndex + 1));
          i = closeIndex + 1;
        }
      } else {
        buffer.write(regex[i]);
        i++;
      }
    }

    return buffer.toString();
  }

  /// Finds the index of the matching closing parenthesis
  static int _findMatchingCloseParen(String regex, int openIndex) {
    int depth = 0;
    for (int i = openIndex; i < regex.length; i++) {
      if (regex[i] == '(') {
        depth++;
      } else if (regex[i] == ')') {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }
    return -1;
  }

  /// Checks if a string represents a single symbol (not a complex expression)
  /// Single symbols include:
  /// - Single characters (a, b, 0, 1, etc.)
  /// - Epsilon (ε)
  /// - Empty string (special case)
  static bool _isSingleSymbol(String s) {
    if (s.isEmpty) return true;
    if (s.length == 1) return true;

    // Check for epsilon
    if (s == 'ε' || s == 'λ') return true;

    // If it contains operators or parentheses, it's not a single symbol
    if (s.contains('|') || s.contains('*') || s.contains('+') ||
        s.contains('?') || s.contains('(') || s.contains(')')) {
      return false;
    }

    // If longer than 1 character and not epsilon, it's a concatenation
    return s.length == 1;
  }

  /// Applies algebraic identities to simplify the regex
  ///
  /// Handles three categories of identities:
  /// 1. Empty set (∅) identities:
  ///    - r|∅ → r, ∅|r → r (union with empty set)
  ///    - r∅ → ∅, ∅r → ∅ (concatenation with empty set)
  ///    - ∅* → ε (Kleene star of empty set)
  /// 2. Epsilon (ε) identities:
  ///    - rε → r, εr → r (concatenation with epsilon)
  ///    - ε* → ε (Kleene star of epsilon)
  /// 3. Idempotence:
  ///    - r|r → r (union idempotence)
  ///    - r** → r* (double Kleene star)
  static String _applyAlgebraicIdentities(String regex) {
    if (regex.isEmpty) return regex;

    String result = regex;

    // Apply identities in order
    result = _applyEmptySetIdentities(result);
    result = _applyEpsilonIdentities(result);
    result = _applyIdempotenceIdentities(result);

    return result;
  }

  /// Applies empty set (∅) identities
  static String _applyEmptySetIdentities(String regex) {
    String result = regex;

    // ∅* → ε
    result = result.replaceAll('∅*', 'ε');

    // r|∅ → r and ∅|r → r (union with empty set)
    result = _removeEmptySetFromUnion(result);

    // r∅ → ∅ and ∅r → ∅ (concatenation with empty set)
    result = _simplifyEmptySetConcatenation(result);

    return result;
  }

  /// Removes empty set from union expressions
  static String _removeEmptySetFromUnion(String regex) {
    final buffer = StringBuffer();
    int i = 0;

    while (i < regex.length) {
      if (i < regex.length - 1 && regex[i] == '∅' && regex[i + 1] == '|') {
        // ∅|r → r
        i += 2; // Skip ∅|
      } else if (i > 0 && regex[i] == '∅' && i > 0 && regex[i - 1] == '|') {
        // r|∅ → r (already handled by removing |∅)
        // This case is handled by looking ahead
        buffer.write(regex[i]);
        i++;
      } else if (i < regex.length - 1 && regex[i] == '|' && regex[i + 1] == '∅') {
        // r|∅ → r
        i += 2; // Skip |∅
      } else {
        buffer.write(regex[i]);
        i++;
      }
    }

    return buffer.toString();
  }

  /// Simplifies concatenation with empty set
  static String _simplifyEmptySetConcatenation(String regex) {
    // Any concatenation with ∅ results in ∅
    // We need to identify concatenation segments and check if any contain ∅

    // Simple case: if the entire expression is just symbols concatenated
    // and one is ∅, the whole thing becomes ∅
    final segments = _splitIntoConcatenationSegments(regex);

    for (final segment in segments) {
      if (segment.contains('∅') && !segment.contains('|')) {
        // This segment has ∅ in concatenation, replace entire segment with ∅
        // But we need to be careful about union context
        return regex.replaceAll(segment, '∅');
      }
    }

    return regex;
  }

  /// Splits regex into concatenation segments (separated by |)
  static List<String> _splitIntoConcatenationSegments(String regex) {
    final segments = <String>[];
    final buffer = StringBuffer();
    int depth = 0;

    for (int i = 0; i < regex.length; i++) {
      if (regex[i] == '(') {
        depth++;
        buffer.write(regex[i]);
      } else if (regex[i] == ')') {
        depth--;
        buffer.write(regex[i]);
      } else if (regex[i] == '|' && depth == 0) {
        segments.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(regex[i]);
      }
    }

    if (buffer.isNotEmpty) {
      segments.add(buffer.toString());
    }

    return segments;
  }

  /// Applies epsilon (ε) identities
  static String _applyEpsilonIdentities(String regex) {
    String result = regex;

    // ε* → ε
    result = result.replaceAll('ε*', 'ε');

    // Remove epsilon from concatenation
    result = _removeEpsilonFromConcatenation(result);

    return result;
  }

  /// Removes epsilon from concatenation (εr → r, rε → r)
  static String _removeEpsilonFromConcatenation(String regex) {
    String result = regex;

    // Remove ε in concatenation, but not in union
    // We need to be careful not to remove ε when it's the only element

    bool changed;
    do {
      changed = false;
      final buffer = StringBuffer();
      int i = 0;

      while (i < regex.length) {
        if (regex[i] == 'ε') {
          // Check context - is this in a concatenation?
          final before = i > 0 ? regex[i - 1] : '';
          final after = i < regex.length - 1 ? regex[i + 1] : '';

          // Skip ε if it's in concatenation (not after | or ( or start, and not before | or ) or end or *)
          final inConcatenation =
              (before != '' && before != '|' && before != '(') ||
                  (after != '' && after != '|' && after != ')' && after != '*');

          if (inConcatenation && regex != 'ε') {
            // Skip the epsilon
            changed = true;
            i++;
            continue;
          }
        }

        buffer.write(regex[i]);
        i++;
      }

      if (changed) {
        regex = buffer.toString();
      }
    } while (changed);

    return regex;
  }

  /// Applies idempotence identities
  static String _applyIdempotenceIdentities(String regex) {
    String result = regex;

    // r** → r*, r*** → r*, etc.
    result = _reduceMultipleStars(result);

    // r|r → r (union idempotence)
    result = _applyUnionIdempotence(result);

    return result;
  }

  /// Reduces multiple consecutive Kleene stars to a single star
  static String _reduceMultipleStars(String regex) {
    // Match any character followed by multiple stars and reduce to single star
    final buffer = StringBuffer();
    int i = 0;

    while (i < regex.length) {
      buffer.write(regex[i]);

      if (regex[i] == '*') {
        // Skip any additional consecutive stars
        while (i + 1 < regex.length && regex[i + 1] == '*') {
          i++;
        }
      }

      i++;
    }

    return buffer.toString();
  }

  /// Applies union idempotence (r|r → r)
  static String _applyUnionIdempotence(String regex) {
    // Split by | at top level and check for duplicates
    final segments = _splitIntoConcatenationSegments(regex);

    if (segments.length <= 1) return regex;

    // Remove duplicates while preserving order
    final seen = <String>{};
    final unique = <String>[];

    for (final segment in segments) {
      if (!seen.contains(segment)) {
        seen.add(segment);
        unique.add(segment);
      }
    }

    if (unique.length < segments.length) {
      return unique.join('|');
    }

    return regex;
  }
}
