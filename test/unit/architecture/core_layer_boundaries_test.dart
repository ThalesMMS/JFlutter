import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('core code does not import Flutter', () {
    final flutterImport = RegExp(
      r'''import\s+['"]package:flutter/''',
    );
    final offenders = Directory('lib/core')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => flutterImport.hasMatch(file.readAsStringSync()))
        .map((file) => file.path)
        .toList()
      ..sort();

    expect(offenders, isEmpty);
  });
}
