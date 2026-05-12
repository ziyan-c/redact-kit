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
                  if (constraints.maxWidth < 600) {
                    return _MobileLayout(state: state);
                  }

                  if (constraints.maxWidth < 1000) {
                    return _TabletLayout(state: state);
                  }

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
                              onPrivacyDetails: () =>
                                  _showPrivacyDetails(context),
                            ),
                            Expanded(child: _CanvasArea(state: state)),
                          ],
                        ),
                      ),
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

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout({required this.state});

  final RedactionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(redactionControllerProvider.notifier);
    final canExport = state.hasImage && !state.isExporting;

    return Column(
      children: <Widget>[
        _MobileTopBar(
          status: state.status,
          onPrivacyDetails: () => _showPrivacyDetails(context),
          onSettings: () => _showExportSheet(context),
        ),
        Expanded(
          child: _CanvasArea(
            state: state,
            margin: EdgeInsets.zero,
            showBorder: false,
            fitPadding: 12,
            showPhotoButton: true,
          ),
        ),
        _MobileBottomBar(
          canUndo: state.hasRedactions,
          canClear: state.hasRedactions,
          isOpening: state.isOpening,
          canExport: canExport,
          onOpen: controller.openImage,
          onOpenPhotos: controller.openPhotoLibrary,
          onUndo: controller.undo,
          onClear: controller.clear,
          onExportOptions: () => _showExportSheet(context),
        ),
      ],
    );
  }
}

class _TabletLayout extends ConsumerWidget {
  const _TabletLayout({required this.state});

  final RedactionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(redactionControllerProvider.notifier);
    final canExport = state.hasImage && !state.isExporting;

    return Column(
      children: <Widget>[
        _TabletTopBar(
          status: state.status,
          canUndo: state.hasRedactions,
          canClear: state.hasRedactions,
          canExport: canExport,
          isOpening: state.isOpening,
          isExporting: state.isExporting,
          onOpen: controller.openImage,
          onOpenPhotos: controller.openPhotoLibrary,
          onUndo: controller.undo,
          onClear: controller.clear,
          onExport: controller.exportImage,
          onSaveToPhotos: controller.saveImageToPhotos,
          onShare: controller.shareImage,
          onPrivacyDetails: () => _showPrivacyDetails(context),
          onSettings: () => _showExportSheet(context),
        ),
        Expanded(
          child: _CanvasArea(
            state: state,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            fitPadding: 16,
            showPhotoButton: true,
          ),
        ),
      ],
    );
  }
}

