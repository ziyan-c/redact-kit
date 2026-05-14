import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pdf_document_service.g.dart';

class PdfDocumentService {
  const PdfDocumentService();

  Future<PdfDocumentHandle> openData(Uint8List bytes) async {
    final document = await pdfx.PdfDocument.openData(bytes);
    return PdfxDocumentHandle(document);
  }
}

abstract class PdfDocumentHandle {
  int get pagesCount;

  Future<PdfRenderedPage> renderPage(
    int pageNumber, {
    double preferredScale = pdfDefaultPreferredRenderScale,
    double maxRenderedSide = pdfDefaultMaxRenderedSide,
  });

  Future<void> close();
}

class PdfRenderedPage {
  const PdfRenderedPage({
    required this.pageNumber,
    required this.width,
    required this.height,
    required this.pageWidth,
    required this.pageHeight,
    required this.pngBytes,
  });

  final int pageNumber;
  final int width;
  final int height;
  final double pageWidth;
  final double pageHeight;
  final Uint8List pngBytes;
}

class PdfxDocumentHandle implements PdfDocumentHandle {
  PdfxDocumentHandle(this._document);

  final pdfx.PdfDocument _document;

  @override
  int get pagesCount => _document.pagesCount;

  @override
  Future<PdfRenderedPage> renderPage(
    int pageNumber, {
    double preferredScale = pdfDefaultPreferredRenderScale,
    double maxRenderedSide = pdfDefaultMaxRenderedSide,
  }) async {
    final page = await _document.getPage(pageNumber);
    try {
      final scale = pdfRenderScaleForPage(
        page.width,
        page.height,
        preferredScale: preferredScale,
        maxRenderedSide: maxRenderedSide,
      );
      final image = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: pdfx.PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      if (image == null || image.width == null || image.height == null) {
        throw StateError('PDF page render failed.');
      }

      return PdfRenderedPage(
        pageNumber: pageNumber,
        width: image.width!,
        height: image.height!,
        pageWidth: page.width,
        pageHeight: page.height,
        pngBytes: image.bytes,
      );
    } finally {
      await page.close();
    }
  }

  @override
  Future<void> close() => _document.close();
}

const pdfDefaultPreferredRenderScale = 2.0;
const pdfDefaultMaxRenderedSide = 2600.0;

double pdfRenderScaleForPage(
  double width,
  double height, {
  double preferredScale = pdfDefaultPreferredRenderScale,
  double maxRenderedSide = pdfDefaultMaxRenderedSide,
}) {
  final maxSide = math.max(width, height);
  if (maxSide <= 0) return preferredScale;

  return math.min(preferredScale, maxRenderedSide / maxSide).clamp(1.0, 2.0);
}

@riverpod
PdfDocumentService pdfDocumentService(Ref ref) {
  return const PdfDocumentService();
}
