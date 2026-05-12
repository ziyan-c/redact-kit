enum ExportFormat {
  png(label: 'PNG', extension: 'png'),
  jpeg(label: 'JPEG', extension: 'jpg');

  const ExportFormat({required this.label, required this.extension});

  final String label;
  final String extension;

  String get defaultFileName => 'redacted-clean.$extension';
}
