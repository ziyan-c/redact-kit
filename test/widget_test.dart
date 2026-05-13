import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

import 'package:redact_kit/app/redact_kit_app.dart';
import 'package:redact_kit/features/redaction/application/redaction_controller.dart';
import 'package:redact_kit/features/redaction/data/file_channel_service.dart';
import 'package:redact_kit/features/redaction/data/jpeg_metadata.dart';
import 'package:redact_kit/features/redaction/data/png_metadata.dart';
import 'package:redact_kit/features/redaction/domain/export_format.dart';
import 'package:redact_kit/features/redaction/domain/jpeg_quality_preset.dart';
import 'package:redact_kit/features/redaction/domain/redaction_state.dart';
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
    expect(find.text('Redact'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
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
    expect(find.text('Clean Metadata'), findsNothing);
    expect(find.text('Keep filename'), findsOneWidget);
    expect(find.text('Save to Files'), findsOneWidget);
    expect(find.text('Save to Photos'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metadata'));
    await tester.pumpAndSettle();

    expect(find.text('Clean Metadata'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('No input selected'), findsOneWidget);
    expect(find.text('Output'), findsOneWidget);
    expect(find.text('Output: app Cleaned folder'), findsOneWidget);
    expect(find.text('Keep filenames'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
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
    expect(find.text('Redact'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    expect(find.text('Format'), findsNothing);
    expect(find.byIcon(Icons.tune), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Format'), findsOneWidget);
    expect(find.text('PNG'), findsWidgets);
    expect(find.text('JPEG'), findsOneWidget);
    expect(find.text('Clean Metadata'), findsNothing);
    expect(find.text('Keep filename'), findsOneWidget);
    expect(find.text('Save to Files'), findsOneWidget);
    expect(find.text('Save to Photos'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metadata'));
    await tester.pumpAndSettle();

    expect(find.text('Clean Metadata'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('No input selected'), findsOneWidget);
    expect(find.text('Output'), findsOneWidget);
    expect(find.text('Output: app Cleaned folder'), findsOneWidget);
    expect(find.text('Keep filenames'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
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

    expect(find.text('macOS / iOS'), findsNothing);
    expect(find.text('Redact'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    expect(find.text('Format'), findsOneWidget);
    expect(find.text('PNG'), findsWidgets);
    expect(find.text('JPEG'), findsOneWidget);
    expect(find.text('Clean Metadata'), findsNothing);
    expect(find.text('Keep filename'), findsOneWidget);
    expect(find.text('Choose Images'), findsNothing);
    expect(find.text('JPEG quality'), findsNothing);

    await tester.tap(find.text('JPEG'));
    await tester.pumpAndSettle();

    expect(find.text('JPEG quality'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Medium'), findsWidgets);
    expect(find.text('High'), findsWidgets);
    expect(find.text('Balanced size and image quality.'), findsOneWidget);

    await tester.tap(find.text('Metadata'));
    await tester.pumpAndSettle();

    expect(find.text('Clean Metadata'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('Choose Image'), findsOneWidget);
    expect(find.text('Choose Images'), findsOneWidget);
    expect(find.text('Choose Folder'), findsOneWidget);
    expect(find.text('No input selected'), findsOneWidget);
    expect(find.text('Output'), findsOneWidget);
    expect(find.text('Choose input to preview output'), findsOneWidget);
    expect(find.text('Keep filenames'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
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

  test('defaults JPEG quality to medium', () {
    expect(const RedactionState().jpegQualityPreset, JpegQualityPreset.medium);
    expect(const RedactionState().preserveRedactionExportFileName, isFalse);
    expect(const RedactionState().preserveMetadataCleanFileNames, isFalse);
  });

  testWidgets('folder metadata input plans an app cleaned output subfolder', (
    WidgetTester tester,
  ) async {
    final source = image_lib.Image(width: 1, height: 1)
      ..setPixelRgb(0, 0, 255, 255, 255);
    final pngBytes = Uint8List.fromList(image_lib.encodePng(source));
    final service = _FakeFileChannelService(
      openBytes: pngBytes,
      metadataFolder: MetadataPickedFolder(
        directoryPath: '/tmp/source-folder',
        displayName: '/tmp/source-folder',
        images: <MetadataInputImage>[
          MetadataInputImage(
            bytes: pngBytes,
            sourceName: 'one.png',
            sourcePath: '/tmp/source-folder/one.png',
          ),
        ],
        ignoredCount: 1,
      ),
    );
    final container = ProviderContainer(
      overrides: [fileChannelServiceProvider.overrideWithValue(service)],
    );
    final subscription = container.listen(
      redactionControllerProvider,
      (_, _) {},
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    final controller = container.read(redactionControllerProvider.notifier);

    await tester.runAsync(controller.chooseMetadataFolder);

    expect(
      container.read(redactionControllerProvider).metadataInputLabel,
      'Folder: source-folder',
    );
    expect(
      container
          .read(redactionControllerProvider)
          .metadataOutputDirectoryDisplayName,
      'Cleaned/source-folder-metadata-removed',
    );
    expect(
      container.read(redactionControllerProvider).metadataInputDescription,
      '1 image, 1 ignored',
    );

    await tester.runAsync(controller.startMetadataClean);

    expect(service.batchDestinationPaths, <String>[
      '/tmp/redact-kit-cleaned/source-folder-metadata-removed',
    ]);
    expect(
      container.read(redactionControllerProvider).status,
      'Success: cleaned metadata for 1 image to Cleaned/source-folder-metadata-removed (1 ignored)',
    );
  });

  testWidgets('metadata output field opens the full output value', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1120, 760);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final pngBytes = Uint8List.fromList(<int>[
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      ..._chunk('IHDR', <int>[0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0]),
      ..._chunk('IDAT', <int>[120, 1, 1, 0]),
      ..._chunk('IEND', const <int>[]),
    ]);
    final service = _FakeFileChannelService(
      openBytes: pngBytes,
      metadataImage: MetadataInputImage(
        bytes: pngBytes,
        sourceName: 'very-long-private-document-name.png',
        sourcePath: '/tmp/source/very-long-private-document-name.png',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [fileChannelServiceProvider.overrideWithValue(service)],
        child: const RedactKitApp(),
      ),
    );

    await tester.tap(find.text('Metadata'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Image'));
    await tester.pumpAndSettle();

    const outputPath =
        'Cleaned/very-long-private-document-name-metadata-removed.png';
    expect(find.text(outputPath), findsOneWidget);

    await tester.tap(find.text(outputPath));
    await tester.pumpAndSettle();

    expect(find.text('Full Output'), findsOneWidget);
    expect(find.text(outputPath), findsWidgets);
    expect(find.text('Folder Path'), findsOneWidget);
    expect(find.text('/tmp/redact-kit-cleaned'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets(
    'single metadata input plans an app-cleaned suffixed file and strips directly',
    (WidgetTester tester) async {
      final pngWithMetadata = Uint8List.fromList(<int>[
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        ..._chunk('IHDR', <int>[0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0]),
        ..._chunk('tEXt', 'gps=secret'.codeUnits),
        ..._chunk('IDAT', <int>[120, 1, 1, 0]),
        ..._chunk('IEND', const <int>[]),
      ]);
      final expectedBytes = stripPngMetadataChunks(pngWithMetadata);
      final service = _FakeFileChannelService(
        openBytes: pngWithMetadata,
        metadataImage: MetadataInputImage(
          bytes: pngWithMetadata,
          sourceName: 'secret-card.png',
          sourcePath: '/tmp/source/secret-card.png',
        ),
      );
      final container = ProviderContainer(
        overrides: [fileChannelServiceProvider.overrideWithValue(service)],
      );
      final subscription = container.listen(
        redactionControllerProvider,
        (_, _) {},
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });

      final controller = container.read(redactionControllerProvider.notifier);

      await tester.runAsync(controller.chooseMetadataImageFromFiles);

      expect(
        container.read(redactionControllerProvider).metadataInputLabel,
        '1 image',
      );
      expect(
        container
            .read(redactionControllerProvider)
            .metadataOutputDirectoryDisplayName,
        'Cleaned/secret-card-metadata-removed.png',
      );

      await tester.runAsync(controller.startMetadataClean);

      expect(service.batchDestinationPaths, <String>[
        '/tmp/redact-kit-cleaned',
      ]);
      expect(service.batchSavedNames, <String>[
        'secret-card-metadata-removed.png',
      ]);
      expect(service.batchSavedBytes.single, expectedBytes);
      expect(
        container
            .read(redactionControllerProvider)
            .metadataOutputDirectoryDisplayName,
        'Cleaned/secret-card-metadata-removed.png',
      );

      await tester.runAsync(controller.openMetadataOutputFolder);

      expect(service.openedDirectoryPath, '/tmp/redact-kit-cleaned');
      expect(
        container.read(redactionControllerProvider).status,
        'Opened output folder',
      );
    },
  );

  testWidgets('metadata-only export ignores active redaction boxes', (
    WidgetTester tester,
  ) async {
    final source = image_lib.Image(width: 6, height: 6);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgb(x, y, 255, 255, 255);
      }
    }

    final service = _FakeFileChannelService(
      openBytes: Uint8List.fromList(image_lib.encodePng(source)),
    );
    final container = ProviderContainer(
      overrides: [fileChannelServiceProvider.overrideWithValue(service)],
    );
    final subscription = container.listen(
      redactionControllerProvider,
      (_, _) {},
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    final controller = container.read(redactionControllerProvider.notifier);
    await tester.runAsync(() async {
      await controller.openImage();
      controller.beginRedaction(
        const Offset(0, 0),
        const Rect.fromLTWH(0, 0, 6, 6),
      );
      controller.updateRedaction(
        const Offset(6, 6),
        const Rect.fromLTWH(0, 0, 6, 6),
      );
      controller.finishRedaction();
    });

    expect(container.read(redactionControllerProvider).redactions.length, 1);

    await tester.runAsync(controller.exportMetadataCleanImage);

    expect(service.savedName, 'metadata-clean.png');
    final cleanImage = image_lib.decodePng(service.savedBytes!)!;
    final centerPixel = cleanImage.getPixel(3, 3);

    expect(centerPixel.r, 255);
    expect(centerPixel.g, 255);
    expect(centerPixel.b, 255);
  });

  testWidgets('redaction export can preserve the source filename', (
    WidgetTester tester,
  ) async {
    final source = image_lib.Image(width: 4, height: 4);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgb(x, y, 255, 255, 255);
      }
    }

    final service = _FakeFileChannelService(
      openBytes: Uint8List.fromList(image_lib.encodePng(source)),
    );
    final container = ProviderContainer(
      overrides: [fileChannelServiceProvider.overrideWithValue(service)],
    );
    final subscription = container.listen(
      redactionControllerProvider,
      (_, _) {},
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    final controller = container.read(redactionControllerProvider.notifier);
    await tester.runAsync(controller.openImage);
    controller.setPreserveRedactionExportFileName(true);

    await tester.runAsync(controller.exportImage);

    expect(service.savedName, 'source-secret.png');
  });

  testWidgets(
    'batch metadata cleaner writes generic filenames to destination',
    (WidgetTester tester) async {
      final source = image_lib.Image(width: 6, height: 6);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          source.setPixelRgb(x, y, 255, 255, 255);
        }
      }

      final service = _FakeFileChannelService(
        openBytes: Uint8List.fromList(image_lib.encodePng(source)),
        batchImages: <MetadataInputImage>[
          MetadataInputImage(
            bytes: Uint8List.fromList(image_lib.encodePng(source)),
            sourceName: 'private-home-gps.png',
            sourcePath: '/tmp/input/private-home-gps.png',
          ),
          MetadataInputImage(
            bytes: Uint8List.fromList(image_lib.encodePng(source)),
            sourceName: 'passport.png',
            sourcePath: '/tmp/input/passport.png',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [fileChannelServiceProvider.overrideWithValue(service)],
      );
      final subscription = container.listen(
        redactionControllerProvider,
        (_, _) {},
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });

      final controller = container.read(redactionControllerProvider.notifier);

      await tester.runAsync(controller.cleanMetadataBatchFromFiles);

      expect(service.batchSavedNames, <String>[
        'metadata-clean-001.png',
        'metadata-clean-002.png',
      ]);
      expect(service.batchDestinationPaths, <String>[
        '/tmp/redact-kit-cleaned',
        '/tmp/redact-kit-cleaned',
      ]);

      final cleanImage = image_lib.decodePng(service.batchSavedBytes.first)!;
      final centerPixel = cleanImage.getPixel(3, 3);

      expect(centerPixel.r, 255);
      expect(centerPixel.g, 255);
      expect(centerPixel.b, 255);
    },
  );

  testWidgets(
    'batch metadata cleaner can preserve sanitized unique filenames',
    (WidgetTester tester) async {
      final source = image_lib.Image(width: 6, height: 6);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          source.setPixelRgb(x, y, 255, 255, 255);
        }
      }

      final service = _FakeFileChannelService(
        openBytes: Uint8List.fromList(image_lib.encodePng(source)),
        batchImages: <MetadataInputImage>[
          MetadataInputImage(
            bytes: Uint8List.fromList(image_lib.encodePng(source)),
            sourceName: 'ID card.jpg',
          ),
          MetadataInputImage(
            bytes: Uint8List.fromList(image_lib.encodePng(source)),
            sourceName: 'ID card.png',
          ),
          MetadataInputImage(
            bytes: Uint8List.fromList(image_lib.encodePng(source)),
            sourceName: r'folder/home:gps.jpeg',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [fileChannelServiceProvider.overrideWithValue(service)],
      );
      final subscription = container.listen(
        redactionControllerProvider,
        (_, _) {},
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });

      final controller = container.read(redactionControllerProvider.notifier);
      controller.setPreserveMetadataCleanFileNames(true);

      await tester.runAsync(controller.cleanMetadataBatchFromFiles);

      expect(service.batchSavedNames, <String>[
        'ID card.png',
        'ID card-2.png',
        'home-gps.png',
      ]);
    },
  );

  testWidgets('batch metadata cleaner uses chosen output folder', (
    WidgetTester tester,
  ) async {
    final source = image_lib.Image(width: 6, height: 6);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgb(x, y, 255, 255, 255);
      }
    }

    final service = _FakeFileChannelService(
      openBytes: Uint8List.fromList(image_lib.encodePng(source)),
      chosenMetadataDestination: const MetadataCleanDestination(
        directoryPath: '/tmp/chosen-metadata',
        displayName: 'Chosen Metadata Folder',
      ),
      batchImages: <MetadataInputImage>[
        MetadataInputImage(
          bytes: Uint8List.fromList(image_lib.encodePng(source)),
          sourceName: 'private-home-gps.png',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [fileChannelServiceProvider.overrideWithValue(service)],
    );
    final subscription = container.listen(
      redactionControllerProvider,
      (_, _) {},
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    final controller = container.read(redactionControllerProvider.notifier);

    await tester.runAsync(controller.chooseMetadataImagesFromFiles);
    await tester.runAsync(controller.chooseMetadataOutputFolder);

    expect(
      container
          .read(redactionControllerProvider)
          .metadataOutputDirectoryDisplayName,
      'Chosen Metadata Folder',
    );

    await tester.runAsync(controller.startMetadataClean);

    expect(service.batchDestinationPaths, <String>['/tmp/chosen-metadata']);
    expect(
      container.read(redactionControllerProvider).status,
      contains('Chosen Metadata Folder'),
    );
  });

  testWidgets('metadata cleaner reports the failing file and reason', (
    WidgetTester tester,
  ) async {
    final service = _FakeFileChannelService(
      openBytes: Uint8List(0),
      metadataImage: MetadataInputImage(
        bytes: Uint8List(0),
        sourceName: 'broken.png',
        sourcePath: '/tmp/source/broken.png',
      ),
    );
    final container = ProviderContainer(
      overrides: [fileChannelServiceProvider.overrideWithValue(service)],
    );
    final subscription = container.listen(
      redactionControllerProvider,
      (_, _) {},
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    final controller = container.read(redactionControllerProvider.notifier);

    await tester.runAsync(controller.chooseMetadataImageFromFiles);
    await tester.runAsync(controller.startMetadataClean);

    expect(
      container.read(redactionControllerProvider).status,
      'Could not clean metadata: broken.png: PNG is too short. (1 failed)',
    );
    expect(
      container.read(redactionControllerProvider).metadataCleanProgress,
      isNull,
    );
  });

  testWidgets('metadata cleaner explains automatic output permission failure', (
    WidgetTester tester,
  ) async {
    final source = image_lib.Image(width: 1, height: 1);
    source.setPixelRgb(0, 0, 255, 255, 255);
    final service = _FakeFileChannelService(
      openBytes: Uint8List.fromList(image_lib.encodePng(source)),
      destinationError: const FileSystemException(
        'Creation failed',
        '/tmp/input/images-metadata-removed',
      ),
      batchImages: <MetadataInputImage>[
        MetadataInputImage(
          bytes: Uint8List.fromList(image_lib.encodePng(source)),
          sourceName: 'private.png',
          sourcePath: '/tmp/input/private.png',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [fileChannelServiceProvider.overrideWithValue(service)],
    );
    final subscription = container.listen(
      redactionControllerProvider,
      (_, _) {},
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    final controller = container.read(redactionControllerProvider.notifier);

    await tester.runAsync(controller.chooseMetadataImagesFromFiles);
    await tester.runAsync(controller.startMetadataClean);

    expect(
      container.read(redactionControllerProvider).status,
      'Could not create output folder: macOS sandbox did not allow the planned output location. Use Output > Choose Folder and select or create /tmp/input/images-metadata-removed.',
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

class _FakeFileChannelService extends FileChannelService {
  _FakeFileChannelService({
    required this.openBytes,
    this.batchImages = const <MetadataInputImage>[],
    this.metadataImage,
    this.metadataFolder,
    this.chosenMetadataDestination,
    this.destinationError,
  });

  final Uint8List openBytes;
  final List<MetadataInputImage> batchImages;
  final MetadataInputImage? metadataImage;
  final MetadataPickedFolder? metadataFolder;
  final MetadataCleanDestination? chosenMetadataDestination;
  final FileSystemException? destinationError;
  String? savedName;
  Uint8List? savedBytes;
  final batchSavedNames = <String>[];
  final batchSavedBytes = <Uint8List>[];
  final batchDestinationPaths = <String>[];
  String? openedDirectoryPath;

  @override
  Future<Uint8List?> openImageBytes() async => openBytes;

  @override
  Future<PickedImageBytes?> openImageFile() async {
    return PickedImageBytes(bytes: openBytes, sourceName: 'source-secret.jpg');
  }

  @override
  Future<List<PickedImageBytes>> openImageFilesBytes() async {
    final picked = <PickedImageBytes>[];
    for (final image in batchImages) {
      picked.add(
        PickedImageBytes(
          bytes: await image.readBytes(),
          sourceName: image.sourceName,
          sourcePath: image.sourcePath,
        ),
      );
    }
    return picked;
  }

  @override
  Future<List<MetadataInputImage>> chooseMetadataImageFiles() async =>
      batchImages;

  @override
  Future<MetadataInputImage?> chooseMetadataImageFile() async => metadataImage;

  @override
  Future<MetadataPickedFolder?> chooseMetadataImageFolder() async =>
      metadataFolder;

  @override
  Future<MetadataCleanDestination?> chooseMetadataCleanOutputDirectory() async {
    return chosenMetadataDestination;
  }

  @override
  Future<MetadataCleanDestination> createMetadataCleanDestination({
    required List<MetadataInputImage> images,
    MetadataCleanDestination? selectedDestination,
    String? automaticFolderName,
  }) async {
    final error = destinationError;
    if (error != null) throw error;

    if (selectedDestination != null) return selectedDestination;

    return previewMetadataCleanDestination(
      automaticFolderName: automaticFolderName,
    );
  }

  @override
  Future<MetadataCleanDestination> previewMetadataCleanDestination({
    String? automaticFolderName,
  }) async {
    final folderName = automaticFolderName;
    return MetadataCleanDestination(
      directoryPath: folderName == null
          ? '/tmp/redact-kit-cleaned'
          : '/tmp/redact-kit-cleaned/$folderName',
      displayName: folderName == null ? 'Cleaned' : 'Cleaned/$folderName',
    );
  }

  @override
  Future<void> openDirectory(String path) async {
    openedDirectoryPath = path;
  }

  @override
  Future<String?> saveImage({
    required String name,
    required Uint8List bytes,
    required ExportFormat format,
  }) async {
    savedName = name;
    savedBytes = Uint8List.fromList(bytes);
    return '/tmp/$name';
  }

  @override
  Future<String> saveMetadataCleanImage({
    required MetadataCleanDestination destination,
    required String name,
    required Uint8List bytes,
  }) async {
    batchSavedNames.add(name);
    batchSavedBytes.add(Uint8List.fromList(bytes));
    batchDestinationPaths.add(destination.directoryPath);
    return '${destination.directoryPath}/$name';
  }
}
