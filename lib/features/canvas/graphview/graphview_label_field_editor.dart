/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/features/canvas/graphview/graphview_label_field_editor.dart
/// Descrição: Fornece o overlay de edição de rótulos de transição no GraphView,
///            mediando entrada do usuário e confirmação/cancelamento no canvas.
/// ---------------------------------------------------------------------------
import 'package:flutter/material.dart';

import '../../../presentation/widgets/transition_editors/transition_label_editor.dart';

/// Overlay editor used by the GraphView canvas to update transition labels.
class GraphViewLabelFieldEditor extends StatefulWidget {
  const GraphViewLabelFieldEditor({
    super.key,
    required this.initialValue,
    required this.onSubmit,
    required this.onCancel,
  });

  final String initialValue;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  @override
  State<GraphViewLabelFieldEditor> createState() =>
      _GraphViewLabelFieldEditorState();
}

class _GraphViewLabelFieldEditorState extends State<GraphViewLabelFieldEditor> {
  late final FocusScopeNode _focusScopeNode;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusScopeNode = FocusScopeNode();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusScopeNode.requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusScopeNode.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool focused) {
    if (!focused) {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _focusScopeNode,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: _handleFocusChange,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TransitionLabelEditorForm(
                initialValue: widget.initialValue,
                onSubmit: (value) {
                  widget.onSubmit(value);
                  _focusScopeNode.unfocus();
                },
                onCancel: () {
                  widget.onCancel();
                  _focusScopeNode.unfocus();
                },
                autofocus: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
