/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/widgets/transition_editors/transition_label_editor.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Componente reutilizável para editar rótulos de transições com suporte a teclado, acessibilidade e otimizações para toque. Encapsula lógica de submissão, cancelamento e feedback sem exigir dependências externas.
/// Contexto: Utilizado por diferentes editores de autômatos para permitir ajustes rápidos em transições diretamente no canvas. Integra atalhos de teclado padrão e semântica configurável para melhorar a experiência do usuário.
/// Observações: Ajusta layout para contextos desktop e mobile oferecendo botões dimensionados conforme necessidade. Pode ser estendido com validações adicionais ou máscaras mantendo a mesma estrutura de formulário.
/// ---------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransitionLabelEditorForm extends StatefulWidget {
  const TransitionLabelEditorForm({
    super.key,
    required this.initialValue,
    required this.onSubmit,
    required this.onCancel,
    this.autofocus = false,
    this.touchOptimized = false,
    this.fieldLabel = 'Rótulo',
    this.cancelLabel = 'Cancelar',
    this.saveLabel = 'Salvar',
    this.semanticLabel = 'Editar rótulo da transição',
  });

  final String initialValue;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final bool autofocus;
  final bool touchOptimized;
  final String fieldLabel;
  final String cancelLabel;
  final String saveLabel;
  final String semanticLabel;

  @override
  State<TransitionLabelEditorForm> createState() =>
      _TransitionLabelEditorFormState();
}

class _TransitionLabelEditorFormState
    extends State<TransitionLabelEditorForm> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    widget.onSubmit(_controller.text.trim());
  }

  void _handleCancel() {
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.enter): const _SubmitIntent(),
      LogicalKeySet(LogicalKeyboardKey.numpadEnter): const _SubmitIntent(),
      LogicalKeySet(LogicalKeyboardKey.escape): const _CancelIntent(),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          _SubmitIntent: CallbackAction<_SubmitIntent>(onInvoke: (intent) {
            _handleSubmit();
            return null;
          }),
          _CancelIntent: CallbackAction<_CancelIntent>(onInvoke: (intent) {
            _handleCancel();
            return null;
          }),
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (intent) {
            _handleCancel();
            return null;
          }),
        },
        child: FocusTraversalGroup(
          child: Semantics(
            container: true,
            label: widget.semanticLabel,
            explicitChildNodes: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  autofocus: widget.autofocus,
                  decoration: InputDecoration(
                    labelText: widget.fieldLabel,
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSubmit(),
                ),
                SizedBox(height: widget.touchOptimized ? 16 : 8),
                if (widget.touchOptimized)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleCancel,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(widget.cancelLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _handleSubmit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(widget.saveLabel),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _handleCancel,
                        child: Text(widget.cancelLabel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _handleSubmit,
                        child: Text(widget.saveLabel),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
