import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/core/services/trace_persistence_service.dart';
import 'package:jflutter/core/use_cases/algorithm_use_cases.dart';
import 'package:jflutter/core/use_cases/automaton_use_cases.dart';
import 'package:jflutter/data/data_sources/examples_asset_data_source.dart';
import 'package:jflutter/data/data_sources/local_storage_data_source.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/data/services/conversion_service.dart';
import 'package:jflutter/data/services/simulation_service.dart';
import 'package:jflutter/data/services/trace_persistence_service.dart'
    as data_trace;
import 'package:jflutter/injection/dependency_injection.dart';
import 'package:jflutter/presentation/providers/algorithm_provider.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/grammar_provider.dart';
import 'package:jflutter/presentation/providers/unified_trace_provider.dart';

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
      expect(
        getIt<DependencyInitializationStatus>().sharedPreferencesFallbackUsed,
        isFalse,
      );
    });

    test('resolves registered singletons and factories without error',
        () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      await setupDependencyInjection();

      expect(() => getIt<SharedPreferences>(), returnsNormally);
      expect(() => getIt<DependencyInitializationStatus>(), returnsNormally);
      expect(() => getIt<LocalStorageDataSource>(), returnsNormally);
      expect(() => getIt<ExamplesAssetDataSource>(), returnsNormally);
      expect(() => getIt<AutomatonService>(), returnsNormally);
      expect(() => getIt<SimulationService>(), returnsNormally);
      expect(() => getIt<ConversionService>(), returnsNormally);
      expect(() => getIt<TracePersistenceService>(), returnsNormally);
      expect(
          () => getIt<data_trace.TracePersistenceService>(), returnsNormally);
      expect(() => getIt<AutomatonRepository>(), returnsNormally);
      expect(() => getIt<ExamplesRepository>(), returnsNormally);
      expect(() => getIt<AlgorithmRepository>(), returnsNormally);
      expect(() => getIt<LayoutRepository>(), returnsNormally);
      expect(() => getIt<CreateAutomatonUseCase>(), returnsNormally);
      expect(() => getIt<LoadAutomatonUseCase>(), returnsNormally);
      expect(() => getIt<SaveAutomatonUseCase>(), returnsNormally);
      expect(() => getIt<DeleteAutomatonUseCase>(), returnsNormally);
      expect(() => getIt<ExportAutomatonUseCase>(), returnsNormally);
      expect(() => getIt<ImportAutomatonUseCase>(), returnsNormally);
      expect(() => getIt<ValidateAutomatonUseCase>(), returnsNormally);
      expect(() => getIt<AddStateUseCase>(), returnsNormally);
      expect(() => getIt<RemoveStateUseCase>(), returnsNormally);
      expect(() => getIt<AddTransitionUseCase>(), returnsNormally);
      expect(() => getIt<RemoveTransitionUseCase>(), returnsNormally);
      expect(() => getIt<NfaToDfaUseCase>(), returnsNormally);
      expect(() => getIt<RemoveLambdaTransitionsUseCase>(), returnsNormally);
      expect(() => getIt<MinimizeDfaUseCase>(), returnsNormally);
      expect(() => getIt<CompleteDfaUseCase>(), returnsNormally);
      expect(() => getIt<ComplementDfaUseCase>(), returnsNormally);
      expect(() => getIt<UnionDfaUseCase>(), returnsNormally);
      expect(() => getIt<IntersectionDfaUseCase>(), returnsNormally);
      expect(() => getIt<DifferenceDfaUseCase>(), returnsNormally);
      expect(() => getIt<PrefixClosureUseCase>(), returnsNormally);
      expect(() => getIt<SuffixClosureUseCase>(), returnsNormally);
      expect(() => getIt<RegexToNfaUseCase>(), returnsNormally);
      expect(() => getIt<DfaToRegexUseCase>(), returnsNormally);
      expect(() => getIt<FsaToGrammarUseCase>(), returnsNormally);
      expect(() => getIt<CheckEquivalenceUseCase>(), returnsNormally);
      expect(() => getIt<SimulateWordUseCase>(), returnsNormally);
      expect(() => getIt<CreateStepByStepSimulationUseCase>(), returnsNormally);
      expect(() => getIt<AutomatonProvider>(), returnsNormally);
      expect(() => getIt<AlgorithmProvider>(), returnsNormally);
      expect(() => getIt<GrammarProvider>(), returnsNormally);
      expect(() => getIt<UnifiedTraceNotifier>(), returnsNormally);
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
          DependencyInitializationStage.dataSources,
          DependencyInitializationStage.services,
          DependencyInitializationStage.repositories,
          DependencyInitializationStage.useCases,
          DependencyInitializationStage.providers,
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

      final status = getIt<DependencyInitializationStatus>();

      expect(status.sharedPreferencesFallbackUsed, isTrue);
      expect(status.sharedPreferencesError, isNotNull);
      expect(getIt<SharedPreferences>(), isA<SharedPreferences>());

      await resetDependencies();

      expect(
        SharedPreferencesStorePlatform.instance,
        same(originalStore),
      );
    });
  });
}
