// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grammar_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GrammarDto {

 String get id; String get name; String get type; List<String> get terminals; List<String> get variables; String get initialSymbol; Map<String, List<String>> get productions;
/// Create a copy of GrammarDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrammarDtoCopyWith<GrammarDto> get copyWith => _$GrammarDtoCopyWithImpl<GrammarDto>(this as GrammarDto, _$identity);

  /// Serializes this GrammarDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrammarDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.terminals, terminals)&&const DeepCollectionEquality().equals(other.variables, variables)&&(identical(other.initialSymbol, initialSymbol) || other.initialSymbol == initialSymbol)&&const DeepCollectionEquality().equals(other.productions, productions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,const DeepCollectionEquality().hash(terminals),const DeepCollectionEquality().hash(variables),initialSymbol,const DeepCollectionEquality().hash(productions));

@override
String toString() {
  return 'GrammarDto(id: $id, name: $name, type: $type, terminals: $terminals, variables: $variables, initialSymbol: $initialSymbol, productions: $productions)';
}


}

/// @nodoc
abstract mixin class $GrammarDtoCopyWith<$Res>  {
  factory $GrammarDtoCopyWith(GrammarDto value, $Res Function(GrammarDto) _then) = _$GrammarDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String type, List<String> terminals, List<String> variables, String initialSymbol, Map<String, List<String>> productions
});




}
/// @nodoc
class _$GrammarDtoCopyWithImpl<$Res>
    implements $GrammarDtoCopyWith<$Res> {
  _$GrammarDtoCopyWithImpl(this._self, this._then);

  final GrammarDto _self;
  final $Res Function(GrammarDto) _then;

/// Create a copy of GrammarDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? terminals = null,Object? variables = null,Object? initialSymbol = null,Object? productions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,terminals: null == terminals ? _self.terminals : terminals // ignore: cast_nullable_to_non_nullable
as List<String>,variables: null == variables ? _self.variables : variables // ignore: cast_nullable_to_non_nullable
as List<String>,initialSymbol: null == initialSymbol ? _self.initialSymbol : initialSymbol // ignore: cast_nullable_to_non_nullable
as String,productions: null == productions ? _self.productions : productions // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}

}


/// Adds pattern-matching-related methods to [GrammarDto].
extension GrammarDtoPatterns on GrammarDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrammarDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrammarDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrammarDto value)  $default,){
final _that = this;
switch (_that) {
case _GrammarDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrammarDto value)?  $default,){
final _that = this;
switch (_that) {
case _GrammarDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String type,  List<String> terminals,  List<String> variables,  String initialSymbol,  Map<String, List<String>> productions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrammarDto() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.terminals,_that.variables,_that.initialSymbol,_that.productions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String type,  List<String> terminals,  List<String> variables,  String initialSymbol,  Map<String, List<String>> productions)  $default,) {final _that = this;
switch (_that) {
case _GrammarDto():
return $default(_that.id,_that.name,_that.type,_that.terminals,_that.variables,_that.initialSymbol,_that.productions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String type,  List<String> terminals,  List<String> variables,  String initialSymbol,  Map<String, List<String>> productions)?  $default,) {final _that = this;
switch (_that) {
case _GrammarDto() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.terminals,_that.variables,_that.initialSymbol,_that.productions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GrammarDto implements GrammarDto {
  const _GrammarDto({required this.id, required this.name, required this.type, required final  List<String> terminals, required final  List<String> variables, required this.initialSymbol, required final  Map<String, List<String>> productions}): _terminals = terminals,_variables = variables,_productions = productions;
  factory _GrammarDto.fromJson(Map<String, dynamic> json) => _$GrammarDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String type;
 final  List<String> _terminals;
@override List<String> get terminals {
  if (_terminals is EqualUnmodifiableListView) return _terminals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_terminals);
}

 final  List<String> _variables;
@override List<String> get variables {
  if (_variables is EqualUnmodifiableListView) return _variables;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variables);
}

@override final  String initialSymbol;
 final  Map<String, List<String>> _productions;
@override Map<String, List<String>> get productions {
  if (_productions is EqualUnmodifiableMapView) return _productions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_productions);
}


/// Create a copy of GrammarDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrammarDtoCopyWith<_GrammarDto> get copyWith => __$GrammarDtoCopyWithImpl<_GrammarDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GrammarDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrammarDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._terminals, _terminals)&&const DeepCollectionEquality().equals(other._variables, _variables)&&(identical(other.initialSymbol, initialSymbol) || other.initialSymbol == initialSymbol)&&const DeepCollectionEquality().equals(other._productions, _productions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,const DeepCollectionEquality().hash(_terminals),const DeepCollectionEquality().hash(_variables),initialSymbol,const DeepCollectionEquality().hash(_productions));

@override
String toString() {
  return 'GrammarDto(id: $id, name: $name, type: $type, terminals: $terminals, variables: $variables, initialSymbol: $initialSymbol, productions: $productions)';
}


}

