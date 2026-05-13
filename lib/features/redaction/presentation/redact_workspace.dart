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

enum _WorkspaceMode { redact, metadata }

class RedactWorkspace extends ConsumerStatefulWidget {
  const RedactWorkspace({super.key});

  @override
  ConsumerState<RedactWorkspace> createState() => _RedactWorkspaceState();
}

class _RedactWorkspaceState extends ConsumerState<RedactWorkspace> {
  _WorkspaceMode _mode = _WorkspaceMode.redact;

  @override
  Widget build(BuildContext context) {
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
                    return _MobileLayout(
                      state: state,
                      mode: _mode,
                      onModeChanged: _setMode,
                    );
                  }

                  if (constraints.maxWidth < 1100) {
                    return _TabletLayout(
                      state: state,
                      mode: _mode,
                      onModeChanged: _setMode,
                    );
                  }

                  return Column(
                    children: <Widget>[
                      _TopBar(
                        mode: _mode,
                        onModeChanged: _setMode,
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
                        onHelp: () => _mode == _WorkspaceMode.redact
                            ? _showRedactDetails(context)
                            : _showMetadataDetails(context),
                      ),
                      Expanded(
                        child: _mode == _WorkspaceMode.redact
                            ? Row(
                                children: <Widget>[
                                  Expanded(child: _CanvasArea(state: state)),
                                  _SidePanel(
                                    image: state.image,
                                    redactionCount: state.redactions.length,
                                    selectedColor: state.redactionColor,
                                    exportFormat: state.exportFormat,
                                    jpegQualityPreset: state.jpegQualityPreset,
                                    preserveRedactionExportFileName:
                                        state.preserveRedactionExportFileName,
                                    onColorChanged: controller.selectColor,
                                    onExportFormatChanged:
                                        controller.setExportFormat,
                                    onJpegQualityPresetChanged:
                                        controller.setJpegQualityPreset,
                                    onPreserveRedactionExportFileNameChanged:
                                        controller
                                            .setPreserveRedactionExportFileName,
                                  ),
                                ],
                              )
                            : _MetadataCleanerView(state: state, desktop: true),
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

  void _setMode(_WorkspaceMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
    });
  }
}

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout({
    required this.state,
    required this.mode,
    required this.onModeChanged,
  });

  final RedactionState state;
  final _WorkspaceMode mode;
  final ValueChanged<_WorkspaceMode> onModeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(redactionControllerProvider.notifier);
    final canExport = state.hasImage && !state.isExporting;

    return Column(
      children: <Widget>[
        _MobileTopBar(
          status: state.status,
          onHelp: () => mode == _WorkspaceMode.redact
              ? _showRedactDetails(context)
              : _showMetadataDetails(context),
          onSettings: mode == _WorkspaceMode.redact
              ? () => _showExportSheet(context)
              : null,
        ),
        _ModeSwitcherBand(mode: mode, onModeChanged: onModeChanged),
        Expanded(
          child: mode == _WorkspaceMode.redact
              ? _CanvasArea(
                  state: state,
                  margin: EdgeInsets.zero,
                  showBorder: false,
                  fitPadding: 12,
                  showPhotoButton: true,
                  enablePanZoom: true,
                )
              : _MetadataCleanerView(state: state, desktop: false),
        ),
        if (mode == _WorkspaceMode.redact)
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
  const _TabletLayout({
    required this.state,
    required this.mode,
    required this.onModeChanged,
  });

  final RedactionState state;
  final _WorkspaceMode mode;
  final ValueChanged<_WorkspaceMode> onModeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(redactionControllerProvider.notifier);
    final canExport = state.hasImage && !state.isExporting;

    return Column(
      children: <Widget>[
        _TabletTopBar(
          mode: mode,
          onModeChanged: onModeChanged,
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
          onHelp: () => mode == _WorkspaceMode.redact
              ? _showRedactDetails(context)
              : _showMetadataDetails(context),
          onSettings: mode == _WorkspaceMode.redact
              ? () => _showExportSheet(context)
              : null,
        ),
        Expanded(
          child: mode == _WorkspaceMode.redact
              ? _CanvasArea(
                  state: state,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  fitPadding: 16,
                  showPhotoButton: true,
                  enablePanZoom: true,
                )
              : _MetadataCleanerView(state: state, desktop: false),
        ),
      ],
    );
  }
}

class _TabletTopBar extends StatelessWidget {
  const _TabletTopBar({
    required this.mode,
    required this.onModeChanged,
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
    required this.onHelp,
    required this.onSettings,
  });

