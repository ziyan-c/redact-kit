import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pdf_widgets;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/file_channel_service.dart';
import '../data/jpeg_metadata.dart';
import '../data/pdf_document_service.dart';
import '../data/png_metadata.dart';
import '../domain/export_format.dart';
import '../domain/jpeg_quality_preset.dart';
import '../domain/pdf_quality_preset.dart';
import '../domain/redaction_region.dart';
import '../domain/redaction_state.dart';

part 'redaction_controller.g.dart';

@riverpod
class RedactionController extends _$RedactionController {
  ui.Image? _ownedImage;
  ui.Image? _ownedPdfPageImage;
  PdfDocumentHandle? _pdfDocument;
  int? _pendingPdfPageNumber;
  _MetadataInputSelection? _metadataInputSelection;

  @override
  RedactionState build() {
    final fileService = ref.read(fileChannelServiceProvider);
    ref.onDispose(() {
      unawaited(
        _deleteTemporaryMetadataSelection(fileService, _metadataInputSelection),
      );
      _ownedImage?.dispose();
      _ownedImage = null;
      _ownedPdfPageImage?.dispose();
      _ownedPdfPageImage = null;
      _pdfDocument?.close();
      _pdfDocument = null;
      _pendingPdfPageNumber = null;
      _metadataInputSelection = null;
    });

    return const RedactionState();
  }

  Future<void> openImage() async {
    await _openImage(
      status: 'Opening image',
      loadImage: () => ref.read(fileChannelServiceProvider).openImageFile(),
    );
  }

  Future<void> openPhotoLibrary() async {
    await _openImage(
      status: 'Opening photo library',
      loadImage: () =>
          ref.read(fileChannelServiceProvider).openPhotoLibraryImage(),
    );
  }

