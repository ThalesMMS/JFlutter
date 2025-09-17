import 'package:collection/collection.dart';

/// Represents an L-system (Lindenmayer system)
class LSystem {
  final String axiom;
  final Map<String, String> rules;
  final Map<String, String> commands;
  final String name;
  final String description;

  const LSystem({
    required this.axiom,
    required this.rules,
    required this.commands,
    this.name = '',
    this.description = '',
  });

  /// Creates a predefined dragon curve L-system
  factory LSystem.dragon() {
    return LSystem(
      axiom: 'F',
      rules: {
        'F': 'F+G',
        'G': 'F-G',
      },
      commands: {
        'F': 'F',
        'G': 'F',
        '+': '+',
        '-': '-',
      },
      name: 'Dragon Curve',
      description: 'A classic fractal curve',
    );
  }

  /// Creates a predefined Sierpinski triangle L-system
  factory LSystem.sierpinski() {
    return LSystem(
      axiom: 'F-G-G',
      rules: {
        'F': 'F-G+F+G-F',
        'G': 'GG',
      },
      commands: {
        'F': 'F',
        'G': 'F',
        '+': '+',
        '-': '-',
      },
      name: 'Sierpinski Triangle',
      description: 'A fractal triangle pattern',
    );
  }

  /// Creates a predefined Koch curve L-system
  factory LSystem.koch() {
    return LSystem(
      axiom: 'F',
      rules: {
        'F': 'F+F-F-F+F',
      },
      commands: {
        'F': 'F',
        '+': '+',
        '-': '-',
      },
      name: 'Koch Curve',
      description: 'A fractal curve with self-similarity',
    );
  }

  /// Creates a predefined Hilbert curve L-system
  factory LSystem.hilbert() {
    return LSystem(
      axiom: 'A',
      rules: {
        'A': '-BF+AFA+FB-',
        'B': '+AF-BFB-FA+',
      },
      commands: {
        'A': '',
        'B': '',
        'F': 'F',
        '+': '+',
        '-': '-',
      },
      name: 'Hilbert Curve',
      description: 'A space-filling curve',
    );
  }

  /// Creates a predefined Peano curve L-system
  factory LSystem.peano() {
    return LSystem(
      axiom: 'F',
      rules: {
        'F': 'F+F-F-F-F+F+F+F-F',
      },
      commands: {
        'F': 'F',
        '+': '+',
        '-': '-',
      },
      name: 'Peano Curve',
      description: 'Another space-filling curve',
    );
  }

  /// Creates a predefined Gosper curve L-system
  factory LSystem.gosper() {
    return LSystem(
      axiom: 'A',
      rules: {
        'A': 'A-B--B+A++AA+B-',
        'B': '+A-BB--B-A++A+B',
      },
      commands: {
        'A': 'F',
        'B': 'F',
        '+': '+',
        '-': '-',
      },
      name: 'Gosper Curve',
      description: 'A fractal curve with hexagonal symmetry',
    );
  }

  /// Creates a predefined snowflake L-system
  factory LSystem.snowflake() {
    return LSystem(
      axiom: 'F++F++F',
      rules: {
        'F': 'F-F++F-F',
      },
      commands: {
        'F': 'F',
        '+': '+',
        '-': '-',
      },
      name: 'Snowflake',
      description: 'A fractal snowflake pattern',
    );
  }

  /// Creates a predefined plant L-system
  factory LSystem.plant() {
    return LSystem(
      axiom: 'F',
      rules: {
        'F': 'F[+F]F[-F]F',
      },
      commands: {
        'F': 'F',
        '+': '+',
        '-': '-',
        '[': '[',
        ']': ']',
      },
      name: 'Plant',
      description: 'A branching plant-like structure',
    );
  }

  /// Validates the L-system
  bool isValid() {
    if (axiom.isEmpty) return false;
    
    // Check if all symbols in axiom have rules or commands
    for (int i = 0; i < axiom.length; i++) {
      final symbol = axiom[i];
      if (!rules.containsKey(symbol) && !commands.containsKey(symbol)) {
        return false;
      }
    }
    
    return true;
  }

  /// Gets all symbols used in the L-system
  Set<String> getAllSymbols() {
    final symbols = <String>{};
    
    // Add symbols from axiom
    for (int i = 0; i < axiom.length; i++) {
      symbols.add(axiom[i]);
    }
    
    // Add symbols from rules
    for (final rule in rules.values) {
      for (int i = 0; i < rule.length; i++) {
        symbols.add(rule[i]);
      }
    }
    
    return symbols;
  }

  /// Gets all non-terminal symbols (those with rules)
  Set<String> getNonTerminals() {
    return rules.keys.toSet();
  }

  /// Gets all terminal symbols (those with commands but no rules)
  Set<String> getTerminals() {
    final nonTerminals = getNonTerminals();
    return commands.keys.where((symbol) => !nonTerminals.contains(symbol)).toSet();
  }

  /// Generates the L-system string for a given number of iterations
  String generate(int iterations) {
    if (iterations < 0) return '';
    if (iterations == 0) return axiom;
    
    var currentString = axiom;
    
    for (int i = 0; i < iterations; i++) {
      var newString = '';
      
      for (int j = 0; j < currentString.length; j++) {
        final symbol = currentString[j];
        final rule = rules[symbol];
        
        if (rule != null) {
          newString += rule;
        } else {
          newString += symbol;
        }
      }
      
      currentString = newString;
    }
    
    return currentString;
  }

  /// Calculates the growth rate of the L-system
  double calculateGrowthRate(int maxIterations) {
    if (maxIterations <= 1) return 1.0;
    
    final lengths = <int>[];
    for (int i = 0; i <= maxIterations; i++) {
      lengths.add(generate(i).length);
    }
    
    if (lengths.length < 2) return 1.0;
    
    // Calculate average growth rate
    double totalGrowth = 0.0;
    for (int i = 1; i < lengths.length; i++) {
      if (lengths[i - 1] > 0) {
        totalGrowth += lengths[i] / lengths[i - 1];
      }
    }
    
    return totalGrowth / (lengths.length - 1);
  }

  /// Creates a copy of the L-system with updated properties
  LSystem copyWith({
    String? axiom,
    Map<String, String>? rules,
    Map<String, String>? commands,
    String? name,
    String? description,
  }) {
    return LSystem(
      axiom: axiom ?? this.axiom,
      rules: rules ?? this.rules,
      commands: commands ?? this.commands,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LSystem &&
        other.axiom == axiom &&
        const MapEquality().equals(other.rules, rules) &&
        const MapEquality().equals(other.commands, commands) &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      axiom,
      const MapEquality().hash(rules),
      const MapEquality().hash(commands),
      name,
      description,
    );
  }

  @override
  String toString() {
    return 'LSystem(name: $name, axiom: $axiom, rules: $rules, commands: $commands)';
  }
}
