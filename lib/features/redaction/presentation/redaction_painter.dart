import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/redaction_region.dart';

class RedactionPainter extends CustomPainter {
  RedactionPainter({
    required this.image,
    required this.imageRect,
    required this.redactions,
    required this.draftRect,
    required this.draftColor,
  });

  final ui.Image image;
  final Rect imageRect;
  final List<RedactionRegion> redactions;
  final Rect? draftRect;
  final Color? draftColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);

    final sourceRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(
      image,
      sourceRect,
      imageRect,
      Paint()..filterQuality = FilterQuality.high,
    );

    for (final redaction in redactions) {
      canvas.drawRect(
        _toDisplayRect(redaction.rect),
        Paint()..color = redaction.color,
      );
    }

    final draft = draftRect;
    final color = draftColor;
    if (draft != null && color != null) {
      final displayDraft = _toDisplayRect(draft);
      canvas.drawRect(displayDraft, Paint()..color = color);
      canvas.drawRect(
        displayDraft.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
    }

    canvas.drawRect(
      imageRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x33000000),
    );
  }

  void _paintGrid(Canvas canvas, Size size) {
    const spacing = 32.0;
    final paint = Paint()
      ..color = const Color(0x10494FDF)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  Rect _toDisplayRect(Rect imageSpaceRect) {
    final scaleX = imageRect.width / image.width;
    final scaleY = imageRect.height / image.height;

    return Rect.fromLTRB(
      imageRect.left + imageSpaceRect.left * scaleX,
      imageRect.top + imageSpaceRect.top * scaleY,
      imageRect.left + imageSpaceRect.right * scaleX,
      imageRect.top + imageSpaceRect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(covariant RedactionPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.redactions != redactions ||
        oldDelegate.draftRect != draftRect ||
        oldDelegate.draftColor != draftColor;
  }
}