  Future<void> openPdf() async {
    if (state.isOpening) return;

    state = state.copyWith(isOpening: true, status: 'Opening PDF');

    PdfDocumentHandle? document;
    ui.Image? pageImage;
    try {
      final pickedPdf = await ref
          .read(fileChannelServiceProvider)
          .openPdfFile();
      if (!ref.mounted) return;

      if (pickedPdf == null) {
        state = state.copyWith(status: 'Ready');
        return;
      }

      document = await ref
          .read(pdfDocumentServiceProvider)
          .openData(pickedPdf.bytes);
      final renderedPage = await document.renderPage(1);
      pageImage = await _decodeImage(renderedPage.pngBytes);
      if (!ref.mounted) {
        pageImage.dispose();
        await document.close();
        return;
      }

      final previousDocument = _pdfDocument;
      final previousPageImage = _ownedPdfPageImage;
      _pdfDocument = document;
      _ownedPdfPageImage = pageImage;
      document = null;
      pageImage = null;

      state = state.copyWith(
        pdfPageImage: _ownedPdfPageImage,
        pdfSourceFileName: pickedPdf.sourceName,
        pdfPageCount: _pdfDocument!.pagesCount,
        pdfCurrentPage: 1,
        pdfRedactions: const <int, List<RedactionRegion>>{},
        draftRect: null,
        draftStart: null,
        draftColor: null,
        status: 'Loaded PDF page 1 of ${_pdfDocument!.pagesCount}',
      );

      previousPageImage?.dispose();
      await previousDocument?.close();
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(status: error.message ?? 'Could not open PDF');
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: 'Could not open PDF: ${_friendlyError(error)}',
      );
    } finally {
      pageImage?.dispose();
      await document?.close();
      if (ref.mounted) {
        state = state.copyWith(isOpening: false);
      }
    }
  }

  Future<void> _openImage({
    required String status,
    required Future<PickedImageBytes?> Function() loadImage,
  }) async {
    if (state.isOpening) return;

    state = state.copyWith(isOpening: true, status: status);

    try {
      final pickedImage = await loadImage();
      if (!ref.mounted) return;

      if (pickedImage == null) {
        state = state.copyWith(status: 'Ready');
        return;
      }

      final decoded = await _decodeImage(pickedImage.bytes);
      if (!ref.mounted) {
        decoded.dispose();
        return;
      }

      final previous = state.image;
      _ownedImage = decoded;
      state = state.copyWith(
        image: decoded,
        sourceFileName: pickedImage.sourceName,
        redactions: const <RedactionRegion>[],
        draftRect: null,
        draftStart: null,
        draftColor: null,
        status: 'Loaded ${decoded.width} x ${decoded.height}px',
      );
      previous?.dispose();
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(status: error.message ?? 'Could not open image');
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(status: 'Could not decode this image');
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isOpening: false);
      }
    }
  }

  Future<void> exportImage() async {
    await _exportCleanImage(
      progressStatus: 'Encoding clean ${state.exportFormat.label}',
      canceledStatus: 'Export canceled',
      successStatus: (snapshot) {
        final redactionCount = snapshot.redactions.length;
        if (redactionCount == 0) {
          return 'Exported clean ${snapshot.exportFormat.label}';
        }

        return 'Exported clean ${snapshot.exportFormat.label} with $redactionCount redaction${redactionCount == 1 ? '' : 's'}';
      },
      fileName: _redactedExportFileName,
      action: (service, snapshot, name, bytes) => service.saveImage(
        name: name,
        bytes: bytes,
        format: snapshot.exportFormat,
      ),
    );
  }

  Future<void> exportMetadataCleanImage() async {
    await _exportCleanImage(
      progressStatus: 'Removing metadata from ${state.exportFormat.label}',
      canceledStatus: 'Metadata removal canceled',
      successStatus: (snapshot) =>
          'Saved metadata-clean ${snapshot.exportFormat.label}',
      fileName: (snapshot) => _metadataCleanFileName(snapshot.exportFormat),
      redactionsForExport: (_) => const <RedactionRegion>[],
      action: (service, snapshot, name, bytes) => service.saveImage(
        name: name,
        bytes: bytes,
        format: snapshot.exportFormat,
      ),
    );
  }

  Future<void> exportPdf() async {
    await _exportCleanPdf(
      progressStatus: 'Flattening clean PDF',
      canceledStatus: 'PDF export canceled',
      successStatus: (snapshot) {
        final redactionCount = snapshot.pdfRedactionCount;
        if (redactionCount == 0) return 'Exported clean PDF';

        return 'Exported clean PDF with $redactionCount redaction${redactionCount == 1 ? '' : 's'}';
      },
      fileName: (snapshot) => _pdfExportFileName(snapshot, redacted: true),
      redactionsForExport: (snapshot) => snapshot.pdfRedactions,
    );
  }

  Future<void> exportMetadataCleanPdf() async {
    await _exportCleanPdf(
      progressStatus: 'Cleaning PDF metadata',
      canceledStatus: 'PDF clean canceled',
      successStatus: (_) => 'Saved metadata-clean PDF',
      fileName: (snapshot) => _pdfExportFileName(snapshot, redacted: false),
      redactionsForExport: (_) => const <int, List<RedactionRegion>>{},
    );
  }

  Future<void> cleanMetadataPdfFromFile() async {
    if (state.isOpening || state.isExporting) return;

    state = state.copyWith(isOpening: true, status: 'Choosing PDF');

    PdfDocumentHandle? document;
    try {
      final pickedPdf = await ref
          .read(fileChannelServiceProvider)
          .openPdfFile();
      if (!ref.mounted) return;

      if (pickedPdf == null) {
        state = state.copyWith(status: 'PDF clean canceled');
        return;
      }

      document = await ref
          .read(pdfDocumentServiceProvider)
          .openData(pickedPdf.bytes);
      if (!ref.mounted) return;

      state = state.copyWith(
        isOpening: false,
        isExporting: true,
        status: 'Cleaning PDF metadata',
      );

      final bytes = await _renderCleanPdf(
        document: document,
        redactionsByPage: const <int, List<RedactionRegion>>{},
        pdfQualityPreset: state.pdfQualityPreset,
        onPage: (pageNumber, pageCount) {
          if (!ref.mounted) return;
          state = state.copyWith(
            status: 'Flattening PDF page $pageNumber of $pageCount',
          );
        },
      );
      if (!ref.mounted) return;

      final fileName = _metadataCleanPdfFileName(
        sourceName: pickedPdf.sourceName,
        preserveFileName: state.preserveMetadataCleanFileNames,
      );
      final result = await ref
          .read(fileChannelServiceProvider)
          .savePdf(name: fileName, bytes: bytes);
      if (!ref.mounted) return;

      state = state.copyWith(
        status: result == null
            ? 'PDF clean canceled'
            : 'Saved metadata-clean PDF',
      );
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(status: error.message ?? 'Could not export PDF');
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: 'Could not export PDF: ${_friendlyError(error)}',
      );
    } finally {
      await document?.close();
      if (ref.mounted) {
        state = state.copyWith(isOpening: false, isExporting: false);
      }
    }
  }

  Future<void> cleanMetadataBatchFromFiles() async {
    final previousSelection = _metadataInputSelection;
    await chooseMetadataImagesFromFiles();
    if (!identical(previousSelection, _metadataInputSelection)) {
      await startMetadataClean();
    }
  }

  Future<void> cleanMetadataBatchFromPhotos() async {
    final previousSelection = _metadataInputSelection;
    await chooseMetadataImagesFromPhotos();
    if (!identical(previousSelection, _metadataInputSelection)) {
      await startMetadataClean();
    }
  }

  Future<void> chooseMetadataFilesOrFolder() async {
    await _chooseMetadataInput(
      choosingStatus: 'Choosing files or folder',
      emptyStatus: 'No supported images or PDFs selected',
      loadSelection: (service) async {
        final pickedInput = await service.chooseMetadataFilesOrFolder();
        if (pickedInput == null) return null;
        return _pickedMetadataInput(pickedInput);
      },
    );
  }

  Future<void> addMetadataFiles() async {
    if (state.isOpening || state.isExporting) return;

    final existingSelection = _metadataInputSelection;
    if (existingSelection == null || existingSelection.isEmpty) {
      await chooseMetadataFilesOrFolder();
      return;
    }

    state = state.copyWith(isOpening: true, status: 'Adding files');

    try {
      final service = ref.read(fileChannelServiceProvider);
      final pickedInput = await service.chooseMetadataFiles();
      if (!ref.mounted) return;

      final pickedSelection = pickedInput == null
          ? null
          : _pickedMetadataFilesInput(pickedInput);
      if (pickedSelection == null || pickedSelection.isEmpty) {
        state = state.copyWith(
          isOpening: false,
          status: 'No supported images or PDFs selected',
        );
        return;
      }

      final selection = existingSelection.appendFilesFrom(pickedSelection);
      _metadataInputSelection = selection;
      var nextState = _stateWithMetadataInput(
        state,
        selection,
        status: 'Selected ${selection.inputLabel}',
      );
      nextState = await _stateWithPreviewedMetadataOutput(
        nextState,
        selection,
        service,
      );
      if (!ref.mounted) return;
      state = nextState.copyWith(isOpening: false);
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isOpening: false,
        status: error.message ?? 'Could not add metadata files',
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isOpening: false,
        status: 'Could not add metadata files',
      );
    }
  }

  Future<void> addMetadataPhotos() async {
    if (state.isOpening || state.isExporting) return;

    final existingSelection = _metadataInputSelection;
    if (existingSelection == null || existingSelection.isEmpty) {
      await chooseMetadataImagesFromPhotos();
      return;
    }

    if (existingSelection.sources.any(
      (source) => source.kind == MetadataInputDisplayKind.folder,
    )) {
      state = state.copyWith(status: 'Remove the folder before adding photos');
      return;
    }

    state = state.copyWith(isOpening: true, status: 'Adding photos');

    try {
      final service = ref.read(fileChannelServiceProvider);
      final images = await service.chooseMetadataPhotoImages();
      if (!ref.mounted) return;

      if (images.isEmpty) {
        state = state.copyWith(isOpening: false, status: 'No photos selected');
        return;
      }

      final selection = existingSelection.appendFilesFrom(
        _photosMetadataInput(images),
      );
      _metadataInputSelection = selection;
      var nextState = _stateWithMetadataInput(
        state,
        selection,
        status: 'Selected ${selection.inputLabel}',
      );
      nextState = await _stateWithPreviewedMetadataOutput(
        nextState,
        selection,
        service,
      );
      if (!ref.mounted) return;
      state = nextState.copyWith(isOpening: false);
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isOpening: false,
        status: error.message ?? 'Could not add photos',
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(isOpening: false, status: 'Could not add photos');
    }
  }

  Future<void> removeMetadataInputAt(int index) async {
    if (state.isOpening || state.isExporting) return;

    final selection = _metadataInputSelection;
    if (selection == null || index < 0 || index >= selection.sources.length) {
      return;
    }

    final removedSource = selection.sources[index];
    final service = ref.read(fileChannelServiceProvider);
    final nextSelection = selection.removingSourceAt(index);

    await _deleteTemporaryMetadataSource(service, removedSource);
    if (!ref.mounted) return;

    if (nextSelection == null || nextSelection.isEmpty) {
      _metadataInputSelection = null;
      state = _stateWithoutMetadataInput(
        state,
        status: 'Removed ${removedSource.displayLabel}',
      );
      return;
    }

    _metadataInputSelection = nextSelection;
    var nextState = _stateWithMetadataInput(
      state,
      nextSelection,
      status: 'Removed ${removedSource.displayLabel}',
    );
    nextState = await _stateWithPreviewedMetadataOutput(
      nextState,
      nextSelection,
      service,
    );
    if (!ref.mounted) return;
    state = nextState;
  }

  List<MetadataInputDisplayItem> get metadataInputItems =>
      _metadataInputSelection?.displayItems ??
      const <MetadataInputDisplayItem>[];

  Future<void> chooseMetadataImageFromFiles() async {
    await _chooseMetadataInput(
      choosingStatus: 'Choosing image file',
      emptyStatus: 'Metadata clean canceled',
      loadSelection: (service) async {
        final image = await service.chooseMetadataImageFile();
        if (image == null) return null;
        return _singleFileMetadataInput(image);
      },
    );
  }

  Future<void> chooseMetadataImagesFromFiles() async {
    await _chooseMetadataInput(
      choosingStatus: 'Choosing image files',
      emptyStatus: 'Metadata clean canceled',
      loadSelection: (service) async {
        final images = await service.chooseMetadataImageFiles();
        if (images.isEmpty) return null;
        if (images.length == 1) return _singleFileMetadataInput(images.single);
        return _multiFileMetadataInput(images);
      },
    );
  }

  Future<void> chooseMetadataPdfFromFiles() async {
    await _chooseMetadataInput(
      choosingStatus: 'Choosing PDF file',
      emptyStatus: 'Metadata clean canceled',
      loadSelection: (service) async {
        final pdf = await service.chooseMetadataPdfFile();
        if (pdf == null) return null;
        return _singlePdfMetadataInput(pdf);
      },
    );
  }

  Future<void> chooseMetadataPdfsFromFiles() async {
    await _chooseMetadataInput(
      choosingStatus: 'Choosing PDF files',
      emptyStatus: 'Metadata clean canceled',
      loadSelection: (service) async {
        final pdfs = await service.chooseMetadataPdfFiles();
        if (pdfs.isEmpty) return null;
        if (pdfs.length == 1) return _singlePdfMetadataInput(pdfs.single);
        return _multiPdfMetadataInput(pdfs);
      },
    );
  }

  Future<void> chooseMetadataFolder() async {
    await _chooseMetadataInput(
      choosingStatus: 'Choosing folder',
      emptyStatus: 'No supported images or PDFs found in that folder',
      loadSelection: (service) async {
        final folder = await service.chooseMetadataImageFolder();
        if (folder == null) return null;
        return _folderMetadataInput(folder);
      },
    );
  }

  Future<void> chooseMetadataImagesFromPhotos() async {
    await _chooseMetadataInput(
      choosingStatus: 'Choosing images from Photos',
      emptyStatus: 'Metadata clean canceled',
      loadSelection: (service) async {
        final images = await service.chooseMetadataPhotoImages();
        if (images.isEmpty) return null;
        return _photosMetadataInput(images);
      },
    );
  }

  Future<void> chooseMetadataOutputFolder() async {
    if (state.isOpening || state.isExporting) return;

    final selection = _metadataInputSelection;
    if (selection == null) {
      state = state.copyWith(status: 'Choose metadata input first');
      return;
    }

    final previousStatus = state.status;
    state = state.copyWith(isOpening: true, status: 'Choosing output folder');

    try {
      final destination = await ref
          .read(fileChannelServiceProvider)
          .chooseMetadataCleanOutputDirectory();
      if (!ref.mounted) return;

      state = destination == null
          ? state.copyWith(status: previousStatus)
          : _stateWithMetadataInput(
              state,
              selection.withSelectedDestination(destination),
              status: 'Metadata output folder set',
            );
      if (destination != null) {
        _metadataInputSelection = selection.withSelectedDestination(
          destination,
        );
      }
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: error.message ?? 'Could not choose output folder',
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(status: 'Could not choose output folder');
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isOpening: false);
      }
    }
  }

  Future<void> openMetadataOutputFolder() async {
    if (state.isOpening || state.isExporting) return;

    final path = state.metadataOutputDirectoryPath;
    if (path == null || path.trim().isEmpty) {
      state = state.copyWith(
        status: 'Start cleaning first to create the output folder',
      );
      return;
    }

    try {
      await ref.read(fileChannelServiceProvider).openDirectory(path);
      if (!ref.mounted) return;
      state = state.copyWith(status: 'Opened output folder');
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: error.message ?? 'Could not open output folder',
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: 'Could not open output folder: ${_friendlyError(error)}',
      );
    }
  }

  Future<void> shareImage() async {
    await _exportCleanImage(
      progressStatus: 'Preparing clean ${state.exportFormat.label} to share',
      canceledStatus: 'Share canceled',
      successStatus: (snapshot) =>
          'Shared clean ${snapshot.exportFormat.label}',
      fileName: _redactedExportFileName,
      action: (service, snapshot, name, bytes) => service.shareImage(
        name: name,
        bytes: bytes,
        format: snapshot.exportFormat,
      ),
    );
  }

  Future<void> saveImageToPhotos() async {
    await _exportCleanImage(
      progressStatus: 'Saving clean ${state.exportFormat.label} to Photos',
      canceledStatus: 'Save canceled',
      successStatus: (snapshot) =>
          'Saved clean ${snapshot.exportFormat.label} to Photos',
      fileName: _redactedExportFileName,
      action: (service, snapshot, name, bytes) =>
          service.saveImageToPhotos(name: name, bytes: bytes),
    );
  }

  Future<void> _exportCleanImage({
    required String progressStatus,
    required String canceledStatus,
    required String Function(RedactionState snapshot) successStatus,
    String Function(RedactionState snapshot)? fileName,
    List<RedactionRegion> Function(RedactionState snapshot)?
    redactionsForExport,
    required Future<String?> Function(
      FileChannelService service,
      RedactionState snapshot,
      String name,
      Uint8List bytes,
    )
    action,
  }) async {
    final snapshot = state;
    final image = snapshot.image;
    if (image == null || snapshot.isExporting) return;

    state = state.copyWith(isExporting: true, status: progressStatus);

    try {
      final exportRedactions =
          redactionsForExport?.call(snapshot) ?? snapshot.redactions;
      final bytes = await _renderCleanImage(
        image: image,
        redactions: exportRedactions,
        format: snapshot.exportFormat,
        jpegQualityPreset: snapshot.jpegQualityPreset,
      );
      if (!ref.mounted) return;

      final result = await action(
        ref.read(fileChannelServiceProvider),
        snapshot,
        fileName?.call(snapshot) ?? snapshot.exportFormat.defaultFileName,
        bytes,
      );
      if (!ref.mounted) return;

      state = state.copyWith(
        status: result == null ? canceledStatus : successStatus(snapshot),
      );
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(status: error.message ?? 'Could not export image');
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(status: 'Could not export image');
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isExporting: false);
      }
    }
  }

  Future<void> _exportCleanPdf({
    required String progressStatus,
    required String canceledStatus,
    required String Function(RedactionState snapshot) successStatus,
    required String Function(RedactionState snapshot) fileName,
    required Map<int, List<RedactionRegion>> Function(RedactionState snapshot)
    redactionsForExport,
  }) async {
    final snapshot = state;
    final document = _pdfDocument;
    if (document == null || !snapshot.hasPdf || snapshot.isExporting) return;

    state = state.copyWith(isExporting: true, status: progressStatus);

    try {
      final bytes = await _renderCleanPdf(
        document: document,
        redactionsByPage: redactionsForExport(snapshot),
        pdfQualityPreset: snapshot.pdfQualityPreset,
        onPage: (pageNumber, pageCount) {
          if (!ref.mounted) return;
          state = state.copyWith(
            status: 'Flattening PDF page $pageNumber of $pageCount',
          );
        },
      );
      if (!ref.mounted) return;

      final result = await ref
          .read(fileChannelServiceProvider)
          .savePdf(name: fileName(snapshot), bytes: bytes);
      if (!ref.mounted) return;

      state = state.copyWith(
        status: result == null ? canceledStatus : successStatus(snapshot),
      );
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(status: error.message ?? 'Could not export PDF');
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: 'Could not export PDF: ${_friendlyError(error)}',
      );
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isExporting: false);
      }
    }
  }

  Future<void> _chooseMetadataInput({
    required String choosingStatus,
    required String emptyStatus,
    required Future<_MetadataInputSelection?> Function(
      FileChannelService service,
    )
    loadSelection,
  }) async {
    if (state.isOpening || state.isExporting) return;

    state = state.copyWith(isOpening: true, status: choosingStatus);

    try {
      final service = ref.read(fileChannelServiceProvider);
      final selection = await loadSelection(service);
      if (!ref.mounted) return;

      if (selection == null) {
        state = state.copyWith(isOpening: false, status: emptyStatus);
        return;
      }

      if (selection.isEmpty) {
        state = state.copyWith(isOpening: false, status: emptyStatus);
        return;
      }

      final previousSelection = _metadataInputSelection;
      _metadataInputSelection = selection;
      var nextState = _stateWithMetadataInput(
        state,
        selection,
        status: 'Selected ${selection.inputLabel}',
      );
      nextState = await _stateWithPreviewedMetadataOutput(
        nextState,
        selection,
        service,
      );
      if (!ref.mounted) return;
      state = nextState.copyWith(isOpening: false);
      unawaited(_deleteTemporaryMetadataSelection(service, previousSelection));
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isOpening: false,
        status: error.message ?? 'Could not choose metadata input',
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isOpening: false,
        status: 'Could not choose metadata input',
      );
    }
  }

  Future<void> startMetadataClean() async {
    if (state.isOpening || state.isExporting) return;

    final selection = _metadataInputSelection;
    if (selection == null || selection.isEmpty) {
      state = state.copyWith(status: 'Choose metadata input first');
      return;
    }

    final output = selection.outputFor(state.exportFormat);
    final service = ref.read(fileChannelServiceProvider);
    final pdfService = ref.read(pdfDocumentServiceProvider);
    final totalCount = selection.totalCount;
    state = state.copyWith(
      isExporting: true,
      metadataCleanProgress: 0,
      status: 'Starting metadata clean',
    );

    try {
      state = state.copyWith(status: 'Preparing output folder');
      final destination = await service.createMetadataCleanDestination(
        images: selection.images,
        automaticFolderName: output.automaticFolderName,
        selectedDestination: output.directoryPath == null
            ? null
            : MetadataCleanDestination(
                directoryPath: output.directoryPath!,
                displayName: output.directoryDisplayName,
              ),
      );
      if (!ref.mounted) return;

      state = state.copyWith(
        metadataOutputDirectoryPath: destination.directoryPath,
        metadataOutputDirectoryDisplayName: output.directoryPath == null
            ? output.singleFileName == null
                  ? destination.displayName
                  : _joinPath(destination.displayName, output.singleFileName!)
            : output.displayName,
      );

      final snapshot = state;
      final format = snapshot.exportFormat;
      final jpegQualityPreset = snapshot.jpegQualityPreset;
      final pdfQualityPreset = snapshot.pdfQualityPreset;
      final preserveFileNames = snapshot.preserveMetadataCleanFileNames;
      final usedFileNames = <String>{};
      var processedCount = 0;
      var savedCount = 0;
      var failedCount = 0;
      String? firstFailure;
      String? lastSavedPath;

      for (var index = 0; index < selection.images.length; index += 1) {
        if (!ref.mounted) return;
        final image = selection.images[index];
        final imageLabel = _metadataInputName(image, index);
        state = state.copyWith(
          metadataCleanProgress: processedCount / totalCount,
          status: 'Cleaning $imageLabel (${processedCount + 1}/$totalCount)',
        );

        try {
          final bytes = await _renderMetadataCleanImage(
            input: image,
            format: format,
            jpegQualityPreset: jpegQualityPreset,
          );
          lastSavedPath = await service.saveMetadataCleanImage(
            destination: destination,
            name:
                output.singleFileName ??
                _metadataCleanBatchFileName(
                  index: processedCount,
                  total: totalCount,
                  format: format,
                  sourceName: image.sourceName,
                  preserveFileNames: preserveFileNames,
                  usedFileNames: usedFileNames,
                ),
            bytes: bytes,
          );
          savedCount += 1;
        } catch (error) {
          failedCount += 1;
          firstFailure ??= '$imageLabel: ${_friendlyError(error)}';
        } finally {
          processedCount += 1;
          if (ref.mounted) {
            state = state.copyWith(
              metadataCleanProgress: processedCount / totalCount,
            );
          }
        }
      }

      for (var index = 0; index < selection.pdfs.length; index += 1) {
        if (!ref.mounted) return;
        final pdf = selection.pdfs[index];
        final pdfLabel = _metadataPdfInputName(pdf, index);
        state = state.copyWith(
          metadataCleanProgress: processedCount / totalCount,
          status: 'Cleaning $pdfLabel (${processedCount + 1}/$totalCount)',
        );

        PdfDocumentHandle? document;
        try {
          final bytes = await pdf.readBytes();
          document = await pdfService.openData(bytes);
          final cleanBytes = await _renderCleanPdf(
            document: document,
            redactionsByPage: const <int, List<RedactionRegion>>{},
            pdfQualityPreset: pdfQualityPreset,
            onPage: (pageNumber, pageCount) {
              if (!ref.mounted) return;
              state = state.copyWith(
                status:
                    'Cleaning $pdfLabel page $pageNumber of $pageCount (${processedCount + 1}/$totalCount)',
              );
            },
          );
          lastSavedPath = await service.saveMetadataCleanFile(
            destination: destination,
            name:
                output.singleFileName ??
                _metadataCleanPdfBatchFileName(
                  index: processedCount,
                  total: totalCount,
                  sourceName: pdf.sourceName,
                  preserveFileNames: preserveFileNames,
                  usedFileNames: usedFileNames,
                ),
            bytes: cleanBytes,
          );
          savedCount += 1;
        } catch (error) {
          failedCount += 1;
          firstFailure ??= '$pdfLabel: ${_friendlyError(error)}';
        } finally {
          await document?.close();
          processedCount += 1;
          if (ref.mounted) {
            state = state.copyWith(
              metadataCleanProgress: processedCount / totalCount,
            );
          }
        }
      }

      if (!ref.mounted) return;
      final status = _metadataCleanBatchStatus(
        savedCount: savedCount,
        failedCount: failedCount,
        ignoredCount: selection.ignoredCount,
        destinationName: output.isSingleFile && lastSavedPath != null
            ? lastSavedPath
            : destination.displayName,
        firstFailure: firstFailure,
      );
      final deletedTemporaryInputs = await _deleteTemporaryMetadataSelection(
        service,
        selection,
      );
      if (!ref.mounted) return;
      if (deletedTemporaryInputs &&
          identical(_metadataInputSelection, selection)) {
        _metadataInputSelection = null;
      }
      state = state.copyWith(
        metadataInputCount: deletedTemporaryInputs
            ? 0
            : state.metadataInputCount,
        metadataHasImages: deletedTemporaryInputs
            ? false
            : state.metadataHasImages,
        metadataHasPdfs: deletedTemporaryInputs ? false : state.metadataHasPdfs,
        metadataInputLabel: deletedTemporaryInputs
            ? null
            : state.metadataInputLabel,
        metadataInputDescription: deletedTemporaryInputs
            ? null
            : state.metadataInputDescription,
        metadataCleanProgress: null,
        status: status,
      );
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        metadataCleanProgress: null,
        status:
            'Could not clean metadata: ${error.message ?? 'Platform error'}',
      );
    } on FileSystemException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        metadataCleanProgress: null,
        status: _metadataOutputFileSystemStatus(
          error: error,
          automaticOutput: selection.selectedDestination == null,
          outputPath: output.directoryPath,
        ),
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        metadataCleanProgress: null,
        status: 'Could not clean metadata: ${_friendlyError(error)}',
      );
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isExporting: false, metadataCleanProgress: null);
      }
    }
  }

  Future<void> startMetadataCleanToPhotos() async {
    if (state.isOpening || state.isExporting) return;

    final selection = _metadataInputSelection;
    if (selection == null || selection.isEmpty) {
      state = state.copyWith(status: 'Choose metadata input first');
      return;
    }
    if (!selection.canSaveImagesToPhotos) {
      state = state.copyWith(
        status: 'Photos output is available for image files only',
      );
      return;
    }

    final output = selection.outputFor(state.exportFormat);
    final service = ref.read(fileChannelServiceProvider);
    final totalCount = selection.images.length;
    state = state.copyWith(
      isExporting: true,
      metadataCleanProgress: 0,
      metadataOutputDirectoryPath: null,
      metadataOutputDirectoryDisplayName: 'Photos',
      status: 'Starting metadata clean to Photos',
    );

    try {
      final snapshot = state;
      final format = snapshot.exportFormat;
      final jpegQualityPreset = snapshot.jpegQualityPreset;
      final preserveFileNames = snapshot.preserveMetadataCleanFileNames;
      final usedFileNames = <String>{};
      var processedCount = 0;
      var savedCount = 0;
      var failedCount = 0;
      String? firstFailure;

      for (var index = 0; index < selection.images.length; index += 1) {
        if (!ref.mounted) return;
        final image = selection.images[index];
        final imageLabel = _metadataInputName(image, index);
        state = state.copyWith(
          metadataCleanProgress: processedCount / totalCount,
          status:
              'Saving $imageLabel to Photos (${processedCount + 1}/$totalCount)',
        );

        try {
          final bytes = await _renderMetadataCleanImage(
            input: image,
            format: format,
            jpegQualityPreset: jpegQualityPreset,
          );
          await service.saveImageToPhotos(
            name:
                output.singleFileName ??
                _metadataCleanBatchFileName(
                  index: processedCount,
                  total: totalCount,
                  format: format,
                  sourceName: image.sourceName,
                  preserveFileNames: preserveFileNames,
                  usedFileNames: usedFileNames,
                ),
            bytes: bytes,
          );
          savedCount += 1;
        } catch (error) {
          failedCount += 1;
          firstFailure ??= '$imageLabel: ${_friendlyError(error)}';
        } finally {
          processedCount += 1;
          if (ref.mounted) {
            state = state.copyWith(
              metadataCleanProgress: processedCount / totalCount,
            );
          }
        }
      }

      if (!ref.mounted) return;
      final status = _metadataCleanBatchStatus(
        savedCount: savedCount,
        failedCount: failedCount,
        ignoredCount: selection.ignoredCount,
        destinationName: 'Photos',
        firstFailure: firstFailure,
      );
      final deletedTemporaryInputs = await _deleteTemporaryMetadataSelection(
        service,
        selection,
      );
      if (!ref.mounted) return;
      if (deletedTemporaryInputs &&
          identical(_metadataInputSelection, selection)) {
        _metadataInputSelection = null;
      }
      state = state.copyWith(
        metadataInputCount: deletedTemporaryInputs
            ? 0
            : state.metadataInputCount,
        metadataHasImages: deletedTemporaryInputs
            ? false
            : state.metadataHasImages,
        metadataHasPdfs: deletedTemporaryInputs ? false : state.metadataHasPdfs,
        metadataInputLabel: deletedTemporaryInputs
            ? null
            : state.metadataInputLabel,
        metadataInputDescription: deletedTemporaryInputs
            ? null
            : state.metadataInputDescription,
        metadataOutputDirectoryPath: null,
        metadataOutputDirectoryDisplayName: deletedTemporaryInputs
            ? null
            : 'Photos',
        metadataCleanProgress: null,
        status: status,
      );
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        metadataCleanProgress: null,
        status:
            'Could not clean metadata: ${error.message ?? 'Platform error'}',
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        metadataCleanProgress: null,
        status: 'Could not clean metadata: ${_friendlyError(error)}',
      );
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isExporting: false, metadataCleanProgress: null);
      }
    }
  }

  Future<Uint8List> _renderCleanImage({
    required ui.Image image,
    required List<RedactionRegion> redactions,
    required ExportFormat format,
    required JpegQualityPreset jpegQualityPreset,
  }) async {
    ui.Picture? picture;
    ui.Image? redactedImage;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(image, Offset.zero, Paint());

      for (final region in redactions) {
        canvas.drawRect(region.rect, Paint()..color = region.color);
      }

      picture = recorder.endRecording();
      redactedImage = await picture.toImage(image.width, image.height);
      final byteData = await redactedImage.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );

      if (byteData == null) {
        throw StateError('Pixel readback failed.');
      }

      final raster = image_lib.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: byteData.buffer,
        bytesOffset: byteData.offsetInBytes,
        numChannels: 4,
        order: image_lib.ChannelOrder.rgba,
      );

      switch (format) {
        case ExportFormat.png:
          return stripPngMetadataChunks(image_lib.encodePng(raster));
        case ExportFormat.jpeg:
          return stripJpegMetadataSegments(
            image_lib.encodeJpg(raster, quality: jpegQualityPreset.quality),
          );
      }
    } finally {
      picture?.dispose();
      redactedImage?.dispose();
    }
  }

  Future<Uint8List> _renderMetadataCleanImage({
    required MetadataInputImage input,
    required ExportFormat format,
    required JpegQualityPreset jpegQualityPreset,
  }) async {
    final sourceBytes = await input.readBytes();
    final sourceFormat = _detectSourceFormat(sourceBytes, input.sourceName);

    if (sourceFormat == format) {
      switch (format) {
        case ExportFormat.png:
          return stripPngMetadataChunks(sourceBytes);
        case ExportFormat.jpeg:
          if (hasNonDefaultJpegExifOrientation(sourceBytes)) {
            final raster = image_lib.decodeImage(sourceBytes);
            if (raster == null) {
              throw StateError('Image decode failed.');
            }
            return stripJpegMetadataSegments(
              image_lib.encodeJpg(raster, quality: jpegQualityPreset.quality),
            );
          }
          return stripJpegMetadataSegments(sourceBytes);
      }
    }

    final raster = image_lib.decodeImage(sourceBytes);
    if (raster == null) {
      throw StateError('Image decode failed.');
    }

    switch (format) {
      case ExportFormat.png:
        return stripPngMetadataChunks(image_lib.encodePng(raster));
      case ExportFormat.jpeg:
        return stripJpegMetadataSegments(
          image_lib.encodeJpg(raster, quality: jpegQualityPreset.quality),
        );
    }
  }

  Future<Uint8List> _renderCleanPdf({
    required PdfDocumentHandle document,
    required Map<int, List<RedactionRegion>> redactionsByPage,
    required PdfQualityPreset pdfQualityPreset,
    void Function(int pageNumber, int pageCount)? onPage,
  }) async {
    final output = pdf_widgets.Document(compress: true);
    final pageCount = document.pagesCount;

    for (var pageNumber = 1; pageNumber <= pageCount; pageNumber += 1) {
      onPage?.call(pageNumber, pageCount);
      final renderedPage = await document.renderPage(
        pageNumber,
        preferredScale: pdfQualityPreset.renderScale,
        maxRenderedSide: pdfQualityPreset.maxRenderedSide,
      );
      final redactions =
          redactionsByPage[pageNumber] ?? const <RedactionRegion>[];
      final pageBytes = await _renderCleanPdfPage(
        renderedPage: renderedPage,
        redactions: _scalePdfRedactionsForRenderedPage(
          redactions,
          renderedPage,
        ),
        pdfQualityPreset: pdfQualityPreset,
      );
      final image = pdf_widgets.MemoryImage(pageBytes);
      output.addPage(
        pdf_widgets.Page(
          pageFormat: pdf_lib.PdfPageFormat(
            renderedPage.pageWidth,
            renderedPage.pageHeight,
          ),
          build: (_) => pdf_widgets.FullPage(
            ignoreMargins: true,
            child: pdf_widgets.Image(image, fit: pdf_widgets.BoxFit.fill),
          ),
        ),
      );
    }

    return output.save();
  }

  Future<Uint8List> _renderCleanPdfPage({
    required PdfRenderedPage renderedPage,
    required List<RedactionRegion> redactions,
    required PdfQualityPreset pdfQualityPreset,
  }) async {
    final image = await _decodeImage(renderedPage.pngBytes);
    try {
      return _renderCleanImage(
        image: image,
        redactions: redactions,
        format: ExportFormat.jpeg,
        jpegQualityPreset: pdfQualityPreset.jpegQualityPreset,
      );
    } finally {
      image.dispose();
    }
  }

  List<RedactionRegion> _scalePdfRedactionsForRenderedPage(
    List<RedactionRegion> redactions,
    PdfRenderedPage renderedPage,
  ) {
    if (redactions.isEmpty) return redactions;

    final previewScale = pdfRenderScaleForPage(
      renderedPage.pageWidth,
      renderedPage.pageHeight,
    );
    final previewWidth = renderedPage.pageWidth * previewScale;
    final previewHeight = renderedPage.pageHeight * previewScale;
    if (previewWidth <= 0 || previewHeight <= 0) return redactions;

    final scaleX = renderedPage.width / previewWidth;
    final scaleY = renderedPage.height / previewHeight;
    if ((scaleX - 1).abs() < 0.0001 && (scaleY - 1).abs() < 0.0001) {
      return redactions;
    }

    return redactions
        .map(
          (redaction) => RedactionRegion(
            rect: Rect.fromLTRB(
              redaction.rect.left * scaleX,
              redaction.rect.top * scaleY,
              redaction.rect.right * scaleX,
              redaction.rect.bottom * scaleY,
            ),
            color: redaction.color,
          ),
        )
        .toList(growable: false);
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  Future<void> showPdfPage(int pageNumber) async {
    final document = _pdfDocument;
    if (document == null || state.isExporting) return;
    if (pageNumber < 1 || pageNumber > document.pagesCount) return;
    if (pageNumber == state.pdfCurrentPage) return;
    if (state.isOpening) {
      _pendingPdfPageNumber = pageNumber;
      return;
    }

    finishPdfRedaction();
    state = state.copyWith(
      isOpening: true,
      status: 'Rendering PDF page $pageNumber',
    );

    ui.Image? pageImage;
    try {
      final renderedPage = await document.renderPage(pageNumber);
      pageImage = await _decodeImage(renderedPage.pngBytes);
      if (!ref.mounted) {
        pageImage.dispose();
        pageImage = null;
        return;
      }

      final previousPageImage = _ownedPdfPageImage;
      _ownedPdfPageImage = pageImage;
      pageImage = null;

      state = state.copyWith(
        pdfPageImage: _ownedPdfPageImage,
        pdfCurrentPage: pageNumber,
        draftRect: null,
        draftStart: null,
        draftColor: null,
        status: 'PDF page $pageNumber of ${document.pagesCount}',
      );
      previousPageImage?.dispose();
    } on PlatformException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: error.message ?? 'Could not render PDF page',
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: 'Could not render PDF page: ${_friendlyError(error)}',
      );
    } finally {
      pageImage?.dispose();
      if (ref.mounted) {
        state = state.copyWith(isOpening: false);
        final pendingPageNumber = _pendingPdfPageNumber;
        _pendingPdfPageNumber = null;
        if (pendingPageNumber != null &&
            pendingPageNumber != state.pdfCurrentPage) {
          await showPdfPage(pendingPageNumber);
        }
      }
    }
  }

  Future<void> nextPdfPage() => showPdfPage(state.pdfCurrentPage + 1);

  Future<void> previousPdfPage() => showPdfPage(state.pdfCurrentPage - 1);

  void selectColor(Color color) {
    state = state.copyWith(redactionColor: color);
  }

  void setExportFormat(ExportFormat format) {
    final selection = _metadataInputSelection;
    final next = state.copyWith(exportFormat: format);
    if (selection == null) {
      state = next;
      return;
    }

    final output = selection.outputFor(format);
    final withInput = _stateWithMetadataInput(next, selection);
    state = output.directoryPath == null
        ? withInput.copyWith(
            metadataOutputDirectoryPath: state.metadataOutputDirectoryPath,
          )
        : withInput;
  }

  void setJpegQualityPreset(JpegQualityPreset preset) {
    state = state.copyWith(jpegQualityPreset: preset);
  }

  void setPdfQualityPreset(PdfQualityPreset preset) {
    state = state.copyWith(pdfQualityPreset: preset);
  }

  void setPreserveRedactionExportFileName(bool preserve) {
    state = state.copyWith(preserveRedactionExportFileName: preserve);
  }

  void setPreserveMetadataCleanFileNames(bool preserve) {
    state = state.copyWith(preserveMetadataCleanFileNames: preserve);
  }

  void setPreservePdfExportFileName(bool preserve) {
    state = state.copyWith(preservePdfExportFileName: preserve);
  }

  void undo() {
    if (state.redactions.isEmpty) return;

    final redactions = state.redactions.toList()..removeLast();
    state = state.copyWith(
      redactions: redactions,
      status: redactions.isEmpty
          ? 'Redactions cleared'
          : '${redactions.length} redaction${redactions.length == 1 ? '' : 's'}',
    );
  }

  void clear() {
    if (state.redactions.isEmpty && state.draftRect == null) return;

    state = state.copyWith(
      redactions: const <RedactionRegion>[],
      draftRect: null,
      draftStart: null,
      draftColor: null,
      status: 'Redactions cleared',
    );
  }

  void undoPdfRedaction() {
    final currentRedactions = state.currentPdfRedactions;
    if (currentRedactions.isEmpty) return;

    final redactions = currentRedactions.toList()..removeLast();
    state = state.copyWith(
      pdfRedactions: _pdfRedactionsWithPage(
        state.pdfRedactions,
        state.pdfCurrentPage,
        redactions,
      ),
      status: redactions.isEmpty
          ? 'PDF page redactions cleared'
          : 'PDF page ${state.pdfCurrentPage}: ${redactions.length} redaction${redactions.length == 1 ? '' : 's'}',
    );
  }

  void clearPdfPageRedactions() {
    if (state.currentPdfRedactions.isEmpty && state.draftRect == null) return;

    state = state.copyWith(
      pdfRedactions: _pdfRedactionsWithPage(
        state.pdfRedactions,
        state.pdfCurrentPage,
        const <RedactionRegion>[],
      ),
      draftRect: null,
      draftStart: null,
      draftColor: null,
      status: 'PDF page redactions cleared',
    );
  }

  void beginRedaction(Offset localPosition, Rect imageRect) {
    final image = state.image;
    _beginRedactionForImage(image, localPosition, imageRect);
  }

  void beginPdfRedaction(Offset localPosition, Rect imageRect) {
    final image = state.pdfPageImage;
    _beginRedactionForImage(image, localPosition, imageRect);
  }

  void _beginRedactionForImage(
    ui.Image? image,
    Offset localPosition,
    Rect imageRect,
  ) {
    if (image == null || !imageRect.contains(localPosition)) return;

    final point = _toImagePoint(localPosition, imageRect, image);
    state = state.copyWith(
      draftStart: point,
      draftRect: Rect.fromPoints(point, point),
      draftColor: state.redactionColor,
    );
  }

  void updateRedaction(Offset localPosition, Rect imageRect) {
    final image = state.image;
    final start = state.draftStart;
    _updateRedactionForImage(image, start, localPosition, imageRect);
  }

  void updatePdfRedaction(Offset localPosition, Rect imageRect) {
    final image = state.pdfPageImage;
    final start = state.draftStart;
    _updateRedactionForImage(image, start, localPosition, imageRect);
  }

  void _updateRedactionForImage(
    ui.Image? image,
    Offset? start,
    Offset localPosition,
    Rect imageRect,
  ) {
    if (image == null || start == null) return;

    final point = _toImagePoint(localPosition, imageRect, image);
    state = state.copyWith(
      draftRect: _normalizeRect(Rect.fromPoints(start, point)),
    );
  }

  void finishRedaction() {
    final draft = state.draftRect;
    final color = state.draftColor;
    if (draft == null || color == null) return;

    final normalized = _normalizeRect(draft);
    final redactions = state.redactions.toList();
    var status = state.status;

    if (normalized.width >= 3 && normalized.height >= 3) {
      redactions.add(RedactionRegion(rect: normalized, color: color));
      status =
          '${redactions.length} redaction${redactions.length == 1 ? '' : 's'} ready';
    }

    state = state.copyWith(
      redactions: redactions,
      draftRect: null,
      draftStart: null,
      draftColor: null,
      status: status,
    );
  }

  void finishPdfRedaction() {
    final draft = state.draftRect;
    final color = state.draftColor;
    if (draft == null || color == null) return;

    final normalized = _normalizeRect(draft);
    final redactions = state.currentPdfRedactions.toList();
    var status = state.status;

    if (normalized.width >= 3 && normalized.height >= 3) {
      redactions.add(RedactionRegion(rect: normalized, color: color));
      status =
          'PDF page ${state.pdfCurrentPage}: ${redactions.length} redaction${redactions.length == 1 ? '' : 's'} ready';
    }

    state = state.copyWith(
      pdfRedactions: _pdfRedactionsWithPage(
        state.pdfRedactions,
        state.pdfCurrentPage,
        redactions,
      ),
      draftRect: null,
      draftStart: null,
      draftColor: null,
      status: status,
    );
  }

  Offset _toImagePoint(Offset local, Rect imageRect, ui.Image image) {
    final x = ((local.dx - imageRect.left) * image.width / imageRect.width)
        .clamp(0.0, image.width.toDouble())
        .toDouble();
    final y = ((local.dy - imageRect.top) * image.height / imageRect.height)
        .clamp(0.0, image.height.toDouble())
        .toDouble();
    return Offset(x, y);
  }

  Rect _normalizeRect(Rect rect) {
    return Rect.fromLTRB(
      math.min(rect.left, rect.right),
      math.min(rect.top, rect.bottom),
      math.max(rect.left, rect.right),
      math.max(rect.top, rect.bottom),
    );
  }
}

