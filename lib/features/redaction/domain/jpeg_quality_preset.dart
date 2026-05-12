enum JpegQualityPreset {
  low(
    label: 'Low',
    quality: 60,
    description: 'Smallest file, more visible loss.',
  ),
  medium(
    label: 'Medium',
    quality: 82,
    description: 'Balanced size and image quality.',
  ),
  high(label: 'High', quality: 92, description: 'Larger file, cleaner image.');

  const JpegQualityPreset({
    required this.label,
    required this.quality,
    required this.description,
  });

  final String label;
  final int quality;
  final String description;
}
