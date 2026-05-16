import 'package:flutter/foundation.dart';

import 'metadata_input_display.dart';

enum RedactionStatusKind {
  ready,
  openingImage,
  openingPhotoLibrary,
  openingPdf,
  loadedImage,
  pdfPage,
  renderingPdfPage,
  flatteningCleanPdf,
  flatteningPdfPage,
  choosingPdf,
  choosingFilesOrFolder,
  choosingImageFile,
  choosingImageFiles,
  choosingPdfFile,
  choosingPdfFiles,
  choosingFolder,
  choosingImagesFromPhotos,
  choosingOutputFolder,
  addingFiles,
  addingPhotos,
  selectedMetadataInput,
  removedMetadataInput,
  noSupportedImagesOrPdfsSelected,
  noSupportedImagesOrPdfsFoundInFolder,
  noPhotosSelected,
  removeFolderBeforeAddingPhotos,
  chooseMetadataInputFirst,
  metadataOutputFolderSet,
  startCleaningFirstToCreateOutputFolder,
  openedOutputFolder,
  encodingCleanImage,
  removingImageMetadata,
  preparingCleanImageToShare,
  savingCleanImageToPhotos,
  exportedCleanImage,
  savedCleanImageToPhotos,
  sharedCleanImage,
  savedMetadataCleanImage,
  cleaningPdfMetadata,
  savedMetadataCleanPdf,
  exportedCleanPdf,
  exportCanceled,
  metadataRemovalCanceled,
  pdfExportCanceled,
  pdfCleanCanceled,
  shareCanceled,
  saveCanceled,
  startingMetadataClean,
  preparingOutputFolder,
  startingMetadataCleanToPhotos,
  photosOutputImagesOnly,
  cleaningMetadataItem,
  cleaningMetadataPdfPage,
  savingMetadataItemToPhotos,
  metadataBatchResult,
  redactionsCleared,
  pdfPageRedactionsCleared,
  redactionCountReady,
  pdfRedactionCountReady,
  couldNotOpenPdf,
  couldNotOpenImage,
  couldNotDecodeImage,
  couldNotExportImage,
  couldNotExportPdf,
  couldNotChooseMetadataInput,
  couldNotAddMetadataFiles,
  couldNotAddPhotos,
  couldNotChooseOutputFolder,
  couldNotOpenOutputFolder,
  couldNotCleanMetadata,
  couldNotCreateOutputFolder,
  couldNotRenderPdfPage,
  externalMessage,
}

@immutable
class RedactionStatus {
  const RedactionStatus._(
    this.kind,
    this.fallbackMessage, {
    this.formatLabel,
    this.label,
    this.detail,
    this.destinationName,
    this.path,
    this.width,
    this.height,
    this.count,
    this.pageNumber,
    this.pageCount,
    this.current,
    this.total,
    this.savedCount,
    this.failedCount,
    this.ignoredCount,
    this.metadataInputSummary,
    this.automaticOutputFailure = false,
  });

  const RedactionStatus.ready() : this._(RedactionStatusKind.ready, 'Ready');

  const RedactionStatus.openingImage()
    : this._(RedactionStatusKind.openingImage, 'Opening image');

  const RedactionStatus.openingPhotoLibrary()
    : this._(RedactionStatusKind.openingPhotoLibrary, 'Opening photo library');

  const RedactionStatus.openingPdf()
    : this._(RedactionStatusKind.openingPdf, 'Opening PDF');

  factory RedactionStatus.loadedImage({
    required int width,
    required int height,
  }) {
    return RedactionStatus._(
      RedactionStatusKind.loadedImage,
      'Loaded $width x ${height}px',
      width: width,
      height: height,
    );
  }

  factory RedactionStatus.pdfPage({
    required int pageNumber,
    required int pageCount,
  }) {
    return RedactionStatus._(
      RedactionStatusKind.pdfPage,
      'PDF page $pageNumber of $pageCount',
      pageNumber: pageNumber,
      pageCount: pageCount,
    );
  }

  factory RedactionStatus.loadedPdf({
    required int pageNumber,
    required int pageCount,
  }) {
    return RedactionStatus._(
      RedactionStatusKind.pdfPage,
      'Loaded PDF page $pageNumber of $pageCount',
      pageNumber: pageNumber,
      pageCount: pageCount,
    );
  }