String _metadataCleanFileName(ExportFormat format) =>
    'metadata-clean.${format.extension}';

Future<bool> _deleteTemporaryMetadataSelection(
  FileChannelService service,
  _MetadataInputSelection? selection,
) async {
  if (selection == null) return false;
  return service.deleteTemporaryMetadataInputPaths(selection.sourcePaths);
}

Future<bool> _deleteTemporaryMetadataSource(
  FileChannelService service,
  _MetadataInputSource source,
) {
  return service.deleteTemporaryMetadataInputPaths(source.sourcePaths);
}

_MetadataInputSelection _singleFileMetadataInput(MetadataInputImage image) {
  return _MetadataInputSelection.fromSources(<_MetadataInputSource>[
    _MetadataInputSource.image(image),
  ]);
}

_MetadataInputSelection _multiFileMetadataInput(
  List<MetadataInputImage> images,
) {
  return _MetadataInputSelection.fromSources(<_MetadataInputSource>[
    for (final image in images) _MetadataInputSource.image(image),
  ]);
}

_MetadataInputSelection _singlePdfMetadataInput(MetadataInputPdf pdf) {
  return _MetadataInputSelection.fromSources(<_MetadataInputSource>[
    _MetadataInputSource.pdf(pdf),
  ]);
}

_MetadataInputSelection _multiPdfMetadataInput(List<MetadataInputPdf> pdfs) {
  return _MetadataInputSelection.fromSources(<_MetadataInputSource>[
    for (final pdf in pdfs) _MetadataInputSource.pdf(pdf),
  ]);
}

