// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'redaction_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RedactionState {

 ui.Image? get image; String? get sourceFileName; String get status; Color get redactionColor; Offset? get draftStart; Rect? get draftRect; Color? get draftColor; bool get isOpening; bool get isExporting; ExportFormat get exportFormat; JpegQualityPreset get jpegQualityPreset; bool get preserveRedactionExportFileName; bool get preserveMetadataCleanFileNames; int get metadataInputCount; String? get metadataInputLabel; String? get metadataInputDescription; double? get metadataCleanProgress; String? get metadataOutputDirectoryPath; String? get metadataOutputDirectoryDisplayName; List<RedactionRegion> get redactions;
/// Create a copy of RedactionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RedactionStateCopyWith<RedactionState> get copyWith => _$RedactionStateCopyWithImpl<RedactionState>(this as RedactionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RedactionState&&(identical(other.image, image) || other.image == image)&&(identical(other.sourceFileName, sourceFileName) || other.sourceFileName == sourceFileName)&&(identical(other.status, status) || other.status == status)&&(identical(other.redactionColor, redactionColor) || other.redactionColor == redactionColor)&&(identical(other.draftStart, draftStart) || other.draftStart == draftStart)&&(identical(other.draftRect, draftRect) || other.draftRect == draftRect)&&(identical(other.draftColor, draftColor) || other.draftColor == draftColor)&&(identical(other.isOpening, isOpening) || other.isOpening == isOpening)&&(identical(other.isExporting, isExporting) || other.isExporting == isExporting)&&(identical(other.exportFormat, exportFormat) || other.exportFormat == exportFormat)&&(identical(other.jpegQualityPreset, jpegQualityPreset) || other.jpegQualityPreset == jpegQualityPreset)&&(identical(other.preserveRedactionExportFileName, preserveRedactionExportFileName) || other.preserveRedactionExportFileName == preserveRedactionExportFileName)&&(identical(other.preserveMetadataCleanFileNames, preserveMetadataCleanFileNames) || other.preserveMetadataCleanFileNames == preserveMetadataCleanFileNames)&&(identical(other.metadataInputCount, metadataInputCount) || other.metadataInputCount == metadataInputCount)&&(identical(other.metadataInputLabel, metadataInputLabel) || other.metadataInputLabel == metadataInputLabel)&&(identical(other.metadataInputDescription, metadataInputDescription) || other.metadataInputDescription == metadataInputDescription)&&(identical(other.metadataCleanProgress, metadataCleanProgress) || other.metadataCleanProgress == metadataCleanProgress)&&(identical(other.metadataOutputDirectoryPath, metadataOutputDirectoryPath) || other.metadataOutputDirectoryPath == metadataOutputDirectoryPath)&&(identical(other.metadataOutputDirectoryDisplayName, metadataOutputDirectoryDisplayName) || other.metadataOutputDirectoryDisplayName == metadataOutputDirectoryDisplayName)&&const DeepCollectionEquality().equals(other.redactions, redactions));
}


@override
int get hashCode => Object.hashAll([runtimeType,image,sourceFileName,status,redactionColor,draftStart,draftRect,draftColor,isOpening,isExporting,exportFormat,jpegQualityPreset,preserveRedactionExportFileName,preserveMetadataCleanFileNames,metadataInputCount,metadataInputLabel,metadataInputDescription,metadataCleanProgress,metadataOutputDirectoryPath,metadataOutputDirectoryDisplayName,const DeepCollectionEquality().hash(redactions)]);

@override
String toString() {
  return 'RedactionState(image: $image, sourceFileName: $sourceFileName, status: $status, redactionColor: $redactionColor, draftStart: $draftStart, draftRect: $draftRect, draftColor: $draftColor, isOpening: $isOpening, isExporting: $isExporting, exportFormat: $exportFormat, jpegQualityPreset: $jpegQualityPreset, preserveRedactionExportFileName: $preserveRedactionExportFileName, preserveMetadataCleanFileNames: $preserveMetadataCleanFileNames, metadataInputCount: $metadataInputCount, metadataInputLabel: $metadataInputLabel, metadataInputDescription: $metadataInputDescription, metadataCleanProgress: $metadataCleanProgress, metadataOutputDirectoryPath: $metadataOutputDirectoryPath, metadataOutputDirectoryDisplayName: $metadataOutputDirectoryDisplayName, redactions: $redactions)';
}


}

