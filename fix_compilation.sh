#!/bin/bash

echo "🚀 Removendo diretórios de testes legados..."
rm -rf test/core
rm -rf test/integration
rm -rf test/unit
rm -rf test/contract

echo "🚀 Removendo arquivos de teste legados..."
rm -f test/core_algorithms_ops_test.dart
rm -f test/core_algorithms_test.dart
rm -f test/core_error_handler_test.dart
rm -f test/core_result_test.dart
rm -f test/dfa_minimization_test.dart
rm -f test/examples_roundtrip_test.dart
rm -f test/ll_lr_parsing_test.dart
rm -f test/nfa_reversal_test.dart
rm -f test/nfa_to_dfa_test.dart
rm -f test/presentation_automaton_provider_test.dart
rm -f test/regex_to_nfa_test.dart

echo "✅ Limpeza dos testes concluída. Apenas 'widget_test.dart' foi mantido."