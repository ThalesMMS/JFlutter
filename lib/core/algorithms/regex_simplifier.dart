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
  ///
  /// Performs basic validation to ensure the regex is well-formed:
  /// - Non-empty string
  /// - Balanced parentheses
  ///
  /// This validation catches structural errors before attempting simplification,
  /// preventing runtime errors and providing clear error messages.
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
  ///
  /// Uses a counter-based algorithm:
  /// - Increment counter for '('
  /// - Decrement counter for ')'
  /// - Counter going negative indicates unmatched closing parenthesis
  /// - Non-zero final counter indicates unmatched opening parentheses
  ///
  /// Time complexity: O(n) where n is the length of the regex
  /// Space complexity: O(1)
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
  ///
  /// Algorithm:
  /// 1. Find the matching closing parenthesis for the opening '(' at position 0
  /// 2. If it matches the last character and no operator follows, remove both
  /// 3. Special case: (a)* where a is a single symbol can become a*
  ///
  /// Examples:
  /// - (a|b) → a|b (outer parens wrapping entire expression)
  /// - (a)* → a* (single symbol with operator can lose parens)
  /// - (a|b)* → (a|b)* (complex expression needs parens for operator)
  /// - (a)(b) → (a)(b) (not outer parens, handled by _removeSingleSymbolParentheses)
  ///
  /// Time complexity: O(n) for finding matching parenthesis
  static String _removeOuterParentheses(String regex) {
    if (regex.length < 2) return regex;
    if (regex[0] != '(') return regex;

    // Check if the first parenthesis matches the last one
    // and they wrap the entire expression
    // Uses depth tracking to handle nested parentheses correctly
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
          // (a)* → a* (operator can apply directly to single symbol)
          return content + afterParen + regex.substring(matchingIndex + 2);
        }
      }
    }

    return regex;
  }

  /// Removes redundant parentheses around single symbols
  ///
  /// Scans the regex left-to-right and identifies parenthesized groups.
  /// If a group contains only a single symbol and is not followed by an operator,
  /// or if it's a single symbol followed by an operator, the parentheses are removed.
  ///
  /// Examples:
  /// - (a)(b) → ab (concatenation of single symbols)
  /// - a(b) → ab (single symbol doesn't need parens)
  /// - (a)b → ab (single symbol doesn't need parens)
  /// - (a)* → a* (single symbol with operator can lose parens)
  /// - (a|b) → (a|b) (complex expression keeps parens)
  /// - (a|b)* → (a|b)* (complex expression needs parens for operator)
  ///
  /// Time complexity: O(n²) worst case due to nested _findMatchingCloseParen calls
  /// Space complexity: O(n) for the StringBuffer
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
        final hasOperatorAfter =
            closeIndex + 1 < regex.length &&
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
          // (a)* → a* (operator can apply directly to single symbol)
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
  ///
  /// Uses depth tracking to handle nested parentheses:
  /// - Increment depth for each '('
  /// - Decrement depth for each ')'
  /// - Return index when depth reaches 0 (matching parenthesis found)
  ///
  /// Time complexity: O(n) where n is the length from openIndex to end
  /// Space complexity: O(1)
  ///
  /// Returns -1 if no matching parenthesis is found (shouldn't happen after validation)
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
  ///
  /// Single symbols include:
  /// - Single characters (a, b, 0, 1, etc.)
  /// - Epsilon (ε or λ)
  /// - Empty string (special case)
  ///
  /// Not single symbols:
  /// - Expressions with operators (|, *, +, ?)
  /// - Expressions with parentheses
  /// - Concatenations (multiple characters)
  ///
  /// Examples:
  /// - 'a' → true (single character)
  /// - 'ε' → true (epsilon)
  /// - 'ab' → false (concatenation)
  /// - 'a|b' → false (union)
  /// - 'a*' → false (contains operator)
  ///
  /// Time complexity: O(n) where n is the length of s
  /// Space complexity: O(1)
  static bool _isSingleSymbol(String s) {
    if (s.isEmpty) return true;
    if (s.length == 1) return true;

    // Check for epsilon
    if (s == 'ε' || s == 'λ') return true;

    // If it contains operators or parentheses, it's not a single symbol
    if (s.contains('|') ||
        s.contains('*') ||
        s.contains('+') ||
        s.contains('?') ||
        s.contains('(') ||
        s.contains(')')) {
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
  ///
  /// Empty set identities from regular expression algebra:
  /// - ∅* → ε (Kleene star of empty set is epsilon)
  /// - r|∅ → r (union with empty set is the other expression)
  /// - ∅|r → r (union is commutative)
  /// - r∅ → ∅ (concatenation with empty set is empty)
  /// - ∅r → ∅ (concatenation with empty set is empty)
  ///
  /// These identities are fundamental to regex simplification and
  /// help reduce complex expressions generated by state elimination algorithms.
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
  ///
  /// Handles two cases:
  /// 1. ∅|r → r (empty set at start of union)
  /// 2. r|∅ → r (empty set at end of union)
  ///
  /// Must be careful to handle multiple unions correctly,
  /// e.g., ∅|a|b should become a|b, not just a|b with ∅ removed.
  ///
  /// Time complexity: O(n)
  /// Space complexity: O(n)
  static String _removeEmptySetFromUnion(String regex) {
    final buffer = StringBuffer();
    int i = 0;

    while (i < regex.length) {
      if (i < regex.length - 1 && regex[i] == '∅' && regex[i + 1] == '|') {
        // ∅|r → r (skip the empty set and union operator)
        i += 2; // Skip ∅|
      } else if (i > 0 && regex[i] == '∅' && i > 0 && regex[i - 1] == '|') {
        // r|∅ → r (already handled by removing |∅)
        // This case is handled by looking ahead
        buffer.write(regex[i]);
        i++;
      } else if (i < regex.length - 1 &&
          regex[i] == '|' &&
          regex[i + 1] == '∅') {
        // r|∅ → r (skip the union operator and empty set)
        i += 2; // Skip |∅
      } else {
        buffer.write(regex[i]);
        i++;
      }
    }

    return buffer.toString();
  }

  /// Simplifies concatenation with empty set
  ///
  /// According to regex algebra: r∅ = ∅r = ∅
  /// Any expression concatenated with the empty set results in the empty set.
  ///
  /// Algorithm:
  /// 1. Split regex into union segments (top-level | operators)
  /// 2. For each segment, check if it contains ∅ in concatenation context
  /// 3. If so, replace entire segment with ∅
  ///
  /// Example:
  /// - a∅b → ∅ (entire concatenation becomes empty)
  /// - a|∅b → a|∅ (only second union segment becomes empty)
  ///
  /// Time complexity: O(n)
  /// Space complexity: O(n) for segments list
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
  ///
  /// Splits at top-level union operators (|) only, respecting parentheses depth.
  /// This allows us to process each union alternative independently.
  ///
  /// Algorithm:
  /// - Track parenthesis depth
  /// - Split at | only when depth is 0 (top level)
  /// - Preserve all characters within parenthesized groups
  ///
  /// Examples:
  /// - 'a|b|c' → ['a', 'b', 'c']
  /// - '(a|b)|c' → ['(a|b)', 'c']
  /// - 'a(b|c)d' → ['a(b|c)d'] (no top-level |)
  ///
  /// Time complexity: O(n)
  /// Space complexity: O(n) for segments list
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
        // Top-level union operator - split here
        segments.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(regex[i]);
      }
    }

    // Add remaining content
    if (buffer.isNotEmpty) {
      segments.add(buffer.toString());
    }

    return segments;
  }

  /// Applies epsilon (ε) identities
  ///
  /// Epsilon identities from regular expression algebra:
  /// - ε* → ε (Kleene star of epsilon is epsilon)
  /// - rε → r (concatenating epsilon has no effect)
  /// - εr → r (concatenating epsilon has no effect)
  ///
  /// Epsilon is the identity element for concatenation, similar to
  /// 1 being the identity for multiplication (1×x = x×1 = x).
  ///
  /// These simplifications are crucial for readable output from
  /// FA-to-regex conversion algorithms, which often generate
  /// epsilon transitions during state elimination.
  static String _applyEpsilonIdentities(String regex) {
    String result = regex;

    // ε* → ε
    result = result.replaceAll('ε*', 'ε');

    // Remove epsilon from concatenation
    result = _removeEpsilonFromConcatenation(result);

    return result;
  }

  /// Removes epsilon from concatenation (εr → r, rε → r)
  ///
  /// Algorithm:
  /// 1. Scan for epsilon characters
  /// 2. Check context - is epsilon in a concatenation or standalone?
  /// 3. If in concatenation, remove it; if standalone, keep it
  /// 4. Repeat until no changes (fixed point)
  ///
  /// Context determination:
  /// - Epsilon is in concatenation if preceded/followed by non-operator characters
  /// - Epsilon is standalone if in union context (r|ε) or alone
  ///
  /// Examples:
  /// - aεb → ab (epsilon in concatenation)
  /// - εa → a (epsilon at start of concatenation)
  /// - aε → a (epsilon at end of concatenation)
  /// - ε|a → ε|a (epsilon in union context, keep it)
  /// - ε → ε (standalone epsilon, keep it)
  /// - (ε)* → ε* → ε (epsilon with operator, handled by other rules)
  ///
  /// Time complexity: O(n²) worst case (multiple passes × string length)
  /// Space complexity: O(n) for buffer
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
            // Skip the epsilon (remove it from concatenation)
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
  ///
  /// Idempotence identities from regular expression algebra:
  /// - r** → r* (multiple Kleene stars reduce to one)
  /// - r|r → r (union with itself is itself)
  ///
  /// Idempotence means "same power" - applying an operation multiple
  /// times has the same effect as applying it once. These identities
  /// help eliminate redundancy in regex expressions.
  ///
  /// Examples:
  /// - a** → a* (double star becomes single star)
  /// - (a|b)*** → (a|b)* (triple star becomes single star)
  /// - a|a|b → a|b (duplicate union alternative removed)
  /// - (ab)|(ab) → ab (duplicate complex alternatives removed)
  static String _applyIdempotenceIdentities(String regex) {
    String result = regex;

    // r** → r*, r*** → r*, etc.
    result = _reduceMultipleStars(result);

    // r|r → r (union idempotence)
    result = _applyUnionIdempotence(result);

    return result;
  }

  /// Reduces multiple consecutive Kleene stars to a single star
  ///
  /// According to regex algebra: (r*)* = r*
  /// More generally: r** = r***, etc. - all reduce to r*
  ///
  /// Algorithm:
  /// - Scan for star operators
  /// - When found, skip all consecutive stars
  /// - Write only one star to output
  ///
  /// This handles cases like:
  /// - a** → a*
  /// - (a|b)*** → (a|b)*
  /// - (a*)** → a* (after first pass gives a**, which becomes a*)
  ///
  /// Time complexity: O(n)
  /// Space complexity: O(n) for buffer
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
  ///
  /// According to regex algebra: r|r = r
  /// A union of identical expressions can be reduced to a single instance.
  ///
  /// Algorithm:
  /// 1. Split regex into top-level union segments
  /// 2. Track which segments we've seen using a set
  /// 3. Keep only first occurrence of each unique segment
  /// 4. Rejoin with | operator
  ///
  /// This preserves order and removes duplicates, similar to
  /// Python's dict.fromkeys() or SQL's SELECT DISTINCT.
  ///
  /// Examples:
  /// - a|a → a (simple duplicate)
  /// - a|b|a → a|b (removes second occurrence of 'a')
  /// - (ab)|(cd)|(ab) → (ab)|(cd) (complex expressions)
  /// - a|b|c → a|b|c (no duplicates, unchanged)
  ///
  /// Time complexity: O(n×m) where m is average segment length (for hashing)
  /// Space complexity: O(k) where k is number of unique segments
  static String _applyUnionIdempotence(String regex) {
    // Split by | at top level and check for duplicates
    final segments = _splitIntoConcatenationSegments(regex);

    if (segments.length <= 1) return regex;

    // Remove duplicates while preserving order
    // Using LinkedHashSet would be ideal, but we use manual tracking for clarity
    final seen = <String>{};
    final unique = <String>[];

    for (final segment in segments) {
      if (!seen.contains(segment)) {
        seen.add(segment);
        unique.add(segment);
      }
    }

    // Only rebuild if we actually removed duplicates
    if (unique.length < segments.length) {
      return unique.join('|');
    }

    return regex;
  }
}
