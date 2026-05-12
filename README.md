# Redact Kit

Redact Kit is a local-first macOS Flutter app for image redaction.

## Privacy model

- Redaction is pixel-level: selected regions are replaced with 100% opaque filled rectangles.
- Export creates a new PNG or JPEG from rendered pixels instead of copying source bytes.
- PNG exports use lossless level-6 compression and strip ancillary chunks so EXIF/text/time/profile metadata is not copied.
- JPEG exports are lossy, default to the High quality preset, and strip APP/comment metadata segments after encoding.
- Export defaults to a generic filename instead of reusing the source image name.
- Files are opened and saved through native macOS panels. There is no upload or server step.

## Run

```sh
flutter run -d macos
```

## Development

This project uses a generated-code Flutter structure:

- `go_router` for app routing
- `flutter_riverpod` + `riverpod_generator` for state and dependency injection
- `freezed` for immutable redaction state/models

After changing annotated providers or Freezed models, regenerate code:

```sh
dart run build_runner build
```

## Use

Open an image, drag across private regions, choose PNG or JPEG, then export the clean image.

Keyboard shortcuts:

- `Cmd+O`: open image
- `Cmd+Z`: undo last redaction
- `Cmd+S`: export clean image
- `Delete`: clear redactions

## Scope

The privacy path stays simple: decode pixels, burn in redaction rectangles, and encode a fresh PNG or JPEG without carrying source metadata forward.
