import 'automaton.dart';
import 'algo_log.dart';

/// Base class for pumping lemma implementations
abstract class PumpingLemma {
  String get title;
  String get description;
  
  /// Check if a word can be pumped according to the lemma
  PumpingResult checkPumping(String word, int pumpingLength);
  
  /// Generate a word that demonstrates the pumping lemma
  String generateWord(int pumpingLength);
  
  /// Repeat a string n times
  String pumpString(String s, int n) {
    if (n == 0) return '';
    if (n == 1) return s;
    return s * n;
  }
}

/// Result of pumping lemma check
class PumpingResult {
  final bool canPump;
  final String explanation;
  final List<String> decompositions;
  final List<String> pumpedStrings;

  PumpingResult({
    required this.canPump,
    required this.explanation,
    this.decompositions = const [],
    this.pumpedStrings = const [],
  });
}

/// Regular language pumping lemma implementation
class RegularPumpingLemma extends PumpingLemma {
  final Automaton automaton;
  final String languageDescription;
  
  RegularPumpingLemma(this.automaton, this.languageDescription);
  
  @override
  String get title => 'Lema do Bombeamento para Linguagens Regulares';
  
  @override
  String get description => 
    'Para toda linguagem regular L, existe um número p (comprimento de bombeamento) '
    'tal que para toda palavra w ∈ L com |w| ≥ p, w pode ser escrita como w = xyz '
    'onde |xy| ≤ p, |y| ≥ 1, e xyⁱz ∈ L para todo i ≥ 0.';
  
  @override
  String generateWord(int pumpingLength) {
    // Generate a word that's longer than the pumping length
    return 'a' * (pumpingLength + 1);
  }
  
  @override
  PumpingResult checkPumping(String word, int pumpingLength) {
    AlgoLog.startAlgo('regularPumping', 'Lema do Bombeamento - Linguagens Regulares');
    AlgoLog.add('Verificando palavra: "$word" com comprimento de bombeamento p = $pumpingLength');
    
    if (word.length < pumpingLength) {
      AlgoLog.add('|w| = ${word.length} < p = $pumpingLength, então o lema não se aplica');
      return PumpingResult(
        canPump: true,
        explanation: 'Palavra muito curta para aplicar o lema do bombeamento',
      );
    }
    
    // Try all possible decompositions w = xyz where |xy| ≤ p and |y| ≥ 1
    for (int i = 0; i <= word.length; i++) {
      for (int j = i + 1; j <= word.length && j - i <= pumpingLength; j++) {
        final x = word.substring(0, i);
        final y = word.substring(i, j);
        final z = word.substring(j);
        
        if (y.isEmpty) continue; // |y| ≥ 1
        
        AlgoLog.add('Testando decomposição: x = "$x", y = "$y", z = "$z"');
        
        // Check if xyⁱz ∈ L for i = 0, 1, 2
        final results = <bool>[];
        final pumpedWords = <String>[];
        
        for (int k = 0; k <= 2; k++) {
          final pumpedWord = x + pumpString(y, k) + z;
          pumpedWords.add(pumpedWord);
          final accepted = _runWord(automaton, pumpedWord);
          results.add(accepted);
          AlgoLog.add('  xy^$k z = "$pumpedWord" → ${accepted ? "aceita" : "rejeitada"}');
        }
        
        // If all pumped words are accepted, this decomposition works
        if (results.every((r) => r)) {
          AlgoLog.add('Decomposição válida encontrada!');
          return PumpingResult(
            canPump: true,
            explanation: 'Palavra pode ser bombeada com a decomposição x = "$x", y = "$y", z = "$z"',
            decompositions: ['x = "$x", y = "$y", z = "$z"'],
            pumpedStrings: pumpedWords,
          );
        }
      }
    }
    
    AlgoLog.add('Nenhuma decomposição válida encontrada');
    return PumpingResult(
      canPump: false,
      explanation: 'Palavra não pode ser bombeada - linguagem pode não ser regular',
    );
  }
  
  // Simplified word running for pumping lemma
  bool _runWord(Automaton a, String word) {
    if (a.initialId == null) return false;
    
    String? current = a.initialId;
    
    for (final char in word.split('')) {
      if (current == null) break;
      final key = '$current|$char';
      final transitions = a.transitions[key];
      if (transitions == null || transitions.isEmpty) {
        current = null;
        break;
      }
      current = transitions.first;
    }
    
    return current != null && a.getState(current)?.isFinal == true;
  }
}