  final _WorkspaceMode mode;
  final ValueChanged<_WorkspaceMode> onModeChanged;
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
  final VoidCallback onHelp;
  final VoidCallback? onSettings;

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
          SizedBox(
            width: 260,
            child: _ModeSwitcher(mode: mode, onModeChanged: onModeChanged),
          ),
          if (mode == _WorkspaceMode.redact) ...<Widget>[
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
          ],
          _TopBarIconButton(
            tooltip: mode == _WorkspaceMode.redact
                ? 'Redact details'
                : 'Metadata details',
            onPressed: onHelp,
            icon: const Icon(Icons.info_outline),
          ),
          if (onSettings != null)
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

class _ModeSwitcherBand extends StatelessWidget {
  const _ModeSwitcherBand({required this.mode, required this.onModeChanged});

  final _WorkspaceMode mode;
  final ValueChanged<_WorkspaceMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2DC))),
      ),
      child: _ModeSwitcher(mode: mode, onModeChanged: onModeChanged),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.mode, required this.onModeChanged});

  final _WorkspaceMode mode;
  final ValueChanged<_WorkspaceMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_WorkspaceMode>(
        showSelectedIcon: false,
        segments: const <ButtonSegment<_WorkspaceMode>>[
          ButtonSegment<_WorkspaceMode>(
            value: _WorkspaceMode.redact,
            icon: Icon(Icons.crop_square),
            label: Text('Redact'),
          ),
          ButtonSegment<_WorkspaceMode>(
            value: _WorkspaceMode.metadata,
            icon: Icon(Icons.cleaning_services_outlined),
            label: Text('Metadata'),
          ),
        ],
        selected: <_WorkspaceMode>{mode},
        onSelectionChanged: (modes) => onModeChanged(modes.single),
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.status,
    required this.onHelp,
    required this.onSettings,
  });

  final String status;
  final VoidCallback onHelp;
  final VoidCallback? onSettings;

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
            message: 'Details',
            child: IconButton(
              onPressed: onHelp,
              icon: const Icon(Icons.info_outline),
            ),
          ),
          if (onSettings != null)
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
                    const SizedBox(height: 18),
                    _KeepFilenamesToggle(
                      label: 'Keep filename',
                      value: state.preserveRedactionExportFileName,
                      onChanged: controller.setPreserveRedactionExportFileName,
                    ),
                    const SizedBox(height: 18),
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

void _showRedactDetails(BuildContext context) {
  _showDetails(
    context,
    _RedactDetailsContent(onClose: () => Navigator.of(context).pop()),
  );
}

void _showMetadataDetails(BuildContext context) {
  _showDetails(
    context,
    _MetadataDetailsContent(onClose: () => Navigator.of(context).pop()),
  );
}

