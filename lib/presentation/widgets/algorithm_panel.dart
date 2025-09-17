import 'package:flutter/material.dart';

/// Panel for algorithm operations and controls
class AlgorithmPanel extends StatefulWidget {
  final VoidCallback? onNfaToDfa;
  final VoidCallback? onMinimizeDfa;
  final VoidCallback? onClear;
  final Function(String)? onRegexToNfa;
  final VoidCallback? onFaToRegex;

  const AlgorithmPanel({
    super.key,
    this.onNfaToDfa,
    this.onMinimizeDfa,
    this.onClear,
    this.onRegexToNfa,
    this.onFaToRegex,
  });

  @override
  State<AlgorithmPanel> createState() => _AlgorithmPanelState();
}

class _AlgorithmPanelState extends State<AlgorithmPanel> {
  final TextEditingController _regexController = TextEditingController();

  @override
  void dispose() {
    _regexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Algorithms',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Regex to NFA conversion
            _buildRegexInput(context),
            
            const SizedBox(height: 12),
            
            // NFA to DFA conversion
            _buildAlgorithmButton(
              context,
              title: 'NFA to DFA',
              description: 'Convert non-deterministic to deterministic automaton',
              icon: Icons.transform,
              onPressed: widget.onNfaToDfa,
            ),
            
            const SizedBox(height: 12),
            
            // DFA minimization
            _buildAlgorithmButton(
              context,
              title: 'Minimize DFA',
              description: 'Minimize deterministic finite automaton',
              icon: Icons.compress,
              onPressed: widget.onMinimizeDfa,
            ),
            
            const SizedBox(height: 12),
            
            // FA to Regex conversion
            _buildAlgorithmButton(
              context,
              title: 'FA to Regex',
              description: 'Convert finite automaton to regular expression',
              icon: Icons.text_fields,
              onPressed: widget.onFaToRegex,
            ),
            
            const SizedBox(height: 12),
            
            // Clear automaton
            _buildAlgorithmButton(
              context,
              title: 'Clear',
              description: 'Clear current automaton',
              icon: Icons.clear,
              onPressed: widget.onClear,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegexInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regex to NFA',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _regexController,
                decoration: const InputDecoration(
                  labelText: 'Regular Expression',
                  hintText: 'e.g., (a|b)*',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty && widget.onRegexToNfa != null) {
                    widget.onRegexToNfa!(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_regexController.text.isNotEmpty && widget.onRegexToNfa != null) {
                  widget.onRegexToNfa!(_regexController.text);
                }
              },
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlgorithmButton(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    VoidCallback? onPressed,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
