// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'turing_machine_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TuringMachineDto {

 String get id; String get name; String get type; List<String> get inputAlphabet; List<String> get tapeAlphabet; List<String> get states; String get initialState; List<String> get finalStates; String get blankSymbol; Map<String, Map<String, TuringTransitionDto>> get transitions;
/// Create a copy of TuringMachineDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TuringMachineDtoCopyWith<TuringMachineDto> get copyWith => _$TuringMachineDtoCopyWithImpl<TuringMachineDto>(this as TuringMachineDto, _$identity);

  /// Serializes this TuringMachineDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TuringMachineDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.inputAlphabet, inputAlphabet)&&const DeepCollectionEquality().equals(other.tapeAlphabet, tapeAlphabet)&&const DeepCollectionEquality().equals(other.states, states)&&(identical(other.initialState, initialState) || other.initialState == initialState)&&const DeepCollectionEquality().equals(other.finalStates, finalStates)&&(identical(other.blankSymbol, blankSymbol) || other.blankSymbol == blankSymbol)&&const DeepCollectionEquality().equals(other.transitions, transitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,const DeepCollectionEquality().hash(inputAlphabet),const DeepCollectionEquality().hash(tapeAlphabet),const DeepCollectionEquality().hash(states),initialState,const DeepCollectionEquality().hash(finalStates),blankSymbol,const DeepCollectionEquality().hash(transitions));

@override
String toString() {
  return 'TuringMachineDto(id: $id, name: $name, type: $type, inputAlphabet: $inputAlphabet, tapeAlphabet: $tapeAlphabet, states: $states, initialState: $initialState, finalStates: $finalStates, blankSymbol: $blankSymbol, transitions: $transitions)';
}


}

/// @nodoc
abstract mixin class $TuringMachineDtoCopyWith<$Res>  {
  factory $TuringMachineDtoCopyWith(TuringMachineDto value, $Res Function(TuringMachineDto) _then) = _$TuringMachineDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String type, List<String> inputAlphabet, List<String> tapeAlphabet, List<String> states, String initialState, List<String> finalStates, String blankSymbol, Map<String, Map<String, TuringTransitionDto>> transitions
});




}
/// @nodoc
class _$TuringMachineDtoCopyWithImpl<$Res>
    implements $TuringMachineDtoCopyWith<$Res> {
  _$TuringMachineDtoCopyWithImpl(this._self, this._then);

  final TuringMachineDto _self;
  final $Res Function(TuringMachineDto) _then;

/// Create a copy of TuringMachineDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? inputAlphabet = null,Object? tapeAlphabet = null,Object? states = null,Object? initialState = null,Object? finalStates = null,Object? blankSymbol = null,Object? transitions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,inputAlphabet: null == inputAlphabet ? _self.inputAlphabet : inputAlphabet // ignore: cast_nullable_to_non_nullable
as List<String>,tapeAlphabet: null == tapeAlphabet ? _self.tapeAlphabet : tapeAlphabet // ignore: cast_nullable_to_non_nullable
as List<String>,states: null == states ? _self.states : states // ignore: cast_nullable_to_non_nullable
as List<String>,initialState: null == initialState ? _self.initialState : initialState // ignore: cast_nullable_to_non_nullable
as String,finalStates: null == finalStates ? _self.finalStates : finalStates // ignore: cast_nullable_to_non_nullable
as List<String>,blankSymbol: null == blankSymbol ? _self.blankSymbol : blankSymbol // ignore: cast_nullable_to_non_nullable
as String,transitions: null == transitions ? _self.transitions : transitions // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, TuringTransitionDto>>,
  ));
}

}


