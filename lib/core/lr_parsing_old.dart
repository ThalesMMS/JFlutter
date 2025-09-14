import 'cfg.dart';
import 'll_parsing.dart';

/// Represents an LR item (production with dot position)
class LRItem {
  final String lhs;
  final String rhs;
  final int dotPosition;
  final String lookahead;

  LRItem({
    required this.lhs,
    required this.rhs,
    required this.dotPosition,
    required this.lookahead,
  });

  /// Get the symbol after the dot
  String? get symbolAfterDot {
    if (dotPosition >= rhs.length) return null;
    return rhs[dotPosition];
  }

  /// Check if this is a reduce item (dot at the end)
  bool get isReduceItem => dotPosition >= rhs.length;

  /// Get the string before the dot
  String get beforeDot => rhs.substring(0, dotPosition);

  /// Get the string after the dot
  String get afterDot => rhs.substring(dotPosition);

  /// Create a new item with dot moved one position forward
  LRItem advanceDot() {
    return LRItem(
      lhs: lhs,
      rhs: rhs,
      dotPosition: dotPosition + 1,
      lookahead: lookahead,
    );
  }

  @override
  String toString() {
    final before = beforeDot;
    final after = afterDot;
    return '$lhs → $before•$after, $lookahead';
  }

  @override
  bool operator ==(Object other) =>
      other is LRItem &&
      lhs == other.lhs &&
      rhs == other.rhs &&
      dotPosition == other.dotPosition &&
      lookahead == other.lookahead;

  @override
  int get hashCode => Object.hash(lhs, rhs, dotPosition, lookahead);
}

/// Represents an LR state (set of LR items)
class LRState {
  final int id;
  final Set<LRItem> items;

  LRState({
    required this.id,
    required this.items,
  });

  @override
  String toString() => 'State $id: ${items.length} items';

  @override
  bool operator ==(Object other) =>
      other is LRState && id == other.id && items == other.items;

  @override
  int get hashCode => Object.hash(id, items);
}

/// Represents an LR parse table entry
class LRParseTableEntry {
  final String action; // 's' (shift), 'r' (reduce), 'acc' (accept), or state number (goto)
  final int? stateNumber;
  final int? productionNumber;

  LRParseTableEntry({
    required this.action,
    this.stateNumber,
    this.productionNumber,
  });

  @override
  String toString() {
    switch (action) {
      case 's':
        return 's$stateNumber';
      case 'r':
        return 'r$productionNumber';
      case 'acc':
        return 'acc';
      default:
        return stateNumber.toString();
    }
  }
}

/// Represents an LR parse table
class LRParseTable {
  final Map<int, Map<String, LRParseTableEntry>> _actionTable;
  final Map<int, Map<String, int>> _gotoTable;
  final List<CFGProduction> productions;
  final List<String> terminals;
  final List<String> variables;

  LRParseTable({
    required this.productions,
    required this.terminals,
    required this.variables,
  }) : _actionTable = {}, _gotoTable = {};

  /// Add an action entry
  void addAction(int state, String symbol, LRParseTableEntry entry) {
    _actionTable[state] ??= {};
    _actionTable[state]![symbol] = entry;
  }

  /// Add a goto entry
  void addGoto(int state, String symbol, int targetState) {
    _gotoTable[state] ??= {};
    _gotoTable[state]![symbol] = targetState;
  }

  /// Get action for state and symbol
  LRParseTableEntry? getAction(int state, String symbol) {
    return _actionTable[state]?[symbol];
  }

  /// Get goto for state and symbol
  int? getGoto(int state, String symbol) {
    return _gotoTable[state]?[symbol];
  }

  /// Get all states
  Set<int> get states => {
    ..._actionTable.keys,
    ..._gotoTable.keys,
  };

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('LR Parse Table:');
    buffer.writeln('Productions:');
    for (int i = 0; i < productions.length; i++) {
      buffer.writeln('  $i: ${productions[i]}');
    }
    buffer.writeln();
    
    buffer.writeln('Action Table:');
    for (final state in states.toList()..sort()) {
      buffer.write('State $state: ');
      final actions = _actionTable[state] ?? {};
      for (final symbol in [...terminals, '\$']) {
        final action = actions[symbol];
        if (action != null) {
          buffer.write('$symbol:${action.toString()} ');
        }
      }
      buffer.writeln();
    }
    
