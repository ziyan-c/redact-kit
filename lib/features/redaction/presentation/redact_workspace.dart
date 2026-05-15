import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/platform_style.dart';
import '../application/redaction_controller.dart';
import '../domain/export_format.dart';
import '../domain/jpeg_quality_preset.dart';
import '../domain/pdf_quality_preset.dart';
import '../domain/redaction_region.dart';
import '../domain/redaction_state.dart';
import 'redaction_painter.dart';

enum _WorkspaceMode { redact, pdf, metadata }

class RedactWorkspace extends ConsumerStatefulWidget {
  const RedactWorkspace({super.key});

  @override
  ConsumerState<RedactWorkspace> createState() => _RedactWorkspaceState();
}

class _RedactWorkspaceState extends ConsumerState<RedactWorkspace> {
  _WorkspaceMode _mode = _WorkspaceMode.redact;
  String? _lastCompletionNoticeStatus;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(redactionControllerProvider);
    final controller = ref.read(redactionControllerProvider.notifier);
    ref.listen<RedactionState>(
      redactionControllerProvider,
      _showCompletionNoticeWhenFinished,
    );

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
            onInvoke: (_) => _mode == _WorkspaceMode.pdf
                ? controller.openPdf()
                : controller.openImage(),
          ),
          ExportImageIntent: CallbackAction<ExportImageIntent>(
            onInvoke: (_) => _mode == _WorkspaceMode.pdf
                ? controller.exportPdf()
                : controller.exportImage(),
          ),
          UndoRedactionIntent: CallbackAction<UndoRedactionIntent>(
            onInvoke: (_) {
              if (_mode == _WorkspaceMode.pdf) {
                controller.undoPdfRedaction();
              } else {
                controller.undo();
              }
              return null;
            },
          ),
          ClearRedactionsIntent: CallbackAction<ClearRedactionsIntent>(
            onInvoke: (_) {
              if (_mode == _WorkspaceMode.pdf) {
                controller.clearPdfPageRedactions();
              } else {
                controller.clear();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: CupertinoPageScaffold(
            backgroundColor: redactKitBackgroundColor,
            child: SafeArea(
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

                  return _DesktopLayout(
                    state: state,
                    mode: _mode,
                    onModeChanged: _setMode,
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

  void _showCompletionNoticeWhenFinished(
    RedactionState? previous,
    RedactionState next,
  ) {
    if (previous == null) return;
    if (next.isExporting) {
      _lastCompletionNoticeStatus = null;
      return;
    }

    if (!previous.isExporting || next.isExporting) return;

    final notice = _completionNoticeForStatus(next.status);
    if (notice == null) return;
    if (_lastCompletionNoticeStatus == next.status) return;

    _lastCompletionNoticeStatus = next.status;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showCompletionNotice(context, notice);
    });
  }
}

enum _NoticeTone { success, warning, error }

class _CompletionNotice {
  const _CompletionNotice({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final _NoticeTone tone;
}

_CompletionNotice? _completionNoticeForStatus(String status) {
  if (status.startsWith('Exported clean ')) {
    return const _CompletionNotice(
      title: 'Clean image exported',
      message: 'Redactions are burned in and metadata is removed.',
      tone: _NoticeTone.success,
    );
  }

  if (status.startsWith('Saved clean ')) {
    return const _CompletionNotice(
      title: 'Saved to Photos',
      message: 'The clean image is ready in your photo library.',
      tone: _NoticeTone.success,
    );
  }

  if (status.startsWith('Shared clean ')) {
    return const _CompletionNotice(
      title: 'Ready to share',
      message: 'A clean copy was prepared for sharing.',
      tone: _NoticeTone.success,
    );
  }

  if (status.startsWith('Saved metadata-clean ')) {
    if (status == 'Saved metadata-clean PDF') {
      return const _CompletionNotice(
        title: 'PDF cleaned',
        message: 'A flattened PDF was saved without original metadata.',
        tone: _NoticeTone.success,
      );
    }

    return const _CompletionNotice(
      title: 'Metadata removed',
      message: 'A clean image copy was saved without private metadata.',
      tone: _NoticeTone.success,
    );
  }

  if (status.startsWith('Exported clean PDF')) {
    return const _CompletionNotice(
      title: 'Clean PDF exported',
      message: 'Pages were flattened and PDF metadata was removed.',
      tone: _NoticeTone.success,
    );
  }

  if (status.startsWith('Success: cleaned metadata for ')) {
    return const _CompletionNotice(
      title: 'Metadata cleaned',
      message: 'Clean copies were saved to the output folder.',
      tone: _NoticeTone.success,
    );
  }

  if (status.startsWith('Cleaned metadata for ')) {
    return const _CompletionNotice(
      title: 'Metadata cleaned with notes',
      message: 'Some files need attention. Check the status text for details.',
      tone: _NoticeTone.warning,
    );
  }

  if (status.startsWith('Could not export image') ||
      status.startsWith('Could not clean metadata') ||
      status.startsWith('Could not create output folder')) {
    return _CompletionNotice(
      title: 'Could not finish',
      message: status,
      tone: _NoticeTone.error,
    );
  }

  return null;
}

void _showCompletionNotice(BuildContext context, _CompletionNotice notice) {
  final isMobile = MediaQuery.sizeOf(context).width < 600;
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 16,
      right: 16,
      bottom: isMobile ? 96 : 24,
      child: SafeArea(
        top: false,
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _CompletionNoticeCard(notice: notice),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 2800), () {
    if (entry.mounted) entry.remove();
  });
}

class _CompletionNoticeCard extends StatelessWidget {
  const _CompletionNoticeCard({required this.notice});

  final _CompletionNotice notice;

  @override
  Widget build(BuildContext context) {
    final accent = switch (notice.tone) {
      _NoticeTone.success => redactKitSystemGreenColor,
      _NoticeTone.warning => redactKitSystemOrangeColor,
      _NoticeTone.error => redactKitSystemRedColor,
    };
    final background = switch (notice.tone) {
      _NoticeTone.success => redactKitSystemGreenFillColor,
      _NoticeTone.warning => redactKitSystemOrangeFillColor,
      _NoticeTone.error => redactKitSystemRedFillColor,
    };
    final icon = switch (notice.tone) {
      _NoticeTone.success => Icons.check_circle,
      _NoticeTone.warning => Icons.info,
      _NoticeTone.error => Icons.error_outline,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: redactKitSubtleBorderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox.square(
                dimension: 38,
                child: Icon(icon, color: accent, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    notice.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: redactKitPrimaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notice.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: redactKitMutedTextColor,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout({
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

    return ColoredBox(
      color: redactKitBackgroundColor,
      child: Column(
        children: <Widget>[
          _TopBar(
            mode: mode,
            onModeChanged: onModeChanged,
            status: state.status,
            canUndo: mode == _WorkspaceMode.pdf
                ? state.currentPdfRedactions.isNotEmpty
                : state.hasRedactions,
            canClear: mode == _WorkspaceMode.pdf
                ? state.currentPdfRedactions.isNotEmpty
                : state.hasRedactions,
            canExport: mode == _WorkspaceMode.pdf
                ? state.hasPdf && !state.isExporting
                : state.hasImage && !state.isExporting,
            isOpening: state.isOpening,
            isExporting: state.isExporting,
            onOpen: mode == _WorkspaceMode.pdf
                ? controller.openPdf
                : controller.openImage,
            onOpenPhotos: controller.openPhotoLibrary,
            onUndo: mode == _WorkspaceMode.pdf
                ? controller.undoPdfRedaction
                : controller.undo,
            onClear: mode == _WorkspaceMode.pdf
                ? controller.clearPdfPageRedactions
                : controller.clear,
            onExport: mode == _WorkspaceMode.pdf
                ? controller.exportPdf
                : controller.exportImage,
            onShare: controller.shareImage,
            onSaveToPhotos: controller.saveImageToPhotos,
            onHelp: () => switch (mode) {
              _WorkspaceMode.redact => _showRedactDetails(context),
              _WorkspaceMode.pdf => _showPdfDetails(context),
              _WorkspaceMode.metadata => _showMetadataDetails(context),
            },
          ),
          Expanded(
            child: switch (mode) {
              _WorkspaceMode.redact => Row(
                children: <Widget>[
                  Expanded(
                    child: _CanvasArea(
                      state: state,
                      image: state.image,
                      redactions: state.redactions,
                      onBeginRedaction: controller.beginRedaction,
                      onUpdateRedaction: controller.updateRedaction,
                      onFinishRedaction: controller.finishRedaction,
                      onOpen: controller.openImage,
                      onOpenPhotos: controller.openPhotoLibrary,
                      emptyTitle: 'Choose an image',
                      openLabel: 'Files',
                      fitPadding: 28,
                      showPhotoButton: true,
                      compactEmptyState: true,
                    ),
                  ),
                  _SidePanel(
                    image: state.image,
                    redactionCount: state.redactions.length,
                    selectedColor: state.redactionColor,
                    exportFormat: state.exportFormat,
                    jpegQualityPreset: state.jpegQualityPreset,
                    preserveRedactionExportFileName:
                        state.preserveRedactionExportFileName,
                    onColorChanged: controller.selectColor,
                    onExportFormatChanged: controller.setExportFormat,
                    onJpegQualityPresetChanged: controller.setJpegQualityPreset,
                    onPreserveRedactionExportFileNameChanged:
                        controller.setPreserveRedactionExportFileName,
                  ),
                ],
              ),
              _WorkspaceMode.pdf => Row(
                children: <Widget>[
                  Expanded(
                    child: _CanvasArea(
                      state: state,
                      image: state.pdfPageImage,
                      redactions: state.currentPdfRedactions,
                      onBeginRedaction: controller.beginPdfRedaction,
                      onUpdateRedaction: controller.updatePdfRedaction,
                      onFinishRedaction: controller.finishPdfRedaction,
                      onOpen: controller.openPdf,
                      emptyTitle: 'Choose a PDF',
                      openLabel: 'Files',
                      fitPadding: 28,
                      compactEmptyState: true,
                    ),
                  ),
                  _PdfSidePanel(
                    state: state,
                    selectedColor: state.redactionColor,
                    onColorChanged: controller.selectColor,
                    onPreviousPage: controller.previousPdfPage,
                    onNextPage: controller.nextPdfPage,
                    onPageChanged: controller.showPdfPage,
                    onExport: controller.exportPdf,
                    onPdfQualityPresetChanged: controller.setPdfQualityPreset,
                    onPreservePdfExportFileNameChanged:
                        controller.setPreservePdfExportFileName,
                  ),
                ],
              ),
              _WorkspaceMode.metadata => _MetadataCleanerView(
                state: state,
                desktop: true,
              ),
            },
          ),
        ],
      ),
    );
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
    final canExport = mode == _WorkspaceMode.pdf
        ? state.hasPdf && !state.isExporting
        : state.hasImage && !state.isExporting;
    final hasDocument = mode == _WorkspaceMode.pdf
        ? state.hasPdf
        : state.hasImage;

    return ColoredBox(
      color: redactKitBackgroundColor,
      child: Column(
        children: <Widget>[
          _MobileTopBar(
            mode: mode,
            status: state.status,
            redactionCount: mode == _WorkspaceMode.pdf
                ? state.currentPdfRedactions.length
                : state.redactions.length,
            hasMetadataInput: state.hasMetadataInput,
            hasPdf: state.hasPdf,
            onHelp: () => switch (mode) {
              _WorkspaceMode.redact => _showRedactDetails(context),
              _WorkspaceMode.pdf => _showPdfDetails(context),
              _WorkspaceMode.metadata => _showMetadataDetails(context),
            },
            onSettings: mode == _WorkspaceMode.redact
                ? () => _showExportSheet(context)
                : mode == _WorkspaceMode.pdf
                ? () => _showPdfExportSheet(context)
                : null,
          ),
          _ModeSwitcherBand(mode: mode, onModeChanged: onModeChanged),
          if (mode == _WorkspaceMode.pdf && state.hasPdf)
            _PdfPageNavigationStrip(
              currentPage: state.pdfCurrentPage,
              pageCount: state.pdfPageCount,
              isBusy: state.isOpening || state.isExporting,
              onPrevious: controller.previousPdfPage,
              onNext: controller.nextPdfPage,
              onPageChanged: controller.showPdfPage,
            ),
          Expanded(
            child: switch (mode) {
              _WorkspaceMode.redact => _CanvasArea(
                state: state,
                image: state.image,
                redactions: state.redactions,
                onBeginRedaction: controller.beginRedaction,
                onUpdateRedaction: controller.updateRedaction,
                onFinishRedaction: controller.finishRedaction,
                onOpen: controller.openImage,
                onOpenPhotos: controller.openPhotoLibrary,
                emptyTitle: 'Choose an image',
                openLabel: 'Files',
                margin: EdgeInsets.zero,
                showBorder: false,
                fitPadding: 14,
                showPhotoButton: true,
                enablePanZoom: true,
                compactEmptyState: true,
              ),
              _WorkspaceMode.pdf => _CanvasArea(
                state: state,
                image: state.pdfPageImage,
                redactions: state.currentPdfRedactions,
                onBeginRedaction: controller.beginPdfRedaction,
                onUpdateRedaction: controller.updatePdfRedaction,
                onFinishRedaction: controller.finishPdfRedaction,
                onOpen: controller.openPdf,
                emptyTitle: 'Choose a PDF',
                openLabel: 'Files',
                margin: EdgeInsets.zero,
                showBorder: false,
                fitPadding: 14,
                enablePanZoom: true,
                compactEmptyState: true,
              ),
              _WorkspaceMode.metadata => _MetadataCleanerView(
                state: state,
                desktop: false,
              ),
            },
          ),
          if ((mode == _WorkspaceMode.redact || mode == _WorkspaceMode.pdf) &&
              hasDocument)
            _MobileBottomBar(
              canUndo: mode == _WorkspaceMode.pdf
                  ? state.currentPdfRedactions.isNotEmpty
                  : state.hasRedactions,
              canClear: mode == _WorkspaceMode.pdf
                  ? state.currentPdfRedactions.isNotEmpty
                  : state.hasRedactions,
              isOpening: state.isOpening,
              canExport: canExport,
              onOpen: mode == _WorkspaceMode.pdf
                  ? controller.openPdf
                  : controller.openImage,
              onOpenPhotos: controller.openPhotoLibrary,
              onUndo: mode == _WorkspaceMode.pdf
                  ? controller.undoPdfRedaction
                  : controller.undo,
              onClear: mode == _WorkspaceMode.pdf
                  ? controller.clearPdfPageRedactions
                  : controller.clear,
              onExportOptions: mode == _WorkspaceMode.pdf
                  ? () => _showPdfExportSheet(context)
                  : () => _showExportSheet(context),
              pdfMode: mode == _WorkspaceMode.pdf,
            ),
        ],
      ),
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
    final canExport = mode == _WorkspaceMode.pdf
        ? state.hasPdf && !state.isExporting
        : state.hasImage && !state.isExporting;

    return Column(
      children: <Widget>[
        _TabletTopBar(
          mode: mode,
          onModeChanged: onModeChanged,
          status: state.status,
          canUndo: mode == _WorkspaceMode.pdf
              ? state.currentPdfRedactions.isNotEmpty
              : state.hasRedactions,
          canClear: mode == _WorkspaceMode.pdf
              ? state.currentPdfRedactions.isNotEmpty
              : state.hasRedactions,
          canExport: canExport,
          isExporting: state.isExporting,
          onUndo: mode == _WorkspaceMode.pdf
              ? controller.undoPdfRedaction
              : controller.undo,
          onClear: mode == _WorkspaceMode.pdf
              ? controller.clearPdfPageRedactions
              : controller.clear,
          onExport: mode == _WorkspaceMode.pdf
              ? controller.exportPdf
              : controller.exportImage,
          onSaveToPhotos: controller.saveImageToPhotos,
          onShare: controller.shareImage,
          onHelp: () => switch (mode) {
            _WorkspaceMode.redact => _showRedactDetails(context),
            _WorkspaceMode.pdf => _showPdfDetails(context),
            _WorkspaceMode.metadata => _showMetadataDetails(context),
          },
          onSettings: mode == _WorkspaceMode.redact
              ? () => _showExportSheet(context)
              : mode == _WorkspaceMode.pdf
              ? () => _showPdfExportSheet(context)
              : null,
        ),
        if (mode == _WorkspaceMode.redact || mode == _WorkspaceMode.pdf)
          _TabletSourceStrip(
            pdfMode: mode == _WorkspaceMode.pdf,
            isOpening: state.isOpening,
            onFiles: mode == _WorkspaceMode.pdf
                ? controller.openPdf
                : controller.openImage,
            onPhotos: mode == _WorkspaceMode.redact
                ? controller.openPhotoLibrary
                : null,
          ),
        if (mode == _WorkspaceMode.pdf && state.hasPdf)
          _PdfPageNavigationStrip(
            currentPage: state.pdfCurrentPage,
            pageCount: state.pdfPageCount,
            isBusy: state.isOpening || state.isExporting,
            onPrevious: controller.previousPdfPage,
            onNext: controller.nextPdfPage,
            onPageChanged: controller.showPdfPage,
          ),
        Expanded(
          child: switch (mode) {
            _WorkspaceMode.redact => _CanvasArea(
              state: state,
              image: state.image,
              redactions: state.redactions,
              onBeginRedaction: controller.beginRedaction,
              onUpdateRedaction: controller.updateRedaction,
              onFinishRedaction: controller.finishRedaction,
              onOpen: controller.openImage,
              onOpenPhotos: controller.openPhotoLibrary,
              emptyTitle: 'Choose an image',
              openLabel: 'Files',
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              fitPadding: 16,
              showPhotoButton: true,
              enablePanZoom: true,
            ),
            _WorkspaceMode.pdf => _CanvasArea(
              state: state,
              image: state.pdfPageImage,
              redactions: state.currentPdfRedactions,
              onBeginRedaction: controller.beginPdfRedaction,
              onUpdateRedaction: controller.updatePdfRedaction,
              onFinishRedaction: controller.finishPdfRedaction,
              onOpen: controller.openPdf,
              emptyTitle: 'Choose a PDF',
              openLabel: 'Files',
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              fitPadding: 16,
              enablePanZoom: true,
            ),
            _WorkspaceMode.metadata => _MetadataCleanerView(
              state: state,
              desktop: false,
            ),
          },
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
    required this.isExporting,
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
  final bool isExporting;
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
        color: redactKitSecondaryBackgroundColor,
        border: Border(bottom: BorderSide(color: redactKitSubtleBorderColor)),
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
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: redactKitMutedTextColor,
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
          if (mode != _WorkspaceMode.metadata) ...<Widget>[
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
                      child: CupertinoActivityIndicator(color: Colors.white),
                    )
                  : const Icon(Icons.save_alt),
              filled: true,
            ),
            if (mode == _WorkspaceMode.redact) ...<Widget>[
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
          ],
          _TopBarIconButton(
            tooltip: switch (mode) {
              _WorkspaceMode.redact => 'Image details',
              _WorkspaceMode.pdf => 'PDF details',
              _WorkspaceMode.metadata => 'Metadata details',
            },
            onPressed: onHelp,
            icon: const Icon(CupertinoIcons.info),
          ),
          if (onSettings != null)
            _TopBarIconButton(
              tooltip: 'Settings',
              onPressed: onSettings,
              icon: const Icon(CupertinoIcons.slider_horizontal_3),
            ),
        ],
      ),
    );
  }
}

class _TabletSourceStrip extends StatelessWidget {
  const _TabletSourceStrip({
    required this.pdfMode,
    required this.isOpening,
    required this.onFiles,
    required this.onPhotos,
  });

  final bool pdfMode;
  final bool isOpening;
  final VoidCallback onFiles;
  final VoidCallback? onPhotos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: redactKitSecondaryBackgroundColor,
        border: Border(bottom: BorderSide(color: redactKitSubtleBorderColor)),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: pdfMode ? 180 : 156,
            child: _SourceActionButton(
              onPressed: isOpening ? null : onFiles,
              icon: pdfMode ? CupertinoIcons.doc_text : CupertinoIcons.folder,
              label: 'Files',
            ),
          ),
          if (!pdfMode && onPhotos != null) ...<Widget>[
            const SizedBox(width: 10),
            SizedBox(
              width: 156,
              child: _SourceActionButton(
                onPressed: isOpening ? null : onPhotos,
                icon: CupertinoIcons.photo_on_rectangle,
                label: 'Photos',
              ),
            ),
          ],
          const Spacer(),
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
    final button = _CupertinoIconControl(
      onPressed: onPressed,
      icon: icon,
      emphasis: filled
          ? _CupertinoControlEmphasis.filled
          : tonal
          ? _CupertinoControlEmphasis.tonal
          : _CupertinoControlEmphasis.outlined,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: _CupertinoTooltip(message: tooltip, child: button),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      decoration: const BoxDecoration(
        color: redactKitSecondaryBackgroundColor,
        border: Border(bottom: BorderSide(color: redactKitSubtleBorderColor)),
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
    return _CupertinoSegmentedControl<_WorkspaceMode>(
      selected: mode,
      values: _WorkspaceMode.values,
      labelFor: (mode) => switch (mode) {
        _WorkspaceMode.redact => 'Image',
        _WorkspaceMode.pdf => 'PDF',
        _WorkspaceMode.metadata => 'Metadata',
      },
      cupertinoIconFor: (mode) => switch (mode) {
        _WorkspaceMode.redact => CupertinoIcons.photo,
        _WorkspaceMode.pdf => CupertinoIcons.doc_text,
        _WorkspaceMode.metadata => CupertinoIcons.sparkles,
      },
      onChanged: onModeChanged,
    );
  }
}

enum _CupertinoControlEmphasis { outlined, tonal, filled }

class _CupertinoSegmentedControl<T extends Object> extends StatelessWidget {
  const _CupertinoSegmentedControl({
    required this.selected,
    required this.values,
    required this.labelFor,
    required this.onChanged,
    this.cupertinoIconFor,
  });

  final T selected;
  final List<T> values;
  final String Function(T value) labelFor;
  final IconData? Function(T value)? cupertinoIconFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: selected,
        padding: const EdgeInsets.all(2),
        backgroundColor: redactKitDisabledFillColor,
        thumbColor: Colors.white,
        children: <T, Widget>{
          for (final value in values)
            value: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: _CupertinoSegmentContent(
                icon: cupertinoIconFor?.call(value),
                label: labelFor(value),
                selected: value == selected,
                selectedColor: redactKitPrimaryTextColor,
              ),
            ),
        },
        onValueChanged: (value) {
          if (value == null) return;
          onChanged(value);
        },
      ),
    );
  }
}

class _CupertinoSegmentContent extends StatelessWidget {
  const _CupertinoSegmentContent({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
  });

  final IconData? icon;
  final String label;
  final bool selected;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : redactKitMutedTextColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CupertinoActionButton extends StatelessWidget {
  const _CupertinoActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.emphasis,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final _CupertinoControlEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = enabled
        ? switch (emphasis) {
            _CupertinoControlEmphasis.filled => redactKitAccentColor,
            _ => redactKitAccentColor,
          }
        : redactKitDisabledColor;
    final background = switch (emphasis) {
      _CupertinoControlEmphasis.filled =>
        enabled ? redactKitAccentFillColor : redactKitDisabledFillColor,
      _CupertinoControlEmphasis.tonal =>
        enabled ? redactKitAccentFillColor : redactKitDisabledFillColor,
      _CupertinoControlEmphasis.outlined => redactKitSecondaryBackgroundColor,
    };
    final borderColor = switch (emphasis) {
      _CupertinoControlEmphasis.filled =>
        enabled ? redactKitAccentBorderColor : redactKitSubtleBorderColor,
      _CupertinoControlEmphasis.tonal => Colors.transparent,
      _CupertinoControlEmphasis.outlined =>
        enabled ? redactKitSubtleBorderColor : redactKitSubtleBorderColor,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: onPressed,
          child: Container(
            constraints: BoxConstraints(
              minHeight: 40,
              minWidth: constraints.hasBoundedWidth ? constraints.maxWidth : 0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground, size: 18),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: constraints.hasBoundedWidth
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  children: <Widget>[
                    icon,
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CupertinoIconControl extends StatelessWidget {
  const _CupertinoIconControl({
    required this.onPressed,
    required this.icon,
    required this.emphasis,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final _CupertinoControlEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = enabled
        ? switch (emphasis) {
            _CupertinoControlEmphasis.filled => Colors.white,
            _CupertinoControlEmphasis.tonal => redactKitAccentColor,
            _CupertinoControlEmphasis.outlined => redactKitMutedTextColor,
          }
        : redactKitDisabledColor;
    final background = switch (emphasis) {
      _CupertinoControlEmphasis.filled =>
        enabled ? redactKitAccentColor : redactKitSubtleBorderColor,
      _CupertinoControlEmphasis.tonal =>
        enabled ? redactKitAccentFillColor : redactKitDisabledFillColor,
      _CupertinoControlEmphasis.outlined => redactKitSecondaryBackgroundColor,
    };
    final borderColor = emphasis == _CupertinoControlEmphasis.outlined
        ? redactKitSubtleBorderColor
        : Colors.transparent;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: foreground, size: 20),
          child: icon,
        ),
      ),
    );
  }
}

class _PdfPageNavigationStrip extends StatelessWidget {
  const _PdfPageNavigationStrip({
    required this.currentPage,
    required this.pageCount,
    required this.isBusy,
    required this.onPrevious,
    required this.onNext,
    required this.onPageChanged,
  });

  final int currentPage;
  final int pageCount;
  final bool isBusy;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: redactKitBorderColor)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _CupertinoActionButton(
                  onPressed: !isBusy && currentPage > 1 ? onPrevious : null,
                  icon: const Icon(Icons.chevron_left),
                  label: 'Prev',
                  emphasis: _CupertinoControlEmphasis.outlined,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 96,
                child: _PdfPageNumberField(
                  currentPage: currentPage,
                  pageCount: pageCount,
                  isBusy: isBusy,
                  onPageChanged: onPageChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CupertinoActionButton(
                  onPressed: !isBusy && currentPage < pageCount ? onNext : null,
                  icon: const Icon(Icons.chevron_right),
                  label: 'Next',
                  emphasis: _CupertinoControlEmphasis.outlined,
                ),
              ),
            ],
          ),
          if (pageCount > 1) ...<Widget>[
            const SizedBox(height: 6),
            _PdfPageSlider(
              currentPage: currentPage,
              pageCount: pageCount,
              isBusy: isBusy,
              onPageChanged: onPageChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _PdfPageNumberField extends StatefulWidget {
  const _PdfPageNumberField({
    required this.currentPage,
    required this.pageCount,
    required this.isBusy,
    required this.onPageChanged,
  });

  final int currentPage;
  final int pageCount;
  final bool isBusy;
  final ValueChanged<int> onPageChanged;

  @override
  State<_PdfPageNumberField> createState() => _PdfPageNumberFieldState();
}

class _PdfPageNumberFieldState extends State<_PdfPageNumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPage.toString());
  }

  @override
  void didUpdateWidget(covariant _PdfPageNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage &&
        _controller.text != widget.currentPage.toString()) {
      _controller.text = widget.currentPage.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: _controller,
      enabled: !widget.isBusy && widget.pageCount > 0,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.go,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      placeholder: 'Page',
      suffix: Padding(
        padding: const EdgeInsets.only(right: 9),
        child: Text(
          '/ ${widget.pageCount}',
          style: const TextStyle(color: redactKitMutedTextColor, fontSize: 12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: redactKitSubtleBorderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      onSubmitted: _submit,
    );
  }

  void _submit(String value) {
    final requested = int.tryParse(value);
    if (requested == null || widget.pageCount <= 0) {
      _controller.text = widget.currentPage.toString();
      return;
    }

    final page = requested.clamp(1, widget.pageCount).toInt();
    _controller.text = page.toString();
    widget.onPageChanged(page);
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

class _PdfPageSlider extends StatefulWidget {
  const _PdfPageSlider({
    required this.currentPage,
    required this.pageCount,
    required this.isBusy,
    required this.onPageChanged,
  });

  final int currentPage;
  final int pageCount;
  final bool isBusy;
  final ValueChanged<int> onPageChanged;

  @override
  State<_PdfPageSlider> createState() => _PdfPageSliderState();
}

class _PdfPageSliderState extends State<_PdfPageSlider> {
  late double _value;
  int? _lastRequestedPage;

  @override
  void initState() {
    super.initState();
    _value = widget.currentPage.toDouble();
  }

  @override
  void didUpdateWidget(covariant _PdfPageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _value = widget.currentPage.toDouble();
      _lastRequestedPage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoSlider(
      min: 1,
      max: widget.pageCount.toDouble(),
      divisions: widget.pageCount > 1 ? widget.pageCount - 1 : null,
      value: _value.clamp(1, widget.pageCount.toDouble()),
      onChanged: widget.pageCount <= 1 ? null : _previewPage,
      onChangeEnd: widget.pageCount <= 1
          ? null
          : (value) => _requestPage(value.round()),
    );
  }

  void _previewPage(double value) {
    setState(() => _value = value);
    _requestPage(value.round());
  }

  void _requestPage(int page) {
    if (page == widget.currentPage || page == _lastRequestedPage) return;

    _lastRequestedPage = page;
    widget.onPageChanged(page);
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.mode,
    required this.status,
    required this.redactionCount,
    required this.hasMetadataInput,
    required this.hasPdf,
    required this.onHelp,
    required this.onSettings,
  });

  final _WorkspaceMode mode;
  final String status;
  final int redactionCount;
  final bool hasMetadataInput;
  final bool hasPdf;
  final VoidCallback onHelp;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final summary = switch (mode) {
      _WorkspaceMode.redact =>
        redactionCount > 0
            ? '$redactionCount redaction${redactionCount == 1 ? '' : 's'}'
            : null,
      _WorkspaceMode.pdf => hasPdf ? '$redactionCount on page' : null,
      _WorkspaceMode.metadata => hasMetadataInput ? 'Input selected' : null,
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.fromLTRB(16, 7, 10, 7),
      decoration: const BoxDecoration(
        color: redactKitSecondaryBackgroundColor,
        border: Border(bottom: BorderSide(color: redactKitSubtleBorderColor)),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        status,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: redactKitMutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (summary != null) ...<Widget>[
                      const SizedBox(width: 8),
                      _StatusPill(text: summary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _CupertinoTooltip(
            message: 'Details',
            child: _CupertinoIconControl(
              onPressed: onHelp,
              icon: const Icon(CupertinoIcons.info),
              emphasis: _CupertinoControlEmphasis.outlined,
            ),
          ),
          if (onSettings != null)
            _CupertinoTooltip(
              message: 'Settings',
              child: _CupertinoIconControl(
                onPressed: onSettings,
                icon: const Icon(CupertinoIcons.slider_horizontal_3),
                emphasis: _CupertinoControlEmphasis.outlined,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: redactKitDisabledFillColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: redactKitMutedTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    this.pdfMode = false,
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
  final bool pdfMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
      decoration: const BoxDecoration(
        color: redactKitSecondaryBackgroundColor,
        border: Border(top: BorderSide(color: redactKitSubtleBorderColor)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _MobileToolbarItem(
            icon: pdfMode ? Icons.picture_as_pdf_outlined : Icons.folder_open,
            label: pdfMode ? 'PDF' : 'Files',
            onPressed: isOpening ? null : onOpen,
          ),
          if (!pdfMode)
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
            icon: canExport
                ? Icons.save_alt
                : CupertinoIcons.slider_horizontal_3,
            label: pdfMode ? 'Save' : 'Export',
            onPressed: onExportOptions,
            primary: canExport,
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
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = primary && enabled
        ? Colors.white
        : enabled
        ? redactKitMutedTextColor
        : redactKitDisabledColor;
    final background = primary && enabled
        ? redactKitAccentColor
        : Colors.transparent;

    return Expanded(
      child: _CupertinoTooltip(
        message: label,
        child: CupertinoButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 56),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground, size: 21),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: foreground),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, size: 21),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showExportSheet(BuildContext context) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      return _CupertinoSheetSurface(
        child: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(redactionControllerProvider);
            final controller = ref.read(redactionControllerProvider.notifier);
            final image = state.image;
            final canExport = state.hasImage && !state.isExporting;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.86,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                        _CupertinoTooltip(
                          message: 'Close',
                          child: _CupertinoIconControl(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(CupertinoIcons.xmark),
                            emphasis: _CupertinoControlEmphasis.outlined,
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
                    const _DividerLine(),
                    const SizedBox(height: 22),
                    const _PanelHeading('Format'),
                    _ExportFormatPicker(
                      selected: state.exportFormat,
                      onChanged: controller.setExportFormat,
                    ),
                    const SizedBox(height: 18),
                    _ImageQualityPicker(
                      format: state.exportFormat,
                      selected: state.jpegQualityPreset,
                      onChanged: controller.setJpegQualityPreset,
                    ),
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
                          child: _CupertinoActionButton(
                            onPressed: canExport
                                ? () {
                                    Navigator.of(context).pop();
                                    controller.exportImage();
                                  }
                                : null,
                            icon: state.isExporting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CupertinoActivityIndicator(),
                                  )
                                : const Icon(Icons.save_alt),
                            label: 'Save to Files',
                            emphasis: _CupertinoControlEmphasis.filled,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CupertinoActionButton(
                            onPressed: canExport
                                ? () {
                                    Navigator.of(context).pop();
                                    controller.saveImageToPhotos();
                                  }
                                : null,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: 'Save to Photos',
                            emphasis: _CupertinoControlEmphasis.tonal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: _CupertinoActionButton(
                        onPressed: canExport
                            ? () {
                                Navigator.of(context).pop();
                                controller.shareImage();
                              }
                            : null,
                        icon: const Icon(Icons.ios_share),
                        label: 'Share',
                        emphasis: _CupertinoControlEmphasis.tonal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

void _showPdfExportSheet(BuildContext context) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      return _CupertinoSheetSurface(
        child: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(redactionControllerProvider);
            final controller = ref.read(redactionControllerProvider.notifier);
            final canExport = state.hasPdf && !state.isExporting;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'PDF Export',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _CupertinoTooltip(
                        message: 'Close',
                        child: _CupertinoIconControl(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(CupertinoIcons.xmark),
                          emphasis: _CupertinoControlEmphasis.outlined,
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
                  const _PanelHeading('PDF'),
                  _MetricRow(
                    label: 'Pages',
                    value: state.hasPdf ? '${state.pdfPageCount}' : 'None',
                  ),
                  _MetricRow(
                    label: 'Current page',
                    value: state.hasPdf ? '${state.pdfCurrentPage}' : 'None',
                  ),
                  _MetricRow(
                    label: 'Redactions',
                    value: '${state.pdfRedactionCount}',
                  ),
                  const SizedBox(height: 18),
                  _PdfQualityPresetPicker(
                    selected: state.pdfQualityPreset,
                    onChanged: controller.setPdfQualityPreset,
                  ),
                  const SizedBox(height: 18),
                  _KeepFilenamesToggle(
                    label: 'Keep filename',
                    value: state.preservePdfExportFileName,
                    onChanged: controller.setPreservePdfExportFileName,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _CupertinoActionButton(
                          onPressed: canExport
                              ? () {
                                  Navigator.of(context).pop();
                                  controller.exportPdf();
                                }
                              : null,
                          icon: state.isExporting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CupertinoActivityIndicator(),
                                )
                              : const Icon(Icons.save_alt),
                          label: 'Save Redacted PDF',
                          emphasis: _CupertinoControlEmphasis.filled,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

void _showRedactDetails(BuildContext context) {
  _showDetails(
    context,
    title: 'Image Privacy',
    children: const <Widget>[
      _PrivacyPoint(
        icon: Icons.grid_on_outlined,
        title: 'Pixel-level redaction',
        body:
            'Redaction boxes are burned into the raster as 100% opaque solid pixels. The exported image has no editable layer, hidden mask, or original pixels under the box.',
      ),
      _PrivacyPoint(
        icon: Icons.auto_fix_high_outlined,
        title: 'Rebuilt from visible pixels',
        body:
            'Export creates a new PNG or JPEG from the rendered pixel buffer. It does not copy the original file container forward.',
      ),
      _PrivacyPoint(
        icon: Icons.cleaning_services_outlined,
        title: 'Metadata removed',
        body:
            'Image export always rebuilds the image and removes metadata. PNG keeps pixel, transparency, and standard color-rendering chunks. JPEG removes APP0-APP15 and COM segments.',
      ),
      _PrivacyPoint(
        icon: Icons.badge_outlined,
        title: 'File names',
        body:
            'Exports start with a generic name. The Keep filename option only preserves the visible file name, not image metadata.',
      ),
      _PrivacyPoint(
        icon: CupertinoIcons.slider_horizontal_3,
        title: 'Format choice',
        body:
            'PNG keeps redaction pixels exact. JPEG makes smaller files and may slightly soften edges, but it cannot restore pixels that were already replaced. Just make sure the box fully covers the sensitive area.',
      ),
    ],
  );
}

void _showPdfDetails(BuildContext context) {
  _showDetails(
    context,
    title: 'PDF Privacy',
    children: const <Widget>[
      _PrivacyPoint(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Flattened PDF export',
        body:
            'Each PDF page is rendered as an image, redaction boxes are burned into that image, and a new PDF is generated from the cleaned pages. The exported page size follows the original PDF page size.',
      ),
      _PrivacyPoint(
        icon: Icons.layers_clear_outlined,
        title: 'Original PDF structure removed',
        body:
            'The clean PDF does not copy the original text layer, annotations, forms, links, embedded files, hidden OCR text, or original document metadata.',
      ),
      _PrivacyPoint(
        icon: Icons.cleaning_services_outlined,
        title: 'Metadata-only PDFs',
        body:
            'Metadata Only can flatten one PDF without drawing boxes. It removes original PDF metadata and hidden document structure, but text selection and search are not preserved.',
      ),
      _PrivacyPoint(
        icon: Icons.search_off_outlined,
        title: 'Tradeoff',
        body:
            'Flattened PDFs are safer and simpler to verify, but the exported document behaves like scanned pages. Text outside redactions is visible, but not selectable or searchable.',
      ),
    ],
  );
}

void _showMetadataDetails(BuildContext context) {
  _showDetails(
    context,
    title: 'Metadata Only',
    children: const <Widget>[
      _PrivacyPoint(
        icon: Icons.photo_library_outlined,
        title: 'Image and PDF input',
        body:
            'Choose files or a folder from one input button. Files can be images or PDFs, and folder input scans supported images and PDFs inside it. This mode does not draw redaction boxes.',
      ),
      _PrivacyPoint(
        icon: Icons.auto_fix_high_outlined,
        title: 'Fast clean path',
        body:
            'PNG-to-PNG outputs strip metadata directly from a copied file container. JPEG-to-JPEG does the same unless EXIF orientation must be baked into pixels. Format changes decode visible pixels and encode a fresh clean file.',
      ),
      _PrivacyPoint(
        icon: Icons.cleaning_services_outlined,
        title: 'Metadata removed',
        body:
            'PNG output keeps pixel, transparency, and standard color-rendering chunks. JPEG output removes APP0-APP15 and COM segments, covering EXIF, GPS, IPTC, XMP, thumbnails, and comments.',
      ),
      _PrivacyPoint(
        icon: Icons.drive_file_rename_outline,
        title: 'File names',
        body:
            'Generic names are used unless Keep filenames is enabled. Preserved names are sanitized and deduplicated inside the output folder.',
      ),
      _PrivacyPoint(
        icon: Icons.folder_copy_outlined,
        title: 'Output',
        body:
            'Images and PDFs save into the app Cleaned folder unless you choose another output folder. Folder input creates a Cleaned subfolder named with -metadata-removed.',
      ),
    ],
  );
}

void _showDetails(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  final compact = MediaQuery.sizeOf(context).width < 600;
  final sheet = _InfoDetailsSheet(
    title: title,
    bottomSheet: compact,
    children: children,
  );

  if (compact) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => sheet,
    );
    return;
  }

  showCupertinoDialog<void>(context: context, builder: (context) => sheet);
}

class _InfoDetailsSheet extends StatelessWidget {
  const _InfoDetailsSheet({
    required this.title,
    required this.children,
    required this.bottomSheet,
  });

  final String title;
  final List<Widget> children;
  final bool bottomSheet;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final availableHeight = math.max(
      260.0,
      bottomSheet ? size.height * 0.78 : size.height - 96,
    );
    final sheetHeight = math.min(availableHeight, bottomSheet ? 640.0 : 560.0);
    final sheetWidth = bottomSheet
        ? size.width
        : math.min(560.0, size.width - 32);
    final surface = CupertinoPopupSurface(
      child: SizedBox(
        width: sheetWidth,
        height: sheetHeight,
        child: Column(
          children: <Widget>[
            Container(
              height: 56,
              padding: const EdgeInsets.only(left: 20, right: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: redactKitSubtleBorderColor),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: redactKitPrimaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _CupertinoTooltip(
                    message: 'Close',
                    child: _CupertinoIconControl(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(CupertinoIcons.xmark),
                      emphasis: _CupertinoControlEmphasis.outlined,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottomSheet ? 22 : 16),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );

    if (bottomSheet) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(top: false, left: false, right: false, child: surface),
      );
    }

    return Center(
      child: SafeArea(minimum: const EdgeInsets.all(16), child: surface),
    );
  }
}

class _CupertinoSheetSurface extends StatelessWidget {
  const _CupertinoSheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoPopupSurface(child: SafeArea(top: false, child: child));
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: ColoredBox(color: redactKitBorderColor),
    );
  }
}

class _CupertinoTooltip extends StatelessWidget {
  const _CupertinoTooltip({
    required this.message,
    required this.child,
    this.waitDuration,
  });

  final String message;
  final Widget child;
  final Duration? waitDuration;

  @override
  Widget build(BuildContext context) {
    return Semantics(label: message, child: child);
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
          Icon(icon, color: redactKitAccentColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: redactKitMutedTextColor,
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
    if (desktop) {
      return _DesktopMetadataCleanerView(
        state: state,
        controller: controller,
        canClean: canClean,
      );
    }

    if (!desktop) {
      return _MobileMetadataCleanerView(
        state: state,
        controller: controller,
        canClean: canClean,
      );
    }

    return const SizedBox.shrink();
  }
}

String _metadataExportFormatDescription(RedactionState state) {
  if (!state.hasMetadataInput) {
    return 'Pick files or a folder first. The export controls will match the selected input types.';
  }
  if (state.metadataHasImages && state.metadataHasPdfs) {
    return 'Images use the image format and quality settings. PDFs are flattened with the PDF quality setting.';
  }
  if (state.metadataHasImages) {
    return 'Images use the selected PNG/JPEG format and image quality.';
  }
  if (state.metadataHasPdfs) {
    return 'PDFs are flattened with the selected PDF quality.';
  }
  return 'No supported files selected.';
}

bool _metadataInputHasFolder(List<MetadataInputDisplayItem> items) {
  return items.any((item) => item.kind == MetadataInputDisplayKind.folder);
}

String _metadataChooserTitle(bool hasInput, bool hasFolderInput) {
  if (hasFolderInput) return 'Folder Selected';
  return 'Files or Folder';
}

String _metadataChooserDescription(bool hasInput, bool hasFolderInput) {
  if (hasFolderInput) {
    return 'Remove the folder to choose files or another folder.';
  }
  if (hasInput) {
    return 'Add more images or PDFs to this list.';
  }
  return 'Files and folders can include images or PDFs.';
}

IconData _metadataChooserIcon(bool hasInput, bool hasFolderInput) {
  if (hasFolderInput) return CupertinoIcons.folder;
  if (hasInput) return CupertinoIcons.plus;
  return CupertinoIcons.folder_badge_plus;
}

VoidCallback? _metadataChooserAction({
  required bool canClean,
  required bool hasInput,
  required bool hasFolderInput,
  required RedactionController controller,
}) {
  if (!canClean || hasFolderInput) return null;
  if (hasInput) return controller.addMetadataFiles;
  return controller.chooseMetadataFilesOrFolder;
}

VoidCallback? _metadataPhotosAction({
  required bool canClean,
  required bool hasFolderInput,
  required RedactionController controller,
}) {
  if (!canClean || hasFolderInput) return null;
  return controller.addMetadataPhotos;
}

class _DesktopMetadataCleanerView extends StatelessWidget {
  const _DesktopMetadataCleanerView({
    required this.state,
    required this.controller,
    required this.canClean,
  });

  final RedactionState state;
  final RedactionController controller;
  final bool canClean;

  @override
  Widget build(BuildContext context) {
    final result = _MetadataResultSummaryData.fromStatus(state.status);
    final showImageExportControls =
        state.hasMetadataInput && state.metadataHasImages;
    final showPdfExportControls =
        state.hasMetadataInput && state.metadataHasPdfs;
    final inputItems = controller.metadataInputItems;
    final hasFolderInput = _metadataInputHasFolder(inputItems);
    final openingPhotos =
        state.isOpening && state.status.toLowerCase().contains('photo');

    return ColoredBox(
      color: redactKitBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Metadata Only',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Clean image or PDF metadata without drawing redaction boxes.',
                            style: TextStyle(
                              color: redactKitMutedTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      text: state.hasMetadataInput
                          ? '${state.metadataInputCount} selected'
                          : 'No input',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: <Widget>[
                          _DesktopMetadataPanel(
                            title: 'Input',
                            icon: CupertinoIcons.tray_arrow_down,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                _MetadataInputChooserButton(
                                  title: _metadataChooserTitle(
                                    state.hasMetadataInput,
                                    hasFolderInput,
                                  ),
                                  description: _metadataChooserDescription(
                                    state.hasMetadataInput,
                                    hasFolderInput,
                                  ),
                                  icon: _metadataChooserIcon(
                                    state.hasMetadataInput,
                                    hasFolderInput,
                                  ),
                                  onPressed: _metadataChooserAction(
                                    canClean: canClean,
                                    hasInput: state.hasMetadataInput,
                                    hasFolderInput: hasFolderInput,
                                    controller: controller,
                                  ),
                                  loading: state.isOpening && !openingPhotos,
                                ),
                                const SizedBox(height: 10),
                                _MetadataInputChooserButton(
                                  title: 'Photos',
                                  description: hasFolderInput
                                      ? 'Remove the folder before adding photos.'
                                      : 'Choose images from Photos.',
                                  icon: CupertinoIcons.photo_on_rectangle,
                                  onPressed: _metadataPhotosAction(
                                    canClean: canClean,
                                    hasFolderInput: hasFolderInput,
                                    controller: controller,
                                  ),
                                  loading: openingPhotos,
                                ),
                                const SizedBox(height: 14),
                                _MetadataInputList(
                                  items: inputItems,
                                  emptyLabel: 'No input selected',
                                  emptyDescription:
                                      'Choose files, photos, or a folder containing images and PDFs.',
                                  onRemove: canClean
                                      ? controller.removeMetadataInputAt
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DesktopMetadataPanel(
                            title: 'Output',
                            icon: CupertinoIcons.folder,
                            child: _MetadataOutputFolderPicker(
                              displayName:
                                  state.metadataOutputDirectoryDisplayName ??
                                  'Choose input to preview output',
                              path: state.metadataOutputDirectoryPath,
                              onChoose: canClean && state.hasMetadataInput
                                  ? controller.chooseMetadataOutputFolder
                                  : null,
                              onOpen:
                                  canClean &&
                                      state.metadataOutputDirectoryPath != null
                                  ? controller.openMetadataOutputFolder
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 340,
                      child: Column(
                        children: <Widget>[
                          _DesktopMetadataPanel(
                            title: 'Export Format',
                            icon: CupertinoIcons.slider_horizontal_3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                if (!state.hasMetadataInput)
                                  const Text(
                                    'Choose input to show matching export controls.',
                                    style: TextStyle(
                                      color: redactKitMutedTextColor,
                                      height: 1.35,
                                    ),
                                  ),
                                if (showImageExportControls) ...<Widget>[
                                  _ExportFormatPicker(
                                    selected: state.exportFormat,
                                    onChanged: controller.setExportFormat,
                                  ),
                                  const SizedBox(height: 16),
                                  _ImageQualityPicker(
                                    format: state.exportFormat,
                                    selected: state.jpegQualityPreset,
                                    onChanged: controller.setJpegQualityPreset,
                                  ),
                                ],
                                if (showPdfExportControls) ...<Widget>[
                                  if (showImageExportControls)
                                    const SizedBox(height: 16),
                                  _PdfQualityPresetPicker(
                                    selected: state.pdfQualityPreset,
                                    onChanged: controller.setPdfQualityPreset,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                _KeepFilenamesToggle(
                                  label: 'Keep filenames',
                                  value: state.preserveMetadataCleanFileNames,
                                  onChanged: canClean
                                      ? controller
                                            .setPreserveMetadataCleanFileNames
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _metadataExportFormatDescription(state),
                                  style: TextStyle(
                                    color: redactKitMutedTextColor,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: _CupertinoActionButton(
                              onPressed: canClean && state.hasMetadataInput
                                  ? controller.startMetadataClean
                                  : null,
                              icon: state.isExporting
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CupertinoActivityIndicator(),
                                    )
                                  : const Icon(CupertinoIcons.play_fill),
                              label: 'Start',
                              emphasis: _CupertinoControlEmphasis.filled,
                            ),
                          ),
                          if (state.isCleaningMetadata) ...<Widget>[
                            const SizedBox(height: 14),
                            _MetadataProgressBanner(
                              progress: state.metadataCleanProgress,
                              status: state.status,
                            ),
                          ],
                          if (result != null) ...<Widget>[
                            const SizedBox(height: 14),
                            _MetadataResultSummaryCard(
                              result: result,
                              outputPath: state.metadataOutputDirectoryPath,
                              onOpenFolder:
                                  state.metadataOutputDirectoryPath != null
                                  ? controller.openMetadataOutputFolder
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopMetadataPanel extends StatelessWidget {
  const _DesktopMetadataPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: redactKitSecondaryBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: redactKitSubtleBorderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 17, color: redactKitMutedTextColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: redactKitPrimaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetadataInputChooserButton extends StatelessWidget {
  const _MetadataInputChooserButton({
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final content = Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled
            ? redactKitInputActionFillColor
            : redactKitDisabledFillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? redactKitInputActionBorderColor
              : redactKitSubtleBorderColor,
        ),
      ),
      child: Row(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: enabled
                  ? redactKitSecondaryBackgroundColor
                  : redactKitDisabledFillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled
                    ? redactKitInputActionBorderColor
                    : redactKitSubtleBorderColor,
              ),
            ),
            child: SizedBox.square(
              dimension: 42,
              child: Center(
                child: loading
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CupertinoActivityIndicator(),
                      )
                    : Icon(
                        icon,
                        color: enabled
                            ? redactKitAccentColor
                            : redactKitDisabledColor,
                        size: 23,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled
                        ? redactKitInputActionTextColor
                        : redactKitDisabledColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: redactKitMutedTextColor,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            CupertinoIcons.chevron_forward,
            color: enabled
                ? redactKitInputActionTextColor
                : redactKitDisabledColor,
          ),
        ],
      ),
    );

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: content,
    );
  }
}

class _MetadataResultSummaryData {
  const _MetadataResultSummaryData({
    required this.title,
    required this.message,
    required this.tone,
    required this.savedCount,
    required this.ignoredCount,
    required this.failedCount,
  });

  final String title;
  final String message;
  final _NoticeTone tone;
  final int? savedCount;
  final int ignoredCount;
  final int failedCount;

  static _MetadataResultSummaryData? fromStatus(String status) {
    if (status == 'Saved metadata-clean PDF') {
      return const _MetadataResultSummaryData(
        title: 'Last result',
        message: 'Saved metadata-clean PDF',
        tone: _NoticeTone.success,
        savedCount: null,
        ignoredCount: 0,
        failedCount: 0,
      );
    }

    final successMatch = RegExp(
      r'^(?:Success: )?cleaned metadata for (\d+) (?:images?|files?) to (.+?)(?: \((.*)\))?$',
      caseSensitive: false,
    ).firstMatch(status);

    if (successMatch != null) {
      final saved = int.tryParse(successMatch.group(1) ?? '');
      final details = successMatch.group(3) ?? '';
      final ignored = _detailCount(details, 'ignored');
      final failed = _detailCount(details, 'failed');
      final tone = failed > 0 ? _NoticeTone.warning : _NoticeTone.success;

      return _MetadataResultSummaryData(
        title: failed > 0 ? 'Last result: needs review' : 'Last result',
        message: status,
        tone: tone,
        savedCount: saved,
        ignoredCount: ignored,
        failedCount: failed,
      );
    }

    if (status.startsWith('Could not clean metadata') ||
        status.startsWith('Could not create output folder')) {
      return _MetadataResultSummaryData(
        title: 'Last result: failed',
        message: status,
        tone: _NoticeTone.error,
        savedCount: 0,
        ignoredCount: 0,
        failedCount: 1,
      );
    }

    return null;
  }

  static int _detailCount(String details, String label) {
    final match = RegExp('(\\d+) $label').firstMatch(details);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }
}

class _MetadataResultSummaryCard extends StatelessWidget {
  const _MetadataResultSummaryCard({
    required this.result,
    required this.outputPath,
    required this.onOpenFolder,
  });

  final _MetadataResultSummaryData result;
  final String? outputPath;
  final VoidCallback? onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final accent = switch (result.tone) {
      _NoticeTone.success => redactKitSystemGreenColor,
      _NoticeTone.warning => redactKitSystemOrangeColor,
      _NoticeTone.error => redactKitSystemRedColor,
    };
    final background = switch (result.tone) {
      _NoticeTone.success => redactKitSystemGreenFillColor,
      _NoticeTone.warning => redactKitSystemOrangeFillColor,
      _NoticeTone.error => redactKitSystemRedFillColor,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: redactKitBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox.square(
                  dimension: 34,
                  child: Icon(
                    result.tone == _NoticeTone.error
                        ? Icons.error_outline
                        : result.tone == _NoticeTone.warning
                        ? CupertinoIcons.info
                        : Icons.check_circle,
                    color: accent,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (result.savedCount != null)
                _ResultCountPill(
                  label: 'Cleaned',
                  value: result.savedCount.toString(),
                ),
              _ResultCountPill(
                label: 'Ignored',
                value: result.ignoredCount.toString(),
              ),
              _ResultCountPill(
                label: 'Failed',
                value: result.failedCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: redactKitMutedTextColor,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (outputPath != null || onOpenFolder != null) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                if (outputPath != null)
                  Expanded(
                    child: _CupertinoTooltip(
                      message: outputPath!,
                      child: Text(
                        outputPath!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: redactKitMutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                if (onOpenFolder != null) ...<Widget>[
                  const SizedBox(width: 10),
                  _CupertinoActionButton(
                    onPressed: onOpenFolder,
                    icon: const Icon(CupertinoIcons.folder),
                    label: 'Open Folder',
                    emphasis: _CupertinoControlEmphasis.outlined,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCountPill extends StatelessWidget {
  const _ResultCountPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: redactKitGroupedFillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: redactKitSubtleBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                color: redactKitPrimaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: redactKitMutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileMetadataCleanerView extends StatelessWidget {
  const _MobileMetadataCleanerView({
    required this.state,
    required this.controller,
    required this.canClean,
  });

  final RedactionState state;
  final RedactionController controller;
  final bool canClean;

  @override
  Widget build(BuildContext context) {
    final showImageExportControls =
        state.hasMetadataInput && state.metadataHasImages;
    final showPdfExportControls =
        state.hasMetadataInput && state.metadataHasPdfs;
    final inputItems = controller.metadataInputItems;
    final hasFolderInput = _metadataInputHasFolder(inputItems);
    final openingPhotos =
        state.isOpening && state.status.toLowerCase().contains('photo');

    return ColoredBox(
      color: redactKitBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Metadata Only',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusPill(
                  text: state.hasMetadataInput
                      ? '${state.metadataInputCount} selected'
                      : 'No input',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MobileMetadataSection(
              title: 'Input',
              icon: CupertinoIcons.tray_arrow_down,
              children: <Widget>[
                _MetadataInputChooserButton(
                  title: _metadataChooserTitle(
                    state.hasMetadataInput,
                    hasFolderInput,
                  ),
                  description: _metadataChooserDescription(
                    state.hasMetadataInput,
                    hasFolderInput,
                  ),
                  icon: _metadataChooserIcon(
                    state.hasMetadataInput,
                    hasFolderInput,
                  ),
                  onPressed: _metadataChooserAction(
                    canClean: canClean,
                    hasInput: state.hasMetadataInput,
                    hasFolderInput: hasFolderInput,
                    controller: controller,
                  ),
                  loading: state.isOpening && !openingPhotos,
                ),
                const SizedBox(height: 10),
                _MetadataInputChooserButton(
                  title: 'Photos',
                  description: hasFolderInput
                      ? 'Remove the folder before adding photos.'
                      : 'Choose images from Photos.',
                  icon: CupertinoIcons.photo_on_rectangle,
                  onPressed: _metadataPhotosAction(
                    canClean: canClean,
                    hasFolderInput: hasFolderInput,
                    controller: controller,
                  ),
                  loading: openingPhotos,
                ),
                const SizedBox(height: 12),
                _MetadataInputList(
                  items: inputItems,
                  emptyLabel: 'No input selected',
                  emptyDescription:
                      'Choose files, photos, or a folder containing images and PDFs.',
                  onRemove: canClean ? controller.removeMetadataInputAt : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MobileMetadataSection(
              title: 'Output',
              icon: CupertinoIcons.folder,
              children: <Widget>[
                _MetadataOutputFolderPicker(
                  displayName:
                      state.metadataOutputDirectoryDisplayName ??
                      'Output: app Cleaned folder',
                  path: state.metadataOutputDirectoryPath,
                  onChoose: null,
                  onOpen: null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MobileMetadataSection(
              title: 'Export Format',
              icon: CupertinoIcons.slider_horizontal_3,
              children: <Widget>[
                if (!state.hasMetadataInput)
                  const Text(
                    'Choose input to show matching export controls.',
                    style: TextStyle(
                      color: redactKitMutedTextColor,
                      height: 1.35,
                    ),
                  ),
                if (showImageExportControls) ...<Widget>[
                  _ExportFormatPicker(
                    selected: state.exportFormat,
                    onChanged: controller.setExportFormat,
                  ),
                  const SizedBox(height: 16),
                  _ImageQualityPicker(
                    format: state.exportFormat,
                    selected: state.jpegQualityPreset,
                    onChanged: controller.setJpegQualityPreset,
                  ),
                ],
                if (showPdfExportControls) ...<Widget>[
                  if (showImageExportControls) const SizedBox(height: 16),
                  _PdfQualityPresetPicker(
                    selected: state.pdfQualityPreset,
                    onChanged: controller.setPdfQualityPreset,
                  ),
                ],
                const SizedBox(height: 16),
                _KeepFilenamesToggle(
                  label: 'Keep filenames',
                  value: state.preserveMetadataCleanFileNames,
                  onChanged: canClean
                      ? controller.setPreserveMetadataCleanFileNames
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  _metadataExportFormatDescription(state),
                  style: const TextStyle(
                    color: redactKitMutedTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
            if (state.isCleaningMetadata) ...<Widget>[
              const SizedBox(height: 12),
              _MetadataProgressBanner(
                progress: state.metadataCleanProgress,
                status: state.status,
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: _CupertinoActionButton(
                onPressed: canClean && state.hasMetadataInput
                    ? controller.startMetadataClean
                    : null,
                icon: state.isExporting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CupertinoActivityIndicator(),
                      )
                    : const Icon(CupertinoIcons.play_fill),
                label: 'Start',
                emphasis: _CupertinoControlEmphasis.filled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileMetadataSection extends StatelessWidget {
  const _MobileMetadataSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: redactKitSecondaryBackgroundColor,
        border: Border.all(color: redactKitSubtleBorderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 17, color: redactKitMutedTextColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: redactKitSubtleBorderColor),
        color: redactKitSecondaryBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _CupertinoProgressBar(value: clampedProgress),
        ],
      ),
    );
  }
}

class _CupertinoProgressBar extends StatelessWidget {
  const _CupertinoProgressBar({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final progress = value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const ColoredBox(color: redactKitSubtleBorderColor),
            if (progress != null)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: const ColoredBox(color: redactKitAccentColor),
              )
            else
              const Align(
                alignment: Alignment.center,
                child: CupertinoActivityIndicator(radius: 7),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetadataInputList extends StatelessWidget {
  const _MetadataInputList({
    required this.items,
    required this.emptyLabel,
    required this.emptyDescription,
    required this.onRemove,
  });

  final List<MetadataInputDisplayItem> items;
  final String emptyLabel;
  final String emptyDescription;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _MetadataInputRow(
        icon: CupertinoIcons.tray,
        label: emptyLabel,
        detail: emptyDescription,
        selected: false,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var index = 0; index < items.length; index += 1) ...<Widget>[
          if (index > 0) const SizedBox(height: 8),
          _MetadataInputRow(
            icon: _metadataInputDisplayIcon(items[index].kind),
            label: items[index].label,
            detail: items[index].detail,
            selected: true,
            onRemove: onRemove == null
                ? null
                : () {
                    onRemove!(index);
                  },
          ),
        ],
      ],
    );
  }
}

class _MetadataInputRow extends StatelessWidget {
  const _MetadataInputRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.selected,
    this.onRemove,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: redactKitSubtleBorderColor),
        color: selected ? Colors.white : redactKitGroupedFillColor,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: selected ? redactKitAccentColor : redactKitMutedTextColor,
            size: 21,
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
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: redactKitMutedTextColor,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null) ...<Widget>[
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onRemove,
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: redactKitDisabledColor,
                size: 22,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _metadataInputDisplayIcon(MetadataInputDisplayKind kind) {
  return switch (kind) {
    MetadataInputDisplayKind.image => CupertinoIcons.photo,
    MetadataInputDisplayKind.pdf => CupertinoIcons.doc_text,
    MetadataInputDisplayKind.folder => CupertinoIcons.folder,
  };
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
        _CupertinoTooltip(
          message: path ?? displayName,
          waitDuration: const Duration(milliseconds: 450),
          child: GestureDetector(
            onTap: () => _showMetadataOutputDetails(context, displayName, path),
            onLongPress: () =>
                _showMetadataOutputDetails(context, displayName, path),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: redactKitSubtleBorderColor),
                color: redactKitGroupedFillColor,
              ),
              child: Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: redactKitMutedTextColor,
                  fontWeight: FontWeight.w500,
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
                _CupertinoActionButton(
                  onPressed: onOpen,
                  icon: const Icon(Icons.folder_open),
                  label: 'Open Folder',
                  emphasis: _CupertinoControlEmphasis.outlined,
                ),
              if (onChoose != null)
                _CupertinoActionButton(
                  onPressed: onChoose,
                  icon: const Icon(Icons.drive_folder_upload_outlined),
                  label: 'Choose Folder',
                  emphasis: _CupertinoControlEmphasis.outlined,
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

  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      return _CupertinoSheetSurface(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                  _CupertinoTooltip(
                    message: 'Close',
                    child: _CupertinoIconControl(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(CupertinoIcons.xmark),
                      emphasis: _CupertinoControlEmphasis.outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: redactKitBorderColor),
                  color: redactKitGroupedFillColor,
                ),
                child: SelectableText(
                  output,
                  style: const TextStyle(
                    color: redactKitPrimaryTextColor,
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
                    border: Border.all(color: redactKitBorderColor),
                    color: redactKitGroupedFillColor,
                  ),
                  child: SelectableText(
                    path,
                    style: const TextStyle(
                      color: redactKitPrimaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _CupertinoActionButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: copyValue));
                    if (!context.mounted) return;
                    _showCompletionNotice(
                      context,
                      const _CompletionNotice(
                        title: 'Copied',
                        message: 'Output path copied.',
                        tone: _NoticeTone.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: 'Copy',
                  emphasis: _CupertinoControlEmphasis.outlined,
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
    required this.image,
    required this.redactions,
    required this.onBeginRedaction,
    required this.onUpdateRedaction,
    required this.onFinishRedaction,
    required this.onOpen,
    required this.emptyTitle,
    required this.openLabel,
    this.onOpenPhotos,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 0, 16),
    this.showBorder = true,
    this.fitPadding = 24,
    this.showPhotoButton = false,
    this.enablePanZoom = false,
    this.compactEmptyState = false,
  });

  final RedactionState state;
  final ui.Image? image;
  final List<RedactionRegion> redactions;
  final void Function(Offset localPosition, Rect imageRect) onBeginRedaction;
  final void Function(Offset localPosition, Rect imageRect) onUpdateRedaction;
  final VoidCallback onFinishRedaction;
  final VoidCallback onOpen;
  final VoidCallback? onOpenPhotos;
  final String emptyTitle;
  final String openLabel;
  final EdgeInsetsGeometry margin;
  final bool showBorder;
  final double fitPadding;
  final bool showPhotoButton;
  final bool enablePanZoom;
  final bool compactEmptyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = this.image;

    if (image == null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: redactKitSecondaryBackgroundColor,
          border: showBorder ? Border.all(color: redactKitBorderColor) : null,
        ),
        child: Center(
          child: compactEmptyState
              ? _MobileCanvasEmptyState(
                  isOpening: state.isOpening,
                  showPhotoButton: showPhotoButton,
                  title: emptyTitle,
                  openLabel: openLabel,
                  onOpen: onOpen,
                  onOpenPhotos: onOpenPhotos,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 220,
                      child: _SourceActionButton(
                        onPressed: state.isOpening ? null : onOpen,
                        icon: Icons.folder_open,
                        label: openLabel,
                      ),
                    ),
                    if (showPhotoButton && onOpenPhotos != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SizedBox(
                          width: 220,
                          child: _SourceActionButton(
                            onPressed: state.isOpening ? null : onOpenPhotos,
                            icon: Icons.photo_library_outlined,
                            label: 'Photos',
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
        color: redactKitSecondaryBackgroundColor,
        border: showBorder ? Border.all(color: redactKitBorderColor) : null,
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
              redactions: redactions,
              onBeginRedaction: onBeginRedaction,
              onUpdateRedaction: onUpdateRedaction,
              onFinishRedaction: onFinishRedaction,
            );
          }

          return _PlainRedactionCanvas(
            state: state,
            image: image,
            imageRect: imageRect,
            redactions: redactions,
            onBeginRedaction: onBeginRedaction,
            onUpdateRedaction: onUpdateRedaction,
            onFinishRedaction: onFinishRedaction,
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

class _MobileCanvasEmptyState extends StatelessWidget {
  const _MobileCanvasEmptyState({
    required this.isOpening,
    required this.showPhotoButton,
    required this.title,
    required this.openLabel,
    required this.onOpen,
    required this.onOpenPhotos,
  });

  final bool isOpening;
  final bool showPhotoButton;
  final String title;
  final String openLabel;
  final VoidCallback onOpen;
  final VoidCallback? onOpenPhotos;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 304),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: redactKitAccentFillColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: redactKitAccentBorderColor),
              ),
              child: const SizedBox.square(
                dimension: 62,
                child: Icon(
                  CupertinoIcons.lock_shield_fill,
                  color: redactKitAccentColor,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: redactKitPrimaryTextColor,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _SourceActionButton(
              onPressed: isOpening ? null : onOpen,
              icon: CupertinoIcons.folder,
              label: openLabel,
            ),
            if (showPhotoButton && onOpenPhotos != null) ...<Widget>[
              const SizedBox(height: 10),
              _SourceActionButton(
                onPressed: isOpening ? null : onOpenPhotos,
                icon: CupertinoIcons.photo_on_rectangle,
                label: 'Photos',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceActionButton extends StatelessWidget {
  const _SourceActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = !enabled
        ? redactKitDisabledColor
        : redactKitInputActionTextColor;
    final background = !enabled
        ? redactKitDisabledFillColor
        : redactKitInputActionFillColor;
    final borderColor = enabled
        ? redactKitInputActionBorderColor
        : redactKitSubtleBorderColor;

    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: foreground, size: 18),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlainRedactionCanvas extends StatelessWidget {
  const _PlainRedactionCanvas({
    required this.state,
    required this.image,
    required this.imageRect,
    required this.redactions,
    required this.onBeginRedaction,
    required this.onUpdateRedaction,
    required this.onFinishRedaction,
  });

  final RedactionState state;
  final ui.Image image;
  final Rect imageRect;
  final List<RedactionRegion> redactions;
  final void Function(Offset localPosition, Rect imageRect) onBeginRedaction;
  final void Function(Offset localPosition, Rect imageRect) onUpdateRedaction;
  final VoidCallback onFinishRedaction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        onBeginRedaction(details.localPosition, imageRect);
      },
      onPanUpdate: (details) {
        onUpdateRedaction(details.localPosition, imageRect);
      },
      onPanEnd: (_) => onFinishRedaction(),
      onPanCancel: onFinishRedaction,
      child: _RedactionPaintSurface(
        state: state,
        image: image,
        imageRect: imageRect,
        redactions: redactions,
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
    required this.redactions,
    required this.onBeginRedaction,
    required this.onUpdateRedaction,
    required this.onFinishRedaction,
  });

  final RedactionState state;
  final ui.Image image;
  final Rect imageRect;
  final Size canvasSize;
  final List<RedactionRegion> redactions;
  final void Function(Offset localPosition, Rect imageRect) onBeginRedaction;
  final void Function(Offset localPosition, Rect imageRect) onUpdateRedaction;
  final VoidCallback onFinishRedaction;

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
          widget.onFinishRedaction();
          return;
        }

        _gestureMode = _CanvasGestureMode.draw;
        widget.onBeginRedaction(
          _toCanvasPoint(details.localFocalPoint, effectiveOffset),
          widget.imageRect,
        );
      },
      onScaleUpdate: (details) {
        if (details.pointerCount >= 2) {
          if (_gestureMode != _CanvasGestureMode.zoom) {
            _gestureMode = _CanvasGestureMode.zoom;
            widget.onFinishRedaction();
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
          widget.onUpdateRedaction(
            _toCanvasPoint(details.localFocalPoint, effectiveOffset),
            widget.imageRect,
          );
        }
      },
      onScaleEnd: (_) {
        if (_gestureMode == _CanvasGestureMode.draw) {
          widget.onFinishRedaction();
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
                redactions: widget.redactions,
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
    required this.redactions,
  });

  final RedactionState state;
  final ui.Image image;
  final Rect imageRect;
  final List<RedactionRegion> redactions;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: CustomPaint(
        painter: RedactionPainter(
          image: image,
          imageRect: imageRect,
          redactions: redactions,
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
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: redactKitSecondaryBackgroundColor,
        border: Border(bottom: BorderSide(color: redactKitSubtleBorderColor)),
      ),
      child: Row(
        children: <Widget>[
          const _DesktopAppTitle(),
          const SizedBox(width: 18),
          SizedBox(
            width: 310,
            child: _ModeSwitcher(mode: mode, onModeChanged: onModeChanged),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _DesktopStatusBadge(
              status: status,
              busy: isOpening || isExporting,
            ),
          ),
          const SizedBox(width: 14),
          if (mode != _WorkspaceMode.metadata)
            DecoratedBox(
              decoration: BoxDecoration(
                color: redactKitGroupedFillColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: redactKitSubtleBorderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _DesktopToolbarAction(
                      message: 'Files',
                      onPressed: isOpening ? null : onOpen,
                      icon: isOpening
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CupertinoActivityIndicator(radius: 9),
                            )
                          : const Icon(Icons.folder_open),
                      emphasis: _ToolbarEmphasis.tonal,
                    ),
                    if (mode == _WorkspaceMode.redact)
                      _DesktopToolbarAction(
                        message: 'Photos',
                        onPressed: isOpening ? null : onOpenPhotos,
                        icon: const Icon(Icons.photo_library_outlined),
                        emphasis: _ToolbarEmphasis.tonal,
                      ),
                    const _ToolbarDivider(),
                    _DesktopToolbarAction(
                      message: 'Undo',
                      onPressed: canUndo ? onUndo : null,
                      icon: const Icon(Icons.undo),
                    ),
                    _DesktopToolbarAction(
                      message: 'Clear',
                      onPressed: canClear ? onClear : null,
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const _ToolbarDivider(),
                    _DesktopToolbarAction(
                      message: 'Save to Files',
                      onPressed: canExport ? onExport : null,
                      icon: isExporting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CupertinoActivityIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_alt),
                      emphasis: _ToolbarEmphasis.filled,
                    ),
                    if (mode == _WorkspaceMode.redact) ...<Widget>[
                      _DesktopToolbarAction(
                        message: 'Save to Photos',
                        onPressed: canExport ? onSaveToPhotos : null,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        emphasis: _ToolbarEmphasis.tonal,
                      ),
                      _DesktopToolbarAction(
                        message: 'Share',
                        onPressed: canExport ? onShare : null,
                        icon: const Icon(Icons.ios_share),
                        emphasis: _ToolbarEmphasis.tonal,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(width: 10),
          _CupertinoTooltip(
            message: switch (mode) {
              _WorkspaceMode.redact => 'Image details',
              _WorkspaceMode.pdf => 'PDF details',
              _WorkspaceMode.metadata => 'Metadata details',
            },
            child: _CupertinoIconControl(
              onPressed: onHelp,
              icon: const Icon(CupertinoIcons.info),
              emphasis: _CupertinoControlEmphasis.outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopAppTitle extends StatelessWidget {
  const _DesktopAppTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: redactKitAccentFillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: redactKitSubtleBorderColor),
          ),
          child: const SizedBox.square(
            dimension: 36,
            child: Icon(
              CupertinoIcons.lock_shield_fill,
              color: redactKitAccentColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Redact Kit',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DesktopStatusBadge extends StatelessWidget {
  const _DesktopStatusBadge({required this.status, required this.busy});

  final String status;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: redactKitGroupedFillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: redactKitSubtleBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          busy ? 'Working: $status' : status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: redactKitMutedTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

enum _ToolbarEmphasis { plain, tonal, filled }

class _DesktopToolbarAction extends StatelessWidget {
  const _DesktopToolbarAction({
    required this.message,
    required this.onPressed,
    required this.icon,
    this.emphasis = _ToolbarEmphasis.plain,
  });

  final String message;
  final VoidCallback? onPressed;
  final Widget icon;
  final _ToolbarEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final button = _CupertinoIconControl(
      onPressed: onPressed,
      icon: icon,
      emphasis: switch (emphasis) {
        _ToolbarEmphasis.filled => _CupertinoControlEmphasis.filled,
        _ToolbarEmphasis.tonal => _CupertinoControlEmphasis.tonal,
        _ToolbarEmphasis.plain => _CupertinoControlEmphasis.outlined,
      },
    );

    return _CupertinoTooltip(message: message, child: button);
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: redactKitSubtleBorderColor,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: redactKitBorderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _InspectorSection(
              title: 'Tool',
              icon: Icons.format_color_fill_outlined,
              child: Row(
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
            ),
            const SizedBox(height: 12),
            _InspectorSection(
              title: 'Image',
              icon: Icons.image_outlined,
              child: Column(
                children: <Widget>[
                  _MetricRow(
                    label: 'Pixels',
                    value: image == null
                        ? 'None'
                        : '${image.width} x ${image.height}',
                  ),
                  _MetricRow(label: 'Redactions', value: '$redactionCount'),
                  const _MetricRow(label: 'Cover', value: '100% opaque'),
                  _MetricRow(label: 'Format', value: exportFormat.label),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InspectorSection(
              title: 'Export',
              icon: Icons.save_alt,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ExportFormatPicker(
                    selected: exportFormat,
                    onChanged: onExportFormatChanged,
                  ),
                  const SizedBox(height: 16),
                  _ImageQualityPicker(
                    format: exportFormat,
                    selected: jpegQualityPreset,
                    onChanged: onJpegQualityPresetChanged,
                  ),
                  const SizedBox(height: 16),
                  _KeepFilenamesToggle(
                    label: 'Keep filename',
                    value: preserveRedactionExportFileName,
                    onChanged: onPreserveRedactionExportFileNameChanged,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    exportFormat == ExportFormat.png
                        ? 'PNG is lossless. The exported file is rebuilt from visible pixels.'
                        : 'JPEG is lossy. Lower quality makes smaller files.',
                    style: const TextStyle(
                      color: redactKitMutedTextColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfSidePanel extends StatelessWidget {
  const _PdfSidePanel({
    required this.state,
    required this.selectedColor,
    required this.onColorChanged,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onPageChanged,
    required this.onExport,
    required this.onPdfQualityPresetChanged,
    required this.onPreservePdfExportFileNameChanged,
  });

  final RedactionState state;
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onExport;
  final ValueChanged<PdfQualityPreset> onPdfQualityPresetChanged;
  final ValueChanged<bool> onPreservePdfExportFileNameChanged;

  @override
  Widget build(BuildContext context) {
    final pageImage = state.pdfPageImage;
    final canExport = state.hasPdf && !state.isExporting;
    final canMoveBack = state.hasPdf && state.pdfCurrentPage > 1;
    final canMoveForward =
        state.hasPdf && state.pdfCurrentPage < state.pdfPageCount;

    return Container(
      width: 320,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: redactKitBorderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _InspectorSection(
              title: 'Tool',
              icon: Icons.format_color_fill_outlined,
              child: Row(
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
            ),
            const SizedBox(height: 12),
            _InspectorSection(
              title: 'PDF',
              icon: Icons.picture_as_pdf_outlined,
              child: Column(
                children: <Widget>[
                  _MetricRow(
                    label: 'Page',
                    value: state.hasPdf
                        ? '${state.pdfCurrentPage} / ${state.pdfPageCount}'
                        : 'None',
                  ),
                  _MetricRow(
                    label: 'Pixels',
                    value: pageImage == null
                        ? 'None'
                        : '${pageImage.width} x ${pageImage.height}',
                  ),
                  _MetricRow(
                    label: 'Page redactions',
                    value: '${state.currentPdfRedactions.length}',
                  ),
                  _MetricRow(
                    label: 'Total redactions',
                    value: '${state.pdfRedactionCount}',
                  ),
                  const SizedBox(height: 10),
                  _PdfPageNumberField(
                    currentPage: state.pdfCurrentPage,
                    pageCount: state.pdfPageCount,
                    isBusy: state.isOpening || state.isExporting,
                    onPageChanged: onPageChanged,
                  ),
                  if (state.pdfPageCount > 1) ...<Widget>[
                    const SizedBox(height: 6),
                    _PdfPageSlider(
                      currentPage: state.pdfCurrentPage,
                      pageCount: state.pdfPageCount,
                      isBusy: state.isOpening || state.isExporting,
                      onPageChanged: onPageChanged,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _CupertinoActionButton(
                          onPressed: canMoveBack ? onPreviousPage : null,
                          icon: const Icon(Icons.chevron_left),
                          label: 'Prev',
                          emphasis: _CupertinoControlEmphasis.outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CupertinoActionButton(
                          onPressed: canMoveForward ? onNextPage : null,
                          icon: const Icon(Icons.chevron_right),
                          label: 'Next',
                          emphasis: _CupertinoControlEmphasis.outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InspectorSection(
              title: 'Export',
              icon: Icons.save_alt,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _PdfQualityPresetPicker(
                    selected: state.pdfQualityPreset,
                    onChanged: onPdfQualityPresetChanged,
                  ),
                  const SizedBox(height: 16),
                  _KeepFilenamesToggle(
                    label: 'Keep filename',
                    value: state.preservePdfExportFileName,
                    onChanged: onPreservePdfExportFileNameChanged,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PDF exports are flattened into image pages. Redacted export removes original PDF metadata and hidden document structure.',
                    style: TextStyle(
                      color: redactKitMutedTextColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CupertinoActionButton(
                    onPressed: canExport ? onExport : null,
                    icon: state.isExporting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CupertinoActivityIndicator(),
                          )
                        : const Icon(Icons.save_alt),
                    label: 'Save Redacted PDF',
                    emphasis: _CupertinoControlEmphasis.filled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectorSection extends StatelessWidget {
  const _InspectorSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 17, color: redactKitAccentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 2),
      ],
    );
  }
}

class _ExportFormatPicker extends StatelessWidget {
  const _ExportFormatPicker({required this.selected, required this.onChanged});

  final ExportFormat selected;
  final ValueChanged<ExportFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CupertinoSegmentedControl<ExportFormat>(
      selected: selected,
      values: ExportFormat.values,
      labelFor: (format) => format.label,
      onChanged: onChanged,
    );
  }
}

class _ImageQualityPicker extends StatelessWidget {
  const _ImageQualityPicker({
    required this.format,
    required this.selected,
    required this.onChanged,
  });

  final ExportFormat format;
  final JpegQualityPreset selected;
  final ValueChanged<JpegQualityPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    if (format == ExportFormat.jpeg) {
      return _JpegQualityPresetPicker(
        title: 'Image quality',
        selected: selected,
        onChanged: onChanged,
      );
    }

    return const _ReadOnlyQualityIndicator(
      title: 'Image quality',
      value: 'Original lossless',
      description:
          'PNG output keeps visible pixels lossless and strips metadata.',
    );
  }
}

class _PdfQualityPresetPicker extends StatelessWidget {
  const _PdfQualityPresetPicker({
    required this.selected,
    required this.onChanged,
  });

  final PdfQualityPreset selected;
  final ValueChanged<PdfQualityPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return _QualityPicker<PdfQualityPreset>(
      title: 'PDF quality',
      value: selected.label,
      values: PdfQualityPreset.values,
      selected: selected,
      labelFor: (preset) => preset.label,
      description: selected.description,
      onChanged: onChanged,
    );
  }
}

class _JpegQualityPresetPicker extends StatelessWidget {
  const _JpegQualityPresetPicker({
    required this.title,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final JpegQualityPreset selected;
  final ValueChanged<JpegQualityPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return _QualityPicker<JpegQualityPreset>(
      title: title,
      value: selected.label,
      values: JpegQualityPreset.values,
      selected: selected,
      labelFor: (preset) => preset.label,
      description: selected.description,
      onChanged: onChanged,
    );
  }
}

class _QualityPicker<T extends Object> extends StatelessWidget {
  const _QualityPicker({
    required this.title,
    required this.value,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.description,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final String description;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: redactKitMutedTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        _CupertinoSegmentedControl<T>(
          selected: selected,
          values: values,
          labelFor: labelFor,
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(color: redactKitMutedTextColor, height: 1.35),
        ),
      ],
    );
  }
}

class _ReadOnlyQualityIndicator extends StatelessWidget {
  const _ReadOnlyQualityIndicator({
    required this.title,
    required this.value,
    required this.description,
  });

  final String title;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: redactKitMutedTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: redactKitGroupedFillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: redactKitBorderColor),
          ),
          child: const SizedBox(
            width: double.infinity,
            height: 42,
            child: Center(
              child: Text(
                'Original',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(color: redactKitMutedTextColor, height: 1.35),
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
          color: redactKitMutedTextColor,
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
                color: redactKitMutedTextColor,
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
    return _CupertinoTooltip(
      message: label,
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        child: Container(
          width: 48,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? redactKitAccentColor : redactKitBorderColor,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  CupertinoIcons.checkmark,
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

    return _CupertinoTooltip(
      message: label,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: <Widget>[
              CupertinoSwitch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeTrackColor: redactKitAccentColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled ? null : redactKitDisabledColor,
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
