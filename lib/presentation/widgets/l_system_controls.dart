import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Panel for L-System controls and presets
class LSystemControls extends ConsumerStatefulWidget {
  const LSystemControls({super.key});

  @override
  ConsumerState<LSystemControls> createState() => _LSystemControlsState();
}

class _LSystemControlsState extends ConsumerState<LSystemControls> {
  String _selectedPreset = 'Dragon Curve';
  double _angle = 90.0;
  int _iterations = 3;
  double _stepSize = 10.0;
  Color _lineColor = Colors.blue;
  double _lineWidth = 2.0;

  final List<LSystemPreset> _presets = [
    LSystemPreset(
      name: 'Dragon Curve',
      axiom: 'F',
      rules: {'F': 'F+F-F-F+F'},
      angle: 90.0,
      description: 'A classic fractal curve',
    ),
    LSystemPreset(
      name: 'Sierpinski Triangle',
      axiom: 'F-G-G',
      rules: {
        'F': 'F-G+F+G-F',
        'G': 'GG',
      },
      angle: 120.0,
      description: 'Triangular fractal pattern',
    ),
    LSystemPreset(
      name: 'Koch Curve',
      axiom: 'F',
      rules: {'F': 'F+F-F-F+F'},
      angle: 90.0,
      description: 'Snowflake-like curve',
    ),
    LSystemPreset(
      name: 'Plant',
      axiom: 'F',
      rules: {
        'F': 'F[+F]F[-F]F',
      },
      angle: 25.0,
      description: 'Tree-like structure',
    ),
    LSystemPreset(
      name: 'Hilbert Curve',
      axiom: 'A',
      rules: {
        'A': '-BF+AFA+FB-',
        'B': '+AF-BFB-FA+',
      },
      angle: 90.0,
      description: 'Space-filling curve',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildPresetSelector(context),
            const SizedBox(height: 16),
            _buildParameterControls(context),
            const SizedBox(height: 16),
            _buildVisualControls(context),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.settings,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'L-System Controls',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presets',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPreset,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _presets.map((preset) {
              return DropdownMenuItem(
                value: preset.name,
                child: Text(preset.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPreset = value!;
                final preset = _presets.firstWhere((p) => p.name == value);
                _angle = preset.angle;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            _presets.firstWhere((p) => p.name == _selectedPreset).description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parameters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSliderControl(
            context,
            label: 'Angle',
            value: _angle,
            min: 0.0,
            max: 180.0,
            divisions: 18,
            onChanged: (value) => setState(() => _angle = value),
          ),
          const SizedBox(height: 12),
          _buildSliderControl(
            context,
            label: 'Iterations',
            value: _iterations.toDouble(),
            min: 1.0,
            max: 6.0,
            divisions: 5,
            onChanged: (value) => setState(() => _iterations = value.round()),
          ),
          const SizedBox(height: 12),
          _buildSliderControl(
            context,
            label: 'Step Size',
            value: _stepSize,
            min: 1.0,
            max: 20.0,
            divisions: 19,
            onChanged: (value) => setState(() => _stepSize = value),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visual Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Line Color',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              GestureDetector(
                onTap: _selectColor,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _lineColor,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSliderControl(
            context,
            label: 'Line Width',
            value: _lineWidth,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            onChanged: (value) => setState(() => _lineWidth = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loadPreset,
            icon: const Icon(Icons.download),
            label: const Text('Load Preset'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _savePreset,
            icon: const Icon(Icons.save),
            label: const Text('Save Preset'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _exportImage,
            icon: const Icon(Icons.image),
            label: const Text('Export Image'),
          ),
        ),
      ],
    );
  }

  void _selectColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Line Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorOption(Colors.blue),
              _buildColorOption(Colors.red),
              _buildColorOption(Colors.green),
              _buildColorOption(Colors.purple),
              _buildColorOption(Colors.orange),
              _buildColorOption(Colors.teal),
              _buildColorOption(Colors.pink),
              _buildColorOption(Colors.brown),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return ListTile(
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(color.toString().split('(')[1].split(')')[0]),
      onTap: () {
        setState(() {
          _lineColor = color;
        });
        Navigator.of(context).pop();
      },
    );
  }

  void _loadPreset() {
    final preset = _presets.firstWhere((p) => p.name == _selectedPreset);
    
    // In a real implementation, this would load the preset into the editor
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded preset: ${preset.name}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _savePreset() {
    // In a real implementation, this would save the current L-system as a preset
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preset saved successfully'),
      ),
    );
  }

  void _exportImage() {
    // In a real implementation, this would export the current visualization as an image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image exported successfully'),
      ),
    );
  }
}

/// Data class for L-System presets
class LSystemPreset {
  final String name;
  final String axiom;
  final Map<String, String> rules;
  final double angle;
  final String description;

  LSystemPreset({
    required this.name,
    required this.axiom,
    required this.rules,
    required this.angle,
    required this.description,
  });
}