  factory RedactionStatus.renderingPdfPage(int pageNumber) {
    return RedactionStatus._(
      RedactionStatusKind.renderingPdfPage,
      'Rendering PDF page $pageNumber',
      pageNumber: pageNumber,
    );
  }

  const RedactionStatus.flatteningCleanPdf()
    : this._(RedactionStatusKind.flatteningCleanPdf, 'Flattening clean PDF');

  factory RedactionStatus.flatteningPdfPage({
    required int pageNumber,
    required int pageCount,
  }) {
    return RedactionStatus._(
      RedactionStatusKind.flatteningPdfPage,
      'Flattening PDF page $pageNumber of $pageCount',
      pageNumber: pageNumber,
      pageCount: pageCount,
    );
  }

  const RedactionStatus.choosingPdf()
    : this._(RedactionStatusKind.choosingPdf, 'Choosing PDF');

  const RedactionStatus.choosingFilesOrFolder()
    : this._(
        RedactionStatusKind.choosingFilesOrFolder,
        'Choosing files or folder',
      );

  const RedactionStatus.choosingImageFile()
    : this._(RedactionStatusKind.choosingImageFile, 'Choosing image file');

  const RedactionStatus.choosingImageFiles()
    : this._(RedactionStatusKind.choosingImageFiles, 'Choosing image files');

  const RedactionStatus.choosingPdfFile()
    : this._(RedactionStatusKind.choosingPdfFile, 'Choosing PDF file');

  const RedactionStatus.choosingPdfFiles()
    : this._(RedactionStatusKind.choosingPdfFiles, 'Choosing PDF files');

  const RedactionStatus.choosingFolder()
    : this._(RedactionStatusKind.choosingFolder, 'Choosing folder');

  const RedactionStatus.choosingImagesFromPhotos()
    : this._(
        RedactionStatusKind.choosingImagesFromPhotos,
        'Choosing images from Photos',
      );

  const RedactionStatus.choosingOutputFolder()
    : this._(
        RedactionStatusKind.choosingOutputFolder,
        'Choosing output folder',
      );

  const RedactionStatus.addingFiles()
    : this._(RedactionStatusKind.addingFiles, 'Adding files');

  const RedactionStatus.addingPhotos()
    : this._(RedactionStatusKind.addingPhotos, 'Adding photos');

  factory RedactionStatus.selectedMetadataInput(MetadataInputSummary summary) {
    return RedactionStatus._(
      RedactionStatusKind.selectedMetadataInput,
      'Selected ${summary.fallbackLabel}',
      label: summary.fallbackLabel,
      metadataInputSummary: summary,
    );
  }

  factory RedactionStatus.removedMetadataInput(MetadataInputSummary summary) {
    return RedactionStatus._(
      RedactionStatusKind.removedMetadataInput,
      'Removed ${summary.fallbackLabel}',
      label: summary.fallbackLabel,
      metadataInputSummary: summary,
    );
  }

  const RedactionStatus.noSupportedImagesOrPdfsSelected()
    : this._(
        RedactionStatusKind.noSupportedImagesOrPdfsSelected,
        'No supported images or PDFs selected',
      );

  const RedactionStatus.noSupportedImagesOrPdfsFoundInFolder()
    : this._(
        RedactionStatusKind.noSupportedImagesOrPdfsFoundInFolder,
        'No supported images or PDFs found in that folder',
      );

  const RedactionStatus.noPhotosSelected()
    : this._(RedactionStatusKind.noPhotosSelected, 'No photos selected');

  const RedactionStatus.removeFolderBeforeAddingPhotos()
    : this._(
        RedactionStatusKind.removeFolderBeforeAddingPhotos,
        'Remove the folder before adding photos',
      );

  const RedactionStatus.chooseMetadataInputFirst()
    : this._(
        RedactionStatusKind.chooseMetadataInputFirst,
        'Choose metadata input first',
      );

  const RedactionStatus.metadataOutputFolderSet()
    : this._(
        RedactionStatusKind.metadataOutputFolderSet,
        'Metadata output folder set',
      );

  const RedactionStatus.startCleaningFirstToCreateOutputFolder()
    : this._(
        RedactionStatusKind.startCleaningFirstToCreateOutputFolder,
        'Start cleaning first to create the output folder',
      );

  const RedactionStatus.openedOutputFolder()
    : this._(RedactionStatusKind.openedOutputFolder, 'Opened output folder');

  factory RedactionStatus.encodingCleanImage(String formatLabel) {
    return RedactionStatus._(
      RedactionStatusKind.encodingCleanImage,
      'Encoding clean $formatLabel',
      formatLabel: formatLabel,
    );
  }

