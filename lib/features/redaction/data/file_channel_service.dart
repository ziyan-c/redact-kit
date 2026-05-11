import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  Future<String?> savePng({required String name, required Uint8List bytes}) {
    return _channel.invokeMethod<String>('savePng', <String, Object>{
      'name': name,
      'bytes': bytes,
    });
  }
}

@riverpod
FileChannelService fileChannelService(Ref ref) {
  return const FileChannelService();
}
