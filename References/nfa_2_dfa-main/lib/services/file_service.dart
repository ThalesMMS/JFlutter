import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/nfa.dart';

class FileOperationResult<T> {
  final bool success;
  final String message;
  final T? data;
  final FileOperationError? error;
  final Map<String, dynamic>? metadata;

  const FileOperationResult({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.metadata,
  });

  factory FileOperationResult.success(
    T data, {
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return FileOperationResult(
      success: true,
      message: message ?? 'عملیات با موفقیت انجام شد',
      data: data,
      metadata: metadata,
    );
  }

  factory FileOperationResult.failure(
    String message, {
    FileOperationError? error,
    Map<String, dynamic>? metadata,
  }) {
    return FileOperationResult(
      success: false,
      message: message,
      error: error,
      metadata: metadata,
    );
  }
}

/// انواع خطای عملیات فایل
enum FileOperationError {
  fileNotFound,
  invalidFormat,
  permissionDenied,
  corruptedData,
  unsupportedVersion,
  networkError,
  insufficientSpace,
  userCancelled,
  unknown,
}

/// اطلاعات فایل NFA
class NFAFileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;
  final String version;
  final String description;
  final int stateCount;
  final int transitionCount;
  final String checksum;

  const NFAFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
    required this.version,
    required this.description,
    required this.stateCount,
    required this.transitionCount,
    required this.checksum,
  });

  factory NFAFileInfo.fromFile(File file, NFA nfa) {
    final stat = file.statSync();
    return NFAFileInfo(
      name: p.basenameWithoutExtension(file.path),
      path: file.path,
      size: stat.size,
      lastModified: stat.modified,
      version: '2.0',
      description: nfa.description,
      stateCount: nfa.stateCount,
      transitionCount: nfa.transitionCount,
      checksum: _calculateChecksum(file),
    );
  }

  static String _calculateChecksum(File file) {
    final content = file.readAsBytesSync();
    return content.fold(0, (prev, byte) => prev + byte).toString();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'size': size,
    'lastModified': lastModified.toIso8601String(),
    'version': version,
    'description': description,
    'stateCount': stateCount,
    'transitionCount': transitionCount,
    'checksum': checksum,
  };
}

/// سرویس پیشرفته مدیریت فایل‌های NFA
class FileService {
  static const String _defaultExtension = 'json';
  static const String _backupExtension = 'bak';
  static const int _maxFileSize = 50 * 1024 * 1024; // 50MB
  static const List<String> _supportedVersions = ['1.0', '2.0'];

  // تنظیمات پیش‌فرض
  static String defaultDirectory = '';
  static bool autoBackup = true;
  static bool validateOnLoad = true;
  static bool compressFiles = false;