/// @nodoc
abstract mixin class $RedactionStateCopyWith<$Res>  {
  factory $RedactionStateCopyWith(RedactionState value, $Res Function(RedactionState) _then) = _$RedactionStateCopyWithImpl;
@useResult
$Res call({
 ui.Image? image, String? sourceFileName, String status, Color redactionColor, Offset? draftStart, Rect? draftRect, Color? draftColor, bool isOpening, bool isExporting, ExportFormat exportFormat, JpegQualityPreset jpegQualityPreset, bool preserveRedactionExportFileName, bool preserveMetadataCleanFileNames, int metadataInputCount, String? metadataInputLabel, String? metadataInputDescription, double? metadataCleanProgress, String? metadataOutputDirectoryPath, String? metadataOutputDirectoryDisplayName, List<RedactionRegion> redactions
});




}
/// @nodoc
class _$RedactionStateCopyWithImpl<$Res>
    implements $RedactionStateCopyWith<$Res> {
  _$RedactionStateCopyWithImpl(this._self, this._then);

  final RedactionState _self;
  final $Res Function(RedactionState) _then;

/// Create a copy of RedactionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? image = freezed,Object? sourceFileName = freezed,Object? status = null,Object? redactionColor = null,Object? draftStart = freezed,Object? draftRect = freezed,Object? draftColor = freezed,Object? isOpening = null,Object? isExporting = null,Object? exportFormat = null,Object? jpegQualityPreset = null,Object? preserveRedactionExportFileName = null,Object? preserveMetadataCleanFileNames = null,Object? metadataInputCount = null,Object? metadataInputLabel = freezed,Object? metadataInputDescription = freezed,Object? metadataCleanProgress = freezed,Object? metadataOutputDirectoryPath = freezed,Object? metadataOutputDirectoryDisplayName = freezed,Object? redactions = null,}) {
  return _then(_self.copyWith(
image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ui.Image?,sourceFileName: freezed == sourceFileName ? _self.sourceFileName : sourceFileName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,redactionColor: null == redactionColor ? _self.redactionColor : redactionColor // ignore: cast_nullable_to_non_nullable
as Color,draftStart: freezed == draftStart ? _self.draftStart : draftStart // ignore: cast_nullable_to_non_nullable
as Offset?,draftRect: freezed == draftRect ? _self.draftRect : draftRect // ignore: cast_nullable_to_non_nullable
as Rect?,draftColor: freezed == draftColor ? _self.draftColor : draftColor // ignore: cast_nullable_to_non_nullable
as Color?,isOpening: null == isOpening ? _self.isOpening : isOpening // ignore: cast_nullable_to_non_nullable
as bool,isExporting: null == isExporting ? _self.isExporting : isExporting // ignore: cast_nullable_to_non_nullable
as bool,exportFormat: null == exportFormat ? _self.exportFormat : exportFormat // ignore: cast_nullable_to_non_nullable
as ExportFormat,jpegQualityPreset: null == jpegQualityPreset ? _self.jpegQualityPreset : jpegQualityPreset // ignore: cast_nullable_to_non_nullable
as JpegQualityPreset,preserveRedactionExportFileName: null == preserveRedactionExportFileName ? _self.preserveRedactionExportFileName : preserveRedactionExportFileName // ignore: cast_nullable_to_non_nullable
as bool,preserveMetadataCleanFileNames: null == preserveMetadataCleanFileNames ? _self.preserveMetadataCleanFileNames : preserveMetadataCleanFileNames // ignore: cast_nullable_to_non_nullable
as bool,metadataInputCount: null == metadataInputCount ? _self.metadataInputCount : metadataInputCount // ignore: cast_nullable_to_non_nullable
as int,metadataInputLabel: freezed == metadataInputLabel ? _self.metadataInputLabel : metadataInputLabel // ignore: cast_nullable_to_non_nullable
as String?,metadataInputDescription: freezed == metadataInputDescription ? _self.metadataInputDescription : metadataInputDescription // ignore: cast_nullable_to_non_nullable
as String?,metadataCleanProgress: freezed == metadataCleanProgress ? _self.metadataCleanProgress : metadataCleanProgress // ignore: cast_nullable_to_non_nullable
as double?,metadataOutputDirectoryPath: freezed == metadataOutputDirectoryPath ? _self.metadataOutputDirectoryPath : metadataOutputDirectoryPath // ignore: cast_nullable_to_non_nullable
as String?,metadataOutputDirectoryDisplayName: freezed == metadataOutputDirectoryDisplayName ? _self.metadataOutputDirectoryDisplayName : metadataOutputDirectoryDisplayName // ignore: cast_nullable_to_non_nullable
as String?,redactions: null == redactions ? _self.redactions : redactions // ignore: cast_nullable_to_non_nullable
as List<RedactionRegion>,
  ));
}

}


