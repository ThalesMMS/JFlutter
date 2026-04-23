//
//  file_operations_panel.dart
//  JFlutter
//
//  Painel de interface que agrupa ações de salvar, carregar e exportar
//  autômatos, gramáticas, PDAs e máquinas de Turing nos formatos suportados,
//  apresentando apenas as operações liberadas para cada módulo pelo escopo de
//  release. O widget orquestra o FileOperationsService, interage com o
//  FilePicker e exibe indicadores de progresso para operações assíncronas,
//  atualizando callbacks fornecidos pela tela hospedeira.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/config/v1_feature_flags.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/entities/grammar_entity.dart';
import '../../core/entities/turing_machine_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../core/result.dart';
import '../../core/utils/epsilon_utils.dart';
import '../../data/services/file_operations_service.dart';
import 'utils/platform_file_loader.dart';
import 'error_banner.dart';
import 'import_error_dialog.dart';

class _FileOperationCapabilities {
  const _FileOperationCapabilities({
    this.supportsJflapImport = false,
    this.supportsJflapExport = false,
    this.supportsJsonImport = false,
    this.supportsJsonExport = false,
    this.supportsSvgExport = false,
    this.supportsPngExport = false,
  });

  final bool supportsJflapImport;
  final bool supportsJflapExport;
  final bool supportsJsonImport;
  final bool supportsJsonExport;
  final bool supportsSvgExport;
  final bool supportsPngExport;
}

const _fsaCapabilities = _FileOperationCapabilities(
  supportsJflapImport: V1FeatureFlags.fsaSupportsJflapImport,
  supportsJflapExport: V1FeatureFlags.fsaSupportsJflapExport,
  supportsJsonImport: V1FeatureFlags.fsaSupportsJsonImport,
  supportsJsonExport: V1FeatureFlags.fsaSupportsJsonExport,
  supportsSvgExport: V1FeatureFlags.fsaSupportsSvgExport,
  supportsPngExport: V1FeatureFlags.fsaSupportsPngExport,
);

const _grammarCapabilities = _FileOperationCapabilities(
  supportsJflapImport: V1FeatureFlags.grammarSupportsJflapImport,
  supportsJflapExport: V1FeatureFlags.grammarSupportsJflapExport,
  supportsSvgExport: V1FeatureFlags.grammarSupportsSvgExport,
);

const _pdaCapabilities = _FileOperationCapabilities(
  supportsJflapImport: V1FeatureFlags.pdaSupportsJflapImport,
  supportsJflapExport: V1FeatureFlags.pdaSupportsJflapExport,
  supportsJsonImport: V1FeatureFlags.pdaSupportsJsonImport,
  supportsJsonExport: V1FeatureFlags.pdaSupportsJsonExport,
  supportsSvgExport: V1FeatureFlags.pdaSupportsSvgExport,
);

const _tmCapabilities = _FileOperationCapabilities(
  supportsJflapImport: V1FeatureFlags.tmSupportsJflapImport,
  supportsJflapExport: V1FeatureFlags.tmSupportsJflapExport,
  supportsJsonImport: V1FeatureFlags.tmSupportsJsonImport,
  supportsJsonExport: V1FeatureFlags.tmSupportsJsonExport,
  supportsSvgExport: V1FeatureFlags.tmSupportsSvgExport,
);

const _kJsonUnreadableFileMessage =
    'JFlutter could not access the selected JSON file data. Pick the file again and keep it available until the import finishes.';

