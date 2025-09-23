import 'package:flutter/material.dart';

class SettingsActionsCard extends StatelessWidget {
  const SettingsActionsCard({
    super.key,
    required this.onSave,
    required this.onReset,
  });

  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
                key: const ValueKey('settings_save_button'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
                key: const ValueKey('settings_reset_button'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