/// Adds pattern-matching-related methods to [RedactionState].
extension RedactionStatePatterns on RedactionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RedactionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RedactionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RedactionState value)  $default,){
final _that = this;
switch (_that) {
case _RedactionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RedactionState value)?  $default,){
final _that = this;
switch (_that) {
case _RedactionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ui.Image? image,  String? sourceFileName,  String status,  Color redactionColor,  Offset? draftStart,  Rect? draftRect,  Color? draftColor,  bool isOpening,  bool isExporting,  ExportFormat exportFormat,  JpegQualityPreset jpegQualityPreset,  bool preserveRedactionExportFileName,  bool preserveMetadataCleanFileNames,  int metadataInputCount,  String? metadataInputLabel,  String? metadataInputDescription,  double? metadataCleanProgress,  String? metadataOutputDirectoryPath,  String? metadataOutputDirectoryDisplayName,  List<RedactionRegion> redactions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RedactionState() when $default != null:
return $default(_that.image,_that.sourceFileName,_that.status,_that.redactionColor,_that.draftStart,_that.draftRect,_that.draftColor,_that.isOpening,_that.isExporting,_that.exportFormat,_that.jpegQualityPreset,_that.preserveRedactionExportFileName,_that.preserveMetadataCleanFileNames,_that.metadataInputCount,_that.metadataInputLabel,_that.metadataInputDescription,_that.metadataCleanProgress,_that.metadataOutputDirectoryPath,_that.metadataOutputDirectoryDisplayName,_that.redactions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ui.Image? image,  String? sourceFileName,  String status,  Color redactionColor,  Offset? draftStart,  Rect? draftRect,  Color? draftColor,  bool isOpening,  bool isExporting,  ExportFormat exportFormat,  JpegQualityPreset jpegQualityPreset,  bool preserveRedactionExportFileName,  bool preserveMetadataCleanFileNames,  int metadataInputCount,  String? metadataInputLabel,  String? metadataInputDescription,  double? metadataCleanProgress,  String? metadataOutputDirectoryPath,  String? metadataOutputDirectoryDisplayName,  List<RedactionRegion> redactions)  $default,) {final _that = this;
switch (_that) {
case _RedactionState():
return $default(_that.image,_that.sourceFileName,_that.status,_that.redactionColor,_that.draftStart,_that.draftRect,_that.draftColor,_that.isOpening,_that.isExporting,_that.exportFormat,_that.jpegQualityPreset,_that.preserveRedactionExportFileName,_that.preserveMetadataCleanFileNames,_that.metadataInputCount,_that.metadataInputLabel,_that.metadataInputDescription,_that.metadataCleanProgress,_that.metadataOutputDirectoryPath,_that.metadataOutputDirectoryDisplayName,_that.redactions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ui.Image? image,  String? sourceFileName,  String status,  Color redactionColor,  Offset? draftStart,  Rect? draftRect,  Color? draftColor,  bool isOpening,  bool isExporting,  ExportFormat exportFormat,  JpegQualityPreset jpegQualityPreset,  bool preserveRedactionExportFileName,  bool preserveMetadataCleanFileNames,  int metadataInputCount,  String? metadataInputLabel,  String? metadataInputDescription,  double? metadataCleanProgress,  String? metadataOutputDirectoryPath,  String? metadataOutputDirectoryDisplayName,  List<RedactionRegion> redactions)?  $default,) {final _that = this;
switch (_that) {
case _RedactionState() when $default != null:
return $default(_that.image,_that.sourceFileName,_that.status,_that.redactionColor,_that.draftStart,_that.draftRect,_that.draftColor,_that.isOpening,_that.isExporting,_that.exportFormat,_that.jpegQualityPreset,_that.preserveRedactionExportFileName,_that.preserveMetadataCleanFileNames,_that.metadataInputCount,_that.metadataInputLabel,_that.metadataInputDescription,_that.metadataCleanProgress,_that.metadataOutputDirectoryPath,_that.metadataOutputDirectoryDisplayName,_that.redactions);case _:
  return null;

}
}

}

/// @nodoc


class _RedactionState extends RedactionState {
  const _RedactionState({this.image, this.sourceFileName, this.status = 'Ready', this.redactionColor = const Color(0xFF050505), this.draftStart, this.draftRect, this.draftColor, this.isOpening = false, this.isExporting = false, this.exportFormat = ExportFormat.png, this.jpegQualityPreset = JpegQualityPreset.medium, this.preserveRedactionExportFileName = false, this.preserveMetadataCleanFileNames = false, this.metadataInputCount = 0, this.metadataInputLabel, this.metadataInputDescription, this.metadataCleanProgress, this.metadataOutputDirectoryPath, this.metadataOutputDirectoryDisplayName, final  List<RedactionRegion> redactions = const <RedactionRegion>[]}): _redactions = redactions,super._();
  

@override final  ui.Image? image;
@override final  String? sourceFileName;
@override@JsonKey() final  String status;
@override@JsonKey() final  Color redactionColor;
@override final  Offset? draftStart;
@override final  Rect? draftRect;
@override final  Color? draftColor;
@override@JsonKey() final  bool isOpening;
@override@JsonKey() final  bool isExporting;
@override@JsonKey() final  ExportFormat exportFormat;
@override@JsonKey() final  JpegQualityPreset jpegQualityPreset;
@override@JsonKey() final  bool preserveRedactionExportFileName;
@override@JsonKey() final  bool preserveMetadataCleanFileNames;
@override@JsonKey() final  int metadataInputCount;
@override final  String? metadataInputLabel;
@override final  String? metadataInputDescription;
@override final  double? metadataCleanProgress;
@override final  String? metadataOutputDirectoryPath;
@override final  String? metadataOutputDirectoryDisplayName;
 final  List<RedactionRegion> _redactions;
@override@JsonKey() List<RedactionRegion> get redactions {
  if (_redactions is EqualUnmodifiableListView) return _redactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_redactions);
}


/// Create a copy of RedactionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RedactionStateCopyWith<_RedactionState> get copyWith => __$RedactionStateCopyWithImpl<_RedactionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RedactionState&&(identical(other.image, image) || other.image == image)&&(identical(other.sourceFileName, sourceFileName) || other.sourceFileName == sourceFileName)&&(identical(other.status, status) || other.status == status)&&(identical(other.redactionColor, redactionColor) || other.redactionColor == redactionColor)&&(identical(other.draftStart, draftStart) || other.draftStart == draftStart)&&(identical(other.draftRect, draftRect) || other.draftRect == draftRect)&&(identical(other.draftColor, draftColor) || other.draftColor == draftColor)&&(identical(other.isOpening, isOpening) || other.isOpening == isOpening)&&(identical(other.isExporting, isExporting) || other.isExporting == isExporting)&&(identical(other.exportFormat, exportFormat) || other.exportFormat == exportFormat)&&(identical(other.jpegQualityPreset, jpegQualityPreset) || other.jpegQualityPreset == jpegQualityPreset)&&(identical(other.preserveRedactionExportFileName, preserveRedactionExportFileName) || other.preserveRedactionExportFileName == preserveRedactionExportFileName)&&(identical(other.preserveMetadataCleanFileNames, preserveMetadataCleanFileNames) || other.preserveMetadataCleanFileNames == preserveMetadataCleanFileNames)&&(identical(other.metadataInputCount, metadataInputCount) || other.metadataInputCount == metadataInputCount)&&(identical(other.metadataInputLabel, metadataInputLabel) || other.metadataInputLabel == metadataInputLabel)&&(identical(other.metadataInputDescription, metadataInputDescription) || other.metadataInputDescription == metadataInputDescription)&&(identical(other.metadataCleanProgress, metadataCleanProgress) || other.metadataCleanProgress == metadataCleanProgress)&&(identical(other.metadataOutputDirectoryPath, metadataOutputDirectoryPath) || other.metadataOutputDirectoryPath == metadataOutputDirectoryPath)&&(identical(other.metadataOutputDirectoryDisplayName, metadataOutputDirectoryDisplayName) || other.metadataOutputDirectoryDisplayName == metadataOutputDirectoryDisplayName)&&const DeepCollectionEquality().equals(other._redactions, _redactions));
}


