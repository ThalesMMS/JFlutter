/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/widgets/automaton_canvas_web.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Expõe a implementação compartilhada do canvas de autômatos baseada em GraphView para a plataforma web. Simplifica a manutenção apontando diretamente para o widget principal utilizado nas demais plataformas.
/// Contexto: Este arquivo atua como adaptador mínimo preservando compatibilidade com imports históricos. Garante que o build web utilize a mesma infraestrutura rica de edição disponível no ambiente desktop.
/// Observações: Mantém comentário orientativo destacando a reutilização do canvas unificado. Pode ser expandido caso diferenças específicas da web sejam necessárias no futuro.
/// ---------------------------------------------------------------------------
/// Web now shares the GraphView-based automaton canvas implementation.
export 'automaton_graphview_canvas.dart';