class _TabletTopBar extends StatelessWidget {
  const _TabletTopBar({
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
    required this.onSaveToPhotos,
    required this.onShare,
    required this.onPrivacyDetails,
    required this.onSettings,
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
  final VoidCallback onSaveToPhotos;
  final VoidCallback onShare;
  final VoidCallback onPrivacyDetails;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2DC))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Redact Kit',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF637066),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _TopBarIconButton(
            tooltip: 'Open from Files',
            onPressed: isOpening ? null : onOpen,
            icon: isOpening
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open),
            tonal: true,
          ),
          _TopBarIconButton(
            tooltip: 'Open from Photos',
            onPressed: isOpening ? null : onOpenPhotos,
            icon: const Icon(Icons.photo_library_outlined),
          ),
          _TopBarIconButton(
            tooltip: 'Undo',
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo),
          ),
          _TopBarIconButton(
            tooltip: 'Clear',
            onPressed: canClear ? onClear : null,
            icon: const Icon(Icons.delete_outline),
          ),
          _TopBarIconButton(
            tooltip: 'Save to Files',
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
            filled: true,
          ),
          _TopBarIconButton(
            tooltip: 'Save to Photos',
            onPressed: canExport ? onSaveToPhotos : null,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tonal: true,
          ),
          _TopBarIconButton(
            tooltip: 'Share',
            onPressed: canExport ? onShare : null,
            icon: const Icon(Icons.ios_share),
            tonal: true,
          ),
          _TopBarIconButton(
            tooltip: 'Privacy details',
            onPressed: onPrivacyDetails,
            icon: const Icon(Icons.info_outline),
          ),
          _TopBarIconButton(
            tooltip: 'Settings',
            onPressed: onSettings,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.filled = false,
    this.tonal = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;
  final bool filled;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    Widget button;
    if (filled) {
      button = IconButton.filled(onPressed: onPressed, icon: icon);
    } else if (tonal) {
      button = IconButton.filledTonal(onPressed: onPressed, icon: icon);
    } else {
      button = IconButton.outlined(onPressed: onPressed, icon: icon);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: Tooltip(message: tooltip, child: button),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.status,
    required this.onPrivacyDetails,
    required this.onSettings,
  });

  final String status;
  final VoidCallback onPrivacyDetails;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2DC))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Redact Kit',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF637066),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Privacy details',
            child: IconButton(
              onPressed: onPrivacyDetails,
              icon: const Icon(Icons.info_outline),
            ),
          ),
          Tooltip(
            message: 'Settings',
            child: IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBottomBar extends StatelessWidget {
  const _MobileBottomBar({
    required this.canUndo,
    required this.canClear,
    required this.isOpening,
    required this.canExport,
    required this.onOpen,
    required this.onOpenPhotos,
    required this.onUndo,
    required this.onClear,
    required this.onExportOptions,
  });

  final bool canUndo;
  final bool canClear;
  final bool isOpening;
  final bool canExport;
  final VoidCallback onOpen;
  final VoidCallback onOpenPhotos;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onExportOptions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDCE2DC))),
      ),
      child: Row(
        children: <Widget>[
          _MobileToolbarItem(
            icon: Icons.folder_open,
            label: 'Files',
            onPressed: isOpening ? null : onOpen,
          ),
          _MobileToolbarItem(
            icon: Icons.photo_library_outlined,
            label: 'Photos',
            onPressed: isOpening ? null : onOpenPhotos,
          ),
          _MobileToolbarItem(
            icon: Icons.undo,
            label: 'Undo',
            onPressed: canUndo ? onUndo : null,
          ),
          _MobileToolbarItem(
            icon: Icons.delete_outline,
            label: 'Clear',
            onPressed: canClear ? onClear : null,
          ),
          _MobileToolbarItem(
            icon: canExport ? Icons.save_alt : Icons.tune,
            label: 'Export',
            onPressed: onExportOptions,
          ),
        ],
      ),
    );
  }
}