_MetadataInputSelection _folderMetadataInput(MetadataPickedFolder folder) {
  return _MetadataInputSelection.fromSources(<_MetadataInputSource>[
    _MetadataInputSource.folder(folder),
  ]);
}

_MetadataInputSelection _photosMetadataInput(List<MetadataInputImage> images) {
  return _MetadataInputSelection.fromSources(<_MetadataInputSource>[
    for (final image in images) _MetadataInputSource.image(image, photo: true),
  ]);
}

_MetadataInputSelection? _pickedMetadataInput(MetadataPickedInput input) {
  final sources = <_MetadataInputSource>[];
  var ignoredCount = input.ignoredCount;
  if (input.folders.isNotEmpty) {
    sources.add(_MetadataInputSource.folder(input.folders.first));
    for (final folder in input.folders.skip(1)) {
      ignoredCount += folder.images.length + folder.pdfs.length;
      ignoredCount += folder.ignoredCount;
    }
  }
  sources.addAll(<_MetadataInputSource>[
    for (final image in input.images) _MetadataInputSource.image(image),
    for (final pdf in input.pdfs) _MetadataInputSource.pdf(pdf),
  ]);

  if (sources.isEmpty) return null;
  return _MetadataInputSelection.fromSources(
    sources,
    extraIgnoredCount: ignoredCount,
  );
}

