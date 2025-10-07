//
//  automaton_canvas.dart
//  JFlutter
//
//  Age como fachada para o canvas unificado baseado em GraphView, mantendo
//  compatibilidade com importações legadas e permitindo a substituição do
//  widget principal sem tocar consumidores espalhados pelo projeto.
//  Reexporta AutomatonGraphViewCanvas com um typedef amigável para preservar
//  nomenclaturas antigas enquanto concentra futuras personalizações em um único
//  ponto de entrada.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'automaton_graphview_canvas.dart';

export 'automaton_graphview_canvas.dart' show AutomatonGraphViewCanvas;

typedef AutomatonCanvas = AutomatonGraphViewCanvas;
