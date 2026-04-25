part of '../file_operations_panel.dart';

extension _FileOperationsPanelMachineActions on _FileOperationsPanelState {
  Future<void> _performTextFileAction({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    required String Function() contentsProvider,
    required Future<StringResult> Function(String targetName) webSaveCall,
    required Future<StringResult> Function(String path) writeToPath,
    required String cancelMessage,
    required String Function(Result<String> result) successMessageBuilder,
    required String failureMessagePrefix,
    required String errorMessagePrefix,
    required Future<void> Function() retryOperation,
  }) async {
    _updatePanelState(() => _isLoading = true);

    try {
      Result<String>? result;

      if (kIsWeb) {
        result = await webSaveCall(fileName);
      } else {
        result = await _saveTextFileWithPicker(
          dialogTitle: dialogTitle,
          fileName: fileName,
          allowedExtensions: allowedExtensions,
          contents: contentsProvider(),
          writeToPath: writeToPath,
          cancelMessage: cancelMessage,
        );

        if (result == null) {
          return;
        }
      }

      if (result.isSuccess) {
        _showSuccessMessage(successMessageBuilder(result));
      } else {
        final error = result.error?.trim();
        final failureMessage = error == null || error.isEmpty
            ? failureMessagePrefix
            : '$failureMessagePrefix: $error';
        _showErrorMessage(
          failureMessage,
          retryOperation: retryOperation,
        );
      }
    } catch (e, stackTrace) {
      _showErrorMessage(
        '$errorMessagePrefix: $e',
        retryOperation: retryOperation,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveGrammarAsJFLAP() async {
    if (widget.grammar == null) return;
    final grammar = widget.grammar!;
    final fileName = '${grammar.name}.cfg';

    await _performTextFileAction(
      dialogTitle: 'Save Grammar as JFLAP',
      fileName: fileName,
      allowedExtensions: const ['cfg'],
      contentsProvider: () => _fileService.serializeGrammarToJFLAPString(
        grammar,
      ),
      webSaveCall: (targetName) =>
          _fileService.saveGrammarToJFLAP(grammar, targetName),
      writeToPath: (path) => _fileService.saveGrammarToJFLAP(grammar, path),
      cancelMessage: 'Save canceled.',
      successMessageBuilder: (result) => kIsWeb
          ? 'Download started for ${result.data ?? 'grammar.cfg'}'
          : 'Grammar saved successfully',
      failureMessagePrefix: 'Failed to save grammar',
      errorMessagePrefix: 'Error saving grammar',
      retryOperation: _saveGrammarAsJFLAP,
    );
  }

  Future<void> _loadGrammarFromJFLAP() async {
    _updatePanelState(() => _isLoading = true);

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
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportGrammarAsSVG() async {
    if (widget.grammar == null) return;
    final grammar = widget.grammar!;
    final grammarEntity = _convertGrammarToEntity(grammar);
    final fileName = '${grammar.name}.svg';

    await _performTextFileAction(
      dialogTitle: 'Export Grammar as SVG',
      fileName: fileName,
      allowedExtensions: const ['svg'],
      contentsProvider: () => _fileService.exportGrammarToSvgString(
        grammarEntity,
      ),
      webSaveCall: (targetName) =>
          _fileService.exportGrammarToSVG(grammarEntity, targetName),
      writeToPath: (path) => _fileService.exportGrammarToSVG(
        grammarEntity,
        path,
      ),
      cancelMessage: 'Export canceled.',
      successMessageBuilder: (result) => kIsWeb
          ? 'Download started for ${result.data ?? 'grammar.svg'}'
          : 'Grammar exported successfully',
      failureMessagePrefix: 'Failed to export grammar',
      errorMessagePrefix: 'Error exporting grammar',
      retryOperation: _exportGrammarAsSVG,
    );
  }

  Future<void> _exportPdaAsSVG() async {
    if (widget.pda == null) return;
    final pda = widget.pda!;
    final automatonEntity = _convertPdaToAutomatonEntity(pda);
    final fileName = '${pda.name}.svg';

    await _performTextFileAction(
      dialogTitle: 'Export PDA as SVG',
      fileName: fileName,
      allowedExtensions: const ['svg'],
      contentsProvider: () => _fileService.exportAutomatonToSvgString(
        automatonEntity,
      ),
      webSaveCall: (targetName) =>
          _fileService.exportAutomatonToSVG(automatonEntity, targetName),
      writeToPath: (path) => _fileService.exportAutomatonToSVG(
        automatonEntity,
        path,
      ),
      cancelMessage: 'Export canceled.',
      successMessageBuilder: (result) => kIsWeb
          ? 'Download started for ${result.data ?? 'pda.svg'}'
          : 'PDA exported successfully',
      failureMessagePrefix: 'Failed to export PDA',
      errorMessagePrefix: 'Error exporting PDA',
      retryOperation: _exportPdaAsSVG,
    );
  }

  Future<void> _exportTuringMachineAsSVG() async {
    if (widget.turingMachine == null) return;
    final turingMachine = widget.turingMachine!;
    final tmEntity = _convertTmToEntity(turingMachine);
    final fileName = '${turingMachine.name}.svg';

    await _performTextFileAction(
      dialogTitle: 'Export Turing Machine as SVG',
      fileName: fileName,
      allowedExtensions: const ['svg'],
      contentsProvider: () => _fileService.exportTuringMachineToSvgString(
        tmEntity,
      ),
      webSaveCall: (targetName) =>
          _fileService.exportTuringMachineToSVG(tmEntity, targetName),
      writeToPath: (path) => _fileService.exportTuringMachineToSVG(
        tmEntity,
        path,
      ),
      cancelMessage: 'Export canceled.',
      successMessageBuilder: (result) => kIsWeb
          ? 'Download started for ${result.data ?? 'tm.svg'}'
          : 'Turing machine exported successfully',
      failureMessagePrefix: 'Failed to export Turing machine',
      errorMessagePrefix: 'Error exporting Turing machine',
      retryOperation: _exportTuringMachineAsSVG,
    );
  }
}
