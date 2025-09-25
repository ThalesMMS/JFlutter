import 'package:flutter/material.dart';

import 'settings_toggle_tile.dart';

class SettingsGeneralCard extends StatelessWidget {
  const SettingsGeneralCard({
    super.key,
    required this.autoSave,
    required this.showTooltips,
    required this.onAutoSaveChanged,
    required this.onShowTooltipsChanged,
  });

  final bool autoSave;
  final bool showTooltips;
  final ValueChanged<bool> onAutoSaveChanged;
  final ValueChanged<bool> onShowTooltipsChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsToggleTile(
              title: 'Auto Save',
              subtitle: 'Automatically save changes',
              value: autoSave,
              onChanged: onAutoSaveChanged,
              switchKey: const ValueKey('settings_auto_save_switch'),
            ),
            const SizedBox(height: 16),
            SettingsToggleTile(
              title: 'Show Tooltips',
              subtitle: 'Display helpful tooltips',
              value: showTooltips,
              onChanged: onShowTooltipsChanged,
              switchKey: const ValueKey('settings_show_tooltips_switch'),
            ),
          ],
        ),
      ),
    );
  }
}