  factory RedactionStatus.removingImageMetadata(String formatLabel) {
    return RedactionStatus._(
      RedactionStatusKind.removingImageMetadata,
      'Removing metadata from $formatLabel',
      formatLabel: formatLabel,
    );
  }

  factory RedactionStatus.preparingCleanImageToShare(String formatLabel) {
    return RedactionStatus._(
      RedactionStatusKind.preparingCleanImageToShare,
      'Preparing clean $formatLabel to share',
      formatLabel: formatLabel,
    );
  }

  factory RedactionStatus.savingCleanImageToPhotos(String formatLabel) {
    return RedactionStatus._(
      RedactionStatusKind.savingCleanImageToPhotos,
      'Saving clean $formatLabel to Photos',
      formatLabel: formatLabel,
    );
  }

  factory RedactionStatus.exportedCleanImage({
    required String formatLabel,
    required int redactionCount,
  }) {
    return RedactionStatus._(
      RedactionStatusKind.exportedCleanImage,
      redactionCount == 0
          ? 'Exported clean $formatLabel'
          : 'Exported clean $formatLabel with $redactionCount redaction${redactionCount == 1 ? '' : 's'}',
      formatLabel: formatLabel,
      count: redactionCount,
    );
  }

  factory RedactionStatus.savedCleanImageToPhotos(String formatLabel) {
    return RedactionStatus._(
      RedactionStatusKind.savedCleanImageToPhotos,
      'Saved clean $formatLabel to Photos',
      formatLabel: formatLabel,
    );
  }

  factory RedactionStatus.sharedCleanImage(String formatLabel) {
    return RedactionStatus._(
      RedactionStatusKind.sharedCleanImage,
      'Shared clean $formatLabel',
      formatLabel: formatLabel,
    );
  }

  factory RedactionStatus.savedMetadataCleanImage(String formatLabel) {
    return RedactionStatus._(
      RedactionStatusKind.savedMetadataCleanImage,
      'Saved metadata-clean $formatLabel',
      formatLabel: formatLabel,
    );
  }

  const RedactionStatus.cleaningPdfMetadata()
    : this._(RedactionStatusKind.cleaningPdfMetadata, 'Cleaning PDF metadata');

  const RedactionStatus.savedMetadataCleanPdf()
    : this._(
        RedactionStatusKind.savedMetadataCleanPdf,
        'Saved metadata-clean PDF',
      );

  factory RedactionStatus.exportedCleanPdf(int redactionCount) {
    return RedactionStatus._(
      RedactionStatusKind.exportedCleanPdf,
      redactionCount == 0
          ? 'Exported clean PDF'
          : 'Exported clean PDF with $redactionCount redaction${redactionCount == 1 ? '' : 's'}',
      count: redactionCount,
    );
  }

  const RedactionStatus.exportCanceled()
    : this._(RedactionStatusKind.exportCanceled, 'Export canceled');

  const RedactionStatus.metadataRemovalCanceled()
    : this._(
        RedactionStatusKind.metadataRemovalCanceled,
        'Metadata removal canceled',
      );

  const RedactionStatus.pdfExportCanceled()
    : this._(RedactionStatusKind.pdfExportCanceled, 'PDF export canceled');

  const RedactionStatus.pdfCleanCanceled()
    : this._(RedactionStatusKind.pdfCleanCanceled, 'PDF clean canceled');

  const RedactionStatus.shareCanceled()
    : this._(RedactionStatusKind.shareCanceled, 'Share canceled');

  const RedactionStatus.saveCanceled()
    : this._(RedactionStatusKind.saveCanceled, 'Save canceled');

  const RedactionStatus.startingMetadataClean()
    : this._(
        RedactionStatusKind.startingMetadataClean,
        'Starting metadata clean',
      );

  const RedactionStatus.preparingOutputFolder()
    : this._(
        RedactionStatusKind.preparingOutputFolder,
        'Preparing output folder',
      );

  const RedactionStatus.startingMetadataCleanToPhotos()
    : this._(
        RedactionStatusKind.startingMetadataCleanToPhotos,
        'Starting metadata clean to Photos',
      );

  const RedactionStatus.photosOutputImagesOnly()
    : this._(
        RedactionStatusKind.photosOutputImagesOnly,
        'Photos output is available for image files only',
      );

