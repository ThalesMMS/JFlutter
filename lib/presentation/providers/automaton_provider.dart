import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/result.dart';
import '../../core/use_cases/automaton_use_cases.dart';

/// Provider for managing automaton state and operations
class AutomatonProvider extends ChangeNotifier {
  final CreateAutomatonUseCase _createAutomatonUseCase;
  final LoadAutomatonUseCase _loadAutomatonUseCase;
  final SaveAutomatonUseCase _saveAutomatonUseCase;
  final DeleteAutomatonUseCase _deleteAutomatonUseCase;
  final ExportAutomatonUseCase _exportAutomatonUseCase;
  final ImportAutomatonUseCase _importAutomatonUseCase;
  final ValidateAutomatonUseCase _validateAutomatonUseCase;
  final AddStateUseCase _addStateUseCase;
  final RemoveStateUseCase _removeStateUseCase;
  final AddTransitionUseCase _addTransitionUseCase;
  final RemoveTransitionUseCase _removeTransitionUseCase;

  AutomatonEntity? _currentAutomaton;
  bool _isLoading = false;
  String? _error;
  List<String> _validationErrors = [];
  Set<String> _selectedStates = {};
  // UI interaction mode: connecting states for transition creation
  bool _isConnectingStates = false;
  String? _connectingFromState;

  AutomatonProvider({
    required CreateAutomatonUseCase createAutomatonUseCase,
    required LoadAutomatonUseCase loadAutomatonUseCase,
    required SaveAutomatonUseCase saveAutomatonUseCase,
    required DeleteAutomatonUseCase deleteAutomatonUseCase,
    required ExportAutomatonUseCase exportAutomatonUseCase,
    required ImportAutomatonUseCase importAutomatonUseCase,
    required ValidateAutomatonUseCase validateAutomatonUseCase,
    required AddStateUseCase addStateUseCase,
    required RemoveStateUseCase removeStateUseCase,
    required AddTransitionUseCase addTransitionUseCase,
    required RemoveTransitionUseCase removeTransitionUseCase,
  })  : _createAutomatonUseCase = createAutomatonUseCase,
        _loadAutomatonUseCase = loadAutomatonUseCase,
        _saveAutomatonUseCase = saveAutomatonUseCase,
        _deleteAutomatonUseCase = deleteAutomatonUseCase,
        _exportAutomatonUseCase = exportAutomatonUseCase,
        _importAutomatonUseCase = importAutomatonUseCase,
        _validateAutomatonUseCase = validateAutomatonUseCase,
        _addStateUseCase = addStateUseCase,
        _removeStateUseCase = removeStateUseCase,
        _addTransitionUseCase = addTransitionUseCase,
        _removeTransitionUseCase = removeTransitionUseCase;

  // Getters
  AutomatonEntity? get currentAutomaton => _currentAutomaton;
  Set<String> get selectedStates => _selectedStates;
  bool get isConnectingStates => _isConnectingStates;
  String? get connectingFromState => _connectingFromState;
  
  // Setters
  set currentAutomaton(AutomatonEntity? automaton) {
    _currentAutomaton = automaton;
    notifyListeners();
  }
  set selectedStates(Set<String> states) {
    _selectedStates = states;
    notifyListeners();
  }
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get validationErrors => _validationErrors;

  // Setters
  void setCurrentAutomaton(AutomatonEntity? automaton) {
    _currentAutomaton = automaton;
    notifyListeners();
  }
  bool get hasAutomaton => _currentAutomaton != null;
  bool get isValid => _validationErrors.isEmpty;

