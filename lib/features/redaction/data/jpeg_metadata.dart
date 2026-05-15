import 'dart:typed_data';

Uint8List stripJpegMetadataSegments(Uint8List jpeg) {
  if (jpeg.length < 4) {
    throw const FormatException('JPEG is too short.');
  }

  if (jpeg[0] != _markerPrefix || jpeg[1] != _markerSoi) {
    throw const FormatException('Invalid JPEG SOI.');
  }

  final output = <int>[_markerPrefix, _markerSoi];
  var offset = 2;
  var foundEnd = false;

  while (offset < jpeg.length) {
    final markerStart = _findNextJpegMarker(jpeg, offset);
    if (markerStart == -1) {
      break;
    }

    if (markerStart > offset) {
      output.addAll(jpeg.getRange(offset, markerStart));
    }

    var markerOffset = markerStart + 1;
    while (markerOffset < jpeg.length && jpeg[markerOffset] == _markerPrefix) {
      markerOffset += 1;
    }

    if (markerOffset >= jpeg.length) {
      throw const FormatException('Invalid JPEG marker.');
    }

    final marker = jpeg[markerOffset];
    final markerEnd = markerOffset + 1;

    if (_isStandaloneJpegMarker(marker)) {
      output.addAll(<int>[_markerPrefix, marker]);
      offset = markerEnd;

      if (marker == _markerEoi) {
        foundEnd = true;
        break;
      }
      continue;
    }

    if (markerEnd + 2 > jpeg.length) {
      throw const FormatException('JPEG segment is missing length.');
    }

    final segmentLength = _readJpegUint16(jpeg, markerEnd);
    if (segmentLength < 2) {
      throw const FormatException('Invalid JPEG segment length.');
    }

    final segmentEnd = markerEnd + segmentLength;
    if (segmentEnd > jpeg.length) {
      throw const FormatException('Invalid JPEG segment length.');
    }

    if (!_isJpegMetadataMarker(marker)) {
      output.addAll(<int>[_markerPrefix, marker]);
      output.addAll(jpeg.getRange(markerEnd, segmentEnd));
    }

    offset = segmentEnd;
  }

  if (!foundEnd) {
    throw const FormatException('JPEG is missing EOI.');
  }

  return Uint8List.fromList(output);
}

bool hasNonDefaultJpegExifOrientation(Uint8List jpeg) {
  final orientation = readJpegExifOrientation(jpeg);
  return orientation != null && orientation != 1;
}

int? readJpegExifOrientation(Uint8List jpeg) {
  if (jpeg.length < 4) return null;
  if (jpeg[0] != _markerPrefix || jpeg[1] != _markerSoi) return null;

  var offset = 2;
  while (offset < jpeg.length) {
    final markerStart = _findNextJpegMarker(jpeg, offset);
    if (markerStart == -1) return null;

    var markerOffset = markerStart + 1;
    while (markerOffset < jpeg.length && jpeg[markerOffset] == _markerPrefix) {
      markerOffset += 1;
    }

    if (markerOffset >= jpeg.length) return null;

    final marker = jpeg[markerOffset];
    final markerEnd = markerOffset + 1;

    if (_isStandaloneJpegMarker(marker)) {
      offset = markerEnd;
      if (marker == _markerEoi) return null;
      continue;
    }

    if (marker == _markerStartOfScan) return null;
    if (markerEnd + 2 > jpeg.length) return null;

    final segmentLength = _readJpegUint16(jpeg, markerEnd);
    if (segmentLength < 2) return null;

    final segmentDataStart = markerEnd + 2;
    final segmentEnd = markerEnd + segmentLength;
    if (segmentEnd > jpeg.length) return null;

    if (marker == _markerApp1 &&
        _hasExifSignature(jpeg, segmentDataStart, segmentEnd)) {
      final orientation = _readTiffOrientation(
        jpeg,
        segmentDataStart + _exifSignature.length,
        segmentEnd,
      );
      if (orientation != null) return orientation;
    }

    offset = segmentEnd;
  }

  return null;
}

