// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Redact Kit';

  @override
  String get ready => 'Ready';

  @override
  String get fileDialogOpen => 'Open';

  @override
  String get fileDialogChoose => 'Choose';

  @override
  String get fileDialogChooseFiles => 'Choose Files';

  @override
  String get fileDialogChooseFolder => 'Choose Folder';

  @override
  String get fileDialogSave => 'Save';

  @override
  String get shareCleanImageTitle => 'Share clean image';

  @override
  String get shareCleanPdfTitle => 'Share clean PDF';

  @override
  String get openFoldersUnsupportedMessage =>
      'Opening output folders is only available on macOS.';

  @override
  String workingStatus(Object status) {
    return 'Working: $status';
  }

  @override
  String get image => 'Image';

  @override
  String get pdf => 'PDF';

  @override
  String get metadata => 'Metadata';

  @override
  String get imageDetails => 'Image details';

  @override
  String get pdfDetails => 'PDF details';

  @override
  String get metadataDetails => 'Metadata details';

  @override
  String get settings => 'Settings';

  @override
  String get files => 'Files';

  @override
  String get photos => 'Photos';

  @override
  String get undo => 'Undo';

  @override
  String get clear => 'Clear';

  @override
  String get crop => 'Crop';

  @override
  String get cancelCrop => 'Cancel';

  @override
  String get applyCrop => 'Apply';

  @override
  String get export => 'Export';

  @override
  String get save => 'Save';

  @override
  String get share => 'Share';

  @override
  String get saveToFiles => 'Save to Files';

  @override
  String get saveToPhotos => 'Save to Photos';

  @override
  String get input => 'Input';

  @override
  String get output => 'Output';

  @override
  String get exportFormat => 'Export Format';

  @override
  String get chooseImage => 'Choose an image';

  @override
  String get choosePdf => 'Choose a PDF';

  @override
  String get chooseFilesOrFolder => 'Choose Files or Folder';

  @override
  String get filesAndFoldersCanIncludeImagesOrPdfs =>
      'Files and folders can include images or PDFs.';

  @override
  String get choosePhotos => 'Choose Photos';

  @override
  String get chooseImagesFromPhotos => 'Choose images from Photos.';

  @override
  String get removeFolderBeforeAddingPhotos =>
      'Remove the folder before adding photos.';

  @override
  String get noInput => 'No input';

  @override
  String get noInputSelected => 'No input selected';

  @override
  String get chooseFilesPhotosOrFolder =>
      'Choose files, photos, or a folder containing images and PDFs.';

  @override
  String get metadataOnly => 'Metadata Only';

  @override
  String get metadataOnlySubtitle =>
      'Clean image or PDF metadata without drawing redaction boxes.';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get chooseInputPreviewOutput => 'Choose input to preview output';

  @override
  String get outputAppCleanedFolder => 'Output: app Cleaned folder';

  @override
  String get chooseInputShowControls =>
      'Choose input to show matching export controls.';

  @override
  String get keepFilenames => 'Keep filenames';

  @override
  String get keepFilename => 'Keep filename';

  @override
  String get openFolder => 'Open Folder';

  @override
  String get chooseFolder => 'Choose Folder';

  @override
  String get fullOutput => 'Full Output';

  @override
  String get folderPath => 'Folder Path';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get outputPathCopied => 'Output path copied.';

  @override
  String get lastResult => 'Last result';

  @override
  String get lastResultNeedsReview => 'Last result: needs review';

  @override
  String get lastResultFailed => 'Last result: failed';

  @override
  String get lastResultSavedMetadataPdf => 'Saved metadata-clean PDF';

  @override
  String get cleaned => 'Cleaned';

  @override
  String get ignored => 'Ignored';

  @override
  String get failed => 'Failed';

  @override
  String get tool => 'Tool';

  @override
  String get black => 'Black';

  @override
  String get white => 'White';

  @override
  String get pixels => 'Pixels';

  @override
  String get none => 'None';

  @override
  String get redactions => 'Redactions';

  @override
  String get cover => 'Cover';

  @override
  String get format => 'Format';

  @override
  String get pages => 'Pages';

  @override
  String get page => 'Page';

  @override
  String get currentPage => 'Current page';

  @override
  String get pageRedactions => 'Page redactions';

  @override
  String get totalRedactions => 'Total redactions';

  @override
  String get prev => 'Prev';

  @override
  String get next => 'Next';

  @override
  String get pagePlaceholder => 'Page';

  @override
  String get saveRedactedPdf => 'Save Redacted PDF';

  @override
  String get pdfExport => 'PDF Export';

  @override
  String get close => 'Close';

  @override
  String get details => 'Details';

  @override
  String get imagePrivacy => 'Image Privacy';

  @override
  String get pdfPrivacy => 'PDF Privacy';

  @override
  String get metadataOnlyInfo => 'Metadata Only';

  @override
  String get pixelLevelRedaction => 'Pixel-level redaction';

  @override
  String get pixelLevelRedactionBody =>
      'Redaction boxes are burned into exported pixels. There is no editable layer or hidden content under the covered area.';

  @override
  String get metadataRemoved => 'Metadata removed';

  @override
  String get imageMetadataRemovedBody =>
      'Exports remove EXIF, GPS, camera details, thumbnails, XMP/IPTC, comments, and other hidden image metadata.';

  @override
  String get outputFormatPoint => 'Output format';

  @override
  String get imageOutputFormatBody =>
      'PNG is lossless. JPEG is smaller and may soften edges. Both are written as fresh files without original metadata.';

  @override
  String get hiddenPdfDataRemoved => 'Hidden PDF data is removed';

  @override
  String get hiddenPdfDataRemovedBody =>
      'The export drops original text layers, annotations, forms, links, attachments, OCR text, and document metadata.';

  @override
  String get pdfMetadataRemovedBody =>
      'The clean PDF is written without the original title, author, creator, producer, dates, keywords, trailer ID, or XMP metadata.';

  @override
  String get flattenRedactedPages => 'Flatten redacted pages';

  @override
  String get flattenRedactedPagesBody =>
      'Each page is rendered as an image. Redaction boxes are burned in, then a new PDF is built at the original page size.';

  @override
  String get pdfOutputBody =>
      'The exported PDF keeps the original page size and uses the selected PDF quality setting.';

  @override
  String get tradeoff => 'Tradeoff';

  @override
  String get pdfTradeoffBody =>
      'Flattened PDFs are safer to verify, but text is no longer selectable or searchable.';

  @override
  String get cleanWithoutRedaction => 'Clean without redaction';

  @override
  String get cleanWithoutRedactionBody =>
      'Pick images, PDFs, Photos, or one folder. This mode removes hidden metadata without drawing boxes.';

  @override
  String get metadataOnlyRemovedBody =>
      'Images remove EXIF, GPS, camera details, thumbnails, XMP/IPTC, and comments. PDFs are rebuilt without original document metadata or hidden structure.';

  @override
  String get metadataOnlyOutputBody =>
      'Save to the app Cleaned folder, choose another folder, or save image-only results to Photos.';

  @override
  String get note => 'Note';

  @override
  String get metadataOnlyNoteBody =>
      'Metadata-only does not hide visible text or pixels. Use Image or PDF mode when private content is visible on the page.';

  @override
  String get metadataExportDescriptionNoInput =>
      'Pick files or a folder first. The export controls will match the selected input types.';

  @override
  String get metadataExportDescriptionMixed =>
      'Images use the image format and quality settings. PDFs are flattened with the PDF quality setting.';

  @override
  String get metadataExportDescriptionImages =>
      'Images use the selected PNG/JPEG format and image quality.';

  @override
  String get metadataExportDescriptionPdfs =>
      'PDFs are flattened with the selected PDF quality.';

  @override
  String get metadataExportDescriptionEmpty => 'No supported files selected.';

  @override
  String get folderSelected => 'Folder Selected';

  @override
  String get filesOrFolder => 'Files or Folder';

  @override
  String get metadataChooserFolderDisabled =>
      'Remove the folder to choose files or another folder.';

  @override
  String get metadataChooserAddMore => 'Add more images or PDFs to this list.';

  @override
  String get imageQuality => 'Image quality';

  @override
  String get pdfQuality => 'PDF quality';

  @override
  String get originalLossless => 'Original lossless';

  @override
  String get pngQualityDescription =>
      'PNG output keeps visible pixels lossless and strips metadata.';

  @override
  String get original => 'Original';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get jpegLowDescription => 'Smallest file, more visible loss.';

  @override
  String get jpegMediumDescription => 'Balanced size and image quality.';

  @override
  String get jpegHighDescription => 'Larger file, cleaner image.';

  @override
  String get pdfLowDescription => 'Smallest PDFs, softer page images.';

  @override
  String get pdfMediumDescription => 'Balanced readability and file size.';

  @override
  String get pdfHighDescription => 'Sharper pages, larger flattened PDFs.';

  @override
  String get pngLosslessExportNote =>
      'PNG is lossless. The exported file is rebuilt from visible pixels.';

  @override
  String get jpegLossyExportNote =>
      'JPEG is lossy. Lower quality makes smaller files.';

  @override
  String get pdfFlattenExportNote =>
      'PDF exports are flattened into image pages. Redacted export removes original PDF metadata and hidden document structure.';

  @override
  String get cleanImageExported => 'Clean image exported';

  @override
  String get redactionsBurnedMetadataRemoved =>
      'Redactions are burned in and metadata is removed.';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String get cleanImageReadyInPhotos =>
      'The clean image is ready in your photo library.';

  @override
  String get readyToShare => 'Ready to share';

  @override
  String get cleanCopyPreparedForSharing =>
      'A clean copy was prepared for sharing.';

  @override
  String get pdfCleaned => 'PDF cleaned';

  @override
  String get flattenedPdfSavedWithoutOriginalMetadata =>
      'A flattened PDF was saved without original metadata.';

  @override
  String get cleanImageSavedWithoutMetadata =>
      'A clean image copy was saved without private metadata.';

  @override
  String get cleanPdfExported => 'Clean PDF exported';

  @override
  String get pagesFlattenedPdfMetadataRemoved =>
      'Pages were flattened and PDF metadata was removed.';

  @override
  String get metadataCleaned => 'Metadata cleaned';

  @override
  String get cleanCopiesSavedToOutputFolder =>
      'Clean copies were saved to the output folder.';

  @override
  String get metadataCleanedWithNotes => 'Metadata cleaned with notes';

  @override
  String get someFilesNeedAttention =>
      'Some files need attention. Check the status text for details.';

  @override
  String get couldNotFinish => 'Could not finish';

  @override
  String redactionCountReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count redactions ready',
      one: '1 redaction ready',
    );
    return '$_temp0';
  }

  @override
  String redactionCountShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count redactions',
      one: '1 redaction',
    );
    return '$_temp0';
  }

  @override
  String onPageCount(int count) {
    return '$count on page';
  }

  @override
  String get inputSelected => 'Input selected';

  @override
  String get coverOpaque => '100% opaque';

  @override
  String metadataSummaryFolder(Object name) {
    return 'Folder: $name';
  }

  @override
  String metadataSummaryImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return '$_temp0';
  }

  @override
  String metadataSummaryPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String metadataSummaryPdfs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PDFs',
      one: '1 PDF',
    );
    return '$_temp0';
  }

  @override
  String metadataSummaryFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get metadataDetailPhotoLibrary => 'Photo library';

  @override
  String get metadataDetailImage => 'Image';

  @override
  String get metadataDetailPdf => 'PDF';

  @override
  String metadataDetailImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return '$_temp0';
  }

  @override
  String metadataDetailPdfs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PDFs',
      one: '1 PDF',
    );
    return '$_temp0';
  }

  @override
  String metadataDetailIgnored(int count) {
    return '$count ignored';
  }

  @override
  String get metadataDetailSeparator => ', ';

  @override
  String get statusOpeningImage => 'Opening image';

  @override
  String get statusOpeningPhotoLibrary => 'Opening photo library';

  @override
  String get statusOpeningPdf => 'Opening PDF';

  @override
  String statusLoadedImage(int width, int height) {
    return 'Loaded $width x ${height}px';
  }

  @override
  String get statusAdjustingCrop => 'Adjust crop';

  @override
  String get statusCroppingImage => 'Cropping image';

  @override
  String statusImageCropped(int width, int height) {
    return 'Cropped to $width x ${height}px';
  }

  @override
  String get statusCropCanceled => 'Crop canceled';

  @override
  String statusPdfPage(int pageNumber, int pageCount) {
    return 'PDF page $pageNumber of $pageCount';
  }

  @override
  String statusRenderingPdfPage(int pageNumber) {
    return 'Rendering PDF page $pageNumber';
  }

  @override
  String get statusFlatteningCleanPdf => 'Flattening clean PDF';

  @override
  String statusFlatteningPdfPage(int pageNumber, int pageCount) {
    return 'Flattening PDF page $pageNumber of $pageCount';
  }

  @override
  String get statusChoosingPdf => 'Choosing PDF';

  @override
  String get statusChoosingFilesOrFolder => 'Choosing files or folder';

  @override
  String get statusChoosingImageFile => 'Choosing image file';

  @override
  String get statusChoosingImageFiles => 'Choosing image files';

  @override
  String get statusChoosingPdfFile => 'Choosing PDF file';

  @override
  String get statusChoosingPdfFiles => 'Choosing PDF files';

  @override
  String get statusChoosingFolder => 'Choosing folder';

  @override
  String get statusChoosingImagesFromPhotos => 'Choosing images from Photos';

  @override
  String get statusChoosingOutputFolder => 'Choosing output folder';

  @override
  String get statusAddingFiles => 'Adding files';

  @override
  String get statusAddingPhotos => 'Adding photos';

  @override
  String statusSelectedMetadataInput(Object label) {
    return 'Selected $label';
  }

  @override
  String statusRemovedMetadataInput(Object label) {
    return 'Removed $label';
  }

  @override
  String get statusNoSupportedImagesOrPdfsSelected =>
      'No supported images or PDFs selected';

  @override
  String get statusNoSupportedImagesOrPdfsFoundInFolder =>
      'No supported images or PDFs found in that folder';

  @override
  String get statusNoPhotosSelected => 'No photos selected';

  @override
  String get statusRemoveFolderBeforeAddingPhotos =>
      'Remove the folder before adding photos';

  @override
  String get statusChooseMetadataInputFirst => 'Choose metadata input first';

  @override
  String get statusMetadataOutputFolderSet => 'Metadata output folder set';

  @override
  String get statusStartCleaningFirstToCreateOutputFolder =>
      'Start cleaning first to create the output folder';

  @override
  String get statusOpenedOutputFolder => 'Opened output folder';

  @override
  String statusEncodingCleanImage(Object format) {
    return 'Encoding clean $format';
  }

  @override
  String statusRemovingImageMetadata(Object format) {
    return 'Removing metadata from $format';
  }

  @override
  String statusPreparingCleanImageToShare(Object format) {
    return 'Preparing clean $format to share';
  }

  @override
  String statusSavingCleanImageToPhotos(Object format) {
    return 'Saving clean $format to Photos';
  }

  @override
  String statusExportedCleanImage(Object format) {
    return 'Exported clean $format';
  }

  @override
  String statusExportedCleanImageWithRedactions(Object format, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count redactions',
      one: '1 redaction',
    );
    return 'Exported clean $format with $_temp0';
  }

  @override
  String statusSavedCleanImageToPhotos(Object format) {
    return 'Saved clean $format to Photos';
  }

  @override
  String statusSharedCleanImage(Object format) {
    return 'Shared clean $format';
  }

  @override
  String statusSavedMetadataCleanImage(Object format) {
    return 'Saved metadata-clean $format';
  }

  @override
  String get statusCleaningPdfMetadata => 'Cleaning PDF metadata';

  @override
  String get statusSavedMetadataCleanPdf => 'Saved metadata-clean PDF';

  @override
  String get statusExportedCleanPdf => 'Exported clean PDF';

  @override
  String statusExportedCleanPdfWithRedactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count redactions',
      one: '1 redaction',
    );
    return 'Exported clean PDF with $_temp0';
  }

  @override
  String get statusExportCanceled => 'Export canceled';

  @override
  String get statusMetadataRemovalCanceled => 'Metadata removal canceled';

  @override
  String get statusPdfExportCanceled => 'PDF export canceled';

  @override
  String get statusPdfCleanCanceled => 'PDF clean canceled';

  @override
  String get statusShareCanceled => 'Share canceled';

  @override
  String get statusSaveCanceled => 'Save canceled';

  @override
  String get statusStartingMetadataClean => 'Starting metadata clean';

  @override
  String get statusPreparingOutputFolder => 'Preparing output folder';

  @override
  String get statusStartingMetadataCleanToPhotos =>
      'Starting metadata clean to Photos';

  @override
  String get statusPhotosOutputImagesOnly =>
      'Photos output is available for image files only';

  @override
  String statusCleaningMetadataItem(Object label, int current, int total) {
    return 'Cleaning $label ($current/$total)';
  }

  @override
  String statusCleaningMetadataPdfPage(
    Object label,
    int pageNumber,
    int pageCount,
    int current,
    int total,
  ) {
    return 'Cleaning $label page $pageNumber of $pageCount ($current/$total)';
  }

  @override
  String statusSavingMetadataItemToPhotos(
    Object label,
    int current,
    int total,
  ) {
    return 'Saving $label to Photos ($current/$total)';
  }

  @override
  String statusMetadataBatchNoSaved(Object details) {
    return 'Could not clean selected files$details';
  }

  @override
  String statusMetadataBatchCompleted(
    int savedCount,
    Object destinationName,
    Object details,
  ) {
    return 'Cleaned $savedCount files to $destinationName$details';
  }

  @override
  String statusMetadataBatchIgnoredDetail(int count) {
    return '$count ignored';
  }

  @override
  String statusMetadataBatchFailedDetail(int count) {
    return '$count failed';
  }

  @override
  String statusMetadataBatchFailedWithReasonDetail(int count, Object reason) {
    return '$count failed: $reason';
  }

  @override
  String statusMetadataBatchDetailsWrapper(Object details) {
    return ' ($details)';
  }

  @override
  String get statusMetadataBatchDetailSeparator => ', ';

  @override
  String get statusRedactionsCleared => 'Redactions cleared';

  @override
  String get statusPdfPageRedactionsCleared => 'PDF page redactions cleared';

  @override
  String statusPdfRedactionCountReady(int pageNumber, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count redactions ready',
      one: '1 redaction ready',
    );
    return 'PDF page $pageNumber: $_temp0';
  }

  @override
  String get statusCouldNotOpenPdf => 'Could not open PDF';

  @override
  String get statusCouldNotOpenImage => 'Could not open image';

  @override
  String get statusCouldNotDecodeImage => 'Could not decode this image';

  @override
  String get statusCouldNotExportImage => 'Could not export image';

  @override
  String get statusCouldNotExportPdf => 'Could not export PDF';

  @override
  String get statusCouldNotChooseMetadataInput =>
      'Could not choose metadata input';

  @override
  String get statusCouldNotAddMetadataFiles => 'Could not add metadata files';

  @override
  String get statusCouldNotAddPhotos => 'Could not add photos';

  @override
  String get statusCouldNotChooseOutputFolder =>
      'Could not choose output folder';

  @override
  String get statusCouldNotOpenOutputFolder => 'Could not open output folder';

  @override
  String get statusCouldNotCleanMetadata => 'Could not clean metadata';

  @override
  String get statusCouldNotCreateOutputFolder =>
      'Could not create output folder';

  @override
  String statusCouldNotCreateOutputFolderAutomatic(Object path) {
    return 'Could not create output folder: macOS sandbox did not allow the planned output location. Use Output > Choose Folder and select or create $path.';
  }

  @override
  String statusCouldNotCreateOutputFolderPath(Object path) {
    return 'Could not create output folder: $path. Choose another output folder.';
  }

  @override
  String get statusCouldNotRenderPdfPage => 'Could not render PDF page';

  @override
  String statusFailureWithDetail(Object title, Object detail) {
    return '$title: $detail';
  }
}
