import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/entities/automaton_entity.dart';
import 'contextual_help.dart';

class LayoutTools {
  static const double _defaultRadius = 150.0;
  static const double _minDistance = 100.0;

  /// Arranges states in a compact circular layout
  static AutomatonEntity compactLayout(AutomatonEntity automaton) {
    if (automaton.states.isEmpty) return automaton;

    final states = automaton.states.toList();
    final centerX = 300.0;
    final centerY = 200.0;
    final radius = math.min(_defaultRadius, states.length * 20.0);

    final newStates = <StateEntity>[];
    for (int i = 0; i < states.length; i++) {
      final angle = (2 * math.pi * i) / states.length;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      newStates.add(states[i].copyWith(x: x, y: y));
    }

    return automaton.copyWith(states: newStates);
  }

  /// Arranges states in a balanced grid layout
  static AutomatonEntity balancedLayout(AutomatonEntity automaton) {
    if (automaton.states.isEmpty) return automaton;

    final states = automaton.states.toList();
    final cols = math.sqrt(states.length).ceil().toInt();
    final rows = (states.length / cols).ceil().toInt();
    
    final cellWidth = 120.0;
    final cellHeight = 100.0;
    final startX = 100.0;
    final startY = 100.0;

    final newStates = <StateEntity>[];
    for (int i = 0; i < states.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      
      final x = startX + col * cellWidth;
      final y = startY + row * cellHeight;

      newStates.add(states[i].copyWith(x: x, y: y));
    }

    return automaton.copyWith(states: newStates);
  }

  /// Arranges states in a spread layout with better spacing
  static AutomatonEntity spreadLayout(AutomatonEntity automaton) {
    if (automaton.states.isEmpty) return automaton;

    final states = automaton.states.toList();
    final cols = math.sqrt(states.length).ceil().toInt();
    final rows = (states.length / cols).ceil().toInt();
    
    final cellWidth = 180.0;
    final cellHeight = 150.0;
    final startX = 50.0;
    final startY = 50.0;

    final newStates = <StateEntity>[];
    for (int i = 0; i < states.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      
      final x = startX + col * cellWidth;
      final y = startY + row * cellHeight;

      newStates.add(states[i].copyWith(x: x, y: y));
    }

    return automaton.copyWith(states: newStates);
  }

  /// Arranges states in a hierarchical layout (initial state at top)
  static AutomatonEntity hierarchicalLayout(AutomatonEntity automaton) {
    if (automaton.states.isEmpty) return automaton;

    final states = automaton.states.toList();
    final initialId = automaton.initialId;
    
    if (initialId == null) {
      return balancedLayout(automaton);
    }

    // Find initial state and place it at the top
    final initialState = states.firstWhere(
      (s) => s.id == initialId,
      orElse: () => states.first,
    );

    final newStates = <StateEntity>[];
    
    // Place initial state at the top center
    newStates.add(initialState.copyWith(x: 300.0, y: 50.0));
    
    // Place other states in a grid below
    final otherStates = states.where((s) => s.id != initialId).toList();
    final cols = math.sqrt(otherStates.length).ceil().toInt();
    
    for (int i = 0; i < otherStates.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      
      final x = 100.0 + col * 150.0;
      final y = 150.0 + row * 100.0;

      newStates.add(otherStates[i].copyWith(x: x, y: y));
    }

    return automaton.copyWith(states: newStates);
  }

  /// Auto-arranges states to minimize edge crossings
  static AutomatonEntity autoLayout(AutomatonEntity automaton) {
    if (automaton.states.isEmpty) return automaton;

    // Simple force-directed layout
    final states = automaton.states.toList();
    final positions = <String, Offset>{};
    
    // Initialize positions randomly
    final random = math.Random(42); // Fixed seed for reproducibility
    for (final state in states) {
      positions[state.id] = Offset(
        100 + random.nextDouble() * 400,
        100 + random.nextDouble() * 300,
      );
    }

    // Apply force-directed algorithm
    for (int iteration = 0; iteration < 100; iteration++) {
      final forces = <String, Offset>{};
      
      // Initialize forces
      for (final state in states) {
        forces[state.id] = Offset.zero;
      }

      // Repulsive forces between all pairs of states
      for (int i = 0; i < states.length; i++) {
        for (int j = i + 1; j < states.length; j++) {
          final state1 = states[i];
          final state2 = states[j];
          final pos1 = positions[state1.id]!;
          final pos2 = positions[state2.id]!;
          
          final distance = (pos1 - pos2).distance;
          if (distance > 0) {
            final direction = (pos1 - pos2) / distance;
            final force = direction * (1000 / (distance * distance));
            
            forces[state1.id] = forces[state1.id]! + force;
            forces[state2.id] = forces[state2.id]! - force;
          }
        }
      }

      // Attractive forces for connected states
      for (final entry in automaton.transitions.entries) {
        final parts = entry.key.split('|');
        if (parts.length == 2) {
          final fromId = parts[0];
          final toId = entry.value.isNotEmpty ? entry.value.first : null;
          
          if (toId != null && positions.containsKey(fromId) && positions.containsKey(toId)) {
            final pos1 = positions[fromId]!;
            final pos2 = positions[toId]!;
            final distance = (pos1 - pos2).distance;
            
            if (distance > 0) {
              final direction = (pos2 - pos1) / distance;
              final force = direction * (distance / 100);
              
              forces[fromId] = forces[fromId]! + force;
              forces[toId] = forces[toId]! - force;
            }
          }
        }
      }

      // Update positions
      for (final state in states) {
        final force = forces[state.id]!;
        final newPos = positions[state.id]! + force * 0.1;
        
        // Keep within bounds
        positions[state.id] = Offset(
          newPos.dx.clamp(50.0, 550.0),
          newPos.dy.clamp(50.0, 350.0),
        );
      }
    }

    // Create new states with calculated positions
    final newStates = states.map((state) {
      final pos = positions[state.id]!;
      return state.copyWith(x: pos.dx, y: pos.dy);
    }).toList();

    return automaton.copyWith(states: newStates);
  }

