import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redact_kit/app/redact_kit_app.dart';
import 'package:redact_kit/features/redaction/data/png_metadata.dart';
import 'package:redact_kit/features/redaction/domain/redaction_region.dart';
import 'package:redact_kit/features/redaction/presentation/redaction_painter.dart';

void main() {
  testWidgets('shows Redact Kit workspace', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RedactKitApp()));

    expect(find.text('Redact Kit'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open), findsWidgets);
    expect(find.text('Open Image'), findsOneWidget);
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