/// Adds pattern-matching-related methods to [TuringMachineDto].
extension TuringMachineDtoPatterns on TuringMachineDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TuringMachineDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TuringMachineDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TuringMachineDto value)  $default,){
final _that = this;
switch (_that) {
case _TuringMachineDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TuringMachineDto value)?  $default,){
final _that = this;
switch (_that) {
case _TuringMachineDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String type,  List<String> inputAlphabet,  List<String> tapeAlphabet,  List<String> states,  String initialState,  List<String> finalStates,  String blankSymbol,  Map<String, Map<String, TuringTransitionDto>> transitions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TuringMachineDto() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.inputAlphabet,_that.tapeAlphabet,_that.states,_that.initialState,_that.finalStates,_that.blankSymbol,_that.transitions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String type,  List<String> inputAlphabet,  List<String> tapeAlphabet,  List<String> states,  String initialState,  List<String> finalStates,  String blankSymbol,  Map<String, Map<String, TuringTransitionDto>> transitions)  $default,) {final _that = this;
switch (_that) {
case _TuringMachineDto():
return $default(_that.id,_that.name,_that.type,_that.inputAlphabet,_that.tapeAlphabet,_that.states,_that.initialState,_that.finalStates,_that.blankSymbol,_that.transitions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String type,  List<String> inputAlphabet,  List<String> tapeAlphabet,  List<String> states,  String initialState,  List<String> finalStates,  String blankSymbol,  Map<String, Map<String, TuringTransitionDto>> transitions)?  $default,) {final _that = this;
switch (_that) {
case _TuringMachineDto() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.inputAlphabet,_that.tapeAlphabet,_that.states,_that.initialState,_that.finalStates,_that.blankSymbol,_that.transitions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TuringMachineDto implements TuringMachineDto {
  const _TuringMachineDto({required this.id, required this.name, required this.type, required final  List<String> inputAlphabet, required final  List<String> tapeAlphabet, required final  List<String> states, required this.initialState, required final  List<String> finalStates, required this.blankSymbol, required final  Map<String, Map<String, TuringTransitionDto>> transitions}): _inputAlphabet = inputAlphabet,_tapeAlphabet = tapeAlphabet,_states = states,_finalStates = finalStates,_transitions = transitions;
  factory _TuringMachineDto.fromJson(Map<String, dynamic> json) => _$TuringMachineDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String type;
 final  List<String> _inputAlphabet;
@override List<String> get inputAlphabet {
  if (_inputAlphabet is EqualUnmodifiableListView) return _inputAlphabet;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inputAlphabet);
}

 final  List<String> _tapeAlphabet;
@override List<String> get tapeAlphabet {
  if (_tapeAlphabet is EqualUnmodifiableListView) return _tapeAlphabet;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tapeAlphabet);
}

 final  List<String> _states;
@override List<String> get states {
  if (_states is EqualUnmodifiableListView) return _states;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_states);
}

@override final  String initialState;
 final  List<String> _finalStates;
@override List<String> get finalStates {
  if (_finalStates is EqualUnmodifiableListView) return _finalStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_finalStates);
}

@override final  String blankSymbol;
 final  Map<String, Map<String, TuringTransitionDto>> _transitions;
@override Map<String, Map<String, TuringTransitionDto>> get transitions {
  if (_transitions is EqualUnmodifiableMapView) return _transitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_transitions);
}


/// Create a copy of TuringMachineDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TuringMachineDtoCopyWith<_TuringMachineDto> get copyWith => __$TuringMachineDtoCopyWithImpl<_TuringMachineDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TuringMachineDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TuringMachineDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._inputAlphabet, _inputAlphabet)&&const DeepCollectionEquality().equals(other._tapeAlphabet, _tapeAlphabet)&&const DeepCollectionEquality().equals(other._states, _states)&&(identical(other.initialState, initialState) || other.initialState == initialState)&&const DeepCollectionEquality().equals(other._finalStates, _finalStates)&&(identical(other.blankSymbol, blankSymbol) || other.blankSymbol == blankSymbol)&&const DeepCollectionEquality().equals(other._transitions, _transitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,const DeepCollectionEquality().hash(_inputAlphabet),const DeepCollectionEquality().hash(_tapeAlphabet),const DeepCollectionEquality().hash(_states),initialState,const DeepCollectionEquality().hash(_finalStates),blankSymbol,const DeepCollectionEquality().hash(_transitions));

@override
String toString() {
  return 'TuringMachineDto(id: $id, name: $name, type: $type, inputAlphabet: $inputAlphabet, tapeAlphabet: $tapeAlphabet, states: $states, initialState: $initialState, finalStates: $finalStates, blankSymbol: $blankSymbol, transitions: $transitions)';
}


}

