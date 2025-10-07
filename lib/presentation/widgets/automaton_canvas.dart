/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/widgets/automaton_canvas.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Redireciona para o canvas unificado baseado em GraphView garantindo interface consistente para importações legadas. Fornece typedef amigável para manter nomenclaturas utilizadas anteriormente no projeto.
/// Contexto: Funciona como ponto de entrada simplificado permitindo alternar implementações sem atualizar consumidores espalhados. Mantém compatibilidade ao reexportar o widget principal com escopo controlado.
/// Observações: Estrutura mínima facilita futuras adaptações específicas por plataforma. Documentação clara auxilia desenvolvedores na transição para a nova infraestrutura de canvas.
/// ---------------------------------------------------------------------------
import 'automaton_graphview_canvas.dart';

export 'automaton_graphview_canvas.dart' show AutomatonGraphViewCanvas;

typedef AutomatonCanvas = AutomatonGraphViewCanvas;