int _findNextJpegMarker(Uint8List bytes, int offset) {
  for (var index = offset; index + 1 < bytes.length; index += 1) {
    if (bytes[index] != _markerPrefix) {
      continue;
    }

    var markerOffset = index + 1;
    while (markerOffset < bytes.length &&
        bytes[markerOffset] == _markerPrefix) {
      markerOffset += 1;
    }

    if (markerOffset >= bytes.length) {
      return -1;
    }

    if (bytes[markerOffset] == _stuffedMarkerByte) {
      index = markerOffset;
      continue;
    }

    return index;
  }

  return -1;
}

bool _isJpegMetadataMarker(int marker) {
  return marker == _markerComment ||
      (marker >= _markerApp0 && marker <= _markerApp15);
}

bool _hasExifSignature(Uint8List bytes, int offset, int end) {
  if (offset + _exifSignature.length > end) return false;
  for (var index = 0; index < _exifSignature.length; index += 1) {
    if (bytes[offset + index] != _exifSignature[index]) return false;
  }
  return true;
}

int? _readTiffOrientation(Uint8List bytes, int tiffStart, int end) {
  if (tiffStart + 8 > end) return null;

  final littleEndian = bytes[tiffStart] == 0x49 && bytes[tiffStart + 1] == 0x49;
  final bigEndian = bytes[tiffStart] == 0x4d && bytes[tiffStart + 1] == 0x4d;
  if (!littleEndian && !bigEndian) return null;

  final magic = _readTiffUint16(bytes, tiffStart + 2, littleEndian);
  if (magic != 42) return null;

  final ifd0Offset = _readTiffUint32(bytes, tiffStart + 4, littleEndian);
  final ifd0 = tiffStart + ifd0Offset;
  if (ifd0 < tiffStart || ifd0 + 2 > end) return null;

  final entryCount = _readTiffUint16(bytes, ifd0, littleEndian);
  final entriesStart = ifd0 + 2;
  for (var index = 0; index < entryCount; index += 1) {
    final entry = entriesStart + index * 12;
    if (entry + 12 > end) return null;

    final tag = _readTiffUint16(bytes, entry, littleEndian);
    if (tag != _exifOrientationTag) continue;

    final type = _readTiffUint16(bytes, entry + 2, littleEndian);
    final count = _readTiffUint32(bytes, entry + 4, littleEndian);
    if (type != _tiffTypeShort || count < 1) return null;

    final orientation = _readTiffUint16(bytes, entry + 8, littleEndian);
    return orientation >= 1 && orientation <= 8 ? orientation : null;
  }

  return null;
}

int _readTiffUint16(Uint8List bytes, int offset, bool littleEndian) {
  if (littleEndian) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }
  return (bytes[offset] << 8) | bytes[offset + 1];
}

int _readTiffUint32(Uint8List bytes, int offset, bool littleEndian) {
  if (littleEndian) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

bool _isStandaloneJpegMarker(int marker) {
  return marker == _markerSoi ||
      marker == _markerEoi ||
      marker == _markerTem ||
      (marker >= _markerRst0 && marker <= _markerRst7);
}

int _readJpegUint16(Uint8List bytes, int offset) {
  return (bytes[offset] << 8) | bytes[offset + 1];
}

const _markerPrefix = 0xff;
const _stuffedMarkerByte = 0x00;
const _markerTem = 0x01;
const _markerRst0 = 0xd0;
const _markerRst7 = 0xd7;
const _markerSoi = 0xd8;
const _markerEoi = 0xd9;
const _markerApp0 = 0xe0;
const _markerApp1 = 0xe1;
const _markerApp15 = 0xef;
const _markerStartOfScan = 0xda;
const _markerComment = 0xfe;
const _exifSignature = <int>[0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
const _exifOrientationTag = 0x0112;
const _tiffTypeShort = 3;
