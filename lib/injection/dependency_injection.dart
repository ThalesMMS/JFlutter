import 'package:get_it/get_it.dart';
import '../core/repositories/automaton_repository.dart';
import '../core/use_cases/automaton_use_cases.dart';
import '../core/use_cases/algorithm_use_cases.dart';
import '../data/data_sources/local_storage_data_source.dart';
import '../data/data_sources/examples_data_source.dart';
import '../data/repositories/automaton_repository_impl.dart';
import '../data/repositories/examples_repository_impl.dart';
import '../data/repositories/algorithm_repository_impl.dart';
import '../features/layout/layout_repository_impl.dart';
import '../data/services/automaton_service.dart';
import '../data/services/simulation_service.dart';
import '../data/services/conversion_service.dart';
import '../presentation/providers/automaton_provider.dart';
import '../presentation/providers/algorithm_provider.dart';
import '../presentation/providers/grammar_provider.dart';
import '../presentation/providers/automaton/automaton_creation_controller.dart';
import '../presentation/providers/automaton/automaton_simulation_controller.dart';
import '../presentation/providers/automaton/automaton_conversion_controller.dart';
import '../presentation/providers/automaton/automaton_layout_controller.dart';
import 'app_configuration.dart';
import 'app_configuration_model.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Sets up dependency injection for the application
Future<void> setupDependencyInjection() async {
  final appConfiguration = resolveAppConfiguration();
  getIt.registerSingleton<AppConfiguration>(appConfiguration);

  // Data Sources
  getIt.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSource(),
  );
  
  getIt.registerLazySingleton<ExamplesDataSource>(
    () => ExamplesDataSource(),
  );

  // Services
  getIt.registerLazySingleton<AutomatonService>(
    () => AutomatonService(
      baseUrl: getIt<AppConfiguration>().apiBaseUrl,
    ),
  );
  
  getIt.registerLazySingleton<SimulationService>(
    () => SimulationService(),
  );
  
  getIt.registerLazySingleton<ConversionService>(
    () => ConversionService(),
  );

  // Repositories
  getIt.registerLazySingleton<AutomatonRepository>(
    () => AutomatonRepositoryImpl(getIt<AutomatonService>()),
  );
  
  getIt.registerLazySingleton<ExamplesRepository>(
    () => ExamplesRepositoryImpl(getIt<ExamplesDataSource>()),
  );
  
  getIt.registerLazySingleton<AlgorithmRepository>(
    () => AlgorithmRepositoryImpl(),
  );

  getIt.registerLazySingleton<LayoutRepository>(
    () => LayoutRepositoryImpl(),
  );

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

  getIt.registerLazySingleton<ApplyAutoLayoutUseCase>(
    () => ApplyAutoLayoutUseCase(getIt<LayoutRepository>()),
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

  getIt.registerLazySingleton<ConcatenateFsaUseCase>(
    () => ConcatenateFsaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<KleeneStarFsaUseCase>(
    () => KleeneStarFsaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<ReverseFsaUseCase>(
    () => ReverseFsaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<ShuffleFsaUseCase>(
    () => ShuffleFsaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<IsLanguageEmptyUseCase>(
    () => IsLanguageEmptyUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<IsLanguageFiniteUseCase>(
    () => IsLanguageFiniteUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<GenerateWordsUseCase>(
    () => GenerateWordsUseCase(getIt<AlgorithmRepository>()),
  );
  
  getIt.registerLazySingleton<RegexToNfaUseCase>(
    () => RegexToNfaUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<ParseRegexUseCase>(
    () => ParseRegexUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<DfaToRegexUseCase>(
    () => DfaToRegexUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<FsaToGrammarUseCase>(
    () => FsaToGrammarUseCase(getIt<AlgorithmRepository>()),
  );

  getIt.registerLazySingleton<ParseGrammarDefinitionUseCase>(
    () => ParseGrammarDefinitionUseCase(getIt<AlgorithmRepository>()),
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

  // Controllers
  getIt.registerLazySingleton<AutomatonCreationController>(
    () => AutomatonCreationController(
      createAutomatonUseCase: getIt<CreateAutomatonUseCase>(),
      addStateUseCase: getIt<AddStateUseCase>(),
    ),
  );

  getIt.registerLazySingleton<AutomatonSimulationController>(
    () => AutomatonSimulationController(
      simulateWordUseCase: getIt<SimulateWordUseCase>(),
    ),
  );

  getIt.registerLazySingleton<AutomatonConversionController>(
    () => AutomatonConversionController(
      nfaToDfaUseCase: getIt<NfaToDfaUseCase>(),
      minimizeDfaUseCase: getIt<MinimizeDfaUseCase>(),
      completeDfaUseCase: getIt<CompleteDfaUseCase>(),
      regexToNfaUseCase: getIt<RegexToNfaUseCase>(),
      dfaToRegexUseCase: getIt<DfaToRegexUseCase>(),
      fsaToGrammarUseCase: getIt<FsaToGrammarUseCase>(),
      checkEquivalenceUseCase: getIt<CheckEquivalenceUseCase>(),
    ),
  );

  getIt.registerLazySingleton<AutomatonLayoutController>(
    () => AutomatonLayoutController(
      applyAutoLayoutUseCase: getIt<ApplyAutoLayoutUseCase>(),
    ),
  );

  // Providers
  getIt.registerFactory<AutomatonProvider>(
    () => AutomatonProvider(
      creationController: getIt<AutomatonCreationController>(),
      simulationController: getIt<AutomatonSimulationController>(),
      conversionController: getIt<AutomatonConversionController>(),
      layoutController: getIt<AutomatonLayoutController>(),
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
      concatenateFsaUseCase: getIt<ConcatenateFsaUseCase>(),
      kleeneStarFsaUseCase: getIt<KleeneStarFsaUseCase>(),
      reverseFsaUseCase: getIt<ReverseFsaUseCase>(),
      shuffleFsaUseCase: getIt<ShuffleFsaUseCase>(),
      isLanguageEmptyUseCase: getIt<IsLanguageEmptyUseCase>(),
      isLanguageFiniteUseCase: getIt<IsLanguageFiniteUseCase>(),
      generateWordsUseCase: getIt<GenerateWordsUseCase>(),
      regexToNfaUseCase: getIt<RegexToNfaUseCase>(),
      dfaToRegexUseCase: getIt<DfaToRegexUseCase>(),
      fsaToGrammarUseCase: getIt<FsaToGrammarUseCase>(),
      checkEquivalenceUseCase: getIt<CheckEquivalenceUseCase>(),
      simulateWordUseCase: getIt<SimulateWordUseCase>(),
      createStepByStepSimulationUseCase: getIt<CreateStepByStepSimulationUseCase>(),
    ),
  );
  
  getIt.registerFactory<GrammarProvider>(
    () => GrammarProvider(
      conversionService: getIt<ConversionService>(),
    ),
  );
}

/// Resets all dependencies (useful for testing)
void resetDependencies() {
  getIt.reset();
}