_MetadataInputSelection? _pickedMetadataFilesInput(MetadataPickedInput input) {
  final sources = <_MetadataInputSource>[
    for (final image in input.images) _MetadataInputSource.image(image),
    for (final pdf in input.pdfs) _MetadataInputSource.pdf(pdf),
  ];
  if (sources.isEmpty) return null;
  return _MetadataInputSelection.fromSources(
    sources,
    extraIgnoredCount: input.ignoredCount,
  );
}

RedactionState _stateWithMetadataInput(
  RedactionState state,
  _MetadataInputSelection selection, {
  String? status,
}) {
  final output = selection.outputFor(state.exportFormat);
  return state.copyWith(
    metadataInputCount: selection.totalCount,
    metadataHasImages: selection.images.isNotEmpty,
    metadataHasPdfs: selection.pdfs.isNotEmpty,
    metadataInputLabel: selection.inputLabel,
    metadataInputDescription: selection.inputDescription,
    metadataOutputDirectoryPath: output.directoryPath,
    metadataOutputDirectoryDisplayName: output.displayName,
    status: status ?? state.status,
  );
}

RedactionState _stateWithoutMetadataInput(
  RedactionState state, {
  String? status,
}) {
  return state.copyWith(
    metadataInputCount: 0,
    metadataHasImages: false,
    metadataHasPdfs: false,
    metadataInputLabel: null,
    metadataInputDescription: null,
    metadataOutputDirectoryPath: null,
    metadataOutputDirectoryDisplayName: null,
    metadataCleanProgress: null,
    status: status ?? state.status,
  );
}

