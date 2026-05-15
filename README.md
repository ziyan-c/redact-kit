# Redact Kit

Redact Kit is a local-first Flutter app for image and PDF redaction on macOS
and iOS.

## Privacy model

- Redaction is pixel-level: selected regions are replaced with 100% opaque filled rectangles.
- Export creates a new PNG or JPEG from rendered pixels instead of copying source bytes.
- PDF redaction renders each page, burns redactions into the page image, and
  generates a new flattened PDF.
- Metadata Only PDF cleaning uses the same flattening path without redaction
  boxes, so the original PDF metadata, annotations, forms, links, embedded
  files, OCR layer, and text layer are not copied forward.
- Flattened PDF export is safer and easier to verify, but exported PDFs behave
  like scanned pages: visible text is not selectable or searchable.
- Metadata Only mode uses one input button for files or folders. Files can be
  images or PDFs; folder input scans supported images and PDFs without applying
  redaction boxes.
- macOS and iOS share the same Metadata input UI. Platform-native pickers prepare
  selected files or supported folder contents inside the app sandbox before
  cleaning.
- PNG exports show as Original lossless quality, use lossless level-6
  compression, preserve transparency and standard color-rendering chunks, and
  strip EXIF/text/time/profile metadata.
- JPEG is the default image export format. JPEG exports are lossy, start on the
  Medium quality preset, bake EXIF orientation into pixels when needed, and
  strip APP/comment metadata segments after encoding.
- Flattened PDF exports use High, Medium, or Low quality presets. The preset
  controls page render resolution and JPEG page-image compression, then writes a
  new metadata-clean PDF.
- PNG-to-PNG metadata cleaning strips the original container directly while
  preserving transparency and standard color-rendering chunks. JPEG-to-JPEG
  metadata cleaning strips the original container directly unless EXIF
  orientation must be baked into pixels. Format changes decode visible pixels
  and encode a fresh clean file.
- Exports start with a generic filename instead of reusing the source image name.
- Redact export can preserve the source filename when `Keep filename` is enabled; it starts disabled.
- Single-image and multi-image metadata cleaning write directly to the app `Cleaned` folder unless an output folder is chosen.
- Folder input writes cleaned images and flattened metadata-clean PDFs to an app
  `Cleaned/<folder>-metadata-removed` folder by default, so macOS App Sandbox
  permission stays explicit.
- Folder input ignores unsupported files and reports cleaned, ignored, and failed counts after processing.
- Batch metadata cleaning can preserve source filenames when `Keep filenames` is enabled; it starts disabled.
- Image, PDF, and Metadata Only have separate in-app details panels describing
  their privacy behavior.
- File picking, sharing, and Photos export use Flutter plugins. There is no upload or server step.

## Run

```sh
flutter run -d macos
```

```sh
flutter run -d ios
```

## GitHub macOS release

The GitHub Actions workflow in `.github/workflows/macos-release.yml` builds a
macOS `.app` bundle, zips it, uploads the zip as a workflow artifact, and
attaches it to a GitHub Release when a `v*` version tag is pushed.

Create a release build by pushing a `v`-prefixed tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The uploaded zip keeps the full tag in the file name, such as
`Redact-Kit-macOS-v1.0.0.zip`. It is not Developer ID notarized unless Apple
signing and notarization secrets are added later.

## Development

This project uses a generated-code Flutter structure:

- `go_router` for app routing
- `flutter_riverpod` + `riverpod_generator` for state and dependency injection
- `freezed` for immutable redaction state/models
- `file_selector`, `image_picker`, `path_provider`, `share_plus`, and `gal` for platform file/photo workflows
- `pdfx` for PDF page rendering and `pdf` for flattened PDF generation
- The UI is Apple-first and uses a Cupertino app shell and Cupertino controls
  across iOS and macOS.
- The shared palette follows Cupertino-style system blue, grouped backgrounds,
  separator lines, and label colors.
- TODO(android): if Android distribution is added later, design and QA a
  separate Material shell instead of reusing the Apple-first UI unchanged.

After changing annotated providers or Freezed models, regenerate code:

```sh
dart run build_runner build
```

## Local private config

Optional signing settings can live in `.local/`, which is ignored by Git and may
be a symlink to private storage. Copy templates from `.local.example/` and fill
in personal values locally.

## Use

Use the mode switcher to choose `Image`, `PDF`, or `Metadata`. Image opens
one image, burns in solid redaction pixels, and exports a rebuilt image with
metadata removed. PDF opens one document, lets you redact page by page, then
exports a flattened clean PDF with metadata removed while keeping each exported
page at the original PDF page size. PDF quality defaults to Medium; High keeps
pages sharper and Low makes smaller files. Metadata Only lets you choose files
or a folder from one input button, then cleans supported images and PDFs without
redaction boxes. PDF metadata cleaning uses the same flattening path but no
boxes. On iOS, image metadata cleaning writes into the app's `Cleaned` folder.

Keyboard shortcuts:

- `Cmd+O`: open image
- `Cmd+Z`: undo last redaction
- `Cmd+S`: export clean image
- `Delete`: clear redactions

## Scope

The privacy path stays simple: image redact exports decode pixels, optionally
burn in redaction rectangles, and encode a fresh PNG or JPEG. PDF exports render
pages to pixels, optionally burn in redaction rectangles, and generate a fresh
flattened PDF. Metadata-only image cleaning uses direct PNG/JPEG metadata
stripping when possible, and only transcodes pixels when the output format
changes. Metadata-only PDF cleaning renders pages to images and writes a new
flattened PDF.
