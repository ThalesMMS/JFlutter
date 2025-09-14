import 'cfg.dart';
import 'algo_log.dart';

/// Represents an LL(1) parse table entry
class LLParseTableEntry {
  final String variable;
  final String lookahead;
  final String expansion;

  LLParseTableEntry({
    required this.variable,
    required this.lookahead,
    required this.expansion,
  });

  @override
  String toString() => 'M[$variable, $lookahead] = $expansion';

  @override
  bool operator ==(Object other) =>
      other is LLParseTableEntry &&
      variable == other.variable &&
      lookahead == other.lookahead &&
      expansion == other.expansion;

  @override
  int get hashCode => Object.hash(variable, lookahead, expansion);
}

/// Represents an LL(1) parse table
class LLParseTable {
  final Map<String, Map<String, Set<String>>> _table;
  final List<String> variables;
  final List<String> terminals;

  LLParseTable({
    required this.variables,
    required this.terminals,
  }) : _table = {};

  /// Add an entry to the parse table
  void addEntry(String variable, String lookahead, String expansion) {
    _table[variable] ??= {};
    _table[variable]![lookahead] ??= <String>{};
    _table[variable]![lookahead]!.add(expansion);
  }

  /// Get entries for a variable and lookahead
  Set<String> getEntries(String variable, String lookahead) {
    return _table[variable]?[lookahead] ?? <String>{};
  }

  /// Check if the table has conflicts (multiple entries for same variable/lookahead)
  bool hasConflicts() {
    for (final variable in variables) {
      for (final terminal in terminals) {
        final entries = getEntries(variable, terminal);
        if (entries.length > 1) {
          return true;
        }
      }
      // Check for $ (end of input)
      final entries = getEntries(variable, '\$');
      if (entries.length > 1) {
        return true;
      }
    }
    return false;
  }

  /// Get all conflicts in the table
  List<Map<String, dynamic>> getConflicts() {
    final conflicts = <Map<String, dynamic>>[];
    
    for (final variable in variables) {
      for (final terminal in terminals) {
        final entries = getEntries(variable, terminal);
        if (entries.length > 1) {
          conflicts.add({
            'variable': variable,
            'lookahead': terminal,
            'entries': entries.toList(),
          });
        }
      }
      // Check for $ (end of input)
      final entries = getEntries(variable, '\$');
      if (entries.length > 1) {
        conflicts.add({
          'variable': variable,
          'lookahead': '\$',
          'entries': entries.toList(),
        });
      }
    }
    
    return conflicts;
  }

  /// Convert table to string representation
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('LL(1) Parse Table:');
    buffer.writeln('Variables: ${variables.join(', ')}');
    buffer.writeln('Terminals: ${terminals.join(', ')}, \$');
    buffer.writeln();
    
    for (final variable in variables) {
      buffer.writeln('$variable:');
      for (final terminal in [...terminals, '\$']) {
        final entries = getEntries(variable, terminal);
        if (entries.isNotEmpty) {
          buffer.writeln('  $terminal -> ${entries.join(' | ')}');
        }
      }
    }
    
    return buffer.toString();
  }
}

/// Result of LL parsing
class LLParsingResult {
  final bool accepted;
  final List<String> steps;
  final String explanation;
  final List<CFGProduction> derivation;

  LLParsingResult({
    required this.accepted,
    required this.steps,
    required this.explanation,
    required this.derivation,
  });
}

/// LL(1) parsing algorithms
class LLParsing {
  
  /// Calculate FIRST sets for a grammar
  static Map<String, Set<String>> calculateFirstSets(ContextFreeGrammar grammar) {
    AlgoLog.startAlgo('firstSets', 'Cálculo dos Conjuntos FIRST');
    AlgoLog.add('Calculando conjuntos FIRST para a gramática');
    
    final firstSets = <String, Set<String>>{};
    
    // Initialize FIRST sets for terminals
    for (final terminal in grammar.terminals) {
      firstSets[terminal] = {terminal};
    }
    
    // Initialize FIRST sets for variables as empty
    for (final variable in grammar.variables) {
      firstSets[variable] = <String>{};
    }
    
    // Add lambda to terminals if not present
    if (!grammar.terminals.contains('λ') && !grammar.terminals.contains('ε')) {
      firstSets['λ'] = {'λ'};
      firstSets['ε'] = {'λ'};
    }
    
    // Iterate until no changes
    bool changed = true;
    while (changed) {
      changed = false;
      
      for (final production in grammar.productions) {
        final variable = production.leftHandSide;
        final rhs = production.rightHandSide;
        
        final rhsFirst = _calculateFirstForString(firstSets, rhs);
        final originalSize = firstSets[variable]!.length;
        firstSets[variable]!.addAll(rhsFirst);
        
        if (firstSets[variable]!.length > originalSize) {
          changed = true;
        }
      }
    }
    
    AlgoLog.add('Conjuntos FIRST calculados:');
    for (final entry in firstSets.entries) {
      AlgoLog.add('  FIRST(${entry.key}) = {${entry.value.join(', ')}}');
    }
    
    return firstSets;
  }

