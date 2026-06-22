import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:jflutter/injection/dependency_injection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await resetDependencies();
  });

  group('Dependency injection initialization', () {
    test('completes successfully with mocked SharedPreferences', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'boot': 'ready',
      });
      final prefs = await SharedPreferences.getInstance();

      await setupDependencyInjection(
          sharedPreferencesProvider: () async => prefs);

      expect(getIt<SharedPreferences>(), same(prefs));
    });

    test('resolves registered singletons and factories without error',
        () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      await setupDependencyInjection();

      expect(() => getIt<SharedPreferences>(), returnsNormally);
    });

    test('reports initialization stages in the expected order', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final observedStages = <DependencyInitializationStage>[];

      await setupDependencyInjection(
        onStage: observedStages.add,
      );

      expect(
        observedStages,
        equals(<DependencyInitializationStage>[
          DependencyInitializationStage.sharedPreferences,
        ]),
      );
    });

    test('falls back to in-memory SharedPreferences when initialization fails',
        () async {
      final originalStore = SharedPreferencesStorePlatform.instance;

      await setupDependencyInjection(
        sharedPreferencesProvider: () async {
          throw Exception('preferences unavailable');
        },
      );

      expect(getIt<SharedPreferences>(), isA<SharedPreferences>());

      await resetDependencies();

      expect(
        SharedPreferencesStorePlatform.instance,
        same(originalStore),
      );
    });
  });
}
