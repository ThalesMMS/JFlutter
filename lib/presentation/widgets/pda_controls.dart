import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/pda.dart';
import '../../core/pda_algorithms.dart';

/// PDA Controls widget optimized for mobile devices
/// Provides tools for editing and simulating Pushdown Automata
class PDAControls extends StatefulWidget {
  const PDAControls({
    super.key,
    required this.pda,
    required this.onPDAChanged,
    this.onSimulationRequested,
  });

  final PushdownAutomaton pda;
  final ValueChanged<PushdownAutomaton> onPDAChanged;
  final ValueChanged<String>? onSimulationRequested;

  @override
  State<PDAControls> createState() => _PDAControlsState();
}

class _PDAControlsState extends State<PDAControls> {
  final TextEditingController _alphabetController = TextEditingController();
  final TextEditingController _stackAlphabetController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  AcceptanceMode _acceptanceMode = AcceptanceMode.finalState;

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  @override
  void didUpdateWidget(PDAControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pda != oldWidget.pda) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    _alphabetController.text = widget.pda.alphabet.join(', ');
    _stackAlphabetController.text = widget.pda.stackAlphabet.join(', ');
    _acceptanceMode = widget.pda.acceptanceMode;
  }

  @override
  void dispose() {
    _alphabetController.dispose();
    _stackAlphabetController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildAlphabetSection(),
          const SizedBox(height: 16),
          _buildStackAlphabetSection(),
          const SizedBox(height: 16),
          _buildAcceptanceModeSection(),
          const SizedBox(height: 16),
          _buildSimulationSection(),
          const SizedBox(height: 16),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Pushdown Automaton',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'States: ${widget.pda.states.length} | Transitions: ${widget.pda.transitions.length}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlphabetSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input Alphabet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alphabetController,
              decoration: const InputDecoration(
                hintText: 'Enter symbols separated by commas (e.g., a, b, c)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.text_fields),
              ),
              onChanged: _updateAlphabet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackAlphabetSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stack Alphabet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stackAlphabetController,
              decoration: const InputDecoration(
                hintText: 'Enter stack symbols separated by commas (e.g., A, B, Z)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.storage),
              ),
              onChanged: _updateStackAlphabet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptanceModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acceptance Mode',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AcceptanceMode>(
              segments: const [
                ButtonSegment<AcceptanceMode>(
                  value: AcceptanceMode.finalState,
                  label: Text('Final State'),
                  icon: Icon(Icons.flag),
                ),
                ButtonSegment<AcceptanceMode>(
                  value: AcceptanceMode.emptyStack,
                  label: Text('Empty Stack'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
              ],
              selected: {_acceptanceMode},
              onSelectionChanged: (Set<AcceptanceMode> selection) {
                setState(() {
                  _acceptanceMode = selection.first;
                });
                _updateAcceptanceMode();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: 'Enter input string to simulate',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.play_arrow),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _simulateInput,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Simulate'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _validatePDA,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Validate'),
                ),
                ElevatedButton.icon(
                  onPressed: _convertToCFG,
                  icon: const Icon(Icons.transform),
                  label: const Text('To CFG'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearPDA,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateAlphabet(String value) {
    final symbols = value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    widget.onPDAChanged(widget.pda.withAlphabet(symbols));
  }

  void _updateStackAlphabet(String value) {
    final symbols = value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    widget.onPDAChanged(widget.pda.withStackAlphabet(symbols));
  }

  void _updateAcceptanceMode() {
    widget.onPDAChanged(widget.pda.setAcceptanceMode(_acceptanceMode));
  }

  void _simulateInput() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('Please enter an input string');
      return;
    }

    widget.onSimulationRequested?.call(input);
  }

  void _validatePDA() {
    final result = PDAAlgorithms.validatePDA(widget.pda);
    if (result.isSuccess) {
      _showSnackBar('PDA is valid');
    } else {
      _showErrorDialog('Validation Error', result.error!);
    }
  }

  void _convertToCFG() {
    final result = PDAAlgorithms.pdaToCFG(widget.pda);
    if (result.isSuccess) {
      _showCFGResult(result.data!);
    } else {
      _showErrorDialog('CFG Conversion Error', result.error!);
    }
  }

  void _clearPDA() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear PDA'),
        content: const Text('Are you sure you want to clear the PDA? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onPDAChanged(PushdownAutomaton.empty());
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCFGResult(Map<String, dynamic> cfg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Context-Free Grammar'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Variables: ${cfg['variables'].join(', ')}'),
                const SizedBox(height: 8),
                Text('Terminals: ${cfg['terminals'].join(', ')}'),
                const SizedBox(height: 8),
                const Text('Productions:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...cfg['productions'].entries.map<Widget>((entry) => 
                  Text('${entry.key} → ${entry.value.join(' | ')}')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard
              final cfgText = _formatCFGForClipboard(cfg);
              Clipboard.setData(ClipboardData(text: cfgText));
              _showSnackBar('CFG copied to clipboard');
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  String _formatCFGForClipboard(Map<String, dynamic> cfg) {
    final buffer = StringBuffer();
    buffer.writeln('Variables: ${cfg['variables'].join(', ')}');
    buffer.writeln('Terminals: ${cfg['terminals'].join(', ')}');
    buffer.writeln('Start Variable: ${cfg['startVariable']}');
    buffer.writeln();
    buffer.writeln('Productions:');
    for (final entry in cfg['productions'].entries) {
      buffer.writeln('${entry.key} → ${entry.value.join(' | ')}');
    }
    return buffer.toString();
  }
}