String? _normalizedJsonPath(String? path) {
  if (path == null) {
    return null;
  }

  final trimmed = path.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Panel for file operations (save/load/export)
class FileOperationsPanel extends StatefulWidget {
  final FSA? automaton;
  final Grammar? grammar;
  final PDA? pda;
  final TM? turingMachine;
  final ValueChanged<FSA>? onAutomatonLoaded;
  final ValueChanged<Grammar>? onGrammarLoaded;
  final FileOperationsService? fileService;

  const FileOperationsPanel({
    super.key,
    this.automaton,
    this.grammar,
    this.pda,
    this.turingMachine,
    this.onAutomatonLoaded,
    this.onGrammarLoaded,
    this.fileService,
  });

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
    _fileService = widget.fileService ?? FileOperationsService();
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

            // FSA operations
            if (widget.automaton != null) ...[
              _buildSectionTitle('FSA'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_fsaCapabilities.supportsJflapExport)
                    _buildButton(
                      kIsWeb ? 'Download JFLAP' : 'Save as JFLAP',
                      Icons.save,
                      () => _saveAutomatonAsJFLAP(),
                    ),
                  if (_fsaCapabilities.supportsJflapImport)
                    _buildButton(
                      'Load JFLAP',
                      Icons.folder_open,
                      () => _loadAutomatonFromJFLAP(),
                    ),
                  if (_fsaCapabilities.supportsJsonExport)
                    _buildButton(
                      kIsWeb ? 'Download JSON' : 'Save as JSON',
                      Icons.data_object,
                      () => _saveAutomatonAsJson(),
                    ),
                  if (_fsaCapabilities.supportsJsonImport)
                    _buildButton(
                      'Load JSON',
                      Icons.upload_file,
                      () => _loadAutomatonFromJson(),
                    ),
                  if (_fsaCapabilities.supportsSvgExport)
                    _buildButton(
                      kIsWeb ? 'Download SVG' : 'Export SVG',
                      Icons.image,
                      () => _exportAutomatonAsSVG(),
                    ),
                  if (_fsaCapabilities.supportsPngExport && !kIsWeb)
                    _buildButton(
                      'Export PNG',
                      Icons.photo,
                      () => _exportAutomatonAsPNG(),
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
                  if (_grammarCapabilities.supportsJflapExport)
                    _buildButton(
                      kIsWeb ? 'Download JFLAP' : 'Save as JFLAP',
                      Icons.save,
                      () => _saveGrammarAsJFLAP(),
                    ),
                  if (_grammarCapabilities.supportsJflapImport)
                    _buildButton(
                      'Load JFLAP',
                      Icons.folder_open,
                      () => _loadGrammarFromJFLAP(),
                    ),
                  if (_grammarCapabilities.supportsSvgExport)
                    _buildButton(
                      kIsWeb ? 'Download SVG' : 'Export SVG',
                      Icons.image,
                      () => _exportGrammarAsSVG(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (widget.pda != null) ...[
              _buildSectionTitle('PDA'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_pdaCapabilities.supportsSvgExport)
                    _buildButton(
                      kIsWeb ? 'Download SVG' : 'Export SVG',
                      Icons.image,
                      () => _exportPdaAsSVG(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (widget.turingMachine != null) ...[
              _buildSectionTitle('Turing Machine'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_tmCapabilities.supportsSvgExport)
                    _buildButton(
                      kIsWeb ? 'Download SVG' : 'Export SVG',
                      Icons.image,
                      () => _exportTuringMachineAsSVG(),
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

  bool get _saveFileConsumesBytesInPicker =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<String?> _selectSaveDestination({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    Uint8List? bytes,
  }) {
    return FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      bytes: _saveFileConsumesBytesInPicker ? bytes : null,
    );
  }

  Future<Result<String>?> _saveTextFileWithPicker({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    required String contents,
    required Future<StringResult> Function(String path) writeToPath,
  }) async {
    final selectedPath = await _selectSaveDestination(
      dialogTitle: dialogTitle,
      fileName: fileName,
      allowedExtensions: allowedExtensions,
      bytes: Uint8List.fromList(utf8.encode(contents)),
    );

    if (selectedPath == null) {
      _showOperationCancelledMessage('Save canceled.');
      return null;
    }

    if (_saveFileConsumesBytesInPicker) {
      return Success(selectedPath);
    }

    return writeToPath(selectedPath);
  }

  Future<Result<String>?> _saveBinaryFileWithPicker({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    required Uint8List bytes,
    required Future<StringResult> Function(String path) writeToPath,
  }) async {
    final selectedPath = await _selectSaveDestination(
      dialogTitle: dialogTitle,
      fileName: fileName,
      allowedExtensions: allowedExtensions,
      bytes: bytes,
    );

    if (selectedPath == null) {
      _showOperationCancelledMessage('Export canceled.');
      return null;
    }

    if (_saveFileConsumesBytesInPicker) {
      return Success(selectedPath);
    }

    return writeToPath(selectedPath);
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
        saveResult = await _saveTextFileWithPicker(
          dialogTitle: 'Save Automaton as JFLAP',
          fileName: '${widget.automaton!.name}.jff',
          allowedExtensions: ['jff'],
          contents: _fileService.serializeAutomatonToJFLAPString(
            widget.automaton!,
          ),
          writeToPath: (path) =>
              _fileService.saveAutomatonToJFLAP(widget.automaton!, path),
        );

        if (saveResult == null) {
          return;
        }
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
    } catch (e, stackTrace) {
      _showErrorMessage(
        'Error saving automaton: $e',
        retryOperation: _saveAutomatonAsJFLAP,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      } else {
        _showOperationCancelledMessage('Import canceled.');
      }
    } catch (e, stackTrace) {
      await _handleImportFailure(
        fileName: 'Automaton',
        errorMessage: 'Error loading automaton: $e',
        retryOperation: _loadAutomatonFromJFLAP,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAutomatonAsJson() async {
    if (widget.automaton == null) return;
    setState(() => _isLoading = true);

    try {
      Result<String>? saveResult;

      if (kIsWeb) {
        saveResult = await _fileService.saveAutomatonToJson(
          widget.automaton!,
          '${widget.automaton!.name}.json',
        );
      } else {
        saveResult = await _saveTextFileWithPicker(
          dialogTitle: 'Save Automaton as JSON',
          fileName: '${widget.automaton!.name}.json',
          allowedExtensions: ['json'],
          contents: _fileService.serializeAutomatonToJsonString(
            widget.automaton!,
          ),
          writeToPath: (path) =>
              _fileService.saveAutomatonToJson(widget.automaton!, path),
        );

        if (saveResult == null) {
          return;
        }
      }

      if (saveResult.isSuccess) {
        final successMessage = kIsWeb
            ? 'Download started for ${saveResult.data ?? 'automaton.json'}'
            : 'Automaton saved successfully';
        _showSuccessMessage(successMessage);
      } else {
        _showErrorMessage(
          'Failed to save automaton JSON: ${saveResult.error}',
          retryOperation: _saveAutomatonAsJson,
        );
      }
    } catch (e, stackTrace) {
      _showErrorMessage(
        'Error saving automaton JSON: $e',
        retryOperation: _saveAutomatonAsJson,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAutomatonFromJson() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Load Automaton JSON',
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final loadResult = await _loadAutomatonJsonFromPlatformFile(file);

        if (loadResult.isSuccess) {
          widget.onAutomatonLoaded?.call(loadResult.data!);
          _showSuccessMessage('Automaton loaded successfully');
        } else {
          await _handleImportFailure(
            fileName: file.name,
            errorMessage: loadResult.error ?? 'Unknown error',
            retryOperation: _loadAutomatonFromJson,
          );
        }
      } else {
        _showOperationCancelledMessage('Import canceled.');
      }
    } catch (e, stackTrace) {
      await _handleImportFailure(
        fileName: 'Automaton JSON',
        errorMessage: 'Error loading automaton JSON: $e',
        retryOperation: _loadAutomatonFromJson,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        exportResult = await _saveTextFileWithPicker(
          dialogTitle: 'Export Automaton as SVG',
          fileName: '${widget.automaton!.name}.svg',
          allowedExtensions: ['svg'],
          contents: _fileService.exportLegacyAutomatonToSvgString(
            widget.automaton!,
          ),
          writeToPath: (path) => _fileService.exportLegacyAutomatonToSVG(
            widget.automaton!,
            path,
          ),
        );

        if (exportResult == null) {
          return;
        }
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
    } catch (e, stackTrace) {
      _showErrorMessage(
        'Error exporting automaton: $e',
        retryOperation: _exportAutomatonAsSVG,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportAutomatonAsPNG() async {
    if (widget.automaton == null) return;
    setState(() => _isLoading = true);

    try {
      Result<String>? exportResult;
      final pngBytesResult = await _fileService.exportAutomatonToPngBytes(
        widget.automaton!,
      );
      if (pngBytesResult.isFailure) {
        _showErrorMessage(
          'Failed to export automaton PNG: ${pngBytesResult.error}',
          retryOperation: _exportAutomatonAsPNG,
        );
        return;
      }

      exportResult = await _saveBinaryFileWithPicker(
        dialogTitle: 'Export Automaton as PNG',
        fileName: '${widget.automaton!.name}.png',
        allowedExtensions: ['png'],
        bytes: pngBytesResult.data!,
        writeToPath: (path) =>
            _fileService.writePngBytesToPath(pngBytesResult.data!, path),
      );

      if (exportResult == null) {
        return;
      }

      if (exportResult.isSuccess) {
        _showSuccessMessage('Automaton exported successfully');
      } else {
        _showErrorMessage(
          'Failed to export automaton PNG: ${exportResult.error}',
          retryOperation: _exportAutomatonAsPNG,
        );
      }
    } catch (e, stackTrace) {
      _showErrorMessage(
        'Error exporting automaton PNG: $e',
        retryOperation: _exportAutomatonAsPNG,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        saveResult = await _saveTextFileWithPicker(
          dialogTitle: 'Save Grammar as JFLAP',
          fileName: '${widget.grammar!.name}.cfg',
          allowedExtensions: ['cfg'],
          contents: _fileService.serializeGrammarToJFLAPString(
            widget.grammar!,
          ),
          writeToPath: (path) =>
              _fileService.saveGrammarToJFLAP(widget.grammar!, path),
        );

        if (saveResult == null) {
          return;
        }
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
    } catch (e, stackTrace) {
      _showErrorMessage(
        'Error saving grammar: $e',
        retryOperation: _saveGrammarAsJFLAP,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      } else {
        _showOperationCancelledMessage('Import canceled.');
      }
    } catch (e, stackTrace) {
      await _handleImportFailure(
        fileName: 'Grammar',
        errorMessage: 'Error loading grammar: $e',
        retryOperation: _loadGrammarFromJFLAP,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportGrammarAsSVG() async {
    if (widget.grammar == null) return;
    setState(() => _isLoading = true);

    try {
      Result<String>? exportResult;
      final grammarEntity = _convertGrammarToEntity(widget.grammar!);

      if (kIsWeb) {
        exportResult = await _fileService.exportGrammarToSVG(
          grammarEntity,
          '${widget.grammar!.name}.svg',
        );
      } else {
        exportResult = await _saveTextFileWithPicker(
          dialogTitle: 'Export Grammar as SVG',
          fileName: '${widget.grammar!.name}.svg',
          allowedExtensions: ['svg'],
          contents: _fileService.exportGrammarToSvgString(grammarEntity),
          writeToPath: (path) =>
              _fileService.exportGrammarToSVG(grammarEntity, path),
        );

        if (exportResult == null) {
          return;
        }
      }

      if (exportResult.isSuccess) {
        final successMessage = kIsWeb
            ? 'Download started for ${exportResult.data ?? 'grammar.svg'}'
            : 'Grammar exported successfully';
        _showSuccessMessage(successMessage);
      } else {
        _showErrorMessage(
          'Failed to export grammar: ${exportResult.error}',
          retryOperation: _exportGrammarAsSVG,
        );
      }
    } catch (e, stackTrace) {
      _showErrorMessage(
        'Error exporting grammar: $e',
        retryOperation: _exportGrammarAsSVG,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportPdaAsSVG() async {
    if (widget.pda == null) return;
    setState(() => _isLoading = true);

    try {
      Result<String>? exportResult;
      final automatonEntity = _convertPdaToAutomatonEntity(widget.pda!);

      if (kIsWeb) {
        exportResult = await _fileService.exportAutomatonToSVG(
          automatonEntity,
          '${widget.pda!.name}.svg',
        );
      } else {
        exportResult = await _saveTextFileWithPicker(
          dialogTitle: 'Export PDA as SVG',
          fileName: '${widget.pda!.name}.svg',
          allowedExtensions: ['svg'],
          contents: _fileService.exportAutomatonToSvgString(automatonEntity),
          writeToPath: (path) =>
              _fileService.exportAutomatonToSVG(automatonEntity, path),
        );

        if (exportResult == null) {
          return;
        }
      }

      if (exportResult.isSuccess) {
        final successMessage = kIsWeb
            ? 'Download started for ${exportResult.data ?? 'pda.svg'}'
            : 'PDA exported successfully';
        _showSuccessMessage(successMessage);
      } else {
        _showErrorMessage(
          'Failed to export PDA: ${exportResult.error}',
          retryOperation: _exportPdaAsSVG,
        );
      }
    } catch (e, stackTrace) {
      _showErrorMessage(
        'Error exporting PDA: $e',
        retryOperation: _exportPdaAsSVG,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportTuringMachineAsSVG() async {
    if (widget.turingMachine == null) return;
    setState(() => _isLoading = true);

    try {
      Result<String>? exportResult;
      final tmEntity = _convertTmToEntity(widget.turingMachine!);

      if (kIsWeb) {
        exportResult = await _fileService.exportTuringMachineToSVG(
          tmEntity,
          '${widget.turingMachine!.name}.svg',
        );
      } else {
        exportResult = await _saveTextFileWithPicker(
          dialogTitle: 'Export Turing Machine as SVG',
          fileName: '${widget.turingMachine!.name}.svg',
          allowedExtensions: ['svg'],
          contents: _fileService.exportTuringMachineToSvgString(tmEntity),
          writeToPath: (path) =>
              _fileService.exportTuringMachineToSVG(tmEntity, path),
        );

        if (exportResult == null) {
          return;
        }
      }

      if (exportResult.isSuccess) {
        final successMessage = kIsWeb
            ? 'Download started for ${exportResult.data ?? 'tm.svg'}'
            : 'Turing machine exported successfully';
        _showSuccessMessage(successMessage);
      } else {
        _showErrorMessage(
          'Failed to export Turing machine: ${exportResult.error}',
          retryOperation: _exportTuringMachineAsSVG,
        );
      }
    } catch (e, stackTrace) {
      _showErrorMessage(
        'Error exporting Turing machine: $e',
        retryOperation: _exportTuringMachineAsSVG,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Result<FSA>> _loadAutomatonJsonFromPlatformFile(
    PlatformFile file,
  ) async {
    if (file.bytes != null) {
      return _fileService.loadAutomatonFromJsonBytes(file.bytes!);
    }

    final normalizedPath = _normalizedJsonPath(file.path);
    if (normalizedPath != null) {
      return _fileService.loadAutomatonFromJson(normalizedPath);
    }

    return const Failure<FSA>(_kJsonUnreadableFileMessage);
  }

  GrammarEntity _convertGrammarToEntity(Grammar grammar) {
    return GrammarEntity(
      id: grammar.id,
      name: grammar.name,
      terminals: grammar.terminals,
      nonTerminals: grammar.nonterminals,
      startSymbol: grammar.startSymbol,
      productions: grammar.productions
          .map(
            (production) => ProductionEntity(
              id: production.id,
              leftSide: List<String>.from(production.leftSide),
              rightSide: List<String>.from(production.rightSide),
            ),
          )
          .toList(),
    );
  }

  AutomatonEntity _convertPdaToAutomatonEntity(PDA pda) {
    final transitions = <String, List<String>>{};

    for (final transition in pda.pdaTransitions) {
      final label = _formatPdaTransitionLabel(transition);
      final key = '${transition.fromState.id}|$label';
      transitions.putIfAbsent(key, () => <String>[]).add(transition.toState.id);
    }

    return AutomatonEntity(
      id: pda.id,
      name: pda.name,
      alphabet: pda.alphabet.map(normalizeToEpsilon).toSet(),
      states: pda.states
          .map(
            (state) => StateEntity(
              id: state.id,
              name: state.label,
              x: state.position.x,
              y: state.position.y,
              isInitial: state.isInitial,
              isFinal: state.isAccepting,
            ),
          )
          .toList(),
      transitions: transitions,
      initialId: pda.initialState?.id,
      nextId: pda.states.length,
      type: AutomatonType.nfa,
    );
  }

  TuringMachineEntity _convertTmToEntity(TM tm) {
    return TuringMachineEntity(
      id: tm.id,
      name: tm.name,
      inputAlphabet: tm.alphabet,
      tapeAlphabet: tm.tapeAlphabet,
      blankSymbol: tm.blankSymbol,
      states: tm.states
          .map(
            (state) => TuringStateEntity(
              id: state.id,
              name: state.label,
              isInitial: state.isInitial,
              isAccepting: state.isAccepting,
            ),
          )
          .toList(),
      transitions: tm.tmTransitions
          .map(
            (transition) => TuringTransitionEntity(
              id: transition.id,
              fromStateId: transition.fromState.id,
              toStateId: transition.toState.id,
              readSymbol: transition.readSymbol,
              writeSymbol: transition.writeSymbol,
              moveDirection: _convertTapeDirection(transition.direction),
            ),
          )
          .toList(),
      initialStateId: tm.initialState?.id ?? '',
      acceptingStateIds: tm.acceptingStates.map((state) => state.id).toSet(),
      rejectingStateIds: const <String>{},
      nextStateIndex: tm.states.length,
    );
  }

  String _formatPdaTransitionLabel(PDATransition transition) {
    final read = normalizeToEpsilon(
      transition.isLambdaInput ? '' : transition.inputSymbol,
    );
    final pop = normalizeToEpsilon(
      transition.isLambdaPop ? '' : transition.popSymbol,
    );
    final push = normalizeToEpsilon(
      transition.isLambdaPush ? '' : transition.pushSymbol,
    );
    return '$read,$pop->$push';
  }

  TuringMoveDirection _convertTapeDirection(TapeDirection direction) {
    switch (direction) {
      case TapeDirection.left:
        return TuringMoveDirection.left;
      case TapeDirection.right:
        return TuringMoveDirection.right;
      case TapeDirection.stay:
        return TuringMoveDirection.stay;
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

    if (normalized.contains('could not access')) {
      return ImportErrorType.inaccessibleFile;
    }
    if (normalized.contains('corrupt') ||
        normalized.contains('unreadable') ||
        normalized.contains('readable data')) {
      return ImportErrorType.corruptedData;
    }
    if (normalized.contains('json')) {
      return ImportErrorType.invalidJSON;
    }
    if (normalized.contains('version')) {
      return ImportErrorType.unsupportedVersion;
    }
    if (normalized.contains('xml') ||
        normalized.contains('jflap') ||
        normalized.contains('parse')) {
      return ImportErrorType.malformedJFF;
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
      case ImportErrorType.inaccessibleFile:
        return 'JFlutter could not access the selected file. Pick it again from the system dialog and keep it available until the import finishes.';
      case ImportErrorType.corruptedData:
        return 'The file appears to be corrupted or unreadable. Restore a valid backup before importing again.';
      case ImportErrorType.invalidAutomaton:
        return 'The automaton definition is inconsistent. Review the transitions and states before retrying the import.';
    }
  }

  bool _isCriticalImportError(String message) {
    final normalized = message.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final isJsonFailure = normalized.contains('json') &&
        (normalized.contains('invalid') ||
            normalized.contains('malformed') ||
            normalized.contains('parse'));

    return normalized.contains('xml') ||
        normalized.contains('json') ||
        normalized.contains('parse') ||
        normalized.contains('malformed') ||
        normalized.contains('version') ||
        normalized.contains('could not access') ||
        normalized.contains('invalid') ||
        isJsonFailure ||
        normalized.contains('corrupt') ||
        normalized.contains('unreadable') ||
        normalized.contains('readable data');
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

  void _showOperationCancelledMessage(String message) {
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
    StackTrace? stackTrace,
  }) {
    if (stackTrace != null) {
      debugPrintStack(label: message, stackTrace: stackTrace);
    }

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
