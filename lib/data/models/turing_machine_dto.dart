import 'package:freezed_annotation/freezed_annotation.dart';

part 'turing_machine_dto.freezed.dart';
part 'turing_machine_dto.g.dart';

/// DTO for serializing Turing machine data
@freezed
class TuringMachineDto with _$TuringMachineDto {
  const factory TuringMachineDto({
    required String id,
    required String name,
    required String type,
    required List<String> inputAlphabet,
    required List<String> tapeAlphabet,
    required List<String> states,
    required String initialState,
    required List<String> finalStates,
    required String blankSymbol,
    required Map<String, Map<String, TuringTransitionDto>> transitions,
  }) = _TuringMachineDto;

  factory TuringMachineDto.fromJson(Map<String, dynamic> json) =>
      _$TuringMachineDtoFromJson(json);
}

/// DTO for Turing machine transition
@freezed
class TuringTransitionDto with _$TuringTransitionDto {
  const factory TuringTransitionDto({
    required String newState,
    required String writeSymbol,
    required String direction,
  }) = _TuringTransitionDto;

  factory TuringTransitionDto.fromJson(Map<String, dynamic> json) =>
      _$TuringTransitionDtoFromJson(json);
}

/// DTO for JFLAP Turing machine structure
@freezed
class JflapTuringMachineDto with _$JflapTuringMachineDto {
  const factory JflapTuringMachineDto({
    required String type,
    required JflapTuringStructureDto structure,
  }) = _JflapTuringMachineDto;

  factory JflapTuringMachineDto.fromJson(Map<String, dynamic> json) =>
      _$JflapTuringMachineDtoFromJson(json);
}

/// DTO for JFLAP Turing machine structure
@freezed
class JflapTuringStructureDto with _$JflapTuringStructureDto {
  const factory JflapTuringStructureDto({
    required List<String> states,
    required List<String> inputAlphabet,
    required List<String> tapeAlphabet,
    required String initialState,
    required List<String> finalStates,
    required String blankSymbol,
    required List<JflapTuringTransitionDto> transitions,
  }) = _JflapTuringStructureDto;

  factory JflapTuringStructureDto.fromJson(Map<String, dynamic> json) =>
      _$JflapTuringStructureDtoFromJson(json);
}

/// DTO for JFLAP Turing machine transition
@freezed
class JflapTuringTransitionDto with _$JflapTuringTransitionDto {
  const factory JflapTuringTransitionDto({
    required String from,
    required String to,
    required String read,
    required String write,
    required String direction,
  }) = _JflapTuringTransitionDto;

  factory JflapTuringTransitionDto.fromJson(Map<String, dynamic> json) =>
      _$JflapTuringTransitionDtoFromJson(json);
}
