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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/result.dart';
import '../../data/services/file_operations_service.dart';
import 'utils/platform_file_loader.dart';
import 'error_banner.dart';
// import 'import_error_dialog.dart'; // does not exist yet (TODO)

/// Panel for file operations (save/load/export)
class FileOperationsPanel extends StatefulWidget {
  final FSA? automaton;
  final Grammar? grammar;
  final ValueChanged<FSA>? onAutomatonLoaded;
  final ValueChanged<Grammar>? onGrammarLoaded;
  final FileOperationsService fileService;

  const FileOperationsPanel({
    super.key,
    this.automaton,
    this.grammar,
    this.onAutomatonLoaded,
    this.onGrammarLoaded,
    FileOperationsService? fileService,
  }) : fileService = fileService ?? FileOperationsService();

  @override
  State<FileOperationsPanel> createState() => _FileOperationsPanelState();
}

class _PanelFeedback {
  const _PanelFeedback({
    required this.message,
    required this.severity,
    this.canRetry = false,
  });

  final String message;
  final ErrorSeverity severity;
  final bool canRetry;
}

class _FileOperationsPanelState extends State<FileOperationsPanel> {
  late final FileOperationsService _fileService;
  bool _isLoading = false;
  _PanelFeedback? _feedback;
  Future<void> Function()? _pendingRetry;

