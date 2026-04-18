// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get selectTransition => 'Selecione a transição';

  @override
  String get createNewTransition => 'Criar nova transição';

  @override
  String get contextAwareHelp => 'Ajuda contextual';

  @override
  String get algorithms => 'Algoritmos';

  @override
  String get regularExpressionTitle => 'Expressão regular';

  @override
  String get regularExpressionLabel => 'Expressão regular:';

  @override
  String get regularExpressionHint => 'Digite a expressão regular (ex.: a*b+)';

  @override
  String get validateRegex => 'Validar regex';

  @override
  String get enterRegexToValidate =>
      'Digite uma expressão regular para validar.';

  @override
  String get validRegex => 'Regex válida';

  @override
  String get invalidRegex => 'Regex inválida';

  @override
  String get testStringLabel => 'Cadeia de teste:';

  @override
  String get testStringHint => 'Digite a cadeia para testar';

  @override
  String get testStringTooltip => 'Testar cadeia';

  @override
  String get matches => 'Aceita!';

  @override
  String get doesNotMatch => 'Não aceita';

  @override
  String get convertToAutomaton => 'Converter para autômato:';

  @override
  String get convertToNfa => 'Converter para AFN';

  @override
  String get convertToDfa => 'Converter para AFD';

  @override
  String get simplifyOutput => 'Simplificar saída';

  @override
  String get simplifyOutputSubtitle =>
      'Aplicar simplificações algébricas aos autômatos convertidos';

  @override
  String get compareRegularExpressions => 'Comparar expressões regulares:';

  @override
  String get comparisonRegexHint => 'Digite a segunda expressão regular';

  @override
  String get compareEquivalence => 'Comparar equivalência';

  @override
  String get regexHelp => 'Ajuda de regex';

  @override
  String get regexHelpPatterns =>
      'Padrões comuns:\n• a* - zero ou mais a\n• a+ - um ou mais a\n• a? - zero ou um a\n• a|b - a ou b\n• (ab)* - zero ou mais ab\n• [abc] - qualquer um entre a, b ou c';

  @override
  String get convertedRegexSimplified => 'Regex convertida (simplificada)';

  @override
  String get convertedRegexRaw => 'Regex convertida (bruta)';

  @override
  String get regexCopiedToClipboard =>
      'Regex copiada para a área de transferência';

  @override
  String get copyToClipboard => 'Copiar para a área de transferência';

  @override
  String get toggleOffRawOutput => 'Desative para ver a saída bruta';

  @override
  String get toggleOnSimplifiedOutput => 'Ative para ver a saída simplificada';

  @override
  String get enterValidRegexFirst =>
      'Digite primeiro uma expressão regular válida';

  @override
  String get failedConvertRegexToNfa => 'Falha ao converter regex para AFN';

  @override
  String get convertedRegexToNfa =>
      'Regex convertida para AFN. Veja no espaço de trabalho de AFD/AFN.';

  @override
  String get failedConvertNfaToDfa => 'Falha ao converter AFN para AFD';

  @override
  String get convertedRegexToDfa =>
      'Regex convertida para AFD. Abrindo o AFD no espaço de trabalho.';

  @override
  String get failedSimplifyRegex => 'Falha ao simplificar regex';

  @override
  String get failedAnalyzeRegex => 'Falha ao analisar regex';

  @override
  String get failedGenerateSampleStrings => 'Falha ao gerar cadeias de exemplo';

  @override
  String get simplificationSteps => 'Passos de simplificação';

  @override
  String get hideSteps => 'Ocultar passos';

  @override
  String get showSteps => 'Mostrar passos';

  @override
  String get simplifyWithSteps => 'Simplificar com passos';

  @override
  String get clear => 'Limpar';

  @override
  String get resimplify => 'Simplificar novamente';

  @override
  String get originalLabel => 'Original:';

  @override
  String get rulesAppliedLabel => 'regra(s) aplicada(s)';

  @override
  String get simplifiedLabel => 'Simplificada:';

  @override
  String get simplifiedRegexCopiedToClipboard =>
      'Regex simplificada copiada para a área de transferência';

  @override
  String get copySimplifiedRegex => 'Copiar regex simplificada';

  @override
  String get saved => 'Economia';

  @override
  String get charactersAbbreviation => 'caracteres';

  @override
  String get reduction => 'Redução';

  @override
  String get time => 'Tempo';

  @override
  String get stepLabel => 'Passo';

  @override
  String get ofLabel => 'de';

  @override
  String get previousStep => 'Passo anterior';

  @override
  String get nextStep => 'Próximo passo';

  @override
  String get allSteps => 'Todos os passos:';

  @override
  String get transformation => 'Transformação';

  @override
  String get before => 'Antes';

  @override
  String get after => 'Depois';

  @override
  String get rule => 'Regra';

  @override
  String get starHeight => 'Altura de estrela';

  @override
  String get nestingDepth => 'Profundidade de aninhamento';

  @override
  String get operators => 'Operadores';
}