/// @nodoc
abstract mixin class _$GrammarDtoCopyWith<$Res> implements $GrammarDtoCopyWith<$Res> {
  factory _$GrammarDtoCopyWith(_GrammarDto value, $Res Function(_GrammarDto) _then) = __$GrammarDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String type, List<String> terminals, List<String> variables, String initialSymbol, Map<String, List<String>> productions
});




}
/// @nodoc
class __$GrammarDtoCopyWithImpl<$Res>
    implements _$GrammarDtoCopyWith<$Res> {
  __$GrammarDtoCopyWithImpl(this._self, this._then);

  final _GrammarDto _self;
  final $Res Function(_GrammarDto) _then;

/// Create a copy of GrammarDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? terminals = null,Object? variables = null,Object? initialSymbol = null,Object? productions = null,}) {
  return _then(_GrammarDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,terminals: null == terminals ? _self._terminals : terminals // ignore: cast_nullable_to_non_nullable
as List<String>,variables: null == variables ? _self._variables : variables // ignore: cast_nullable_to_non_nullable
as List<String>,initialSymbol: null == initialSymbol ? _self.initialSymbol : initialSymbol // ignore: cast_nullable_to_non_nullable
as String,productions: null == productions ? _self._productions : productions // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}


}


/// @nodoc
mixin _$JflapGrammarDto {

 String get type; JflapGrammarStructureDto get structure;
/// Create a copy of JflapGrammarDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JflapGrammarDtoCopyWith<JflapGrammarDto> get copyWith => _$JflapGrammarDtoCopyWithImpl<JflapGrammarDto>(this as JflapGrammarDto, _$identity);

  /// Serializes this JflapGrammarDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JflapGrammarDto&&(identical(other.type, type) || other.type == type)&&(identical(other.structure, structure) || other.structure == structure));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,structure);

@override
String toString() {
  return 'JflapGrammarDto(type: $type, structure: $structure)';
}


}

/// @nodoc
abstract mixin class $JflapGrammarDtoCopyWith<$Res>  {
  factory $JflapGrammarDtoCopyWith(JflapGrammarDto value, $Res Function(JflapGrammarDto) _then) = _$JflapGrammarDtoCopyWithImpl;
@useResult
$Res call({
 String type, JflapGrammarStructureDto structure
});


$JflapGrammarStructureDtoCopyWith<$Res> get structure;

}
/// @nodoc
class _$JflapGrammarDtoCopyWithImpl<$Res>
    implements $JflapGrammarDtoCopyWith<$Res> {
  _$JflapGrammarDtoCopyWithImpl(this._self, this._then);

  final JflapGrammarDto _self;
  final $Res Function(JflapGrammarDto) _then;

/// Create a copy of JflapGrammarDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? structure = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,structure: null == structure ? _self.structure : structure // ignore: cast_nullable_to_non_nullable
as JflapGrammarStructureDto,
  ));
}
/// Create a copy of JflapGrammarDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JflapGrammarStructureDtoCopyWith<$Res> get structure {
  
  return $JflapGrammarStructureDtoCopyWith<$Res>(_self.structure, (value) {
    return _then(_self.copyWith(structure: value));
  });
}
}


