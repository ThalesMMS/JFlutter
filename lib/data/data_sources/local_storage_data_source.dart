//
//  local_storage_data_source.dart
//  JFlutter
//
//  Controla o armazenamento local de autômatos com SharedPreferences, cuidando de salvar, listar, remover, exportar e importar registros em JSON.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/automaton_model.dart';
import '../../core/result.dart';

/// Data source for local storage operations using SharedPreferences
class LocalStorageDataSource {
  static const String _automatonPrefix = 'automaton_';
  static const String _automatonListKey = 'automaton_list';

  /// Saves an automaton to local storage
  Future<BoolResult> saveAutomaton(AutomatonModel automaton) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_automatonPrefix${automaton.id}';
      final jsonString = jsonEncode(automaton.toJson());

      final success = await prefs.setString(key, jsonString);
      if (success) {
        // Update the list of automaton IDs
        await _updateAutomatonList(automaton.id);
      }

      return success
          ? const Success(true)
          : const Failure('Failed to save automaton');
    } catch (e) {
      return Failure('Error saving automaton: $e');
    }
  }

  /// Loads an automaton from local storage
  Future<Result<AutomatonModel>> loadAutomaton(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_automatonPrefix$id';
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        return const Failure('Automaton not found');
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final automaton = AutomatonModel.fromJson(json);

      return Success(automaton);
    } catch (e) {
      return Failure('Error loading automaton: $e');
    }
  }

  /// Loads all automatons from local storage
  Future<ListResult<AutomatonModel>> loadAllAutomatons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final automatonIds = prefs.getStringList(_automatonListKey) ?? [];

      final automatons = <AutomatonModel>[];
      for (final id in automatonIds) {
        final result = await loadAutomaton(id);
        result.onSuccess((automaton) => automatons.add(automaton));
      }

      return Success(automatons);
    } catch (e) {
      return Failure('Error loading automatons: $e');
    }
  }

  /// Deletes an automaton from local storage
  Future<BoolResult> deleteAutomaton(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_automatonPrefix$id';

      final success = await prefs.remove(key);
      if (success) {
        // Remove from the list of automaton IDs
        await _removeFromAutomatonList(id);
      }

      return success
          ? const Success(true)
          : const Failure('Failed to delete automaton');
    } catch (e) {
      return Failure('Error deleting automaton: $e');
    }
  }

  /// Updates the list of automaton IDs
  Future<void> _updateAutomatonList(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList(_automatonListKey) ?? [];

      if (!currentList.contains(id)) {
        currentList.add(id);
        await prefs.setStringList(_automatonListKey, currentList);
      }
    } catch (e) {
      // Ignore errors in list management
    }
  }

  /// Removes an ID from the automaton list
  Future<void> _removeFromAutomatonList(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList(_automatonListKey) ?? [];

      currentList.remove(id);
      await prefs.setStringList(_automatonListKey, currentList);
    } catch (e) {
      // Ignore errors in list management
    }
  }

  /// Clears all automaton data
  Future<BoolResult> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final automatonIds = prefs.getStringList(_automatonListKey) ?? [];

      for (final id in automatonIds) {
        await prefs.remove('$_automatonPrefix$id');
      }

      await prefs.remove(_automatonListKey);

      return const Success(true);
    } catch (e) {
      return Failure('Error clearing data: $e');
    }
  }

  /// Exports an automaton as JSON string
  Future<StringResult> exportAutomaton(AutomatonModel automaton) async {
    try {
      final jsonString = jsonEncode(automaton.toJson());
      return Success(jsonString);
    } catch (e) {
      return Failure('Error exporting automaton: $e');
    }
  }

  /// Imports an automaton from JSON string
  Future<Result<AutomatonModel>> importAutomaton(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final automaton = AutomatonModel.fromJson(json);

      // Generate new ID to avoid conflicts
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final importedAutomaton = automaton.copyWith(id: newId);

      return Success(importedAutomaton);
    } catch (e) {
      return Failure('Error importing automaton: $e');
    }
  }
}
