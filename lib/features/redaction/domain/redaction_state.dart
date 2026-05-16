import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'export_format.dart';
import 'jpeg_quality_preset.dart';
import 'pdf_quality_preset.dart';
import 'redaction_region.dart';
import 'redaction_status.dart';

part 'redaction_state.freezed.dart';

@freezed
abstract class RedactionState with _$RedactionState {
  const RedactionState._();

  const factory RedactionState({
    ui.Image? image,
    String? sourceFileName,
    ui.Image? pdfPageImage,
    String? pdfSourceFileName,
    @Default(0) int pdfPageCount,
    @Default(1) int pdfCurrentPage,
    @Default(false) bool preservePdfExportFileName,
    @Default(<int, List<RedactionRegion>>{})
    Map<int, List<RedactionRegion>> pdfRedactions,
    @Default(RedactionStatus.ready()) RedactionStatus statusMessage,
    @Default(Color(0xFF050505)) Color redactionColor,
    Offset? draftStart,
    Rect? draftRect,
    Color? draftColor,
    Rect? cropRect,
    @Default(false) bool isOpening,
    @Default(false) bool isExporting,
    @Default(ExportFormat.jpeg) ExportFormat exportFormat,
    @Default(JpegQualityPreset.medium) JpegQualityPreset jpegQualityPreset,
    @Default(PdfQualityPreset.medium) PdfQualityPreset pdfQualityPreset,
    @Default(false) bool preserveRedactionExportFileName,
    @Default(false) bool preserveMetadataCleanFileNames,
    @Default(0) int metadataInputCount,
    @Default(false) bool metadataHasImages,
    @Default(false) bool metadataHasPdfs,
    String? metadataInputLabel,
    String? metadataInputDescription,
    double? metadataCleanProgress,
    String? metadataOutputDirectoryPath,
    String? metadataOutputDirectoryDisplayName,
    @Default(<RedactionRegion>[]) List<RedactionRegion> redactions,
  }) = _RedactionState;

  bool get hasImage => image != null;
  bool get isCropping => cropRect != null;
  String get status => statusMessage.fallbackMessage;
  bool get hasRedactions => redactions.isNotEmpty;
  bool get hasPdf => pdfPageImage != null && pdfPageCount > 0;
  List<RedactionRegion> get currentPdfRedactions =>
      pdfRedactions[pdfCurrentPage] ?? const <RedactionRegion>[];
  int get pdfRedactionCount => pdfRedactions.values.fold<int>(
    0,
    (count, pageRedactions) => count + pageRedactions.length,
  );
  bool get hasPdfRedactions => pdfRedactionCount > 0;
  bool get hasMetadataInput => metadataInputCount > 0;
  bool get isCleaningMetadata => metadataCleanProgress != null;
}
