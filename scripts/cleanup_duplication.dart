#!/usr/bin/env dart

// Script to identify and clean up code duplication in JFlutter
// This script analyzes the codebase for common patterns and suggests consolidations

import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 JFlutter Code Duplication Analysis');
  print('=====================================\n');

  final analysis = await analyzeDuplication();
  printAnalysis(analysis);
  
  print('\n📋 Cleanup Recommendations:');
  printRecommendations(analysis);
}

Future<DuplicationAnalysis> analyzeDuplication() async {
  final analysis = DuplicationAnalysis();
  
  // Analyze repository implementations
  await analyzeRepositoryPatterns(analysis);
  
  // Analyze service patterns
  await analyzeServicePatterns(analysis);
  
  // Analyze provider patterns
  await analyzeProviderPatterns(analysis);
  
  // Analyze test patterns
  await analyzeTestPatterns(analysis);
  
  return analysis;
}

Future<void> analyzeRepositoryPatterns(DuplicationAnalysis analysis) async {
  print('📁 Analyzing Repository Implementations...');
  
  final repositoryFiles = [
    'lib/data/repositories/automaton_repository_impl.dart',
    'lib/data/repositories/algorithm_repository_impl.dart',
    'lib/data/repositories/examples_repository_impl.dart',
    'lib/features/layout/layout_repository_impl.dart',
  ];
  
  final commonPatterns = <String, int>{};
  final errorHandlingPatterns = <String, int>{};
  
  for (final file in repositoryFiles) {
    if (await File(file).exists()) {
      final content = await File(file).readAsString();
      
      // Count common patterns
      if (content.contains('try {')) {
        commonPatterns['try-catch'] = (commonPatterns['try-catch'] ?? 0) + 1;
      }
      
      if (content.contains('Future<')) {
        commonPatterns['async-methods'] = (commonPatterns['async-methods'] ?? 0) + 1;
      }
      
      if (content.contains('catch (e) {')) {
        errorHandlingPatterns['generic-catch'] = (errorHandlingPatterns['generic-catch'] ?? 0) + 1;
      }
      
      if (content.contains('rethrow')) {
        errorHandlingPatterns['rethrow'] = (errorHandlingPatterns['rethrow'] ?? 0) + 1;
      }
    }
  }
  
  analysis.repositoryPatterns = commonPatterns;
  analysis.errorHandlingPatterns = errorHandlingPatterns;
}

Future<void> analyzeServicePatterns(DuplicationAnalysis analysis) async {
  print('🔧 Analyzing Service Implementations...');
  
  final serviceFiles = [
    'lib/data/services/automaton_service.dart',
    'lib/data/services/file_operations_service.dart',
    'lib/data/services/conversion_service.dart',
    'lib/data/services/simulation_service.dart',
  ];
  
  final commonPatterns = <String, int>{};
  
  for (final file in serviceFiles) {
    if (await File(file).exists()) {
      final content = await File(file).readAsString();
      
      if (content.contains('http.')) {
        commonPatterns['http-calls'] = (commonPatterns['http-calls'] ?? 0) + 1;
      }
      
      if (content.contains('jsonEncode')) {
        commonPatterns['json-serialization'] = (commonPatterns['json-serialization'] ?? 0) + 1;
      }
      
      if (content.contains('await')) {
        commonPatterns['async-operations'] = (commonPatterns['async-operations'] ?? 0) + 1;
      }
    }
  }
  
  analysis.servicePatterns = commonPatterns;
}

Future<void> analyzeProviderPatterns(DuplicationAnalysis analysis) async {
  print('🎯 Analyzing Provider Implementations...');
  
  final providerFiles = [
    'lib/presentation/providers/automaton_provider.dart',
    'lib/presentation/providers/algorithm_provider.dart',
    'lib/presentation/providers/grammar_provider.dart',
  ];
  
  final commonPatterns = <String, int>{};
  
  for (final file in providerFiles) {
    if (await File(file).exists()) {
      final content = await File(file).readAsString();
      
      if (content.contains('StateNotifier')) {
        commonPatterns['state-notifier'] = (commonPatterns['state-notifier'] ?? 0) + 1;
      }
      
      if (content.contains('ref.watch')) {
        commonPatterns['ref-watch'] = (commonPatterns['ref-watch'] ?? 0) + 1;
      }
      
      if (content.contains('ref.read')) {
        commonPatterns['ref-read'] = (commonPatterns['ref-read'] ?? 0) + 1;
      }
    }
  }
  
  analysis.providerPatterns = commonPatterns;
}

