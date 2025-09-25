import 'package:freezed_annotation/freezed_annotation.dart';

part 'automaton_metadata.freezed.dart';
part 'automaton_metadata.g.dart';

/// Represents metadata for an automaton
@freezed
class AutomatonMetadata with _$AutomatonMetadata {
  const factory AutomatonMetadata({
    required DateTime createdAt,
    required DateTime modifiedAt,
    required String createdBy,
    String? description,
    @Default([]) List<String> tags,
  }) = _AutomatonMetadata;

  factory AutomatonMetadata.fromJson(Map<String, dynamic> json) => _$AutomatonMetadataFromJson(json);

  /// Creates metadata with current timestamp
  factory AutomatonMetadata.create({
    required String createdBy,
    String? description,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    return AutomatonMetadata(
      createdAt: now,
      modifiedAt: now,
      createdBy: createdBy,
      description: description,
      tags: tags ?? [],
    );
  }

  /// Updates the modified timestamp
  AutomatonMetadata touch() {
    return copyWith(modifiedAt: DateTime.now());
  }
}