void _showDetails(BuildContext context, Widget content) {
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

class _RedactDetailsContent extends StatelessWidget {
  const _RedactDetailsContent({required this.onClose});

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
                'Redact export always rebuilds the image and removes metadata. PNG keeps only IHDR, PLTE, IDAT, and IEND chunks. JPEG removes APP0-APP15 and COM segments.',
          ),
          const _PrivacyPoint(
            icon: Icons.badge_outlined,
            title: 'File names',
            body:
                'Exports start with a generic name. The Keep filename option only preserves the visible file name, not image metadata.',
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

class _MetadataDetailsContent extends StatelessWidget {
  const _MetadataDetailsContent({required this.onClose});

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
                  'Clean Metadata',
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
            icon: Icons.photo_library_outlined,
            title: 'Batch input',
            body:
                'Choose one image, multiple images, a folder on desktop, or Photos on mobile. This mode does not draw redaction boxes.',
          ),
          const _PrivacyPoint(
            icon: Icons.auto_fix_high_outlined,
            title: 'Fast clean path',
            body:
                'PNG-to-PNG and JPEG-to-JPEG outputs strip metadata directly from a copied file container. Format changes decode visible pixels and encode a fresh clean file.',
          ),
          const _PrivacyPoint(
            icon: Icons.cleaning_services_outlined,
            title: 'Metadata removed',
            body:
                'PNG output keeps only IHDR, PLTE, IDAT, and IEND chunks. JPEG output removes APP0-APP15 and COM segments, covering EXIF, GPS, IPTC, XMP, thumbnails, and comments.',
          ),
          const _PrivacyPoint(
            icon: Icons.drive_file_rename_outline,
            title: 'File names',
            body:
                'Generic names are used unless Keep filenames is enabled. Preserved names are sanitized and deduplicated inside the output folder.',
          ),
          const _PrivacyPoint(
            icon: Icons.folder_copy_outlined,
            title: 'Output',
            body:
                'Single images and multi-image picks save directly into the app Cleaned folder unless you choose another output folder. Folder input creates a Cleaned subfolder named with -metadata-removed and writes only cleaned images into it.',
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

class _MetadataCleanerView extends ConsumerWidget {
  const _MetadataCleanerView({required this.state, required this.desktop});

  final RedactionState state;
  final bool desktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(redactionControllerProvider.notifier);
    final canClean = !state.isOpening && !state.isExporting;
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: desktop ? 720 : double.infinity),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          desktop ? 28 : 20,
          desktop ? 28 : 20,
          desktop ? 28 : 20,
          28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Clean Metadata',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _PanelHeading('Input'),
            if (desktop)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: canClean
                        ? controller.chooseMetadataImageFromFiles
                        : null,
                    icon: state.isOpening
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.image_outlined),
                    label: const Text('Choose Image'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: canClean
                        ? controller.chooseMetadataImagesFromFiles
                        : null,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose Images'),
                  ),
                  OutlinedButton.icon(
                    onPressed: canClean
                        ? controller.chooseMetadataFolder
                        : null,
                    icon: const Icon(Icons.folder_copy_outlined),
                    label: const Text('Choose Folder'),
                  ),
                ],
              )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canClean
                          ? controller.chooseMetadataImagesFromFiles
                          : null,
                      icon: const Icon(Icons.folder_copy_outlined),
                      label: const Text('Files'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: canClean
                          ? controller.chooseMetadataImagesFromPhotos
                          : null,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Photos'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            _KeepFilenamesToggle(
              label: 'Keep filenames',
              value: state.preserveMetadataCleanFileNames,
              onChanged: canClean
                  ? controller.setPreserveMetadataCleanFileNames
                  : null,
            ),
            const SizedBox(height: 14),
            _MetadataInputSummary(
              label: state.metadataInputLabel ?? 'No input selected',
              description:
                  state.metadataInputDescription ??
                  'Choose an image, multiple images, or a folder.',
              selected: state.hasMetadataInput,
            ),
            const SizedBox(height: 26),
            const Divider(height: 1),
            const SizedBox(height: 24),
            const _PanelHeading('Output'),
            _MetadataOutputFolderPicker(
              displayName:
                  state.metadataOutputDirectoryDisplayName ??
                  (desktop
                      ? 'Choose input to preview output'
                      : 'Output: app Cleaned folder'),
              path: state.metadataOutputDirectoryPath,
              onChoose: desktop && canClean && state.hasMetadataInput
                  ? controller.chooseMetadataOutputFolder
                  : null,
              onOpen:
                  desktop &&
                      canClean &&
                      state.metadataOutputDirectoryPath != null
                  ? controller.openMetadataOutputFolder
                  : null,
            ),
            const SizedBox(height: 26),
            const Divider(height: 1),
            const SizedBox(height: 24),
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
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canClean && state.hasMetadataInput
                    ? controller.startMetadataClean
                    : null,
                icon: state.isExporting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
            ),
            if (state.isCleaningMetadata) ...<Widget>[
              const SizedBox(height: 14),
              _MetadataProgressBanner(
                progress: state.metadataCleanProgress,
                status: state.status,
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'PNG/JPEG keep the same format by stripping metadata directly. Format changes rebuild the visible pixels into a new clean file.',
              style: TextStyle(color: Color(0xFF637066), height: 1.35),
            ),
          ],
        ),
      ),
    );

    return Container(
      width: double.infinity,
      color: const Color(0xFFFBFCFA),
      child: Align(
        alignment: desktop ? Alignment.topCenter : Alignment.topLeft,
        child: content,
      ),
    );
  }
}

class _MetadataProgressBanner extends StatelessWidget {
  const _MetadataProgressBanner({required this.progress, required this.status});

  final double? progress;
  final String status;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress?.clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDCE2DC)),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: clampedProgress),
        ],
      ),
    );
  }
}

class _MetadataInputSummary extends StatelessWidget {
  const _MetadataInputSummary({
    required this.label,
    required this.description,
    required this.selected,
  });

  final String label;
  final String description;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDCE2DC)),
        color: selected ? Colors.white : const Color(0xFFF4F7F3),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            selected ? Icons.check_circle_outline : Icons.inbox_outlined,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFF637066),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF637066),
                    fontSize: 12,
                    height: 1.25,
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

class _MetadataOutputFolderPicker extends StatelessWidget {
  const _MetadataOutputFolderPicker({
    required this.displayName,
    required this.path,
    required this.onChoose,
    required this.onOpen,
  });

