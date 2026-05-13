import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/file_channel_service.dart';
import '../data/jpeg_metadata.dart';
import '../data/png_metadata.dart';
import '../domain/export_format.dart';
import '../domain/jpeg_quality_preset.dart';
import '../domain/redaction_region.dart';
import '../domain/redaction_state.dart';

part 'redaction_controller.g.dart';

@riverpod
class RedactionController extends _$RedactionController {
  ui.Image? _ownedImage;
  _MetadataInputSelection? _metadataInputSelection;

  @override
  RedactionState build() {
    ref.onDispose(() {
      _ownedImage?.dispose();
      _ownedImage = null;
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
        return _multiFileMetadataInput(images);
      },
    );
  }

  Future<void> chooseMetadataFolder() async {
    await _chooseMetadataInput(
      choosingStatus: 'Choosing image folder',
      emptyStatus: 'No supported images found in that folder',
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

      if (selection.images.isEmpty) {
        state = state.copyWith(isOpening: false, status: emptyStatus);
        return;
      }

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
    if (selection == null || selection.images.isEmpty) {
      state = state.copyWith(status: 'Choose metadata input first');
      return;
    }

    final output = selection.outputFor(state.exportFormat);
    final service = ref.read(fileChannelServiceProvider);
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
      final preserveFileNames = snapshot.preserveMetadataCleanFileNames;
      final usedFileNames = <String>{};
      var savedCount = 0;
      var failedCount = 0;
      String? firstFailure;
      String? lastSavedPath;

      for (var index = 0; index < selection.images.length; index += 1) {
        if (!ref.mounted) return;
        final image = selection.images[index];
        final imageLabel = _metadataInputName(image, index);
        state = state.copyWith(
          metadataCleanProgress: index / selection.images.length,
          status:
              'Cleaning $imageLabel (${index + 1}/${selection.images.length})',
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
                  index: index,
                  total: selection.images.length,
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
          if (ref.mounted) {
            state = state.copyWith(
              metadataCleanProgress: (index + 1) / selection.images.length,
            );
          }
        }
      }

      if (!ref.mounted) return;
      state = state.copyWith(
        metadataCleanProgress: null,
        status: _metadataCleanBatchStatus(
          savedCount: savedCount,
          failedCount: failedCount,
          ignoredCount: selection.ignoredCount,
          destinationName: output.isSingleFile && lastSavedPath != null
              ? lastSavedPath
              : destination.displayName,
          firstFailure: firstFailure,
        ),
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

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

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

  void setPreserveRedactionExportFileName(bool preserve) {
    state = state.copyWith(preserveRedactionExportFileName: preserve);
  }

  void setPreserveMetadataCleanFileNames(bool preserve) {
    state = state.copyWith(preserveMetadataCleanFileNames: preserve);
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

  void beginRedaction(Offset localPosition, Rect imageRect) {
    final image = state.image;
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

_MetadataInputSelection _singleFileMetadataInput(MetadataInputImage image) {
  final sourceName =
      image.sourceName ?? _lastPathComponent(image.sourcePath ?? 'image');
  final baseName = _preservedBaseName(sourceName) ?? 'image';

  return _MetadataInputSelection(
    images: <MetadataInputImage>[image],
    inputLabel: '1 image',
    inputDescription: sourceName,
    defaultOutputDirectoryPath: null,
    defaultOutputDirectoryDisplayName: 'Cleaned',
    singleOutputBaseName: baseName,
  );
}

_MetadataInputSelection _multiFileMetadataInput(
  List<MetadataInputImage> images,
) {
  return _MetadataInputSelection(
    images: images,
    inputLabel: '${images.length} image${images.length == 1 ? '' : 's'}',
    inputDescription: _inputPreview(images),
    defaultOutputDirectoryPath: null,
    defaultOutputDirectoryDisplayName: 'Cleaned',
  );
}

_MetadataInputSelection _folderMetadataInput(MetadataPickedFolder folder) {
  final folderName = _lastPathComponent(folder.directoryPath);
  final outputFolderName = _safeOutputFolderName(
    '$folderName-metadata-removed',
  );

  return _MetadataInputSelection(
    images: folder.images,
    inputLabel: 'Folder: $folderName',
    inputDescription: _folderInputDescription(folder),
    defaultOutputDirectoryPath: null,
    defaultOutputDirectoryDisplayName: 'Cleaned',
    automaticOutputSubfolderName: outputFolderName,
    ignoredCount: folder.ignoredCount,
  );
}

_MetadataInputSelection _photosMetadataInput(List<MetadataInputImage> images) {
  return _MetadataInputSelection(
    images: images,
    inputLabel: '${images.length} photo${images.length == 1 ? '' : 's'}',
    inputDescription: _inputPreview(images),
    defaultOutputDirectoryPath: null,
    defaultOutputDirectoryDisplayName: 'Cleaned',
  );
}

RedactionState _stateWithMetadataInput(
  RedactionState state,
  _MetadataInputSelection selection, {
  String? status,
}) {
  final output = selection.outputFor(state.exportFormat);
  return state.copyWith(
    metadataInputCount: selection.images.length,
    metadataInputLabel: selection.inputLabel,
    metadataInputDescription: selection.inputDescription,
    metadataOutputDirectoryPath: output.directoryPath,
    metadataOutputDirectoryDisplayName: output.displayName,
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

class _MetadataInputSelection {
  const _MetadataInputSelection({
    required this.images,
    required this.inputLabel,
    required this.inputDescription,
    required this.defaultOutputDirectoryPath,
    required this.defaultOutputDirectoryDisplayName,
    this.singleOutputBaseName,
    this.automaticOutputSubfolderName,
    this.ignoredCount = 0,
    this.selectedDestination,
  });

  final List<MetadataInputImage> images;
  final String inputLabel;
  final String inputDescription;
  final String? defaultOutputDirectoryPath;
  final String defaultOutputDirectoryDisplayName;
  final String? singleOutputBaseName;
  final String? automaticOutputSubfolderName;
  final int ignoredCount;
  final MetadataCleanDestination? selectedDestination;

  _MetadataInputSelection withSelectedDestination(
    MetadataCleanDestination destination,
  ) {
    return _MetadataInputSelection(
      images: images,
      inputLabel: inputLabel,
      inputDescription: inputDescription,
      defaultOutputDirectoryPath: defaultOutputDirectoryPath,
      defaultOutputDirectoryDisplayName: defaultOutputDirectoryDisplayName,
      singleOutputBaseName: singleOutputBaseName,
      automaticOutputSubfolderName: automaticOutputSubfolderName,
      ignoredCount: ignoredCount,
      selectedDestination: destination,
    );
  }

  _MetadataResolvedOutput outputFor(ExportFormat format) {
    final rootPath =
        selectedDestination?.directoryPath ?? defaultOutputDirectoryPath;
    final rootDisplayName =
        selectedDestination?.displayName ?? defaultOutputDirectoryDisplayName;
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

    final fileName = '$baseName-metadata-removed.${format.extension}';
    return _MetadataResolvedOutput(
      directoryPath: directoryPath,
      directoryDisplayName: directoryDisplayName,
      displayName: _joinPath(directoryDisplayName, fileName),
      singleFileName: fileName,
      automaticFolderName: null,
    );
  }
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
        ? 'Could not clean metadata for selected images$detailText'
        : 'Could not clean metadata: $firstFailure$detailText';
  }

  final imageLabel = savedCount == 1 ? 'image' : 'images';
  if (failedCount == 0) {
    return 'Success: cleaned metadata for $savedCount $imageLabel to $destinationName$detailText';
  }

  return 'Cleaned metadata for $savedCount $imageLabel to $destinationName$detailText';
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

String _folderInputDescription(MetadataPickedFolder folder) {
  final imageCount = folder.images.length;
  final imageLabel = imageCount == 1 ? 'image' : 'images';
  if (folder.ignoredCount == 0) {
    return '$imageCount $imageLabel';
  }

  return '$imageCount $imageLabel, ${folder.ignoredCount} ignored';
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
