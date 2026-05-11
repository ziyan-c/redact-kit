# Redact Kit

Redact Kit is a local-first macOS Flutter app for image redaction.

## Privacy model

- Redaction is pixel-level: selected regions are replaced with 100% opaque filled rectangles.
- Export creates a new PNG from rendered pixels, then strips PNG ancillary chunks so EXIF/text/time/profile metadata is not copied.
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

Open an image, drag across private regions, then export the clean PNG.

Keyboard shortcuts:

- `Cmd+O`: open image
- `Cmd+Z`: undo last redaction
- `Cmd+S`: export clean PNG
- `Delete`: clear redactions

## Scope

The first Flutter version exports PNG only. That keeps the privacy path simple: decode pixels, burn in redaction rectangles, and encode a fresh PNG without carrying source metadata forward.
