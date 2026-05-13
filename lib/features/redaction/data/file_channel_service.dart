import 'dart:io';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

import '../domain/export_format.dart';

part 'file_channel_service.g.dart';

class FileChannelService {
  FileChannelService();

  static const _channel = MethodChannel('app.redactkit/files');

  Future<Uint8List?> openImageBytes() async {
    return (await openImageFile())?.bytes;
  }

  Future<PickedImageBytes?> openImageFile() async {
    final file = await file_selector.openFile(
      acceptedTypeGroups: _imageTypeGroups,
      confirmButtonText: 'Open',
    );
    if (file == null) return null;

    return PickedImageBytes(
      bytes: await file.readAsBytes(),
      sourceName: file.name,
      sourcePath: file.path,
    );
  }

  Future<Uint8List?> openPhotoLibraryBytes() async {
    return (await openPhotoLibraryImage())?.bytes;
  }

  Future<PickedImageBytes?> openPhotoLibraryImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );

    if (file == null) return null;

    final bytes = await file.readAsBytes();
    await _deleteIfInsideAppCache(file.path);
    return PickedImageBytes(bytes: bytes, sourceName: file.name);
  }

  Future<List<PickedImageBytes>> openImageFilesBytes() async {
    final files = await file_selector.openFiles(
      acceptedTypeGroups: _imageTypeGroups,
      confirmButtonText: 'Choose',
    );

    final images = <PickedImageBytes>[];
    for (final file in files) {
      images.add(
        PickedImageBytes(
          bytes: await file.readAsBytes(),
          sourceName: file.name,
          sourcePath: file.path,
        ),
      );
    }

    return images;
  }

  Future<List<PickedImageBytes>> openPhotoLibraryImagesBytes() async {
    final files = await ImagePicker().pickMultiImage(
      requestFullMetadata: false,
    );

    final images = <PickedImageBytes>[];
    for (final file in files) {
      images.add(
        PickedImageBytes(
          bytes: await file.readAsBytes(),
          sourceName: file.name,
        ),
      );
      await _deleteIfInsideAppCache(file.path);
    }

    return images;
  }

  Future<MetadataInputImage?> chooseMetadataImageFile() async {
    final file = await file_selector.openFile(
      acceptedTypeGroups: _imageTypeGroups,
      confirmButtonText: 'Choose',
    );
    if (file == null) return null;

    if (!_supportsDirectoryPicker) {
      return MetadataInputImage(
        bytes: await file.readAsBytes(),
        sourceName: file.name,
      );
    }

    return MetadataInputImage(sourceName: file.name, sourcePath: file.path);
  }

  Future<List<MetadataInputImage>> chooseMetadataImageFiles() async {
    final files = await file_selector.openFiles(
      acceptedTypeGroups: _imageTypeGroups,
      confirmButtonText: 'Choose',
    );

    final images = <MetadataInputImage>[];
    for (final file in files) {
      images.add(
        _supportsDirectoryPicker
            ? MetadataInputImage(sourceName: file.name, sourcePath: file.path)
            : MetadataInputImage(
                bytes: await file.readAsBytes(),
                sourceName: file.name,
              ),
      );
    }

    return images;
  }

  Future<MetadataPickedFolder?> chooseMetadataImageFolder() async {
    if (!_supportsDirectoryPicker) return null;

    final path = await file_selector.getDirectoryPath(
      confirmButtonText: 'Choose Folder',
    );
    if (path == null) return null;

    final directory = Directory(path);
    final images = <MetadataInputImage>[];
    var ignoredCount = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !_isSupportedImagePath(entity.path)) {
        ignoredCount += 1;
        continue;
      }

      images.add(
        MetadataInputImage(
          sourceName: _lastPathComponent(entity.path),
          sourcePath: entity.path,
        ),
      );
    }

    images.sort((a, b) {
      final left = (a.sourceName ?? '').toLowerCase();
      final right = (b.sourceName ?? '').toLowerCase();
      return left.compareTo(right);
    });

    return MetadataPickedFolder(
      directoryPath: directory.absolute.path,
      displayName: directory.absolute.path,
      images: images,
      ignoredCount: ignoredCount,
    );
  }

  Future<List<MetadataInputImage>> chooseMetadataPhotoImages() async {
    final files = await ImagePicker().pickMultiImage(
      requestFullMetadata: false,
    );

    final images = <MetadataInputImage>[];
    for (final file in files) {
      images.add(
        MetadataInputImage(
          bytes: await file.readAsBytes(),
          sourceName: file.name,
        ),
      );
      await _deleteIfInsideAppCache(file.path);
    }

    return images;
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

  Future<MetadataCleanDestination?> chooseMetadataCleanOutputDirectory() async {
    if (_supportsDirectoryPicker) {
      final path = await file_selector.getDirectoryPath(
        confirmButtonText: 'Use Folder',
        canCreateDirectories: true,
      );
      if (path == null) return null;

      return MetadataCleanDestination(directoryPath: path, displayName: path);
    }

    return null;
  }

  Future<MetadataCleanDestination> createMetadataCleanDestination({
    required List<MetadataInputImage> images,
    MetadataCleanDestination? selectedDestination,
    String? automaticFolderName,
  }) async {
    if (selectedDestination != null) {
      final directory = await Directory(
        selectedDestination.directoryPath,
      ).create(recursive: true);
      return MetadataCleanDestination(
        directoryPath: directory.path,
        displayName: selectedDestination.displayName,
      );
    }

    final destination = await previewMetadataCleanDestination(
      automaticFolderName: automaticFolderName,
    );
    final directory = await Directory(
      destination.directoryPath,
    ).create(recursive: true);
    return MetadataCleanDestination(
      directoryPath: directory.path,
      displayName: destination.displayName,
    );
  }

  Future<MetadataCleanDestination> previewMetadataCleanDestination({
    String? automaticFolderName,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final cleanedDirectory = Directory('${documents.path}/Cleaned');
    final outputFolderName = automaticFolderName;
    final directoryPath = outputFolderName == null
        ? cleanedDirectory.path
        : '${cleanedDirectory.path}/${_safeFolderName(outputFolderName)}';
    return MetadataCleanDestination(
      directoryPath: directoryPath,
      displayName: outputFolderName == null
          ? 'Cleaned'
          : 'Cleaned/${_lastPathComponent(directoryPath)}',
    );
  }

  Future<String> saveMetadataCleanImage({
    required MetadataCleanDestination destination,
    required String name,
    required Uint8List bytes,
  }) async {
    final file = await _uniqueFile('${destination.directoryPath}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> openDirectory(String path) async {
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      throw PlatformException(
        code: 'unsupported_platform',
        message: 'Opening output folders is only available on macOS.',
      );
    }

    final directory = await Directory(path).create(recursive: true);
    await _channel.invokeMethod<void>('openDirectory', <String, Object?>{
      'path': directory.path,
    });
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

class PickedImageBytes {
  const PickedImageBytes({
    required this.bytes,
    this.sourceName,
    this.sourcePath,
  });

  final Uint8List bytes;
  final String? sourceName;
  final String? sourcePath;
}

class MetadataInputImage {
  const MetadataInputImage({this.bytes, this.sourceName, this.sourcePath});

  final Uint8List? bytes;
  final String? sourceName;
  final String? sourcePath;

  Future<Uint8List> readBytes() async {
    final inMemoryBytes = bytes;
    if (inMemoryBytes != null) return inMemoryBytes;

    final path = sourcePath;
    if (path == null) {
      throw StateError('Metadata input has no readable source.');
    }

    return File(path).readAsBytes();
  }
}

class MetadataPickedFolder {
  const MetadataPickedFolder({
    required this.directoryPath,
    required this.displayName,
    required this.images,
    this.ignoredCount = 0,
  });

  final String directoryPath;
  final String displayName;
  final List<MetadataInputImage> images;
  final int ignoredCount;
}

class MetadataCleanDestination {
  const MetadataCleanDestination({
    required this.directoryPath,
    required this.displayName,
  });

  final String directoryPath;
  final String displayName;
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

bool get _supportsDirectoryPicker {
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

String _safeFolderName(String name) {
  final safeName = name
      .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1F]+'), '-')
      .replaceAll(RegExp(r'^\.+'), '')
      .trim();
  return safeName.isEmpty ? 'metadata-removed' : safeName;
}

bool _isSupportedImagePath(String path) {
  return _imageFileExtensions.contains(_extension(path));
}

String _extension(String path) {
  final name = _lastPathComponent(path).toLowerCase();
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1);
}

const _imageFileExtensions = <String>{'png', 'jpg', 'jpeg', 'webp', 'bmp'};

String _lastPathComponent(String path) {
  final normalized = path.replaceAll(RegExp(r'/+$'), '');
  final slash = normalized.lastIndexOf('/');
  if (slash < 0) return normalized;
  return normalized.substring(slash + 1);
}

Future<File> _uniqueFile(String path) async {
  var candidate = File(path);
  if (!await candidate.exists()) return candidate;

  final dot = path.lastIndexOf('.');
  final basePath = dot > 0 ? path.substring(0, dot) : path;
  final extension = dot > 0 ? path.substring(dot) : '';
  var suffix = 2;
  while (await candidate.exists()) {
    candidate = File('$basePath-$suffix$extension');
    suffix += 1;
  }

  return candidate;
}