  /// Creates a new automaton
  Future<void> createAutomaton({
    required String name,
    required AutomatonType type,
    Set<String> alphabet = const {},
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _createAutomatonUseCase.execute(
      name: name,
      type: type,
      alphabet: alphabet,
    );

    result.onSuccess((automaton) {
      _currentAutomaton = automaton;
      notifyListeners();
    });

    result.onFailure((error) {
      _setError(error);
    });

    _setLoading(false);
  }

  /// Loads an automaton by ID
  Future<void> loadAutomaton(String id) async {
    _setLoading(true);
    _clearError();

    final result = await _loadAutomatonUseCase.execute(id);

    result.onSuccess((automaton) {
      _currentAutomaton = automaton;
      notifyListeners();
    });

    result.onFailure((error) {
      _setError(error);
    });

    _setLoading(false);
  }

  /// Saves the current automaton
  Future<void> saveAutomaton() async {
    if (_currentAutomaton == null) return;

    _setLoading(true);
    _clearError();

    final result = await _saveAutomatonUseCase.execute(_currentAutomaton!);

    result.onSuccess((automaton) {
      _currentAutomaton = automaton;
      notifyListeners();
    });

    result.onFailure((error) {
      _setError(error);
    });

    _setLoading(false);
  }

  /// Deletes an automaton
  Future<void> deleteAutomaton(String id) async {
    _setLoading(true);
    _clearError();

    final result = await _deleteAutomatonUseCase.execute(id);

    result.onSuccess((_) {
      if (_currentAutomaton?.id == id) {
        _currentAutomaton = null;
        notifyListeners();
      }
    });

    result.onFailure((error) {
      _setError(error);
    });

    _setLoading(false);
  }

  /// Exports the current automaton
  Future<String?> exportAutomaton() async {
    if (_currentAutomaton == null) return null;

    _setLoading(true);
    _clearError();

    final result = await _exportAutomatonUseCase.execute(_currentAutomaton!);

    _setLoading(false);

    return result.data;
  }

  /// Imports an automaton from JSON
  Future<void> importAutomaton(String jsonString) async {
    _setLoading(true);
    _clearError();

    final result = await _importAutomatonUseCase.execute(jsonString);

    result.onSuccess((automaton) {
      _currentAutomaton = automaton;
      notifyListeners();
    });

    result.onFailure((error) {
      _setError(error);
    });

    _setLoading(false);
  }

  /// Validates the current automaton
  Future<void> validateAutomaton() async {
    if (_currentAutomaton == null) return;

    _setLoading(true);
    _clearError();

    final result = await _validateAutomatonUseCase.execute(_currentAutomaton!);

    result.onSuccess((isValid) {
      _validationErrors = isValid ? [] : ['Automaton has validation errors'];
      notifyListeners();
    });

    result.onFailure((error) {
      _setError(error);
    });

    _setLoading(false);
  }

  /// Adds a state to the current automaton
  Future<void> addState({
    required String name,
    required double x,
    required double y,
    bool isInitial = false,
    bool isFinal = false,
  }) async {
    if (_currentAutomaton == null) return;

    _setLoading(true);
    _clearError();

    final result = await _addStateUseCase.execute(
      automaton: _currentAutomaton!,
      name: name,
      x: x,
      y: y,
      isInitial: isInitial,
      isFinal: isFinal,
    );

    result.onSuccess((automaton) {
      _currentAutomaton = automaton;
      notifyListeners();
    });

    result.onFailure((error) {
      _setError(error);
    });

    _setLoading(false);
  }

  /// Removes a state from the current automaton
  Future<void> removeState(String stateId) async {
    if (_currentAutomaton == null) return;

    _setLoading(true);
    _clearError();

    final result = await _removeStateUseCase.execute(
      automaton: _currentAutomaton!,
      stateId: stateId,
    );

    result.onSuccess((automaton) {
      _currentAutomaton = automaton;
      notifyListeners();
    });

    result.onFailure((error) {
      _setError(error);
    });

    _setLoading(false);
  }

  /// Adds a transition to the current automaton
  Future<void> addTransition({
    required String fromStateId,
    required String symbol,
    required String toStateId,
  }) async {
    if (_currentAutomaton == null) return;

    _setLoading(true);
    _clearError();

    final result = await _addTransitionUseCase.execute(
      automaton: _currentAutomaton!,
      fromStateId: fromStateId,
      symbol: symbol,
      toStateId: toStateId,
    );

    result.onSuccess((automaton) {
      _currentAutomaton = automaton;
      notifyListeners();
    });

    result.onFailure((error) {
      _setError(error);
    });

    _setLoading(false);
  }

  /// Removes a transition from the current automaton
  Future<void> removeTransition({
    required String fromStateId,
    required String symbol,
    String? toStateId,
  }) async {
    if (_currentAutomaton == null) return;

    _setLoading(true);
    _clearError();

    final result = await _removeTransitionUseCase.execute(
      automaton: _currentAutomaton!,
      fromStateId: fromStateId,
      symbol: symbol,
      toStateId: toStateId,
    );

    result.onSuccess((automaton) {
      _currentAutomaton = automaton;
      notifyListeners();
    });

    result.onFailure((error) {
      _setError(error);
    });

    _setLoading(false);
  }

  /// Clears the current automaton
  void clearAutomaton() {
    _currentAutomaton = null;
    _clearError();
    _validationErrors.clear();
    notifyListeners();
  }

  /// Clears any error state
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // CFG-related methods
  static const String _cfgKey = 'cfg_grammar';

  /// Save CFG grammar to shared preferences
  Future<void> saveCFG(String grammar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cfgKey, grammar);
    } catch (e) {
      _setError('Erro ao salvar gramática CFG: $e');
    }
  }

  /// Load CFG grammar from shared preferences
  String? getSavedCFG() {
    // This is a synchronous method for immediate access
    // In a real implementation, you might want to make this async
    return null; // Placeholder - would need to implement proper loading
  }

  /// Load CFG grammar from shared preferences (async)
  Future<String?> loadCFG() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_cfgKey);
    } catch (e) {
      _setError('Erro ao carregar gramática CFG: $e');
      return null;
    }
  }

  /// Sets the current automaton directly
  void setAutomaton(AutomatonEntity automaton) {
    _currentAutomaton = automaton;
    _clearError();
    _validationErrors.clear();
    notifyListeners();
  }

  /// Clears validation errors
  void clearValidationErrors() {
    _validationErrors.clear();
    notifyListeners();
  }

  /// Sets the selected states
  void setSelectedStates(Set<String> states) {
    _selectedStates = states;
    notifyListeners();
  }

  /// Clears the selected states
  void clearSelectedStates() {
    _selectedStates.clear();
    notifyListeners();
  }

  /// Adds a state to the selection
  void addSelectedState(String stateId) {
    _selectedStates.add(stateId);
    notifyListeners();
  }

  /// Removes a state from the selection
  void removeSelectedState(String stateId) {
    _selectedStates.remove(stateId);
    notifyListeners();
  }

  /// Begin transition creation mode. Optionally set the origin state.
  void startConnecting({String? fromStateId}) {
    _isConnectingStates = true;
    _connectingFromState = fromStateId;
    notifyListeners();
  }

  /// Set the origin state during connecting mode.
  void setConnectingFromState(String stateId) {
    _connectingFromState = stateId;
    notifyListeners();
  }

  /// Finish/Cancel connecting mode.
  void finishConnecting() {
    _isConnectingStates = false;
    _connectingFromState = null;
    notifyListeners();
  }
}