  final String displayName;
  final String? path;
  final VoidCallback? onChoose;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Tooltip(
          message: path ?? displayName,
          waitDuration: const Duration(milliseconds: 450),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  _showMetadataOutputDetails(context, displayName, path),
              onLongPress: () =>
                  _showMetadataOutputDetails(context, displayName, path),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDCE2DC)),
                  color: Colors.white,
                ),
                child: Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF637066),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onChoose != null || onOpen != null) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              if (onOpen != null)
                OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open Folder'),
                ),
              if (onChoose != null)
                OutlinedButton.icon(
                  onPressed: onChoose,
                  icon: const Icon(Icons.drive_folder_upload_outlined),
                  label: const Text('Choose Folder'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

void _showMetadataOutputDetails(
  BuildContext context,
  String output,
  String? path,
) {
  final copyValue = path ?? output;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Full Output',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDCE2DC)),
                  color: const Color(0xFFF7F9F6),
                ),
                child: SelectableText(
                  output,
                  style: const TextStyle(
                    color: Color(0xFF26312A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (path != null && path != output) ...<Widget>[
                const SizedBox(height: 12),
                const Text(
                  'Folder Path',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDCE2DC)),
                    color: const Color(0xFFF7F9F6),
                  ),
                  child: SelectableText(
                    path,
                    style: const TextStyle(
                      color: Color(0xFF26312A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: copyValue));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Output copied')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _CanvasArea extends ConsumerWidget {
  const _CanvasArea({
    required this.state,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 0, 16),
    this.showBorder = true,
    this.fitPadding = 24,
    this.showPhotoButton = false,
    this.enablePanZoom = false,
  });

  final RedactionState state;
  final EdgeInsetsGeometry margin;
  final bool showBorder;
  final double fitPadding;
  final bool showPhotoButton;
  final bool enablePanZoom;

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

          if (enablePanZoom) {
            return _ZoomableRedactionCanvas(
              state: state,
              image: image,
              imageRect: imageRect,
              canvasSize: size,
              controller: controller,
            );
          }

          return _PlainRedactionCanvas(
            state: state,
            image: image,
            imageRect: imageRect,
            controller: controller,
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

class _PlainRedactionCanvas extends StatelessWidget {
  const _PlainRedactionCanvas({
    required this.state,
    required this.image,
    required this.imageRect,
    required this.controller,
  });

  final RedactionState state;
  final ui.Image image;
  final Rect imageRect;
  final RedactionController controller;

  @override
  Widget build(BuildContext context) {
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
      child: _RedactionPaintSurface(
        state: state,
        image: image,
        imageRect: imageRect,
      ),
    );
  }
}

enum _CanvasGestureMode { draw, zoom }

class _ZoomableRedactionCanvas extends StatefulWidget {
  const _ZoomableRedactionCanvas({
    required this.state,
    required this.image,
    required this.imageRect,
    required this.canvasSize,
    required this.controller,
  });

  final RedactionState state;
  final ui.Image image;
  final Rect imageRect;
  final Size canvasSize;
  final RedactionController controller;

  @override
  State<_ZoomableRedactionCanvas> createState() =>
      _ZoomableRedactionCanvasState();
}

class _ZoomableRedactionCanvasState extends State<_ZoomableRedactionCanvas> {
  static const double _minScale = 1;
  static const double _maxScale = 6;

  double _scale = _minScale;
  double _gestureStartScale = _minScale;
  Offset _offset = Offset.zero;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocalPoint = Offset.zero;
  _CanvasGestureMode? _gestureMode;

  @override
  void didUpdateWidget(covariant _ZoomableRedactionCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _scale = _minScale;
      _gestureStartScale = _minScale;
      _offset = Offset.zero;
      _gestureStartOffset = Offset.zero;
      _gestureStartFocalPoint = Offset.zero;
      _gestureMode = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOffset = _clampOffset(_offset, _scale, widget.canvasSize);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) {
        _gestureStartScale = _scale;
        _gestureStartOffset = effectiveOffset;
        _gestureStartFocalPoint = details.localFocalPoint;

        if (details.pointerCount >= 2) {
          _gestureMode = _CanvasGestureMode.zoom;
          widget.controller.finishRedaction();
          return;
        }

        _gestureMode = _CanvasGestureMode.draw;
        widget.controller.beginRedaction(
          _toCanvasPoint(details.localFocalPoint, effectiveOffset),
          widget.imageRect,
        );
      },
      onScaleUpdate: (details) {
        if (details.pointerCount >= 2) {
          if (_gestureMode != _CanvasGestureMode.zoom) {
            _gestureMode = _CanvasGestureMode.zoom;
            widget.controller.finishRedaction();
            _gestureStartScale = _scale;
            _gestureStartOffset = effectiveOffset;
            _gestureStartFocalPoint = details.localFocalPoint;
          }

          final nextScale = (_gestureStartScale * details.scale).clamp(
            _minScale,
            _maxScale,
          );
          final focalCanvasPoint =
              (_gestureStartFocalPoint - _gestureStartOffset) /
              _gestureStartScale;
          final nextOffset =
              details.localFocalPoint - focalCanvasPoint * nextScale;

          setState(() {
            _scale = nextScale;
            _offset = _clampOffset(nextOffset, nextScale, widget.canvasSize);
          });
          return;
        }

        if (_gestureMode == _CanvasGestureMode.draw) {
          widget.controller.updateRedaction(
            _toCanvasPoint(details.localFocalPoint, effectiveOffset),
            widget.imageRect,
          );
        }
      },
      onScaleEnd: (_) {
        if (_gestureMode == _CanvasGestureMode.draw) {
          widget.controller.finishRedaction();
        }
        _gestureMode = null;
      },
      child: ClipRect(
        child: Transform.translate(
          offset: effectiveOffset,
          child: Transform.scale(
            scale: _scale,
            alignment: Alignment.topLeft,
            child: SizedBox.fromSize(
              size: widget.canvasSize,
              child: _RedactionPaintSurface(
                state: widget.state,
                image: widget.image,
                imageRect: widget.imageRect,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset _toCanvasPoint(Offset localPosition, Offset effectiveOffset) {
    return (localPosition - effectiveOffset) / _scale;
  }

  Offset _clampOffset(Offset offset, double scale, Size bounds) {
    if (scale <= _minScale) return Offset.zero;

    final minDx = bounds.width - bounds.width * scale;
    final minDy = bounds.height - bounds.height * scale;
    return Offset(
      offset.dx.clamp(minDx, 0.0).toDouble(),
      offset.dy.clamp(minDy, 0.0).toDouble(),
    );
  }
}

class _RedactionPaintSurface extends StatelessWidget {
  const _RedactionPaintSurface({
    required this.state,
    required this.image,
    required this.imageRect,
  });

  final RedactionState state;
  final ui.Image image;
  final Rect imageRect;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.mode,
    required this.onModeChanged,
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
    required this.onHelp,
  });

  final _WorkspaceMode mode;
  final ValueChanged<_WorkspaceMode> onModeChanged;
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
  final VoidCallback onHelp;

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
          const Text(
            'Redact Kit',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 22),
          SizedBox(
            width: 280,
            child: _ModeSwitcher(mode: mode, onModeChanged: onModeChanged),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              status,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF637066)),
            ),
          ),
          if (mode == _WorkspaceMode.redact) ...<Widget>[
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
          ],
          Tooltip(
            message: mode == _WorkspaceMode.redact
                ? 'Redact details'
                : 'Metadata details',
            child: IconButton.outlined(
              onPressed: onHelp,
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
    required this.preserveRedactionExportFileName,
    required this.onColorChanged,
    required this.onExportFormatChanged,
    required this.onJpegQualityPresetChanged,
    required this.onPreserveRedactionExportFileNameChanged,
  });

  final ui.Image? image;
  final int redactionCount;
  final Color selectedColor;
  final ExportFormat exportFormat;
  final JpegQualityPreset jpegQualityPreset;
  final bool preserveRedactionExportFileName;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<ExportFormat> onExportFormatChanged;
  final ValueChanged<JpegQualityPreset> onJpegQualityPresetChanged;
  final ValueChanged<bool> onPreserveRedactionExportFileNameChanged;

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
      child: SingleChildScrollView(
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
              value: image == null
                  ? 'None'
                  : '${image.width} x ${image.height}',
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
            const SizedBox(height: 18),
            _KeepFilenamesToggle(
              label: 'Keep filename',
              value: preserveRedactionExportFileName,
              onChanged: onPreserveRedactionExportFileNameChanged,
            ),
            const SizedBox(height: 18),
            Text(
              exportFormat == ExportFormat.png
                  ? 'PNG is lossless. The exported file is rebuilt from visible pixels.'
                  : 'JPEG is lossy. Lower quality makes smaller files.',
              style: const TextStyle(color: Color(0xFF637066), height: 1.35),
            ),
          ],
        ),
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

class _KeepFilenamesToggle extends StatelessWidget {
  const _KeepFilenamesToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: <Widget>[
              Checkbox(
                value: value,
                onChanged: enabled ? (checked) => onChanged!(checked!) : null,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled ? null : const Color(0xFF9AA49C),
                    fontWeight: FontWeight.w600,
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
