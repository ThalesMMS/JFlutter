import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/error_handler.dart';

/// Advanced export tools for automata and grammars
/// Supports PNG, SVG, and LaTeX export formats
class AdvancedExportTools extends StatefulWidget {
  const AdvancedExportTools({
    super.key,
    required this.automaton,
    required this.canvasKey,
    this.grammar,
  });

  final AutomatonEntity automaton;
  final GlobalKey canvasKey;
  final Map<String, dynamic>? grammar;

  @override
  State<AdvancedExportTools> createState() => _AdvancedExportToolsState();
}

class _AdvancedExportToolsState extends State<AdvancedExportTools> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exportação Avançada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildExportButton(
                  'PNG',
                  Icons.image,
                  () => _exportToPNG(context),
                ),
                _buildExportButton(
                  'SVG',
                  Icons.image,
                  () => _exportToSVG(context),
                ),
                _buildExportButton(
                  'LaTeX',
                  Icons.code,
                  () => _exportToLaTeX(context),
                ),
                if (widget.grammar != null)
                  _buildExportButton(
                    'LaTeX CFG',
                    Icons.functions,
                    () => _exportGrammarToLaTeX(context),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Exporta o autômato atual em diferentes formatos. PNG para imagens, SVG para gráficos vetoriais, LaTeX para documentos acadêmicos.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_isExporting)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Exportando...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isExporting ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<void> _exportToPNG(BuildContext context) async {
    setState(() => _isExporting = true);
    
    try {
      final renderObject = widget.canvasKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        throw Exception('Canvas não encontrado');
      }

      final renderRepaintBoundary = renderObject as RenderRepaintBoundary;
      final image = await renderRepaintBoundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Falha ao converter imagem');
      }

      final bytes = byteData.buffer.asUint8List();
      
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, save to temporary directory and share
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/automaton_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Automaton exportado como PNG',
        );
      } else {
        // On desktop/web, copy to clipboard
        await Clipboard.setData(ClipboardData(
          text: 'PNG exportado (${bytes.length} bytes)',
        ));
      }
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'PNG exportado com sucesso');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erro ao exportar PNG: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportToSVG(BuildContext context) async {
    setState(() => _isExporting = true);
    
    try {
      final svgContent = _generateSVG();
      
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, save to temporary directory and share
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/automaton_${DateTime.now().millisecondsSinceEpoch}.svg');
        await file.writeAsString(svgContent);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Automaton exportado como SVG',
        );
      } else {
        // On desktop/web, copy to clipboard
        await Clipboard.setData(ClipboardData(text: svgContent));
      }
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'SVG exportado com sucesso');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erro ao exportar SVG: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportToLaTeX(BuildContext context) async {
    setState(() => _isExporting = true);
    
    try {
      final latexContent = _generateLaTeX();
      
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, save to temporary directory and share
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/automaton_${DateTime.now().millisecondsSinceEpoch}.tex');
        await file.writeAsString(latexContent);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Automaton exportado como LaTeX',
        );
      } else {
        // On desktop/web, copy to clipboard
        await Clipboard.setData(ClipboardData(text: latexContent));
      }
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'LaTeX exportado com sucesso');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erro ao exportar LaTeX: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportGrammarToLaTeX(BuildContext context) async {
    if (widget.grammar == null) return;
    
    setState(() => _isExporting = true);
    
    try {
      final latexContent = _generateGrammarLaTeX();
      
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, save to temporary directory and share
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/grammar_${DateTime.now().millisecondsSinceEpoch}.tex');
        await file.writeAsString(latexContent);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Gramática exportada como LaTeX',
        );
      } else {
        // On desktop/web, copy to clipboard
        await Clipboard.setData(ClipboardData(text: latexContent));
      }
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'LaTeX da gramática exportado com sucesso');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erro ao exportar LaTeX da gramática: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _generateSVG() {
    final states = widget.automaton.states;
    final transitions = widget.automaton.transitions;
    
    // Calculate bounds
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (final state in states) {
      minX = minX < state.x ? minX : state.x;
      maxX = maxX > state.x ? maxX : state.x;
      minY = minY < state.y ? minY : state.y;
      maxY = maxY > state.y ? maxY : state.y;
    }
    
    final width = (maxX - minX + 200).clamp(400.0, 800.0);
    final height = (maxY - minY + 200).clamp(300.0, 600.0);
    
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">');
    buffer.writeln('  <defs>');
    buffer.writeln('    <style>');
    buffer.writeln('      .state { fill: white; stroke: black; stroke-width: 2; }');
    buffer.writeln('      .final-state { fill: white; stroke: black; stroke-width: 3; }');
    buffer.writeln('      .initial-state { fill: lightblue; stroke: black; stroke-width: 2; }');
    buffer.writeln('      .transition { stroke: black; stroke-width: 1; fill: none; }');
    buffer.writeln('      .label { font-family: Arial, sans-serif; font-size: 12px; text-anchor: middle; }');
    buffer.writeln('    </style>');
    buffer.writeln('  </defs>');
    
    // Draw transitions
    for (final entry in transitions.entries) {
      final parts = entry.key.split('|');
      if (parts.length != 2) continue;
      
      final fromStateId = parts[0];
      final symbol = parts[1];
      final fromState = widget.automaton.getState(fromStateId);
      
      if (fromState == null) continue;
      
      for (final toStateId in entry.value) {
        final toState = widget.automaton.getState(toStateId);
        if (toState == null) continue;
        
        final x1 = fromState.x - minX + 100;
        final y1 = fromState.y - minY + 100;
        final x2 = toState.x - minX + 100;
        final y2 = toState.y - minY + 100;
        
        // Draw transition line
        buffer.writeln('    <line x1="$x1" y1="$y1" x2="$x2" y2="$y2" class="transition"/>');
        
        // Draw transition label
        final midX = (x1 + x2) / 2;
        final midY = (y1 + y2) / 2;
        buffer.writeln('    <text x="$midX" y="${midY - 5}" class="label">$symbol</text>');
      }
    }
    
    // Draw states
    for (final state in states) {
      final x = state.x - minX + 100;
      final y = state.y - minY + 100;
      final radius = 20.0;
      
      String stateClass = 'state';
      if (state.isFinal) stateClass = 'final-state';
      if (state.id == widget.automaton.initialId) stateClass = 'initial-state';
      
      buffer.writeln('    <circle cx="$x" cy="$y" r="$radius" class="$stateClass"/>');
      buffer.writeln('    <text x="$x" y="${y + 4}" class="label">${state.name}</text>');
    }
    
    buffer.writeln('</svg>');
    return buffer.toString();
  }

  String _generateLaTeX() {
    final states = widget.automaton.states;
    final transitions = widget.automaton.transitions;
    final alphabet = widget.automaton.alphabet;
    
    final buffer = StringBuffer();
    buffer.writeln('\\documentclass{article}');
    buffer.writeln('\\usepackage{tikz}');
    buffer.writeln('\\usetikzlibrary{automata,positioning}');
    buffer.writeln('\\begin{document}');
    buffer.writeln('');
    buffer.writeln('\\begin{tikzpicture}[shorten >=1pt,node distance=2cm,on grid,auto]');
    buffer.writeln('');
    
    // Define states
    for (final state in states) {
      final stateOptions = <String>[];
      
      if (state.id == widget.automaton.initialId) {
        stateOptions.add('initial');
      }
      
      if (state.isFinal) {
        stateOptions.add('accepting');
      }
      
      final options = stateOptions.isNotEmpty ? '[${stateOptions.join(',')}]' : '';
      buffer.writeln('  \\node[state$options] ($state) {$state.name};');
    }
    
    buffer.writeln('');
    
    // Define transitions
    for (final entry in transitions.entries) {
      final parts = entry.key.split('|');
      if (parts.length != 2) continue;
      
      final fromStateId = parts[0];
      final symbol = parts[1];
      
      for (final toStateId in entry.value) {
        buffer.writeln('  \\path[->] ($fromStateId) edge node {$symbol} ($toStateId);');
      }
    }
    
    buffer.writeln('\\end{tikzpicture}');
    buffer.writeln('');
    buffer.writeln('\\textbf{Alfabeto:} \\{${alphabet.join(', ')}\\}');
    buffer.writeln('');
    buffer.writeln('\\textbf{Estados:} ${states.map((s) => s.name).join(', ')}');
    buffer.writeln('');
    buffer.writeln('\\textbf{Estado inicial:} ${widget.automaton.initialId ?? 'N/A'}');
    buffer.writeln('');
    buffer.writeln('\\textbf{Estados finais:} ${states.where((s) => s.isFinal).map((s) => s.name).join(', ')}');
    buffer.writeln('');
    buffer.writeln('\\end{document}');
    
    return buffer.toString();
  }

  String _generateGrammarLaTeX() {
    if (widget.grammar == null) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('\\documentclass{article}');
    buffer.writeln('\\usepackage{amsmath}');
    buffer.writeln('\\begin{document}');
    buffer.writeln('');
    buffer.writeln('\\section{Gramática Livre de Contexto}');
    buffer.writeln('');
    
    // Extract grammar information
    final productions = widget.grammar!['productions'] as List<dynamic>? ?? [];
    final startSymbol = widget.grammar!['startSymbol'] as String? ?? 'S';
    
    buffer.writeln('\\textbf{Símbolo inicial:} $startSymbol');
    buffer.writeln('');
    buffer.writeln('\\textbf{Produções:}');
    buffer.writeln('\\begin{align}');
    
    for (int i = 0; i < productions.length; i++) {
      final production = productions[i] as Map<String, dynamic>;
      final left = production['left'] as String? ?? '';
      final right = production['right'] as String? ?? '';
      
      final arrow = i < productions.length - 1 ? '\\\\' : '';
      buffer.writeln('  $left &\\rightarrow $right$arrow');
    }
    
    buffer.writeln('\\end{align}');
    buffer.writeln('');
    buffer.writeln('\\end{document}');
    
    return buffer.toString();
  }
}

/// Export dialog for advanced export options
class AdvancedExportDialog extends StatefulWidget {
  const AdvancedExportDialog({
    super.key,
    required this.automaton,
    required this.canvasKey,
    this.grammar,
  });

  final AutomatonEntity automaton;
  final GlobalKey canvasKey;
  final Map<String, dynamic>? grammar;

  @override
  State<AdvancedExportDialog> createState() => _AdvancedExportDialogState();
}

class _AdvancedExportDialogState extends State<AdvancedExportDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportação Avançada'),
      content: SizedBox(
        width: 400,
        child: AdvancedExportTools(
          automaton: widget.automaton,
          canvasKey: widget.canvasKey,
          grammar: widget.grammar,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
