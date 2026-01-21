//
//  visualizations_test.dart
//  JFlutter
//
//  Verifica a infraestrutura de testes golden, garantindo que o golden_toolkit
//  esteja corretamente configurado com fontes carregadas via flutter_test_config.
//  Os casos validam renderização básica de widgets, comparação de snapshots
//  visuais e integração com o framework de testes, estabelecendo a base para
//  testes de regressão visual de componentes críticos do canvas e UI.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('Golden test infrastructure verification', () {
    testGoldens('renders simple widget and generates golden file', (
      tester,
    ) async {
      final widget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: Container(
              width: 100,
              height: 100,
              color: Colors.blue,
              child: const Center(
                child: Text(
                  'Golden Test',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'simple_widget_golden');
    });

    testGoldens('verifies font loading for text rendering consistency', (
      tester,
    ) async {
      final widget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'JFlutter',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Golden Test Framework', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'text_rendering_golden');
    });

    testGoldens('verifies Material Design component rendering', (tester) async {
      final widget = MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Golden Test')),
          body: Center(
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'material_components_golden');
    });
  });

  group('Golden test infrastructure - device variations', () {
    testGoldens('renders widget on different device sizes', (tester) async {
      final builder = GoldenBuilder.grid(columns: 2, widthToHeightRatio: 1)
        ..addScenario(
          'Mobile',
          SizedBox(
            width: 200,
            height: 150,
            child: Container(
              color: Colors.grey[200],
              child: const Center(child: Text('Mobile View')),
            ),
          ),
        )
        ..addScenario(
          'Tablet',
          SizedBox(
            width: 200,
            height: 150,
            child: Container(
              color: Colors.grey[300],
              child: const Center(child: Text('Tablet View')),
            ),
          ),
        );

      await tester.pumpWidgetBuilder(builder.build());

      await screenMatchesGolden(tester, 'device_variations_golden');
    });
  });
}