  /// Calculate FIRST set for a string of symbols
  static Set<String> _calculateFirstForString(Map<String, Set<String>> firstSets, String string) {
    final result = <String>{};
    
    if (string.isEmpty || string == 'λ' || string == 'ε') {
      result.add('λ');
      return result;
    }
    
    for (int i = 0; i < string.length; i++) {
      final symbol = string[i];
      final symbolFirst = firstSets[symbol] ?? <String>{};
      
      // Add all symbols from FIRST(symbol) except λ
      for (final firstSymbol in symbolFirst) {
        if (firstSymbol != 'λ') {
          result.add(firstSymbol);
        }
      }
      
      // If λ is not in FIRST(symbol), stop
      if (!symbolFirst.contains('λ')) {
        break;
      }
      
      // If this is the last symbol and λ is in FIRST(symbol), add λ
      if (i == string.length - 1) {
        result.add('λ');
      }
    }
    
    return result;
  }

  /// Calculate FOLLOW sets for a grammar
  static Map<String, Set<String>> calculateFollowSets(ContextFreeGrammar grammar) {
    AlgoLog.startAlgo('followSets', 'Cálculo dos Conjuntos FOLLOW');
    AlgoLog.add('Calculando conjuntos FOLLOW para a gramática');
    
    final followSets = <String, Set<String>>{};
    final firstSets = calculateFirstSets(grammar);
    
    // Initialize FOLLOW sets
    for (final variable in grammar.variables) {
      followSets[variable] = <String>{};
    }
    
    // Add $ to FOLLOW of start variable
    if (grammar.startVariable.isNotEmpty) {
      followSets[grammar.startVariable]!.add('\$');
    }
    
    // Iterate until no changes
    bool changed = true;
    while (changed) {
      changed = false;
      
      for (final production in grammar.productions) {
        final lhs = production.leftHandSide;
        final rhs = production.rightHandSide;
        
        for (int i = 0; i < rhs.length; i++) {
          final symbol = rhs[i];
          
          // Only process variables
          if (!grammar.isVariable(symbol)) {
            continue;
          }
          
          // Get FIRST of symbols after current symbol
          final afterSymbol = rhs.substring(i + 1);
          final afterFirst = _calculateFirstForString(firstSets, afterSymbol);
          
          // Add FIRST(afterSymbol) - {λ} to FOLLOW(symbol)
          final originalSize = followSets[symbol]!.length;
          for (final firstSymbol in afterFirst) {
            if (firstSymbol != 'λ') {
              followSets[symbol]!.add(firstSymbol);
            }
          }
          
          // If λ is in FIRST(afterSymbol), add FOLLOW(lhs) to FOLLOW(symbol)
          if (afterFirst.contains('λ')) {
            followSets[symbol]!.addAll(followSets[lhs]!);
          }
          
          if (followSets[symbol]!.length > originalSize) {
            changed = true;
          }
        }
      }
    }
    
    AlgoLog.add('Conjuntos FOLLOW calculados:');
    for (final entry in followSets.entries) {
      AlgoLog.add('  FOLLOW(${entry.key}) = {${entry.value.join(', ')}}');
    }
    
    return followSets;
  }

  /// Generate LL(1) parse table
  static LLParseTable generateParseTable(ContextFreeGrammar grammar) {
    AlgoLog.startAlgo('llParseTable', 'Geração da Tabela de Parsing LL(1)');
    AlgoLog.add('Gerando tabela de parsing LL(1)');
    
    final firstSets = calculateFirstSets(grammar);
    final followSets = calculateFollowSets(grammar);
    
    final variables = grammar.variables.toList()..sort();
    final terminals = grammar.terminals.toList()..sort();
    
    final table = LLParseTable(
      variables: variables,
      terminals: terminals,
    );
    
    // Fill the parse table
    for (final production in grammar.productions) {
      final lhs = production.leftHandSide;
      final rhs = production.rightHandSide;
      
      final rhsFirst = _calculateFirstForString(firstSets, rhs);
      
      // For each terminal in FIRST(rhs), add production to table
      for (final terminal in rhsFirst) {
        if (terminal != 'λ') {
          table.addEntry(lhs, terminal, rhs);
          AlgoLog.add('  M[$lhs, $terminal] = $rhs');
        }
      }
      
      // If λ is in FIRST(rhs), add production for each terminal in FOLLOW(lhs)
      if (rhsFirst.contains('λ')) {
        for (final terminal in followSets[lhs]!) {
          table.addEntry(lhs, terminal, rhs);
          AlgoLog.add('  M[$lhs, $terminal] = $rhs (λ em FIRST)');
        }
      }
    }
    
    // Check for conflicts
    if (table.hasConflicts()) {
      AlgoLog.add('ATENÇÃO: Conflitos encontrados na tabela LL(1)');
      final conflicts = table.getConflicts();
      for (final conflict in conflicts) {
        AlgoLog.add('  Conflito em M[${conflict['variable']}, ${conflict['lookahead']}]: ${conflict['entries']}');
      }
    } else {
      AlgoLog.add('Tabela LL(1) gerada sem conflitos');
    }
    
    return table;
  }

