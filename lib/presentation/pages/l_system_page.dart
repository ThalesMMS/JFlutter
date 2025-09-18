import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/l_system_editor.dart';
import '../widgets/l_system_visualizer.dart';
import '../widgets/l_system_controls.dart';

/// Page for working with L-Systems
class LSystemPage extends ConsumerStatefulWidget {
  const LSystemPage({super.key});

  @override
  ConsumerState<LSystemPage> createState() => _LSystemPageState();
}

class _LSystemPageState extends ConsumerState<LSystemPage> {
  bool _showEditor = true;
  bool _showVisualizer = false;
  bool _showControls = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 1024;

    return Scaffold(
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Mobile controls toggle
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showEditor = !_showEditor),
                        icon: Icon(_showEditor ? Icons.visibility_off : Icons.visibility),
                        label: Text(_showEditor ? 'Hide Editor' : 'Show Editor'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showVisualizer = !_showVisualizer),
                        icon: Icon(_showVisualizer ? Icons.visibility_off : Icons.auto_awesome),
                        label: Text(_showVisualizer ? 'Hide Visual' : 'Show Visual'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showControls = !_showControls),
                    icon: Icon(_showControls ? Icons.visibility_off : Icons.settings),
                    label: Text(_showControls ? 'Hide Controls' : 'Show Controls'),
                  ),
                ),
              ],
            ),
          ),
          
          // L-System editor (collapsible on mobile)
          if (_showEditor) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
              child: const LSystemEditor(),
            ),
            const SizedBox(height: 8),
          ],
          
          // Visualizer (collapsible on mobile)
          if (_showVisualizer) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
              child: const LSystemVisualizer(),
            ),
            const SizedBox(height: 8),
          ],
          
          // Controls panel (collapsible on mobile)
          if (_showControls) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
              child: const LSystemControls(),
            ),
            const SizedBox(height: 8),
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
                  'Lindenmayer Systems',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create fractal patterns and natural forms using L-systems. Define rules, set parameters, and visualize beautiful mathematical structures.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel - L-System Editor
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const LSystemEditor(),
          ),
        ),
        const SizedBox(width: 16),
        // Center panel - Visualizer
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const LSystemVisualizer(),
          ),
        ),
        const SizedBox(width: 16),
        // Right panel - Controls
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const LSystemControls(),
          ),
        ),
      ],
    );
  }
}
