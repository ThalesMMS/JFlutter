//
//  graphview_canvas_models_test.dart
//  JFlutter
//
//  Verifica os modelos de dados utilizados pelo canvas GraphView, confirmando a imutabilidade e a
//  correta propagação de metadados de transições. Exercita métodos utilitários como copyWith para
//  garantir que updates mantenham integridade do grafo.
//
//  Thales Matheus Mendonça Santos - October 2025
//

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
