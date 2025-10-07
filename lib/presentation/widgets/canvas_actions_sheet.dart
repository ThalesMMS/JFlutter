/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/widgets/canvas_actions_sheet.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Exibe folha de ações contextuais para o canvas permitindo criar estados e ajustar enquadramento rapidamente. Aplica feedback háptico e navegação consistente ao interagir com as opções.
/// Contexto: Foi projetado para ser chamado por gestos no canvas, oferecendo atalhos para adicionar nós, ajustar zoom ao conteúdo e resetar a visão. Utiliza ModalBottomSheet para manter linguagem visual do Material Design.
/// Observações: Ajusta habilitação de ações conforme a área selecionada evitando duplicidades no grafo. Pode ser estendido com novos itens preservando a estrutura existente de callbacks e feedbacks.
/// ---------------------------------------------------------------------------
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
