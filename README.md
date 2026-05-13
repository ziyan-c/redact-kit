# Redact Kit

Redact Kit is a local-first Flutter app for image redaction on macOS and iOS.

## Privacy model

- Redaction is pixel-level: selected regions are replaced with 100% opaque filled rectangles.
- Export creates a new PNG or JPEG from rendered pixels instead of copying source bytes.
- Clean Metadata mode can process one image, multiple images, or a desktop folder without applying redaction boxes.
- PNG exports use lossless level-6 compression and strip ancillary chunks so EXIF/text/time/profile metadata is not copied.
- JPEG exports are lossy, start on the Medium quality preset, and strip APP/comment metadata segments after encoding.
- PNG-to-PNG and JPEG-to-JPEG metadata cleaning strip the original container directly; format changes decode visible pixels and encode a fresh clean file.
- Exports start with a generic filename instead of reusing the source image name.
- Redact export can preserve the source filename when `Keep filename` is enabled; it starts disabled.
- Single-image and multi-image metadata cleaning write directly to the app `Cleaned` folder unless an output folder is chosen.
- Folder input writes cleaned images to an app `Cleaned/<folder>-metadata-removed` folder by default, so macOS App Sandbox permission stays explicit.
- Folder input ignores unsupported files and reports cleaned, ignored, and failed counts after processing.
- Batch metadata cleaning can preserve source filenames when `Keep filenames` is enabled; it starts disabled.
- Redact and Clean Metadata have separate in-app details panels describing their privacy behavior.
- File picking, sharing, and Photos export use Flutter plugins. There is no upload or server step.

## Run

```sh
flutter run -d macos
```

```sh
flutter run -d ios
```

## Development

This project uses a generated-code Flutter structure:

- `go_router` for app routing
- `flutter_riverpod` + `riverpod_generator` for state and dependency injection
- `freezed` for immutable redaction state/models
- `file_selector`, `image_picker`, `path_provider`, `share_plus`, and `gal` for platform file/photo workflows

After changing annotated providers or Freezed models, regenerate code:

```sh
dart run build_runner build
```

## Local private config

Optional signing settings can live in `.local/`, which is ignored by Git and may
be a symlink to private storage. Copy templates from `.local.example/` and fill
in personal values locally.

## Use

Use the mode switcher to choose `Redact` or `Metadata`. Redact opens one image, burns in solid redaction pixels, and exports a rebuilt image with metadata removed. Metadata lets you choose input first, previews the output path, then starts cleaning when you press `Start`. On iOS it writes into the app's `Cleaned` folder.

Keyboard shortcuts:

- `Cmd+O`: open image
- `Cmd+Z`: undo last redaction
- `Cmd+S`: export clean image
- `Delete`: clear redactions

## Scope

The privacy path stays simple: redact exports decode pixels, optionally burn in redaction rectangles, and encode a fresh PNG or JPEG. Metadata-only cleaning uses direct PNG/JPEG metadata stripping when possible, and only transcodes pixels when the output format changes.