  factory RedactionStatus.cleaningMetadataItem({
    required String label,
    required int current,
    required int total,
  }) {
    return RedactionStatus._(
      RedactionStatusKind.cleaningMetadataItem,
      'Cleaning $label ($current/$total)',
      label: label,
      current: current,
      total: total,
    );
  }

  factory RedactionStatus.cleaningMetadataPdfPage({
    required String label,
    required int pageNumber,
    required int pageCount,
    required int current,
    required int total,
  }) {
    return RedactionStatus._(
      RedactionStatusKind.cleaningMetadataPdfPage,
      'Cleaning $label page $pageNumber of $pageCount ($current/$total)',
      label: label,
      pageNumber: pageNumber,
      pageCount: pageCount,
      current: current,
      total: total,
    );
  }

  factory RedactionStatus.savingMetadataItemToPhotos({
    required String label,
    required int current,
    required int total,
  }) {
    return RedactionStatus._(
      RedactionStatusKind.savingMetadataItemToPhotos,
      'Saving $label to Photos ($current/$total)',
      label: label,
      current: current,
      total: total,
    );
  }

  factory RedactionStatus.metadataBatchResult({
    required int savedCount,
    required int failedCount,
    required int ignoredCount,
    required String destinationName,
    String? firstFailure,
  }) {
    final details = <String>[
      if (ignoredCount > 0) '$ignoredCount ignored',
      if (failedCount > 0 && savedCount == 0) '$failedCount failed',
      if (failedCount > 0 && savedCount > 0)
        firstFailure == null
            ? '$failedCount failed'
            : '$failedCount failed: $firstFailure',
    ];
    final detailText = details.isEmpty ? '' : ' (${details.join(', ')})';

    if (savedCount == 0) {
      return RedactionStatus._(
        RedactionStatusKind.couldNotCleanMetadata,
        firstFailure == null
            ? 'Could not clean metadata for selected files$detailText'
            : 'Could not clean metadata: $firstFailure$detailText',
        detail: firstFailure,
        savedCount: savedCount,
        failedCount: failedCount,
        ignoredCount: ignoredCount,
      );
    }

    final fileLabel = savedCount == 1 ? 'file' : 'files';
    return RedactionStatus._(
      RedactionStatusKind.metadataBatchResult,
      failedCount == 0
          ? 'Success: cleaned metadata for $savedCount $fileLabel to $destinationName$detailText'
          : 'Cleaned metadata for $savedCount $fileLabel to $destinationName$detailText',
      destinationName: destinationName,
      detail: firstFailure,
      savedCount: savedCount,
      failedCount: failedCount,
      ignoredCount: ignoredCount,
    );
  }

  const RedactionStatus.redactionsCleared()
    : this._(RedactionStatusKind.redactionsCleared, 'Redactions cleared');

  const RedactionStatus.pdfPageRedactionsCleared()
    : this._(
        RedactionStatusKind.pdfPageRedactionsCleared,
        'PDF page redactions cleared',
      );

  factory RedactionStatus.redactionCountReady(int count) {
    return RedactionStatus._(
      RedactionStatusKind.redactionCountReady,
      '$count redaction${count == 1 ? '' : 's'} ready',
      count: count,
    );
  }

  factory RedactionStatus.pdfRedactionCountReady({
    required int pageNumber,
    required int count,
  }) {
    return RedactionStatus._(
      RedactionStatusKind.pdfRedactionCountReady,
      'PDF page $pageNumber: $count redaction${count == 1 ? '' : 's'} ready',
      pageNumber: pageNumber,
      count: count,
    );
  }

  factory RedactionStatus.couldNotOpenPdf([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotOpenPdf,
      _couldNotFallback('Could not open PDF', detail),
      detail: detail,
    );
  }

  factory RedactionStatus.couldNotOpenImage([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotOpenImage,
      _couldNotFallback('Could not open image', detail),
      detail: detail,
    );
  }

  const RedactionStatus.couldNotDecodeImage()
    : this._(
        RedactionStatusKind.couldNotDecodeImage,
        'Could not decode this image',
      );

  factory RedactionStatus.couldNotExportImage([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotExportImage,
      _couldNotFallback('Could not export image', detail),
      detail: detail,
    );
  }

  factory RedactionStatus.couldNotExportPdf([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotExportPdf,
      _couldNotFallback('Could not export PDF', detail),
      detail: detail,
    );
  }

  factory RedactionStatus.couldNotChooseMetadataInput([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotChooseMetadataInput,
      _couldNotFallback('Could not choose metadata input', detail),
      detail: detail,
    );
  }

