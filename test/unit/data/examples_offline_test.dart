import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/data/data_sources/examples_asset_data_source.dart';
import 'package:jflutter/data/repositories/examples_repository_impl.dart';
import 'package:jflutter/data/services/examples_service.dart';

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

class _CountingExamplesAssetDataSource extends ExamplesAssetDataSource {
  _CountingExamplesAssetDataSource(this.examplesByCategory);

  final Map<ExampleCategory, List<ExampleEntity>> examplesByCategory;
  int loadAllCalls = 0;
  int loadExampleCalls = 0;
  final Map<ExampleCategory, int> loadCategoryCalls = <ExampleCategory, int>{};

  @override
  Future<ListResult<ExampleEntity>> loadAllExamples() async {
    loadAllCalls++;
    return Success(
      examplesByCategory.values.expand((examples) => examples).toList(),
    );
  }

  @override
  Future<ListResult<ExampleEntity>> loadExamplesByCategory(
    ExampleCategory category,
  ) async {
    loadCategoryCalls[category] = (loadCategoryCalls[category] ?? 0) + 1;
    return Success(
        List<ExampleEntity>.from(examplesByCategory[category] ?? []));
  }

  @override
  Future<Result<ExampleEntity>> loadExample(String name) async {
    loadExampleCalls++;
    for (final examples in examplesByCategory.values) {
      for (final example in examples) {
        if (example.name == name) {
          return Success(example);
        }
      }
    }
    return Failure('Example not found: $name');
  }

  @override
  List<ExampleCategory> getAvailableCategories() {
    return examplesByCategory.keys.toList();
  }

  @override
  Map<ExampleCategory, int> getExamplesCountByCategory() {
    return {
      for (final entry in examplesByCategory.entries)
        entry.key: entry.value.length,
    };
  }
}

ExampleEntity _example(String name, ExampleCategory category) {
  return ExampleEntity(
    name: name,
    description: '$name description',
    category: category.displayName,
    subcategory: 'Tests',
    difficultyLevel: DifficultyLevel.easy,
    tags: const ['offline'],
    estimatedComplexity: ComplexityLevel.low,
  );
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
      expect(result.data, hasLength(11));
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

    test('propagates malformed asset data through service and repository',
        () async {
      final results = await _runOffline(() async {
        harness = _AssetBundleHarness(
          overrides: const {
            'jflutter_js/examples/afd_ends_with_a.json': '{"states": "bad"}',
          },
        );
        harness!.install();

        final dataSource = ExamplesAssetDataSource();
        final service = ExamplesService(dataSource);
        final repository = ExamplesRepositoryImpl(dataSource);

        final dataSourceResult =
            await dataSource.loadExample('AFD - Termina com A');
        final serviceResult = await service.loadExamplesByCategory(
          ExampleCategory.dfa,
        );
        final repositoryResult = await repository.loadExamplesByCategory(
          ExampleCategory.dfa,
        );

        return (
          dataSourceResult: dataSourceResult,
          serviceResult: serviceResult,
          repositoryResult: repositoryResult,
        );
      });

      expect(results.dataSourceResult.isFailure, isTrue);
      expect(results.dataSourceResult.error, contains('invalid "states" data'));
      expect(results.serviceResult.isFailure, isTrue);
      expect(results.serviceResult.error, contains('invalid "states" data'));
      expect(results.repositoryResult.isFailure, isTrue);
      expect(
        results.repositoryResult.error,
        contains('invalid "states" data'),
      );
    });

    test('returns expected examples for every bundled category', () async {
      await _runOffline(() async {
        harness = _AssetBundleHarness();
        harness!.install();

        final repository = ExamplesRepositoryImpl(ExamplesAssetDataSource());

        for (final category in ExampleCategory.values) {
          final result = await repository.loadExamplesByCategory(category);
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

  group('ExamplesService cache behavior', () {
    late _CountingExamplesAssetDataSource dataSource;
    late ExamplesService service;

    setUp(() {
      dataSource = _CountingExamplesAssetDataSource({
        ExampleCategory.dfa: <ExampleEntity>[
          _example('DFA One', ExampleCategory.dfa),
          _example('DFA Two', ExampleCategory.dfa),
        ],
        ExampleCategory.tm: <ExampleEntity>[
          _example('TM One', ExampleCategory.tm),
        ],
      });
      service = ExamplesService(dataSource);
    });

    test('does not treat a partial example cache as the full library',
        () async {
      final single = await service.loadExample('DFA One');
      final all = await service.loadAllExamples();

      expect(single.isSuccess, isTrue);
      expect(all.isSuccess, isTrue);
      expect(all.data, hasLength(3));
      expect(dataSource.loadExampleCalls, equals(1));
      expect(dataSource.loadAllCalls, equals(1));
    });

    test(
        'reuses the full-library cache for repeated reads and category filters',
        () async {
      final first = await service.loadAllExamples();
      final second = await service.loadAllExamples();
      final dfa = await service.loadExamplesByCategory(ExampleCategory.dfa);

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(dfa.isSuccess, isTrue);
      expect(dataSource.loadAllCalls, equals(1));
      expect(dataSource.loadCategoryCalls[ExampleCategory.dfa] ?? 0, equals(0));
      expect(dfa.data, hasLength(2));
    });

    test('reuses category cache without re-reading the data source', () async {
      final first = await service.loadExamplesByCategory(ExampleCategory.tm);
      final second = await service.loadExamplesByCategory(ExampleCategory.tm);

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(dataSource.loadCategoryCalls[ExampleCategory.tm], equals(1));
    });
  });
}