/// Adds pattern-matching-related methods to [JflapGrammarDto].
extension JflapGrammarDtoPatterns on JflapGrammarDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JflapGrammarDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JflapGrammarDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JflapGrammarDto value)  $default,){
final _that = this;
switch (_that) {
case _JflapGrammarDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JflapGrammarDto value)?  $default,){
final _that = this;
switch (_that) {
case _JflapGrammarDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  JflapGrammarStructureDto structure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JflapGrammarDto() when $default != null:
return $default(_that.type,_that.structure);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  JflapGrammarStructureDto structure)  $default,) {final _that = this;
switch (_that) {
case _JflapGrammarDto():
return $default(_that.type,_that.structure);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  JflapGrammarStructureDto structure)?  $default,) {final _that = this;
switch (_that) {
case _JflapGrammarDto() when $default != null:
return $default(_that.type,_that.structure);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JflapGrammarDto implements JflapGrammarDto {
  const _JflapGrammarDto({required this.type, required this.structure});
  factory _JflapGrammarDto.fromJson(Map<String, dynamic> json) => _$JflapGrammarDtoFromJson(json);

@override final  String type;
@override final  JflapGrammarStructureDto structure;

/// Create a copy of JflapGrammarDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JflapGrammarDtoCopyWith<_JflapGrammarDto> get copyWith => __$JflapGrammarDtoCopyWithImpl<_JflapGrammarDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JflapGrammarDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JflapGrammarDto&&(identical(other.type, type) || other.type == type)&&(identical(other.structure, structure) || other.structure == structure));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,structure);

@override
String toString() {
  return 'JflapGrammarDto(type: $type, structure: $structure)';
}


}

/// @nodoc
abstract mixin class _$JflapGrammarDtoCopyWith<$Res> implements $JflapGrammarDtoCopyWith<$Res> {
  factory _$JflapGrammarDtoCopyWith(_JflapGrammarDto value, $Res Function(_JflapGrammarDto) _then) = __$JflapGrammarDtoCopyWithImpl;
@override @useResult
$Res call({
 String type, JflapGrammarStructureDto structure
});


@override $JflapGrammarStructureDtoCopyWith<$Res> get structure;

}
/// @nodoc
class __$JflapGrammarDtoCopyWithImpl<$Res>
    implements _$JflapGrammarDtoCopyWith<$Res> {
  __$JflapGrammarDtoCopyWithImpl(this._self, this._then);

  final _JflapGrammarDto _self;
  final $Res Function(_JflapGrammarDto) _then;

/// Create a copy of JflapGrammarDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? structure = null,}) {
  return _then(_JflapGrammarDto(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,structure: null == structure ? _self.structure : structure // ignore: cast_nullable_to_non_nullable
as JflapGrammarStructureDto,
  ));
}

/// Create a copy of JflapGrammarDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JflapGrammarStructureDtoCopyWith<$Res> get structure {
  
  return $JflapGrammarStructureDtoCopyWith<$Res>(_self.structure, (value) {
    return _then(_self.copyWith(structure: value));
  });
}
}


/// @nodoc
mixin _$JflapGrammarStructureDto {

 List<String> get terminals; List<String> get variables; String get startVariable; List<JflapProductionDto> get productions;
/// Create a copy of JflapGrammarStructureDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JflapGrammarStructureDtoCopyWith<JflapGrammarStructureDto> get copyWith => _$JflapGrammarStructureDtoCopyWithImpl<JflapGrammarStructureDto>(this as JflapGrammarStructureDto, _$identity);

  /// Serializes this JflapGrammarStructureDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JflapGrammarStructureDto&&const DeepCollectionEquality().equals(other.terminals, terminals)&&const DeepCollectionEquality().equals(other.variables, variables)&&(identical(other.startVariable, startVariable) || other.startVariable == startVariable)&&const DeepCollectionEquality().equals(other.productions, productions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(terminals),const DeepCollectionEquality().hash(variables),startVariable,const DeepCollectionEquality().hash(productions));

@override
String toString() {
  return 'JflapGrammarStructureDto(terminals: $terminals, variables: $variables, startVariable: $startVariable, productions: $productions)';
}


}

