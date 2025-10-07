//
//  algo_log.dart
//  JFlutter
//
//  Mantém utilitários estáticos para registrar passos de execução de
//  algoritmos, expondo ValueNotifiers que notificam interfaces sobre novas
//  mensagens ou estados destacados. Fornece operações para adicionar linhas,
//  limpar registros e acompanhar destaques durante simulações interativas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/foundation.dart';

/// Centralized logging for algorithm execution steps
class AlgoLog {
  static final ValueNotifier<List<String>> _lines = ValueNotifier<List<String>>(
    [],
  );
  static final ValueNotifier<Set<String>> _highlights =
      ValueNotifier<Set<String>>({});

  /// Stream of log lines
  static ValueNotifier<List<String>> get lines => _lines;

  /// Stream of highlighted states
  static ValueNotifier<Set<String>> get highlights => _highlights;

  /// Adds a log line
  static void addLine(String line) {
    _lines.value = [..._lines.value, line];
  }

  /// Adds multiple log lines
  static void addLines(List<String> lines) {
    _lines.value = [..._lines.value, ...lines];
  }

  /// Clears all log lines
  static void clear() {
    _lines.value = [];
    _highlights.value = {};
  }

  /// Highlights specific states
  static void highlightStates(Set<String> stateIds) {
    _highlights.value = stateIds;
  }

  /// Clears highlights
  static void clearHighlights() {
    _highlights.value = {};
  }

  /// Gets current log lines
  static List<String> get currentLines => _lines.value;

  /// Gets current highlighted states
  static Set<String> get currentHighlights => _highlights.value;
}
