import 'dart:typed_data';

Uint8List stripPngMetadataChunks(Uint8List png) {
  const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  const allowedChunks = <String>{
    'IHDR',
    'PLTE',
    'tRNS',
    'sRGB',
    'gAMA',
    'cHRM',
    'cICP',
    'IDAT',
    'IEND',
  };

  if (png.length < signature.length) {
    throw const FormatException('PNG is too short.');
  }

  for (var index = 0; index < signature.length; index += 1) {
    if (png[index] != signature[index]) {
      throw const FormatException('Invalid PNG signature.');
    }
  }

  final output = <int>[...signature];
  var offset = signature.length;
  var foundEnd = false;

  while (offset + 8 <= png.length) {
    final chunkLength = _readPngUint32(png, offset);
    final chunkStart = offset;
    final chunkTypeStart = offset + 4;
    final chunkDataStart = offset + 8;
    final chunkCrcStart = chunkDataStart + chunkLength;
    final nextChunkStart = chunkCrcStart + 4;

    if (nextChunkStart > png.length) {
      throw const FormatException('Invalid PNG chunk length.');
    }

    final chunkType = String.fromCharCodes(
      png.getRange(chunkTypeStart, chunkTypeStart + 4),
    );

    if (allowedChunks.contains(chunkType)) {
      output.addAll(png.getRange(chunkStart, nextChunkStart));
    }

    offset = nextChunkStart;
    if (chunkType == 'IEND') {
      foundEnd = true;
      break;
    }
  }

  if (!foundEnd) {
    throw const FormatException('PNG is missing IEND.');
  }

  return Uint8List.fromList(output);
}

int _readPngUint32(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
