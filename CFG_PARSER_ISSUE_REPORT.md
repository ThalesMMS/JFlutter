# CFG Parser Implementation Issue Report

## Project Context
This is a Flutter/Dart project implementing automata theory algorithms. We're working on **Task T020: GLC (Context-Free Grammar) parsing algorithms** in the file `lib/core/algorithms/grammar_parser.dart`.

## Current Status
- **10 tests passing** ✅ (62.5% success rate)
- **6 tests failing** ❌
- **Significant progress made** (started with 0 passing tests)

## Architecture Overview

### Main Parser Implementation
- **File**: `lib/core/algorithms/grammar_parser.dart`
- **Entry point**: `GrammarParser.parse()` method
- **Current implementation**: Uses `SimpleRecursiveDescentParser` from `grammar_parser_simple_recursive.dart`

### Grammar Model Structure
```dart
class Grammar {
  String id;
  String name;
  Set<String> terminals;
  Set<String> nonterminals;
  String startSymbol;
  Set<Production> productions;
  GrammarType type;
}

class Production {
  String id;
  List<String> leftSide;
  List<String> rightSide;
  bool isLambda;  // true for epsilon productions
  int order;
}
```

### Test Structure
- **Test file**: `test/unit/glc_validation_test.dart`
- **16 total tests** covering various grammar types and scenarios

## Working Test Cases (10 passing)

### ✅ Balanced Parentheses Grammar
```dart
S -> SS | (S) | ε
```
- **Test cases**: `['', '()', '(())', '()()', '((()))', '()()()']`
- **Status**: All passing
- **Key feature**: 3-symbol productions like `S -> (S)` work correctly

### ✅ CNF Grammar  
```dart
S -> AB | A | B
A -> a | b
B -> b | a
```
- **Test cases**: `['a', 'b', 'ab', 'ba']`
- **Status**: All passing
- **Key feature**: Multi-symbol productions like `S -> AB` work correctly

### ✅ Other Working Features
- CYK algorithm
- CNF conversion
- Left recursion detection
- Ambiguous grammar handling
- Grammar validation
- Empty string handling
- Invalid symbol rejection

## Failing Test Cases (6 failing)

### ❌ Palindrome Grammar
```dart
S -> aSa | bSb | a | b | ε
```
- **Test cases**: `['', 'a', 'b', 'aa', 'bb', 'aba', 'bab', 'abba', 'baab']`
- **Status**: Failing on single terminals like "a"
- **Issue**: Parser not finding terminal production `S -> a`

### ❌ Invalid String Rejection
- **Balanced Parentheses**: Accepting "(" (should reject)
- **Palindrome**: Accepting "ab" (should reject)
- **Issue**: Parser accepting strings it should reject

### ❌ Performance Issues
- **Long strings**: Timing out on complex inputs
- **Complex nested structures**: Performance degradation
- **Issue**: Parser not handling complex cases efficiently

## Current Parser Implementation

### Core Algorithm (`SimpleRecursiveDescentParser`)
```dart
class SimpleRecursiveDescentParser {
  final Grammar grammar;
  final Map<String, List<List<String>>> _memo = {};
  
  Result<ParseResult> parse(String inputString, {Duration timeout = const Duration(seconds: 5)}) {
    // Main parsing logic
  }
  
  List<String>? _parseNonTerminal(String nonTerminal, String inputString, DateTime startTime, Duration timeout, [int depth = 0]) {
    // Recursive descent parsing with depth limit (max 10)
    // Handles: epsilon productions, terminal productions, non-terminal productions, multi-symbol productions
  }
}
```

### Production Handling Logic
1. **Epsilon productions**: `S -> ε` (empty right side or `isLambda: true`)
2. **Terminal productions**: `S -> a` (single terminal)
3. **Non-terminal productions**: `S -> A` (single non-terminal)
4. **Multi-symbol productions**: `S -> AB` (2 symbols) or `S -> (S)` (3 symbols)

### Key Features Implemented
- **Recursion depth limiting** (max 10 levels)
- **Timeout handling** (5 seconds default)
- **Memoization** for efficiency
- **3-symbol production support** for patterns like `S -> (S)` and `S -> aSa`
- **Epsilon production handling**

## Specific Issue: Palindrome Grammar

### Problem Description
The palindrome grammar test is failing on single terminals like "a". The grammar has:
```dart
S -> aSa | bSb | a | b | ε
```

### Expected Behavior
For input "a":
1. Try `S -> aSa`: Check if "a" starts with 'a' and ends with 'a' ✅
2. Extract inner string: `"a".substring(1, 0)` = `""` (empty)
3. Parse `S` against `""` (empty string)
4. `S` should derive empty string via `S -> ε` ✅
5. Return success with derivation `[S, a, S, a]`

### Actual Behavior
The parser is not finding the terminal production `S -> a` even though it exists in the grammar. The parser seems to get stuck on the first production `S -> aSa` and doesn't continue to try other productions.

### Debug Evidence
- Grammar has 5 productions including `S -> a` ✅
- Parser only tries first production `S -> aSa` ❌
- Parser doesn't continue to try `S -> a` ❌

## Code Structure Analysis

