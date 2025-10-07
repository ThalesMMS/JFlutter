//
//  file_operations_panel.dart
//  JFlutter
//
//  Painel de interface que agrupa ações de salvar, carregar e exportar
//  autômatos ou gramáticas nos formatos suportados, apresentando botões
//  contextualizados conforme os dados disponíveis. O widget orquestra o
//  FileOperationsService, interage com o FilePicker e exibe indicadores de
//  progresso para operações assíncronas, atualizando callbacks fornecidos pela
//  tela hospedeira.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../data/services/file_operations_service.dart';

/// Panel for file operations (save/load/export)
class FileOperationsPanel extends StatefulWidget {
  final FSA? automaton;
  final Grammar? grammar;
  final ValueChanged<FSA>? onAutomatonLoaded;
  final ValueChanged<Grammar>? onGrammarLoaded;

  const FileOperationsPanel({
    super.key,
    this.automaton,
    this.grammar,
    this.onAutomatonLoaded,
    this.onGrammarLoaded,
  });

  @override
  State<FileOperationsPanel> createState() => _FileOperationsPanelState();
}

class _FileOperationsPanelState extends State<FileOperationsPanel> {
  final FileOperationsService _fileService = FileOperationsService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Operations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Automaton operations
            if (widget.automaton != null) ...[
              _buildSectionTitle('Automaton'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildButton(
                    'Save as JFLAP',
                    Icons.save,
                    () => _saveAutomatonAsJFLAP(),
                  ),
                  _buildButton(
                    'Load JFLAP',
                    Icons.folder_open,
                    () => _loadAutomatonFromJFLAP(),
                  ),
                  _buildButton(
                    'Export SVG',
                    Icons.image,
                    () => _exportAutomatonAsSVG(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Grammar operations
            if (widget.grammar != null) ...[
              _buildSectionTitle('Grammar'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildButton(
                    'Save as JFLAP',
                    Icons.save,
                    () => _saveGrammarAsJFLAP(),
                  ),
                  _buildButton(
                    'Load JFLAP',
                    Icons.folder_open,
                    () => _loadGrammarFromJFLAP(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Loading indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _saveAutomatonAsJFLAP() async {
    if (widget.automaton == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Automaton as JFLAP',
        fileName: '${widget.automaton!.name}.jff',
        type: FileType.custom,
        allowedExtensions: ['jff'],
      );

      if (result != null) {
        final saveResult = await _fileService.saveAutomatonToJFLAP(
          widget.automaton!,
          result,
        );

        if (saveResult.isSuccess) {
          _showSuccessMessage('Automaton saved successfully');
        } else {
          _showErrorMessage('Failed to save automaton: ${saveResult.error}');
        }
      }
    } catch (e) {
      _showErrorMessage('Error saving automaton: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAutomatonFromJFLAP() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jff'],
        dialogTitle: 'Load JFLAP Automaton',
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path!;
        final loadResult = await _fileService.loadAutomatonFromJFLAP(filePath);

        if (loadResult.isSuccess) {
          widget.onAutomatonLoaded?.call(loadResult.data!);
          _showSuccessMessage('Automaton loaded successfully');
        } else {
          _showErrorMessage('Failed to load automaton: ${loadResult.error}');
        }
      }
    } catch (e) {
      _showErrorMessage('Error loading automaton: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportAutomatonAsSVG() async {
    if (widget.automaton == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Automaton as SVG',
        fileName: '${widget.automaton!.name}.svg',
        type: FileType.custom,
        allowedExtensions: ['svg'],
      );
      if (result != null) {
        // Use legacy exporter path for FSA model
        final exportResult = await _fileService.exportLegacyAutomatonToSVG(
          widget.automaton!,
          result,
        );
        if (exportResult.isSuccess) {
          _showSuccessMessage('Automaton exported successfully');
        } else {
          _showErrorMessage(
            'Failed to export automaton: ${exportResult.error}',
          );
        }
      }
    } catch (e) {
      _showErrorMessage('Error exporting automaton: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGrammarAsJFLAP() async {
    if (widget.grammar == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Grammar as JFLAP',
        fileName: '${widget.grammar!.name}.cfg',
        type: FileType.custom,
        allowedExtensions: ['cfg'],
      );

      if (result != null) {
        final saveResult = await _fileService.saveGrammarToJFLAP(
          widget.grammar!,
          result,
        );

        if (saveResult.isSuccess) {
          _showSuccessMessage('Grammar saved successfully');
        } else {
          _showErrorMessage('Failed to save grammar: ${saveResult.error}');
        }
      }
    } catch (e) {
      _showErrorMessage('Error saving grammar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGrammarFromJFLAP() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['cfg'],
        dialogTitle: 'Load JFLAP Grammar',
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path!;
        final loadResult = await _fileService.loadGrammarFromJFLAP(filePath);

        if (loadResult.isSuccess) {
          widget.onGrammarLoaded?.call(loadResult.data!);
          _showSuccessMessage('Grammar loaded successfully');
        } else {
          _showErrorMessage('Failed to load grammar: ${loadResult.error}');
        }
      }
    } catch (e) {
      _showErrorMessage('Error loading grammar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