  /// بارگذاری NFA از فایل JSON با اعتبارسنجی کامل
  Future<FileOperationResult<NFA>> loadNfaFromFile({
    String? filePath,
    bool validate = true,
  }) async {
    try {
      File? file;

      if (filePath != null) {
        file = File(filePath);
        if (!await file.exists()) {
          return FileOperationResult.failure(
            'فایل مشخص شده وجود ندارد: $filePath',
            error: FileOperationError.fileNotFound,
          );
        }
      } else {
        // باز کردن دیالوگ انتخاب فایل
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [_defaultExtension],
          dialogTitle: 'انتخاب فایل NFA',
          initialDirectory: defaultDirectory,
          lockParentWindow: true,
        );

        if (result == null || result.files.single.path == null) {
          return FileOperationResult.failure(
            'انتخاب فایل لغو شد',
            error: FileOperationError.userCancelled,
          );
        }

        file = File(result.files.single.path!);
      }

      // بررسی سایز فایل
      final fileSize = await file.length();
      if (fileSize > _maxFileSize) {
        return FileOperationResult.failure(
          'فایل بیش از حد بزرگ است (${_formatFileSize(fileSize)})',
          error: FileOperationError.insufficientSpace,
        );
      }

      if (fileSize == 0) {
        return FileOperationResult.failure(
          'فایل خالی است',
          error: FileOperationError.corruptedData,
        );
      }

      // خواندن محتوای فایل
      final content = await file.readAsString();

      // پردازش JSON
      final Map<String, dynamic> jsonMap;
      try {
        jsonMap = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        return FileOperationResult.failure(
          'فرمت JSON نامعتبر است: ${e.toString()}',
          error: FileOperationError.invalidFormat,
        );
      }

      // بررسی نسخه
      final version = jsonMap['version']?.toString() ?? '1.0';
      if (!_supportedVersions.contains(version)) {
        return FileOperationResult.failure(
          'نسخه فایل ($version) پشتیبانی نمی‌شود',
          error: FileOperationError.unsupportedVersion,
        );
      }

      // بررسی وجود فیلدهای ضروری
      final requiredFields = [
        'states',
        'alphabet',
        'startState',
        'finalStates',
        'transitions',
      ];
      for (final field in requiredFields) {
        if (!jsonMap.containsKey(field)) {
          return FileOperationResult.failure(
            'فیلد ضروری "$field" در فایل موجود نیست',
            error: FileOperationError.corruptedData,
          );
        }
      }

      // تبدیل به شیء NFA
      final NFA nfa;
      try {
        nfa = NFA.fromJson(jsonMap);
      } catch (e) {
        return FileOperationResult.failure(
          'خطا در تبدیل داده‌ها به NFA: ${e.toString()}',
          error: FileOperationError.corruptedData,
        );
      }

      // اعتبارسنجی NFA
      if (validate && validateOnLoad) {
        final validationResult = nfa.validate();
        if (!validationResult.isValid) {
          return FileOperationResult.failure(
            'NFA بارگذاری شده نامعتبر است: ${validationResult.errors.join(', ')}',
            error: FileOperationError.corruptedData,
            metadata: {
              'validation_errors': validationResult.errors,
              'validation_warnings': validationResult.warnings,
            },
          );
        }
      }

      final metadata = {
        'file_path': file.path,
        'file_size': fileSize,
        'load_time': DateTime.now().toIso8601String(),
        'version': version,
        'state_count': nfa.stateCount,
        'transition_count': nfa.transitionCount,
      };

      return FileOperationResult.success(
        nfa,
        message: 'NFA با موفقیت از فایل "${p.basename(file.path)}" بارگذاری شد',
        metadata: metadata,
      );
    } catch (e) {
      return FileOperationResult.failure(
        'خطای غیرمنتظره در بارگذاری فایل: ${e.toString()}',
        error: FileOperationError.unknown,
      );
    }
  }

  /// ذخیره NFA در فایل JSON با قابلیت‌های پیشرفته
  Future<FileOperationResult<String>> saveNfaToFile(
    NFA nfa,
    String fileName, {
    String? directoryPath,
    bool createBackup = true,
    bool validate = true,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // اعتبارسنجی NFA
      if (validate) {
        final validationResult = nfa.validate();
        if (!validationResult.isValid) {
          return FileOperationResult.failure(
            'NFA نامعتبر است و قابل ذخیره نیست: ${validationResult.errors.join(', ')}',
            error: FileOperationError.corruptedData,
          );
        }
      }

      // انتخاب مسیر ذخیره
      String? outputPath = directoryPath;
      if (outputPath == null) {
        outputPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'انتخاب پوشه برای ذخیره فایل',
          initialDirectory: defaultDirectory,
          lockParentWindow: true,
        );

        if (outputPath == null) {
          return FileOperationResult.failure(
            'انتخاب پوشه لغو شد',
            error: FileOperationError.userCancelled,
          );
        }
      }

      // تنظیم نام فایل
      final cleanFileName = _sanitizeFileName(fileName);
      final filePath = p.join(outputPath, '$cleanFileName.$_defaultExtension');
      final file = File(filePath);

      // ایجاد پشتیبان از فایل موجود
      if (createBackup && autoBackup && await file.exists()) {
        final backupResult = await _createBackup(file);
        if (!backupResult.success) {
          return FileOperationResult.failure(
            'خطا در ایجاد پشتیبان: ${backupResult.message}',
            error: backupResult.error,
          );
        }
      }

      // تبدیل NFA به JSON
      final nfaJson = nfa.toJson();

      // اضافه کردن metadata اضافی
      if (additionalMetadata != null) {
        nfaJson['additionalMetadata'] = additionalMetadata;
      }

      // اضافه کردن اطلاعات ذخیره‌سازی
      nfaJson['saveInfo'] = {
        'savedAt': DateTime.now().toIso8601String(),
        'savedBy': 'NFA Editor',
        'fileVersion': '2.0',
      };

      // تبدیل به رشته JSON با فرمت زیبا
      final jsonString = const JsonEncoder.withIndent('  ').convert(nfaJson);

      // نوشتن در فایل
      await file.writeAsString(jsonString, flush: true);

      // اطلاعات فایل ذخیره شده
      final fileInfo = NFAFileInfo.fromFile(file, nfa);

      final metadata = {
        'file_info': fileInfo.toJson(),
        'save_time': DateTime.now().toIso8601String(),
        'file_size': await file.length(),
        'backup_created': createBackup && autoBackup,
      };

      return FileOperationResult.success(
        filePath,
        message: 'NFA با موفقیت در "${p.basename(filePath)}" ذخیره شد',
        metadata: metadata,
      );
    } catch (e) {
      return FileOperationResult.failure(
        'خطای غیرمنتظره در ذخیره فایل: ${e.toString()}',
        error: FileOperationError.unknown,
      );
    }
  }

  /// بارگذاری چندین فایل NFA به صورت همزمان
  Future<FileOperationResult<List<NFA>>> loadMultipleNfaFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [_defaultExtension],
        allowMultiple: true,
        dialogTitle: 'انتخاب فایل‌های NFA',
        initialDirectory: defaultDirectory,
        lockParentWindow: true,
      );

      if (result == null || result.files.isEmpty) {
        return FileOperationResult.failure(
          'هیچ فایلی انتخاب نشد',
          error: FileOperationError.userCancelled,
        );
      }

      final nfaList = <NFA>[];
      final errors = <String>[];
      final loadedFiles = <String>[];

      for (final platformFile in result.files) {
        if (platformFile.path != null) {
          final loadResult = await loadNfaFromFile(
            filePath: platformFile.path!,
          );
          if (loadResult.success && loadResult.data != null) {
            nfaList.add(loadResult.data!);
            loadedFiles.add(p.basename(platformFile.path!));
          } else {
            errors.add(
              '${p.basename(platformFile.path!)}: ${loadResult.message}',
            );
          }
        }
      }

      if (nfaList.isEmpty) {
        return FileOperationResult.failure(
          'هیچ فایل معتبری بارگذاری نشد:\n${errors.join('\n')}',
          error: FileOperationError.corruptedData,
        );
      }

      final metadata = {
        'total_files': result.files.length,
        'loaded_files': nfaList.length,
        'failed_files': errors.length,
        'loaded_file_names': loadedFiles,
        'errors': errors,
      };

      String message = '${nfaList.length} فایل NFA بارگذاری شد';
      if (errors.isNotEmpty) {
        message += ' (${errors.length} فایل با خطا مواجه شد)';
      }

      return FileOperationResult.success(
        nfaList,
        message: message,
        metadata: metadata,
      );
    } catch (e) {
      return FileOperationResult.failure(
        'خطا در بارگذاری چندین فایل: ${e.toString()}',
        error: FileOperationError.unknown,
      );
    }
  }

  /// ذخیره چندین NFA در فایل‌های جداگانه
  Future<FileOperationResult<List<String>>> saveMultipleNfaFiles(
    List<NFA> nfaList, {
    String? directoryPath,
    String prefix = 'nfa',
  }) async {
    try {
      if (nfaList.isEmpty) {
        return FileOperationResult.failure(
          'فهرست NFA خالی است',
          error: FileOperationError.corruptedData,
        );
      }

      String? outputPath = directoryPath;
      if (outputPath == null) {
        outputPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'انتخاب پوشه برای ذخیره فایل‌ها',
          initialDirectory: defaultDirectory,
          lockParentWindow: true,
        );

        if (outputPath == null) {
          return FileOperationResult.failure(
            'انتخاب پوشه لغو شد',
            error: FileOperationError.userCancelled,
          );
        }
      }

      final savedFiles = <String>[];
      final errors = <String>[];

      for (int i = 0; i < nfaList.length; i++) {
        final nfa = nfaList[i];
        final fileName = nfa.name.isNotEmpty ? nfa.name : '${prefix}_${i + 1}';

        final saveResult = await saveNfaToFile(
          nfa,
          fileName,
          directoryPath: outputPath,
          createBackup: false,
        );

        if (saveResult.success && saveResult.data != null) {
          savedFiles.add(saveResult.data!);
        } else {
          errors.add('$fileName: ${saveResult.message}');
        }
      }

      if (savedFiles.isEmpty) {
        return FileOperationResult.failure(
          'هیچ فایلی ذخیره نشد:\n${errors.join('\n')}',
          error: FileOperationError.unknown,
        );
      }

      final metadata = {
        'total_nfas': nfaList.length,
        'saved_files': savedFiles.length,
        'failed_saves': errors.length,
        'saved_file_paths': savedFiles,
        'errors': errors,
      };

      String message = '${savedFiles.length} فایل NFA ذخیره شد';
      if (errors.isNotEmpty) {
        message += ' (${errors.length} فایل با خطا مواجه شد)';
      }

      return FileOperationResult.success(
        savedFiles,
        message: message,
        metadata: metadata,
      );
    } catch (e) {
      return FileOperationResult.failure(
        'خطا در ذخیره چندین فایل: ${e.toString()}',
        error: FileOperationError.unknown,
      );
    }
  }

  /// صادرات NFA به فرمت‌های مختلف
  Future<FileOperationResult<String>> exportNfa(
    NFA nfa,
    String fileName,
    ExportFormat format, {
    String? directoryPath,
  }) async {
    try {
      String? outputPath = directoryPath;
      if (outputPath == null) {
        outputPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'انتخاب پوشه برای صادرات',
          initialDirectory: defaultDirectory,
        );

        if (outputPath == null) {
          return FileOperationResult.failure(
            'انتخاب پوشه لغو شد',
            error: FileOperationError.userCancelled,
          );
        }
      }

      final cleanFileName = _sanitizeFileName(fileName);
      final extension = _getExtensionForFormat(format);
      final filePath = p.join(outputPath, '$cleanFileName.$extension');

      final content = _generateContentForFormat(nfa, format);
      await File(filePath).writeAsString(content);

      return FileOperationResult.success(
        filePath,
        message: 'NFA به فرمت $format صادر شد',
        metadata: {'format': format.toString(), 'file_size': content.length},
      );
    } catch (e) {
      return FileOperationResult.failure(
        'خطا در صادرات: ${e.toString()}',
        error: FileOperationError.unknown,
      );
    }
  }

  /// بازیابی فایل‌های پشتیبان
  Future<FileOperationResult<List<File>>> findBackupFiles(
    String originalFilePath,
  ) async {
    try {
      final originalFile = File(originalFilePath);
      final directory = originalFile.parent;
      final baseName = p.basenameWithoutExtension(originalFilePath);

      final backupFiles = <File>[];
      await for (final entity in directory.list()) {
        if (entity is File &&
            entity.path.contains('$baseName.$_backupExtension')) {
          backupFiles.add(entity);
        }
      }

      backupFiles.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );

      return FileOperationResult.success(
        backupFiles,
        message: '${backupFiles.length} فایل پشتیبان یافت شد',
      );
    } catch (e) {
      return FileOperationResult.failure(
        'خطا در جستجوی فایل‌های پشتیبان: ${e.toString()}',
        error: FileOperationError.unknown,
      );
    }
  }

  Future<FileOperationResult<String>> _createBackup(File originalFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${originalFile.path}.$timestamp.$_backupExtension';
      await originalFile.copy(backupPath);

      return FileOperationResult.success(
        backupPath,
        message: 'پشتیبان ایجاد شد',
      );
    } catch (e) {
      return FileOperationResult.failure(
        'خطا در ایجاد پشتیبان: ${e.toString()}',
        error: FileOperationError.unknown,
      );
    }
  }

  String _sanitizeFileName(String fileName) {
    // حذف کاراکترهای نامعتبر برای نام فایل
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getExtensionForFormat(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'json';
      case ExportFormat.dot:
        return 'dot';
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.xml:
        return 'xml';
      case ExportFormat.yaml:
        return 'yaml';
    }
  }

  String _generateContentForFormat(NFA nfa, ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return const JsonEncoder.withIndent('  ').convert(nfa.toJson());
      case ExportFormat.dot:
        return _generateDotFormat(nfa);
      case ExportFormat.csv:
        return _generateCsvFormat(nfa);
      case ExportFormat.xml:
        return _generateXmlFormat(nfa);
      case ExportFormat.yaml:
        return _generateYamlFormat(nfa);
    }
  }

  String _generateDotFormat(NFA nfa) {
    final buffer = StringBuffer();
    buffer.writeln('digraph NFA {');
    buffer.writeln('  rankdir=LR;');
    buffer.writeln('  node [shape=circle];');

    // حالات پایانی
    if (nfa.finalStates.isNotEmpty) {
      buffer.writeln(
        '  node [shape=doublecircle]; ${nfa.finalStates.join(' ')};',
      );
      buffer.writeln('  node [shape=circle];');
    }

    // نقطه شروع
    buffer.writeln('  start [shape=point];');
    buffer.writeln('  start -> ${nfa.startState};');

    // انتقال‌ها
    for (final fromState in nfa.transitions.keys) {
      for (final symbol in nfa.transitions[fromState]!.keys) {
        for (final toState in nfa.transitions[fromState]![symbol]!) {
          final label = symbol == NFA.epsilon ? 'ε' : symbol;
          buffer.writeln('  $fromState -> $toState [label="$label"];');
        }
      }
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _generateCsvFormat(NFA nfa) {
    final buffer = StringBuffer();
    buffer.writeln('From State,Symbol,To State');

    for (final fromState in nfa.transitions.keys) {
      for (final symbol in nfa.transitions[fromState]!.keys) {
        for (final toState in nfa.transitions[fromState]![symbol]!) {
          buffer.writeln('$fromState,$symbol,$toState');
        }
      }
    }

    return buffer.toString();
  }

  String _generateXmlFormat(NFA nfa) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<nfa name="${nfa.name}">');
    buffer.writeln('  <states>');
    for (final state in nfa.states) {
      final isStart = state == nfa.startState ? ' start="true"' : '';
      final isFinal = nfa.finalStates.contains(state) ? ' final="true"' : '';
      buffer.writeln('    <state name="$state"$isStart$isFinal/>');
    }
    buffer.writeln('  </states>');
    buffer.writeln('  <alphabet>');
    for (final symbol in nfa.alphabet) {
      buffer.writeln('    <symbol>$symbol</symbol>');
    }
    buffer.writeln('  </alphabet>');
    buffer.writeln('  <transitions>');
    for (final fromState in nfa.transitions.keys) {
      for (final symbol in nfa.transitions[fromState]!.keys) {
        for (final toState in nfa.transitions[fromState]![symbol]!) {
          buffer.writeln(
            '    <transition from="$fromState" symbol="$symbol" to="$toState"/>',
          );
        }
      }
    }
    buffer.writeln('  </transitions>');
    buffer.writeln('</nfa>');
    return buffer.toString();
  }

  String _generateYamlFormat(NFA nfa) {
    final buffer = StringBuffer();
    buffer.writeln('name: "${nfa.name}"');
    buffer.writeln('description: "${nfa.description}"');
    buffer.writeln('states:');
    for (final state in nfa.states) {
      buffer.writeln('  - "$state"');
    }
    buffer.writeln('alphabet:');
    for (final symbol in nfa.alphabet) {
      buffer.writeln('  - "$symbol"');
    }
    buffer.writeln('start_state: "${nfa.startState}"');
    buffer.writeln('final_states:');
    for (final state in nfa.finalStates) {
      buffer.writeln('  - "$state"');
    }
    buffer.writeln('transitions:');
    for (final fromState in nfa.transitions.keys) {
      buffer.writeln('  "$fromState":');
      for (final symbol in nfa.transitions[fromState]!.keys) {
        buffer.writeln('    "$symbol":');
        for (final toState in nfa.transitions[fromState]![symbol]!) {
          buffer.writeln('      - "$toState"');
        }
      }
    }
    return buffer.toString();
  }
}

/// فرمت‌های صادرات پشتیبانی شده
enum ExportFormat {
  json,
  dot, // Graphviz DOT format
  csv, // Comma Separated Values
  xml, // XML format
  yaml, // YAML format
}

/// نتیجه اعتبارسنجی
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}