/// Context-free language pumping lemma implementation
class ContextFreePumpingLemma extends PumpingLemma {
  final String languageDescription;
  
  ContextFreePumpingLemma(this.languageDescription);
  
  @override
  String get title => 'Lema do Bombeamento para Linguagens Livres de Contexto';
  
  @override
  String get description => 
    'Para toda linguagem livre de contexto L, existe um número p (comprimento de bombeamento) '
    'tal que para toda palavra w ∈ L com |w| ≥ p, w pode ser escrita como w = uvwxy '
    'onde |vwx| ≤ p, |vx| ≥ 1, e uvⁱwxⁱy ∈ L para todo i ≥ 0.';
  
  @override
  String generateWord(int pumpingLength) {
    // Generate a word that's longer than the pumping length
    return 'a' * (pumpingLength + 1) + 'b' * (pumpingLength + 1);
  }
  
  @override
  PumpingResult checkPumping(String word, int pumpingLength) {
    AlgoLog.startAlgo('cfPumping', 'Lema do Bombeamento - Linguagens Livres de Contexto');
    AlgoLog.add('Verificando palavra: "$word" com comprimento de bombeamento p = $pumpingLength');
    
    if (word.length < pumpingLength) {
      AlgoLog.add('|w| = ${word.length} < p = $pumpingLength, então o lema não se aplica');
      return PumpingResult(
        canPump: true,
        explanation: 'Palavra muito curta para aplicar o lema do bombeamento',
      );
    }
    
    // Try all possible decompositions w = uvwxy where |vwx| ≤ p and |vx| ≥ 1
    for (int i = 0; i <= word.length; i++) {
      for (int j = i; j <= word.length; j++) {
        for (int k = j; k <= word.length; k++) {
          for (int l = k; l <= word.length; l++) {
            final u = word.substring(0, i);
            final v = word.substring(i, j);
            final w = word.substring(j, k);
            final x = word.substring(k, l);
            final y = word.substring(l);
            
            // Check constraints: |vwx| ≤ p and |vx| ≥ 1
            if (v.length + w.length + x.length > pumpingLength) continue;
            if (v.length + x.length < 1) continue;
            
            AlgoLog.add('Testando decomposição: u = "$u", v = "$v", w = "$w", x = "$x", y = "$y"');
            
            // Check if uvⁱwxⁱy ∈ L for i = 0, 1, 2
            final results = <bool>[];
            final pumpedWords = <String>[];
            
            for (int m = 0; m <= 2; m++) {
              final pumpedWord = u + pumpString(v, m) + w + pumpString(x, m) + y;
              pumpedWords.add(pumpedWord);
              // For context-free languages, we can't easily check membership
              // This is a simplified implementation
              final accepted = _checkContextFreeMembership(pumpedWord);
              results.add(accepted);
              AlgoLog.add('  uv^$m wx^$m y = "$pumpedWord" → ${accepted ? "aceita" : "rejeitada"}');
            }
            
            // If all pumped words are accepted, this decomposition works
            if (results.every((r) => r)) {
              AlgoLog.add('Decomposição válida encontrada!');
              return PumpingResult(
                canPump: true,
                explanation: 'Palavra pode ser bombeada com a decomposição u = "$u", v = "$v", w = "$w", x = "$x", y = "$y"',
                decompositions: ['u = "$u", v = "$v", w = "$w", x = "$x", y = "$y"'],
                pumpedStrings: pumpedWords,
              );
            }
          }
        }
      }
    }
    
    AlgoLog.add('Nenhuma decomposição válida encontrada');
    return PumpingResult(
      canPump: false,
      explanation: 'Palavra não pode ser bombeada - linguagem pode não ser livre de contexto',
    );
  }
  
  // Simplified context-free membership check
  // In a real implementation, this would use a CFG or PDA
  bool _checkContextFreeMembership(String word) {
    // This is a placeholder implementation
    // In practice, you would use a CFG parser or PDA simulator
    return word.length % 2 == 0; // Simple example
  }
}

/// Specific pumping lemma implementations for common languages
class AnBnPumpingLemma extends ContextFreePumpingLemma {
  AnBnPumpingLemma() : super('L = {a^n b^n | n ≥ 0}');
  
  @override
  String generateWord(int pumpingLength) {
    return 'a' * pumpingLength + 'b' * pumpingLength;
  }
  
