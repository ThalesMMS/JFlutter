/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/widgets/transition_editors/tm_transition_operations_editor.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Permite editar operações de transições de Máquina de Turing, incluindo símbolos de leitura/escrita e direção da cabeça. Apresenta formulário compacto ideal para popovers ou diálogos rápidos.
/// Contexto: Alimenta provedores e canvas ao coletar dados atualizados de transições diretamente do usuário. Utiliza controles Material padrão e valida submissões com retorno estruturado para o chamador.
/// Observações: Mantém estado local mínimo, simplificando extensões como validações customizadas ou rótulos internacionalizados. Pode ser integrado a fluxos de edição inline sem exigir reestruturações na interface principal.
/// ---------------------------------------------------------------------------
import 'package:flutter/material.dart';

import '../../../core/models/tm_transition.dart';

class TmTransitionOperationsEditor extends StatefulWidget {
  const TmTransitionOperationsEditor({
    super.key,
    required this.initialRead,
    required this.initialWrite,
    required this.initialDirection,
    required this.onSubmit,
    required this.onCancel,
  });

  final String initialRead;
  final String initialWrite;
  final TapeDirection initialDirection;
  final void Function({
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection direction,
  }) onSubmit;
  final VoidCallback onCancel;

  @override
  State<TmTransitionOperationsEditor> createState() =>
      _TmTransitionOperationsEditorState();
}

class _TmTransitionOperationsEditorState
    extends State<TmTransitionOperationsEditor> {
  late final TextEditingController _readController =
      TextEditingController(text: widget.initialRead);
  late final TextEditingController _writeController =
      TextEditingController(text: widget.initialWrite);
  late TapeDirection _direction = widget.initialDirection;

  @override
  void dispose() {
    _readController.dispose();
    _writeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    widget.onSubmit(
      readSymbol: _readController.text.trim(),
      writeSymbol: _writeController.text.trim(),
      direction: _direction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 260),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _readController,
                decoration: const InputDecoration(
                  labelText: 'Read symbol',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _writeController,
                decoration: const InputDecoration(
                  labelText: 'Write symbol',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Direction',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TapeDirection>(
                    value: _direction,
                    items: TapeDirection.values
                        .map(
                          (direction) => DropdownMenuItem(
                            value: direction,
                            child: Text(direction.description),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _direction = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _handleSubmit,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
