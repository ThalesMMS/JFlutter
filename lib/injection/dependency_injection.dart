//
//  dependency_injection.dart
//  JFlutter
//
//  Configura o contêiner de injeção de dependências com GetIt, registrando
//  fontes de dados, serviços, repositórios e providers para manter o
//  aplicativo desacoplado e com inicialização preguiçosa. Também prepara as
//  instâncias de SharedPreferences utilizadas na persistência de traços para
//  que camadas distintas compartilhem integrações consistentes.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/repositories/automaton_repository.dart';
import '../core/use_cases/automaton_use_cases.dart';
import '../core/use_cases/algorithm_use_cases.dart';
import '../data/data_sources/local_storage_data_source.dart';
import '../data/data_sources/examples_asset_data_source.dart';
import '../data/repositories/automaton_repository_impl.dart';
import '../data/repositories/examples_repository_impl.dart';
import '../data/repositories/algorithm_repository_impl.dart';
import '../features/layout/layout_repository_impl.dart';
import '../data/services/automaton_service.dart';
import '../data/services/simulation_service.dart';
import '../data/services/conversion_service.dart';
import '../core/services/trace_persistence_service.dart';
import '../data/services/trace_persistence_service.dart' as data_trace;
import '../presentation/providers/automaton_provider.dart';
import '../presentation/providers/algorithm_provider.dart';
import '../presentation/providers/grammar_provider.dart';
import '../presentation/providers/unified_trace_provider.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Sets up dependency injection for the application
Future<void> setupDependencyInjection() async {
  // Initialize SharedPreferences for trace persistence
  final prefs = await SharedPreferences.getInstance();

  // Data Sources
  getIt.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSource(),
  );

  getIt.registerLazySingleton<ExamplesAssetDataSource>(
    () => ExamplesAssetDataSource(),
  );

  // Services
  getIt.registerLazySingleton<AutomatonService>(() => AutomatonService());

  getIt.registerLazySingleton<SimulationService>(() => SimulationService());

  getIt.registerLazySingleton<ConversionService>(() => ConversionService());

  // Core trace persistence service (used by AutomatonProvider and legacy trace flows)
  getIt.registerLazySingleton<TracePersistenceService>(
    () => createTracePersistenceService(prefs),
  );

  // Data layer trace persistence service (for UnifiedTraceNotifier)
  getIt.registerLazySingleton<data_trace.TracePersistenceService>(
    () => data_trace.TracePersistenceService(prefs),
  );

  // Repositories
  getIt.registerLazySingleton<AutomatonRepository>(
    () => AutomatonRepositoryImpl(getIt<AutomatonService>()),
  );

  getIt.registerLazySingleton<ExamplesRepository>(
    () => ExamplesRepositoryImpl(getIt<ExamplesAssetDataSource>()),
  );

  getIt.registerLazySingleton<AlgorithmRepository>(
    () => AlgorithmRepositoryImpl(),
  );

  getIt.registerLazySingleton<LayoutRepository>(() => LayoutRepositoryImpl());

  // Use Cases
  getIt.registerLazySingleton<CreateAutomatonUseCase>(
    () => CreateAutomatonUseCase(getIt<AutomatonRepository>()),
  );

  getIt.registerLazySingleton<LoadAutomatonUseCase>(
    () => LoadAutomatonUseCase(getIt<AutomatonRepository>()),
  );

  getIt.registerLazySingleton<SaveAutomatonUseCase>(
    () => SaveAutomatonUseCase(getIt<AutomatonRepository>()),
  );

  getIt.registerLazySingleton<DeleteAutomatonUseCase>(
    () => DeleteAutomatonUseCase(getIt<AutomatonRepository>()),
  );

  getIt.registerLazySingleton<ExportAutomatonUseCase>(
    () => ExportAutomatonUseCase(getIt<AutomatonRepository>()),
  );

  getIt.registerLazySingleton<ImportAutomatonUseCase>(
    () => ImportAutomatonUseCase(getIt<AutomatonRepository>()),
  );

  getIt.registerLazySingleton<ValidateAutomatonUseCase>(
    () => ValidateAutomatonUseCase(getIt<AutomatonRepository>()),
  );

  getIt.registerLazySingleton<AddStateUseCase>(
    () => AddStateUseCase(getIt<AutomatonRepository>()),
  );

  getIt.registerLazySingleton<RemoveStateUseCase>(
    () => RemoveStateUseCase(getIt<AutomatonRepository>()),
  );

  getIt.registerLazySingleton<AddTransitionUseCase>(
    () => AddTransitionUseCase(getIt<AutomatonRepository>()),
  );

  getIt.registerLazySingleton<RemoveTransitionUseCase>(
    () => RemoveTransitionUseCase(getIt<AutomatonRepository>()),
  );

  // Algorithm Use Cases
  getIt.registerLazySingleton<NfaToDfaUseCase>(
    () => NfaToDfaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<RemoveLambdaTransitionsUseCase>(
    () => RemoveLambdaTransitionsUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<MinimizeDfaUseCase>(
    () => MinimizeDfaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<CompleteDfaUseCase>(
    () => CompleteDfaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<ComplementDfaUseCase>(
    () => ComplementDfaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<UnionDfaUseCase>(
    () => UnionDfaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<IntersectionDfaUseCase>(
    () => IntersectionDfaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<DifferenceDfaUseCase>(
    () => DifferenceDfaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<PrefixClosureUseCase>(
    () => PrefixClosureUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<SuffixClosureUseCase>(
    () => SuffixClosureUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<RegexToNfaUseCase>(
    () => RegexToNfaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<DfaToRegexUseCase>(
    () => DfaToRegexUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<FsaToGrammarUseCase>(
    () => FsaToGrammarUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<CheckEquivalenceUseCase>(
    () => CheckEquivalenceUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<SimulateWordUseCase>(
    () => SimulateWordUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<CreateStepByStepSimulationUseCase>(
    () => CreateStepByStepSimulationUseCase(getIt<AlgorithmRepository>()),
  );

  // Providers
  getIt.registerFactory<AutomatonProvider>(
    () => AutomatonProvider(
      automatonService: getIt<AutomatonService>(),
      layoutRepository: getIt<LayoutRepository>(),
      tracePersistenceService: getIt<TracePersistenceService>(),
    ),
  );

  getIt.registerFactory<AlgorithmProvider>(
    () => AlgorithmProvider(
      nfaToDfaUseCase: getIt<NfaToDfaUseCase>(),
      removeLambdaTransitionsUseCase: getIt<RemoveLambdaTransitionsUseCase>(),
      minimizeDfaUseCase: getIt<MinimizeDfaUseCase>(),
      completeDfaUseCase: getIt<CompleteDfaUseCase>(),
      complementDfaUseCase: getIt<ComplementDfaUseCase>(),
      unionDfaUseCase: getIt<UnionDfaUseCase>(),
      intersectionDfaUseCase: getIt<IntersectionDfaUseCase>(),
      differenceDfaUseCase: getIt<DifferenceDfaUseCase>(),
      prefixClosureUseCase: getIt<PrefixClosureUseCase>(),
      suffixClosureUseCase: getIt<SuffixClosureUseCase>(),
      regexToNfaUseCase: getIt<RegexToNfaUseCase>(),
      dfaToRegexUseCase: getIt<DfaToRegexUseCase>(),
      fsaToGrammarUseCase: getIt<FsaToGrammarUseCase>(),
      checkEquivalenceUseCase: getIt<CheckEquivalenceUseCase>(),
      simulateWordUseCase: getIt<SimulateWordUseCase>(),
      createStepByStepSimulationUseCase:
          getIt<CreateStepByStepSimulationUseCase>(),
    ),
  );

  getIt.registerFactory<GrammarProvider>(
    () => GrammarProvider(conversionService: getIt<ConversionService>()),
  );

  getIt.registerFactory<UnifiedTraceNotifier>(
    () => UnifiedTraceNotifier(getIt<data_trace.TracePersistenceService>()),
  );
}

/// Resets all dependencies (useful for testing)
void resetDependencies() {
  getIt.reset();
}