### Production Iteration Logic
```dart
for (final production in grammar.productions) {
  if (production.leftSide.isNotEmpty && production.leftSide.first == nonTerminal) {
    // Handle epsilon productions
    if (production.rightSide.isEmpty || production.isLambda) { ... }
    
    // Handle terminal productions  
    if (production.rightSide.length == 1 && grammar.terminals.contains(production.rightSide.first)) { ... }
    
    // Handle non-terminal productions
    if (production.rightSide.length == 1 && grammar.nonTerminals.contains(production.rightSide.first)) { ... }
    
    // Handle multi-symbol productions
    if (production.rightSide.length > 1) { ... }
  }
}
```

### 3-Symbol Production Handling
```dart
} else if (production.rightSide.length == 3) {
  final firstSymbol = production.rightSide[0];
  final middleSymbol = production.rightSide[1]; 
  final lastSymbol = production.rightSide[2];
  
  if (inputString.startsWith(firstSymbol) && inputString.endsWith(lastSymbol)) {
    final innerString = inputString.substring(1, inputString.length - 1);
    final innerResult = _parseNonTerminal(middleSymbol, innerString, startTime, timeout, depth + 1);
    if (innerResult != null) {
      return [nonTerminal, firstSymbol, ...innerResult, lastSymbol];
    }
  }
}
```

## Test File Structure

### Palindrome Grammar Definition
```dart
Grammar _createPalindromeGrammar() {
  final productions = {
    Production(id: 'p1', leftSide: ['S'], rightSide: ['a', 'S', 'a'], isLambda: false, order: 1),
    Production(id: 'p2', leftSide: ['S'], rightSide: ['b', 'S', 'b'], isLambda: false, order: 2),
    Production(id: 'p3', leftSide: ['S'], rightSide: ['a'], isLambda: false, order: 3),
    Production(id: 'p4', leftSide: ['S'], rightSide: ['b'], isLambda: false, order: 4),
    Production(id: 'p5', leftSide: ['S'], rightSide: [], isLambda: true, order: 5),
  };
  
  return Grammar(
    id: 'palindrome',
    name: 'Palindrome',
    terminals: {'a', 'b'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
  );
}
```

### Test Cases
```dart
test('Palindrome Grammar - should accept palindromes', () async {
  final testCases = [
    '',        // Empty string
    'a',       // Single character - FAILING
    'b',       // Single character - FAILING  
    'aa',      // Even length palindrome - FAILING
    'bb',      // Even length palindrome - FAILING
    'aba',     // Odd length palindrome - FAILING
    'bab',     // Odd length palindrome - FAILING
    'abba',    // Even length palindrome - FAILING
    'baab',    // Even length palindrome - FAILING
  ];
  
  for (final testString in testCases) {
    final result = GrammarParser.parse(palindromeGrammar, testString);
    expect(result.isSuccess, true, reason: 'Parsing should succeed for "$testString"');
  }
});
```

## Dependencies and Environment

### Flutter/Dart Version
- **Dart SDK**: 3.9.2 (stable)
- **Flutter**: Latest stable
- **Platform**: macOS ARM64

### Key Dependencies
- `petitparser: ^7.0.1` (available but not currently used)
- Standard Flutter/Dart libraries

## Previous Attempts

### 1. Brute Force Algorithm
- **Issue**: Infinite loops with left-recursive grammars
- **Status**: Replaced

### 2. CYK Algorithm  
- **Issue**: Complex CNF conversion and epsilon handling
- **Status**: Partially working

### 3. PetitParser Integration
- **Issue**: "undefined parser" errors with recursive grammar definitions
- **Status**: Abandoned

### 4. Simple Recursive Descent (Current)
- **Status**: 62.5% success rate
- **Issues**: Single terminal parsing, invalid string rejection, performance

## Specific Questions for the AI

1. **Why is the parser not finding the terminal production `S -> a` in the palindrome grammar?**
   - The grammar clearly has this production
   - The parser should iterate through all productions
   - But it seems to get stuck on the first production

2. **How should 3-symbol productions like `S -> aSa` handle empty inner strings?**
   - For input "a", the inner string is empty `""`
   - The parser should be able to derive empty string via `S -> ε`
   - But this derivation is not being found

3. **How can we improve invalid string rejection?**
   - Parser is accepting strings it should reject
   - Need better validation logic

4. **How can we optimize performance for complex cases?**
   - Long strings and complex nested structures are timing out
   - Need better algorithm or memoization

## Files to Examine

### Core Implementation
- `lib/core/algorithms/grammar_parser.dart` - Main parser entry point
- `lib/core/algorithms/grammar_parser_simple_recursive.dart` - Current implementation

### Test Files  
- `test/unit/glc_validation_test.dart` - All GLC validation tests

### Models
- `lib/core/models/grammar.dart` - Grammar model
- `lib/core/models/production.dart` - Production model

## Expected Solution

The AI should provide:
1. **Root cause analysis** of why single terminal parsing fails
2. **Fixed implementation** that handles all test cases correctly
3. **Performance optimizations** for complex cases
4. **Proper invalid string rejection** logic
5. **Clear explanation** of the changes made

## Success Criteria

- **All 16 tests passing** (100% success rate)
- **No infinite loops** or performance issues
- **Proper error handling** for invalid inputs
- **Clean, maintainable code** structure

---

**Note**: This is a critical component of an automata theory educational application. The parser needs to be robust and handle all standard CFG parsing scenarios correctly.
