import 'dart:async';
import 'package:flutter/material.dart';
import '../models/nfa.dart';
import '../models/dfa.dart';
import '../models/state_model.dart';
import '../services/nfa_to_dfa_converter.dart';

class ConversionProvider with ChangeNotifier {
  late final EnhancedNFAToDFAConverter _converter;

  bool _isConverting = false;
  double _conversionProgress = 0.0;
  String _currentStepMessage = '';
  List<dynamic> _conversionLog = [];
  ConversionResult? _conversionResult;
  bool _isNewLogAdded = false;

  // Getters
  bool get isConverting => _isConverting;
  double get conversionProgress => _conversionProgress;
  String get currentStepMessage => _currentStepMessage;
  List<dynamic> get conversionLog => List.unmodifiable(_conversionLog);
  ConversionResult? get conversionResult => _conversionResult;
  bool get isNewLogAdded => _isNewLogAdded;

  ConversionProvider() {
    _converter = EnhancedNFAToDFAConverter(
      config: ConversionProfileManager.getProfile('متعادل'),
      onProgress: (message, progress) {
        _updateProgress(message, progress);
      },
    );
  }

  Future<void> startConversion(NFA nfa) async {
    _isConverting = true;
    _conversionProgress = 0.0;
    _currentStepMessage = 'آماده‌سازی برای تبدیل پیشرفته...';
    _conversionLog = [];
    _conversionResult = null;
    notifyListeners();

    try {
      final (dfa, report) = await _converter.convertWithEnhancedReport(nfa);

      _conversionResult = ConversionResult.success(
        nfa: nfa,
        dfa: dfa,
        steps: report.conversionSteps
            .map((s) => DetailedStep.fromString(s))
            .toList(),
        warnings: report.warnings,
        processingTime: report.conversionTime,
      );

      _currentStepMessage =
          'تبدیل با موفقیت در ${report.conversionTime.inMilliseconds}ms انجام شد.';
    } catch (e) {
      _conversionResult = ConversionResult.error(e.toString());
      _currentStepMessage = e.toString();
    }

    _isConverting = false;
    _conversionProgress = 1.0;
    notifyListeners();
  }

  void _updateProgress(String message, double progress) {
    _currentStepMessage = message;
    _conversionProgress = progress;
    _conversionLog.add(message);
    _isNewLogAdded = true;
    notifyListeners();
  }

  void logWasDisplayed() {
    _isNewLogAdded = false;
  }

  void cancelConversion() {
    _isConverting = false;
    _currentStepMessage = 'عملیات لغو شد.';
    notifyListeners();
  }
}

class ConversionResult {
  final bool isSuccess;
  final String? errorMessage;
  final NFA? nfa;
  final DFA? dfa;
  final List<DetailedStep> steps;
  final List<String> warnings;
  final Duration? processingTime;

  ConversionResult.success({
    this.nfa,
    this.dfa,
    this.steps = const [],
    this.warnings = const [],
    this.processingTime,
  })  : isSuccess = true,
        errorMessage = null;

  ConversionResult.error(this.errorMessage)
      : isSuccess = false,
        nfa = null,
        dfa = null,
        steps = [],
        warnings = [],
        processingTime = null;
}

class DetailedStep {
  final int stepNumber;
  final String stateName;
  final StateSet currentState;
  final Map<String, StateSet> transitions;

  DetailedStep({
    required this.stepNumber,
    required this.stateName,
    required this.currentState,
    this.transitions = const {},
  });

  factory DetailedStep.fromString(String stepString) {
    return DetailedStep(
      stepNumber: 0,
      stateName: stepString,
      currentState: StateSet({}),
    );
  }
}