/// @nodoc
abstract mixin class _$TuringMachineDtoCopyWith<$Res> implements $TuringMachineDtoCopyWith<$Res> {
  factory _$TuringMachineDtoCopyWith(_TuringMachineDto value, $Res Function(_TuringMachineDto) _then) = __$TuringMachineDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String type, List<String> inputAlphabet, List<String> tapeAlphabet, List<String> states, String initialState, List<String> finalStates, String blankSymbol, Map<String, Map<String, TuringTransitionDto>> transitions
});




}
/// @nodoc
class __$TuringMachineDtoCopyWithImpl<$Res>
    implements _$TuringMachineDtoCopyWith<$Res> {
  __$TuringMachineDtoCopyWithImpl(this._self, this._then);

  final _TuringMachineDto _self;
  final $Res Function(_TuringMachineDto) _then;

/// Create a copy of TuringMachineDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? inputAlphabet = null,Object? tapeAlphabet = null,Object? states = null,Object? initialState = null,Object? finalStates = null,Object? blankSymbol = null,Object? transitions = null,}) {
  return _then(_TuringMachineDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,inputAlphabet: null == inputAlphabet ? _self._inputAlphabet : inputAlphabet // ignore: cast_nullable_to_non_nullable
as List<String>,tapeAlphabet: null == tapeAlphabet ? _self._tapeAlphabet : tapeAlphabet // ignore: cast_nullable_to_non_nullable
as List<String>,states: null == states ? _self._states : states // ignore: cast_nullable_to_non_nullable
as List<String>,initialState: null == initialState ? _self.initialState : initialState // ignore: cast_nullable_to_non_nullable
as String,finalStates: null == finalStates ? _self._finalStates : finalStates // ignore: cast_nullable_to_non_nullable
as List<String>,blankSymbol: null == blankSymbol ? _self.blankSymbol : blankSymbol // ignore: cast_nullable_to_non_nullable
as String,transitions: null == transitions ? _self._transitions : transitions // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, TuringTransitionDto>>,
  ));
}


}


/// @nodoc
mixin _$TuringTransitionDto {

 String get newState; String get writeSymbol; String get direction;
/// Create a copy of TuringTransitionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TuringTransitionDtoCopyWith<TuringTransitionDto> get copyWith => _$TuringTransitionDtoCopyWithImpl<TuringTransitionDto>(this as TuringTransitionDto, _$identity);

  /// Serializes this TuringTransitionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TuringTransitionDto&&(identical(other.newState, newState) || other.newState == newState)&&(identical(other.writeSymbol, writeSymbol) || other.writeSymbol == writeSymbol)&&(identical(other.direction, direction) || other.direction == direction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,newState,writeSymbol,direction);

@override
String toString() {
  return 'TuringTransitionDto(newState: $newState, writeSymbol: $writeSymbol, direction: $direction)';
}


}

