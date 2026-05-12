import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/export_format.dart';

part 'file_channel_service.g.dart';

class FileChannelService {
  const FileChannelService();

  static const MethodChannel _channel = MethodChannel('app.redactkit/files');

  Future<Uint8List?> openImageBytes() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'openImage',
    );
    if (result == null) return null;

    final bytes = result['bytes'];
    if (bytes is! Uint8List) {
      throw const FormatException(
        'Native file picker returned invalid image data.',
      );
    }

    return bytes;
  }

  Future<String?> saveImage({
    required String name,
    required Uint8List bytes,
    required ExportFormat format,
  }) {
    return _channel.invokeMethod<String>('saveImage', <String, Object>{
      'name': name,
      'bytes': bytes,
      'extension': format.extension,
    });
  }
}

@riverpod
FileChannelService fileChannelService(Ref ref) {
  return const FileChannelService();
}
