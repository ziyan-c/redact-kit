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

 ui.Image? get image; String? get sourceFileName; ui.Image? get pdfPageImage; String? get pdfSourceFileName; int get pdfPageCount; int get pdfCurrentPage; bool get preservePdfExportFileName; Map<int, List<RedactionRegion>> get pdfRedactions; String get status; Color get redactionColor; Offset? get draftStart; Rect? get draftRect; Color? get draftColor; bool get isOpening; bool get isExporting; ExportFormat get exportFormat; JpegQualityPreset get jpegQualityPreset; PdfQualityPreset get pdfQualityPreset; bool get preserveRedactionExportFileName; bool get preserveMetadataCleanFileNames; int get metadataInputCount; bool get metadataHasImages; bool get metadataHasPdfs; String? get metadataInputLabel; String? get metadataInputDescription; double? get metadataCleanProgress; String? get metadataOutputDirectoryPath; String? get metadataOutputDirectoryDisplayName; List<RedactionRegion> get redactions;
/// Create a copy of RedactionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RedactionStateCopyWith<RedactionState> get copyWith => _$RedactionStateCopyWithImpl<RedactionState>(this as RedactionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RedactionState&&(identical(other.image, image) || other.image == image)&&(identical(other.sourceFileName, sourceFileName) || other.sourceFileName == sourceFileName)&&(identical(other.pdfPageImage, pdfPageImage) || other.pdfPageImage == pdfPageImage)&&(identical(other.pdfSourceFileName, pdfSourceFileName) || other.pdfSourceFileName == pdfSourceFileName)&&(identical(other.pdfPageCount, pdfPageCount) || other.pdfPageCount == pdfPageCount)&&(identical(other.pdfCurrentPage, pdfCurrentPage) || other.pdfCurrentPage == pdfCurrentPage)&&(identical(other.preservePdfExportFileName, preservePdfExportFileName) || other.preservePdfExportFileName == preservePdfExportFileName)&&const DeepCollectionEquality().equals(other.pdfRedactions, pdfRedactions)&&(identical(other.status, status) || other.status == status)&&(identical(other.redactionColor, redactionColor) || other.redactionColor == redactionColor)&&(identical(other.draftStart, draftStart) || other.draftStart == draftStart)&&(identical(other.draftRect, draftRect) || other.draftRect == draftRect)&&(identical(other.draftColor, draftColor) || other.draftColor == draftColor)&&(identical(other.isOpening, isOpening) || other.isOpening == isOpening)&&(identical(other.isExporting, isExporting) || other.isExporting == isExporting)&&(identical(other.exportFormat, exportFormat) || other.exportFormat == exportFormat)&&(identical(other.jpegQualityPreset, jpegQualityPreset) || other.jpegQualityPreset == jpegQualityPreset)&&(identical(other.pdfQualityPreset, pdfQualityPreset) || other.pdfQualityPreset == pdfQualityPreset)&&(identical(other.preserveRedactionExportFileName, preserveRedactionExportFileName) || other.preserveRedactionExportFileName == preserveRedactionExportFileName)&&(identical(other.preserveMetadataCleanFileNames, preserveMetadataCleanFileNames) || other.preserveMetadataCleanFileNames == preserveMetadataCleanFileNames)&&(identical(other.metadataInputCount, metadataInputCount) || other.metadataInputCount == metadataInputCount)&&(identical(other.metadataHasImages, metadataHasImages) || other.metadataHasImages == metadataHasImages)&&(identical(other.metadataHasPdfs, metadataHasPdfs) || other.metadataHasPdfs == metadataHasPdfs)&&(identical(other.metadataInputLabel, metadataInputLabel) || other.metadataInputLabel == metadataInputLabel)&&(identical(other.metadataInputDescription, metadataInputDescription) || other.metadataInputDescription == metadataInputDescription)&&(identical(other.metadataCleanProgress, metadataCleanProgress) || other.metadataCleanProgress == metadataCleanProgress)&&(identical(other.metadataOutputDirectoryPath, metadataOutputDirectoryPath) || other.metadataOutputDirectoryPath == metadataOutputDirectoryPath)&&(identical(other.metadataOutputDirectoryDisplayName, metadataOutputDirectoryDisplayName) || other.metadataOutputDirectoryDisplayName == metadataOutputDirectoryDisplayName)&&const DeepCollectionEquality().equals(other.redactions, redactions));
}


