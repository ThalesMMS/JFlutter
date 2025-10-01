import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jflutter/core/models/settings_model.dart';
import 'package:jflutter/core/repositories/settings_repository.dart';
import 'package:jflutter/data/repositories/settings_repository_impl.dart';
import 'package:jflutter/data/storage/settings_storage.dart';
import 'package:jflutter/presentation/providers/settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  SettingsPage({
    super.key,
    SettingsRepository? repository,
    SettingsStorage? storage,
  }) : repository =
           repository ??
           SharedPreferencesSettingsRepository(
             storage: storage ?? const SharedPreferencesSettingsStorage(),
           );

  final SettingsRepository repository;

  @override
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isLoading = false;
  SettingsModel _settings = const SettingsModel();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await widget.repository.loadSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
      await ref.read(settingsProvider.notifier).refreshFromModel(settings);
    } catch (error, stackTrace) {
      debugPrint('Failed to load settings: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load settings. Please try again.');
    }
  }

  Future<void> _saveSettings() async {
    final currentSettings = _settings;

    try {
      await widget.repository.saveSettings(currentSettings);
      await ref
          .read(settingsProvider.notifier)
          .refreshFromModel(currentSettings);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved!')));
    } catch (error, stackTrace) {
      debugPrint('Failed to save settings: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showError('Failed to save settings. Please try again.');
    }
  }

  Future<void> _resetToDefaults() async {
    const defaults = SettingsModel();

    setState(() {
      _settings = defaults;
    });

    try {
      await widget.repository.saveSettings(defaults);
      await ref.read(settingsProvider.notifier).refreshFromModel(defaults);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings reset to defaults!')),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to reset settings: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showError('Failed to reset settings. Please try again.');
    }
  }

  void _showError(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: theme.colorScheme.onError,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              _settings.emptyStringSymbol,
              const ['λ (Lambda)', 'ε (Epsilon)'],
              (value) {
                setState(() {
                  _settings = _settings.copyWith(
                    emptyStringSymbol: value == 'λ (Lambda)' ? 'λ' : 'ε',
                  );
                });
              },
              chipKeyBuilder: (option) => ValueKey(
                'settings_empty_string_${option.contains('Lambda') ? 'lambda' : 'epsilon'}',
              ),
            ),
            const SizedBox(height: 16),
            _buildSimpleSetting(
              'Epsilon Symbol',
              'Symbol used to represent epsilon transitions',
              _settings.epsilonSymbol,
              const ['ε (Epsilon)', 'λ (Lambda)'],
              (value) {
                setState(() {
                  _settings = _settings.copyWith(
                    epsilonSymbol: value == 'ε (Epsilon)' ? 'ε' : 'λ',
                  );
                });
              },
              chipKeyBuilder: (option) => ValueKey(
                'settings_epsilon_${option.contains('Epsilon') ? 'epsilon' : 'lambda'}',
              ),
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
              _settings.themeMode,
              const ['System', 'Light', 'Dark'],
              (value) {
                setState(() {
                  _settings = _settings.copyWith(
                    themeMode: value.toLowerCase(),
                  );
                });
              },
              chipKeyBuilder: (option) =>
                  ValueKey('settings_theme_${option.toLowerCase()}'),
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
              'Use Draw2D Canvas',
              'Enable the web-based Draw2D renderer (preview)',
              _settings.useDraw2dCanvas,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(useDraw2dCanvas: value);
                });
              },
              switchKey: const ValueKey('settings_use_draw2d_canvas_switch'),
            ),
            const SizedBox(height: 16),
            _buildSwitchSetting(
              'Show Grid',
              'Display grid lines on canvas',
              _settings.showGrid,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(showGrid: value);
                });
              },
              switchKey: const ValueKey('settings_show_grid_switch'),
            ),
            const SizedBox(height: 16),
            _buildSwitchSetting(
              'Show Coordinates',
              'Display coordinate information',
              _settings.showCoordinates,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(showCoordinates: value);
                });
              },
              switchKey: const ValueKey('settings_show_coordinates_switch'),
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'Grid Size',
              'Size of grid cells',
              _settings.gridSize,
              10.0,
              50.0,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(gridSize: value);
                });
              },
              sliderKey: const ValueKey('settings_grid_size_slider'),
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'Node Size',
              'Size of automaton nodes',
              _settings.nodeSize,
              20.0,
              60.0,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(nodeSize: value);
                });
              },
              sliderKey: const ValueKey('settings_node_size_slider'),
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'Font Size',
              'Text size in the interface',
              _settings.fontSize,
              12.0,
              20.0,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(fontSize: value);
                });
              },
              sliderKey: const ValueKey('settings_font_size_slider'),
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
              _settings.autoSave,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(autoSave: value);
                });
              },
              switchKey: const ValueKey('settings_auto_save_switch'),
            ),
            const SizedBox(height: 16),
            _buildSwitchSetting(
              'Show Tooltips',
              'Display helpful tooltips',
              _settings.showTooltips,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(showTooltips: value);
                });
              },
              switchKey: const ValueKey('settings_show_tooltips_switch'),
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
                key: const ValueKey('settings_save_button'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetToDefaults,
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

  Widget _buildSimpleSetting(
    String title,
    String subtitle,
    String currentValue,
    List<String> options,
    Function(String) onChanged, {
    Key Function(String option)? chipKeyBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected =
                option.toLowerCase().contains(currentValue.toLowerCase()) ||
                (currentValue == 'λ' && option.contains('Lambda')) ||
                (currentValue == 'ε' && option.contains('Epsilon')) ||
                (currentValue == 'system' && option == 'System') ||
                (currentValue == 'light' && option == 'Light') ||
                (currentValue == 'dark' && option == 'Dark');

            return FilterChip(
              key: chipKeyBuilder?.call(option),
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
    Function(bool) onChanged, {
    Key? switchKey,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Switch(key: switchKey, value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    Key? sliderKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                key: sliderKey,
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