Future<void> analyzeTestPatterns(DuplicationAnalysis analysis) async {
  print('🧪 Analyzing Test Patterns...');
  
  final testDirectories = [
    'test/unit/',
    'test/integration/',
    'test/widget/',
    'test/contract/',
  ];
  
  final commonPatterns = <String, int>{};
  
  for (final dir in testDirectories) {
    if (await Directory(dir).exists()) {
      final files = await Directory(dir).list().where((f) => f.path.endsWith('.dart')).toList();
      
      for (final file in files) {
        final content = await File(file.path).readAsString();
        
        if (content.contains('test(')) {
          commonPatterns['test-functions'] = (commonPatterns['test-functions'] ?? 0) + 1;
        }
        
        if (content.contains('expect(')) {
          commonPatterns['expect-assertions'] = (commonPatterns['expect-assertions'] ?? 0) + 1;
        }
        
        if (content.contains('setUp(')) {
          commonPatterns['setup-functions'] = (commonPatterns['setup-functions'] ?? 0) + 1;
        }
      }
    }
  }
  
  analysis.testPatterns = commonPatterns;
}

void printAnalysis(DuplicationAnalysis analysis) {
  print('📊 Analysis Results:');
  print('-------------------');
  
  print('\n🏗️ Repository Patterns:');
  analysis.repositoryPatterns.forEach((pattern, count) {
    print('  $pattern: $count occurrences');
  });
  
  print('\n🔧 Service Patterns:');
  analysis.servicePatterns.forEach((pattern, count) {
    print('  $pattern: $count occurrences');
  });
  
  print('\n🎯 Provider Patterns:');
  analysis.providerPatterns.forEach((pattern, count) {
    print('  $pattern: $count occurrences');
  });
  
  print('\n🧪 Test Patterns:');
  analysis.testPatterns.forEach((pattern, count) {
    print('  $pattern: $count occurrences');
  });
  
  print('\n⚠️ Error Handling Patterns:');
  analysis.errorHandlingPatterns.forEach((pattern, count) {
    print('  $pattern: $count occurrences');
  });
}

void printRecommendations(DuplicationAnalysis analysis) {
  print('\n1. 🏗️ Repository Layer Consolidation:');
  print('   - Create a base Repository class with common error handling');
  print('   - Implement generic caching patterns');
  print('   - Standardize async/await error handling');
  
  print('\n2. 🔧 Service Layer Consolidation:');
  print('   - Create a base Service class with HTTP client management');
  print('   - Implement common JSON serialization patterns');
  print('   - Standardize API response handling');
  
  print('\n3. 🎯 Provider Layer Consolidation:');
  print('   - Create base provider mixins for common state management');
  print('   - Implement standard ref.watch/ref.read patterns');
  print('   - Create common state update utilities');
  
  print('\n4. 🧪 Test Layer Consolidation:');
  print('   - Create test utilities and fixtures');
  print('   - Implement common test setup patterns');
  print('   - Standardize assertion helpers');
  
  print('\n5. ⚠️ Error Handling Consolidation:');
  print('   - Create custom exception classes');
  print('   - Implement standard error handling patterns');
  print('   - Create error logging utilities');
  
  print('\n6. 📁 File Organization:');
  print('   - Move common patterns to shared utilities');
  print('   - Create base classes for similar implementations');
  print('   - Implement mixins for shared functionality');
}

class DuplicationAnalysis {
  Map<String, int> repositoryPatterns = {};
  Map<String, int> servicePatterns = {};
  Map<String, int> providerPatterns = {};
  Map<String, int> testPatterns = {};
  Map<String, int> errorHandlingPatterns = {};
}
