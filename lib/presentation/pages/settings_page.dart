import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings page for user preferences and configuration
/// Based on JFLAP's Profile.java settings management
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late SharedPreferences _prefs;
  bool _isLoading = true;

  // Settings values
  String _emptyStringSymbol = 'λ';
  String _epsilonSymbol = 'ε';
  String _themeMode = 'system';
  bool _enableTransitionsFromFinalState = false;
  bool _turingAcceptByFinalState = true;
  bool _turingAcceptByHalting = false;
  bool _turingAllowStay = false;
  int _undoAmount = 50;
  bool _enableAnimations = true;
  bool _enableSoundEffects = false;
  double _canvasZoom = 1.0;
  bool _showGrid = true;
  bool _snapToGrid = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _emptyStringSymbol = _prefs.getString('empty_string_symbol') ?? 'λ';
      _epsilonSymbol = _prefs.getString('epsilon_symbol') ?? 'ε';
      _themeMode = _prefs.getString('theme_mode') ?? 'system';
      _enableTransitionsFromFinalState = _prefs.getBool('enable_transitions_from_final_state') ?? false;
      _turingAcceptByFinalState = _prefs.getBool('turing_accept_by_final_state') ?? true;
      _turingAcceptByHalting = _prefs.getBool('turing_accept_by_halting') ?? false;
      _turingAllowStay = _prefs.getBool('turing_allow_stay') ?? false;
      _undoAmount = _prefs.getInt('undo_amount') ?? 50;
      _enableAnimations = _prefs.getBool('enable_animations') ?? true;
      _enableSoundEffects = _prefs.getBool('enable_sound_effects') ?? false;
      _canvasZoom = _prefs.getDouble('canvas_zoom') ?? 1.0;
      _showGrid = _prefs.getBool('show_grid') ?? true;
      _snapToGrid = _prefs.getBool('snap_to_grid') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setString('empty_string_symbol', _emptyStringSymbol);
    await _prefs.setString('epsilon_symbol', _epsilonSymbol);
    await _prefs.setString('theme_mode', _themeMode);
    await _prefs.setBool('enable_transitions_from_final_state', _enableTransitionsFromFinalState);
    await _prefs.setBool('turing_accept_by_final_state', _turingAcceptByFinalState);
    await _prefs.setBool('turing_accept_by_halting', _turingAcceptByHalting);
    await _prefs.setBool('turing_allow_stay', _turingAllowStay);
    await _prefs.setInt('undo_amount', _undoAmount);
    await _prefs.setBool('enable_animations', _enableAnimations);
    await _prefs.setBool('enable_sound_effects', _enableSoundEffects);
    await _prefs.setDouble('canvas_zoom', _canvasZoom);
    await _prefs.setBool('show_grid', _showGrid);
    await _prefs.setBool('snap_to_grid', _snapToGrid);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _emptyStringSymbol = 'λ';
      _epsilonSymbol = 'ε';
      _themeMode = 'system';
      _enableTransitionsFromFinalState = false;
      _turingAcceptByFinalState = true;
      _turingAcceptByHalting = false;
      _turingAllowStay = false;
      _undoAmount = 50;
      _enableAnimations = true;
      _enableSoundEffects = false;
      _canvasZoom = 1.0;
      _showGrid = true;
      _snapToGrid = false;
    });
    await _saveSettings();
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Symbols'),
          _buildSymbolSettings(),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Theme'),
          _buildThemeSettings(),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Turing Machine'),
          _buildTuringMachineSettings(),
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSymbolSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Empty String Symbol'),
              subtitle: const Text('Symbol used to represent empty string (λ or ε)'),
              trailing: DropdownButton<String>(
                value: _emptyStringSymbol,
                items: const [
                  DropdownMenuItem(value: 'λ', child: Text('λ (Lambda)')),
                  DropdownMenuItem(value: 'ε', child: Text('ε (Epsilon)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _emptyStringSymbol = value;
                    });
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Epsilon Symbol'),
              subtitle: const Text('Symbol used to represent epsilon transitions'),
              trailing: DropdownButton<String>(
                value: _epsilonSymbol,
                items: const [
                  DropdownMenuItem(value: 'ε', child: Text('ε (Epsilon)')),
                  DropdownMenuItem(value: 'λ', child: Text('λ (Lambda)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _epsilonSymbol = value;
                    });
                  }
                },
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
          children: [
            ListTile(
              title: const Text('Theme Mode'),
              subtitle: const Text('Choose your preferred theme'),
              trailing: DropdownButton<String>(
                value: _themeMode,
                items: const [
                  DropdownMenuItem(value: 'system', child: Text('System')),
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                  DropdownMenuItem(value: 'dark', child: Text('Dark')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _themeMode = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTuringMachineSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Transitions from Final State'),
              subtitle: const Text('Allow transitions from Turing machine final states'),
              value: _enableTransitionsFromFinalState,
              onChanged: (value) {
                setState(() {
                  _enableTransitionsFromFinalState = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Accept by Final State'),
              subtitle: const Text('Turing machines accept by reaching final state'),
              value: _turingAcceptByFinalState,
              onChanged: (value) {
                setState(() {
                  _turingAcceptByFinalState = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Accept by Halting'),
              subtitle: const Text('Turing machines accept by halting'),
              value: _turingAcceptByHalting,
              onChanged: (value) {
                setState(() {
                  _turingAcceptByHalting = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Allow Stay Transitions'),
              subtitle: const Text('Allow tape head to stay in place on transitions'),
              value: _turingAllowStay,
              onChanged: (value) {
                setState(() {
                  _turingAllowStay = value;
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
          children: [
            ListTile(
              title: const Text('Default Zoom Level'),
              subtitle: Text('${(_canvasZoom * 100).round()}%'),
              trailing: Slider(
                value: _canvasZoom,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) {
                  setState(() {
                    _canvasZoom = value;
                  });
                },
              ),
            ),
            SwitchListTile(
              title: const Text('Show Grid'),
              subtitle: const Text('Display grid on canvas'),
              value: _showGrid,
              onChanged: (value) {
                setState(() {
                  _showGrid = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Snap to Grid'),
              subtitle: const Text('Snap elements to grid positions'),
              value: _snapToGrid,
              onChanged: (value) {
                setState(() {
                  _snapToGrid = value;
                });
              },
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
          children: [
            ListTile(
              title: const Text('Undo Amount'),
              subtitle: Text('$_undoAmount operations'),
              trailing: Slider(
                value: _undoAmount.toDouble(),
                min: 10,
                max: 100,
                divisions: 9,
                onChanged: (value) {
                  setState(() {
                    _undoAmount = value.round();
                  });
                },
              ),
            ),
            SwitchListTile(
              title: const Text('Enable Animations'),
              subtitle: const Text('Show animations during simulations'),
              value: _enableAnimations,
              onChanged: (value) {
                setState(() {
                  _enableAnimations = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Sound Effects'),
              subtitle: const Text('Play sounds for interactions'),
              value: _enableSoundEffects,
              onChanged: (value) {
                setState(() {
                  _enableSoundEffects = value;
                });
              },
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
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export Settings'),
              subtitle: const Text('Save settings to file'),
              onTap: _exportSettings,
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Import Settings'),
              subtitle: const Text('Load settings from file'),
              onTap: _importSettings,
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About JFlutter'),
              subtitle: const Text('Version information and credits'),
              onTap: _showAboutDialog,
            ),
          ],
        ),
      ),
    );
  }

  void _exportSettings() {
    // TODO: Implement settings export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export settings - Coming soon!')),
    );
  }

  void _importSettings() {
    // TODO: Implement settings import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import settings - Coming soon!')),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'JFlutter',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_tree, size: 48),
      children: [
        const Text(
          'JFlutter is a mobile application for learning formal language theory, '
          'inspired by JFLAP (Java Formal Languages and Automata Package).\n\n'
          'Features:\n'
          '• Finite State Automata (FSA)\n'
          '• Pushdown Automata (PDA)\n'
          '• Turing Machines (TM)\n'
          '• Context-Free Grammars\n'
          '• Regular Expressions\n'
          '• Pumping Lemma Game\n\n'
          'Built with Flutter for mobile learning.',
        ),
      ],
    );
  }
}
