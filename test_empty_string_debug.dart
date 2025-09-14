import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/cfg.dart';
import 'package:jflutter/core/lr_parsing.dart';

void main() {
  test('Debug empty string parsing step by step', () {
    final grammar = ContextFreeGrammar.fromString('''
      S → aSb | λ
    ''');
    
    final table = LRParsing.generateParseTable(grammar);
    
    print('Parsing empty string step by step:');
    
    final stack = <int>[0];
    final inputTokens = ['\$'];
    int inputIndex = 0;
    
    print('Initial: Stack = [${stack.join(', ')}], Input = ${inputTokens.join('')}');
    
    while (true) {
      final currentState = stack.last;
      final currentInput = inputTokens[inputIndex];
      
      print('State: $currentState, Input: $currentInput');
      
      final action = table.getAction(currentState, currentInput);
      print('Action: $action');
      
      if (action == null) {
        print('ERROR: No action defined');
        break;
      }
      
      switch (action.action) {
        case 's':
          final targetState = action.stateNumber!;
          stack.add(targetState);
          inputIndex++;
          print('Shift to state $targetState');
          print('Stack = [${stack.join(', ')}]');
          break;
          
        case 'r':
          final productionNumber = action.productionNumber!;
          final production = table.productions[productionNumber];
          
          print('Reduce with production $productionNumber: $production');
          
          final rhsLength = production.rightHandSide == 'λ' ? 0 : production.rightHandSide.length;
          print('RHS length: $rhsLength');
          
          for (int i = 0; i < rhsLength; i++) {
            stack.removeLast();
          }
          
          print('After pop: Stack = [${stack.join(', ')}]');
          
          if (stack.isEmpty) {
            print('ERROR: Stack is empty');
            break;
          }
          
          final gotoState = table.getGoto(stack.last, production.leftHandSide);
          print('Goto from state ${stack.last} with ${production.leftHandSide}: $gotoState');
          
          if (gotoState == null) {
            print('ERROR: No goto defined');
            break;
          }
          
          stack.add(gotoState);
          print('After goto: Stack = [${stack.join(', ')}]');
          break;
          
        case 'acc':
          print('ACCEPTED!');
          return;
          
        default:
          print('ERROR: Unknown action');
          break;
      }
    }
  });
}
