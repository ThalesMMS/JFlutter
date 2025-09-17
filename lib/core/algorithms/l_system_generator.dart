import '../models/l_system.dart';
import '../models/l_system_parameters.dart';
import '../models/turtle_state.dart';
import '../models/building_block.dart';
import '../result.dart';
import 'dart:math' as math;

/// Generates L-systems and their visual representations
class LSystemGenerator {
  /// Generates an L-system string
  static Result<String> generateLSystem(
    LSystem lSystem,
    int iterations, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(lSystem, iterations);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty L-system
      if (lSystem.axiom.isEmpty) {
        return Result.failure('Cannot generate L-system with empty axiom');
      }

      // Generate the L-system
      final result = _generateLSystem(lSystem, iterations, timeout);
      stopwatch.stop();
      
      return Result.success(result);
    } catch (e) {
      return Result.failure('Error generating L-system: $e');
    }
  }

  /// Validates the input L-system and iterations
  static Result<void> _validateInput(LSystem lSystem, int iterations) {
    if (lSystem.axiom.isEmpty) {
      return Result.failure('L-system must have a non-empty axiom');
    }
    
    if (iterations < 0) {
      return Result.failure('Iterations must be non-negative');
    }
    
    if (iterations > 20) {
      return Result.failure('Iterations must be at most 20 to prevent excessive computation');
    }
    
    return Result.success(null);
  }

  /// Generates the L-system string
  static String _generateLSystem(
    LSystem lSystem,
    int iterations,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    var currentString = lSystem.axiom;
    
    for (int i = 0; i < iterations; i++) {
      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        break;
      }
      
      var newString = '';
      
      for (int j = 0; j < currentString.length; j++) {
        final symbol = currentString[j];
        final rule = lSystem.rules[symbol];
        
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

  /// Generates a visual representation of an L-system
  static Result<List<TurtleState>> generateVisualRepresentation(
    LSystem lSystem,
    int iterations,
    LSystemParameters parameters, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateVisualInput(lSystem, iterations, parameters);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty L-system
      if (lSystem.axiom.isEmpty) {
        return Result.failure('Cannot generate visual representation with empty axiom');
      }

      // Generate the visual representation
      final result = _generateVisualRepresentation(lSystem, iterations, parameters, timeout);
      stopwatch.stop();
      
      return Result.success(result);
    } catch (e) {
      return Result.failure('Error generating visual representation: $e');
    }
  }

  /// Validates the input for visual generation
  static Result<void> _validateVisualInput(
    LSystem lSystem,
    int iterations,
    LSystemParameters parameters,
  ) {
    if (lSystem.axiom.isEmpty) {
      return Result.failure('L-system must have a non-empty axiom');
    }
    
    if (iterations < 0) {
      return Result.failure('Iterations must be non-negative');
    }
    
    if (iterations > 15) {
      return Result.failure('Iterations must be at most 15 for visual generation');
    }
    
    if (parameters.initialAngle < 0 || parameters.initialAngle >= 2 * math.pi) {
      return Result.failure('Initial angle must be between 0 and 2π');
    }
    
    if (parameters.angleIncrement < 0 || parameters.angleIncrement >= 2 * math.pi) {
      return Result.failure('Angle increment must be between 0 and 2π');
    }
    
    if (parameters.stepSize <= 0) {
      return Result.failure('Step size must be positive');
    }
    
    return Result.success(null);
  }

  /// Generates the visual representation
  static List<TurtleState> _generateVisualRepresentation(
    LSystem lSystem,
    int iterations,
    LSystemParameters parameters,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Generate the L-system string
    final lSystemString = _generateLSystem(lSystem, iterations, timeout);
    
    // Initialize turtle state
    var turtleState = TurtleState(
      x: parameters.initialX,
      y: parameters.initialY,
      angle: parameters.initialAngle,
      stepSize: parameters.stepSize,
      angleIncrement: parameters.angleIncrement,
    );
    
    final states = <TurtleState>[turtleState];
    final stack = <TurtleState>[];
    
    // Process each symbol in the L-system string
    for (int i = 0; i < lSystemString.length; i++) {
      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        break;
      }
      
      final symbol = lSystemString[i];
      final command = lSystem.commands[symbol];
      
      if (command != null) {
        switch (command) {
          case 'F':
          case 'G':
            // Move forward and draw
            turtleState = turtleState.moveForward();
            states.add(turtleState);
            break;
          case 'f':
          case 'g':
            // Move forward without drawing
            turtleState = turtleState.moveForward();
            break;
          case '+':
            // Turn left
            turtleState = turtleState.turnLeft();
            break;
          case '-':
            // Turn right
            turtleState = turtleState.turnRight();
            break;
          case '[':
            // Push current state to stack
            stack.add(turtleState);
            break;
          case ']':
            // Pop state from stack
            if (stack.isNotEmpty) {
              turtleState = stack.removeLast();
            }
            break;
          case '|':
            // Turn 180 degrees
            turtleState = turtleState.turn180();
            break;
          case '&':
            // Pitch down
            turtleState = turtleState.pitchDown();
            break;
          case '^':
            // Pitch up
            turtleState = turtleState.pitchUp();
            break;
          case '\\':
            // Roll left
            turtleState = turtleState.rollLeft();
            break;
          case '/':
            // Roll right
            turtleState = turtleState.rollRight();
            break;
          default:
            // Unknown command, do nothing
            break;
        }
      }
    }
    
    return states;
  }

  /// Generates building blocks for an L-system
  static Result<List<BuildingBlock>> generateBuildingBlocks(
    LSystem lSystem,
    int iterations,
    LSystemParameters parameters, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateVisualInput(lSystem, iterations, parameters);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty L-system
      if (lSystem.axiom.isEmpty) {
        return Result.failure('Cannot generate building blocks with empty axiom');
      }

      // Generate the building blocks
      final result = _generateBuildingBlocks(lSystem, iterations, parameters, timeout);
      stopwatch.stop();
      
      return Result.success(result);
    } catch (e) {
      return Result.failure('Error generating building blocks: $e');
    }
  }

  /// Generates the building blocks
  static List<BuildingBlock> _generateBuildingBlocks(
    LSystem lSystem,
    int iterations,
    LSystemParameters parameters,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Generate the L-system string
    final lSystemString = _generateLSystem(lSystem, iterations, timeout);
    
    // Initialize turtle state
    var turtleState = TurtleState(
      x: parameters.initialX,
      y: parameters.initialY,
      angle: parameters.initialAngle,
      stepSize: parameters.stepSize,
      angleIncrement: parameters.angleIncrement,
    );
    
    final buildingBlocks = <BuildingBlock>[];
    final stack = <TurtleState>[];
    
    // Process each symbol in the L-system string
    for (int i = 0; i < lSystemString.length; i++) {
      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        break;
      }
      
      final symbol = lSystemString[i];
      final command = lSystem.commands[symbol];
      
      if (command != null) {
        switch (command) {
          case 'F':
          case 'G':
            // Move forward and draw
            final newState = turtleState.moveForward();
            buildingBlocks.add(BuildingBlock.line(
              startX: turtleState.x,
              startY: turtleState.y,
              endX: newState.x,
              endY: newState.y,
              color: parameters.lineColor,
              thickness: parameters.lineThickness,
            ));
            turtleState = newState;
            break;
          case 'f':
          case 'g':
            // Move forward without drawing
            turtleState = turtleState.moveForward();
            break;
          case '+':
            // Turn left
            turtleState = turtleState.turnLeft();
            break;
          case '-':
            // Turn right
            turtleState = turtleState.turnRight();
            break;
          case '[':
            // Push current state to stack
            stack.add(turtleState);
            break;
          case ']':
            // Pop state from stack
            if (stack.isNotEmpty) {
              turtleState = stack.removeLast();
            }
            break;
          case '|':
            // Turn 180 degrees
            turtleState = turtleState.turn180();
            break;
          case '&':
            // Pitch down
            turtleState = turtleState.pitchDown();
            break;
          case '^':
            // Pitch up
            turtleState = turtleState.pitchUp();
            break;
          case '\\':
            // Roll left
            turtleState = turtleState.rollLeft();
            break;
          case '/':
            // Roll right
            turtleState = turtleState.rollRight();
            break;
          default:
            // Unknown command, do nothing
            break;
        }
      }
    }
    
    return buildingBlocks;
  }

  /// Creates a predefined L-system
  static Result<LSystem> createPredefinedLSystem(String name) {
    switch (name.toLowerCase()) {
      case 'dragon':
        return Result.success(LSystem.dragon());
      case 'sierpinski':
        return Result.success(LSystem.sierpinski());
      case 'koch':
        return Result.success(LSystem.koch());
      case 'hilbert':
        return Result.success(LSystem.hilbert());
      case 'peano':
        return Result.success(LSystem.peano());
      case 'gosper':
        return Result.success(LSystem.gosper());
      case 'snowflake':
        return Result.success(LSystem.snowflake());
      case 'plant':
        return Result.success(LSystem.plant());
      default:
        return Result.failure('Unknown predefined L-system: $name');
    }
  }

  /// Creates predefined L-system parameters
  static Result<LSystemParameters> createPredefinedParameters(String name) {
    switch (name.toLowerCase()) {
      case 'dragon':
        return Result.success(LSystemParameters.dragon());
      case 'sierpinski':
        return Result.success(LSystemParameters.sierpinski());
      case 'koch':
        return Result.success(LSystemParameters.koch());
      case 'hilbert':
        return Result.success(LSystemParameters.hilbert());
      case 'peano':
        return Result.success(LSystemParameters.peano());
      case 'gosper':
        return Result.success(LSystemParameters.gosper());
      case 'snowflake':
        return Result.success(LSystemParameters.snowflake());
      case 'plant':
        return Result.success(LSystemParameters.plant());
      default:
        return Result.failure('Unknown predefined parameters: $name');
    }
  }

  /// Analyzes an L-system string
  static Result<LSystemAnalysis> analyzeLSystem(
    LSystem lSystem,
    int iterations, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(lSystem, iterations);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty L-system
      if (lSystem.axiom.isEmpty) {
        return Result.failure('Cannot analyze L-system with empty axiom');
      }

      // Analyze the L-system
      final result = _analyzeLSystem(lSystem, iterations, timeout);
      stopwatch.stop();
      
      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      
      return Result.success(finalResult);
    } catch (e) {
      return Result.failure('Error analyzing L-system: $e');
    }
  }

  /// Analyzes the L-system
  static LSystemAnalysis _analyzeLSystem(
    LSystem lSystem,
    int iterations,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Generate the L-system string
    final lSystemString = _generateLSystem(lSystem, iterations, timeout);
    
    // Analyze the string
    final symbolCounts = <String, int>{};
    final commandCounts = <String, int>{};
    
    for (int i = 0; i < lSystemString.length; i++) {
      final symbol = lSystemString[i];
      symbolCounts[symbol] = (symbolCounts[symbol] ?? 0) + 1;
      
      final command = lSystem.commands[symbol];
      if (command != null) {
        commandCounts[command] = (commandCounts[command] ?? 0) + 1;
      }
    }
    
    // Calculate growth rate
    final growthRate = _calculateGrowthRate(lSystem, iterations, timeout);
    
    // Calculate complexity
    final complexity = _calculateComplexity(lSystemString, lSystem);
    
    return LSystemAnalysis(
      lSystemString: lSystemString,
      symbolCounts: symbolCounts,
      commandCounts: commandCounts,
      growthRate: growthRate,
      complexity: complexity,
      executionTime: DateTime.now().difference(startTime),
    );
  }

  /// Calculates the growth rate of the L-system
  static double _calculateGrowthRate(
    LSystem lSystem,
    int iterations,
    Duration timeout,
  ) {
    if (iterations == 0) return 1.0;
    
    final lengths = <int>[];
    for (int i = 0; i <= iterations; i++) {
      final string = _generateLSystem(lSystem, i, timeout);
      lengths.add(string.length);
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

  /// Calculates the complexity of the L-system string
  static double _calculateComplexity(String lSystemString, LSystem lSystem) {
    if (lSystemString.isEmpty) return 0.0;
    
    // Calculate entropy
    final symbolCounts = <String, int>{};
    for (int i = 0; i < lSystemString.length; i++) {
      final symbol = lSystemString[i];
      symbolCounts[symbol] = (symbolCounts[symbol] ?? 0) + 1;
    }
    
    double entropy = 0.0;
    for (final count in symbolCounts.values) {
      final probability = count / lSystemString.length;
      if (probability > 0) {
        entropy -= probability * math.log(probability) / math.ln2;
      }
    }
    
    // Normalize by string length
    return entropy / lSystemString.length;
  }
}

/// Analysis result of an L-system
class LSystemAnalysis {
  final String lSystemString;
  final Map<String, int> symbolCounts;
  final Map<String, int> commandCounts;
  final double growthRate;
  final double complexity;
  final Duration executionTime;

  const LSystemAnalysis({
    required this.lSystemString,
    required this.symbolCounts,
    required this.commandCounts,
    required this.growthRate,
    required this.complexity,
    required this.executionTime,
  });

  LSystemAnalysis copyWith({
    String? lSystemString,
    Map<String, int>? symbolCounts,
    Map<String, int>? commandCounts,
    double? growthRate,
    double? complexity,
    Duration? executionTime,
  }) {
    return LSystemAnalysis(
      lSystemString: lSystemString ?? this.lSystemString,
      symbolCounts: symbolCounts ?? this.symbolCounts,
      commandCounts: commandCounts ?? this.commandCounts,
      growthRate: growthRate ?? this.growthRate,
      complexity: complexity ?? this.complexity,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}