  /// Centers the automaton in the view
  static AutomatonEntity centerLayout(AutomatonEntity automaton) {
    if (automaton.states.isEmpty) return automaton;

    final states = automaton.states.toList();
    
    // Calculate bounding box
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (final state in states) {
      minX = math.min(minX, state.x);
      maxX = math.max(maxX, state.x);
      minY = math.min(minY, state.y);
      maxY = math.max(maxY, state.y);
    }
    
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;
    final targetCenterX = 300.0;
    final targetCenterY = 200.0;
    
    final offsetX = targetCenterX - centerX;
    final offsetY = targetCenterY - centerY;
    
    final newStates = states.map((state) {
      return state.copyWith(
        x: state.x + offsetX,
        y: state.y + offsetY,
      );
    }).toList();

    return automaton.copyWith(states: newStates);
  }

  /// Auto-centers any automaton after operations
  static AutomatonEntity autoCenter(AutomatonEntity automaton) {
    return centerLayout(automaton);
  }
}

class LayoutToolsWidget extends StatelessWidget {
  const LayoutToolsWidget({
    super.key,
    required this.automaton,
    this.onLayoutChanged,
  });

  final AutomatonEntity automaton;
  final void Function(AutomatonEntity)? onLayoutChanged;

  void _applyLayout(AutomatonEntity Function(AutomatonEntity) layoutFunction) {
    final newAutomaton = layoutFunction(automaton);
    if (onLayoutChanged != null) {
      onLayoutChanged!(newAutomaton);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Layout e Posicionamento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                ContextualHelp(
                  helpContent: HelpContent.layoutTools,
                  title: 'Ferramentas de Layout',
                  icon: Icons.view_module,
                  showOnHover: !isMobile,
                  showOnTap: isMobile,
                  child: Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Layout presets grid
            if (isMobile)
              _buildMobileLayoutGrid()
            else
              _buildDesktopLayoutGrid(),
            
            const SizedBox(height: 12),
            
            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reorganiza os estados do automaton para melhor visualização.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayoutGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildLayoutButton(
          icon: Icons.circle_outlined,
          label: 'Compacto',
          description: 'Estados em círculo',
          onPressed: () => _applyLayout(LayoutTools.compactLayout),
        ),
        _buildLayoutButton(
          icon: Icons.grid_view,
          label: 'Balanceado',
          description: 'Grid organizado',
          onPressed: () => _applyLayout(LayoutTools.balancedLayout),
        ),
        _buildLayoutButton(
          icon: Icons.open_in_full,
          label: 'Espalhar',
          description: 'Distribuição uniforme',
          onPressed: () => _applyLayout(LayoutTools.spreadLayout),
        ),
        _buildLayoutButton(
          icon: Icons.account_tree,
          label: 'Hierárquico',
          description: 'Organização em níveis',
          onPressed: () => _applyLayout(LayoutTools.hierarchicalLayout),
        ),
        _buildLayoutButton(
          icon: Icons.auto_awesome,
          label: 'Automático',
          description: 'Algoritmo inteligente',
          onPressed: () => _applyLayout(LayoutTools.autoLayout),
        ),
        _buildLayoutButton(
          icon: Icons.center_focus_strong,
          label: 'Centralizar',
          description: 'Centralizar no canvas',
          onPressed: () => _applyLayout(LayoutTools.centerLayout),
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _buildMobileLayoutGrid() {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _buildLayoutButton(
                icon: Icons.circle_outlined,
                label: 'Compacto',
                onPressed: () => _applyLayout(LayoutTools.compactLayout),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLayoutButton(
                icon: Icons.grid_view,
                label: 'Balanceado',
                onPressed: () => _applyLayout(LayoutTools.balancedLayout),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Second row
        Row(
          children: [
            Expanded(
              child: _buildLayoutButton(
                icon: Icons.open_in_full,
                label: 'Espalhar',
                onPressed: () => _applyLayout(LayoutTools.spreadLayout),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLayoutButton(
                icon: Icons.account_tree,
                label: 'Hierárquico',
                onPressed: () => _applyLayout(LayoutTools.hierarchicalLayout),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Third row
        Row(
          children: [
            Expanded(
              child: _buildLayoutButton(
                icon: Icons.auto_awesome,
                label: 'Automático',
                onPressed: () => _applyLayout(LayoutTools.autoLayout),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLayoutButton(
                icon: Icons.center_focus_strong,
                label: 'Centralizar',
                onPressed: () => _applyLayout(LayoutTools.centerLayout),
                isOutlined: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutButton({
    required IconData icon,
    required String label,
    String? description,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return Tooltip(
      message: description ?? label,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label),
            ),
    );
  }
}