Future<RedactionState> _stateWithPreviewedMetadataOutput(
  RedactionState state,
  _MetadataInputSelection selection,
  FileChannelService service,
) async {
  final output = selection.outputFor(state.exportFormat);
  if (output.directoryPath != null) return state;

  final destination = await service.previewMetadataCleanDestination(
    automaticFolderName: output.automaticFolderName,
  );
  return state.copyWith(
    metadataOutputDirectoryPath: destination.directoryPath,
    metadataOutputDirectoryDisplayName: output.singleFileName == null
        ? destination.displayName
        : _joinPath(destination.displayName, output.singleFileName!),
  );
}

enum MetadataInputDisplayKind { image, pdf, folder }

class MetadataInputDisplayItem {
  const MetadataInputDisplayItem({
    required this.kind,
    required this.label,
    required this.detail,
  });

  final MetadataInputDisplayKind kind;
  final String label;
  final String detail;
}

class _MetadataInputSource {
  const _MetadataInputSource._({
    required this.kind,
    required this.displayLabel,
    required this.displayDetail,
    required this.identityKey,
    required this.images,
    required this.pdfs,
    this.ignoredCount = 0,
    this.singleOutputBaseName,
    this.singleOutputExtension,
    this.automaticOutputSubfolderName,
    this.photo = false,
    this.directoryPath,
  });

  factory _MetadataInputSource.image(
    MetadataInputImage image, {
    bool photo = false,
  }) {
    final sourceName =
        image.sourceName ?? _lastPathComponent(image.sourcePath ?? 'image');
    return _MetadataInputSource._(
      kind: MetadataInputDisplayKind.image,
      displayLabel: sourceName,
      displayDetail: image.sourcePath ?? (photo ? 'Photo library' : 'Image'),
      identityKey: 'image:${image.sourcePath ?? sourceName}',
      images: <MetadataInputImage>[image],
      pdfs: const <MetadataInputPdf>[],
      singleOutputBaseName: _preservedBaseName(sourceName) ?? 'image',
      photo: photo,
    );
  }

  factory _MetadataInputSource.pdf(MetadataInputPdf pdf) {
    final sourceName =
        pdf.sourceName ?? _lastPathComponent(pdf.sourcePath ?? 'document');
    return _MetadataInputSource._(
      kind: MetadataInputDisplayKind.pdf,
      displayLabel: sourceName,
      displayDetail: pdf.sourcePath ?? 'PDF',
      identityKey: 'pdf:${pdf.sourcePath ?? sourceName}',
      images: const <MetadataInputImage>[],
      pdfs: <MetadataInputPdf>[pdf],
      singleOutputBaseName: _preservedBaseName(sourceName) ?? 'document',
      singleOutputExtension: 'pdf',
    );
  }

  factory _MetadataInputSource.folder(MetadataPickedFolder folder) {
    final folderName = _lastPathComponent(folder.directoryPath);
    return _MetadataInputSource._(
      kind: MetadataInputDisplayKind.folder,
      displayLabel: folderName,
      displayDetail: _folderInputDescription(folder),
      identityKey: 'folder:${folder.directoryPath}',
      images: folder.images,
      pdfs: folder.pdfs,
      ignoredCount: folder.ignoredCount,
      automaticOutputSubfolderName: _safeOutputFolderName(
        '$folderName-metadata-removed',
      ),
      directoryPath: folder.directoryPath,
    );
  }

  final MetadataInputDisplayKind kind;
  final String displayLabel;
  final String displayDetail;
  final String identityKey;
  final List<MetadataInputImage> images;
  final List<MetadataInputPdf> pdfs;
  final int ignoredCount;
  final String? singleOutputBaseName;
  final String? singleOutputExtension;
  final String? automaticOutputSubfolderName;
  final bool photo;
  final String? directoryPath;

