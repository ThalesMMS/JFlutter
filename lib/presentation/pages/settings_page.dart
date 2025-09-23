import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/settings_model.dart';
import '../providers/settings_providers.dart';
import '../providers/settings_view_model.dart';
import '../widgets/settings/settings_actions_card.dart';
import '../widgets/settings/settings_canvas_card.dart';
import '../widgets/settings/settings_general_card.dart';
import '../widgets/settings/settings_symbols_card.dart';
import '../widgets/settings/settings_theme_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String _saveSuccessMessage = 'Settings saved!';
  static const String _resetSuccessMessage = 'Settings reset to defaults!';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<SettingsModel>>(settingsViewModelProvider,
        (previous, next) {
      final hasNewError = next.hasError && previous?.hasError != true;
      if (hasNewError && context.mounted) {
        _showError(context, SettingsViewModel.loadErrorMessage);
      }
    });

    final settingsState = ref.watch(settingsViewModelProvider);
    final viewModel = ref.read(settingsViewModelProvider.notifier);

    return settingsState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _SettingsErrorView(
        onRetry: () async {
          final message = await viewModel.load();
          if (!context.mounted) return;
          if (message != null) {
            _showError(context, message);
          }
        },
      ),
      data: (settings) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            IconButton(
              onPressed: () => _handleSave(context, viewModel),
              icon: const Icon(Icons.save),
              tooltip: 'Save Settings',
            ),
            IconButton(
              onPressed: () => _handleReset(context, viewModel),
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
              const _SectionHeader(title: 'Symbols'),
              SettingsSymbolsCard(
                emptyStringSymbol: settings.emptyStringSymbol,
                epsilonSymbol: settings.epsilonSymbol,
                onEmptyStringSymbolChanged:
                    viewModel.updateEmptyStringSymbol,
                onEpsilonSymbolChanged: viewModel.updateEpsilonSymbol,
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'Theme'),
              SettingsThemeCard(
                themeMode: settings.themeMode,
                onThemeModeChanged: viewModel.updateThemeMode,
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'Canvas'),
              SettingsCanvasCard(
                showGrid: settings.showGrid,
                showCoordinates: settings.showCoordinates,
                gridSize: settings.gridSize,
                nodeSize: settings.nodeSize,
                fontSize: settings.fontSize,
                onShowGridChanged: viewModel.updateShowGrid,
                onShowCoordinatesChanged: viewModel.updateShowCoordinates,
                onGridSizeChanged: viewModel.updateGridSize,
                onNodeSizeChanged: viewModel.updateNodeSize,
                onFontSizeChanged: viewModel.updateFontSize,
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'General'),
              SettingsGeneralCard(
                autoSave: settings.autoSave,
                showTooltips: settings.showTooltips,
                onAutoSaveChanged: viewModel.updateAutoSave,
                onShowTooltipsChanged: viewModel.updateShowTooltips,
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'Actions'),
              SettingsActionsCard(
                onSave: () => _handleSave(context, viewModel),
                onReset: () => _handleReset(context, viewModel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _handleSave(
    BuildContext context,
    SettingsViewModel viewModel,
  ) async {
    final message = await viewModel.save();
    if (!context.mounted) return;

    if (message == null) {
      _showMessage(context, _saveSuccessMessage);
    } else {
      _showError(context, message);
    }
  }

  static Future<void> _handleReset(
    BuildContext context,
    SettingsViewModel viewModel,
  ) async {
    final message = await viewModel.reset();
    if (!context.mounted) return;

    if (message == null) {
      _showMessage(context, _resetSuccessMessage);
    } else {
      _showError(context, message);
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void _showError(BuildContext context, String message) {
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
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
}

class _SettingsErrorView extends StatelessWidget {
  const _SettingsErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                SettingsViewModel.loadErrorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