  @override
  void initState() {
    super.initState();
    _fileService = widget.fileService;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_feedback != null) ...[
              ErrorBanner(
                message: _feedback!.message,
                severity: _feedback!.severity,
                showRetryButton: _feedback!.canRetry && !_isLoading,
                onRetry: _feedback!.canRetry && !_isLoading
                    ? _retryLastOperation
                    : null,
                onDismiss: _dismissFeedback,
              ),
              const SizedBox(height: 16),
            ],
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
                    kIsWeb ? 'Download JFLAP' : 'Save as JFLAP',
                    Icons.save,
                    () => _saveAutomatonAsJFLAP(),
                  ),
                  _buildButton(
                    'Load JFLAP',
                    Icons.folder_open,
                    () => _loadAutomatonFromJFLAP(),
                  ),
                  _buildButton(
                    kIsWeb ? 'Download SVG' : 'Export SVG',
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
                    kIsWeb ? 'Download JFLAP' : 'Save as JFLAP',
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
      Result<String>? saveResult;

      if (kIsWeb) {
        saveResult = await _fileService.saveAutomatonToJFLAP(
          widget.automaton!,
          '${widget.automaton!.name}.jff',
        );
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Automaton as JFLAP',
          fileName: '${widget.automaton!.name}.jff',
          type: FileType.custom,
          allowedExtensions: ['jff'],
        );

        if (result == null) {
          return;
        }
        saveResult = await _fileService.saveAutomatonToJFLAP(
          widget.automaton!,
          result,
        );
      }

      if (saveResult.isSuccess) {
        final successMessage = kIsWeb
            ? 'Download started for ${saveResult.data ?? 'automaton.jff'}'
            : 'Automaton saved successfully';
        _showSuccessMessage(successMessage);
      } else {
        _showErrorMessage(
          'Failed to save automaton: ${saveResult.error}',
          retryOperation: _saveAutomatonAsJFLAP,
        );
      }
    } catch (e) {
      _showErrorMessage(
        'Error saving automaton: $e',
        retryOperation: _saveAutomatonAsJFLAP,
      );
    } finally {
      if (!mounted) return;
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
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final loadResult = await loadAutomatonFromPlatformFile(
          _fileService,
          file,
        );

        if (loadResult.isSuccess) {
          widget.onAutomatonLoaded?.call(loadResult.data!);
          _showSuccessMessage('Automaton loaded successfully');
        } else {
          await _handleImportFailure(
            fileName: file.name,
            errorMessage: loadResult.error ?? 'Unknown error',
            retryOperation: _loadAutomatonFromJFLAP,
          );
        }
      }
    } catch (e, stackTrace) {
      await _handleImportFailure(
        fileName: 'Automaton',
        errorMessage: 'Error loading automaton: $e',
        retryOperation: _loadAutomatonFromJFLAP,
        stackTrace: stackTrace,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportAutomatonAsSVG() async {
    if (widget.automaton == null) return;
    setState(() => _isLoading = true);
    try {
      Result<String>? exportResult;
      if (kIsWeb) {
        exportResult = await _fileService.exportLegacyAutomatonToSVG(
          widget.automaton!,
          '${widget.automaton!.name}.svg',
        );
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Export Automaton as SVG',
          fileName: '${widget.automaton!.name}.svg',
          type: FileType.custom,
          allowedExtensions: ['svg'],
        );
        if (result == null) {
          return;
        }
        exportResult = await _fileService.exportLegacyAutomatonToSVG(
          widget.automaton!,
          result,
        );
      }

      if (exportResult.isSuccess) {
        final successMessage = kIsWeb
            ? 'Download started for ${exportResult.data ?? 'automaton.svg'}'
            : 'Automaton exported successfully';
        _showSuccessMessage(successMessage);
      } else {
        _showErrorMessage(
          'Failed to export automaton: ${exportResult.error}',
          retryOperation: _exportAutomatonAsSVG,
        );
      }
    } catch (e) {
      _showErrorMessage(
        'Error exporting automaton: $e',
        retryOperation: _exportAutomatonAsSVG,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGrammarAsJFLAP() async {
    if (widget.grammar == null) return;
    setState(() => _isLoading = true);

    try {
      Result<String>? saveResult;

      if (kIsWeb) {
        saveResult = await _fileService.saveGrammarToJFLAP(
          widget.grammar!,
          '${widget.grammar!.name}.cfg',
        );
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Grammar as JFLAP',
          fileName: '${widget.grammar!.name}.cfg',
          type: FileType.custom,
          allowedExtensions: ['cfg'],
        );

        if (result == null) {
          return;
        }

        saveResult = await _fileService.saveGrammarToJFLAP(
          widget.grammar!,
          result,
        );
      }

      if (saveResult.isSuccess) {
        final successMessage = kIsWeb
            ? 'Download started for ${saveResult.data ?? 'grammar.cfg'}'
            : 'Grammar saved successfully';
        _showSuccessMessage(successMessage);
      } else {
        _showErrorMessage(
          'Failed to save grammar: ${saveResult.error}',
          retryOperation: _saveGrammarAsJFLAP,
        );
      }
    } catch (e) {
      _showErrorMessage(
        'Error saving grammar: $e',
        retryOperation: _saveGrammarAsJFLAP,
      );
    } finally {
      if (!mounted) return;
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
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final loadResult = await loadGrammarFromPlatformFile(
          _fileService,
          file,
        );

        if (loadResult.isSuccess) {
          widget.onGrammarLoaded?.call(loadResult.data!);
          _showSuccessMessage('Grammar loaded successfully');
        } else {
          await _handleImportFailure(
            fileName: file.name,
            errorMessage: loadResult.error ?? 'Unknown error',
            retryOperation: _loadGrammarFromJFLAP,
          );
        }
      }
    } catch (e, stackTrace) {
      await _handleImportFailure(
        fileName: 'Grammar',
        errorMessage: 'Error loading grammar: $e',
        retryOperation: _loadGrammarFromJFLAP,
        stackTrace: stackTrace,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImportFailure({
    required String fileName,
    required String errorMessage,
    required Future<void> Function() retryOperation,
    StackTrace? stackTrace,
  }) async {
    final trimmedMessage = errorMessage.trim();
    final isCritical = _isCriticalImportError(trimmedMessage);

    if (isCritical) {
      await _showImportErrorDialog(
        fileName: fileName,
        errorMessage: trimmedMessage,
        retryOperation: retryOperation,
        stackTrace: stackTrace,
      );
    } else {
      _showErrorMessage(trimmedMessage, retryOperation: retryOperation);
    }
  }

  Future<void> _showImportErrorDialog({
    required String fileName,
    required String errorMessage,
    required Future<void> Function() retryOperation,
    StackTrace? stackTrace,
  }) async {
    _pendingRetry = retryOperation;

    final errorType = _resolveImportErrorType(errorMessage);
    final friendlyMessage = _friendlyMessageFor(errorType);
    final technicalDetails = _composeTechnicalDetails(errorMessage, stackTrace);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _feedback = null;
    });

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ImportErrorDialog(
          fileName: fileName,
          errorType: errorType,
          detailedMessage: friendlyMessage,
          technicalDetails: technicalDetails,
          showTechnicalDetails: technicalDetails != null,
          onRetry: () {
            Navigator.of(dialogContext).pop();
            _retryLastOperation();
          },
          onCancel: () {
            Navigator.of(dialogContext).pop();
            _dismissFeedback();
          },
        );
      },
    );
  }

  String? _composeTechnicalDetails(String message, StackTrace? stackTrace) {
    if (message.isEmpty && stackTrace == null) {
      return null;
    }

    if (stackTrace == null) {
      return message;
    }

    final buffer = StringBuffer(message);
    buffer
      ..writeln()
      ..writeln(stackTrace.toString());
    return buffer.toString();
  }

  ImportErrorType _resolveImportErrorType(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('xml') || normalized.contains('parse')) {
      return ImportErrorType.malformedJFF;
    }
    if (normalized.contains('json')) {
      return ImportErrorType.invalidJSON;
    }
    if (normalized.contains('version')) {
      return ImportErrorType.unsupportedVersion;
    }
    if (normalized.contains('corrupt') ||
        normalized.contains('unreadable') ||
        normalized.contains('selected file did not contain readable data')) {
      return ImportErrorType.corruptedData;
    }
    return ImportErrorType.invalidAutomaton;
  }

  String _friendlyMessageFor(ImportErrorType type) {
    switch (type) {
      case ImportErrorType.malformedJFF:
        return 'The selected JFLAP file could not be parsed. Please verify the file integrity and try again.';
      case ImportErrorType.invalidJSON:
        return 'The import contains JSON sections that are invalid. Fix the JSON structure and retry.';
      case ImportErrorType.unsupportedVersion:
        return 'This file targets a newer JFLAP schema version. Export it again using a compatible version and retry.';
      case ImportErrorType.corruptedData:
        return 'The file appears to be corrupted or unreadable. Restore a valid backup before importing again.';
      case ImportErrorType.invalidAutomaton:
        return 'The automaton definition is inconsistent. Review the transitions and states before retrying the import.';
    }
  }

  bool _isCriticalImportError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('xml') ||
        normalized.contains('parse') ||
        normalized.contains('malformed') ||
        normalized.contains('invalid json') ||
        normalized.contains('corrupt') ||
        normalized.contains('unreadable');
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    setState(() {
      _feedback = _PanelFeedback(
        message: message,
        severity: ErrorSeverity.info,
      );
    });
    _pendingRetry = null;
  }

  void _showErrorMessage(
    String message, {
    Future<void> Function()? retryOperation,
  }) {
    if (!mounted) return;

    setState(() {
      _feedback = _PanelFeedback(
        message: message,
        severity: ErrorSeverity.error,
        canRetry: retryOperation != null,
      );
    });
    _pendingRetry = retryOperation;
  }

  void _retryLastOperation() {
    final retryOperation = _pendingRetry;
    if (retryOperation == null || _isLoading) {
      return;
    }

    setState(() {
      _feedback = null;
    });

    retryOperation();
  }

  void _dismissFeedback() {
    if (!mounted) return;

    setState(() {
      _feedback = null;
    });
    _pendingRetry = null;
  }
}