/// @nodoc
abstract mixin class $TuringTransitionDtoCopyWith<$Res>  {
  factory $TuringTransitionDtoCopyWith(TuringTransitionDto value, $Res Function(TuringTransitionDto) _then) = _$TuringTransitionDtoCopyWithImpl;
@useResult
$Res call({
 String newState, String writeSymbol, String direction
});




}
/// @nodoc
class _$TuringTransitionDtoCopyWithImpl<$Res>
    implements $TuringTransitionDtoCopyWith<$Res> {
  _$TuringTransitionDtoCopyWithImpl(this._self, this._then);

  final TuringTransitionDto _self;
  final $Res Function(TuringTransitionDto) _then;

/// Create a copy of TuringTransitionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? newState = null,Object? writeSymbol = null,Object? direction = null,}) {
  return _then(_self.copyWith(
newState: null == newState ? _self.newState : newState // ignore: cast_nullable_to_non_nullable
as String,writeSymbol: null == writeSymbol ? _self.writeSymbol : writeSymbol // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TuringTransitionDto].
extension TuringTransitionDtoPatterns on TuringTransitionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TuringTransitionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TuringTransitionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TuringTransitionDto value)  $default,){
final _that = this;
switch (_that) {
case _TuringTransitionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TuringTransitionDto value)?  $default,){
final _that = this;
switch (_that) {
case _TuringTransitionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String newState,  String writeSymbol,  String direction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TuringTransitionDto() when $default != null:
return $default(_that.newState,_that.writeSymbol,_that.direction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String newState,  String writeSymbol,  String direction)  $default,) {final _that = this;
switch (_that) {
case _TuringTransitionDto():
return $default(_that.newState,_that.writeSymbol,_that.direction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String newState,  String writeSymbol,  String direction)?  $default,) {final _that = this;
switch (_that) {
case _TuringTransitionDto() when $default != null:
return $default(_that.newState,_that.writeSymbol,_that.direction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TuringTransitionDto implements TuringTransitionDto {
  const _TuringTransitionDto({required this.newState, required this.writeSymbol, required this.direction});
  factory _TuringTransitionDto.fromJson(Map<String, dynamic> json) => _$TuringTransitionDtoFromJson(json);

@override final  String newState;
@override final  String writeSymbol;
@override final  String direction;

/// Create a copy of TuringTransitionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TuringTransitionDtoCopyWith<_TuringTransitionDto> get copyWith => __$TuringTransitionDtoCopyWithImpl<_TuringTransitionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TuringTransitionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TuringTransitionDto&&(identical(other.newState, newState) || other.newState == newState)&&(identical(other.writeSymbol, writeSymbol) || other.writeSymbol == writeSymbol)&&(identical(other.direction, direction) || other.direction == direction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,newState,writeSymbol,direction);

@override
String toString() {
  return 'TuringTransitionDto(newState: $newState, writeSymbol: $writeSymbol, direction: $direction)';
}


}

/// @nodoc
abstract mixin class _$TuringTransitionDtoCopyWith<$Res> implements $TuringTransitionDtoCopyWith<$Res> {
  factory _$TuringTransitionDtoCopyWith(_TuringTransitionDto value, $Res Function(_TuringTransitionDto) _then) = __$TuringTransitionDtoCopyWithImpl;
@override @useResult
$Res call({
 String newState, String writeSymbol, String direction
});




}
/// @nodoc
class __$TuringTransitionDtoCopyWithImpl<$Res>
    implements _$TuringTransitionDtoCopyWith<$Res> {
  __$TuringTransitionDtoCopyWithImpl(this._self, this._then);

  final _TuringTransitionDto _self;
  final $Res Function(_TuringTransitionDto) _then;

/// Create a copy of TuringTransitionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? newState = null,Object? writeSymbol = null,Object? direction = null,}) {
  return _then(_TuringTransitionDto(
newState: null == newState ? _self.newState : newState // ignore: cast_nullable_to_non_nullable
as String,writeSymbol: null == writeSymbol ? _self.writeSymbol : writeSymbol // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$JflapTuringMachineDto {

 String get type; JflapTuringStructureDto get structure;
/// Create a copy of JflapTuringMachineDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JflapTuringMachineDtoCopyWith<JflapTuringMachineDto> get copyWith => _$JflapTuringMachineDtoCopyWithImpl<JflapTuringMachineDto>(this as JflapTuringMachineDto, _$identity);

  /// Serializes this JflapTuringMachineDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JflapTuringMachineDto&&(identical(other.type, type) || other.type == type)&&(identical(other.structure, structure) || other.structure == structure));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,structure);

@override
String toString() {
  return 'JflapTuringMachineDto(type: $type, structure: $structure)';
}


}

/// @nodoc
abstract mixin class $JflapTuringMachineDtoCopyWith<$Res>  {
  factory $JflapTuringMachineDtoCopyWith(JflapTuringMachineDto value, $Res Function(JflapTuringMachineDto) _then) = _$JflapTuringMachineDtoCopyWithImpl;
@useResult
$Res call({
 String type, JflapTuringStructureDto structure
});


$JflapTuringStructureDtoCopyWith<$Res> get structure;

}
/// @nodoc
class _$JflapTuringMachineDtoCopyWithImpl<$Res>
    implements $JflapTuringMachineDtoCopyWith<$Res> {
  _$JflapTuringMachineDtoCopyWithImpl(this._self, this._then);

  final JflapTuringMachineDto _self;
  final $Res Function(JflapTuringMachineDto) _then;

/// Create a copy of JflapTuringMachineDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? structure = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,structure: null == structure ? _self.structure : structure // ignore: cast_nullable_to_non_nullable
as JflapTuringStructureDto,
  ));
}
/// Create a copy of JflapTuringMachineDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JflapTuringStructureDtoCopyWith<$Res> get structure {
  
  return $JflapTuringStructureDtoCopyWith<$Res>(_self.structure, (value) {
    return _then(_self.copyWith(structure: value));
  });
}
}


/// Adds pattern-matching-related methods to [JflapTuringMachineDto].
extension JflapTuringMachineDtoPatterns on JflapTuringMachineDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JflapTuringMachineDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JflapTuringMachineDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JflapTuringMachineDto value)  $default,){
final _that = this;
switch (_that) {
case _JflapTuringMachineDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JflapTuringMachineDto value)?  $default,){
final _that = this;
switch (_that) {
case _JflapTuringMachineDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  JflapTuringStructureDto structure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JflapTuringMachineDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  JflapTuringStructureDto structure)  $default,) {final _that = this;
switch (_that) {
case _JflapTuringMachineDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  JflapTuringStructureDto structure)?  $default,) {final _that = this;
switch (_that) {
case _JflapTuringMachineDto() when $default != null:
return $default(_that.type,_that.structure);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JflapTuringMachineDto implements JflapTuringMachineDto {
  const _JflapTuringMachineDto({required this.type, required this.structure});
  factory _JflapTuringMachineDto.fromJson(Map<String, dynamic> json) => _$JflapTuringMachineDtoFromJson(json);

@override final  String type;
@override final  JflapTuringStructureDto structure;

/// Create a copy of JflapTuringMachineDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JflapTuringMachineDtoCopyWith<_JflapTuringMachineDto> get copyWith => __$JflapTuringMachineDtoCopyWithImpl<_JflapTuringMachineDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JflapTuringMachineDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JflapTuringMachineDto&&(identical(other.type, type) || other.type == type)&&(identical(other.structure, structure) || other.structure == structure));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,structure);

@override
String toString() {
  return 'JflapTuringMachineDto(type: $type, structure: $structure)';
}


}

/// @nodoc
abstract mixin class _$JflapTuringMachineDtoCopyWith<$Res> implements $JflapTuringMachineDtoCopyWith<$Res> {
  factory _$JflapTuringMachineDtoCopyWith(_JflapTuringMachineDto value, $Res Function(_JflapTuringMachineDto) _then) = __$JflapTuringMachineDtoCopyWithImpl;
@override @useResult
$Res call({
 String type, JflapTuringStructureDto structure
});


@override $JflapTuringStructureDtoCopyWith<$Res> get structure;

}
/// @nodoc
class __$JflapTuringMachineDtoCopyWithImpl<$Res>
    implements _$JflapTuringMachineDtoCopyWith<$Res> {
  __$JflapTuringMachineDtoCopyWithImpl(this._self, this._then);

  final _JflapTuringMachineDto _self;
  final $Res Function(_JflapTuringMachineDto) _then;

/// Create a copy of JflapTuringMachineDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? structure = null,}) {
  return _then(_JflapTuringMachineDto(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,structure: null == structure ? _self.structure : structure // ignore: cast_nullable_to_non_nullable
as JflapTuringStructureDto,
  ));
}

/// Create a copy of JflapTuringMachineDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JflapTuringStructureDtoCopyWith<$Res> get structure {
  
  return $JflapTuringStructureDtoCopyWith<$Res>(_self.structure, (value) {
    return _then(_self.copyWith(structure: value));
  });
}
}


/// @nodoc
mixin _$JflapTuringStructureDto {

 List<String> get states; List<String> get inputAlphabet; List<String> get tapeAlphabet; String get initialState; List<String> get finalStates; String get blankSymbol; List<JflapTuringTransitionDto> get transitions;
/// Create a copy of JflapTuringStructureDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JflapTuringStructureDtoCopyWith<JflapTuringStructureDto> get copyWith => _$JflapTuringStructureDtoCopyWithImpl<JflapTuringStructureDto>(this as JflapTuringStructureDto, _$identity);

  /// Serializes this JflapTuringStructureDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JflapTuringStructureDto&&const DeepCollectionEquality().equals(other.states, states)&&const DeepCollectionEquality().equals(other.inputAlphabet, inputAlphabet)&&const DeepCollectionEquality().equals(other.tapeAlphabet, tapeAlphabet)&&(identical(other.initialState, initialState) || other.initialState == initialState)&&const DeepCollectionEquality().equals(other.finalStates, finalStates)&&(identical(other.blankSymbol, blankSymbol) || other.blankSymbol == blankSymbol)&&const DeepCollectionEquality().equals(other.transitions, transitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(states),const DeepCollectionEquality().hash(inputAlphabet),const DeepCollectionEquality().hash(tapeAlphabet),initialState,const DeepCollectionEquality().hash(finalStates),blankSymbol,const DeepCollectionEquality().hash(transitions));

@override
String toString() {
  return 'JflapTuringStructureDto(states: $states, inputAlphabet: $inputAlphabet, tapeAlphabet: $tapeAlphabet, initialState: $initialState, finalStates: $finalStates, blankSymbol: $blankSymbol, transitions: $transitions)';
}


}

/// @nodoc
abstract mixin class $JflapTuringStructureDtoCopyWith<$Res>  {
  factory $JflapTuringStructureDtoCopyWith(JflapTuringStructureDto value, $Res Function(JflapTuringStructureDto) _then) = _$JflapTuringStructureDtoCopyWithImpl;
@useResult
$Res call({
 List<String> states, List<String> inputAlphabet, List<String> tapeAlphabet, String initialState, List<String> finalStates, String blankSymbol, List<JflapTuringTransitionDto> transitions
});




}
/// @nodoc
class _$JflapTuringStructureDtoCopyWithImpl<$Res>
    implements $JflapTuringStructureDtoCopyWith<$Res> {
  _$JflapTuringStructureDtoCopyWithImpl(this._self, this._then);

  final JflapTuringStructureDto _self;
  final $Res Function(JflapTuringStructureDto) _then;

/// Create a copy of JflapTuringStructureDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? states = null,Object? inputAlphabet = null,Object? tapeAlphabet = null,Object? initialState = null,Object? finalStates = null,Object? blankSymbol = null,Object? transitions = null,}) {
  return _then(_self.copyWith(
states: null == states ? _self.states : states // ignore: cast_nullable_to_non_nullable
as List<String>,inputAlphabet: null == inputAlphabet ? _self.inputAlphabet : inputAlphabet // ignore: cast_nullable_to_non_nullable
as List<String>,tapeAlphabet: null == tapeAlphabet ? _self.tapeAlphabet : tapeAlphabet // ignore: cast_nullable_to_non_nullable
as List<String>,initialState: null == initialState ? _self.initialState : initialState // ignore: cast_nullable_to_non_nullable
as String,finalStates: null == finalStates ? _self.finalStates : finalStates // ignore: cast_nullable_to_non_nullable
as List<String>,blankSymbol: null == blankSymbol ? _self.blankSymbol : blankSymbol // ignore: cast_nullable_to_non_nullable
as String,transitions: null == transitions ? _self.transitions : transitions // ignore: cast_nullable_to_non_nullable
as List<JflapTuringTransitionDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [JflapTuringStructureDto].
extension JflapTuringStructureDtoPatterns on JflapTuringStructureDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JflapTuringStructureDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JflapTuringStructureDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JflapTuringStructureDto value)  $default,){
final _that = this;
switch (_that) {
case _JflapTuringStructureDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JflapTuringStructureDto value)?  $default,){
final _that = this;
switch (_that) {
case _JflapTuringStructureDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> states,  List<String> inputAlphabet,  List<String> tapeAlphabet,  String initialState,  List<String> finalStates,  String blankSymbol,  List<JflapTuringTransitionDto> transitions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JflapTuringStructureDto() when $default != null:
return $default(_that.states,_that.inputAlphabet,_that.tapeAlphabet,_that.initialState,_that.finalStates,_that.blankSymbol,_that.transitions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> states,  List<String> inputAlphabet,  List<String> tapeAlphabet,  String initialState,  List<String> finalStates,  String blankSymbol,  List<JflapTuringTransitionDto> transitions)  $default,) {final _that = this;
switch (_that) {
case _JflapTuringStructureDto():
return $default(_that.states,_that.inputAlphabet,_that.tapeAlphabet,_that.initialState,_that.finalStates,_that.blankSymbol,_that.transitions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> states,  List<String> inputAlphabet,  List<String> tapeAlphabet,  String initialState,  List<String> finalStates,  String blankSymbol,  List<JflapTuringTransitionDto> transitions)?  $default,) {final _that = this;
switch (_that) {
case _JflapTuringStructureDto() when $default != null:
return $default(_that.states,_that.inputAlphabet,_that.tapeAlphabet,_that.initialState,_that.finalStates,_that.blankSymbol,_that.transitions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JflapTuringStructureDto implements JflapTuringStructureDto {
  const _JflapTuringStructureDto({required final  List<String> states, required final  List<String> inputAlphabet, required final  List<String> tapeAlphabet, required this.initialState, required final  List<String> finalStates, required this.blankSymbol, required final  List<JflapTuringTransitionDto> transitions}): _states = states,_inputAlphabet = inputAlphabet,_tapeAlphabet = tapeAlphabet,_finalStates = finalStates,_transitions = transitions;
  factory _JflapTuringStructureDto.fromJson(Map<String, dynamic> json) => _$JflapTuringStructureDtoFromJson(json);

 final  List<String> _states;
@override List<String> get states {
  if (_states is EqualUnmodifiableListView) return _states;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_states);
}

 final  List<String> _inputAlphabet;
@override List<String> get inputAlphabet {
  if (_inputAlphabet is EqualUnmodifiableListView) return _inputAlphabet;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inputAlphabet);
}

 final  List<String> _tapeAlphabet;
@override List<String> get tapeAlphabet {
  if (_tapeAlphabet is EqualUnmodifiableListView) return _tapeAlphabet;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tapeAlphabet);
}

@override final  String initialState;
 final  List<String> _finalStates;
@override List<String> get finalStates {
  if (_finalStates is EqualUnmodifiableListView) return _finalStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_finalStates);
}

@override final  String blankSymbol;
 final  List<JflapTuringTransitionDto> _transitions;
@override List<JflapTuringTransitionDto> get transitions {
  if (_transitions is EqualUnmodifiableListView) return _transitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transitions);
}


/// Create a copy of JflapTuringStructureDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JflapTuringStructureDtoCopyWith<_JflapTuringStructureDto> get copyWith => __$JflapTuringStructureDtoCopyWithImpl<_JflapTuringStructureDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JflapTuringStructureDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JflapTuringStructureDto&&const DeepCollectionEquality().equals(other._states, _states)&&const DeepCollectionEquality().equals(other._inputAlphabet, _inputAlphabet)&&const DeepCollectionEquality().equals(other._tapeAlphabet, _tapeAlphabet)&&(identical(other.initialState, initialState) || other.initialState == initialState)&&const DeepCollectionEquality().equals(other._finalStates, _finalStates)&&(identical(other.blankSymbol, blankSymbol) || other.blankSymbol == blankSymbol)&&const DeepCollectionEquality().equals(other._transitions, _transitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_states),const DeepCollectionEquality().hash(_inputAlphabet),const DeepCollectionEquality().hash(_tapeAlphabet),initialState,const DeepCollectionEquality().hash(_finalStates),blankSymbol,const DeepCollectionEquality().hash(_transitions));

@override
String toString() {
  return 'JflapTuringStructureDto(states: $states, inputAlphabet: $inputAlphabet, tapeAlphabet: $tapeAlphabet, initialState: $initialState, finalStates: $finalStates, blankSymbol: $blankSymbol, transitions: $transitions)';
}


}

/// @nodoc
abstract mixin class _$JflapTuringStructureDtoCopyWith<$Res> implements $JflapTuringStructureDtoCopyWith<$Res> {
  factory _$JflapTuringStructureDtoCopyWith(_JflapTuringStructureDto value, $Res Function(_JflapTuringStructureDto) _then) = __$JflapTuringStructureDtoCopyWithImpl;
@override @useResult
$Res call({
 List<String> states, List<String> inputAlphabet, List<String> tapeAlphabet, String initialState, List<String> finalStates, String blankSymbol, List<JflapTuringTransitionDto> transitions
});




}
/// @nodoc
class __$JflapTuringStructureDtoCopyWithImpl<$Res>
    implements _$JflapTuringStructureDtoCopyWith<$Res> {
  __$JflapTuringStructureDtoCopyWithImpl(this._self, this._then);

  final _JflapTuringStructureDto _self;
  final $Res Function(_JflapTuringStructureDto) _then;

/// Create a copy of JflapTuringStructureDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? states = null,Object? inputAlphabet = null,Object? tapeAlphabet = null,Object? initialState = null,Object? finalStates = null,Object? blankSymbol = null,Object? transitions = null,}) {
  return _then(_JflapTuringStructureDto(
states: null == states ? _self._states : states // ignore: cast_nullable_to_non_nullable
as List<String>,inputAlphabet: null == inputAlphabet ? _self._inputAlphabet : inputAlphabet // ignore: cast_nullable_to_non_nullable
as List<String>,tapeAlphabet: null == tapeAlphabet ? _self._tapeAlphabet : tapeAlphabet // ignore: cast_nullable_to_non_nullable
as List<String>,initialState: null == initialState ? _self.initialState : initialState // ignore: cast_nullable_to_non_nullable
as String,finalStates: null == finalStates ? _self._finalStates : finalStates // ignore: cast_nullable_to_non_nullable
as List<String>,blankSymbol: null == blankSymbol ? _self.blankSymbol : blankSymbol // ignore: cast_nullable_to_non_nullable
as String,transitions: null == transitions ? _self._transitions : transitions // ignore: cast_nullable_to_non_nullable
as List<JflapTuringTransitionDto>,
  ));
}


}


/// @nodoc
mixin _$JflapTuringTransitionDto {

 String get from; String get to; String get read; String get write; String get direction;
/// Create a copy of JflapTuringTransitionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JflapTuringTransitionDtoCopyWith<JflapTuringTransitionDto> get copyWith => _$JflapTuringTransitionDtoCopyWithImpl<JflapTuringTransitionDto>(this as JflapTuringTransitionDto, _$identity);

  /// Serializes this JflapTuringTransitionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JflapTuringTransitionDto&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.read, read) || other.read == read)&&(identical(other.write, write) || other.write == write)&&(identical(other.direction, direction) || other.direction == direction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,read,write,direction);

@override
String toString() {
  return 'JflapTuringTransitionDto(from: $from, to: $to, read: $read, write: $write, direction: $direction)';
}


}

/// @nodoc
abstract mixin class $JflapTuringTransitionDtoCopyWith<$Res>  {
  factory $JflapTuringTransitionDtoCopyWith(JflapTuringTransitionDto value, $Res Function(JflapTuringTransitionDto) _then) = _$JflapTuringTransitionDtoCopyWithImpl;
@useResult
$Res call({
 String from, String to, String read, String write, String direction
});




}
/// @nodoc
class _$JflapTuringTransitionDtoCopyWithImpl<$Res>
    implements $JflapTuringTransitionDtoCopyWith<$Res> {
  _$JflapTuringTransitionDtoCopyWithImpl(this._self, this._then);

  final JflapTuringTransitionDto _self;
  final $Res Function(JflapTuringTransitionDto) _then;

/// Create a copy of JflapTuringTransitionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? read = null,Object? write = null,Object? direction = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as String,write: null == write ? _self.write : write // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JflapTuringTransitionDto].
extension JflapTuringTransitionDtoPatterns on JflapTuringTransitionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JflapTuringTransitionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JflapTuringTransitionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JflapTuringTransitionDto value)  $default,){
final _that = this;
switch (_that) {
case _JflapTuringTransitionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JflapTuringTransitionDto value)?  $default,){
final _that = this;
switch (_that) {
case _JflapTuringTransitionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String from,  String to,  String read,  String write,  String direction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JflapTuringTransitionDto() when $default != null:
return $default(_that.from,_that.to,_that.read,_that.write,_that.direction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String from,  String to,  String read,  String write,  String direction)  $default,) {final _that = this;
switch (_that) {
case _JflapTuringTransitionDto():
return $default(_that.from,_that.to,_that.read,_that.write,_that.direction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String from,  String to,  String read,  String write,  String direction)?  $default,) {final _that = this;
switch (_that) {
case _JflapTuringTransitionDto() when $default != null:
return $default(_that.from,_that.to,_that.read,_that.write,_that.direction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JflapTuringTransitionDto implements JflapTuringTransitionDto {
  const _JflapTuringTransitionDto({required this.from, required this.to, required this.read, required this.write, required this.direction});
  factory _JflapTuringTransitionDto.fromJson(Map<String, dynamic> json) => _$JflapTuringTransitionDtoFromJson(json);

@override final  String from;
@override final  String to;
@override final  String read;
@override final  String write;
@override final  String direction;

/// Create a copy of JflapTuringTransitionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JflapTuringTransitionDtoCopyWith<_JflapTuringTransitionDto> get copyWith => __$JflapTuringTransitionDtoCopyWithImpl<_JflapTuringTransitionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JflapTuringTransitionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JflapTuringTransitionDto&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.read, read) || other.read == read)&&(identical(other.write, write) || other.write == write)&&(identical(other.direction, direction) || other.direction == direction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,read,write,direction);

@override
String toString() {
  return 'JflapTuringTransitionDto(from: $from, to: $to, read: $read, write: $write, direction: $direction)';
}


}

/// @nodoc
abstract mixin class _$JflapTuringTransitionDtoCopyWith<$Res> implements $JflapTuringTransitionDtoCopyWith<$Res> {
  factory _$JflapTuringTransitionDtoCopyWith(_JflapTuringTransitionDto value, $Res Function(_JflapTuringTransitionDto) _then) = __$JflapTuringTransitionDtoCopyWithImpl;
@override @useResult
$Res call({
 String from, String to, String read, String write, String direction
});




}
/// @nodoc
class __$JflapTuringTransitionDtoCopyWithImpl<$Res>
    implements _$JflapTuringTransitionDtoCopyWith<$Res> {
  __$JflapTuringTransitionDtoCopyWithImpl(this._self, this._then);

  final _JflapTuringTransitionDto _self;
  final $Res Function(_JflapTuringTransitionDto) _then;

/// Create a copy of JflapTuringTransitionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? read = null,Object? write = null,Object? direction = null,}) {
  return _then(_JflapTuringTransitionDto(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as String,write: null == write ? _self.write : write // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
