import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays the context actions available for canvas interactions.
Future<void> showCanvasContextActions({
  required BuildContext context,
  required bool canAddState,
  required VoidCallback onAddState,
  required VoidCallback onFitToContent,
  required VoidCallback onResetView,
}) async {
  HapticFeedback.mediumImpact();

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ListTile(
              title: Text(
                'Canvas actions',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              subtitle: const Text('Choose what to do at this location'),
            ),
            const Divider(height: 0),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: colorScheme.primary),
              title: const Text('Add state'),
              subtitle:
                  canAddState ? null : const Text('There is already an item here'),
              enabled: canAddState,
              onTap: () {
                Navigator.of(sheetContext).pop();
                HapticFeedback.selectionClick();
                onAddState();
              },
            ),
            ListTile(
              leading: const Icon(Icons.fit_screen),
              title: const Text('Fit to content'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                HapticFeedback.selectionClick();
                onFitToContent();
              },
            ),
            ListTile(
              leading: const Icon(Icons.center_focus_strong),
              title: const Text('Reset view'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                HapticFeedback.selectionClick();
                onResetView();
              },
            ),
          ],
        ),
      );
    },
  );
}
