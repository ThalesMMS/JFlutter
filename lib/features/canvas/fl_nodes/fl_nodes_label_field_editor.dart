import 'package:flutter/material.dart';
import 'package:jflutter/presentation/widgets/transition_editors/transition_label_editor.dart';

/// Shared text field overlay used by fl_nodes controllers to edit node labels.
class FlNodesLabelFieldEditor extends StatelessWidget {
  const FlNodesLabelFieldEditor({
    super.key,
    required this.initialValue,
    required this.onSubmit,
    required this.onCancel,
  });

  final String initialValue;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: TransitionLabelEditorForm(
            initialValue: initialValue,
            onSubmit: onSubmit,
            onCancel: onCancel,
            autofocus: true,
          ),
        ),
      ),
    );
  }
}
