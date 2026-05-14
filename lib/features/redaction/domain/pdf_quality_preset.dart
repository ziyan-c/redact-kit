import 'jpeg_quality_preset.dart';

enum PdfQualityPreset {
  low(
    label: 'Low',
    jpegQualityPreset: JpegQualityPreset.low,
    renderScale: 1.0,
    maxRenderedSide: 1600,
    description: 'Smallest PDFs, softer page images.',
  ),
  medium(
    label: 'Medium',
    jpegQualityPreset: JpegQualityPreset.medium,
    renderScale: 1.5,
    maxRenderedSide: 2200,
    description: 'Balanced readability and file size.',
  ),
  high(
    label: 'High',
    jpegQualityPreset: JpegQualityPreset.high,
    renderScale: 2.0,
    maxRenderedSide: 2600,
    description: 'Sharper pages, larger flattened PDFs.',
  );

  const PdfQualityPreset({
    required this.label,
    required this.jpegQualityPreset,
    required this.renderScale,
    required this.maxRenderedSide,
    required this.description,
  });

  final String label;
  final JpegQualityPreset jpegQualityPreset;
  final double renderScale;
  final double maxRenderedSide;
  final String description;
}
