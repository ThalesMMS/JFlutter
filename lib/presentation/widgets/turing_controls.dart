import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/turing.dart';
import '../../core/turing_algorithms.dart';

/// Turing Machine Controls widget optimized for mobile devices
/// Provides tools for editing and simulating Turing Machines
class TuringControls extends StatefulWidget {
  const TuringControls({
    super.key,
    required this.tm,
    required this.onTMChanged,
    this.onSimulationRequested,
  });

  final TuringMachine tm;
  final ValueChanged<TuringMachine> onTMChanged;
  final ValueChanged<String>? onSimulationRequested;

  @override
  State<TuringControls> createState() => _TuringControlsState();
}

class _TuringControlsState extends State<TuringControls> {
  final TextEditingController _alphabetController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  AcceptanceMode _acceptanceMode = AcceptanceMode.finalState;
  int _numTapes = 1;

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  @override
  void didUpdateWidget(TuringControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tm != oldWidget.tm) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    _alphabetController.text = widget.tm.alphabet.join(', ');
    _acceptanceMode = widget.tm.acceptanceMode;
    _numTapes = widget.tm.numTapes;
  }

  @override
  void dispose() {
    _alphabetController.dispose();
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
          _buildTapeSection(),
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
                Icon(Icons.smart_toy, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Turing Machine',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'States: ${widget.tm.states.length} | Transitions: ${widget.tm.transitions.length} | Tapes: ${widget.tm.numTapes}',
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
              'Tape Alphabet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alphabetController,
              decoration: const InputDecoration(
                hintText: 'Enter symbols separated by commas (e.g., 0, 1, a, b)',
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

  Widget _buildTapeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Number of Tapes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _numTapes > 1 ? _decreaseTapes : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    '$_numTapes tape(s)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _numTapes < 5 ? _increaseTapes : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Multi-tape Turing machines can perform more complex computations',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                  value: AcceptanceMode.halting,
                  label: Text('Halting'),
                  icon: Icon(Icons.stop),
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
                hintText: 'Enter input string for tape 1',
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
                  onPressed: _validateTM,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Validate'),
                ),
                ElevatedButton.icon(
                  onPressed: _convertToCSG,
                  icon: const Icon(Icons.transform),
                  label: const Text('To CSG'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearTM,
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
    widget.onTMChanged(widget.tm.withAlphabet(symbols));
  }

  void _increaseTapes() {
    setState(() {
      _numTapes++;
    });
    widget.onTMChanged(widget.tm.withNumTapes(_numTapes));
  }

  void _decreaseTapes() {
    if (_numTapes > 1) {
      setState(() {
        _numTapes--;
      });
      widget.onTMChanged(widget.tm.withNumTapes(_numTapes));
    }
  }

  void _updateAcceptanceMode() {
    widget.onTMChanged(widget.tm.setAcceptanceMode(_acceptanceMode));
  }

  void _simulateInput() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('Please enter an input string');
      return;
    }

    widget.onSimulationRequested?.call(input);
  }

  void _validateTM() {
    final result = TuringAlgorithms.validateTM(widget.tm);
    if (result.isSuccess) {
      _showSnackBar('Turing Machine is valid');
    } else {
      _showErrorDialog('Validation Error', result.error!);
    }
  }

  void _convertToCSG() {
    final result = TuringAlgorithms.tmToCSG(widget.tm);
    if (result.isSuccess) {
      _showCSGResult(result.data!);
    } else {
      _showErrorDialog('CSG Conversion Error', result.error!);
    }
  }

  void _clearTM() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Turing Machine'),
        content: const Text('Are you sure you want to clear the Turing Machine? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onTMChanged(TuringMachine.empty());
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

  void _showCSGResult(Map<String, dynamic> csg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Context-Sensitive Grammar'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Variables: ${csg['variables'].join(', ')}'),
                const SizedBox(height: 8),
                Text('Terminals: ${csg['terminals'].join(', ')}'),
                const SizedBox(height: 8),
                const Text('Productions:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...csg['productions'].entries.map<Widget>((entry) => 
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
              final csgText = _formatCSGForClipboard(csg);
              Clipboard.setData(ClipboardData(text: csgText));
              _showSnackBar('CSG copied to clipboard');
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  String _formatCSGForClipboard(Map<String, dynamic> csg) {
    final buffer = StringBuffer();
    buffer.writeln('Variables: ${csg['variables'].join(', ')}');
    buffer.writeln('Terminals: ${csg['terminals'].join(', ')}');
    buffer.writeln('Start Variable: ${csg['startVariable']}');
    buffer.writeln();
    buffer.writeln('Productions:');
    for (final entry in csg['productions'].entries) {
      buffer.writeln('${entry.key} → ${entry.value.join(' | ')}');
    }
    return buffer.toString();
  }
}
