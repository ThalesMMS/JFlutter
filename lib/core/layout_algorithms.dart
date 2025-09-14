import 'dart:math' as math;
import 'automaton.dart';

/// Base class for layout algorithms
abstract class LayoutAlgorithm {
  String get name;
  String get description;
  
  /// Applies the layout algorithm to the automaton
  Automaton apply(Automaton automaton, {Size? canvasSize});
}

/// Circle layout algorithm - arranges states in a circle
class CircleLayoutAlgorithm extends LayoutAlgorithm {
  @override
  String get name => 'Círculo';
  
  @override
  String get description => 'Organiza os estados em um círculo';
  
  @override
  Automaton apply(Automaton automaton, {Size? canvasSize}) {
    if (automaton.states.isEmpty) return automaton;
    
    final size = canvasSize ?? const Size(600, 400);
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(centerX, centerY) * 0.7;
    
    final states = automaton.states.length;
    final angleStep = 2 * math.pi / states;
    
    var result = automaton.clone();
    
    for (int i = 0; i < states; i++) {
      final angle = i * angleStep - math.pi / 2; // Start from top
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      result = result.setStatePosition(automaton.states[i].id, x, y);
    }
    
    return result;
  }
}

/// Tree layout algorithm - arranges states in a hierarchical tree
class TreeLayoutAlgorithm extends LayoutAlgorithm {
  @override
  String get name => 'Árvore';
  
  @override
  String get description => 'Organiza os estados em uma estrutura hierárquica de árvore';
  
  @override
  Automaton apply(Automaton automaton, {Size? canvasSize}) {
    if (automaton.states.isEmpty) return automaton;
    
    final size = canvasSize ?? const Size(600, 400);
    final startX = size.width / 2;
    final startY = 50.0;
    const levelHeight = 80.0;
    const nodeSpacing = 120.0;
    
    var result = automaton.clone();
    
    // Build adjacency list
    final adjacency = <String, List<String>>{};
    for (final state in automaton.states) {
      adjacency[state.id] = [];
    }
    
    for (final entry in automaton.transitions.entries) {
      final parts = entry.key.split('|');
      final from = parts[0];
      final to = entry.value.first;
      if (!adjacency[from]!.contains(to)) {
        adjacency[from]!.add(to);
      }
    }
    
    // Find root (initial state or first state)
    final root = automaton.initialId ?? automaton.states.first.id;
    
    // Calculate positions using BFS
    final visited = <String>{};
    final queue = <String>[root];
    final levels = <String, int>{};
    final positions = <String, Offset>{};
    
    levels[root] = 0;
    positions[root] = Offset(startX, startY);
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (visited.contains(current)) continue;
      
      visited.add(current);
      final level = levels[current]!;
      final children = adjacency[current]!.where((child) => !visited.contains(child)).toList();
      
      if (children.isNotEmpty) {
        final childY = startY + (level + 1) * levelHeight;
        final totalWidth = children.length * nodeSpacing;
        final startChildX = startX - totalWidth / 2 + nodeSpacing / 2;
        
        for (int i = 0; i < children.length; i++) {
          final child = children[i];
          final childX = startChildX + i * nodeSpacing;
          levels[child] = level + 1;
          positions[child] = Offset(childX, childY);
          queue.add(child);
        }
      }
    }
    
    // Apply positions
    for (final entry in positions.entries) {
      result = result.setStatePosition(entry.key, entry.value.dx, entry.value.dy);
    }
    
    return result;
  }
}

/// Spiral layout algorithm - arranges states in a spiral pattern
class SpiralLayoutAlgorithm extends LayoutAlgorithm {
  @override
  String get name => 'Espiral';
  
  @override
  String get description => 'Organiza os estados em um padrão espiral';
  
  @override
  Automaton apply(Automaton automaton, {Size? canvasSize}) {
    if (automaton.states.isEmpty) return automaton;
    
    final size = canvasSize ?? const Size(600, 400);
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    var result = automaton.clone();
    
    for (int i = 0; i < automaton.states.length; i++) {
      final angle = i * 0.5; // Spiral angle increment
      final radius = 50 + i * 15; // Increasing radius
      
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      result = result.setStatePosition(automaton.states[i].id, x, y);
    }
    
    return result;
  }
}

/// GEM (Graph Embedder) layout algorithm - force-directed layout
class GEMLayoutAlgorithm extends LayoutAlgorithm {
  @override
  String get name => 'GEM';
  
  @override
  String get description => 'Algoritmo de layout baseado em forças (GEM)';
  
