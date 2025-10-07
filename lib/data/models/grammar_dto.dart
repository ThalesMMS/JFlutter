/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/data/models/grammar_dto.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Define os DTOs das gramáticas e estruturas JFLAP responsáveis
///             por serializar símbolos, produções e metadados associados.
/// Contexto: Suporta importação e exportação de gramáticas entre o domínio e
///           formatos JSON/JFLAP, assegurando compatibilidade com o ecossistema
///           da aplicação e ferramentas externas.
/// Observações: Construtores imutáveis e fábricas dedicadas simplificam a
///               reconstrução das gramáticas mantendo a fidelidade dos dados
///               originais.
/// ---------------------------------------------------------------------------
class GrammarDto {
  final String id;
  final String name;
  final String type;
  final List<String> terminals;
  final List<String> variables;
  final String initialSymbol;
  final Map<String, List<String>> productions;

  const GrammarDto({
    required this.id,
    required this.name,
    required this.type,
    required this.terminals,
    required this.variables,
    required this.initialSymbol,
    required this.productions,
  });

  factory GrammarDto.fromJson(Map<String, dynamic> json) {
    return GrammarDto(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      terminals: List<String>.from(json['terminals'] as List),
      variables: List<String>.from(json['variables'] as List),
      initialSymbol: json['initialSymbol'] as String,
      productions: (json['productions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'terminals': terminals,
      'variables': variables,
      'initialSymbol': initialSymbol,
      'productions': productions,
    };
  }
}

/// DTO for JFLAP grammar structure
class JflapGrammarDto {
  final String type;
  final JflapGrammarStructureDto structure;

  const JflapGrammarDto({required this.type, required this.structure});

  factory JflapGrammarDto.fromJson(Map<String, dynamic> json) {
    return JflapGrammarDto(
      type: json['type'] as String,
      structure: JflapGrammarStructureDto.fromJson(
        json['structure'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'structure': structure.toJson()};
  }
}

/// DTO for JFLAP grammar structure details
class JflapGrammarStructureDto {
  final List<String> terminals;
  final List<String> variables;
  final String startVariable;
  final List<JflapProductionDto> productions;

  const JflapGrammarStructureDto({
    required this.terminals,
    required this.variables,
    required this.startVariable,
    required this.productions,
  });

  factory JflapGrammarStructureDto.fromJson(Map<String, dynamic> json) {
    return JflapGrammarStructureDto(
      terminals: List<String>.from(json['terminals'] as List),
      variables: List<String>.from(json['variables'] as List),
      startVariable: json['startVariable'] as String,
      productions: (json['productions'] as List)
          .map((p) => JflapProductionDto.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'terminals': terminals,
      'variables': variables,
      'startVariable': startVariable,
      'productions': productions.map((p) => p.toJson()).toList(),
    };
  }
}

/// DTO for JFLAP production
class JflapProductionDto {
  final String left;
  final String right;

  const JflapProductionDto({required this.left, required this.right});

  factory JflapProductionDto.fromJson(Map<String, dynamic> json) {
    return JflapProductionDto(
      left: json['left'] as String,
      right: json['right'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'left': left, 'right': right};
  }
}