@override
int get hashCode => Object.hashAll([runtimeType,image,sourceFileName,status,redactionColor,draftStart,draftRect,draftColor,isOpening,isExporting,exportFormat,jpegQualityPreset,preserveRedactionExportFileName,preserveMetadataCleanFileNames,metadataInputCount,metadataInputLabel,metadataInputDescription,metadataCleanProgress,metadataOutputDirectoryPath,metadataOutputDirectoryDisplayName,const DeepCollectionEquality().hash(_redactions)]);

@override
String toString() {
  return 'RedactionState(image: $image, sourceFileName: $sourceFileName, status: $status, redactionColor: $redactionColor, draftStart: $draftStart, draftRect: $draftRect, draftColor: $draftColor, isOpening: $isOpening, isExporting: $isExporting, exportFormat: $exportFormat, jpegQualityPreset: $jpegQualityPreset, preserveRedactionExportFileName: $preserveRedactionExportFileName, preserveMetadataCleanFileNames: $preserveMetadataCleanFileNames, metadataInputCount: $metadataInputCount, metadataInputLabel: $metadataInputLabel, metadataInputDescription: $metadataInputDescription, metadataCleanProgress: $metadataCleanProgress, metadataOutputDirectoryPath: $metadataOutputDirectoryPath, metadataOutputDirectoryDisplayName: $metadataOutputDirectoryDisplayName, redactions: $redactions)';
}


}

