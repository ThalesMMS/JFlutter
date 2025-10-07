//
//  grammar_entity.dart
//  JFlutter
//
//  Define as estruturas imutáveis que representam gramáticas formais dentro do
//  núcleo, incluindo identificadores, conjuntos de terminais e não terminais,
//  símbolo inicial e produções completas. Estabelece também o modelo de cada
//  produção, permitindo que algoritmos de análise, transformação e conversão
//  manipulem dados consistentes em toda a plataforma.
//
//  Thales Matheus Mendonça Santos - October 2025
//
class GrammarEntity {
  final String id;
  final String name;
  final Set<String> terminals;
  final Set<String> nonTerminals;
  final String startSymbol;
  final List<ProductionEntity> productions;

  const GrammarEntity({
    required this.id,
    required this.name,
    required this.terminals,
    required this.nonTerminals,
    required this.startSymbol,
    required this.productions,
  });
}

class ProductionEntity {
  final String id;
  final List<String> leftSide;
  final List<String> rightSide;

  const ProductionEntity({
    required this.id,
    required this.leftSide,
    required this.rightSide,
  });
}
