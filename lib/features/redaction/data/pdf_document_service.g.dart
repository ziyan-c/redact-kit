// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_document_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pdfDocumentService)
final pdfDocumentServiceProvider = PdfDocumentServiceProvider._();

final class PdfDocumentServiceProvider
    extends
        $FunctionalProvider<
          PdfDocumentService,
          PdfDocumentService,
          PdfDocumentService
        >
    with $Provider<PdfDocumentService> {
  PdfDocumentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfDocumentServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfDocumentServiceHash();

  @$internal
  @override
  $ProviderElement<PdfDocumentService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PdfDocumentService create(Ref ref) {
    return pdfDocumentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PdfDocumentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PdfDocumentService>(value),
    );
  }
}

String _$pdfDocumentServiceHash() =>
    r'cd6f285155884f38ad7e898a0fdc3b12515a7d34';
