import 'dart:math';
import 'automaton.dart';
import '../presentation/widgets/layout_tools.dart';

/// Checks if a character is a literal (letter, digit, or underscore)
bool _isLiteral(String c) => RegExp(r'^[A-Za-z0-9_]$').hasMatch(c);

/// Checks if two tokens need an implicit concatenation
bool _needsConcat(String a, String b) {
  return (a == ')' || a == '*' || a == '+' || a == '?' || a == 'λ' ||
          _isLiteral(a) || (a == ']' && b != '|' && b != ')' && b != '*' && b != '+' && b != '?')) &&
      (b == '(' || b == '[' || b == 'λ' || _isLiteral(b));
}

/// Converts a regex string to postfix notation using the Shunting Yard algorithm
List<String> regexToPostfix(String re) {
  // Normalize the input
  re = re
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('∪', '|')
      .replaceAll('ε', 'λ')
      .replaceAll('?', '|λ'); // Convert '?' to '|λ'

  final tokens = <String>[];
  final out = <String>[];
  final ops = <String>[];
  
  // Operator precedence (higher number = higher precedence)
  const prec = {
    '|': 1,  // alternation (lowest)
    '.': 2,  // concatenation (explicit or implicit)
    '?': 3,  // zero or one
    '*': 3,  // zero or more
    '+': 3,  // one or more
  };
  
  // Right-associative operators (currently only '^' for position, but we might add more)
  const rightAssoc = {'^': true};
  
  // Process character classes and other special sequences
  int i = 0;
  while (i < re.length) {
    final c = re[i];
    
    // Handle character classes [a-z0-9_]
    if (c == '[') {
      final end = re.indexOf(']', i);
      if (end == -1) throw FormatException('Unclosed character class');
      
      // Extract the character class
      final charClass = re.substring(i, end + 1);
      tokens.add(charClass);
      i = end + 1;
      continue;
    }
    
    // Handle escaped characters
    if (c == '\\') {
      if (i + 1 >= re.length) throw FormatException('Trailing backslash');
      tokens.add(re[i + 1]);
      i += 2;
      continue;
    }
    
    tokens.add(c);
    i++;
  }
  
  // Add explicit concatenation operators
  final t2 = <String>[];
  for (i = 0; i < tokens.length; i++) {
    final t1 = tokens[i];
    t2.add(t1);
    
    if (i + 1 < tokens.length) {
      final tnext = tokens[i + 1];
      if (_needsConcat(t1, tnext)) {
        t2.add('.');
      }
    }
  }
  
  // Convert to postfix notation
  for (final t in t2) {
    if (_isLiteral(t) || t == 'λ' || t.startsWith('[')) {
      out.add(t);
    } else if (t == '(') {
      ops.add(t);
    } else if (t == ')') {
      while (ops.isNotEmpty && ops.last != '(') {
        out.add(ops.removeLast());
      }
      if (ops.isEmpty) throw FormatException('Mismatched parentheses');
      ops.removeLast(); // Remove the '('
    } else if (prec.containsKey(t)) {
      while (ops.isNotEmpty &&
             ops.last != '(' &&
             ((prec[ops.last]! > prec[t]!) || 
              (prec[ops.last] == prec[t] && rightAssoc[t] != true))) {
        out.add(ops.removeLast());
      }
      ops.add(t);
    } else {
      throw FormatException('Invalid token: $t');
    }
  }
  
  // Pop remaining operators
  while (ops.isNotEmpty) {
    final op = ops.removeLast();
    if (op == '(' || op == ')') throw FormatException('Mismatched parentheses');
    out.add(op);
  }
  return out;
}

/// Represents a fragment of an NFA during construction
class _NFANode {
  StateNode start;
  StateNode end;
  final Map<String, List<String>> transitions;
  final List<StateNode> states;

  _NFANode(this.start, this.end, this.transitions, this.states);
}

