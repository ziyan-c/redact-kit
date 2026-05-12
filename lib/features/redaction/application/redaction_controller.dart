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

  @override
  RedactionState build() {
    ref.onDispose(() {
      _ownedImage?.dispose();
      _ownedImage = null;
    });

    return const RedactionState();
  }

  Future<void> openImage() async {
    await _openImageBytes(
      status: 'Opening image',
      loadBytes: () => ref.read(fileChannelServiceProvider).openImageBytes(),
    );
  }

  Future<void> openPhotoLibrary() async {
    await _openImageBytes(
      status: 'Opening photo library',
      loadBytes: () =>
          ref.read(fileChannelServiceProvider).openPhotoLibraryBytes(),
    );
  }

  Future<void> _openImageBytes({
    required String status,
    required Future<Uint8List?> Function() loadBytes,
  }) async {
    if (state.isOpening) return;

    state = state.copyWith(isOpening: true, status: status);

    try {
      final bytes = await loadBytes();
      if (!ref.mounted) return;

      if (bytes == null) {
        state = state.copyWith(status: 'Ready');
        return;
      }

      final decoded = await _decodeImage(bytes);
      if (!ref.mounted) {
        decoded.dispose();
        return;
      }

      final previous = state.image;
      _ownedImage = decoded;
      state = state.copyWith(
        image: decoded,
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
      successStatus: (snapshot) =>
          'Exported clean ${snapshot.exportFormat.label} with ${snapshot.redactions.length} redaction${snapshot.redactions.length == 1 ? '' : 's'}',
      action: (service, snapshot, name, bytes) => service.saveImage(
        name: name,
        bytes: bytes,
        format: snapshot.exportFormat,
      ),
    );
  }

  Future<void> shareImage() async {
    await _exportCleanImage(
      progressStatus: 'Preparing clean ${state.exportFormat.label} to share',
      canceledStatus: 'Share canceled',
      successStatus: (snapshot) =>
          'Shared clean ${snapshot.exportFormat.label}',
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
      action: (service, snapshot, name, bytes) =>
          service.saveImageToPhotos(name: name, bytes: bytes),
    );
  }

  Future<void> _exportCleanImage({
    required String progressStatus,
    required String canceledStatus,
    required String Function(RedactionState snapshot) successStatus,
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
      final bytes = await _renderCleanImage(
        image: image,
        redactions: snapshot.redactions,
        format: snapshot.exportFormat,
        jpegQualityPreset: snapshot.jpegQualityPreset,
      );
      if (!ref.mounted) return;

      final result = await action(
        ref.read(fileChannelServiceProvider),
        snapshot,
        snapshot.exportFormat.defaultFileName,
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
    state = state.copyWith(exportFormat: format);
  }

  void setJpegQualityPreset(JpegQualityPreset preset) {
    state = state.copyWith(jpegQualityPreset: preset);
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
