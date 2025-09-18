import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/grammar_editor.dart';
import '../widgets/grammar_simulation_panel.dart';
import '../widgets/grammar_algorithm_panel.dart';

/// Page for working with Context-Free Grammars
class GrammarPage extends ConsumerStatefulWidget {
  const GrammarPage({super.key});

  @override
  ConsumerState<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends ConsumerState<GrammarPage> {
  bool _showControls = true;
  bool _showSimulation = false;
  bool _showAlgorithms = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 1024;

    return Scaffold(
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          // Mobile controls toggle - more compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    icon: Icons.edit,
                    label: 'Editor',
                    isActive: _showControls,
                    onPressed: () => setState(() => _showControls = !_showControls),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleButton(
                    icon: Icons.play_arrow,
                    label: 'Parse',
                    isActive: _showSimulation,
                    onPressed: () => setState(() => _showSimulation = !_showSimulation),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleButton(
                    icon: Icons.auto_awesome,
                    label: 'Algorithms',
                    isActive: _showAlgorithms,
                    onPressed: () => setState(() => _showAlgorithms = !_showAlgorithms),
                  ),
                ),
              ],
            ),
          ),

          // Content area with proper scrolling
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Collapsible panels with better space management
                  if (_showControls || _showSimulation || _showAlgorithms) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildPanelsColumn(),
                    ),
                  ],

                  // Info panel (always visible)
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Context-Free Grammar Editor',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create production rules, test strings, and analyze grammars. Use the panels above to edit, simulate, and apply algorithms.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel - Grammar Editor
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const GrammarEditor(),
          ),
        ),
        const SizedBox(width: 16),
        // Center panel - Simulation
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const GrammarSimulationPanel(),
          ),
        ),
        const SizedBox(width: 16),
        // Right panel - Algorithms
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const GrammarAlgorithmPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isActive 
            ? Theme.of(context).colorScheme.onPrimary 
            : Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        minimumSize: Size.zero,
      ),
    );
  }

  Widget _buildPanelsColumn() {
    return Column(
      children: [
        // Grammar editor
        if (_showControls) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: const GrammarEditor(),
          ),
          const SizedBox(height: 8),
        ],

        // Simulation panel
        if (_showSimulation) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            child: const GrammarSimulationPanel(),
          ),
          const SizedBox(height: 8),
        ],

        // Algorithm panel
        if (_showAlgorithms) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            child: const GrammarAlgorithmPanel(),
          ),
        ],
      ],
    );
  }
}
