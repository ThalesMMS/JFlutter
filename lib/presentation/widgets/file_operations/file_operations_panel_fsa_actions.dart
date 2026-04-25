part of '../file_operations_panel.dart';

extension _FileOperationsPanelFsaActions on _FileOperationsPanelState {
  Future<void> _saveAutomatonAsJFLAP() async {
    if (widget.automaton == null) return;
    _updatePanelState(() => _isLoading = true);

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
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAutomatonFromJFLAP() async {
    _updatePanelState(() => _isLoading = true);

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
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAutomatonAsJson() async {
    if (widget.automaton == null) return;
    _updatePanelState(() => _isLoading = true);

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
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAutomatonFromJson() async {
    _updatePanelState(() => _isLoading = true);

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
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportAutomatonAsSVG() async {
    if (widget.automaton == null) return;
    _updatePanelState(() => _isLoading = true);
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
          writeToPath: (path) =>
              _fileService.exportLegacyAutomatonToSVG(widget.automaton!, path),
          cancelMessage: 'Export canceled.',
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
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportAutomatonAsPNG() async {
    if (widget.automaton == null) return;
    _updatePanelState(() => _isLoading = true);

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
        _updatePanelState(() => _isLoading = false);
      }
    }
  }
}
