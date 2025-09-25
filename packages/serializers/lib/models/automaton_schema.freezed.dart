// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'automaton_schema.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AutomatonSchema _$AutomatonSchemaFromJson(Map<String, dynamic> json) {
  return _AutomatonSchema.fromJson(json);
}

/// @nodoc
mixin _$AutomatonSchema {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  AutomatonType get type => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;
  List<String> get requiredFields => throw _privateConstructorUsedError;
  List<String> get optionalFields => throw _privateConstructorUsedError;
  Map<String, dynamic> get validationRules =>
      throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get author => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this AutomatonSchema to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AutomatonSchema
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AutomatonSchemaCopyWith<AutomatonSchema> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AutomatonSchemaCopyWith<$Res> {
  factory $AutomatonSchemaCopyWith(
          AutomatonSchema value, $Res Function(AutomatonSchema) then) =
      _$AutomatonSchemaCopyWithImpl<$Res, AutomatonSchema>;
  @useResult
  $Res call(
      {String id,
      String name,
      AutomatonType type,
      String version,
      Map<String, dynamic> metadata,
      List<String> requiredFields,
      List<String> optionalFields,
      Map<String, dynamic> validationRules,
      String? description,
      String? author,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$AutomatonSchemaCopyWithImpl<$Res, $Val extends AutomatonSchema>
    implements $AutomatonSchemaCopyWith<$Res> {
  _$AutomatonSchemaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AutomatonSchema
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? version = null,
    Object? metadata = null,
    Object? requiredFields = null,
    Object? optionalFields = null,
    Object? validationRules = null,
    Object? description = freezed,
    Object? author = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as AutomatonType,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      requiredFields: null == requiredFields
          ? _value.requiredFields
          : requiredFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      optionalFields: null == optionalFields
          ? _value.optionalFields
          : optionalFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      validationRules: null == validationRules
          ? _value.validationRules
          : validationRules // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AutomatonSchemaImplCopyWith<$Res>
    implements $AutomatonSchemaCopyWith<$Res> {
  factory _$$AutomatonSchemaImplCopyWith(_$AutomatonSchemaImpl value,
          $Res Function(_$AutomatonSchemaImpl) then) =
      __$$AutomatonSchemaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      AutomatonType type,
      String version,
      Map<String, dynamic> metadata,
      List<String> requiredFields,
      List<String> optionalFields,
      Map<String, dynamic> validationRules,
      String? description,
      String? author,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$AutomatonSchemaImplCopyWithImpl<$Res>
    extends _$AutomatonSchemaCopyWithImpl<$Res, _$AutomatonSchemaImpl>
    implements _$$AutomatonSchemaImplCopyWith<$Res> {
  __$$AutomatonSchemaImplCopyWithImpl(
      _$AutomatonSchemaImpl _value, $Res Function(_$AutomatonSchemaImpl) _then)
      : super(_value, _then);

  /// Create a copy of AutomatonSchema
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? version = null,
    Object? metadata = null,
    Object? requiredFields = null,
    Object? optionalFields = null,
    Object? validationRules = null,
    Object? description = freezed,
    Object? author = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$AutomatonSchemaImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as AutomatonType,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      requiredFields: null == requiredFields
          ? _value._requiredFields
          : requiredFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      optionalFields: null == optionalFields
          ? _value._optionalFields
          : optionalFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      validationRules: null == validationRules
          ? _value._validationRules
          : validationRules // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AutomatonSchemaImpl implements _AutomatonSchema {
  const _$AutomatonSchemaImpl(
      {required this.id,
      required this.name,
      required this.type,
      required this.version,
      required final Map<String, dynamic> metadata,
      required final List<String> requiredFields,
      required final List<String> optionalFields,
      required final Map<String, dynamic> validationRules,
      this.description,
      this.author,
      this.createdAt,
      this.updatedAt})
      : _metadata = metadata,
        _requiredFields = requiredFields,
        _optionalFields = optionalFields,
        _validationRules = validationRules;

  factory _$AutomatonSchemaImpl.fromJson(Map<String, dynamic> json) =>
      _$$AutomatonSchemaImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final AutomatonType type;
  @override
  final String version;
  final Map<String, dynamic> _metadata;
  @override
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  final List<String> _requiredFields;
  @override
  List<String> get requiredFields {
    if (_requiredFields is EqualUnmodifiableListView) return _requiredFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredFields);
  }

  final List<String> _optionalFields;
  @override
  List<String> get optionalFields {
    if (_optionalFields is EqualUnmodifiableListView) return _optionalFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_optionalFields);
  }

  final Map<String, dynamic> _validationRules;
  @override
  Map<String, dynamic> get validationRules {
    if (_validationRules is EqualUnmodifiableMapView) return _validationRules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_validationRules);
  }

  @override
  final String? description;
  @override
  final String? author;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'AutomatonSchema(id: $id, name: $name, type: $type, version: $version, metadata: $metadata, requiredFields: $requiredFields, optionalFields: $optionalFields, validationRules: $validationRules, description: $description, author: $author, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AutomatonSchemaImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.version, version) || other.version == version) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            const DeepCollectionEquality()
                .equals(other._requiredFields, _requiredFields) &&
            const DeepCollectionEquality()
                .equals(other._optionalFields, _optionalFields) &&
            const DeepCollectionEquality()
                .equals(other._validationRules, _validationRules) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      version,
      const DeepCollectionEquality().hash(_metadata),
      const DeepCollectionEquality().hash(_requiredFields),
      const DeepCollectionEquality().hash(_optionalFields),
      const DeepCollectionEquality().hash(_validationRules),
      description,
      author,
      createdAt,
      updatedAt);

  /// Create a copy of AutomatonSchema
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AutomatonSchemaImplCopyWith<_$AutomatonSchemaImpl> get copyWith =>
      __$$AutomatonSchemaImplCopyWithImpl<_$AutomatonSchemaImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AutomatonSchemaImplToJson(
      this,
    );
  }
}

abstract class _AutomatonSchema implements AutomatonSchema {
  const factory _AutomatonSchema(
      {required final String id,
      required final String name,
      required final AutomatonType type,
      required final String version,
      required final Map<String, dynamic> metadata,
      required final List<String> requiredFields,
      required final List<String> optionalFields,
      required final Map<String, dynamic> validationRules,
      final String? description,
      final String? author,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$AutomatonSchemaImpl;

  factory _AutomatonSchema.fromJson(Map<String, dynamic> json) =
      _$AutomatonSchemaImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  AutomatonType get type;
  @override
  String get version;
  @override
  Map<String, dynamic> get metadata;
  @override
  List<String> get requiredFields;
  @override
  List<String> get optionalFields;
  @override
  Map<String, dynamic> get validationRules;
  @override
  String? get description;
  @override
  String? get author;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of AutomatonSchema
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AutomatonSchemaImplCopyWith<_$AutomatonSchemaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SchemaValidationResult _$SchemaValidationResultFromJson(
    Map<String, dynamic> json) {
  return _SchemaValidationResult.fromJson(json);
}

/// @nodoc
mixin _$SchemaValidationResult {
  bool get isValid => throw _privateConstructorUsedError;
  List<String> get errors => throw _privateConstructorUsedError;
  List<String> get warnings => throw _privateConstructorUsedError;
  Map<String, dynamic> get validatedData => throw _privateConstructorUsedError;

  /// Serializes this SchemaValidationResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SchemaValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SchemaValidationResultCopyWith<SchemaValidationResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SchemaValidationResultCopyWith<$Res> {
  factory $SchemaValidationResultCopyWith(SchemaValidationResult value,
          $Res Function(SchemaValidationResult) then) =
      _$SchemaValidationResultCopyWithImpl<$Res, SchemaValidationResult>;
  @useResult
  $Res call(
      {bool isValid,
      List<String> errors,
      List<String> warnings,
      Map<String, dynamic> validatedData});
}

/// @nodoc
class _$SchemaValidationResultCopyWithImpl<$Res,
        $Val extends SchemaValidationResult>
    implements $SchemaValidationResultCopyWith<$Res> {
  _$SchemaValidationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SchemaValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isValid = null,
    Object? errors = null,
    Object? warnings = null,
    Object? validatedData = null,
  }) {
    return _then(_value.copyWith(
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      errors: null == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      warnings: null == warnings
          ? _value.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      validatedData: null == validatedData
          ? _value.validatedData
          : validatedData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SchemaValidationResultImplCopyWith<$Res>
    implements $SchemaValidationResultCopyWith<$Res> {
  factory _$$SchemaValidationResultImplCopyWith(
          _$SchemaValidationResultImpl value,
          $Res Function(_$SchemaValidationResultImpl) then) =
      __$$SchemaValidationResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isValid,
      List<String> errors,
      List<String> warnings,
      Map<String, dynamic> validatedData});
}

/// @nodoc
class __$$SchemaValidationResultImplCopyWithImpl<$Res>
    extends _$SchemaValidationResultCopyWithImpl<$Res,
        _$SchemaValidationResultImpl>
    implements _$$SchemaValidationResultImplCopyWith<$Res> {
  __$$SchemaValidationResultImplCopyWithImpl(
      _$SchemaValidationResultImpl _value,
      $Res Function(_$SchemaValidationResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of SchemaValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isValid = null,
    Object? errors = null,
    Object? warnings = null,
    Object? validatedData = null,
  }) {
    return _then(_$SchemaValidationResultImpl(
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      errors: null == errors
          ? _value._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      warnings: null == warnings
          ? _value._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      validatedData: null == validatedData
          ? _value._validatedData
          : validatedData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SchemaValidationResultImpl implements _SchemaValidationResult {
  const _$SchemaValidationResultImpl(
      {required this.isValid,
      required final List<String> errors,
      required final List<String> warnings,
      required final Map<String, dynamic> validatedData})
      : _errors = errors,
        _warnings = warnings,
        _validatedData = validatedData;

  factory _$SchemaValidationResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$SchemaValidationResultImplFromJson(json);

  @override
  final bool isValid;
  final List<String> _errors;
  @override
  List<String> get errors {
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_errors);
  }

  final List<String> _warnings;
  @override
  List<String> get warnings {
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_warnings);
  }

  final Map<String, dynamic> _validatedData;
  @override
  Map<String, dynamic> get validatedData {
    if (_validatedData is EqualUnmodifiableMapView) return _validatedData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_validatedData);
  }

  @override
  String toString() {
    return 'SchemaValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings, validatedData: $validatedData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SchemaValidationResultImpl &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            const DeepCollectionEquality().equals(other._errors, _errors) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings) &&
            const DeepCollectionEquality()
                .equals(other._validatedData, _validatedData));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      isValid,
      const DeepCollectionEquality().hash(_errors),
      const DeepCollectionEquality().hash(_warnings),
      const DeepCollectionEquality().hash(_validatedData));

  /// Create a copy of SchemaValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SchemaValidationResultImplCopyWith<_$SchemaValidationResultImpl>
      get copyWith => __$$SchemaValidationResultImplCopyWithImpl<
          _$SchemaValidationResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SchemaValidationResultImplToJson(
      this,
    );
  }
}

abstract class _SchemaValidationResult implements SchemaValidationResult {
  const factory _SchemaValidationResult(
          {required final bool isValid,
          required final List<String> errors,
          required final List<String> warnings,
          required final Map<String, dynamic> validatedData}) =
      _$SchemaValidationResultImpl;

  factory _SchemaValidationResult.fromJson(Map<String, dynamic> json) =
      _$SchemaValidationResultImpl.fromJson;

  @override
  bool get isValid;
  @override
  List<String> get errors;
  @override
  List<String> get warnings;
  @override
  Map<String, dynamic> get validatedData;

  /// Create a copy of SchemaValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SchemaValidationResultImplCopyWith<_$SchemaValidationResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SchemaRegistry _$SchemaRegistryFromJson(Map<String, dynamic> json) {
  return _SchemaRegistry.fromJson(json);
}

/// @nodoc
mixin _$SchemaRegistry {
  Map<String, AutomatonSchema> get schemas =>
      throw _privateConstructorUsedError;
  List<String> get supportedTypes => throw _privateConstructorUsedError;
  String? get defaultSchema => throw _privateConstructorUsedError;

  /// Serializes this SchemaRegistry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SchemaRegistry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SchemaRegistryCopyWith<SchemaRegistry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SchemaRegistryCopyWith<$Res> {
  factory $SchemaRegistryCopyWith(
          SchemaRegistry value, $Res Function(SchemaRegistry) then) =
      _$SchemaRegistryCopyWithImpl<$Res, SchemaRegistry>;
  @useResult
  $Res call(
      {Map<String, AutomatonSchema> schemas,
      List<String> supportedTypes,
      String? defaultSchema});
}

/// @nodoc
class _$SchemaRegistryCopyWithImpl<$Res, $Val extends SchemaRegistry>
    implements $SchemaRegistryCopyWith<$Res> {
  _$SchemaRegistryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SchemaRegistry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemas = null,
    Object? supportedTypes = null,
    Object? defaultSchema = freezed,
  }) {
    return _then(_value.copyWith(
      schemas: null == schemas
          ? _value.schemas
          : schemas // ignore: cast_nullable_to_non_nullable
              as Map<String, AutomatonSchema>,
      supportedTypes: null == supportedTypes
          ? _value.supportedTypes
          : supportedTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      defaultSchema: freezed == defaultSchema
          ? _value.defaultSchema
          : defaultSchema // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SchemaRegistryImplCopyWith<$Res>
    implements $SchemaRegistryCopyWith<$Res> {
  factory _$$SchemaRegistryImplCopyWith(_$SchemaRegistryImpl value,
          $Res Function(_$SchemaRegistryImpl) then) =
      __$$SchemaRegistryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Map<String, AutomatonSchema> schemas,
      List<String> supportedTypes,
      String? defaultSchema});
}

/// @nodoc
class __$$SchemaRegistryImplCopyWithImpl<$Res>
    extends _$SchemaRegistryCopyWithImpl<$Res, _$SchemaRegistryImpl>
    implements _$$SchemaRegistryImplCopyWith<$Res> {
  __$$SchemaRegistryImplCopyWithImpl(
      _$SchemaRegistryImpl _value, $Res Function(_$SchemaRegistryImpl) _then)
      : super(_value, _then);

  /// Create a copy of SchemaRegistry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemas = null,
    Object? supportedTypes = null,
    Object? defaultSchema = freezed,
  }) {
    return _then(_$SchemaRegistryImpl(
      schemas: null == schemas
          ? _value._schemas
          : schemas // ignore: cast_nullable_to_non_nullable
              as Map<String, AutomatonSchema>,
      supportedTypes: null == supportedTypes
          ? _value._supportedTypes
          : supportedTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      defaultSchema: freezed == defaultSchema
          ? _value.defaultSchema
          : defaultSchema // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SchemaRegistryImpl implements _SchemaRegistry {
  const _$SchemaRegistryImpl(
      {final Map<String, AutomatonSchema> schemas = const {},
      final List<String> supportedTypes = const [],
      this.defaultSchema})
      : _schemas = schemas,
        _supportedTypes = supportedTypes;

  factory _$SchemaRegistryImpl.fromJson(Map<String, dynamic> json) =>
      _$$SchemaRegistryImplFromJson(json);

  final Map<String, AutomatonSchema> _schemas;
  @override
  @JsonKey()
  Map<String, AutomatonSchema> get schemas {
    if (_schemas is EqualUnmodifiableMapView) return _schemas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_schemas);
  }

  final List<String> _supportedTypes;
  @override
  @JsonKey()
  List<String> get supportedTypes {
    if (_supportedTypes is EqualUnmodifiableListView) return _supportedTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_supportedTypes);
  }

  @override
  final String? defaultSchema;

  @override
  String toString() {
    return 'SchemaRegistry(schemas: $schemas, supportedTypes: $supportedTypes, defaultSchema: $defaultSchema)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SchemaRegistryImpl &&
            const DeepCollectionEquality().equals(other._schemas, _schemas) &&
            const DeepCollectionEquality()
                .equals(other._supportedTypes, _supportedTypes) &&
            (identical(other.defaultSchema, defaultSchema) ||
                other.defaultSchema == defaultSchema));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_schemas),
      const DeepCollectionEquality().hash(_supportedTypes),
      defaultSchema);

  /// Create a copy of SchemaRegistry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SchemaRegistryImplCopyWith<_$SchemaRegistryImpl> get copyWith =>
      __$$SchemaRegistryImplCopyWithImpl<_$SchemaRegistryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SchemaRegistryImplToJson(
      this,
    );
  }
}

abstract class _SchemaRegistry implements SchemaRegistry {
  const factory _SchemaRegistry(
      {final Map<String, AutomatonSchema> schemas,
      final List<String> supportedTypes,
      final String? defaultSchema}) = _$SchemaRegistryImpl;

  factory _SchemaRegistry.fromJson(Map<String, dynamic> json) =
      _$SchemaRegistryImpl.fromJson;

  @override
  Map<String, AutomatonSchema> get schemas;
  @override
  List<String> get supportedTypes;
  @override
  String? get defaultSchema;

  /// Create a copy of SchemaRegistry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SchemaRegistryImplCopyWith<_$SchemaRegistryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