  @override
  PumpingResult checkPumping(String word, int pumpingLength) {
    AlgoLog.startAlgo('anbnPumping', 'Lema do Bombeamento - L = {a^n b^n | n ≥ 0}');
    AlgoLog.add('Verificando palavra: "$word" com comprimento de bombeamento p = $pumpingLength');
    
    // Check if word is in the form a^n b^n
    final aCount = word.split('a').length - 1;
    final bCount = word.split('b').length - 1;
    final isValidForm = word.replaceAll('a', '').replaceAll('b', '').isEmpty && aCount == bCount;
    
    if (!isValidForm) {
      return PumpingResult(
        canPump: false,
        explanation: 'Palavra não está na forma a^n b^n',
      );
    }
    
    if (word.length < pumpingLength) {
      return PumpingResult(
        canPump: true,
        explanation: 'Palavra muito curta para aplicar o lema do bombeamento',
      );
    }
    
    // For a^n b^n, any pumping will break the balance
    // Try to find a decomposition that breaks the language
    for (int i = 0; i <= word.length; i++) {
      for (int j = i; j <= word.length; j++) {
        for (int k = j; k <= word.length; k++) {
          for (int l = k; l <= word.length; l++) {
            final u = word.substring(0, i);
            final v = word.substring(i, j);
            final w = word.substring(j, k);
            final x = word.substring(k, l);
            final y = word.substring(l);
            
            if (v.length + w.length + x.length > pumpingLength) continue;
            if (v.length + x.length < 1) continue;
            
            // Check if pumping breaks the language
            final pumpedWord = u + pumpString(v, 2) + w + pumpString(x, 2) + y;
            final pumpedACount = pumpedWord.split('a').length - 1;
            final pumpedBCount = pumpedWord.split('b').length - 1;
            
            if (pumpedACount != pumpedBCount) {
              AlgoLog.add('Pumping quebra a linguagem: a^${pumpedACount} b^${pumpedBCount}');
              return PumpingResult(
                canPump: false,
                explanation: 'Pumping quebra a linguagem - L não é livre de contexto',
                decompositions: ['u = "$u", v = "$v", w = "$w", x = "$x", y = "$y"'],
                pumpedStrings: [pumpedWord],
              );
            }
          }
        }
      }
    }
    
    return PumpingResult(
      canPump: true,
      explanation: 'Não foi possível encontrar uma decomposição que quebre a linguagem',
    );
  }
}

class PalindromePumpingLemma extends RegularPumpingLemma {
  PalindromePumpingLemma() : super(Automaton.empty(), 'L = {palíndromos}');
  
  @override
  String generateWord(int pumpingLength) {
    return 'a' * pumpingLength + 'b' + 'a' * pumpingLength;
  }
  
  @override
  PumpingResult checkPumping(String word, int pumpingLength) {
    AlgoLog.startAlgo('palindromePumping', 'Lema do Bombeamento - Palíndromos');
    AlgoLog.add('Verificando palavra: "$word" com comprimento de bombeamento p = $pumpingLength');
    
    // Check if word is a palindrome
    final isPalindrome = word == word.split('').reversed.join('');
    
    if (!isPalindrome) {
      return PumpingResult(
        canPump: false,
        explanation: 'Palavra não é um palíndromo',
      );
    }
    
    if (word.length < pumpingLength) {
      return PumpingResult(
        canPump: true,
        explanation: 'Palavra muito curta para aplicar o lema do bombeamento',
      );
    }
    
    // For palindromes, pumping will break the palindrome property
    for (int i = 0; i <= word.length; i++) {
      for (int j = i + 1; j <= word.length && j - i <= pumpingLength; j++) {
        final x = word.substring(0, i);
        final y = word.substring(i, j);
        final z = word.substring(j);
        
        if (y.isEmpty) continue;
        
        // Check if pumping breaks the palindrome
        final pumpedWord = x + pumpString(y, 2) + z;
        final isPumpedPalindrome = pumpedWord == pumpedWord.split('').reversed.join('');
        
        if (!isPumpedPalindrome) {
          AlgoLog.add('Pumping quebra a propriedade de palíndromo');
          return PumpingResult(
            canPump: false,
            explanation: 'Pumping quebra a propriedade de palíndromo - L não é regular',
            decompositions: ['x = "$x", y = "$y", z = "$z"'],
            pumpedStrings: [pumpedWord],
          );
        }
      }
    }
    
    return PumpingResult(
      canPump: true,
      explanation: 'Não foi possível encontrar uma decomposição que quebre a linguagem',
    );
  }
}