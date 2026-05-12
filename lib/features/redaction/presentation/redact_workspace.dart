import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/redaction_controller.dart';
import '../domain/export_format.dart';
import '../domain/jpeg_quality_preset.dart';
import '../domain/redaction_state.dart';
import 'redaction_painter.dart';

class RedactWorkspace extends ConsumerWidget {
  const RedactWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(redactionControllerProvider);
    final controller = ref.read(redactionControllerProvider.notifier);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyO, meta: true): OpenImageIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            ExportImageIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            UndoRedactionIntent(),
        SingleActivator(LogicalKeyboardKey.backspace): ClearRedactionsIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          OpenImageIntent: CallbackAction<OpenImageIntent>(
            onInvoke: (_) => controller.openImage(),
          ),
          ExportImageIntent: CallbackAction<ExportImageIntent>(
            onInvoke: (_) => controller.exportImage(),
          ),
          UndoRedactionIntent: CallbackAction<UndoRedactionIntent>(
            onInvoke: (_) {
              controller.undo();
              return null;
            },
          ),
          ClearRedactionsIntent: CallbackAction<ClearRedactionsIntent>(
            onInvoke: (_) {
              controller.clear();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showSidePanel = constraints.maxWidth >= 900;

                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            _TopBar(
                              status: state.status,
                              canUndo: state.hasRedactions,
                              canClear: state.hasRedactions,
                              canExport: state.hasImage && !state.isExporting,
                              isOpening: state.isOpening,
                              isExporting: state.isExporting,
                              onOpen: controller.openImage,
                              onOpenPhotos: controller.openPhotoLibrary,
                              onUndo: controller.undo,
                              onClear: controller.clear,
                              onExport: controller.exportImage,
                              onShare: controller.shareImage,
                              onSaveToPhotos: controller.saveImageToPhotos,
                            ),
                            Expanded(child: _CanvasArea(state: state)),
                          ],
                        ),
                      ),
                      if (showSidePanel)
                        _SidePanel(
                          image: state.image,
                          redactionCount: state.redactions.length,
                          selectedColor: state.redactionColor,
                          exportFormat: state.exportFormat,
                          jpegQualityPreset: state.jpegQualityPreset,
                          onColorChanged: controller.selectColor,
                          onExportFormatChanged: controller.setExportFormat,
                          onJpegQualityPresetChanged:
                              controller.setJpegQualityPreset,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CanvasArea extends ConsumerWidget {
  const _CanvasArea({required this.state});

  final RedactionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(redactionControllerProvider.notifier);
    final image = state.image;

    if (image == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 0, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFCFA),
          border: Border.all(color: const Color(0xFFDCE2DC)),
        ),
        child: Center(
          child: FilledButton.icon(
            onPressed: state.isOpening ? null : controller.openImage,
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Image'),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 0, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFA),
        border: Border.all(color: const Color(0xFFDCE2DC)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final imageRect = _fitImageRect(image, size);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              controller.beginRedaction(details.localPosition, imageRect);
            },
            onPanUpdate: (details) {
              controller.updateRedaction(details.localPosition, imageRect);
            },
            onPanEnd: (_) => controller.finishRedaction(),
            onPanCancel: controller.finishRedaction,
            child: MouseRegion(
              cursor: SystemMouseCursors.precise,
              child: CustomPaint(
                painter: RedactionPainter(
                  image: image,
                  imageRect: imageRect,
                  redactions: state.redactions,
                  draftRect: state.draftRect,
                  draftColor: state.draftColor,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }

  Rect _fitImageRect(ui.Image image, Size bounds) {
    const padding = 24.0;
    final available = Size(
      math.max(1, bounds.width - padding * 2),
      math.max(1, bounds.height - padding * 2),
    );
    final scale = math.min(
      available.width / image.width,
      available.height / image.height,
    );
    final fitted = Size(image.width * scale, image.height * scale);

    return Rect.fromLTWH(
      (bounds.width - fitted.width) / 2,
      (bounds.height - fitted.height) / 2,
      fitted.width,
      fitted.height,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.status,
    required this.canUndo,
    required this.canClear,
    required this.canExport,
    required this.isOpening,
    required this.isExporting,
    required this.onOpen,
    required this.onOpenPhotos,
    required this.onUndo,
    required this.onClear,
    required this.onExport,
    required this.onShare,
    required this.onSaveToPhotos,
  });

  final String status;
  final bool canUndo;
  final bool canClear;
  final bool canExport;
  final bool isOpening;
  final bool isExporting;
  final VoidCallback onOpen;
  final VoidCallback onOpenPhotos;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onExport;
  final VoidCallback onShare;
  final VoidCallback onSaveToPhotos;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2DC))),
      ),
      child: Row(
        children: <Widget>[
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Redact Kit',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'macOS / iOS',
                style: TextStyle(
                  color: Color(0xFF637066),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Text(
              status,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF637066)),
            ),
          ),
          Tooltip(
            message: 'Open image',
            child: IconButton.filledTonal(
              onPressed: isOpening ? null : onOpen,
              icon: isOpening
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.folder_open),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Open from Photos',
            child: IconButton.outlined(
              onPressed: isOpening ? null : onOpenPhotos,
              icon: const Icon(Icons.photo_library_outlined),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Undo',
            child: IconButton.outlined(
              onPressed: canUndo ? onUndo : null,
              icon: const Icon(Icons.undo),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Clear',
            child: IconButton.outlined(
              onPressed: canClear ? onClear : null,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Save clean image',
            child: IconButton.filled(
              onPressed: canExport ? onExport : null,
              icon: isExporting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_alt),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Share clean image',
            child: IconButton.filledTonal(
              onPressed: canExport ? onShare : null,
              icon: const Icon(Icons.ios_share),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Save clean image to Photos',
            child: IconButton.filledTonal(
              onPressed: canExport ? onSaveToPhotos : null,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.image,
    required this.redactionCount,
    required this.selectedColor,
    required this.exportFormat,
    required this.jpegQualityPreset,
    required this.onColorChanged,
    required this.onExportFormatChanged,
    required this.onJpegQualityPresetChanged,
  });

  final ui.Image? image;
  final int redactionCount;
  final Color selectedColor;
  final ExportFormat exportFormat;
  final JpegQualityPreset jpegQualityPreset;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<ExportFormat> onExportFormatChanged;
  final ValueChanged<JpegQualityPreset> onJpegQualityPresetChanged;

  @override
  Widget build(BuildContext context) {
    final image = this.image;

    return Container(
      width: 320,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE2DC)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F19251F),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _PanelHeading('Tool'),
          Row(
            children: <Widget>[
              _ColorSwatchButton(
                color: const Color(0xFF050505),
                selected: selectedColor == const Color(0xFF050505),
                label: 'Black',
                onTap: () => onColorChanged(const Color(0xFF050505)),
              ),
              const SizedBox(width: 10),
              _ColorSwatchButton(
                color: Colors.white,
                selected: selectedColor == Colors.white,
                label: 'White',
                onTap: () => onColorChanged(Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 22),
          const _PanelHeading('Image'),
          _MetricRow(
            label: 'Pixels',
            value: image == null ? 'None' : '${image.width} x ${image.height}',
          ),
          _MetricRow(label: 'Redactions', value: '$redactionCount'),
          const _MetricRow(label: 'Cover', value: '100% opaque'),
          _MetricRow(label: 'Format', value: exportFormat.label),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 22),
          const _PanelHeading('Export'),
          _ExportFormatPicker(
            selected: exportFormat,
            onChanged: onExportFormatChanged,
          ),
          if (exportFormat == ExportFormat.jpeg) ...<Widget>[
            const SizedBox(height: 18),
            _JpegQualityPresetPicker(
              selected: jpegQualityPreset,
              onChanged: onJpegQualityPresetChanged,
            ),
          ],
          const Spacer(),
          Text(
            exportFormat == ExportFormat.png
                ? 'PNG is lossless. The exported file is rebuilt from visible pixels.'
                : 'JPEG is lossy. Lower quality makes smaller files.',
            style: const TextStyle(color: Color(0xFF637066), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ExportFormatPicker extends StatelessWidget {
  const _ExportFormatPicker({required this.selected, required this.onChanged});

  final ExportFormat selected;
  final ValueChanged<ExportFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ExportFormat>(
        showSelectedIcon: false,
        segments: ExportFormat.values
            .map(
              (format) => ButtonSegment<ExportFormat>(
                value: format,
                label: Text(format.label),
              ),
            )
            .toList(growable: false),
        selected: <ExportFormat>{selected},
        onSelectionChanged: (formats) => onChanged(formats.single),
      ),
    );
  }
}

class _JpegQualityPresetPicker extends StatelessWidget {
  const _JpegQualityPresetPicker({
    required this.selected,
    required this.onChanged,
  });

  final JpegQualityPreset selected;
  final ValueChanged<JpegQualityPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'JPEG quality',
                style: TextStyle(
                  color: Color(0xFF637066),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              selected.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<JpegQualityPreset>(
            showSelectedIcon: false,
            segments: JpegQualityPreset.values
                .map(
                  (preset) => ButtonSegment<JpegQualityPreset>(
                    value: preset,
                    label: Text(preset.label),
                  ),
                )
                .toList(growable: false),
            selected: <JpegQualityPreset>{selected},
            onSelectionChanged: (presets) => onChanged(presets.single),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          selected.description,
          style: const TextStyle(color: Color(0xFF637066), height: 1.35),
        ),
      ],
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF637066),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF637066),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFDCE2DC),
              width: selected ? 3 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

class OpenImageIntent extends Intent {
  const OpenImageIntent();
}

class ExportImageIntent extends Intent {
  const ExportImageIntent();
}

class UndoRedactionIntent extends Intent {
  const UndoRedactionIntent();
}

class ClearRedactionsIntent extends Intent {
  const ClearRedactionsIntent();
}
