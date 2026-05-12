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
const _markerApp15 = 0xef;
const _markerComment = 0xfe;
