import 'package:flutter/material.dart';

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
            _SwitchSetting(
              title: 'Auto Save',
              subtitle: 'Automatically save changes',
              value: autoSave,
              onChanged: onAutoSaveChanged,
              switchKey: const ValueKey('settings_auto_save_switch'),
            ),
            const SizedBox(height: 16),
            _SwitchSetting(
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

class _SwitchSetting extends StatelessWidget {
  const _SwitchSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.switchKey,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Switch(
          key: switchKey,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
