import 'package:flutter/foundation.dart';

enum MetadataInputDisplayKind { image, pdf, folder }

enum MetadataInputSummaryKind { folder, images, photos, pdfs, files }

@immutable
class MetadataInputSummary {
  const MetadataInputSummary._({
    required this.kind,
    required this.fallbackLabel,
    this.name,
    this.count,
  });

  factory MetadataInputSummary.folder(String name) {
    return MetadataInputSummary._(
      kind: MetadataInputSummaryKind.folder,
      name: name,
      fallbackLabel: 'Folder: $name',
    );
  }

  factory MetadataInputSummary.images(int count) {
    return MetadataInputSummary._(
      kind: MetadataInputSummaryKind.images,
      count: count,
      fallbackLabel: '$count image${count == 1 ? '' : 's'}',
    );
  }

  factory MetadataInputSummary.photos(int count) {
    return MetadataInputSummary._(
      kind: MetadataInputSummaryKind.photos,
      count: count,
      fallbackLabel: '$count photo${count == 1 ? '' : 's'}',
    );
  }

  factory MetadataInputSummary.pdfs(int count) {
    return MetadataInputSummary._(
      kind: MetadataInputSummaryKind.pdfs,
      count: count,
      fallbackLabel: '$count PDF${count == 1 ? '' : 's'}',
    );
  }

  factory MetadataInputSummary.files(int count) {
    return MetadataInputSummary._(
      kind: MetadataInputSummaryKind.files,
      count: count,
      fallbackLabel: '$count file${count == 1 ? '' : 's'}',
    );
  }

  final MetadataInputSummaryKind kind;
  final String fallbackLabel;
  final String? name;
  final int? count;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MetadataInputSummary &&
            kind == other.kind &&
            fallbackLabel == other.fallbackLabel &&
            name == other.name &&
            count == other.count;
  }

  @override
  int get hashCode => Object.hash(kind, fallbackLabel, name, count);
}

enum MetadataInputDetailKind { path, photoLibrary, image, pdf, contents }

@immutable
class MetadataInputDetail {
  const MetadataInputDetail._({
    required this.kind,
    required this.fallbackLabel,
    this.path,
    this.imageCount = 0,
    this.pdfCount = 0,
    this.ignoredCount = 0,
  });

  factory MetadataInputDetail.path(String path) {
    return MetadataInputDetail._(
      kind: MetadataInputDetailKind.path,
      path: path,
      fallbackLabel: path,
    );
  }

  const MetadataInputDetail.photoLibrary()
    : this._(
        kind: MetadataInputDetailKind.photoLibrary,
        fallbackLabel: 'Photo library',
      );

  const MetadataInputDetail.image()
    : this._(kind: MetadataInputDetailKind.image, fallbackLabel: 'Image');

  const MetadataInputDetail.pdf()
    : this._(kind: MetadataInputDetailKind.pdf, fallbackLabel: 'PDF');

  factory MetadataInputDetail.contents({
    required int imageCount,
    required int pdfCount,
    required int ignoredCount,
  }) {
    final parts = <String>[
      if (imageCount > 0) '$imageCount image${imageCount == 1 ? '' : 's'}',
      if (pdfCount > 0) '$pdfCount PDF${pdfCount == 1 ? '' : 's'}',
      if (ignoredCount > 0) '$ignoredCount ignored',
    ];
    return MetadataInputDetail._(
      kind: MetadataInputDetailKind.contents,
      imageCount: imageCount,
      pdfCount: pdfCount,
      ignoredCount: ignoredCount,
      fallbackLabel: parts.join(', '),
    );
  }

  final MetadataInputDetailKind kind;
  final String fallbackLabel;
  final String? path;
  final int imageCount;
  final int pdfCount;
  final int ignoredCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MetadataInputDetail &&
            kind == other.kind &&
            fallbackLabel == other.fallbackLabel &&
            path == other.path &&
            imageCount == other.imageCount &&
            pdfCount == other.pdfCount &&
            ignoredCount == other.ignoredCount;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    fallbackLabel,
    path,
    imageCount,
    pdfCount,
    ignoredCount,
  );
}

@immutable
class MetadataInputDisplayItem {
  const MetadataInputDisplayItem({
    required this.kind,
    required this.label,
    required this.detail,
  });

  final MetadataInputDisplayKind kind;
  final String label;
  final MetadataInputDetail detail;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MetadataInputDisplayItem &&
            kind == other.kind &&
            label == other.label &&
            detail == other.detail;
  }

  @override
  int get hashCode => Object.hash(kind, label, detail);
}