    buffer.writeln('Goto Table:');
    for (final state in states.toList()..sort()) {
      buffer.write('State $state: ');
      final gotos = _gotoTable[state] ?? {};
      for (final variable in variables) {
        final goto = gotos[variable];
        if (goto != null) {
          buffer.write('$variable:$goto ');
        }
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

/// Result of LR parsing
class LRParsingResult {
  final bool accepted;
  final List<String> steps;
  final String explanation;
  final List<CFGProduction> derivation;

  LRParsingResult({
    required this.accepted,
    required this.steps,
    required this.explanation,
    required this.derivation,
  });
}

/// LR(1) parsing algorithms
class LRParsing {
  
  /// Create augmented grammar for LR parsing
  static ContextFreeGrammar createAugmentedGrammar(ContextFreeGrammar grammar) {
    final augmentedStart = '${grammar.startVariable}Prime';
    final augmentedProductions = <CFGProduction>[
      CFGProduction(augmentedStart, grammar.startVariable),
      ...grammar.productions,
    ];
    
    final augmentedVariables = <String>{
      augmentedStart,
      ...grammar.variables,
    };
    
    return ContextFreeGrammar(
      variables: augmentedVariables,
      terminals: grammar.terminals,
      startVariable: augmentedStart,
      productions: augmentedProductions,
    );
  }

  /// Calculate closure of a set of LR items
  static Set<LRItem> closure(Set<LRItem> items, ContextFreeGrammar grammar) {
    final result = <LRItem>{...items};
    final firstSets = LLParsing.calculateFirstSets(grammar);
    
    bool changed = true;
    while (changed) {
      changed = false;
      final newItems = <LRItem>{};
      
      for (final item in result) {
        final symbolAfterDot = item.symbolAfterDot;
        
        if (symbolAfterDot != null && grammar.isVariable(symbolAfterDot)) {
          // Get FIRST(βa) where β is after the dot and a is the lookahead
          final afterDot = item.afterDot.substring(1); // Remove the symbol after dot
          final betaA = afterDot + item.lookahead;
          final firstBetaA = _calculateFirstForString(firstSets, betaA);
          
          // Add items for all productions of the variable after dot
          for (final production in grammar.getProductionsFor(symbolAfterDot)) {
            for (final firstSymbol in firstBetaA) {
              final newItem = LRItem(
                lhs: production.leftHandSide,
                rhs: production.rightHandSide,
                dotPosition: 0,
                lookahead: firstSymbol,
              );
              
              if (!result.contains(newItem) && !newItems.contains(newItem)) {
                newItems.add(newItem);
                changed = true;
              }
            }
          }
        }
      }
      
      result.addAll(newItems);
    }
    
    return result;
  }

  /// Calculate FIRST set for a string (helper function)
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

  /// Calculate goto for a set of items and a symbol
  static Set<LRItem> goto(Set<LRItem> items, String symbol, ContextFreeGrammar grammar) {
    final kernel = <LRItem>{};
    
    for (final item in items) {
      if (item.symbolAfterDot == symbol) {
        kernel.add(item.advanceDot());
      }
    }
    
    return closure(kernel, grammar);
  }

  /// Build LR(1) automaton
  static Map<int, LRState> buildLRAutomaton(ContextFreeGrammar grammar) {
    
    final augmentedGrammar = createAugmentedGrammar(grammar);
    
    // Initial item: S' → •S, $
    final initialItem = LRItem(
      lhs: augmentedGrammar.startVariable,
      rhs: grammar.startVariable,
      dotPosition: 0,
      lookahead: '\$',
    );
    
    final initialClosure = closure({initialItem}, augmentedGrammar);
    final states = <int, LRState>{};
    final stateToItems = <int, Set<LRItem>>{};
    final itemsToState = <Set<LRItem>, int>{};
    
    int nextStateId = 0;
    final queue = <Set<LRItem>>[initialClosure];
    
    while (queue.isNotEmpty) {
      final currentItems = queue.removeAt(0);
      
      if (itemsToState.containsKey(currentItems)) {
        continue;
      }
      
      final stateId = nextStateId++;
      final state = LRState(id: stateId, items: currentItems);
      states[stateId] = state;
      stateToItems[stateId] = currentItems;
      itemsToState[currentItems] = stateId;
      
      
      // Find all symbols that can be used for goto
      final symbols = <String>{};
      for (final item in currentItems) {
        final symbolAfterDot = item.symbolAfterDot;
        if (symbolAfterDot != null) {
          symbols.add(symbolAfterDot);
        }
      }
      
      // Calculate goto for each symbol
      for (final symbol in symbols) {
        final gotoItems = goto(currentItems, symbol, augmentedGrammar);
        
        if (gotoItems.isNotEmpty) {
          if (!itemsToState.containsKey(gotoItems)) {
            queue.add(gotoItems);
          }
        }
      }
    }
    
    return states;
  }

  /// Generate LR(1) parse table
  static LRParseTable generateParseTable(ContextFreeGrammar grammar) {
    
    final augmentedGrammar = createAugmentedGrammar(grammar);
    final states = buildLRAutomaton(augmentedGrammar);
    
    final terminals = grammar.terminals.toList()..sort();
    final variables = grammar.variables.toList()..sort();
    
    final table = LRParseTable(
      productions: augmentedGrammar.productions,
      terminals: terminals,
      variables: variables,
    );
    
    // Fill action and goto tables
    for (final stateEntry in states.entries) {
      final stateId = stateEntry.key;
      final state = stateEntry.value;
      
      for (final item in state.items) {
        
        if (item.isReduceItem) {
          // Reduce item
          if (item.lhs == augmentedGrammar.startVariable) {
            // Accept
            table.addAction(stateId, '\$', LRParseTableEntry(action: 'acc'));
          } else {
            // Find production number
            int productionNumber = -1;
            for (int i = 0; i < augmentedGrammar.productions.length; i++) {
              final prod = augmentedGrammar.productions[i];
              if (prod.leftHandSide == item.lhs && prod.rightHandSide == item.beforeDot) {
                productionNumber = i;
                break;
              }
            }
            
            if (productionNumber >= 0) {
              table.addAction(stateId, item.lookahead, 
                LRParseTableEntry(action: 'r', productionNumber: productionNumber));
            }
          }
        } else {
          // Shift item
          final symbolAfterDot = item.symbolAfterDot;
          if (symbolAfterDot != null) {
            // Find target state
            final currentItems = state.items;
            final gotoItems = goto(currentItems, symbolAfterDot, augmentedGrammar);
            
            // Find state ID for goto items
            for (final stateEntry2 in states.entries) {
              if (stateEntry2.value.items == gotoItems) {
                final targetStateId = stateEntry2.key;
                
                if (grammar.isTerminal(symbolAfterDot)) {
                  table.addAction(stateId, symbolAfterDot, 
                    LRParseTableEntry(action: 's', stateNumber: targetStateId));
                } else {
                  table.addGoto(stateId, symbolAfterDot, targetStateId);
                }
                break;
              }
            }
          }
        }
      }
    }
    
    return table;
  }

  /// Parse a string using LR(1) parsing
  static LRParsingResult parseString(ContextFreeGrammar grammar, String input) {
    
    final table = generateParseTable(grammar);
    final steps = <String>[];
    final derivation = <CFGProduction>[];
    
    final stack = <int>[0]; // Stack of states
    final inputTokens = input.split('')..add('\$');
    int inputIndex = 0;
    
    steps.add('Inicializando: Stack = [${stack.join(', ')}], Input = ${inputTokens.join('')}');
    
    while (true) {
      final currentState = stack.last;
      final currentInput = inputTokens[inputIndex];
      
      steps.add('Estado atual: $currentState, Entrada: $currentInput');
      
      final action = table.getAction(currentState, currentInput);
      
      if (action == null) {
        steps.add('ERRO: Ação não definida para estado $currentState e entrada $currentInput');
        return LRParsingResult(
          accepted: false,
          steps: steps,
          explanation: 'Erro de parsing: ação não definida',
          derivation: derivation,
        );
      }
      
      switch (action.action) {
        case 's':
          // Shift
          final targetState = action.stateNumber!;
          stack.add(targetState);
          inputIndex++;
          steps.add('Shift: movendo para estado $targetState');
          steps.add('Stack = [${stack.join(', ')}]');
          break;
          
        case 'r':
          // Reduce
          final productionNumber = action.productionNumber!;
          final production = table.productions[productionNumber];
          
          // Pop |β| elements from stack (only states)
          final rhsLength = production.rightHandSide.length;
          for (int i = 0; i < rhsLength; i++) {
            stack.removeLast();
          }
          
          // Get goto state
          final gotoState = table.getGoto(stack.last, production.leftHandSide);
          if (gotoState == null) {
            steps.add('ERRO: Goto não definido para estado ${stack.last} e símbolo ${production.leftHandSide}');
            return LRParsingResult(
              accepted: false,
              steps: steps,
              explanation: 'Erro de parsing: goto não definido',
              derivation: derivation,
            );
          }
          
          stack.add(gotoState);
          derivation.add(production);
          steps.add('Reduce: aplicando produção $productionNumber: ${production.toString()}');
          steps.add('Stack = [${stack.join(', ')}]');
          break;
          
        case 'acc':
          // Accept
          steps.add('Aceito!');
          return LRParsingResult(
            accepted: true,
            steps: steps,
            explanation: 'String aceita pela gramática LR(1)',
            derivation: derivation,
          );
          
        default:
          steps.add('ERRO: Ação desconhecida: ${action.action}');
          return LRParsingResult(
            accepted: false,
            steps: steps,
            explanation: 'Erro de parsing: ação desconhecida',
            derivation: derivation,
          );
      }
    }
  }
}