  MetadataInputDisplayItem get displayItem => MetadataInputDisplayItem(
    kind: kind,
    label: kind == MetadataInputDisplayKind.folder
        ? 'Folder: $displayLabel'
        : displayLabel,
    detail: displayDetail,
  );

  Iterable<String> get sourcePaths sync* {
    final folderPath = directoryPath;
    if (folderPath != null && folderPath.isNotEmpty) yield folderPath;
    for (final image in images) {
      final path = image.sourcePath;
      if (path != null && path.isNotEmpty) yield path;
    }
    for (final pdf in pdfs) {
      final path = pdf.sourcePath;
      if (path != null && path.isNotEmpty) yield path;
    }
  }
}

class _MetadataInputSelection {
  const _MetadataInputSelection._({
    required this.sources,
    required this.images,
    required this.pdfs,
    required this.inputLabel,
    required this.inputDescription,
    this.singleOutputBaseName,
    this.singleOutputExtension,
    this.automaticOutputSubfolderName,
    this.ignoredCount = 0,
    this.selectedDestination,
  });

  factory _MetadataInputSelection.fromSources(
    List<_MetadataInputSource> sources, {
    int extraIgnoredCount = 0,
    MetadataCleanDestination? selectedDestination,
  }) {
    final normalizedSources = _dedupeMetadataSources(sources);
    final images = <MetadataInputImage>[
      for (final source in normalizedSources) ...source.images,
    ];
    final pdfs = <MetadataInputPdf>[
      for (final source in normalizedSources) ...source.pdfs,
    ];
    final ignoredCount =
        extraIgnoredCount +
        normalizedSources.fold<int>(
          0,
          (total, source) => total + source.ignoredCount,
        );
    final singleSource = normalizedSources.length == 1
        ? normalizedSources.single
        : null;
    final sourceLabel = _metadataSourceSelectionLabel(
      sources: normalizedSources,
      images: images,
      pdfs: pdfs,
    );
    final sourceDescription = _metadataSourceSelectionDescription(
      sources: normalizedSources,
      images: images,
      pdfs: pdfs,
      ignoredCount: ignoredCount,
    );

    return _MetadataInputSelection._(
      sources: normalizedSources,
      images: images,
      pdfs: pdfs,
      inputLabel: sourceLabel,
      inputDescription: sourceDescription,
      singleOutputBaseName: singleSource?.singleOutputBaseName,
      singleOutputExtension: singleSource?.singleOutputExtension,
      automaticOutputSubfolderName: singleSource?.automaticOutputSubfolderName,
      ignoredCount: ignoredCount,
      selectedDestination: selectedDestination,
    );
  }

  final List<_MetadataInputSource> sources;
  final List<MetadataInputImage> images;
  final List<MetadataInputPdf> pdfs;
  final String inputLabel;
  final String inputDescription;
  final String? singleOutputBaseName;
  final String? singleOutputExtension;
  final String? automaticOutputSubfolderName;
  final int ignoredCount;
  final MetadataCleanDestination? selectedDestination;
  int get totalCount => images.length + pdfs.length;
  bool get isEmpty => totalCount == 0;
  bool get hasFolderInput =>
      sources.any((source) => source.kind == MetadataInputDisplayKind.folder);
  bool get canSaveImagesToPhotos =>
      images.isNotEmpty && pdfs.isEmpty && !hasFolderInput;
  List<MetadataInputDisplayItem> get displayItems => <MetadataInputDisplayItem>[
    for (final source in sources) source.displayItem,
  ];
  Iterable<String> get sourcePaths sync* {
    for (final source in sources) {
      yield* source.sourcePaths;
    }
  }

  _MetadataInputSelection withSelectedDestination(
    MetadataCleanDestination destination,
  ) {
    return _MetadataInputSelection.fromSources(
      sources,
      extraIgnoredCount: ignoredCount - _sourceIgnoredCount(sources),
      selectedDestination: destination,
    );
  }

  _MetadataInputSelection appendFilesFrom(_MetadataInputSelection selection) {
    final addedFileSources = selection.sources.where(
      (source) => source.kind != MetadataInputDisplayKind.folder,
    );
    return _MetadataInputSelection.fromSources(
      <_MetadataInputSource>[...sources, ...addedFileSources],
      extraIgnoredCount:
          ignoredCount -
          _sourceIgnoredCount(sources) +
          selection.ignoredCount -
          _sourceIgnoredCount(selection.sources),
      selectedDestination: selectedDestination,
    );
  }

  _MetadataInputSelection? removingSourceAt(int index) {
    final nextSources = <_MetadataInputSource>[...sources]..removeAt(index);
    if (nextSources.isEmpty) return null;
    return _MetadataInputSelection.fromSources(
      nextSources,
      extraIgnoredCount: ignoredCount - _sourceIgnoredCount(sources),
      selectedDestination: selectedDestination,
    );
  }

  _MetadataResolvedOutput outputFor(ExportFormat format) {
    final rootPath = selectedDestination?.directoryPath;
    final rootDisplayName = selectedDestination?.displayName ?? 'Cleaned';
    final subfolderName = automaticOutputSubfolderName;
    final directoryPath = subfolderName == null
        ? rootPath
        : rootPath == null
        ? null
        : _joinPath(rootPath, subfolderName);
    final directoryDisplayName = subfolderName == null
        ? rootDisplayName
        : _joinPath(rootDisplayName, subfolderName);
    final baseName = singleOutputBaseName;
    if (baseName == null) {
      return _MetadataResolvedOutput(
        directoryPath: directoryPath,
        directoryDisplayName: directoryDisplayName,
        displayName: directoryDisplayName,
        automaticFolderName: directoryPath == null ? subfolderName : null,
      );
    }

    final extension = singleOutputExtension ?? format.extension;
    final fileName = '$baseName-metadata-removed.$extension';
    return _MetadataResolvedOutput(
      directoryPath: directoryPath,
      directoryDisplayName: directoryDisplayName,
      displayName: _joinPath(directoryDisplayName, fileName),
      singleFileName: fileName,
      automaticFolderName: null,
    );
  }
}

List<_MetadataInputSource> _dedupeMetadataSources(
  List<_MetadataInputSource> sources,
) {
  final seen = <String>{};
  final deduped = <_MetadataInputSource>[];
  var hasFolder = false;
  for (final source in sources) {
    if (source.kind == MetadataInputDisplayKind.folder) {
      if (hasFolder) continue;
      hasFolder = true;
    }
    if (!seen.add(source.identityKey)) continue;
    deduped.add(source);
  }
  return deduped;
}

int _sourceIgnoredCount(List<_MetadataInputSource> sources) {
  return sources.fold<int>(0, (total, source) => total + source.ignoredCount);
}

String _metadataSourceSelectionLabel({
  required List<_MetadataInputSource> sources,
  required List<MetadataInputImage> images,
  required List<MetadataInputPdf> pdfs,
}) {
  if (sources.length == 1) {
    final source = sources.single;
    return switch (source.kind) {
      MetadataInputDisplayKind.folder => 'Folder: ${source.displayLabel}',
      MetadataInputDisplayKind.image => source.photo ? '1 photo' : '1 image',
      MetadataInputDisplayKind.pdf => '1 PDF',
    };
  }

  final imageCount = images.length;
  final pdfCount = pdfs.length;
  if (pdfCount == 0) {
    final allPhotos = sources.every((source) => source.photo);
    final noun = allPhotos ? 'photo' : 'image';
    return '$imageCount $noun${imageCount == 1 ? '' : 's'}';
  }
  if (imageCount == 0) return '$pdfCount PDF${pdfCount == 1 ? '' : 's'}';

  final fileCount = imageCount + pdfCount;
  return '$fileCount file${fileCount == 1 ? '' : 's'}';
}

String _metadataSourceSelectionDescription({
  required List<_MetadataInputSource> sources,
  required List<MetadataInputImage> images,
  required List<MetadataInputPdf> pdfs,
  required int ignoredCount,
}) {
  if (sources.length == 1) return sources.single.displayDetail;

  if (pdfs.isEmpty && ignoredCount == 0) return _inputPreview(images);
  if (images.isEmpty && ignoredCount == 0) return _pdfInputPreview(pdfs);

  final imageCount = images.length;
  final pdfCount = pdfs.length;
  final parts = <String>[
    if (imageCount > 0) '$imageCount image${imageCount == 1 ? '' : 's'}',
    if (pdfCount > 0) '$pdfCount PDF${pdfCount == 1 ? '' : 's'}',
    if (ignoredCount > 0) '$ignoredCount ignored',
  ];
  return parts.join(', ');
}

class _MetadataResolvedOutput {
  const _MetadataResolvedOutput({
    required this.directoryPath,
    required this.directoryDisplayName,
    required this.displayName,
    this.singleFileName,
    this.automaticFolderName,
  });

  final String? directoryPath;
  final String directoryDisplayName;
  final String displayName;
  final String? singleFileName;
  final String? automaticFolderName;

  bool get isSingleFile => singleFileName != null;
}

