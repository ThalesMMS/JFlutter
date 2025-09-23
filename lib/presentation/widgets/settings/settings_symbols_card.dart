import 'package:flutter/material.dart';

class SettingsSymbolsCard extends StatelessWidget {
  const SettingsSymbolsCard({
    super.key,
    required this.emptyStringSymbol,
    required this.epsilonSymbol,
    required this.onEmptyStringSymbolChanged,
    required this.onEpsilonSymbolChanged,
  });

  final String emptyStringSymbol;
  final String epsilonSymbol;
  final ValueChanged<String> onEmptyStringSymbolChanged;
  final ValueChanged<String> onEpsilonSymbolChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChoiceGroup(
              title: 'Empty String Symbol',
              subtitle: 'Symbol used to represent empty string (λ or ε)',
              currentValue: emptyStringSymbol,
              choices: const [
                _SettingsChoice(
                  label: 'λ (Lambda)',
                  value: 'λ',
                  key: ValueKey('settings_empty_string_lambda'),
                ),
                _SettingsChoice(
                  label: 'ε (Epsilon)',
                  value: 'ε',
                  key: ValueKey('settings_empty_string_epsilon'),
                ),
              ],
              onChanged: onEmptyStringSymbolChanged,
            ),
            const SizedBox(height: 16),
            _ChoiceGroup(
              title: 'Epsilon Symbol',
              subtitle: 'Symbol used to represent epsilon transitions',
              currentValue: epsilonSymbol,
              choices: const [
                _SettingsChoice(
                  label: 'ε (Epsilon)',
                  value: 'ε',
                  key: ValueKey('settings_epsilon_epsilon'),
                ),
                _SettingsChoice(
                  label: 'λ (Lambda)',
                  value: 'λ',
                  key: ValueKey('settings_epsilon_lambda'),
                ),
              ],
              onChanged: onEpsilonSymbolChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.subtitle,
    required this.currentValue,
    required this.choices,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String currentValue;
  final List<_SettingsChoice> choices;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: choices.map((choice) {
            return FilterChip(
              key: choice.key,
              label: Text(choice.label),
              selected: choice.value == currentValue,
              onSelected: (selected) {
                if (selected) {
                  onChanged(choice.value);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SettingsChoice {
  const _SettingsChoice({
    required this.label,
    required this.value,
    this.key,
  });

  final String label;
  final String value;
  final Key? key;
}