  @override
  Automaton apply(Automaton automaton, {Size? canvasSize}) {
    if (automaton.states.isEmpty) return automaton;
    
    final size = canvasSize ?? const Size(600, 400);
    const iterations = 100;
    const temperature = 1.0;
    const coolingFactor = 0.95;
    
    var result = automaton.clone();
    
    // Initialize random positions
    final random = math.Random(42); // Fixed seed for reproducibility
    final positions = <String, Offset>{};
    
    for (final state in automaton.states) {
      positions[state.id] = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
    }
    
    // Build adjacency list
    final adjacency = <String, Set<String>>{};
    for (final state in automaton.states) {
      adjacency[state.id] = {};
    }
    
    for (final entry in automaton.transitions.entries) {
      final parts = entry.key.split('|');
      final from = parts[0];
      for (final to in entry.value) {
        adjacency[from]!.add(to);
        adjacency[to]!.add(from); // Undirected for layout
      }
    }
    
    // GEM algorithm iterations
    var currentTemp = temperature;
    
    for (int iter = 0; iter < iterations; iter++) {
      final forces = <String, Offset>{};
      
      // Initialize forces
      for (final state in automaton.states) {
        forces[state.id] = Offset.zero;
      }
      
      // Calculate repulsive forces (all pairs)
      for (int i = 0; i < automaton.states.length; i++) {
        for (int j = i + 1; j < automaton.states.length; j++) {
          final state1 = automaton.states[i];
          final state2 = automaton.states[j];
          final pos1 = positions[state1.id]!;
          final pos2 = positions[state2.id]!;
          
          final dx = pos1.dx - pos2.dx;
          final dy = pos1.dy - pos2.dy;
          final distance = math.sqrt(dx * dx + dy * dy);
          
          if (distance > 0) {
            final force = 1000 / (distance * distance); // Repulsive force
            final fx = (dx / distance) * force;
            final fy = (dy / distance) * force;
            
            forces[state1.id] = Offset(
              forces[state1.id]!.dx + fx,
              forces[state1.id]!.dy + fy,
            );
            forces[state2.id] = Offset(
              forces[state2.id]!.dx - fx,
              forces[state2.id]!.dy - fy,
            );
          }
        }
      }
      
      // Calculate attractive forces (connected nodes)
      for (final entry in adjacency.entries) {
        final from = entry.key;
        final neighbors = entry.value;
        
        for (final to in neighbors) {
          final pos1 = positions[from]!;
          final pos2 = positions[to]!;
          
          final dx = pos2.dx - pos1.dx;
          final dy = pos2.dy - pos1.dy;
          final distance = math.sqrt(dx * dx + dy * dy);
          
          if (distance > 0) {
            final force = distance / 100; // Attractive force
            final fx = (dx / distance) * force;
            final fy = (dy / distance) * force;
            
            forces[from] = Offset(
              forces[from]!.dx + fx,
              forces[from]!.dy + fy,
            );
          }
        }
      }
      
      // Apply forces with temperature
      for (final entry in forces.entries) {
        final stateId = entry.key;
        final force = entry.value;
        
        final newPos = Offset(
          positions[stateId]!.dx + force.dx * currentTemp,
          positions[stateId]!.dy + force.dy * currentTemp,
        );
        
        // Keep within bounds
        positions[stateId] = Offset(
          newPos.dx.clamp(50, size.width - 50),
          newPos.dy.clamp(50, size.height - 50),
        );
      }
      
      currentTemp *= coolingFactor;
    }
    
    // Apply final positions
    for (final entry in positions.entries) {
      result = result.setStatePosition(entry.key, entry.value.dx, entry.value.dy);
    }
    
    return result;
  }
}

/// Two-circle layout algorithm - arranges states in two concentric circles
class TwoCircleLayoutAlgorithm extends LayoutAlgorithm {
  @override
  String get name => 'Dois Círculos';
  
  @override
  String get description => 'Organiza os estados em dois círculos concêntricos';
  
  @override
  Automaton apply(Automaton automaton, {Size? canvasSize}) {
    if (automaton.states.isEmpty) return automaton;
    
    final size = canvasSize ?? const Size(600, 400);
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    var result = automaton.clone();
    
    // Separate final and non-final states
    final finalStates = automaton.states.where((s) => s.isFinal).toList();
    final nonFinalStates = automaton.states.where((s) => !s.isFinal).toList();
    
    // Place non-final states in inner circle
    if (nonFinalStates.isNotEmpty) {
      final innerRadius = 80.0;
      final angleStep = 2 * math.pi / nonFinalStates.length;
      
      for (int i = 0; i < nonFinalStates.length; i++) {
        final angle = i * angleStep - math.pi / 2;
        final x = centerX + innerRadius * math.cos(angle);
        final y = centerY + innerRadius * math.sin(angle);
        
        result = result.setStatePosition(nonFinalStates[i].id, x, y);
      }
    }
    
    // Place final states in outer circle
    if (finalStates.isNotEmpty) {
      final outerRadius = 150.0;
      final angleStep = 2 * math.pi / finalStates.length;
      
      for (int i = 0; i < finalStates.length; i++) {
        final angle = i * angleStep - math.pi / 2;
        final x = centerX + outerRadius * math.cos(angle);
        final y = centerY + outerRadius * math.sin(angle);
        
        result = result.setStatePosition(finalStates[i].id, x, y);
      }
    }
    
    return result;
  }
}

/// Factory for layout algorithms
class LayoutAlgorithmFactory {
  static final Map<String, LayoutAlgorithm> _algorithms = {
    'circle': CircleLayoutAlgorithm(),
    'tree': TreeLayoutAlgorithm(),
    'spiral': SpiralLayoutAlgorithm(),
    'gem': GEMLayoutAlgorithm(),
    'twoCircle': TwoCircleLayoutAlgorithm(),
  };
  
  static LayoutAlgorithm getAlgorithm(String name) {
    return _algorithms[name] ?? CircleLayoutAlgorithm();
  }
  
  static List<String> getAvailableAlgorithms() {
    return _algorithms.keys.toList();
  }
  
  static List<LayoutAlgorithm> getAllAlgorithms() {
    return _algorithms.values.toList();
  }
}

/// Size class for canvas dimensions
class Size {
  final double width;
  final double height;
  
  const Size(this.width, this.height);
}

/// Offset class for 2D positions
class Offset {
  final double dx;
  final double dy;
  
  const Offset(this.dx, this.dy);
  
  static const Offset zero = Offset(0, 0);
}