  factory RedactionStatus.couldNotAddMetadataFiles([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotAddMetadataFiles,
      _couldNotFallback('Could not add metadata files', detail),
      detail: detail,
    );
  }

  factory RedactionStatus.couldNotAddPhotos([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotAddPhotos,
      _couldNotFallback('Could not add photos', detail),
      detail: detail,
    );
  }

  factory RedactionStatus.couldNotChooseOutputFolder([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotChooseOutputFolder,
      _couldNotFallback('Could not choose output folder', detail),
      detail: detail,
    );
  }

  factory RedactionStatus.couldNotOpenOutputFolder([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotOpenOutputFolder,
      _couldNotFallback('Could not open output folder', detail),
      detail: detail,
    );
  }

  factory RedactionStatus.couldNotCleanMetadata([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotCleanMetadata,
      _couldNotFallback('Could not clean metadata', detail),
      detail: detail,
      failedCount: 1,
    );
  }

  factory RedactionStatus.couldNotCreateOutputFolder({
    required String fallbackMessage,
    String? path,
    bool automaticOutputFailure = false,
  }) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotCreateOutputFolder,
      fallbackMessage,
      path: path,
      automaticOutputFailure: automaticOutputFailure,
      failedCount: 1,
    );
  }

  factory RedactionStatus.couldNotRenderPdfPage([String? detail]) {
    return RedactionStatus._(
      RedactionStatusKind.couldNotRenderPdfPage,
      _couldNotFallback('Could not render PDF page', detail),
      detail: detail,
    );
  }

  factory RedactionStatus.externalMessage(String message) {
    return RedactionStatus._(
      RedactionStatusKind.externalMessage,
      message,
      detail: message,
    );
  }

  final RedactionStatusKind kind;
  final String fallbackMessage;
  final String? formatLabel;
  final String? label;
  final String? detail;
  final String? destinationName;
  final String? path;
  final int? width;
  final int? height;
  final int? count;
  final int? pageNumber;
  final int? pageCount;
  final int? current;
  final int? total;
  final int? savedCount;
  final int? failedCount;
  final int? ignoredCount;
  final MetadataInputSummary? metadataInputSummary;
  final bool automaticOutputFailure;

  bool get isPhotoRelated =>
      kind == RedactionStatusKind.openingPhotoLibrary ||
      kind == RedactionStatusKind.choosingImagesFromPhotos ||
      kind == RedactionStatusKind.addingPhotos ||
      kind == RedactionStatusKind.noPhotosSelected ||
      kind == RedactionStatusKind.startingMetadataCleanToPhotos ||
      kind == RedactionStatusKind.savingCleanImageToPhotos ||
      kind == RedactionStatusKind.savedCleanImageToPhotos ||
      kind == RedactionStatusKind.savingMetadataItemToPhotos;

  bool get isPhotosOutputRelated =>
      kind == RedactionStatusKind.startingMetadataCleanToPhotos ||
      kind == RedactionStatusKind.savingCleanImageToPhotos ||
      kind == RedactionStatusKind.savedCleanImageToPhotos ||
      kind == RedactionStatusKind.savingMetadataItemToPhotos;

  @override
  String toString() => fallbackMessage;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RedactionStatus &&
            kind == other.kind &&
            fallbackMessage == other.fallbackMessage &&
            formatLabel == other.formatLabel &&
            label == other.label &&
            detail == other.detail &&
            destinationName == other.destinationName &&
            path == other.path &&
            width == other.width &&
            height == other.height &&
            count == other.count &&
            pageNumber == other.pageNumber &&
            pageCount == other.pageCount &&
            current == other.current &&
            total == other.total &&
            savedCount == other.savedCount &&
            failedCount == other.failedCount &&
            ignoredCount == other.ignoredCount &&
            metadataInputSummary == other.metadataInputSummary &&
            automaticOutputFailure == other.automaticOutputFailure;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    kind,
    fallbackMessage,
    formatLabel,
    label,
    detail,
    destinationName,
    path,
    width,
    height,
    count,
    pageNumber,
    pageCount,
    current,
    total,
    savedCount,
    failedCount,
    ignoredCount,
    metadataInputSummary,
    automaticOutputFailure,
  ]);
}

String _couldNotFallback(String base, String? detail) {
  if (detail == null || detail.trim().isEmpty) return base;
  return '$base: ${detail.trim()}';
}
