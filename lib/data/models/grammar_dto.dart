import 'package:freezed_annotation/freezed_annotation.dart';

part 'grammar_dto.freezed.dart';
part 'grammar_dto.g.dart';

/// DTO for serializing grammar data
@freezed
class GrammarDto with _$GrammarDto {
  const factory GrammarDto({
    required String id,
    required String name,
    required String type,
    required List<String> terminals,
    required List<String> variables,
    required String initialSymbol,
    required Map<String, List<String>> productions,
  }) = _GrammarDto;

  factory GrammarDto.fromJson(Map<String, dynamic> json) =>
      _$GrammarDtoFromJson(json);
}

/// DTO for JFLAP grammar structure
@freezed
class JflapGrammarDto with _$JflapGrammarDto {
  const factory JflapGrammarDto({
    required String type,
    required JflapGrammarStructureDto structure,
  }) = _JflapGrammarDto;

  factory JflapGrammarDto.fromJson(Map<String, dynamic> json) =>
      _$JflapGrammarDtoFromJson(json);
}

/// DTO for JFLAP grammar structure
@freezed
class JflapGrammarStructureDto with _$JflapGrammarStructureDto {
  const factory JflapGrammarStructureDto({
    required List<String> terminals,
    required List<String> variables,
    required String startVariable,
    required List<JflapProductionDto> productions,
  }) = _JflapGrammarStructureDto;

  factory JflapGrammarStructureDto.fromJson(Map<String, dynamic> json) =>
      _$JflapGrammarStructureDtoFromJson(json);
}

/// DTO for JFLAP production
@freezed
class JflapProductionDto with _$JflapProductionDto {
  const factory JflapProductionDto({
    required String left,
    required String right,
  }) = _JflapProductionDto;

  factory JflapProductionDto.fromJson(Map<String, dynamic> json) =>
      _$JflapProductionDtoFromJson(json);
}
