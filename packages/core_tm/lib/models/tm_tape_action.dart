import 'package:freezed_annotation/freezed_annotation.dart';

part 'tm_tape_action.freezed.dart';
part 'tm_tape_action.g.dart';

/// Direction for tape head movement
enum TapeDirection {
  left,
  right,
  stay,
}

/// Tape action for Turing Machine transitions
@freezed
class TMTapeAction with _$TMTapeAction {
  const factory TMTapeAction({
    required int tape,
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection direction,
  }) = _TMTapeAction;

  factory TMTapeAction.fromJson(Map<String, dynamic> json) => _$TMTapeActionFromJson(json);
}

/// Extension methods for TMTapeAction
extension TMTapeActionExtension on TMTapeAction {
  /// Head position (alias for direction)
  TapeDirection get headPosition => direction;

  /// Validates the tape action properties
  List<String> validate() {
    final errors = <String>[];
    
    if (tape < 0) {
      errors.add('Tape number cannot be negative');
    }
    
    if (readSymbol.isEmpty) {
      errors.add('Read symbol cannot be empty');
    }
    
    if (writeSymbol.isEmpty) {
      errors.add('Write symbol cannot be empty');
    }
    
    return errors;
  }

  /// Checks if the tape action is valid
  bool get isValid => validate().isEmpty;
}
