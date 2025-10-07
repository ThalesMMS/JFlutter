//
//  pda_transition_editor.dart
//  JFlutter
//
//  Disponibiliza editor focado em transições de PDA com campos para leitura, pop e push e toggles para λ. Limpa e valida entradas, disparando callbacks estruturados para que a tela hospedeira aplique alterações com segurança.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';

class PdaTransitionEditor extends StatefulWidget {
  const PdaTransitionEditor({
    super.key,
    required this.initialRead,
    required this.initialPop,
    required this.initialPush,
    required this.isLambdaInput,
    required this.isLambdaPop,
    required this.isLambdaPush,
    required this.onSubmit,
    required this.onCancel,
  });

  final String initialRead;
  final String initialPop;
  final String initialPush;
  final bool isLambdaInput;
  final bool isLambdaPop;
  final bool isLambdaPush;
  final void Function({
    required String readSymbol,
    required String popSymbol,
    required String pushSymbol,
    required bool lambdaInput,
    required bool lambdaPop,
    required bool lambdaPush,
  })
  onSubmit;
  final VoidCallback onCancel;

  @override
  State<PdaTransitionEditor> createState() => _PdaTransitionEditorState();
}

class _PdaTransitionEditorState extends State<PdaTransitionEditor> {
  late final TextEditingController _readController = TextEditingController(
    text: widget.initialRead,
  );
  late final TextEditingController _popController = TextEditingController(
    text: widget.initialPop,
  );
  late final TextEditingController _pushController = TextEditingController(
    text: widget.initialPush,
  );
  late bool _lambdaInput = widget.isLambdaInput;
  late bool _lambdaPop = widget.isLambdaPop;
  late bool _lambdaPush = widget.isLambdaPush;

  @override
  void dispose() {
    _readController.dispose();
    _popController.dispose();
    _pushController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    widget.onSubmit(
      readSymbol: _readController.text.trim(),
      popSymbol: _popController.text.trim(),
      pushSymbol: _pushController.text.trim(),
      lambdaInput: _lambdaInput,
      lambdaPop: _lambdaPop,
      lambdaPush: _lambdaPush,
    );
  }

  Widget _buildLambdaSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: (next) {
        setState(() {
          onChanged(next);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _readController,
                enabled: !_lambdaInput,
                decoration: const InputDecoration(
                  labelText: 'Input symbol',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (_) => _handleSubmit(),
              ),
              _buildLambdaSwitch(
                label: 'λ-input',
                value: _lambdaInput,
                onChanged: (value) {
                  _lambdaInput = value;
                  if (value) {
                    _readController.text = '';
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _popController,
                enabled: !_lambdaPop,
                decoration: const InputDecoration(
                  labelText: 'Pop symbol',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
              _buildLambdaSwitch(
                label: 'λ-pop',
                value: _lambdaPop,
                onChanged: (value) {
                  _lambdaPop = value;
                  if (value) {
                    _popController.text = '';
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pushController,
                enabled: !_lambdaPush,
                decoration: const InputDecoration(
                  labelText: 'Push symbol',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
              _buildLambdaSwitch(
                label: 'λ-push',
                value: _lambdaPush,
                onChanged: (value) {
                  _lambdaPush = value;
                  if (value) {
                    _pushController.text = '';
                  }
                },
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
