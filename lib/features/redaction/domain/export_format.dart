enum ExportFormat {
  png(
    label: 'PNG',
    extension: 'png',
    mimeType: 'image/png',
    uniformTypeIdentifier: 'public.png',
  ),
  jpeg(
    label: 'JPEG',
    extension: 'jpg',
    mimeType: 'image/jpeg',
    uniformTypeIdentifier: 'public.jpeg',
  );

  const ExportFormat({
    required this.label,
    required this.extension,
    required this.mimeType,
    required this.uniformTypeIdentifier,
  });

  final String label;
  final String extension;
  final String mimeType;
  final String uniformTypeIdentifier;

  String get defaultFileName => 'redacted-clean.$extension';
}
