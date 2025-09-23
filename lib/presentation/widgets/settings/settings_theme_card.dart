import 'package:flutter/material.dart';

class SettingsThemeCard extends StatelessWidget {
  const SettingsThemeCard({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final String themeMode;
  final ValueChanged<String> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Mode',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose your preferred theme',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: const [
                _ThemeOption(
                  label: 'System',
                  value: 'system',
                  key: ValueKey('settings_theme_system'),
                ),
                _ThemeOption(
                  label: 'Light',
                  value: 'light',
                  key: ValueKey('settings_theme_light'),
                ),
                _ThemeOption(
                  label: 'Dark',
                  value: 'dark',
                  key: ValueKey('settings_theme_dark'),
                ),
              ]
                  .map(
                    (option) => _ThemeFilterChip(
                      option: option,
                      isSelected: option.value == themeMode,
                      onSelected: onThemeModeChanged,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption({
    required this.label,
    required this.value,
    this.key,
  });

  final String label;
  final String value;
  final Key? key;
}

class _ThemeFilterChip extends StatelessWidget {
  const _ThemeFilterChip({
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  final _ThemeOption option;
  final bool isSelected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      key: option.key,
      label: Text(option.label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(option.value);
        }
      },
    );
  }
}
