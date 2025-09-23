import 'package:flutter/material.dart';

class SettingsCanvasCard extends StatelessWidget {
  const SettingsCanvasCard({
    super.key,
    required this.showGrid,
    required this.showCoordinates,
    required this.gridSize,
    required this.nodeSize,
    required this.fontSize,
    required this.onShowGridChanged,
    required this.onShowCoordinatesChanged,
    required this.onGridSizeChanged,
    required this.onNodeSizeChanged,
    required this.onFontSizeChanged,
  });

  final bool showGrid;
  final bool showCoordinates;
  final double gridSize;
  final double nodeSize;
  final double fontSize;
  final ValueChanged<bool> onShowGridChanged;
  final ValueChanged<bool> onShowCoordinatesChanged;
  final ValueChanged<double> onGridSizeChanged;
  final ValueChanged<double> onNodeSizeChanged;
  final ValueChanged<double> onFontSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SwitchSetting(
              title: 'Show Grid',
              subtitle: 'Display grid lines on canvas',
              value: showGrid,
              onChanged: onShowGridChanged,
              switchKey: const ValueKey('settings_show_grid_switch'),
            ),
            const SizedBox(height: 16),
            _SwitchSetting(
              title: 'Show Coordinates',
              subtitle: 'Display coordinate information',
              value: showCoordinates,
              onChanged: onShowCoordinatesChanged,
              switchKey: const ValueKey('settings_show_coordinates_switch'),
            ),
            const SizedBox(height: 16),
            _SliderSetting(
              title: 'Grid Size',
              subtitle: 'Size of grid cells',
              value: gridSize,
              min: 10.0,
              max: 50.0,
              onChanged: onGridSizeChanged,
              sliderKey: const ValueKey('settings_grid_size_slider'),
            ),
            const SizedBox(height: 16),
            _SliderSetting(
              title: 'Node Size',
              subtitle: 'Size of automaton nodes',
              value: nodeSize,
              min: 20.0,
              max: 60.0,
              onChanged: onNodeSizeChanged,
              sliderKey: const ValueKey('settings_node_size_slider'),
            ),
            const SizedBox(height: 16),
            _SliderSetting(
              title: 'Font Size',
              subtitle: 'Text size in the interface',
              value: fontSize,
              min: 12.0,
              max: 20.0,
              onChanged: onFontSizeChanged,
              sliderKey: const ValueKey('settings_font_size_slider'),
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

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.sliderKey,
  });

  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Key? sliderKey;

  @override
  Widget build(BuildContext context) {
    final divisions = ((max - min) / 5).round();

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
        Row(
          children: [
            Expanded(
              child: Slider(
                key: sliderKey,
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: value.round().toString(),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              value.round().toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