  /// Check if a grammar is LL(1)
  static bool isLL1(ContextFreeGrammar grammar) {
    AlgoLog.startAlgo('isLL1', 'Verificação se Gramática é LL(1)');
    
    final table = generateParseTable(grammar);
    final isLL1 = !table.hasConflicts();
    
    if (isLL1) {
      AlgoLog.add('Gramática é LL(1)');
    } else {
      AlgoLog.add('Gramática NÃO é LL(1) - conflitos encontrados');
    }
    
    return isLL1;
  }

  /// Parse a string using LL(1) parsing
  static LLParsingResult parseString(ContextFreeGrammar grammar, String input) {
    AlgoLog.startAlgo('llParse', 'Parsing LL(1)');
    AlgoLog.add('Parsando string: "$input"');
    
    final table = generateParseTable(grammar);
    
    if (table.hasConflicts()) {
      return LLParsingResult(
        accepted: false,
        steps: ['Gramática não é LL(1) - conflitos na tabela'],
        explanation: 'Não é possível fazer parsing LL(1) devido a conflitos na tabela',
        derivation: [],
      );
    }
    
    final steps = <String>[];
    final derivation = <CFGProduction>[];
    final stack = <String>['\$', grammar.startVariable];
    final inputTokens = input.split('')..add('\$');
    int inputIndex = 0;
    
    steps.add('Inicializando: Stack = [${stack.join(', ')}], Input = ${inputTokens.join('')}');
    
    while (stack.isNotEmpty) {
      final top = stack.last;
      final currentInput = inputTokens[inputIndex];
      
      steps.add('Topo da pilha: $top, Entrada atual: $currentInput');
      
      if (top == currentInput) {
        // Match
        stack.removeLast();
        inputIndex++;
        steps.add('Match: removendo $top da pilha e avançando entrada');
      } else if (grammar.isVariable(top)) {
        // Variable - look up in parse table
        final entries = table.getEntries(top, currentInput);
        
        if (entries.isEmpty) {
          steps.add('ERRO: M[$top, $currentInput] está vazio');
          return LLParsingResult(
            accepted: false,
            steps: steps,
            explanation: 'Erro de parsing: M[$top, $currentInput] está vazio',
            derivation: derivation,
          );
        }
        
        if (entries.length > 1) {
          steps.add('ERRO: Conflito em M[$top, $currentInput]');
          return LLParsingResult(
            accepted: false,
            steps: steps,
            explanation: 'Erro de parsing: conflito em M[$top, $currentInput]',
            derivation: derivation,
          );
        }
        
        final expansion = entries.first;
        stack.removeLast();
        
        if (expansion != 'λ' && expansion != 'ε') {
          // Push symbols in reverse order
          for (int i = expansion.length - 1; i >= 0; i--) {
            stack.add(expansion[i]);
          }
        }
        
        // Add to derivation
        derivation.add(CFGProduction(top, expansion));
        steps.add('Expandindo: $top → $expansion');
        steps.add('Stack = [${stack.join(', ')}]');
      } else {
        // Terminal mismatch
        steps.add('ERRO: Terminal $top não corresponde à entrada $currentInput');
        return LLParsingResult(
          accepted: false,
          steps: steps,
          explanation: 'Erro de parsing: terminal $top não corresponde à entrada $currentInput',
          derivation: derivation,
        );
      }
    }
    
    // Check if we've consumed all input (including the $ marker)
    if (inputIndex >= inputTokens.length - 1) {
      steps.add('Parsing bem-sucedido!');
      return LLParsingResult(
        accepted: true,
        steps: steps,
        explanation: 'String aceita pela gramática LL(1)',
        derivation: derivation,
      );
    } else {
      steps.add('ERRO: Entrada não foi completamente consumida');
      return LLParsingResult(
        accepted: false,
        steps: steps,
        explanation: 'Erro de parsing: entrada não foi completamente consumida',
        derivation: derivation,
      );
    }
  }
}
