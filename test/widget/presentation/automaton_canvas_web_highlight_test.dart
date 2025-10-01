@TestOn('browser')
import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas.dart';

void main() {
  testWidgets('forwards highlight events to the embedded iframe', (tester) async {
    final canvasKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutomatonCanvas(
            automaton: null,
            canvasKey: canvasKey,
            onAutomatonChanged: (_) {},
          ),
        ),
      ),
    );

    final state = tester.state<State<AutomatonCanvas>>(
      find.byType(AutomatonCanvas),
    );

    final completer = Completer<Object?>();
    (state as dynamic).debugInterceptPostMessage((Object? message) {
      if (!completer.isCompleted) {
        completer.complete(message);
      }
    });

    final message = {
      'type': 'highlight',
      'payload': {
        'states': ['q0'],
        'transitions': ['t0'],
      },
    };

    html.window.postMessage(message, '*');

    final forwarded = await completer.future
        .timeout(const Duration(seconds: 1), onTimeout: () => null);

    expect(forwarded, equals(message));

    (state as dynamic).debugInterceptPostMessage(null);
  });
}
