//
//  graphview_canvas_models_test.dart
//  JFlutter
//
//  Testes unitários que asseguram a imutabilidade e os utilitários de cópia dos
//  modelos de canvas empregados pelo GraphView. Os casos verificam atualização
//  de metadados específicos de PDAs por meio de copyWith, garantindo coerência
//  entre símbolos de pilha e indicadores de transições λ.
//
//  Thales Matheus Mendonça Santos - October 2025

import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/features/canvas/graphview/graphview_canvas_models.dart';

void main() {
  group('GraphViewCanvasEdge', () {
    test('copyWith updates PDA metadata fields', () {
      const baseEdge = GraphViewCanvasEdge(
        id: 'edge-1',
        fromStateId: 'q0',
        toStateId: 'q1',
        symbols: ['a'],
        popSymbol: 'A',
        pushSymbol: 'B',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );

      final updated = baseEdge.copyWith(
        popSymbol: 'Z',
        pushSymbol: 'Y',
        isLambdaInput: true,
        isLambdaPop: true,
        isLambdaPush: true,
      );

      expect(updated.popSymbol, 'Z');
      expect(updated.pushSymbol, 'Y');
      expect(updated.isLambdaInput, isTrue);
      expect(updated.isLambdaPop, isTrue);
      expect(updated.isLambdaPush, isTrue);
    });
  });
}
