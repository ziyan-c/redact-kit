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

    return file?.readAsBytes();
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
