import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redact_kit/app/redact_kit_app.dart';
import 'package:redact_kit/features/redaction/data/jpeg_metadata.dart';
import 'package:redact_kit/features/redaction/data/png_metadata.dart';
import 'package:redact_kit/features/redaction/domain/redaction_region.dart';
import 'package:redact_kit/features/redaction/presentation/redaction_painter.dart';

void main() {
  testWidgets('shows Redact Kit workspace', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RedactKitApp()));

    expect(find.text('Redact Kit'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open), findsWidgets);
    expect(find.text('Open from Files'), findsOneWidget);
  });

  testWidgets('uses compact controls on phone width', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const ProviderScope(child: RedactKitApp()));

    expect(find.text('Redact Kit'), findsOneWidget);
    expect(find.text('macOS / iOS'), findsNothing);
    expect(find.text('Open from Files'), findsOneWidget);
    expect(find.text('Open from Photos'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('Privacy & Export'), findsOneWidget);
    expect(find.text('Pixel-level redaction'), findsOneWidget);
    expect(find.textContaining('100% opaque solid pixels'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(find.text('Format'), findsOneWidget);
    expect(find.text('PNG'), findsWidgets);
    expect(find.text('JPEG'), findsOneWidget);
    expect(find.text('Save to Files'), findsOneWidget);
    expect(find.text('Save to Photos'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('uses tablet controls on mid width', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(820, 1180);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const ProviderScope(child: RedactKitApp()));

    expect(find.text('Redact Kit'), findsOneWidget);
    expect(find.text('macOS / iOS'), findsNothing);
    expect(find.text('Open from Files'), findsOneWidget);
    expect(find.text('Format'), findsNothing);
    expect(find.byIcon(Icons.tune), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Format'), findsOneWidget);
    expect(find.text('PNG'), findsWidgets);
    expect(find.text('JPEG'), findsOneWidget);
    expect(find.text('Save to Files'), findsOneWidget);
    expect(find.text('Save to Photos'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('shows export format controls on desktop width', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1120, 760);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const ProviderScope(child: RedactKitApp()));

    expect(find.text('Format'), findsOneWidget);
    expect(find.text('PNG'), findsWidgets);
    expect(find.text('JPEG'), findsOneWidget);
    expect(find.text('JPEG quality'), findsNothing);

    await tester.tap(find.text('JPEG'));
    await tester.pumpAndSettle();

    expect(find.text('JPEG quality'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Medium'), findsWidgets);
    expect(find.text('High'), findsWidgets);
    expect(find.text('Larger file, cleaner image.'), findsOneWidget);
  });

  testWidgets('uses tablet layout before desktop has enough width', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const ProviderScope(child: RedactKitApp()));

    expect(find.text('Format'), findsNothing);
    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps desktop side panel usable near minimum size', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 700);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const ProviderScope(child: RedactKitApp()));

    await tester.tap(find.text('JPEG'));
    await tester.pumpAndSettle();

    expect(find.text('JPEG quality'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('strips PNG ancillary metadata chunks', () {
    final png = Uint8List.fromList(<int>[
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      ..._chunk('IHDR', <int>[0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0]),
      ..._chunk('tEXt', 'secret=home'.codeUnits),
      ..._chunk('eXIf', <int>[1, 2, 3, 4]),
      ..._chunk('IDAT', <int>[120, 1, 1, 0]),
      ..._chunk('IEND', const <int>[]),
    ]);

    final stripped = stripPngMetadataChunks(png);
    final chunkTypes = _chunkTypes(stripped);

    expect(chunkTypes, <String>['IHDR', 'IDAT', 'IEND']);
    expect(String.fromCharCodes(stripped), isNot(contains('secret=home')));
  });

  test('strips JPEG app and comment metadata segments', () {
    final jpeg = Uint8List.fromList(<int>[
      0xff,
      0xd8,
      ..._jpegSegment(0xe0, 'JFIF secret density'.codeUnits),
      ..._jpegSegment(0xe1, 'Exif GPS home'.codeUnits),
      ..._jpegSegment(0xe2, 'ICC profile'.codeUnits),
      ..._jpegSegment(0xed, 'Photoshop IPTC'.codeUnits),
      ..._jpegSegment(0xef, 'vendor payload'.codeUnits),
      ..._jpegSegment(0xfe, 'private comment'.codeUnits),
      ..._jpegSegment(0xdb, <int>[1, 2, 3]),
      ..._jpegSegment(0xc0, <int>[8, 0, 1, 0, 1, 1, 1, 0x11, 0]),
      ..._jpegSegment(0xc4, <int>[0]),
      ..._jpegSegment(0xda, <int>[1, 1, 0, 0, 0]),
      0x11,
      0xff,
      0x00,
      0x22,
      0xff,
      0xd9,
    ]);

    final stripped = stripJpegMetadataSegments(jpeg);
    final markers = _jpegMarkers(stripped);

    expect(markers, containsAll(<int>[0xd8, 0xdb, 0xc0, 0xc4, 0xda, 0xd9]));
    expect(markers, isNot(contains(0xe0)));
    expect(markers, isNot(contains(0xe1)));
    expect(markers, isNot(contains(0xe2)));
    expect(markers, isNot(contains(0xed)));
    expect(markers, isNot(contains(0xef)));
    expect(markers, isNot(contains(0xfe)));
    expect(String.fromCharCodes(stripped), isNot(contains('GPS home')));
    expect(
      _containsSubsequence(stripped, <int>[0x11, 0xff, 0x00, 0x22]),
      isTrue,
    );
  });

  test(
    'redaction painter repaints after mutable source list changes',
    () async {
      final image = await _testImage();
      addTearDown(image.dispose);

      final redactions = <RedactionRegion>[
        const RedactionRegion(
          rect: Rect.fromLTWH(0, 0, 1, 1),
          color: Colors.black,
        ),
      ];
      final oldPainter = RedactionPainter(
        image: image,
        imageRect: const Rect.fromLTWH(0, 0, 10, 10),
        redactions: List<RedactionRegion>.unmodifiable(redactions),
        draftRect: null,
        draftColor: null,
      );

      redactions.clear();

      final newPainter = RedactionPainter(
        image: image,
        imageRect: const Rect.fromLTWH(0, 0, 10, 10),
        redactions: List<RedactionRegion>.unmodifiable(redactions),
        draftRect: null,
        draftColor: null,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    },
  );
}

Future<ui.Image> _testImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = Colors.white,
  );
  final picture = recorder.endRecording();
  try {
    return picture.toImage(1, 1);
  } finally {
    picture.dispose();
  }
}

List<int> _chunk(String type, List<int> data) {
  final length = data.length;
  return <int>[
    (length >> 24) & 0xff,
    (length >> 16) & 0xff,
    (length >> 8) & 0xff,
    length & 0xff,
    ...type.codeUnits,
    ...data,
    0,
    0,
    0,
    0,
  ];
}

List<int> _jpegSegment(int marker, List<int> data) {
  final length = data.length + 2;
  return <int>[0xff, marker, (length >> 8) & 0xff, length & 0xff, ...data];
}

List<String> _chunkTypes(Uint8List png) {
  final types = <String>[];
  var offset = 8;

  while (offset + 8 <= png.length) {
    final int length =
        (png[offset] << 24) |
        (png[offset + 1] << 16) |
        (png[offset + 2] << 8) |
        png[offset + 3];
    final type = String.fromCharCodes(png.getRange(offset + 4, offset + 8));
    types.add(type);
    offset += 12 + length;
    if (type == 'IEND') break;
  }

  return types;
}

List<int> _jpegMarkers(Uint8List jpeg) {
  final markers = <int>[];
  var index = 0;

  while (index + 1 < jpeg.length) {
    if (jpeg[index] != 0xff) {
      index += 1;
      continue;
    }

    var markerOffset = index + 1;
    while (markerOffset < jpeg.length && jpeg[markerOffset] == 0xff) {
      markerOffset += 1;
    }

    if (markerOffset >= jpeg.length || jpeg[markerOffset] == 0x00) {
      index = markerOffset + 1;
      continue;
    }

    final marker = jpeg[markerOffset];
    markers.add(marker);
    index = markerOffset + 1;

    if (marker == 0xd8 ||
        marker == 0xd9 ||
        marker == 0x01 ||
        (marker >= 0xd0 && marker <= 0xd7)) {
      if (marker == 0xd9) break;
      continue;
    }

    if (index + 2 > jpeg.length) break;
    final length = (jpeg[index] << 8) | jpeg[index + 1];
    index += length;
  }

  return markers;
}

bool _containsSubsequence(List<int> source, List<int> needle) {
  if (needle.isEmpty) return true;

  for (var index = 0; index <= source.length - needle.length; index += 1) {
    var matched = true;
    for (var needleIndex = 0; needleIndex < needle.length; needleIndex += 1) {
      if (source[index + needleIndex] != needle[needleIndex]) {
        matched = false;
        break;
      }
    }
    if (matched) return true;
  }

  return false;
}