String _redactedExportFileName(RedactionState snapshot) {
  if (snapshot.preserveRedactionExportFileName) {
    final preservedBaseName = _preservedBaseName(snapshot.sourceFileName);
    if (preservedBaseName != null) {
      return '$preservedBaseName.${snapshot.exportFormat.extension}';
    }
  }

  return snapshot.exportFormat.defaultFileName;
}

String _pdfExportFileName(RedactionState snapshot, {required bool redacted}) {
  if (snapshot.preservePdfExportFileName) {
    final preservedBaseName = _preservedBaseName(snapshot.pdfSourceFileName);
    if (preservedBaseName != null) {
      return '$preservedBaseName.pdf';
    }
  }

  return redacted ? 'redacted-clean.pdf' : 'metadata-clean.pdf';
}

String _metadataCleanPdfFileName({
  required String? sourceName,
  required bool preserveFileName,
}) {
  if (preserveFileName) {
    final preservedBaseName = _preservedBaseName(sourceName);
    if (preservedBaseName != null) return '$preservedBaseName.pdf';
  }

  return 'metadata-clean.pdf';
}

String _metadataCleanPdfBatchFileName({
  required int index,
  required int total,
  required String? sourceName,
  required bool preserveFileNames,
  required Set<String> usedFileNames,
}) {
  if (preserveFileNames) {
    final preservedBaseName = _preservedBaseName(sourceName);
    if (preservedBaseName != null) {
      return _uniqueFileName('$preservedBaseName.pdf', usedFileNames);
    }
  }

  final width = math.max(3, total.toString().length);
  final number = (index + 1).toString().padLeft(width, '0');
  return _uniqueFileName('metadata-clean-$number.pdf', usedFileNames);
}

Map<int, List<RedactionRegion>> _pdfRedactionsWithPage(
  Map<int, List<RedactionRegion>> source,
  int pageNumber,
  List<RedactionRegion> redactions,
) {
  final updated = <int, List<RedactionRegion>>{
    for (final entry in source.entries)
      entry.key: List<RedactionRegion>.unmodifiable(entry.value),
  };

  if (redactions.isEmpty) {
    updated.remove(pageNumber);
  } else {
    updated[pageNumber] = List<RedactionRegion>.unmodifiable(redactions);
  }

  return Map<int, List<RedactionRegion>>.unmodifiable(updated);
}

String _metadataCleanBatchFileName({
  required int index,
  required int total,
  required ExportFormat format,
  required String? sourceName,
  required bool preserveFileNames,
  required Set<String> usedFileNames,
}) {
  if (preserveFileNames) {
    final preservedBaseName = _preservedBaseName(sourceName);
    if (preservedBaseName != null) {
      return _uniqueFileName(
        '$preservedBaseName.${format.extension}',
        usedFileNames,
      );
    }
  }

  final width = math.max(3, total.toString().length);
  final number = (index + 1).toString().padLeft(width, '0');
  return _uniqueFileName(
    'metadata-clean-$number.${format.extension}',
    usedFileNames,
  );
}

String _metadataCleanBatchStatus({
  required int savedCount,
  required int failedCount,
  required int ignoredCount,
  required String destinationName,
  required String? firstFailure,
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
    return firstFailure == null
        ? 'Could not clean metadata for selected files$detailText'
        : 'Could not clean metadata: $firstFailure$detailText';
  }

  final fileLabel = savedCount == 1 ? 'file' : 'files';
  if (failedCount == 0) {
    return 'Success: cleaned metadata for $savedCount $fileLabel to $destinationName$detailText';
  }

  return 'Cleaned metadata for $savedCount $fileLabel to $destinationName$detailText';
}

String _metadataOutputFileSystemStatus({
  required FileSystemException error,
  required bool automaticOutput,
  required String? outputPath,
}) {
  final path = outputPath ?? error.path;
  if (automaticOutput && path != null) {
    return 'Could not create output folder: macOS sandbox did not allow the planned output location. Use Output > Choose Folder and select or create $path.';
  }

  if (path != null) {
    return 'Could not create output folder: $path. Choose another output folder.';
  }

  return 'Could not create output folder. Choose another output folder.';
}

String _metadataInputName(MetadataInputImage image, int index) {
  final sourceName = image.sourceName;
  if (sourceName != null && sourceName.trim().isNotEmpty) {
    return sourceName.trim();
  }

  final sourcePath = image.sourcePath;
  if (sourcePath != null && sourcePath.trim().isNotEmpty) {
    return _lastPathComponent(sourcePath);
  }

  return 'image ${index + 1}';
}

String _metadataPdfInputName(MetadataInputPdf pdf, int index) {
  final sourceName = pdf.sourceName;
  if (sourceName != null && sourceName.trim().isNotEmpty) {
    return sourceName.trim();
  }

  final sourcePath = pdf.sourcePath;
  if (sourcePath != null && sourcePath.trim().isNotEmpty) {
    return _lastPathComponent(sourcePath);
  }

  return 'PDF ${index + 1}';
}

String _friendlyError(Object error) {
  final message = error is FormatException
      ? error.message
      : error.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
  final trimmed = message.trim();
  if (trimmed.isEmpty) return 'Unknown error';
  return trimmed;
}

ExportFormat? _detectSourceFormat(Uint8List bytes, String? sourceName) {
  if (_hasPngSignature(bytes)) return ExportFormat.png;
  if (_hasJpegSignature(bytes)) return ExportFormat.jpeg;

  final extension = _extension(sourceName ?? '');
  return switch (extension) {
    'png' => ExportFormat.png,
    'jpg' || 'jpeg' => ExportFormat.jpeg,
    _ => null,
  };
}

bool _hasPngSignature(Uint8List bytes) {
  const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < signature.length) return false;
  for (var index = 0; index < signature.length; index += 1) {
    if (bytes[index] != signature[index]) return false;
  }
  return true;
}

bool _hasJpegSignature(Uint8List bytes) {
  return bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8;
}

String _inputPreview(List<MetadataInputImage> images) {
  final names = images
      .map(
        (image) =>
            image.sourceName ?? _lastPathComponent(image.sourcePath ?? ''),
      )
      .where((name) => name.isNotEmpty)
      .take(2)
      .toList();
  if (names.isEmpty) return '${images.length} selected';
  if (images.length <= names.length) return names.join(', ');
  return '${names.join(', ')} and ${images.length - names.length} more';
}

String _pdfInputPreview(List<MetadataInputPdf> pdfs) {
  final names = pdfs
      .map((pdf) => pdf.sourceName ?? _lastPathComponent(pdf.sourcePath ?? ''))
      .where((name) => name.isNotEmpty)
      .take(2)
      .toList();
  if (names.isEmpty) return '${pdfs.length} selected';
  if (pdfs.length <= names.length) return names.join(', ');
  return '${names.join(', ')} and ${pdfs.length - names.length} more';
}

String _folderInputDescription(MetadataPickedFolder folder) {
  final imageCount = folder.images.length;
  final pdfCount = folder.pdfs.length;
  final imageLabel = imageCount == 1 ? 'image' : 'images';
  final pdfLabel = pdfCount == 1 ? 'PDF' : 'PDFs';
  final parts = <String>[
    if (imageCount > 0) '$imageCount $imageLabel',
    if (pdfCount > 0) '$pdfCount $pdfLabel',
    if (folder.ignoredCount > 0) '${folder.ignoredCount} ignored',
  ];

  return parts.isEmpty ? 'No supported files' : parts.join(', ');
}

String _lastPathComponent(String path) {
  final normalized = path.replaceAll(r'\', '/').replaceAll(RegExp(r'/+$'), '');
  final slash = normalized.lastIndexOf('/');
  if (slash < 0) return normalized;
  return normalized.substring(slash + 1);
}

String _safeOutputFolderName(String name) {
  final safeName = name
      .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1F]+'), '-')
      .replaceAll(RegExp(r'^\.+'), '')
      .trim();
  return safeName.isEmpty ? 'metadata-removed' : safeName;
}

String _joinPath(String directory, String name) {
  if (directory.isEmpty) return name;
  if (directory == '/') return '/$name';
  if (directory.endsWith('/')) return '$directory$name';
  return '$directory/$name';
}

String _extension(String name) {
  final fileName = _lastPathComponent(name).toLowerCase();
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return '';
  return fileName.substring(dot + 1);
}

String? _preservedBaseName(String? sourceName) {
  if (sourceName == null) return null;

  final fileName = sourceName.split(RegExp(r'[/\\]+')).last.trim();
  if (fileName.isEmpty) return null;

  final dot = fileName.lastIndexOf('.');
  final rawBaseName = dot > 0 ? fileName.substring(0, dot) : fileName;
  final safeBaseName = rawBaseName
      .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1F]+'), '-')
      .replaceAll(RegExp(r'^\.+'), '')
      .trim();
  if (safeBaseName.isEmpty) return null;

  return safeBaseName;
}

String _uniqueFileName(String desiredName, Set<String> usedFileNames) {
  final dot = desiredName.lastIndexOf('.');
  final baseName = dot > 0 ? desiredName.substring(0, dot) : desiredName;
  final extension = dot > 0 ? desiredName.substring(dot) : '';
  var candidate = desiredName;
  var suffix = 2;

  while (!usedFileNames.add(candidate.toLowerCase())) {
    candidate = '$baseName-$suffix$extension';
    suffix += 1;
  }

  return candidate;
}
