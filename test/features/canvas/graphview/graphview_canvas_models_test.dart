// ============================================================================
// JFlutter - Suite de Testes
// ----------------------------------------------------------------------------
// Arquivo: test/features/canvas/graphview/graphview_canvas_models_test.dart
// Objetivo: Avaliar modelos de canvas usados pelo GraphView garantindo
// imutabilidade e helpers consistentes.
// Cenários cobertos:
// - Atualização de metadados de arestas via `copyWith`.
// Autoria: Equipe de Qualidade JFlutter.
// ============================================================================

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
