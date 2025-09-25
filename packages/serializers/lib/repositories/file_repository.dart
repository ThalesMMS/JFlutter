import 'dart:io';
import 'dart:convert';
import '../models/jflap_file.dart';
import '../models/example_library.dart';
import '../serializers/json_serializer.dart';
import '../serializers/jff_serializer.dart';

/// Repository for file I/O operations with automaton models
class FileRepository {
  /// Import automaton from JSON file
  static Future<Map<String, dynamic>> importFromJSON(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json;
    } catch (e) {
      throw FileRepositoryException('Failed to import JSON from $filePath: $e');
    }
  }

  /// Export automaton to JSON file
  static Future<void> exportToJSON(
    Map<String, dynamic> data,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);
    } catch (e) {
      throw FileRepositoryException('Failed to export JSON to $filePath: $e');
    }
  }

  /// Import JFLAP file (.jff)
  static Future<JFLAPFile> importJFLAPFile(String filePath) async {
    try {
      return await JFFSerializer.importFromFile(filePath);
    } catch (e) {
      throw FileRepositoryException('Failed to import JFLAP file from $filePath: $e');
    }
  }

  /// Export JFLAP file (.jff)
  static Future<void> exportJFLAPFile(
    JFLAPFile jflapFile,
    String filePath,
  ) async {
    try {
      await JFFSerializer.exportToFile(jflapFile, filePath);
    } catch (e) {
      throw FileRepositoryException('Failed to export JFLAP file to $filePath: $e');
    }
  }

  /// Import example library
  static Future<ExampleLibrary> importExampleLibrary(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ExampleLibrary.fromJson(json);
    } catch (e) {
      throw FileRepositoryException('Failed to import example library from $filePath: $e');
    }
  }

  /// Export example library
  static Future<void> exportExampleLibrary(
    ExampleLibrary library,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      final jsonString = jsonEncode(library.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw FileRepositoryException('Failed to export example library to $filePath: $e');
    }
  }

  /// List files in directory with specific extensions
  static Future<List<String>> listFiles(
    String directoryPath,
    List<String> extensions,
  ) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }

      final files = <String>[];
      await for (final entity in directory.list()) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (extensions.contains(extension)) {
            files.add(entity.path);
          }
        }
      }
      return files;
    } catch (e) {
      throw FileRepositoryException('Failed to list files in $directoryPath: $e');
    }
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      throw FileRepositoryException('Failed to get file size for $filePath: $e');
    }
  }

  /// Create directory if it doesn't exist
  static Future<void> createDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      throw FileRepositoryException('Failed to create directory $directoryPath: $e');
    }
  }

  /// Delete file
  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw FileRepositoryException('Failed to delete file $filePath: $e');
    }
  }

  /// Copy file
  static Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final destinationFile = File(destinationPath);
      
      // Create destination directory if it doesn't exist
      final destinationDir = Directory(destinationFile.parent.path);
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }
      
      await sourceFile.copy(destinationPath);
    } catch (e) {
      throw FileRepositoryException('Failed to copy file from $sourcePath to $destinationPath: $e');
    }
  }

  /// Move file
  static Future<void> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final destinationFile = File(destinationPath);
      
      // Create destination directory if it doesn't exist
      final destinationDir = Directory(destinationFile.parent.path);
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }
      
      await sourceFile.rename(destinationPath);
    } catch (e) {
      throw FileRepositoryException('Failed to move file from $sourcePath to $destinationPath: $e');
    }
  }
}

/// File repository exception
class FileRepositoryException implements Exception {
  final String message;
  FileRepositoryException(this.message);
  
  @override
  String toString() => 'FileRepositoryException: $message';
}