/// @nodoc
abstract mixin class _$RedactionStateCopyWith<$Res> implements $RedactionStateCopyWith<$Res> {
  factory _$RedactionStateCopyWith(_RedactionState value, $Res Function(_RedactionState) _then) = __$RedactionStateCopyWithImpl;
@override @useResult
$Res call({
 ui.Image? image, String? sourceFileName, String status, Color redactionColor, Offset? draftStart, Rect? draftRect, Color? draftColor, bool isOpening, bool isExporting, ExportFormat exportFormat, JpegQualityPreset jpegQualityPreset, bool preserveRedactionExportFileName, bool preserveMetadataCleanFileNames, int metadataInputCount, String? metadataInputLabel, String? metadataInputDescription, double? metadataCleanProgress, String? metadataOutputDirectoryPath, String? metadataOutputDirectoryDisplayName, List<RedactionRegion> redactions
});




}
/// @nodoc
class __$RedactionStateCopyWithImpl<$Res>
    implements _$RedactionStateCopyWith<$Res> {
  __$RedactionStateCopyWithImpl(this._self, this._then);

  final _RedactionState _self;
  final $Res Function(_RedactionState) _then;

/// Create a copy of RedactionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? image = freezed,Object? sourceFileName = freezed,Object? status = null,Object? redactionColor = null,Object? draftStart = freezed,Object? draftRect = freezed,Object? draftColor = freezed,Object? isOpening = null,Object? isExporting = null,Object? exportFormat = null,Object? jpegQualityPreset = null,Object? preserveRedactionExportFileName = null,Object? preserveMetadataCleanFileNames = null,Object? metadataInputCount = null,Object? metadataInputLabel = freezed,Object? metadataInputDescription = freezed,Object? metadataCleanProgress = freezed,Object? metadataOutputDirectoryPath = freezed,Object? metadataOutputDirectoryDisplayName = freezed,Object? redactions = null,}) {
  return _then(_RedactionState(
image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ui.Image?,sourceFileName: freezed == sourceFileName ? _self.sourceFileName : sourceFileName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,redactionColor: null == redactionColor ? _self.redactionColor : redactionColor // ignore: cast_nullable_to_non_nullable
as Color,draftStart: freezed == draftStart ? _self.draftStart : draftStart // ignore: cast_nullable_to_non_nullable
as Offset?,draftRect: freezed == draftRect ? _self.draftRect : draftRect // ignore: cast_nullable_to_non_nullable
as Rect?,draftColor: freezed == draftColor ? _self.draftColor : draftColor // ignore: cast_nullable_to_non_nullable
as Color?,isOpening: null == isOpening ? _self.isOpening : isOpening // ignore: cast_nullable_to_non_nullable
as bool,isExporting: null == isExporting ? _self.isExporting : isExporting // ignore: cast_nullable_to_non_nullable
as bool,exportFormat: null == exportFormat ? _self.exportFormat : exportFormat // ignore: cast_nullable_to_non_nullable
as ExportFormat,jpegQualityPreset: null == jpegQualityPreset ? _self.jpegQualityPreset : jpegQualityPreset // ignore: cast_nullable_to_non_nullable
as JpegQualityPreset,preserveRedactionExportFileName: null == preserveRedactionExportFileName ? _self.preserveRedactionExportFileName : preserveRedactionExportFileName // ignore: cast_nullable_to_non_nullable
as bool,preserveMetadataCleanFileNames: null == preserveMetadataCleanFileNames ? _self.preserveMetadataCleanFileNames : preserveMetadataCleanFileNames // ignore: cast_nullable_to_non_nullable
as bool,metadataInputCount: null == metadataInputCount ? _self.metadataInputCount : metadataInputCount // ignore: cast_nullable_to_non_nullable
as int,metadataInputLabel: freezed == metadataInputLabel ? _self.metadataInputLabel : metadataInputLabel // ignore: cast_nullable_to_non_nullable
as String?,metadataInputDescription: freezed == metadataInputDescription ? _self.metadataInputDescription : metadataInputDescription // ignore: cast_nullable_to_non_nullable
as String?,metadataCleanProgress: freezed == metadataCleanProgress ? _self.metadataCleanProgress : metadataCleanProgress // ignore: cast_nullable_to_non_nullable
as double?,metadataOutputDirectoryPath: freezed == metadataOutputDirectoryPath ? _self.metadataOutputDirectoryPath : metadataOutputDirectoryPath // ignore: cast_nullable_to_non_nullable
as String?,metadataOutputDirectoryDisplayName: freezed == metadataOutputDirectoryDisplayName ? _self.metadataOutputDirectoryDisplayName : metadataOutputDirectoryDisplayName // ignore: cast_nullable_to_non_nullable
as String?,redactions: null == redactions ? _self._redactions : redactions // ignore: cast_nullable_to_non_nullable
as List<RedactionRegion>,
  ));
}


}

// dart format on