/// @nodoc
abstract mixin class $JflapGrammarStructureDtoCopyWith<$Res>  {
  factory $JflapGrammarStructureDtoCopyWith(JflapGrammarStructureDto value, $Res Function(JflapGrammarStructureDto) _then) = _$JflapGrammarStructureDtoCopyWithImpl;
@useResult
$Res call({
 List<String> terminals, List<String> variables, String startVariable, List<JflapProductionDto> productions
});




}
/// @nodoc
class _$JflapGrammarStructureDtoCopyWithImpl<$Res>
    implements $JflapGrammarStructureDtoCopyWith<$Res> {
  _$JflapGrammarStructureDtoCopyWithImpl(this._self, this._then);

  final JflapGrammarStructureDto _self;
  final $Res Function(JflapGrammarStructureDto) _then;

/// Create a copy of JflapGrammarStructureDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? terminals = null,Object? variables = null,Object? startVariable = null,Object? productions = null,}) {
  return _then(_self.copyWith(
terminals: null == terminals ? _self.terminals : terminals // ignore: cast_nullable_to_non_nullable
as List<String>,variables: null == variables ? _self.variables : variables // ignore: cast_nullable_to_non_nullable
as List<String>,startVariable: null == startVariable ? _self.startVariable : startVariable // ignore: cast_nullable_to_non_nullable
as String,productions: null == productions ? _self.productions : productions // ignore: cast_nullable_to_non_nullable
as List<JflapProductionDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [JflapGrammarStructureDto].
extension JflapGrammarStructureDtoPatterns on JflapGrammarStructureDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JflapGrammarStructureDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JflapGrammarStructureDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JflapGrammarStructureDto value)  $default,){
final _that = this;
switch (_that) {
case _JflapGrammarStructureDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JflapGrammarStructureDto value)?  $default,){
final _that = this;
switch (_that) {
case _JflapGrammarStructureDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> terminals,  List<String> variables,  String startVariable,  List<JflapProductionDto> productions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JflapGrammarStructureDto() when $default != null:
return $default(_that.terminals,_that.variables,_that.startVariable,_that.productions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> terminals,  List<String> variables,  String startVariable,  List<JflapProductionDto> productions)  $default,) {final _that = this;
switch (_that) {
case _JflapGrammarStructureDto():
return $default(_that.terminals,_that.variables,_that.startVariable,_that.productions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> terminals,  List<String> variables,  String startVariable,  List<JflapProductionDto> productions)?  $default,) {final _that = this;
switch (_that) {
case _JflapGrammarStructureDto() when $default != null:
return $default(_that.terminals,_that.variables,_that.startVariable,_that.productions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JflapGrammarStructureDto implements JflapGrammarStructureDto {
  const _JflapGrammarStructureDto({required final  List<String> terminals, required final  List<String> variables, required this.startVariable, required final  List<JflapProductionDto> productions}): _terminals = terminals,_variables = variables,_productions = productions;
  factory _JflapGrammarStructureDto.fromJson(Map<String, dynamic> json) => _$JflapGrammarStructureDtoFromJson(json);

 final  List<String> _terminals;
@override List<String> get terminals {
  if (_terminals is EqualUnmodifiableListView) return _terminals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_terminals);
}

 final  List<String> _variables;
@override List<String> get variables {
  if (_variables is EqualUnmodifiableListView) return _variables;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variables);
}

@override final  String startVariable;
 final  List<JflapProductionDto> _productions;
@override List<JflapProductionDto> get productions {
  if (_productions is EqualUnmodifiableListView) return _productions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_productions);
}


/// Create a copy of JflapGrammarStructureDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JflapGrammarStructureDtoCopyWith<_JflapGrammarStructureDto> get copyWith => __$JflapGrammarStructureDtoCopyWithImpl<_JflapGrammarStructureDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JflapGrammarStructureDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JflapGrammarStructureDto&&const DeepCollectionEquality().equals(other._terminals, _terminals)&&const DeepCollectionEquality().equals(other._variables, _variables)&&(identical(other.startVariable, startVariable) || other.startVariable == startVariable)&&const DeepCollectionEquality().equals(other._productions, _productions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_terminals),const DeepCollectionEquality().hash(_variables),startVariable,const DeepCollectionEquality().hash(_productions));

@override
String toString() {
  return 'JflapGrammarStructureDto(terminals: $terminals, variables: $variables, startVariable: $startVariable, productions: $productions)';
}


}

/// @nodoc
abstract mixin class _$JflapGrammarStructureDtoCopyWith<$Res> implements $JflapGrammarStructureDtoCopyWith<$Res> {
  factory _$JflapGrammarStructureDtoCopyWith(_JflapGrammarStructureDto value, $Res Function(_JflapGrammarStructureDto) _then) = __$JflapGrammarStructureDtoCopyWithImpl;
@override @useResult
$Res call({
 List<String> terminals, List<String> variables, String startVariable, List<JflapProductionDto> productions
});




}
/// @nodoc
class __$JflapGrammarStructureDtoCopyWithImpl<$Res>
    implements _$JflapGrammarStructureDtoCopyWith<$Res> {
  __$JflapGrammarStructureDtoCopyWithImpl(this._self, this._then);

  final _JflapGrammarStructureDto _self;
  final $Res Function(_JflapGrammarStructureDto) _then;

/// Create a copy of JflapGrammarStructureDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? terminals = null,Object? variables = null,Object? startVariable = null,Object? productions = null,}) {
  return _then(_JflapGrammarStructureDto(
terminals: null == terminals ? _self._terminals : terminals // ignore: cast_nullable_to_non_nullable
as List<String>,variables: null == variables ? _self._variables : variables // ignore: cast_nullable_to_non_nullable
as List<String>,startVariable: null == startVariable ? _self.startVariable : startVariable // ignore: cast_nullable_to_non_nullable
as String,productions: null == productions ? _self._productions : productions // ignore: cast_nullable_to_non_nullable
as List<JflapProductionDto>,
  ));
}


}


/// @nodoc
mixin _$JflapProductionDto {

 String get left; String get right;
/// Create a copy of JflapProductionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JflapProductionDtoCopyWith<JflapProductionDto> get copyWith => _$JflapProductionDtoCopyWithImpl<JflapProductionDto>(this as JflapProductionDto, _$identity);

  /// Serializes this JflapProductionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JflapProductionDto&&(identical(other.left, left) || other.left == left)&&(identical(other.right, right) || other.right == right));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,left,right);

@override
String toString() {
  return 'JflapProductionDto(left: $left, right: $right)';
}


}

/// @nodoc
abstract mixin class $JflapProductionDtoCopyWith<$Res>  {
  factory $JflapProductionDtoCopyWith(JflapProductionDto value, $Res Function(JflapProductionDto) _then) = _$JflapProductionDtoCopyWithImpl;
@useResult
$Res call({
 String left, String right
});




}
/// @nodoc
class _$JflapProductionDtoCopyWithImpl<$Res>
    implements $JflapProductionDtoCopyWith<$Res> {
  _$JflapProductionDtoCopyWithImpl(this._self, this._then);

  final JflapProductionDto _self;
  final $Res Function(JflapProductionDto) _then;

/// Create a copy of JflapProductionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? left = null,Object? right = null,}) {
  return _then(_self.copyWith(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as String,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JflapProductionDto].
extension JflapProductionDtoPatterns on JflapProductionDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JflapProductionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JflapProductionDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JflapProductionDto value)  $default,){
final _that = this;
switch (_that) {
case _JflapProductionDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JflapProductionDto value)?  $default,){
final _that = this;
switch (_that) {
case _JflapProductionDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String left,  String right)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JflapProductionDto() when $default != null:
return $default(_that.left,_that.right);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String left,  String right)  $default,) {final _that = this;
switch (_that) {
case _JflapProductionDto():
return $default(_that.left,_that.right);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String left,  String right)?  $default,) {final _that = this;
switch (_that) {
case _JflapProductionDto() when $default != null:
return $default(_that.left,_that.right);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JflapProductionDto implements JflapProductionDto {
  const _JflapProductionDto({required this.left, required this.right});
  factory _JflapProductionDto.fromJson(Map<String, dynamic> json) => _$JflapProductionDtoFromJson(json);

@override final  String left;
@override final  String right;

/// Create a copy of JflapProductionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JflapProductionDtoCopyWith<_JflapProductionDto> get copyWith => __$JflapProductionDtoCopyWithImpl<_JflapProductionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JflapProductionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JflapProductionDto&&(identical(other.left, left) || other.left == left)&&(identical(other.right, right) || other.right == right));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,left,right);

@override
String toString() {
  return 'JflapProductionDto(left: $left, right: $right)';
}


}

/// @nodoc
abstract mixin class _$JflapProductionDtoCopyWith<$Res> implements $JflapProductionDtoCopyWith<$Res> {
  factory _$JflapProductionDtoCopyWith(_JflapProductionDto value, $Res Function(_JflapProductionDto) _then) = __$JflapProductionDtoCopyWithImpl;
@override @useResult
$Res call({
 String left, String right
});




}
/// @nodoc
class __$JflapProductionDtoCopyWithImpl<$Res>
    implements _$JflapProductionDtoCopyWith<$Res> {
  __$JflapProductionDtoCopyWithImpl(this._self, this._then);

  final _JflapProductionDto _self;
  final $Res Function(_JflapProductionDto) _then;

/// Create a copy of JflapProductionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? left = null,Object? right = null,}) {
  return _then(_JflapProductionDto(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as String,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
