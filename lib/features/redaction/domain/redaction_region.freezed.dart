// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'redaction_region.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RedactionRegion {

 Rect get rect; Color get color;
/// Create a copy of RedactionRegion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RedactionRegionCopyWith<RedactionRegion> get copyWith => _$RedactionRegionCopyWithImpl<RedactionRegion>(this as RedactionRegion, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RedactionRegion&&(identical(other.rect, rect) || other.rect == rect)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,rect,color);

@override
String toString() {
  return 'RedactionRegion(rect: $rect, color: $color)';
}


}

/// @nodoc
abstract mixin class $RedactionRegionCopyWith<$Res>  {
  factory $RedactionRegionCopyWith(RedactionRegion value, $Res Function(RedactionRegion) _then) = _$RedactionRegionCopyWithImpl;
@useResult
$Res call({
 Rect rect, Color color
});




}
/// @nodoc
class _$RedactionRegionCopyWithImpl<$Res>
    implements $RedactionRegionCopyWith<$Res> {
  _$RedactionRegionCopyWithImpl(this._self, this._then);

  final RedactionRegion _self;
  final $Res Function(RedactionRegion) _then;

/// Create a copy of RedactionRegion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rect = null,Object? color = null,}) {
  return _then(_self.copyWith(
rect: null == rect ? _self.rect : rect // ignore: cast_nullable_to_non_nullable
as Rect,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}

}


/// Adds pattern-matching-related methods to [RedactionRegion].
extension RedactionRegionPatterns on RedactionRegion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RedactionRegion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RedactionRegion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RedactionRegion value)  $default,){
final _that = this;
switch (_that) {
case _RedactionRegion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RedactionRegion value)?  $default,){
final _that = this;
switch (_that) {
case _RedactionRegion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Rect rect,  Color color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RedactionRegion() when $default != null:
return $default(_that.rect,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Rect rect,  Color color)  $default,) {final _that = this;
switch (_that) {
case _RedactionRegion():
return $default(_that.rect,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Rect rect,  Color color)?  $default,) {final _that = this;
switch (_that) {
case _RedactionRegion() when $default != null:
return $default(_that.rect,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class _RedactionRegion implements RedactionRegion {
  const _RedactionRegion({required this.rect, required this.color});
  

@override final  Rect rect;
@override final  Color color;

/// Create a copy of RedactionRegion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RedactionRegionCopyWith<_RedactionRegion> get copyWith => __$RedactionRegionCopyWithImpl<_RedactionRegion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RedactionRegion&&(identical(other.rect, rect) || other.rect == rect)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,rect,color);

@override
String toString() {
  return 'RedactionRegion(rect: $rect, color: $color)';
}


}

/// @nodoc
abstract mixin class _$RedactionRegionCopyWith<$Res> implements $RedactionRegionCopyWith<$Res> {
  factory _$RedactionRegionCopyWith(_RedactionRegion value, $Res Function(_RedactionRegion) _then) = __$RedactionRegionCopyWithImpl;
@override @useResult
$Res call({
 Rect rect, Color color
});




}
/// @nodoc
class __$RedactionRegionCopyWithImpl<$Res>
    implements _$RedactionRegionCopyWith<$Res> {
  __$RedactionRegionCopyWithImpl(this._self, this._then);

  final _RedactionRegion _self;
  final $Res Function(_RedactionRegion) _then;

/// Create a copy of RedactionRegion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rect = null,Object? color = null,}) {
  return _then(_RedactionRegion(
rect: null == rect ? _self.rect : rect // ignore: cast_nullable_to_non_nullable
as Rect,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}


}

// dart format on
