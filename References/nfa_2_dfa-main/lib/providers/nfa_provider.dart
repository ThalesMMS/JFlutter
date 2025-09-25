import 'package:flutter/material.dart';
import '../models/nfa.dart';
import '../services/file_service.dart';

class RecentProject {
  final String id;
  final String name;
  final DateTime lastModified;
  final Map<String, dynamic> nfaJson;

  RecentProject({
    required this.id,
    required this.name,
    required this.lastModified,
    required this.nfaJson,
  });
}

class NFAProvider with ChangeNotifier {

  NFA _currentNFA = NFA.empty();

  final FileService _fileService = FileService();

  final List<RecentProject> _recentProjects = [];

  bool _isInitializing = false;
  bool _hasCriticalError = false;
  String? _criticalError;

  NFA get currentNFA => _currentNFA;
  List<RecentProject> get recentProjects => List.unmodifiable(_recentProjects);
  bool get isInitializing => _isInitializing;
  bool get hasCriticalError => _hasCriticalError;
  String? get criticalError => _criticalError;

  void loadNfa(NFA nfa) {
    _currentNFA = nfa;
    notifyListeners();
  }

  void createNewNFA() {
    _currentNFA = NFA.empty();
    notifyListeners();
  }

  Future<bool> loadNFAFromFile() async {
    final result = await _fileService.loadNfaFromFile();

    if (result.success && result.data != null) {
      _currentNFA = result.data!;

      _addOrUpdateRecentProject('پروژه بارگذاری شده', _currentNFA.toJson());
      notifyListeners();
      return true;
    }
    return false;
  }

  void addState(String name) {
    _currentNFA.addState(name);
    notifyListeners();
  }

  void removeState(String name) {
    _currentNFA.removeState(name);
    notifyListeners();
  }

  void setStartState(String name) {
    _currentNFA.setStartState(name);
    notifyListeners();
  }

  void toggleFinalState(String name) {
    _currentNFA.toggleFinalState(name);
    notifyListeners();
  }

  void addSymbol(String symbol) {
    _currentNFA.addSymbol(symbol);
    notifyListeners();
  }

  void removeSymbol(String symbol) {
    _currentNFA.removeSymbol(symbol);
    notifyListeners();
  }

  void addTransition(String from, String symbol, String to) {
    _currentNFA.addTransition(from, symbol, to);
    notifyListeners();
  }

  void removeTransition(String from, String symbol, String to) {
    _currentNFA.removeTransition(from, symbol, to);
    notifyListeners();
  }

  void clearTransitions() {
    _currentNFA.clearTransitions();
    notifyListeners();
  }

  void clear() {
    _currentNFA.clear();
    notifyListeners();
  }

  Future<void> loadRecentProjects() async {
    _isInitializing = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _isInitializing = false;
    notifyListeners();
  }

  void _addOrUpdateRecentProject(String name, Map<String, dynamic> nfaJson) {
    final newProject = RecentProject(
      id: DateTime.now().toIso8601String(),
      name: name,
      lastModified: DateTime.now(),
      nfaJson: nfaJson,
    );
    _recentProjects.insert(0, newProject);

    if (_recentProjects.length > 10) {
      _recentProjects.removeLast();
    }
    notifyListeners();
  }

  void loadRecentProject(String id) {
    final project = _recentProjects.firstWhere((p) => p.id == id, orElse: () => throw Exception('پروژه یافت نشد'));
    _currentNFA = NFA.fromJson(project.nfaJson);
    notifyListeners();
  }

  void deleteRecentProject(String id) {
    _recentProjects.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void saveCurrentProject() {
    if (_currentNFA.states.isNotEmpty) {
      _addOrUpdateRecentProject('پروژه ذخیره خودکار', _currentNFA.toJson());
    }
  }

  Future<void> saveNewProject(String name, Map<String, dynamic> nfaJson) async {
    if (name.trim().isEmpty || nfaJson.isEmpty) return;
    _addOrUpdateRecentProject(name, nfaJson);
  }


  void checkExternalChanges() {
  }

  void recoverFromError() {
    _hasCriticalError = false;
    _criticalError = null;
    createNewNFA();
  }

  void resetToDefaults() {
    _hasCriticalError = false;
    _criticalError = null;
    _recentProjects.clear();
    createNewNFA();
  }
}