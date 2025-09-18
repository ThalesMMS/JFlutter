import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;
  String _emptyStringSymbol = 'λ';
  String _epsilonSymbol = 'ε';
  String _themeMode = 'system';
  bool _showGrid = true;
  bool _showCoordinates = false;
  bool _autoSave = true;
  bool _showTooltips = true;
  double _gridSize = 20.0;
  double _nodeSize = 30.0;
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading settings
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    // TODO: Implement settings persistence
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved!')),
    );
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _emptyStringSymbol = 'λ';
      _epsilonSymbol = 'ε';
      _themeMode = 'system';
      _showGrid = true;
      _showCoordinates = false;
      _autoSave = true;
      _showTooltips = true;
      _gridSize = 20.0;
      _nodeSize = 30.0;
      _fontSize = 14.0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings reset to defaults!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            tooltip: 'Save Settings',
          ),
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Symbols'),
            _buildSymbolSettings(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Theme'),
            _buildThemeSettings(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Canvas'),
            _buildCanvasSettings(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('General'),
            _buildGeneralSettings(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Actions'),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSymbolSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSimpleSetting(
              'Empty String Symbol',
              'Symbol used to represent empty string (λ or ε)',
              _emptyStringSymbol,
              ['λ (Lambda)', 'ε (Epsilon)'],
              (value) {
                setState(() {
                  _emptyStringSymbol = value == 'λ (Lambda)' ? 'λ' : 'ε';
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSimpleSetting(
              'Epsilon Symbol',
              'Symbol used to represent epsilon transitions',
              _epsilonSymbol,
              ['ε (Epsilon)', 'λ (Lambda)'],
              (value) {
                setState(() {
                  _epsilonSymbol = value == 'ε (Epsilon)' ? 'ε' : 'λ';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSimpleSetting(
              'Theme Mode',
              'Choose your preferred theme',
              _themeMode,
              ['System', 'Light', 'Dark'],
              (value) {
                setState(() {
                  _themeMode = value.toLowerCase();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchSetting(
              'Show Grid',
              'Display grid lines on canvas',
              _showGrid,
              (value) => setState(() => _showGrid = value),
            ),
            const SizedBox(height: 16),
            _buildSwitchSetting(
              'Show Coordinates',
              'Display coordinate information',
              _showCoordinates,
              (value) => setState(() => _showCoordinates = value),
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'Grid Size',
              'Size of grid cells',
              _gridSize,
              10.0,
              50.0,
              (value) => setState(() => _gridSize = value),
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'Node Size',
              'Size of automaton nodes',
              _nodeSize,
              20.0,
              60.0,
              (value) => setState(() => _nodeSize = value),
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'Font Size',
              'Text size in the interface',
              _fontSize,
              12.0,
              20.0,
              (value) => setState(() => _fontSize = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchSetting(
              'Auto Save',
              'Automatically save changes',
              _autoSave,
              (value) => setState(() => _autoSave = value),
            ),
            const SizedBox(height: 16),
            _buildSwitchSetting(
              'Show Tooltips',
              'Display helpful tooltips',
              _showTooltips,
              (value) => setState(() => _showTooltips = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSetting(
    String title,
    String subtitle,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
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
          children: options.map((option) {
            final isSelected = option.toLowerCase().contains(currentValue.toLowerCase()) ||
                             (currentValue == 'λ' && option.contains('Lambda')) ||
                             (currentValue == 'ε' && option.contains('Epsilon')) ||
                             (currentValue == 'system' && option == 'System') ||
                             (currentValue == 'light' && option == 'Light') ||
                             (currentValue == 'dark' && option == 'Dark');
            
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
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
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
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
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) / 5).round(),
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