@override
int get hashCode => Object.hashAll([runtimeType,image,sourceFileName,pdfPageImage,pdfSourceFileName,pdfPageCount,pdfCurrentPage,preservePdfExportFileName,const DeepCollectionEquality().hash(pdfRedactions),status,redactionColor,draftStart,draftRect,draftColor,isOpening,isExporting,exportFormat,jpegQualityPreset,pdfQualityPreset,preserveRedactionExportFileName,preserveMetadataCleanFileNames,metadataInputCount,metadataHasImages,metadataHasPdfs,metadataInputLabel,metadataInputDescription,metadataCleanProgress,metadataOutputDirectoryPath,metadataOutputDirectoryDisplayName,const DeepCollectionEquality().hash(redactions)]);

@override
String toString() {
  return 'RedactionState(image: $image, sourceFileName: $sourceFileName, pdfPageImage: $pdfPageImage, pdfSourceFileName: $pdfSourceFileName, pdfPageCount: $pdfPageCount, pdfCurrentPage: $pdfCurrentPage, preservePdfExportFileName: $preservePdfExportFileName, pdfRedactions: $pdfRedactions, status: $status, redactionColor: $redactionColor, draftStart: $draftStart, draftRect: $draftRect, draftColor: $draftColor, isOpening: $isOpening, isExporting: $isExporting, exportFormat: $exportFormat, jpegQualityPreset: $jpegQualityPreset, pdfQualityPreset: $pdfQualityPreset, preserveRedactionExportFileName: $preserveRedactionExportFileName, preserveMetadataCleanFileNames: $preserveMetadataCleanFileNames, metadataInputCount: $metadataInputCount, metadataHasImages: $metadataHasImages, metadataHasPdfs: $metadataHasPdfs, metadataInputLabel: $metadataInputLabel, metadataInputDescription: $metadataInputDescription, metadataCleanProgress: $metadataCleanProgress, metadataOutputDirectoryPath: $metadataOutputDirectoryPath, metadataOutputDirectoryDisplayName: $metadataOutputDirectoryDisplayName, redactions: $redactions)';
}


}