/// Builds an NFA from a postfix regular expression
Automaton nfaFromPostfix(List<String> post) {
  int idCounter = 0;
  String nid() => 'q${idCounter++}';
  
  /// Creates a basic NFA fragment for a single character or character class
  _NFANode _createBasicNFA(String c) {
    final startId = nid();
    final endId = nid();
    final transitions = <String, List<String>>{};
    final states = <StateNode>[];
    
    // Create start and end states
    final start = StateNode(
      id: startId,
      name: 'start',
      x: 0,
      y: 0,
      isInitial: true,
      isFinal: false,
    );
    
    final end = StateNode(
      id: endId,
      name: 'end',
      x: 100,
      y: 0,
      isInitial: false,
      isFinal: true,
    );
    
    states.addAll([start, end]);
    
    // Handle character classes
    if (c.startsWith('[') && c.endsWith(']')) {
      final chars = c.substring(1, c.length - 1);
      int i = 0;
      while (i < chars.length) {
        if (i + 2 < chars.length && chars[i + 1] == '-') {
          // Handle character range like a-z
          final startChar = chars.codeUnitAt(i);
          final endChar = chars.codeUnitAt(i + 2);
          for (var code = startChar; code <= endChar; code++) {
            final symbol = String.fromCharCode(code);
            transitions['$startId|$symbol'] = [endId];
          }
          i += 3;
        } else {
          // Single character in class
          final symbol = chars[i];
          transitions['$startId|$symbol'] = [endId];
          i++;
        }
      }
    } else {
      // Single character
      transitions['$startId|$c'] = [endId];
    }
    
    return _NFANode(start, end, transitions, states);
  }
  
  final stack = <_NFANode>[];
  
  // Process each token in postfix notation
  for (final token in post) {
    if (token == '|') {
      // Alternation: a|b
      if (stack.length < 2) throw FormatException('Invalid regular expression: not enough operands for |');
      final b = stack.removeLast();
      final a = stack.removeLast();
      
      // Create new start and end states
      final start = StateNode(
        id: nid(),
        name: 'start',
        x: 0,
        y: 0,
        isInitial: true,
        isFinal: false,
      );
      
      final end = StateNode(
        id: nid(),
        name: 'end',
        x: 100,
        y: 0,
        isInitial: false,
        isFinal: true,
      );
      
      // Merge transitions
      final transitions = <String, List<String>>{
        ...a.transitions,
        ...b.transitions,
        '${start.id}|λ': [a.start.id, b.start.id],
        '${a.end.id}|λ': [end.id],
        '${b.end.id}|λ': [end.id],
      };
      
      // Update states without mutating originals
      final aStates = a.states
          .map((s) => s.id == a.start.id
              ? s.copyWith(isInitial: false)
              : (s.id == a.end.id ? s.copyWith(isFinal: false) : s))
          .toList();
      final bStates = b.states
          .map((s) => s.id == b.start.id
              ? s.copyWith(isInitial: false)
              : (s.id == b.end.id ? s.copyWith(isFinal: false) : s))
          .toList();
      
      stack.add(_NFANode(
        start,
        end,
        transitions,
        [start, ...aStates, ...bStates, end],
      ));
    } else if (token == '.') {
      // Concatenation: ab
      if (stack.length < 2) throw FormatException('Invalid regular expression: not enough operands for .');
      final b = stack.removeLast();
      final a = stack.removeLast();
      
      // Connect a's end to b's start with lambda transition
      final transitions = <String, List<String>>{
        ...a.transitions,
        ...b.transitions,
        '${a.end.id}|λ': [b.start.id],
      };
      
      // Update states without mutating originals
      final aStates2 = a.states
          .map((s) => s.id == a.end.id ? s.copyWith(isFinal: false) : s)
          .toList();
      final bStates2 = b.states
          .map((s) => s.id == b.start.id ? s.copyWith(isInitial: false) : s)
          .toList();
      
      stack.add(_NFANode(
        a.start,
        b.end,
        transitions,
        [...aStates2, ...bStates2],
      ));
    } else if (token == '*') {
      // Kleene star: a*
      if (stack.isEmpty) throw FormatException('Invalid regular expression: no operand for *');
      final a = stack.removeLast();
      
      final start = StateNode(
        id: nid(),
        name: 'start',
        x: 0,
        y: 0,
        isInitial: true,
        isFinal: true,
      );
      
      final end = StateNode(
        id: nid(),
        name: 'end',
        x: 100,
        y: 0,
        isInitial: false,
        isFinal: true,
      );
      
      final transitions = <String, List<String>>{
        ...a.transitions,
        '${start.id}|λ': [a.start.id, end.id],
        '${a.end.id}|λ': [a.start.id, end.id],
      };
      
      // Update states without mutating originals
      final aStates3 = a.states
          .map((s) => s.id == a.start.id
              ? s.copyWith(isInitial: false)
              : (s.id == a.end.id ? s.copyWith(isFinal: false) : s))
          .toList();
      
      stack.add(_NFANode(
        start,
        end,
        transitions,
        [start, ...aStates3, end],
      ));
    } else if (token == '+') {
      // One or more: a+
      if (stack.isEmpty) throw FormatException('Invalid regular expression: no operand for +');
      final a = stack.removeLast();
      
      final start = StateNode(
        id: nid(),
        name: 'start',
        x: 0,
        y: 0,
        isInitial: true,
        isFinal: false,
      );
      
      final end = StateNode(
        id: nid(),
        name: 'end',
        x: 100,
        y: 0,
        isInitial: false,
        isFinal: true,
      );
      
      final transitions = <String, List<String>>{
        ...a.transitions,
        '${start.id}|λ': [a.start.id],
        '${a.end.id}|λ': [a.start.id, end.id],
      };
      
      // Update states without mutating originals
      final aStates4 = a.states
          .map((s) => s.id == a.start.id
              ? s.copyWith(isInitial: false)
              : (s.id == a.end.id ? s.copyWith(isFinal: false) : s))
          .toList();
      
      stack.add(_NFANode(
        start,
        end,
        transitions,
        [start, ...aStates4, end],
      ));
    } else if (token == '?') {
      // Zero or one: a?
      if (stack.isEmpty) throw FormatException('Invalid regular expression: no operand for ?');
      final a = stack.removeLast();
      
      final start = StateNode(
        id: nid(),
        name: 'start',
        x: 0,
        y: 0,
        isInitial: true,
        isFinal: true,
      );
      
      final end = StateNode(
        id: nid(),
        name: 'end',
        x: 100,
        y: 0,
        isInitial: false,
        isFinal: true,
      );
      
      final transitions = <String, List<String>>{
        ...a.transitions,
        '${start.id}|λ': [a.start.id, end.id],
        '${a.end.id}|λ': [end.id],
      };
      
      // Update states without mutating originals
      final aStates5 = a.states
          .map((s) => s.id == a.start.id
              ? s.copyWith(isInitial: false)
              : (s.id == a.end.id ? s.copyWith(isFinal: false) : s))
          .toList();
      
      stack.add(_NFANode(
        start,
        end,
        transitions,
        [start, ...aStates5, end],
      ));
    } else {
      // Literal or character class
      stack.add(_createBasicNFA(token));
    }
  }
  
  // After processing all tokens, we should have exactly one NFA on the stack
  if (stack.length != 1) {
    throw FormatException('Invalid regular expression: too many operands');
  }
  
  final result = stack.single;
  
  // Extract the alphabet from the transitions
  final alphabet = <String>{};
  for (final key in result.transitions.keys) {
    final parts = key.split('|');
    if (parts.length == 2) {
      final symbol = parts[1];
      if (symbol != 'λ') {
        alphabet.add(symbol);
      }
    }
  }
  
  // Create the final automaton
  final automaton = Automaton(
    alphabet: alphabet,
    states: result.states,
    transitions: result.transitions,
    initialId: result.start.id,
    nextId: idCounter,
  );
  
  return automaton;
}

/// Converts a regular expression to an NFA
Automaton automatonFromRegex(String regex) {
  final postfix = regexToPostfix(regex);
  return nfaFromPostfix(postfix);
}
