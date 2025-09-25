// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jflap_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

JFLAPFile _$JFLAPFileFromJson(Map<String, dynamic> json) {
  return _JFLAPFile.fromJson(json);
}

/// @nodoc
mixin _$JFLAPFile {
  String get version => throw _privateConstructorUsedError;
  JFLAPStructure get structure => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this JFLAPFile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JFLAPFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JFLAPFileCopyWith<JFLAPFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JFLAPFileCopyWith<$Res> {
  factory $JFLAPFileCopyWith(JFLAPFile value, $Res Function(JFLAPFile) then) =
      _$JFLAPFileCopyWithImpl<$Res, JFLAPFile>;
  @useResult
  $Res call(
      {String version,
      JFLAPStructure structure,
      String? comment,
      Map<String, dynamic>? metadata});

  $JFLAPStructureCopyWith<$Res> get structure;
}

/// @nodoc
class _$JFLAPFileCopyWithImpl<$Res, $Val extends JFLAPFile>
    implements $JFLAPFileCopyWith<$Res> {
  _$JFLAPFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JFLAPFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? structure = null,
    Object? comment = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      structure: null == structure
          ? _value.structure
          : structure // ignore: cast_nullable_to_non_nullable
              as JFLAPStructure,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }

  /// Create a copy of JFLAPFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JFLAPStructureCopyWith<$Res> get structure {
    return $JFLAPStructureCopyWith<$Res>(_value.structure, (value) {
      return _then(_value.copyWith(structure: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$JFLAPFileImplCopyWith<$Res>
    implements $JFLAPFileCopyWith<$Res> {
  factory _$$JFLAPFileImplCopyWith(
          _$JFLAPFileImpl value, $Res Function(_$JFLAPFileImpl) then) =
      __$$JFLAPFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String version,
      JFLAPStructure structure,
      String? comment,
      Map<String, dynamic>? metadata});

  @override
  $JFLAPStructureCopyWith<$Res> get structure;
}

/// @nodoc
class __$$JFLAPFileImplCopyWithImpl<$Res>
    extends _$JFLAPFileCopyWithImpl<$Res, _$JFLAPFileImpl>
    implements _$$JFLAPFileImplCopyWith<$Res> {
  __$$JFLAPFileImplCopyWithImpl(
      _$JFLAPFileImpl _value, $Res Function(_$JFLAPFileImpl) _then)
      : super(_value, _then);

  /// Create a copy of JFLAPFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? structure = null,
    Object? comment = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$JFLAPFileImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      structure: null == structure
          ? _value.structure
          : structure // ignore: cast_nullable_to_non_nullable
              as JFLAPStructure,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JFLAPFileImpl implements _JFLAPFile {
  const _$JFLAPFileImpl(
      {required this.version,
      required this.structure,
      this.comment,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;

  factory _$JFLAPFileImpl.fromJson(Map<String, dynamic> json) =>
      _$$JFLAPFileImplFromJson(json);

  @override
  final String version;
  @override
  final JFLAPStructure structure;
  @override
  final String? comment;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'JFLAPFile(version: $version, structure: $structure, comment: $comment, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JFLAPFileImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.structure, structure) ||
                other.structure == structure) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, version, structure, comment,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of JFLAPFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JFLAPFileImplCopyWith<_$JFLAPFileImpl> get copyWith =>
      __$$JFLAPFileImplCopyWithImpl<_$JFLAPFileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JFLAPFileImplToJson(
      this,
    );
  }
}

abstract class _JFLAPFile implements JFLAPFile {
  const factory _JFLAPFile(
      {required final String version,
      required final JFLAPStructure structure,
      final String? comment,
      final Map<String, dynamic>? metadata}) = _$JFLAPFileImpl;

  factory _JFLAPFile.fromJson(Map<String, dynamic> json) =
      _$JFLAPFileImpl.fromJson;

  @override
  String get version;
  @override
  JFLAPStructure get structure;
  @override
  String? get comment;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of JFLAPFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JFLAPFileImplCopyWith<_$JFLAPFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

JFLAPStructure _$JFLAPStructureFromJson(Map<String, dynamic> json) {
  return _JFLAPStructure.fromJson(json);
}

/// @nodoc
mixin _$JFLAPStructure {
  JFLAPType get type => throw _privateConstructorUsedError;
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<JFLAPState> get states => throw _privateConstructorUsedError;
  List<JFLAPTransition> get transitions => throw _privateConstructorUsedError;
  List<String> get alphabet => throw _privateConstructorUsedError;
  String? get startState => throw _privateConstructorUsedError;
  List<String> get finalStates => throw _privateConstructorUsedError;
  Map<String, dynamic>? get properties => throw _privateConstructorUsedError;

  /// Serializes this JFLAPStructure to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JFLAPStructure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JFLAPStructureCopyWith<JFLAPStructure> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JFLAPStructureCopyWith<$Res> {
  factory $JFLAPStructureCopyWith(
          JFLAPStructure value, $Res Function(JFLAPStructure) then) =
      _$JFLAPStructureCopyWithImpl<$Res, JFLAPStructure>;
  @useResult
  $Res call(
      {JFLAPType type,
      String id,
      String name,
      List<JFLAPState> states,
      List<JFLAPTransition> transitions,
      List<String> alphabet,
      String? startState,
      List<String> finalStates,
      Map<String, dynamic>? properties});
}

/// @nodoc
class _$JFLAPStructureCopyWithImpl<$Res, $Val extends JFLAPStructure>
    implements $JFLAPStructureCopyWith<$Res> {
  _$JFLAPStructureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JFLAPStructure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? id = null,
    Object? name = null,
    Object? states = null,
    Object? transitions = null,
    Object? alphabet = null,
    Object? startState = freezed,
    Object? finalStates = null,
    Object? properties = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as JFLAPType,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      states: null == states
          ? _value.states
          : states // ignore: cast_nullable_to_non_nullable
              as List<JFLAPState>,
      transitions: null == transitions
          ? _value.transitions
          : transitions // ignore: cast_nullable_to_non_nullable
              as List<JFLAPTransition>,
      alphabet: null == alphabet
          ? _value.alphabet
          : alphabet // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startState: freezed == startState
          ? _value.startState
          : startState // ignore: cast_nullable_to_non_nullable
              as String?,
      finalStates: null == finalStates
          ? _value.finalStates
          : finalStates // ignore: cast_nullable_to_non_nullable
              as List<String>,
      properties: freezed == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JFLAPStructureImplCopyWith<$Res>
    implements $JFLAPStructureCopyWith<$Res> {
  factory _$$JFLAPStructureImplCopyWith(_$JFLAPStructureImpl value,
          $Res Function(_$JFLAPStructureImpl) then) =
      __$$JFLAPStructureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {JFLAPType type,
      String id,
      String name,
      List<JFLAPState> states,
      List<JFLAPTransition> transitions,
      List<String> alphabet,
      String? startState,
      List<String> finalStates,
      Map<String, dynamic>? properties});
}

/// @nodoc
class __$$JFLAPStructureImplCopyWithImpl<$Res>
    extends _$JFLAPStructureCopyWithImpl<$Res, _$JFLAPStructureImpl>
    implements _$$JFLAPStructureImplCopyWith<$Res> {
  __$$JFLAPStructureImplCopyWithImpl(
      _$JFLAPStructureImpl _value, $Res Function(_$JFLAPStructureImpl) _then)
      : super(_value, _then);

  /// Create a copy of JFLAPStructure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? id = null,
    Object? name = null,
    Object? states = null,
    Object? transitions = null,
    Object? alphabet = null,
    Object? startState = freezed,
    Object? finalStates = null,
    Object? properties = freezed,
  }) {
    return _then(_$JFLAPStructureImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as JFLAPType,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      states: null == states
          ? _value._states
          : states // ignore: cast_nullable_to_non_nullable
              as List<JFLAPState>,
      transitions: null == transitions
          ? _value._transitions
          : transitions // ignore: cast_nullable_to_non_nullable
              as List<JFLAPTransition>,
      alphabet: null == alphabet
          ? _value._alphabet
          : alphabet // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startState: freezed == startState
          ? _value.startState
          : startState // ignore: cast_nullable_to_non_nullable
              as String?,
      finalStates: null == finalStates
          ? _value._finalStates
          : finalStates // ignore: cast_nullable_to_non_nullable
              as List<String>,
      properties: freezed == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JFLAPStructureImpl implements _JFLAPStructure {
  const _$JFLAPStructureImpl(
      {required this.type,
      required this.id,
      required this.name,
      required final List<JFLAPState> states,
      required final List<JFLAPTransition> transitions,
      required final List<String> alphabet,
      this.startState,
      required final List<String> finalStates,
      final Map<String, dynamic>? properties})
      : _states = states,
        _transitions = transitions,
        _alphabet = alphabet,
        _finalStates = finalStates,
        _properties = properties;

  factory _$JFLAPStructureImpl.fromJson(Map<String, dynamic> json) =>
      _$$JFLAPStructureImplFromJson(json);

  @override
  final JFLAPType type;
  @override
  final String id;
  @override
  final String name;
  final List<JFLAPState> _states;
  @override
  List<JFLAPState> get states {
    if (_states is EqualUnmodifiableListView) return _states;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_states);
  }

  final List<JFLAPTransition> _transitions;
  @override
  List<JFLAPTransition> get transitions {
    if (_transitions is EqualUnmodifiableListView) return _transitions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transitions);
  }

  final List<String> _alphabet;
  @override
  List<String> get alphabet {
    if (_alphabet is EqualUnmodifiableListView) return _alphabet;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_alphabet);
  }

  @override
  final String? startState;
  final List<String> _finalStates;
  @override
  List<String> get finalStates {
    if (_finalStates is EqualUnmodifiableListView) return _finalStates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_finalStates);
  }

  final Map<String, dynamic>? _properties;
  @override
  Map<String, dynamic>? get properties {
    final value = _properties;
    if (value == null) return null;
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'JFLAPStructure(type: $type, id: $id, name: $name, states: $states, transitions: $transitions, alphabet: $alphabet, startState: $startState, finalStates: $finalStates, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JFLAPStructureImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._states, _states) &&
            const DeepCollectionEquality()
                .equals(other._transitions, _transitions) &&
            const DeepCollectionEquality().equals(other._alphabet, _alphabet) &&
            (identical(other.startState, startState) ||
                other.startState == startState) &&
            const DeepCollectionEquality()
                .equals(other._finalStates, _finalStates) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      id,
      name,
      const DeepCollectionEquality().hash(_states),
      const DeepCollectionEquality().hash(_transitions),
      const DeepCollectionEquality().hash(_alphabet),
      startState,
      const DeepCollectionEquality().hash(_finalStates),
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of JFLAPStructure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JFLAPStructureImplCopyWith<_$JFLAPStructureImpl> get copyWith =>
      __$$JFLAPStructureImplCopyWithImpl<_$JFLAPStructureImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JFLAPStructureImplToJson(
      this,
    );
  }
}

abstract class _JFLAPStructure implements JFLAPStructure {
  const factory _JFLAPStructure(
      {required final JFLAPType type,
      required final String id,
      required final String name,
      required final List<JFLAPState> states,
      required final List<JFLAPTransition> transitions,
      required final List<String> alphabet,
      final String? startState,
      required final List<String> finalStates,
      final Map<String, dynamic>? properties}) = _$JFLAPStructureImpl;

  factory _JFLAPStructure.fromJson(Map<String, dynamic> json) =
      _$JFLAPStructureImpl.fromJson;

  @override
  JFLAPType get type;
  @override
  String get id;
  @override
  String get name;
  @override
  List<JFLAPState> get states;
  @override
  List<JFLAPTransition> get transitions;
  @override
  List<String> get alphabet;
  @override
  String? get startState;
  @override
  List<String> get finalStates;
  @override
  Map<String, dynamic>? get properties;

  /// Create a copy of JFLAPStructure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JFLAPStructureImplCopyWith<_$JFLAPStructureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

JFLAPState _$JFLAPStateFromJson(Map<String, dynamic> json) {
  return _JFLAPState.fromJson(json);
}

/// @nodoc
mixin _$JFLAPState {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;
  bool get isInitial => throw _privateConstructorUsedError;
  bool get isFinal => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  Map<String, dynamic>? get properties => throw _privateConstructorUsedError;

  /// Serializes this JFLAPState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JFLAPState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JFLAPStateCopyWith<JFLAPState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JFLAPStateCopyWith<$Res> {
  factory $JFLAPStateCopyWith(
          JFLAPState value, $Res Function(JFLAPState) then) =
      _$JFLAPStateCopyWithImpl<$Res, JFLAPState>;
  @useResult
  $Res call(
      {String id,
      String name,
      double x,
      double y,
      bool isInitial,
      bool isFinal,
      String? label,
      Map<String, dynamic>? properties});
}

/// @nodoc
class _$JFLAPStateCopyWithImpl<$Res, $Val extends JFLAPState>
    implements $JFLAPStateCopyWith<$Res> {
  _$JFLAPStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JFLAPState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? x = null,
    Object? y = null,
    Object? isInitial = null,
    Object? isFinal = null,
    Object? label = freezed,
    Object? properties = freezed,
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
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      isInitial: null == isInitial
          ? _value.isInitial
          : isInitial // ignore: cast_nullable_to_non_nullable
              as bool,
      isFinal: null == isFinal
          ? _value.isFinal
          : isFinal // ignore: cast_nullable_to_non_nullable
              as bool,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      properties: freezed == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JFLAPStateImplCopyWith<$Res>
    implements $JFLAPStateCopyWith<$Res> {
  factory _$$JFLAPStateImplCopyWith(
          _$JFLAPStateImpl value, $Res Function(_$JFLAPStateImpl) then) =
      __$$JFLAPStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      double x,
      double y,
      bool isInitial,
      bool isFinal,
      String? label,
      Map<String, dynamic>? properties});
}

/// @nodoc
class __$$JFLAPStateImplCopyWithImpl<$Res>
    extends _$JFLAPStateCopyWithImpl<$Res, _$JFLAPStateImpl>
    implements _$$JFLAPStateImplCopyWith<$Res> {
  __$$JFLAPStateImplCopyWithImpl(
      _$JFLAPStateImpl _value, $Res Function(_$JFLAPStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of JFLAPState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? x = null,
    Object? y = null,
    Object? isInitial = null,
    Object? isFinal = null,
    Object? label = freezed,
    Object? properties = freezed,
  }) {
    return _then(_$JFLAPStateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      isInitial: null == isInitial
          ? _value.isInitial
          : isInitial // ignore: cast_nullable_to_non_nullable
              as bool,
      isFinal: null == isFinal
          ? _value.isFinal
          : isFinal // ignore: cast_nullable_to_non_nullable
              as bool,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      properties: freezed == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JFLAPStateImpl implements _JFLAPState {
  const _$JFLAPStateImpl(
      {required this.id,
      required this.name,
      required this.x,
      required this.y,
      required this.isInitial,
      required this.isFinal,
      this.label,
      final Map<String, dynamic>? properties})
      : _properties = properties;

  factory _$JFLAPStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$JFLAPStateImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double x;
  @override
  final double y;
  @override
  final bool isInitial;
  @override
  final bool isFinal;
  @override
  final String? label;
  final Map<String, dynamic>? _properties;
  @override
  Map<String, dynamic>? get properties {
    final value = _properties;
    if (value == null) return null;
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'JFLAPState(id: $id, name: $name, x: $x, y: $y, isInitial: $isInitial, isFinal: $isFinal, label: $label, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JFLAPStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.isInitial, isInitial) ||
                other.isInitial == isInitial) &&
            (identical(other.isFinal, isFinal) || other.isFinal == isFinal) &&
            (identical(other.label, label) || other.label == label) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, x, y, isInitial,
      isFinal, label, const DeepCollectionEquality().hash(_properties));

  /// Create a copy of JFLAPState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JFLAPStateImplCopyWith<_$JFLAPStateImpl> get copyWith =>
      __$$JFLAPStateImplCopyWithImpl<_$JFLAPStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JFLAPStateImplToJson(
      this,
    );
  }
}

abstract class _JFLAPState implements JFLAPState {
  const factory _JFLAPState(
      {required final String id,
      required final String name,
      required final double x,
      required final double y,
      required final bool isInitial,
      required final bool isFinal,
      final String? label,
      final Map<String, dynamic>? properties}) = _$JFLAPStateImpl;

  factory _JFLAPState.fromJson(Map<String, dynamic> json) =
      _$JFLAPStateImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get x;
  @override
  double get y;
  @override
  bool get isInitial;
  @override
  bool get isFinal;
  @override
  String? get label;
  @override
  Map<String, dynamic>? get properties;

  /// Create a copy of JFLAPState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JFLAPStateImplCopyWith<_$JFLAPStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

JFLAPTransition _$JFLAPTransitionFromJson(Map<String, dynamic> json) {
  return _JFLAPTransition.fromJson(json);
}

/// @nodoc
mixin _$JFLAPTransition {
  String get from => throw _privateConstructorUsedError;
  String get to => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String? get stackSymbol => throw _privateConstructorUsedError;
  String? get stackAction => throw _privateConstructorUsedError;
  Map<String, dynamic>? get properties => throw _privateConstructorUsedError;

  /// Serializes this JFLAPTransition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JFLAPTransition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JFLAPTransitionCopyWith<JFLAPTransition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JFLAPTransitionCopyWith<$Res> {
  factory $JFLAPTransitionCopyWith(
          JFLAPTransition value, $Res Function(JFLAPTransition) then) =
      _$JFLAPTransitionCopyWithImpl<$Res, JFLAPTransition>;
  @useResult
  $Res call(
      {String from,
      String to,
      String label,
      String? stackSymbol,
      String? stackAction,
      Map<String, dynamic>? properties});
}

/// @nodoc
class _$JFLAPTransitionCopyWithImpl<$Res, $Val extends JFLAPTransition>
    implements $JFLAPTransitionCopyWith<$Res> {
  _$JFLAPTransitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JFLAPTransition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? from = null,
    Object? to = null,
    Object? label = null,
    Object? stackSymbol = freezed,
    Object? stackAction = freezed,
    Object? properties = freezed,
  }) {
    return _then(_value.copyWith(
      from: null == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      stackSymbol: freezed == stackSymbol
          ? _value.stackSymbol
          : stackSymbol // ignore: cast_nullable_to_non_nullable
              as String?,
      stackAction: freezed == stackAction
          ? _value.stackAction
          : stackAction // ignore: cast_nullable_to_non_nullable
              as String?,
      properties: freezed == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JFLAPTransitionImplCopyWith<$Res>
    implements $JFLAPTransitionCopyWith<$Res> {
  factory _$$JFLAPTransitionImplCopyWith(_$JFLAPTransitionImpl value,
          $Res Function(_$JFLAPTransitionImpl) then) =
      __$$JFLAPTransitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String from,
      String to,
      String label,
      String? stackSymbol,
      String? stackAction,
      Map<String, dynamic>? properties});
}

/// @nodoc
class __$$JFLAPTransitionImplCopyWithImpl<$Res>
    extends _$JFLAPTransitionCopyWithImpl<$Res, _$JFLAPTransitionImpl>
    implements _$$JFLAPTransitionImplCopyWith<$Res> {
  __$$JFLAPTransitionImplCopyWithImpl(
      _$JFLAPTransitionImpl _value, $Res Function(_$JFLAPTransitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of JFLAPTransition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? from = null,
    Object? to = null,
    Object? label = null,
    Object? stackSymbol = freezed,
    Object? stackAction = freezed,
    Object? properties = freezed,
  }) {
    return _then(_$JFLAPTransitionImpl(
      from: null == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      stackSymbol: freezed == stackSymbol
          ? _value.stackSymbol
          : stackSymbol // ignore: cast_nullable_to_non_nullable
              as String?,
      stackAction: freezed == stackAction
          ? _value.stackAction
          : stackAction // ignore: cast_nullable_to_non_nullable
              as String?,
      properties: freezed == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JFLAPTransitionImpl implements _JFLAPTransition {
  const _$JFLAPTransitionImpl(
      {required this.from,
      required this.to,
      required this.label,
      this.stackSymbol,
      this.stackAction,
      final Map<String, dynamic>? properties})
      : _properties = properties;

  factory _$JFLAPTransitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$JFLAPTransitionImplFromJson(json);

  @override
  final String from;
  @override
  final String to;
  @override
  final String label;
  @override
  final String? stackSymbol;
  @override
  final String? stackAction;
  final Map<String, dynamic>? _properties;
  @override
  Map<String, dynamic>? get properties {
    final value = _properties;
    if (value == null) return null;
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'JFLAPTransition(from: $from, to: $to, label: $label, stackSymbol: $stackSymbol, stackAction: $stackAction, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JFLAPTransitionImpl &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.stackSymbol, stackSymbol) ||
                other.stackSymbol == stackSymbol) &&
            (identical(other.stackAction, stackAction) ||
                other.stackAction == stackAction) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, from, to, label, stackSymbol,
      stackAction, const DeepCollectionEquality().hash(_properties));

  /// Create a copy of JFLAPTransition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JFLAPTransitionImplCopyWith<_$JFLAPTransitionImpl> get copyWith =>
      __$$JFLAPTransitionImplCopyWithImpl<_$JFLAPTransitionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JFLAPTransitionImplToJson(
      this,
    );
  }
}

abstract class _JFLAPTransition implements JFLAPTransition {
  const factory _JFLAPTransition(
      {required final String from,
      required final String to,
      required final String label,
      final String? stackSymbol,
      final String? stackAction,
      final Map<String, dynamic>? properties}) = _$JFLAPTransitionImpl;

  factory _JFLAPTransition.fromJson(Map<String, dynamic> json) =
      _$JFLAPTransitionImpl.fromJson;

  @override
  String get from;
  @override
  String get to;
  @override
  String get label;
  @override
  String? get stackSymbol;
  @override
  String? get stackAction;
  @override
  Map<String, dynamic>? get properties;

  /// Create a copy of JFLAPTransition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JFLAPTransitionImplCopyWith<_$JFLAPTransitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

JFLAPResult _$JFLAPResultFromJson(Map<String, dynamic> json) {
  return _JFLAPResult.fromJson(json);
}

/// @nodoc
mixin _$JFLAPResult {
  bool get success => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  JFLAPFile get file => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this JFLAPResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JFLAPResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JFLAPResultCopyWith<JFLAPResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JFLAPResultCopyWith<$Res> {
  factory $JFLAPResultCopyWith(
          JFLAPResult value, $Res Function(JFLAPResult) then) =
      _$JFLAPResultCopyWithImpl<$Res, JFLAPResult>;
  @useResult
  $Res call(
      {bool success,
      String? error,
      JFLAPFile file,
      Map<String, dynamic> metadata});

  $JFLAPFileCopyWith<$Res> get file;
}

/// @nodoc
class _$JFLAPResultCopyWithImpl<$Res, $Val extends JFLAPResult>
    implements $JFLAPResultCopyWith<$Res> {
  _$JFLAPResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JFLAPResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? error = freezed,
    Object? file = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      file: null == file
          ? _value.file
          : file // ignore: cast_nullable_to_non_nullable
              as JFLAPFile,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  /// Create a copy of JFLAPResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JFLAPFileCopyWith<$Res> get file {
    return $JFLAPFileCopyWith<$Res>(_value.file, (value) {
      return _then(_value.copyWith(file: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$JFLAPResultImplCopyWith<$Res>
    implements $JFLAPResultCopyWith<$Res> {
  factory _$$JFLAPResultImplCopyWith(
          _$JFLAPResultImpl value, $Res Function(_$JFLAPResultImpl) then) =
      __$$JFLAPResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      String? error,
      JFLAPFile file,
      Map<String, dynamic> metadata});

  @override
  $JFLAPFileCopyWith<$Res> get file;
}

/// @nodoc
class __$$JFLAPResultImplCopyWithImpl<$Res>
    extends _$JFLAPResultCopyWithImpl<$Res, _$JFLAPResultImpl>
    implements _$$JFLAPResultImplCopyWith<$Res> {
  __$$JFLAPResultImplCopyWithImpl(
      _$JFLAPResultImpl _value, $Res Function(_$JFLAPResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of JFLAPResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? error = freezed,
    Object? file = null,
    Object? metadata = null,
  }) {
    return _then(_$JFLAPResultImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      file: null == file
          ? _value.file
          : file // ignore: cast_nullable_to_non_nullable
              as JFLAPFile,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JFLAPResultImpl implements _JFLAPResult {
  const _$JFLAPResultImpl(
      {required this.success,
      this.error,
      required this.file,
      required final Map<String, dynamic> metadata})
      : _metadata = metadata;

  factory _$JFLAPResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$JFLAPResultImplFromJson(json);

  @override
  final bool success;
  @override
  final String? error;
  @override
  final JFLAPFile file;
  final Map<String, dynamic> _metadata;
  @override
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'JFLAPResult(success: $success, error: $error, file: $file, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JFLAPResultImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.file, file) || other.file == file) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, error, file,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of JFLAPResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JFLAPResultImplCopyWith<_$JFLAPResultImpl> get copyWith =>
      __$$JFLAPResultImplCopyWithImpl<_$JFLAPResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JFLAPResultImplToJson(
      this,
    );
  }
}

abstract class _JFLAPResult implements JFLAPResult {
  const factory _JFLAPResult(
      {required final bool success,
      final String? error,
      required final JFLAPFile file,
      required final Map<String, dynamic> metadata}) = _$JFLAPResultImpl;

  factory _JFLAPResult.fromJson(Map<String, dynamic> json) =
      _$JFLAPResultImpl.fromJson;

  @override
  bool get success;
  @override
  String? get error;
  @override
  JFLAPFile get file;
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of JFLAPResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JFLAPResultImplCopyWith<_$JFLAPResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
