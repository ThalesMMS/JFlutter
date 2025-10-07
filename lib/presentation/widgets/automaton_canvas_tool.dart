/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/widgets/automaton_canvas_tool.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Define os modos de edição disponíveis no canvas de autômatos e fornece controlador observável para alterná-los. Facilita integração com toolbars e componentes que precisam reagir a mudanças de ferramenta.
/// Contexto: Utiliza ChangeNotifier para propagar eventos de seleção permitindo múltiplos ouvintes sincronizados. Mantém estado simples com valor padrão focado na ferramenta de seleção para edições comuns.
/// Observações: Pode ser expandido com novos modos sem alterar contratos existentes. Ideal para coordenação entre painéis e gestos do canvas que dependem da ferramenta ativa.
/// ---------------------------------------------------------------------------
import 'package:flutter/foundation.dart';

/// Editing tools supported by the automaton canvas.
enum AutomatonCanvasTool { selection, addState, transition }

/// Controller that tracks and broadcasts the active canvas tool.
class AutomatonCanvasToolController extends ChangeNotifier {
  AutomatonCanvasToolController([
    this._activeTool = AutomatonCanvasTool.selection,
  ]);

  AutomatonCanvasTool _activeTool;

  AutomatonCanvasTool get activeTool => _activeTool;

  /// Sets the current tool, notifying listeners when it changes.
  void setActiveTool(AutomatonCanvasTool tool) {
    if (_activeTool == tool) {
      return;
    }
    _activeTool = tool;
    notifyListeners();
  }
}