class _MobileToolbarItem extends StatelessWidget {
  const _MobileToolbarItem({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Tooltip(
        message: label,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            disabledForegroundColor: const Color(0xFF9AA49C),
            minimumSize: const Size(48, 56),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 22),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showExportSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(redactionControllerProvider);
          final controller = ref.read(redactionControllerProvider.notifier);
          final image = state.image;
          final canExport = state.hasImage && !state.isExporting;

          return SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.86,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Export',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Close',
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _PanelHeading('Tool'),
                    Row(
                      children: <Widget>[
                        _ColorSwatchButton(
                          color: const Color(0xFF050505),
                          selected:
                              state.redactionColor == const Color(0xFF050505),
                          label: 'Black',
                          onTap: () =>
                              controller.selectColor(const Color(0xFF050505)),
                        ),
                        const SizedBox(width: 10),
                        _ColorSwatchButton(
                          color: Colors.white,
                          selected: state.redactionColor == Colors.white,
                          label: 'White',
                          onTap: () => controller.selectColor(Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _PanelHeading('Image'),
                    _MetricRow(
                      label: 'Pixels',
                      value: image == null
                          ? 'None'
                          : '${image.width} x ${image.height}',
                    ),
                    _MetricRow(
                      label: 'Redactions',
                      value: '${state.redactions.length}',
                    ),
                    const _MetricRow(label: 'Cover', value: '100% opaque'),
                    const SizedBox(height: 22),
                    const Divider(height: 1),
                    const SizedBox(height: 22),
                    const _PanelHeading('Format'),
                    _ExportFormatPicker(
                      selected: state.exportFormat,
                      onChanged: controller.setExportFormat,
                    ),
                    if (state.exportFormat == ExportFormat.jpeg) ...<Widget>[
                      const SizedBox(height: 18),
                      _JpegQualityPresetPicker(
                        selected: state.jpegQualityPreset,
                        onChanged: controller.setJpegQualityPreset,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: canExport
                                ? () {
                                    Navigator.of(context).pop();
                                    controller.exportImage();
                                  }
                                : null,
                            icon: state.isExporting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_alt),
                            label: const Text(
                              'Save to Files',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: canExport
                                ? () {
                                    Navigator.of(context).pop();
                                    controller.saveImageToPhotos();
                                  }
                                : null,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: const Text(
                              'Save to Photos',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: canExport
                            ? () {
                                Navigator.of(context).pop();
                                controller.shareImage();
                              }
                            : null,
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void _showPrivacyDetails(BuildContext context) {
  final content = _PrivacyDetailsContent(
    onClose: () => Navigator.of(context).pop(),
  );

  if (MediaQuery.sizeOf(context).width < 600) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          ),
          child: content,
        ),
      ),
    );
    return;
  }

  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: content,
      ),
    ),
  );
}

class _PrivacyDetailsContent extends StatelessWidget {
  const _PrivacyDetailsContent({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Privacy & Export',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              Tooltip(
                message: 'Close',
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _PrivacyPoint(
            icon: Icons.grid_on_outlined,
            title: 'Pixel-level redaction',
            body:
                'Redaction boxes are burned into the raster as 100% opaque solid pixels. The exported image has no editable layer, hidden mask, or original pixels under the box.',
          ),
          const _PrivacyPoint(
            icon: Icons.auto_fix_high_outlined,
            title: 'Rebuilt from visible pixels',
            body:
                'Export creates a new PNG or JPEG from the rendered pixel buffer. It does not copy the original file container forward.',
          ),
          const _PrivacyPoint(
            icon: Icons.cleaning_services_outlined,
            title: 'Metadata removed',
            body:
                'PNG output keeps only IHDR, PLTE, IDAT, and IEND chunks. JPEG output removes APP0-APP15 and COM segments, which covers EXIF, GPS, IPTC, XMP, thumbnails, and comments.',
          ),
          const _PrivacyPoint(
            icon: Icons.tune_outlined,
            title: 'Format choice',
            body:
                'PNG keeps redaction pixels exact. JPEG makes smaller files and may slightly soften edges, but it cannot restore pixels that were already replaced. Just make sure the box fully covers the sensitive area.',
          ),
        ],
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF637066),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasArea extends ConsumerWidget {
  const _CanvasArea({
    required this.state,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 0, 16),
    this.showBorder = true,
    this.fitPadding = 24,
    this.showPhotoButton = false,
  });

  final RedactionState state;
  final EdgeInsetsGeometry margin;
  final bool showBorder;
  final double fitPadding;
  final bool showPhotoButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(redactionControllerProvider.notifier);
    final image = state.image;

    if (image == null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: const Color(0xFFFBFCFA),
          border: showBorder
              ? Border.all(color: const Color(0xFFDCE2DC))
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 220,
                child: FilledButton.icon(
                  onPressed: state.isOpening ? null : controller.openImage,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open from Files'),
                ),
              ),
              if (showPhotoButton)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    width: 220,
                    child: FilledButton.tonalIcon(
                      onPressed: state.isOpening
                          ? null
                          : controller.openPhotoLibrary,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Open from Photos'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFA),
        border: showBorder ? Border.all(color: const Color(0xFFDCE2DC)) : null,
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
    final available = Size(
      math.max(1, bounds.width - fitPadding * 2),
      math.max(1, bounds.height - fitPadding * 2),
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
    required this.onPrivacyDetails,
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
  final VoidCallback onPrivacyDetails;

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
            message: 'Open from Files',
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
            message: 'Save to Files',
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
            message: 'Save to Photos',
            child: IconButton.filledTonal(
              onPressed: canExport ? onSaveToPhotos : null,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Share',
            child: IconButton.filledTonal(
              onPressed: canExport ? onShare : null,
              icon: const Icon(Icons.ios_share),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Privacy details',
            child: IconButton.outlined(
              onPressed: onPrivacyDetails,
              icon: const Icon(Icons.info_outline),
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
