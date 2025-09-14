import 'package:flutter/material.dart';
import '../../core/automaton.dart';

class DeltaTableViewer extends StatefulWidget {
  const DeltaTableViewer({
    super.key,
    required this.automaton,
    this.onTransitionChanged,
  });

  final Automaton automaton;
  final void Function(String from, String symbol, String? to)? onTransitionChanged;

  @override
  State<DeltaTableViewer> createState() => _DeltaTableViewerState();
}

class _DeltaTableViewerState extends State<DeltaTableViewer> {
  late Automaton _automaton;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _automaton = widget.automaton;
    _initializeControllers();
  }

  @override
  void didUpdateWidget(DeltaTableViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.automaton != widget.automaton) {
      _automaton = widget.automaton;
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    // Clear existing controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    // Create controllers for each transition
    for (final state in _automaton.states) {
      for (final symbol in _automaton.alphabet) {
        final key = '${state.id}|$symbol';
        final controller = TextEditingController();
        final transitions = _automaton.transitions[key];
        if (transitions != null && transitions.isNotEmpty) {
          controller.text = transitions.first;
        }
        _controllers[key] = controller;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTransitionChanged(String from, String symbol, String? to) {
    if (widget.onTransitionChanged != null) {
      widget.onTransitionChanged!(from, symbol, to);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_automaton.states.isEmpty || _automaton.alphabet.isEmpty) {
      return const Center(
        child: Text('Defina estados e alfabeto para ver a tabela δ'),
      );
    }

    final states = _automaton.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final alphabet = _automaton.alphabet.toList()
      ..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          columns: [
            const DataColumn(
              label: Text('δ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final symbol in alphabet)
              DataColumn(
                label: Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
          rows: states.map((state) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.name,
                        style: TextStyle(
                          fontWeight: state.isInitial ? FontWeight.bold : FontWeight.normal,
                          color: state.isFinal 
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      if (state.isInitial) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.play_arrow,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                      if (state.isFinal) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
                for (final symbol in alphabet)
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _controllers['${state.id}|$symbol'],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        style: const TextStyle(fontSize: 12),
                        onChanged: (value) {
                          _onTransitionChanged(state.id, symbol, value.isEmpty ? null : value);
                        },
                      ),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class DeltaTableCard extends StatelessWidget {
  const DeltaTableCard({
    super.key,
    required this.automaton,
    this.onTransitionChanged,
  });

  final Automaton automaton;
  final void Function(String from, String symbol, String? to)? onTransitionChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Tabela δ (AFD)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // Refresh the table
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar tabela',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Edite as células para definir δ(q, a) = p',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DeltaTableViewer(
                automaton: automaton,
                onTransitionChanged: onTransitionChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
