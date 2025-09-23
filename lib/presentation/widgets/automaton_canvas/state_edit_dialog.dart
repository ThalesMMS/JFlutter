import 'package:flutter/material.dart';

import '../../../core/models/state.dart' as automaton_state;

/// Dialog used to edit a state's label and flags, falling back to the
/// identifier when the name field is left empty before saving.
class StateEditDialog extends StatefulWidget {
  final automaton_state.State state;
  final ValueChanged<automaton_state.State> onStateUpdated;

  const StateEditDialog({
    super.key,
    required this.state,
    required this.onStateUpdated,
  });

  @override
  State<StateEditDialog> createState() => _StateEditDialogState();
}

class _StateEditDialogState extends State<StateEditDialog> {
  late TextEditingController _nameController;
  late bool _isInitial;
  late bool _isAccepting;

  @override
  void initState() {
    super.initState();
    // Seed the form fields with the current state data so later updates
    // propagate the latest values to the onStateUpdated callback.
    _nameController = TextEditingController(text: widget.state.label);
    _isInitial = widget.state.isInitial;
    _isAccepting = widget.state.isAccepting;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit State'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'State name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Update the "initial" flag that will be forwarded when the
            // callback receives the updated state.
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Initial state'),
              value: _isInitial,
              onChanged: (value) =>
                  setState(() => _isInitial = value ?? false),
            ),
            // Update the "accepting" flag so onStateUpdated receives the
            // latest selection when the dialog is saved.
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Accepting state'),
              value: _isAccepting,
              onChanged: (value) =>
                  setState(() => _isAccepting = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveState,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveState() {
    // Build a new state, using the ID as a fallback label, and forward it to
    // onStateUpdated so the parent widget receives the form values.
    final updated = widget.state.copyWith(
      label: _nameController.text.trim().isEmpty
          ? widget.state.id
          : _nameController.text.trim(),
      isInitial: _isInitial,
      isAccepting: _isAccepting,
    );

    widget.onStateUpdated(updated);
    Navigator.of(context).pop();
  }
}
