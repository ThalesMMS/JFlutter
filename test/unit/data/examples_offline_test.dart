import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/data/data_sources/examples_asset_data_source.dart';

class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError(
        'Network access is not allowed in offline examples tests.');
  }
}

class _AssetBundleHarness {
  _AssetBundleHarness({
    this.overrides = const {},
    this.missingAssets = const {},
  });

  final Map<String, String> overrides;
  final Set<String> missingAssets;
  final List<String> requestedAssetKeys = <String>[];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) {
        return null;
      }

      final key = utf8.decode(message.buffer.asUint8List());
      requestedAssetKeys.add(key);

      if (missingAssets.contains(key)) {
        return null;
      }

      final overridden = overrides[key];
      if (overridden != null) {
        return ByteData.sublistView(
            Uint8List.fromList(utf8.encode(overridden)));
      }

      final assetFile = File(key);
      if (!assetFile.existsSync()) {
        return null;
      }

      final bytes = assetFile.readAsBytesSync();
      return ByteData.sublistView(Uint8List.fromList(bytes));
    });
  }

  void dispose() {
    for (final key in requestedAssetKeys.toSet()) {
      rootBundle.evict(key);
    }
    requestedAssetKeys.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  }
}

Future<T> _runOffline<T>(Future<T> Function() action) {
  return HttpOverrides.runWithHttpOverrides(
    action,
    _NoNetworkHttpOverrides(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline examples library', () {
    _AssetBundleHarness? harness;

    tearDown(() {
      harness?.dispose();
      harness = null;
    });

    test('loads bundled examples without network access', () async {
      final result = await _runOffline(() async {
        harness = _AssetBundleHarness();
        harness!.install();
        return ExamplesAssetDataSource().loadAllExamples();
      });

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(14));
      expect(
        result.data!.map((example) => example.category).toSet(),
        equals(const {'DFA', 'NFA', 'CFG', 'PDA', 'TM'}),
      );
      expect(
        harness!.requestedAssetKeys.every(
          (key) => key.startsWith('jflutter_js/examples/'),
        ),
        isTrue,
      );
    });

    test('reports missing bundled asset failures', () async {
      final result = await _runOffline(() async {
        harness = _AssetBundleHarness(
          missingAssets: const {'jflutter_js/examples/afd_ends_with_a.json'},
        );
        harness!.install();
        return ExamplesAssetDataSource().loadExample('AFD - Termina com A');
      });

      expect(result.isFailure, isTrue);
      expect(result.error, contains('asset not found'));
    });

    test('propagates malformed asset data through the data source', () async {
      final result = await _runOffline(() async {
        harness = _AssetBundleHarness(
          overrides: const {
            'jflutter_js/examples/afd_ends_with_a.json': '{"states": "bad"}',
          },
        );
        harness!.install();

        final dataSource = ExamplesAssetDataSource();
        return dataSource.loadExample('AFD - Termina com A');
      });

      expect(result.isFailure, isTrue);
      expect(result.error, contains('invalid "states" data'));
    });

    test('returns expected examples for every bundled category', () async {
      await _runOffline(() async {
        harness = _AssetBundleHarness();
        harness!.install();

        final dataSource = ExamplesAssetDataSource();

        for (final category in ExampleCategory.values) {
          final result = await dataSource.loadExamplesByCategory(category);
          expect(result.isSuccess, isTrue, reason: 'category ${category.name}');
          expect(result.data, isNotEmpty, reason: 'category ${category.name}');
          expect(
            result.data!.every(
              (example) => example.category == category.displayName,
            ),
            isTrue,
            reason: 'category ${category.name}',
          );
        }
      });
    });
  });
}
