import 'dart:io';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

import '../domain/export_format.dart';

part 'file_channel_service.g.dart';

class FileChannelService {
  FileChannelService();

  Future<Uint8List?> openImageBytes() async {
    final file = await file_selector.openFile(
      acceptedTypeGroups: _imageTypeGroups,
      confirmButtonText: 'Open',
    );
    return file?.readAsBytes();
  }

  Future<Uint8List?> openPhotoLibraryBytes() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );

    if (file == null) return null;

    final bytes = await file.readAsBytes();
    await _deleteIfInsideAppCache(file.path);
    return bytes;
  }

  Future<String?> saveImage({
    required String name,
    required Uint8List bytes,
    required ExportFormat format,
  }) async {
    if (!_supportsSaveLocation) {
      return shareImage(name: name, bytes: bytes, format: format);
    }

    final destination = await file_selector.getSaveLocation(
      acceptedTypeGroups: <file_selector.XTypeGroup>[_exportTypeGroup(format)],
      suggestedName: name,
      confirmButtonText: 'Save',
      canCreateDirectories: true,
    );
    if (destination == null) return null;

    await share_plus.XFile.fromData(
      bytes,
      mimeType: format.mimeType,
      name: name,
    ).saveTo(destination.path);

    return destination.path;
  }

  Future<String?> shareImage({
    required String name,
    required Uint8List bytes,
    required ExportFormat format,
  }) async {
    final file = await _writeTemporaryCleanImage(
      name: name,
      bytes: bytes,
      format: format,
    );

    try {
      final result = await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          files: <share_plus.XFile>[file],
          fileNameOverrides: <String>[name],
          title: 'Share clean image',
        ),
      );

      if (result.status == share_plus.ShareResultStatus.dismissed) {
        return null;
      }

      return file.path;
    } finally {
      await _deleteFileIfExists(file.path);
    }
  }

  Future<String> saveImageToPhotos({
    required String name,
    required Uint8List bytes,
  }) async {
    await Gal.putImageBytes(bytes, name: _basenameWithoutExtension(name));
    return 'Photos';
  }

  Future<share_plus.XFile> _writeTemporaryCleanImage({
    required String name,
    required Uint8List bytes,
    required ExportFormat format,
  }) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final baseName = _basenameWithoutExtension(name);
    final fileName = '$baseName-$timestamp.${format.extension}';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    return share_plus.XFile(file.path, mimeType: format.mimeType, name: name);
  }
}

@riverpod
FileChannelService fileChannelService(Ref ref) {
  return FileChannelService();
}

const _imageTypeGroups = <file_selector.XTypeGroup>[
  file_selector.XTypeGroup(
    label: 'Images',
    extensions: <String>['png', 'jpg', 'jpeg', 'webp', 'bmp'],
    mimeTypes: <String>['image/png', 'image/jpeg', 'image/webp', 'image/bmp'],
    uniformTypeIdentifiers: <String>[
      'public.png',
      'public.jpeg',
      'org.webmproject.webp',
      'com.microsoft.bmp',
    ],
    webWildCards: <String>['image/*'],
  ),
];

file_selector.XTypeGroup _exportTypeGroup(ExportFormat format) {
  return file_selector.XTypeGroup(
    label: format.label,
    extensions: <String>[format.extension],
    mimeTypes: <String>[format.mimeType],
    uniformTypeIdentifiers: <String>[format.uniformTypeIdentifier],
  );
}

Future<void> _deleteIfInsideAppCache(String path) async {
  if (path.isEmpty) return;

  final roots = <Directory>[];
  try {
    roots.add(await getTemporaryDirectory());
  } catch (_) {
    // Ignore cleanup failures; the OS can still clear temporary files later.
  }
  try {
    roots.add(await getApplicationCacheDirectory());
  } catch (_) {
    // Not every platform exposes a separate app cache directory.
  }

  final file = File(path).absolute;
  final filePath = file.path;
  for (final root in roots) {
    final rootPath = root.absolute.path;
    if (filePath == rootPath || filePath.startsWith('$rootPath/')) {
      await _deleteFileIfExists(filePath);
      return;
    }
  }
}

Future<void> _deleteFileIfExists(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // Cleanup is best-effort and should not turn a successful user action into
    // an error.
  }
}

bool get _supportsSaveLocation {
  if (kIsWeb) return false;

  return switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.iOS => false,
  };
}

String _basenameWithoutExtension(String name) {
  final safeName = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
  final dot = safeName.lastIndexOf('.');
  if (dot <= 0) return safeName;
  return safeName.substring(0, dot);
}
