import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Redact Kit'**
  String get appTitle;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @fileDialogOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get fileDialogOpen;

  /// No description provided for @fileDialogChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get fileDialogChoose;

  /// No description provided for @fileDialogChooseFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose Files'**
  String get fileDialogChooseFiles;

  /// No description provided for @fileDialogChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get fileDialogChooseFolder;

  /// No description provided for @fileDialogSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get fileDialogSave;

  /// No description provided for @shareCleanImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Share clean image'**
  String get shareCleanImageTitle;

  /// No description provided for @shareCleanPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Share clean PDF'**
  String get shareCleanPdfTitle;

  /// No description provided for @openFoldersUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Opening output folders is only available on macOS.'**
  String get openFoldersUnsupportedMessage;

  /// No description provided for @workingStatus.
  ///
  /// In en, this message translates to:
  /// **'Working: {status}'**
  String workingStatus(Object status);

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadata;

  /// No description provided for @imageDetails.
  ///
  /// In en, this message translates to:
  /// **'Image details'**
  String get imageDetails;

  /// No description provided for @pdfDetails.
  ///
  /// In en, this message translates to:
  /// **'PDF details'**
  String get pdfDetails;

  /// No description provided for @metadataDetails.
  ///
  /// In en, this message translates to:
  /// **'Metadata details'**
  String get metadataDetails;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @cancelCrop.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelCrop;

  /// No description provided for @applyCrop.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyCrop;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @saveToFiles.
  ///
  /// In en, this message translates to:
  /// **'Save to Files'**
  String get saveToFiles;

  /// No description provided for @saveToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Save to Photos'**
  String get saveToPhotos;

  /// No description provided for @input.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get input;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get output;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose an image'**
  String get chooseImage;

  /// No description provided for @choosePdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get choosePdf;

  /// No description provided for @chooseFilesOrFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Files or Folder'**
  String get chooseFilesOrFolder;

  /// No description provided for @filesAndFoldersCanIncludeImagesOrPdfs.
  ///
  /// In en, this message translates to:
  /// **'Files and folders can include images or PDFs.'**
  String get filesAndFoldersCanIncludeImagesOrPdfs;

  /// No description provided for @choosePhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose Photos'**
  String get choosePhotos;

  /// No description provided for @chooseImagesFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose images from Photos.'**
  String get chooseImagesFromPhotos;

  /// No description provided for @removeFolderBeforeAddingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Remove the folder before adding photos.'**
  String get removeFolderBeforeAddingPhotos;

  /// No description provided for @noInput.
  ///
  /// In en, this message translates to:
  /// **'No input'**
  String get noInput;

  /// No description provided for @noInputSelected.
  ///
  /// In en, this message translates to:
  /// **'No input selected'**
  String get noInputSelected;

  /// No description provided for @chooseFilesPhotosOrFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose files, photos, or a folder containing images and PDFs.'**
  String get chooseFilesPhotosOrFolder;

  /// No description provided for @metadataOnly.
  ///
  /// In en, this message translates to:
  /// **'Metadata Only'**
  String get metadataOnly;

  /// No description provided for @metadataOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clean image or PDF metadata without drawing redaction boxes.'**
  String get metadataOnlySubtitle;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @chooseInputPreviewOutput.
  ///
  /// In en, this message translates to:
  /// **'Choose input to preview output'**
  String get chooseInputPreviewOutput;

  /// No description provided for @outputAppCleanedFolder.
  ///
  /// In en, this message translates to:
  /// **'Output: app Cleaned folder'**
  String get outputAppCleanedFolder;

  /// No description provided for @chooseInputShowControls.
  ///
  /// In en, this message translates to:
  /// **'Choose input to show matching export controls.'**
  String get chooseInputShowControls;

  /// No description provided for @keepFilenames.
  ///
  /// In en, this message translates to:
  /// **'Keep filenames'**
  String get keepFilenames;

  /// No description provided for @keepFilename.
  ///
  /// In en, this message translates to:
  /// **'Keep filename'**
  String get keepFilename;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @chooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get chooseFolder;

  /// No description provided for @fullOutput.
  ///
  /// In en, this message translates to:
  /// **'Full Output'**
  String get fullOutput;

  /// No description provided for @folderPath.
  ///
  /// In en, this message translates to:
  /// **'Folder Path'**
  String get folderPath;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @outputPathCopied.
  ///
  /// In en, this message translates to:
  /// **'Output path copied.'**
  String get outputPathCopied;

  /// No description provided for @lastResult.
  ///
  /// In en, this message translates to:
  /// **'Last result'**
  String get lastResult;

  /// No description provided for @lastResultNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Last result: needs review'**
  String get lastResultNeedsReview;

  /// No description provided for @lastResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Last result: failed'**
  String get lastResultFailed;

  /// No description provided for @lastResultSavedMetadataPdf.
  ///
  /// In en, this message translates to:
  /// **'Saved metadata-clean PDF'**
  String get lastResultSavedMetadataPdf;

  /// No description provided for @cleaned.
  ///
  /// In en, this message translates to:
  /// **'Cleaned'**
  String get cleaned;

  /// No description provided for @ignored.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get ignored;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @tool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get tool;

  /// No description provided for @black.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get black;

  /// No description provided for @white.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get white;

  /// No description provided for @pixels.
  ///
  /// In en, this message translates to:
  /// **'Pixels'**
  String get pixels;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @redactions.
  ///
  /// In en, this message translates to:
  /// **'Redactions'**
  String get redactions;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @currentPage.
  ///
  /// In en, this message translates to:
  /// **'Current page'**
  String get currentPage;

  /// No description provided for @pageRedactions.
  ///
  /// In en, this message translates to:
  /// **'Page redactions'**
  String get pageRedactions;

  /// No description provided for @totalRedactions.
  ///
  /// In en, this message translates to:
  /// **'Total redactions'**
  String get totalRedactions;

  /// No description provided for @prev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get prev;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @pagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pagePlaceholder;

  /// No description provided for @saveRedactedPdf.
  ///
  /// In en, this message translates to:
  /// **'Save Redacted PDF'**
  String get saveRedactedPdf;

  /// No description provided for @pdfExport.
  ///
  /// In en, this message translates to:
  /// **'PDF Export'**
  String get pdfExport;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @imagePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Image Privacy'**
  String get imagePrivacy;

  /// No description provided for @pdfPrivacy.
  ///
  /// In en, this message translates to:
  /// **'PDF Privacy'**
  String get pdfPrivacy;

  /// No description provided for @metadataOnlyInfo.
  ///
  /// In en, this message translates to:
  /// **'Metadata Only'**
  String get metadataOnlyInfo;

  /// No description provided for @pixelLevelRedaction.
  ///
  /// In en, this message translates to:
  /// **'Pixel-level redaction'**
  String get pixelLevelRedaction;

  /// No description provided for @pixelLevelRedactionBody.
  ///
  /// In en, this message translates to:
  /// **'Redaction boxes are burned into exported pixels. There is no editable layer or hidden content under the covered area.'**
  String get pixelLevelRedactionBody;

  /// No description provided for @metadataRemoved.
  ///
  /// In en, this message translates to:
  /// **'Metadata removed'**
  String get metadataRemoved;

  /// No description provided for @imageMetadataRemovedBody.
  ///
  /// In en, this message translates to:
  /// **'Exports remove EXIF, GPS, camera details, thumbnails, XMP/IPTC, comments, and other hidden image metadata.'**
  String get imageMetadataRemovedBody;

  /// No description provided for @outputFormatPoint.
  ///
  /// In en, this message translates to:
  /// **'Output format'**
  String get outputFormatPoint;

  /// No description provided for @imageOutputFormatBody.
  ///
  /// In en, this message translates to:
  /// **'PNG is lossless. JPEG is smaller and may soften edges. Both are written as fresh files without original metadata.'**
  String get imageOutputFormatBody;

  /// No description provided for @hiddenPdfDataRemoved.
  ///
  /// In en, this message translates to:
  /// **'Hidden PDF data is removed'**
  String get hiddenPdfDataRemoved;

  /// No description provided for @hiddenPdfDataRemovedBody.
  ///
  /// In en, this message translates to:
  /// **'The export drops original text layers, annotations, forms, links, attachments, OCR text, and document metadata.'**
  String get hiddenPdfDataRemovedBody;

  /// No description provided for @pdfMetadataRemovedBody.
  ///
  /// In en, this message translates to:
  /// **'The clean PDF is written without the original title, author, creator, producer, dates, keywords, trailer ID, or XMP metadata.'**
  String get pdfMetadataRemovedBody;

  /// No description provided for @flattenRedactedPages.
  ///
  /// In en, this message translates to:
  /// **'Flatten redacted pages'**
  String get flattenRedactedPages;

  /// No description provided for @flattenRedactedPagesBody.
  ///
  /// In en, this message translates to:
  /// **'Each page is rendered as an image. Redaction boxes are burned in, then a new PDF is built at the original page size.'**
  String get flattenRedactedPagesBody;

  /// No description provided for @pdfOutputBody.
  ///
  /// In en, this message translates to:
  /// **'The exported PDF keeps the original page size and uses the selected PDF quality setting.'**
  String get pdfOutputBody;

  /// No description provided for @tradeoff.
  ///
  /// In en, this message translates to:
  /// **'Tradeoff'**
  String get tradeoff;

  /// No description provided for @pdfTradeoffBody.
  ///
  /// In en, this message translates to:
  /// **'Flattened PDFs are safer to verify, but text is no longer selectable or searchable.'**
  String get pdfTradeoffBody;

  /// No description provided for @cleanWithoutRedaction.
  ///
  /// In en, this message translates to:
  /// **'Clean without redaction'**
  String get cleanWithoutRedaction;

  /// No description provided for @cleanWithoutRedactionBody.
  ///
  /// In en, this message translates to:
  /// **'Pick images, PDFs, Photos, or one folder. This mode removes hidden metadata without drawing boxes.'**
  String get cleanWithoutRedactionBody;

  /// No description provided for @metadataOnlyRemovedBody.
  ///
  /// In en, this message translates to:
  /// **'Images remove EXIF, GPS, camera details, thumbnails, XMP/IPTC, and comments. PDFs are rebuilt without original document metadata or hidden structure.'**
  String get metadataOnlyRemovedBody;

  /// No description provided for @metadataOnlyOutputBody.
  ///
  /// In en, this message translates to:
  /// **'Save to the app Cleaned folder, choose another folder, or save image-only results to Photos.'**
  String get metadataOnlyOutputBody;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @metadataOnlyNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Metadata-only does not hide visible text or pixels. Use Image or PDF mode when private content is visible on the page.'**
  String get metadataOnlyNoteBody;

  /// No description provided for @metadataExportDescriptionNoInput.
  ///
  /// In en, this message translates to:
  /// **'Pick files or a folder first. The export controls will match the selected input types.'**
  String get metadataExportDescriptionNoInput;

  /// No description provided for @metadataExportDescriptionMixed.
  ///
  /// In en, this message translates to:
  /// **'Images use the image format and quality settings. PDFs are flattened with the PDF quality setting.'**
  String get metadataExportDescriptionMixed;

  /// No description provided for @metadataExportDescriptionImages.
  ///
  /// In en, this message translates to:
  /// **'Images use the selected PNG/JPEG format and image quality.'**
  String get metadataExportDescriptionImages;

  /// No description provided for @metadataExportDescriptionPdfs.
  ///
  /// In en, this message translates to:
  /// **'PDFs are flattened with the selected PDF quality.'**
  String get metadataExportDescriptionPdfs;

  /// No description provided for @metadataExportDescriptionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No supported files selected.'**
  String get metadataExportDescriptionEmpty;

  /// No description provided for @folderSelected.
  ///
  /// In en, this message translates to:
  /// **'Folder Selected'**
  String get folderSelected;

  /// No description provided for @filesOrFolder.
  ///
  /// In en, this message translates to:
  /// **'Files or Folder'**
  String get filesOrFolder;

  /// No description provided for @metadataChooserFolderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Remove the folder to choose files or another folder.'**
  String get metadataChooserFolderDisabled;

  /// No description provided for @metadataChooserAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add more images or PDFs to this list.'**
  String get metadataChooserAddMore;

  /// No description provided for @imageQuality.
  ///
  /// In en, this message translates to:
  /// **'Image quality'**
  String get imageQuality;

  /// No description provided for @pdfQuality.
  ///
  /// In en, this message translates to:
  /// **'PDF quality'**
  String get pdfQuality;

  /// No description provided for @originalLossless.
  ///
  /// In en, this message translates to:
  /// **'Original lossless'**
  String get originalLossless;

  /// No description provided for @pngQualityDescription.
  ///
  /// In en, this message translates to:
  /// **'PNG output keeps visible pixels lossless and strips metadata.'**
  String get pngQualityDescription;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @jpegLowDescription.
  ///
  /// In en, this message translates to:
  /// **'Smallest file, more visible loss.'**
  String get jpegLowDescription;

  /// No description provided for @jpegMediumDescription.
  ///
  /// In en, this message translates to:
  /// **'Balanced size and image quality.'**
  String get jpegMediumDescription;

  /// No description provided for @jpegHighDescription.
  ///
  /// In en, this message translates to:
  /// **'Larger file, cleaner image.'**
  String get jpegHighDescription;

  /// No description provided for @pdfLowDescription.
  ///
  /// In en, this message translates to:
  /// **'Smallest PDFs, softer page images.'**
  String get pdfLowDescription;

  /// No description provided for @pdfMediumDescription.
  ///
  /// In en, this message translates to:
  /// **'Balanced readability and file size.'**
  String get pdfMediumDescription;

  /// No description provided for @pdfHighDescription.
  ///
  /// In en, this message translates to:
  /// **'Sharper pages, larger flattened PDFs.'**
  String get pdfHighDescription;

  /// No description provided for @pngLosslessExportNote.
  ///
  /// In en, this message translates to:
  /// **'PNG is lossless. The exported file is rebuilt from visible pixels.'**
  String get pngLosslessExportNote;

  /// No description provided for @jpegLossyExportNote.
  ///
  /// In en, this message translates to:
  /// **'JPEG is lossy. Lower quality makes smaller files.'**
  String get jpegLossyExportNote;

  /// No description provided for @pdfFlattenExportNote.
  ///
  /// In en, this message translates to:
  /// **'PDF exports are flattened into image pages. Redacted export removes original PDF metadata and hidden document structure.'**
  String get pdfFlattenExportNote;

  /// No description provided for @cleanImageExported.
  ///
  /// In en, this message translates to:
  /// **'Clean image exported'**
  String get cleanImageExported;

  /// No description provided for @redactionsBurnedMetadataRemoved.
  ///
  /// In en, this message translates to:
  /// **'Redactions are burned in and metadata is removed.'**
  String get redactionsBurnedMetadataRemoved;

  /// No description provided for @savedToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Saved to Photos'**
  String get savedToPhotos;

  /// No description provided for @cleanImageReadyInPhotos.
  ///
  /// In en, this message translates to:
  /// **'The clean image is ready in your photo library.'**
  String get cleanImageReadyInPhotos;

  /// No description provided for @readyToShare.
  ///
  /// In en, this message translates to:
  /// **'Ready to share'**
  String get readyToShare;

  /// No description provided for @cleanCopyPreparedForSharing.
  ///
  /// In en, this message translates to:
  /// **'A clean copy was prepared for sharing.'**
  String get cleanCopyPreparedForSharing;

  /// No description provided for @pdfCleaned.
  ///
  /// In en, this message translates to:
  /// **'PDF cleaned'**
  String get pdfCleaned;

  /// No description provided for @flattenedPdfSavedWithoutOriginalMetadata.
  ///
  /// In en, this message translates to:
  /// **'A flattened PDF was saved without original metadata.'**
  String get flattenedPdfSavedWithoutOriginalMetadata;

  /// No description provided for @cleanImageSavedWithoutMetadata.
  ///
  /// In en, this message translates to:
  /// **'A clean image copy was saved without private metadata.'**
  String get cleanImageSavedWithoutMetadata;

  /// No description provided for @cleanPdfExported.
  ///
  /// In en, this message translates to:
  /// **'Clean PDF exported'**
  String get cleanPdfExported;

  /// No description provided for @pagesFlattenedPdfMetadataRemoved.
  ///
  /// In en, this message translates to:
  /// **'Pages were flattened and PDF metadata was removed.'**
  String get pagesFlattenedPdfMetadataRemoved;

  /// No description provided for @metadataCleaned.
  ///
  /// In en, this message translates to:
  /// **'Metadata cleaned'**
  String get metadataCleaned;

  /// No description provided for @cleanCopiesSavedToOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Clean copies were saved to the output folder.'**
  String get cleanCopiesSavedToOutputFolder;

  /// No description provided for @metadataCleanedWithNotes.
  ///
  /// In en, this message translates to:
  /// **'Metadata cleaned with notes'**
  String get metadataCleanedWithNotes;

  /// No description provided for @someFilesNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'Some files need attention. Check the status text for details.'**
  String get someFilesNeedAttention;

  /// No description provided for @couldNotFinish.
  ///
  /// In en, this message translates to:
  /// **'Could not finish'**
  String get couldNotFinish;

  /// No description provided for @redactionCountReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 redaction ready} other{{count} redactions ready}}'**
  String redactionCountReady(int count);

  /// No description provided for @redactionCountShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 redaction} other{{count} redactions}}'**
  String redactionCountShort(int count);

  /// No description provided for @onPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} on page'**
  String onPageCount(int count);

  /// No description provided for @inputSelected.
  ///
  /// In en, this message translates to:
  /// **'Input selected'**
  String get inputSelected;

  /// No description provided for @coverOpaque.
  ///
  /// In en, this message translates to:
  /// **'100% opaque'**
  String get coverOpaque;

  /// No description provided for @metadataSummaryFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder: {name}'**
  String metadataSummaryFolder(Object name);

  /// No description provided for @metadataSummaryImages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 image} other{{count} images}}'**
  String metadataSummaryImages(int count);

  /// No description provided for @metadataSummaryPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String metadataSummaryPhotos(int count);

  /// No description provided for @metadataSummaryPdfs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 PDF} other{{count} PDFs}}'**
  String metadataSummaryPdfs(int count);

  /// No description provided for @metadataSummaryFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String metadataSummaryFiles(int count);

  /// No description provided for @metadataDetailPhotoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo library'**
  String get metadataDetailPhotoLibrary;

  /// No description provided for @metadataDetailImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get metadataDetailImage;

  /// No description provided for @metadataDetailPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get metadataDetailPdf;

  /// No description provided for @metadataDetailImages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 image} other{{count} images}}'**
  String metadataDetailImages(int count);

  /// No description provided for @metadataDetailPdfs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 PDF} other{{count} PDFs}}'**
  String metadataDetailPdfs(int count);

  /// No description provided for @metadataDetailIgnored.
  ///
  /// In en, this message translates to:
  /// **'{count} ignored'**
  String metadataDetailIgnored(int count);

  /// No description provided for @metadataDetailSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get metadataDetailSeparator;

  /// No description provided for @statusOpeningImage.
  ///
  /// In en, this message translates to:
  /// **'Opening image'**
  String get statusOpeningImage;

  /// No description provided for @statusOpeningPhotoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Opening photo library'**
  String get statusOpeningPhotoLibrary;

  /// No description provided for @statusOpeningPdf.
  ///
  /// In en, this message translates to:
  /// **'Opening PDF'**
  String get statusOpeningPdf;

  /// No description provided for @statusLoadedImage.
  ///
  /// In en, this message translates to:
  /// **'Loaded {width} x {height}px'**
  String statusLoadedImage(int width, int height);

  /// No description provided for @statusAdjustingCrop.
  ///
  /// In en, this message translates to:
  /// **'Adjust crop'**
  String get statusAdjustingCrop;

  /// No description provided for @statusCroppingImage.
  ///
  /// In en, this message translates to:
  /// **'Cropping image'**
  String get statusCroppingImage;

  /// No description provided for @statusImageCropped.
  ///
  /// In en, this message translates to:
  /// **'Cropped to {width} x {height}px'**
  String statusImageCropped(int width, int height);

  /// No description provided for @statusCropCanceled.
  ///
  /// In en, this message translates to:
  /// **'Crop canceled'**
  String get statusCropCanceled;

  /// No description provided for @statusPdfPage.
  ///
  /// In en, this message translates to:
  /// **'PDF page {pageNumber} of {pageCount}'**
  String statusPdfPage(int pageNumber, int pageCount);

  /// No description provided for @statusRenderingPdfPage.
  ///
  /// In en, this message translates to:
  /// **'Rendering PDF page {pageNumber}'**
  String statusRenderingPdfPage(int pageNumber);

  /// No description provided for @statusFlatteningCleanPdf.
  ///
  /// In en, this message translates to:
  /// **'Flattening clean PDF'**
  String get statusFlatteningCleanPdf;

  /// No description provided for @statusFlatteningPdfPage.
  ///
  /// In en, this message translates to:
  /// **'Flattening PDF page {pageNumber} of {pageCount}'**
  String statusFlatteningPdfPage(int pageNumber, int pageCount);

  /// No description provided for @statusChoosingPdf.
  ///
  /// In en, this message translates to:
  /// **'Choosing PDF'**
  String get statusChoosingPdf;

  /// No description provided for @statusChoosingFilesOrFolder.
  ///
  /// In en, this message translates to:
  /// **'Choosing files or folder'**
  String get statusChoosingFilesOrFolder;

  /// No description provided for @statusChoosingImageFile.
  ///
  /// In en, this message translates to:
  /// **'Choosing image file'**
  String get statusChoosingImageFile;

  /// No description provided for @statusChoosingImageFiles.
  ///
  /// In en, this message translates to:
  /// **'Choosing image files'**
  String get statusChoosingImageFiles;

  /// No description provided for @statusChoosingPdfFile.
  ///
  /// In en, this message translates to:
  /// **'Choosing PDF file'**
  String get statusChoosingPdfFile;

  /// No description provided for @statusChoosingPdfFiles.
  ///
  /// In en, this message translates to:
  /// **'Choosing PDF files'**
  String get statusChoosingPdfFiles;

  /// No description provided for @statusChoosingFolder.
  ///
  /// In en, this message translates to:
  /// **'Choosing folder'**
  String get statusChoosingFolder;

  /// No description provided for @statusChoosingImagesFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Choosing images from Photos'**
  String get statusChoosingImagesFromPhotos;

  /// No description provided for @statusChoosingOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Choosing output folder'**
  String get statusChoosingOutputFolder;

  /// No description provided for @statusAddingFiles.
  ///
  /// In en, this message translates to:
  /// **'Adding files'**
  String get statusAddingFiles;

  /// No description provided for @statusAddingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Adding photos'**
  String get statusAddingPhotos;

  /// No description provided for @statusSelectedMetadataInput.
  ///
  /// In en, this message translates to:
  /// **'Selected {label}'**
  String statusSelectedMetadataInput(Object label);

  /// No description provided for @statusRemovedMetadataInput.
  ///
  /// In en, this message translates to:
  /// **'Removed {label}'**
  String statusRemovedMetadataInput(Object label);

  /// No description provided for @statusNoSupportedImagesOrPdfsSelected.
  ///
  /// In en, this message translates to:
  /// **'No supported images or PDFs selected'**
  String get statusNoSupportedImagesOrPdfsSelected;

  /// No description provided for @statusNoSupportedImagesOrPdfsFoundInFolder.
  ///
  /// In en, this message translates to:
  /// **'No supported images or PDFs found in that folder'**
  String get statusNoSupportedImagesOrPdfsFoundInFolder;

  /// No description provided for @statusNoPhotosSelected.
  ///
  /// In en, this message translates to:
  /// **'No photos selected'**
  String get statusNoPhotosSelected;

  /// No description provided for @statusRemoveFolderBeforeAddingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Remove the folder before adding photos'**
  String get statusRemoveFolderBeforeAddingPhotos;

  /// No description provided for @statusChooseMetadataInputFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose metadata input first'**
  String get statusChooseMetadataInputFirst;

  /// No description provided for @statusMetadataOutputFolderSet.
  ///
  /// In en, this message translates to:
  /// **'Metadata output folder set'**
  String get statusMetadataOutputFolderSet;

  /// No description provided for @statusStartCleaningFirstToCreateOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Start cleaning first to create the output folder'**
  String get statusStartCleaningFirstToCreateOutputFolder;

  /// No description provided for @statusOpenedOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Opened output folder'**
  String get statusOpenedOutputFolder;

  /// No description provided for @statusEncodingCleanImage.
  ///
  /// In en, this message translates to:
  /// **'Encoding clean {format}'**
  String statusEncodingCleanImage(Object format);

  /// No description provided for @statusRemovingImageMetadata.
  ///
  /// In en, this message translates to:
  /// **'Removing metadata from {format}'**
  String statusRemovingImageMetadata(Object format);

  /// No description provided for @statusPreparingCleanImageToShare.
  ///
  /// In en, this message translates to:
  /// **'Preparing clean {format} to share'**
  String statusPreparingCleanImageToShare(Object format);

  /// No description provided for @statusSavingCleanImageToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Saving clean {format} to Photos'**
  String statusSavingCleanImageToPhotos(Object format);

  /// No description provided for @statusExportedCleanImage.
  ///
  /// In en, this message translates to:
  /// **'Exported clean {format}'**
  String statusExportedCleanImage(Object format);

  /// No description provided for @statusExportedCleanImageWithRedactions.
  ///
  /// In en, this message translates to:
  /// **'Exported clean {format} with {count, plural, =1{1 redaction} other{{count} redactions}}'**
  String statusExportedCleanImageWithRedactions(Object format, int count);

  /// No description provided for @statusSavedCleanImageToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Saved clean {format} to Photos'**
  String statusSavedCleanImageToPhotos(Object format);

  /// No description provided for @statusSharedCleanImage.
  ///
  /// In en, this message translates to:
  /// **'Shared clean {format}'**
  String statusSharedCleanImage(Object format);

  /// No description provided for @statusSavedMetadataCleanImage.
  ///
  /// In en, this message translates to:
  /// **'Saved metadata-clean {format}'**
  String statusSavedMetadataCleanImage(Object format);

  /// No description provided for @statusCleaningPdfMetadata.
  ///
  /// In en, this message translates to:
  /// **'Cleaning PDF metadata'**
  String get statusCleaningPdfMetadata;

  /// No description provided for @statusSavedMetadataCleanPdf.
  ///
  /// In en, this message translates to:
  /// **'Saved metadata-clean PDF'**
  String get statusSavedMetadataCleanPdf;

  /// No description provided for @statusExportedCleanPdf.
  ///
  /// In en, this message translates to:
  /// **'Exported clean PDF'**
  String get statusExportedCleanPdf;

  /// No description provided for @statusExportedCleanPdfWithRedactions.
  ///
  /// In en, this message translates to:
  /// **'Exported clean PDF with {count, plural, =1{1 redaction} other{{count} redactions}}'**
  String statusExportedCleanPdfWithRedactions(int count);

  /// No description provided for @statusExportCanceled.
  ///
  /// In en, this message translates to:
  /// **'Export canceled'**
  String get statusExportCanceled;

  /// No description provided for @statusMetadataRemovalCanceled.
  ///
  /// In en, this message translates to:
  /// **'Metadata removal canceled'**
  String get statusMetadataRemovalCanceled;

  /// No description provided for @statusPdfExportCanceled.
  ///
  /// In en, this message translates to:
  /// **'PDF export canceled'**
  String get statusPdfExportCanceled;

  /// No description provided for @statusPdfCleanCanceled.
  ///
  /// In en, this message translates to:
  /// **'PDF clean canceled'**
  String get statusPdfCleanCanceled;

  /// No description provided for @statusShareCanceled.
  ///
  /// In en, this message translates to:
  /// **'Share canceled'**
  String get statusShareCanceled;

  /// No description provided for @statusSaveCanceled.
  ///
  /// In en, this message translates to:
  /// **'Save canceled'**
  String get statusSaveCanceled;

  /// No description provided for @statusStartingMetadataClean.
  ///
  /// In en, this message translates to:
  /// **'Starting metadata clean'**
  String get statusStartingMetadataClean;

  /// No description provided for @statusPreparingOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Preparing output folder'**
  String get statusPreparingOutputFolder;

  /// No description provided for @statusStartingMetadataCleanToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Starting metadata clean to Photos'**
  String get statusStartingMetadataCleanToPhotos;

  /// No description provided for @statusPhotosOutputImagesOnly.
  ///
  /// In en, this message translates to:
  /// **'Photos output is available for image files only'**
  String get statusPhotosOutputImagesOnly;

  /// No description provided for @statusCleaningMetadataItem.
  ///
  /// In en, this message translates to:
  /// **'Cleaning {label} ({current}/{total})'**
  String statusCleaningMetadataItem(Object label, int current, int total);

  /// No description provided for @statusCleaningMetadataPdfPage.
  ///
  /// In en, this message translates to:
  /// **'Cleaning {label} page {pageNumber} of {pageCount} ({current}/{total})'**
  String statusCleaningMetadataPdfPage(
    Object label,
    int pageNumber,
    int pageCount,
    int current,
    int total,
  );

  /// No description provided for @statusSavingMetadataItemToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Saving {label} to Photos ({current}/{total})'**
  String statusSavingMetadataItemToPhotos(Object label, int current, int total);

  /// No description provided for @statusMetadataBatchNoSaved.
  ///
  /// In en, this message translates to:
  /// **'Could not clean selected files{details}'**
  String statusMetadataBatchNoSaved(Object details);

  /// No description provided for @statusMetadataBatchCompleted.
  ///
  /// In en, this message translates to:
  /// **'Cleaned {savedCount} files to {destinationName}{details}'**
  String statusMetadataBatchCompleted(
    int savedCount,
    Object destinationName,
    Object details,
  );

  /// No description provided for @statusMetadataBatchIgnoredDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} ignored'**
  String statusMetadataBatchIgnoredDetail(int count);

  /// No description provided for @statusMetadataBatchFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String statusMetadataBatchFailedDetail(int count);

  /// No description provided for @statusMetadataBatchFailedWithReasonDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} failed: {reason}'**
  String statusMetadataBatchFailedWithReasonDetail(int count, Object reason);

  /// No description provided for @statusMetadataBatchDetailsWrapper.
  ///
  /// In en, this message translates to:
  /// **' ({details})'**
  String statusMetadataBatchDetailsWrapper(Object details);

  /// No description provided for @statusMetadataBatchDetailSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get statusMetadataBatchDetailSeparator;

  /// No description provided for @statusRedactionsCleared.
  ///
  /// In en, this message translates to:
  /// **'Redactions cleared'**
  String get statusRedactionsCleared;

  /// No description provided for @statusPdfPageRedactionsCleared.
  ///
  /// In en, this message translates to:
  /// **'PDF page redactions cleared'**
  String get statusPdfPageRedactionsCleared;

  /// No description provided for @statusPdfRedactionCountReady.
  ///
  /// In en, this message translates to:
  /// **'PDF page {pageNumber}: {count, plural, =1{1 redaction ready} other{{count} redactions ready}}'**
  String statusPdfRedactionCountReady(int pageNumber, int count);

  /// No description provided for @statusCouldNotOpenPdf.
  ///
  /// In en, this message translates to:
  /// **'Could not open PDF'**
  String get statusCouldNotOpenPdf;

  /// No description provided for @statusCouldNotOpenImage.
  ///
  /// In en, this message translates to:
  /// **'Could not open image'**
  String get statusCouldNotOpenImage;

  /// No description provided for @statusCouldNotDecodeImage.
  ///
  /// In en, this message translates to:
  /// **'Could not decode this image'**
  String get statusCouldNotDecodeImage;

  /// No description provided for @statusCouldNotExportImage.
  ///
  /// In en, this message translates to:
  /// **'Could not export image'**
  String get statusCouldNotExportImage;

  /// No description provided for @statusCouldNotExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Could not export PDF'**
  String get statusCouldNotExportPdf;

  /// No description provided for @statusCouldNotChooseMetadataInput.
  ///
  /// In en, this message translates to:
  /// **'Could not choose metadata input'**
  String get statusCouldNotChooseMetadataInput;

  /// No description provided for @statusCouldNotAddMetadataFiles.
  ///
  /// In en, this message translates to:
  /// **'Could not add metadata files'**
  String get statusCouldNotAddMetadataFiles;

  /// No description provided for @statusCouldNotAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Could not add photos'**
  String get statusCouldNotAddPhotos;

  /// No description provided for @statusCouldNotChooseOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not choose output folder'**
  String get statusCouldNotChooseOutputFolder;

  /// No description provided for @statusCouldNotOpenOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not open output folder'**
  String get statusCouldNotOpenOutputFolder;

  /// No description provided for @statusCouldNotCleanMetadata.
  ///
  /// In en, this message translates to:
  /// **'Could not clean metadata'**
  String get statusCouldNotCleanMetadata;

  /// No description provided for @statusCouldNotCreateOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not create output folder'**
  String get statusCouldNotCreateOutputFolder;

  /// No description provided for @statusCouldNotCreateOutputFolderAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Could not create output folder: macOS sandbox did not allow the planned output location. Use Output > Choose Folder and select or create {path}.'**
  String statusCouldNotCreateOutputFolderAutomatic(Object path);

  /// No description provided for @statusCouldNotCreateOutputFolderPath.
  ///
  /// In en, this message translates to:
  /// **'Could not create output folder: {path}. Choose another output folder.'**
  String statusCouldNotCreateOutputFolderPath(Object path);

  /// No description provided for @statusCouldNotRenderPdfPage.
  ///
  /// In en, this message translates to:
  /// **'Could not render PDF page'**
  String get statusCouldNotRenderPdfPage;

  /// No description provided for @statusFailureWithDetail.
  ///
  /// In en, this message translates to:
  /// **'{title}: {detail}'**
  String statusFailureWithDetail(Object title, Object detail);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