/// @nodoc
abstract mixin class $RedactionStateCopyWith<$Res>  {
  factory $RedactionStateCopyWith(RedactionState value, $Res Function(RedactionState) _then) = _$RedactionStateCopyWithImpl;
@useResult
$Res call({
 ui.Image? image, String? sourceFileName, ui.Image? pdfPageImage, String? pdfSourceFileName, int pdfPageCount, int pdfCurrentPage, bool preservePdfExportFileName, Map<int, List<RedactionRegion>> pdfRedactions, String status, Color redactionColor, Offset? draftStart, Rect? draftRect, Color? draftColor, bool isOpening, bool isExporting, ExportFormat exportFormat, JpegQualityPreset jpegQualityPreset, PdfQualityPreset pdfQualityPreset, bool preserveRedactionExportFileName, bool preserveMetadataCleanFileNames, int metadataInputCount, bool metadataHasImages, bool metadataHasPdfs, String? metadataInputLabel, String? metadataInputDescription, double? metadataCleanProgress, String? metadataOutputDirectoryPath, String? metadataOutputDirectoryDisplayName, List<RedactionRegion> redactions
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
@pragma('vm:prefer-inline') @override $Res call({Object? image = freezed,Object? sourceFileName = freezed,Object? pdfPageImage = freezed,Object? pdfSourceFileName = freezed,Object? pdfPageCount = null,Object? pdfCurrentPage = null,Object? preservePdfExportFileName = null,Object? pdfRedactions = null,Object? status = null,Object? redactionColor = null,Object? draftStart = freezed,Object? draftRect = freezed,Object? draftColor = freezed,Object? isOpening = null,Object? isExporting = null,Object? exportFormat = null,Object? jpegQualityPreset = null,Object? pdfQualityPreset = null,Object? preserveRedactionExportFileName = null,Object? preserveMetadataCleanFileNames = null,Object? metadataInputCount = null,Object? metadataHasImages = null,Object? metadataHasPdfs = null,Object? metadataInputLabel = freezed,Object? metadataInputDescription = freezed,Object? metadataCleanProgress = freezed,Object? metadataOutputDirectoryPath = freezed,Object? metadataOutputDirectoryDisplayName = freezed,Object? redactions = null,}) {
  return _then(_self.copyWith(
image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ui.Image?,sourceFileName: freezed == sourceFileName ? _self.sourceFileName : sourceFileName // ignore: cast_nullable_to_non_nullable
as String?,pdfPageImage: freezed == pdfPageImage ? _self.pdfPageImage : pdfPageImage // ignore: cast_nullable_to_non_nullable
as ui.Image?,pdfSourceFileName: freezed == pdfSourceFileName ? _self.pdfSourceFileName : pdfSourceFileName // ignore: cast_nullable_to_non_nullable
as String?,pdfPageCount: null == pdfPageCount ? _self.pdfPageCount : pdfPageCount // ignore: cast_nullable_to_non_nullable
as int,pdfCurrentPage: null == pdfCurrentPage ? _self.pdfCurrentPage : pdfCurrentPage // ignore: cast_nullable_to_non_nullable
as int,preservePdfExportFileName: null == preservePdfExportFileName ? _self.preservePdfExportFileName : preservePdfExportFileName // ignore: cast_nullable_to_non_nullable
as bool,pdfRedactions: null == pdfRedactions ? _self.pdfRedactions : pdfRedactions // ignore: cast_nullable_to_non_nullable
as Map<int, List<RedactionRegion>>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,redactionColor: null == redactionColor ? _self.redactionColor : redactionColor // ignore: cast_nullable_to_non_nullable
as Color,draftStart: freezed == draftStart ? _self.draftStart : draftStart // ignore: cast_nullable_to_non_nullable
as Offset?,draftRect: freezed == draftRect ? _self.draftRect : draftRect // ignore: cast_nullable_to_non_nullable
as Rect?,draftColor: freezed == draftColor ? _self.draftColor : draftColor // ignore: cast_nullable_to_non_nullable
as Color?,isOpening: null == isOpening ? _self.isOpening : isOpening // ignore: cast_nullable_to_non_nullable
as bool,isExporting: null == isExporting ? _self.isExporting : isExporting // ignore: cast_nullable_to_non_nullable
as bool,exportFormat: null == exportFormat ? _self.exportFormat : exportFormat // ignore: cast_nullable_to_non_nullable
as ExportFormat,jpegQualityPreset: null == jpegQualityPreset ? _self.jpegQualityPreset : jpegQualityPreset // ignore: cast_nullable_to_non_nullable
as JpegQualityPreset,pdfQualityPreset: null == pdfQualityPreset ? _self.pdfQualityPreset : pdfQualityPreset // ignore: cast_nullable_to_non_nullable
as PdfQualityPreset,preserveRedactionExportFileName: null == preserveRedactionExportFileName ? _self.preserveRedactionExportFileName : preserveRedactionExportFileName // ignore: cast_nullable_to_non_nullable
as bool,preserveMetadataCleanFileNames: null == preserveMetadataCleanFileNames ? _self.preserveMetadataCleanFileNames : preserveMetadataCleanFileNames // ignore: cast_nullable_to_non_nullable
as bool,metadataInputCount: null == metadataInputCount ? _self.metadataInputCount : metadataInputCount // ignore: cast_nullable_to_non_nullable
as int,metadataHasImages: null == metadataHasImages ? _self.metadataHasImages : metadataHasImages // ignore: cast_nullable_to_non_nullable
as bool,metadataHasPdfs: null == metadataHasPdfs ? _self.metadataHasPdfs : metadataHasPdfs // ignore: cast_nullable_to_non_nullable
as bool,metadataInputLabel: freezed == metadataInputLabel ? _self.metadataInputLabel : metadataInputLabel // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ui.Image? image,  String? sourceFileName,  ui.Image? pdfPageImage,  String? pdfSourceFileName,  int pdfPageCount,  int pdfCurrentPage,  bool preservePdfExportFileName,  Map<int, List<RedactionRegion>> pdfRedactions,  String status,  Color redactionColor,  Offset? draftStart,  Rect? draftRect,  Color? draftColor,  bool isOpening,  bool isExporting,  ExportFormat exportFormat,  JpegQualityPreset jpegQualityPreset,  PdfQualityPreset pdfQualityPreset,  bool preserveRedactionExportFileName,  bool preserveMetadataCleanFileNames,  int metadataInputCount,  bool metadataHasImages,  bool metadataHasPdfs,  String? metadataInputLabel,  String? metadataInputDescription,  double? metadataCleanProgress,  String? metadataOutputDirectoryPath,  String? metadataOutputDirectoryDisplayName,  List<RedactionRegion> redactions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RedactionState() when $default != null:
return $default(_that.image,_that.sourceFileName,_that.pdfPageImage,_that.pdfSourceFileName,_that.pdfPageCount,_that.pdfCurrentPage,_that.preservePdfExportFileName,_that.pdfRedactions,_that.status,_that.redactionColor,_that.draftStart,_that.draftRect,_that.draftColor,_that.isOpening,_that.isExporting,_that.exportFormat,_that.jpegQualityPreset,_that.pdfQualityPreset,_that.preserveRedactionExportFileName,_that.preserveMetadataCleanFileNames,_that.metadataInputCount,_that.metadataHasImages,_that.metadataHasPdfs,_that.metadataInputLabel,_that.metadataInputDescription,_that.metadataCleanProgress,_that.metadataOutputDirectoryPath,_that.metadataOutputDirectoryDisplayName,_that.redactions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ui.Image? image,  String? sourceFileName,  ui.Image? pdfPageImage,  String? pdfSourceFileName,  int pdfPageCount,  int pdfCurrentPage,  bool preservePdfExportFileName,  Map<int, List<RedactionRegion>> pdfRedactions,  String status,  Color redactionColor,  Offset? draftStart,  Rect? draftRect,  Color? draftColor,  bool isOpening,  bool isExporting,  ExportFormat exportFormat,  JpegQualityPreset jpegQualityPreset,  PdfQualityPreset pdfQualityPreset,  bool preserveRedactionExportFileName,  bool preserveMetadataCleanFileNames,  int metadataInputCount,  bool metadataHasImages,  bool metadataHasPdfs,  String? metadataInputLabel,  String? metadataInputDescription,  double? metadataCleanProgress,  String? metadataOutputDirectoryPath,  String? metadataOutputDirectoryDisplayName,  List<RedactionRegion> redactions)  $default,) {final _that = this;
switch (_that) {
case _RedactionState():
return $default(_that.image,_that.sourceFileName,_that.pdfPageImage,_that.pdfSourceFileName,_that.pdfPageCount,_that.pdfCurrentPage,_that.preservePdfExportFileName,_that.pdfRedactions,_that.status,_that.redactionColor,_that.draftStart,_that.draftRect,_that.draftColor,_that.isOpening,_that.isExporting,_that.exportFormat,_that.jpegQualityPreset,_that.pdfQualityPreset,_that.preserveRedactionExportFileName,_that.preserveMetadataCleanFileNames,_that.metadataInputCount,_that.metadataHasImages,_that.metadataHasPdfs,_that.metadataInputLabel,_that.metadataInputDescription,_that.metadataCleanProgress,_that.metadataOutputDirectoryPath,_that.metadataOutputDirectoryDisplayName,_that.redactions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ui.Image? image,  String? sourceFileName,  ui.Image? pdfPageImage,  String? pdfSourceFileName,  int pdfPageCount,  int pdfCurrentPage,  bool preservePdfExportFileName,  Map<int, List<RedactionRegion>> pdfRedactions,  String status,  Color redactionColor,  Offset? draftStart,  Rect? draftRect,  Color? draftColor,  bool isOpening,  bool isExporting,  ExportFormat exportFormat,  JpegQualityPreset jpegQualityPreset,  PdfQualityPreset pdfQualityPreset,  bool preserveRedactionExportFileName,  bool preserveMetadataCleanFileNames,  int metadataInputCount,  bool metadataHasImages,  bool metadataHasPdfs,  String? metadataInputLabel,  String? metadataInputDescription,  double? metadataCleanProgress,  String? metadataOutputDirectoryPath,  String? metadataOutputDirectoryDisplayName,  List<RedactionRegion> redactions)?  $default,) {final _that = this;
switch (_that) {
case _RedactionState() when $default != null:
return $default(_that.image,_that.sourceFileName,_that.pdfPageImage,_that.pdfSourceFileName,_that.pdfPageCount,_that.pdfCurrentPage,_that.preservePdfExportFileName,_that.pdfRedactions,_that.status,_that.redactionColor,_that.draftStart,_that.draftRect,_that.draftColor,_that.isOpening,_that.isExporting,_that.exportFormat,_that.jpegQualityPreset,_that.pdfQualityPreset,_that.preserveRedactionExportFileName,_that.preserveMetadataCleanFileNames,_that.metadataInputCount,_that.metadataHasImages,_that.metadataHasPdfs,_that.metadataInputLabel,_that.metadataInputDescription,_that.metadataCleanProgress,_that.metadataOutputDirectoryPath,_that.metadataOutputDirectoryDisplayName,_that.redactions);case _:
  return null;

}
}

}

/// @nodoc


class _RedactionState extends RedactionState {
  const _RedactionState({this.image, this.sourceFileName, this.pdfPageImage, this.pdfSourceFileName, this.pdfPageCount = 0, this.pdfCurrentPage = 1, this.preservePdfExportFileName = false, final  Map<int, List<RedactionRegion>> pdfRedactions = const <int, List<RedactionRegion>>{}, this.status = 'Ready', this.redactionColor = const Color(0xFF050505), this.draftStart, this.draftRect, this.draftColor, this.isOpening = false, this.isExporting = false, this.exportFormat = ExportFormat.jpeg, this.jpegQualityPreset = JpegQualityPreset.medium, this.pdfQualityPreset = PdfQualityPreset.medium, this.preserveRedactionExportFileName = false, this.preserveMetadataCleanFileNames = false, this.metadataInputCount = 0, this.metadataHasImages = false, this.metadataHasPdfs = false, this.metadataInputLabel, this.metadataInputDescription, this.metadataCleanProgress, this.metadataOutputDirectoryPath, this.metadataOutputDirectoryDisplayName, final  List<RedactionRegion> redactions = const <RedactionRegion>[]}): _pdfRedactions = pdfRedactions,_redactions = redactions,super._();
  

@override final  ui.Image? image;
@override final  String? sourceFileName;
@override final  ui.Image? pdfPageImage;
@override final  String? pdfSourceFileName;
@override@JsonKey() final  int pdfPageCount;
@override@JsonKey() final  int pdfCurrentPage;
@override@JsonKey() final  bool preservePdfExportFileName;
 final  Map<int, List<RedactionRegion>> _pdfRedactions;
@override@JsonKey() Map<int, List<RedactionRegion>> get pdfRedactions {
  if (_pdfRedactions is EqualUnmodifiableMapView) return _pdfRedactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pdfRedactions);
}

@override@JsonKey() final  String status;
@override@JsonKey() final  Color redactionColor;
@override final  Offset? draftStart;
@override final  Rect? draftRect;
@override final  Color? draftColor;
@override@JsonKey() final  bool isOpening;
@override@JsonKey() final  bool isExporting;
@override@JsonKey() final  ExportFormat exportFormat;
@override@JsonKey() final  JpegQualityPreset jpegQualityPreset;
@override@JsonKey() final  PdfQualityPreset pdfQualityPreset;
@override@JsonKey() final  bool preserveRedactionExportFileName;
@override@JsonKey() final  bool preserveMetadataCleanFileNames;
@override@JsonKey() final  int metadataInputCount;
@override@JsonKey() final  bool metadataHasImages;
@override@JsonKey() final  bool metadataHasPdfs;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RedactionState&&(identical(other.image, image) || other.image == image)&&(identical(other.sourceFileName, sourceFileName) || other.sourceFileName == sourceFileName)&&(identical(other.pdfPageImage, pdfPageImage) || other.pdfPageImage == pdfPageImage)&&(identical(other.pdfSourceFileName, pdfSourceFileName) || other.pdfSourceFileName == pdfSourceFileName)&&(identical(other.pdfPageCount, pdfPageCount) || other.pdfPageCount == pdfPageCount)&&(identical(other.pdfCurrentPage, pdfCurrentPage) || other.pdfCurrentPage == pdfCurrentPage)&&(identical(other.preservePdfExportFileName, preservePdfExportFileName) || other.preservePdfExportFileName == preservePdfExportFileName)&&const DeepCollectionEquality().equals(other._pdfRedactions, _pdfRedactions)&&(identical(other.status, status) || other.status == status)&&(identical(other.redactionColor, redactionColor) || other.redactionColor == redactionColor)&&(identical(other.draftStart, draftStart) || other.draftStart == draftStart)&&(identical(other.draftRect, draftRect) || other.draftRect == draftRect)&&(identical(other.draftColor, draftColor) || other.draftColor == draftColor)&&(identical(other.isOpening, isOpening) || other.isOpening == isOpening)&&(identical(other.isExporting, isExporting) || other.isExporting == isExporting)&&(identical(other.exportFormat, exportFormat) || other.exportFormat == exportFormat)&&(identical(other.jpegQualityPreset, jpegQualityPreset) || other.jpegQualityPreset == jpegQualityPreset)&&(identical(other.pdfQualityPreset, pdfQualityPreset) || other.pdfQualityPreset == pdfQualityPreset)&&(identical(other.preserveRedactionExportFileName, preserveRedactionExportFileName) || other.preserveRedactionExportFileName == preserveRedactionExportFileName)&&(identical(other.preserveMetadataCleanFileNames, preserveMetadataCleanFileNames) || other.preserveMetadataCleanFileNames == preserveMetadataCleanFileNames)&&(identical(other.metadataInputCount, metadataInputCount) || other.metadataInputCount == metadataInputCount)&&(identical(other.metadataHasImages, metadataHasImages) || other.metadataHasImages == metadataHasImages)&&(identical(other.metadataHasPdfs, metadataHasPdfs) || other.metadataHasPdfs == metadataHasPdfs)&&(identical(other.metadataInputLabel, metadataInputLabel) || other.metadataInputLabel == metadataInputLabel)&&(identical(other.metadataInputDescription, metadataInputDescription) || other.metadataInputDescription == metadataInputDescription)&&(identical(other.metadataCleanProgress, metadataCleanProgress) || other.metadataCleanProgress == metadataCleanProgress)&&(identical(other.metadataOutputDirectoryPath, metadataOutputDirectoryPath) || other.metadataOutputDirectoryPath == metadataOutputDirectoryPath)&&(identical(other.metadataOutputDirectoryDisplayName, metadataOutputDirectoryDisplayName) || other.metadataOutputDirectoryDisplayName == metadataOutputDirectoryDisplayName)&&const DeepCollectionEquality().equals(other._redactions, _redactions));
}


@override
int get hashCode => Object.hashAll([runtimeType,image,sourceFileName,pdfPageImage,pdfSourceFileName,pdfPageCount,pdfCurrentPage,preservePdfExportFileName,const DeepCollectionEquality().hash(_pdfRedactions),status,redactionColor,draftStart,draftRect,draftColor,isOpening,isExporting,exportFormat,jpegQualityPreset,pdfQualityPreset,preserveRedactionExportFileName,preserveMetadataCleanFileNames,metadataInputCount,metadataHasImages,metadataHasPdfs,metadataInputLabel,metadataInputDescription,metadataCleanProgress,metadataOutputDirectoryPath,metadataOutputDirectoryDisplayName,const DeepCollectionEquality().hash(_redactions)]);

@override
String toString() {
  return 'RedactionState(image: $image, sourceFileName: $sourceFileName, pdfPageImage: $pdfPageImage, pdfSourceFileName: $pdfSourceFileName, pdfPageCount: $pdfPageCount, pdfCurrentPage: $pdfCurrentPage, preservePdfExportFileName: $preservePdfExportFileName, pdfRedactions: $pdfRedactions, status: $status, redactionColor: $redactionColor, draftStart: $draftStart, draftRect: $draftRect, draftColor: $draftColor, isOpening: $isOpening, isExporting: $isExporting, exportFormat: $exportFormat, jpegQualityPreset: $jpegQualityPreset, pdfQualityPreset: $pdfQualityPreset, preserveRedactionExportFileName: $preserveRedactionExportFileName, preserveMetadataCleanFileNames: $preserveMetadataCleanFileNames, metadataInputCount: $metadataInputCount, metadataHasImages: $metadataHasImages, metadataHasPdfs: $metadataHasPdfs, metadataInputLabel: $metadataInputLabel, metadataInputDescription: $metadataInputDescription, metadataCleanProgress: $metadataCleanProgress, metadataOutputDirectoryPath: $metadataOutputDirectoryPath, metadataOutputDirectoryDisplayName: $metadataOutputDirectoryDisplayName, redactions: $redactions)';
}


}

/// @nodoc
abstract mixin class _$RedactionStateCopyWith<$Res> implements $RedactionStateCopyWith<$Res> {
  factory _$RedactionStateCopyWith(_RedactionState value, $Res Function(_RedactionState) _then) = __$RedactionStateCopyWithImpl;
@override @useResult
$Res call({
 ui.Image? image, String? sourceFileName, ui.Image? pdfPageImage, String? pdfSourceFileName, int pdfPageCount, int pdfCurrentPage, bool preservePdfExportFileName, Map<int, List<RedactionRegion>> pdfRedactions, String status, Color redactionColor, Offset? draftStart, Rect? draftRect, Color? draftColor, bool isOpening, bool isExporting, ExportFormat exportFormat, JpegQualityPreset jpegQualityPreset, PdfQualityPreset pdfQualityPreset, bool preserveRedactionExportFileName, bool preserveMetadataCleanFileNames, int metadataInputCount, bool metadataHasImages, bool metadataHasPdfs, String? metadataInputLabel, String? metadataInputDescription, double? metadataCleanProgress, String? metadataOutputDirectoryPath, String? metadataOutputDirectoryDisplayName, List<RedactionRegion> redactions
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
@override @pragma('vm:prefer-inline') $Res call({Object? image = freezed,Object? sourceFileName = freezed,Object? pdfPageImage = freezed,Object? pdfSourceFileName = freezed,Object? pdfPageCount = null,Object? pdfCurrentPage = null,Object? preservePdfExportFileName = null,Object? pdfRedactions = null,Object? status = null,Object? redactionColor = null,Object? draftStart = freezed,Object? draftRect = freezed,Object? draftColor = freezed,Object? isOpening = null,Object? isExporting = null,Object? exportFormat = null,Object? jpegQualityPreset = null,Object? pdfQualityPreset = null,Object? preserveRedactionExportFileName = null,Object? preserveMetadataCleanFileNames = null,Object? metadataInputCount = null,Object? metadataHasImages = null,Object? metadataHasPdfs = null,Object? metadataInputLabel = freezed,Object? metadataInputDescription = freezed,Object? metadataCleanProgress = freezed,Object? metadataOutputDirectoryPath = freezed,Object? metadataOutputDirectoryDisplayName = freezed,Object? redactions = null,}) {
  return _then(_RedactionState(
image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ui.Image?,sourceFileName: freezed == sourceFileName ? _self.sourceFileName : sourceFileName // ignore: cast_nullable_to_non_nullable
as String?,pdfPageImage: freezed == pdfPageImage ? _self.pdfPageImage : pdfPageImage // ignore: cast_nullable_to_non_nullable
as ui.Image?,pdfSourceFileName: freezed == pdfSourceFileName ? _self.pdfSourceFileName : pdfSourceFileName // ignore: cast_nullable_to_non_nullable
as String?,pdfPageCount: null == pdfPageCount ? _self.pdfPageCount : pdfPageCount // ignore: cast_nullable_to_non_nullable
as int,pdfCurrentPage: null == pdfCurrentPage ? _self.pdfCurrentPage : pdfCurrentPage // ignore: cast_nullable_to_non_nullable
as int,preservePdfExportFileName: null == preservePdfExportFileName ? _self.preservePdfExportFileName : preservePdfExportFileName // ignore: cast_nullable_to_non_nullable
as bool,pdfRedactions: null == pdfRedactions ? _self._pdfRedactions : pdfRedactions // ignore: cast_nullable_to_non_nullable
as Map<int, List<RedactionRegion>>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,redactionColor: null == redactionColor ? _self.redactionColor : redactionColor // ignore: cast_nullable_to_non_nullable
as Color,draftStart: freezed == draftStart ? _self.draftStart : draftStart // ignore: cast_nullable_to_non_nullable
as Offset?,draftRect: freezed == draftRect ? _self.draftRect : draftRect // ignore: cast_nullable_to_non_nullable
as Rect?,draftColor: freezed == draftColor ? _self.draftColor : draftColor // ignore: cast_nullable_to_non_nullable
as Color?,isOpening: null == isOpening ? _self.isOpening : isOpening // ignore: cast_nullable_to_non_nullable
as bool,isExporting: null == isExporting ? _self.isExporting : isExporting // ignore: cast_nullable_to_non_nullable
as bool,exportFormat: null == exportFormat ? _self.exportFormat : exportFormat // ignore: cast_nullable_to_non_nullable
as ExportFormat,jpegQualityPreset: null == jpegQualityPreset ? _self.jpegQualityPreset : jpegQualityPreset // ignore: cast_nullable_to_non_nullable
as JpegQualityPreset,pdfQualityPreset: null == pdfQualityPreset ? _self.pdfQualityPreset : pdfQualityPreset // ignore: cast_nullable_to_non_nullable
as PdfQualityPreset,preserveRedactionExportFileName: null == preserveRedactionExportFileName ? _self.preserveRedactionExportFileName : preserveRedactionExportFileName // ignore: cast_nullable_to_non_nullable
as bool,preserveMetadataCleanFileNames: null == preserveMetadataCleanFileNames ? _self.preserveMetadataCleanFileNames : preserveMetadataCleanFileNames // ignore: cast_nullable_to_non_nullable
as bool,metadataInputCount: null == metadataInputCount ? _self.metadataInputCount : metadataInputCount // ignore: cast_nullable_to_non_nullable
as int,metadataHasImages: null == metadataHasImages ? _self.metadataHasImages : metadataHasImages // ignore: cast_nullable_to_non_nullable
as bool,metadataHasPdfs: null == metadataHasPdfs ? _self.metadataHasPdfs : metadataHasPdfs // ignore: cast_nullable_to_non_nullable
as bool,metadataInputLabel: freezed == metadataInputLabel ? _self.metadataInputLabel : metadataInputLabel // ignore: cast_nullable_to_non_nullable
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
