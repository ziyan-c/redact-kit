import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/platform_style.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/redaction_controller.dart';
import '../domain/export_format.dart';
import '../domain/jpeg_quality_preset.dart';
import '../domain/metadata_input_display.dart';
import '../domain/pdf_quality_preset.dart';
import '../domain/redaction_region.dart';
import '../domain/redaction_state.dart';
import '../domain/redaction_status.dart';
import 'redaction_painter.dart';

enum _WorkspaceMode { redact, pdf, metadata }

extension _RedactKitL10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class RedactWorkspace extends ConsumerStatefulWidget {
  const RedactWorkspace({super.key});

  @override
  ConsumerState<RedactWorkspace> createState() => _RedactWorkspaceState();
}

class _RedactWorkspaceState extends ConsumerState<RedactWorkspace> {
  _WorkspaceMode _mode = _WorkspaceMode.redact;
  RedactionStatus? _lastCompletionNoticeStatus;

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

    final notice = _completionNoticeForStatus(next.statusMessage, context.l10n);
    if (notice == null) return;
    if (_lastCompletionNoticeStatus == next.statusMessage) return;

    _lastCompletionNoticeStatus = next.statusMessage;
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

String _localizedStatus(RedactionStatus status, AppLocalizations l10n) {
  final label = status.label ?? '';
  final detail = status.detail;
  final format = status.formatLabel ?? '';
  final destination = status.destinationName ?? '';
  final count = status.count ?? 0;
  final pageNumber = status.pageNumber ?? 0;
  final pageCount = status.pageCount ?? 0;
  final current = status.current ?? 0;
  final total = status.total ?? 0;
  final savedCount = status.savedCount ?? 0;
  final failedCount = status.failedCount ?? 0;
  final ignoredCount = status.ignoredCount ?? 0;

  return switch (status.kind) {
    RedactionStatusKind.ready => l10n.ready,
    RedactionStatusKind.openingImage => l10n.statusOpeningImage,
    RedactionStatusKind.openingPhotoLibrary => l10n.statusOpeningPhotoLibrary,
    RedactionStatusKind.openingPdf => l10n.statusOpeningPdf,
    RedactionStatusKind.loadedImage => l10n.statusLoadedImage(
      status.width ?? 0,
      status.height ?? 0,
    ),
    RedactionStatusKind.adjustingCrop => l10n.statusAdjustingCrop,
    RedactionStatusKind.croppingImage => l10n.statusCroppingImage,
    RedactionStatusKind.imageCropped => l10n.statusImageCropped(
      status.width ?? 0,
      status.height ?? 0,
    ),
    RedactionStatusKind.cropCanceled => l10n.statusCropCanceled,
    RedactionStatusKind.pdfPage => l10n.statusPdfPage(pageNumber, pageCount),
    RedactionStatusKind.renderingPdfPage => l10n.statusRenderingPdfPage(
      pageNumber,
    ),
    RedactionStatusKind.flatteningCleanPdf => l10n.statusFlatteningCleanPdf,
    RedactionStatusKind.flatteningPdfPage => l10n.statusFlatteningPdfPage(
      pageNumber,
      pageCount,
    ),
    RedactionStatusKind.choosingPdf => l10n.statusChoosingPdf,
    RedactionStatusKind.choosingFilesOrFolder =>
      l10n.statusChoosingFilesOrFolder,
    RedactionStatusKind.choosingImageFile => l10n.statusChoosingImageFile,
    RedactionStatusKind.choosingImageFiles => l10n.statusChoosingImageFiles,
    RedactionStatusKind.choosingPdfFile => l10n.statusChoosingPdfFile,
    RedactionStatusKind.choosingPdfFiles => l10n.statusChoosingPdfFiles,
    RedactionStatusKind.choosingFolder => l10n.statusChoosingFolder,
    RedactionStatusKind.choosingImagesFromPhotos =>
      l10n.statusChoosingImagesFromPhotos,
    RedactionStatusKind.choosingOutputFolder => l10n.statusChoosingOutputFolder,
    RedactionStatusKind.addingFiles => l10n.statusAddingFiles,
    RedactionStatusKind.addingPhotos => l10n.statusAddingPhotos,
    RedactionStatusKind.selectedMetadataInput =>
      l10n.statusSelectedMetadataInput(
        _localizedMetadataSummary(status.metadataInputSummary, label, l10n),
      ),
    RedactionStatusKind.removedMetadataInput => l10n.statusRemovedMetadataInput(
      _localizedMetadataSummary(status.metadataInputSummary, label, l10n),
    ),
    RedactionStatusKind.noSupportedImagesOrPdfsSelected =>
      l10n.statusNoSupportedImagesOrPdfsSelected,
    RedactionStatusKind.noSupportedImagesOrPdfsFoundInFolder =>
      l10n.statusNoSupportedImagesOrPdfsFoundInFolder,
    RedactionStatusKind.noPhotosSelected => l10n.statusNoPhotosSelected,
    RedactionStatusKind.removeFolderBeforeAddingPhotos =>
      l10n.statusRemoveFolderBeforeAddingPhotos,
    RedactionStatusKind.chooseMetadataInputFirst =>
      l10n.statusChooseMetadataInputFirst,
    RedactionStatusKind.metadataOutputFolderSet =>
      l10n.statusMetadataOutputFolderSet,
    RedactionStatusKind.startCleaningFirstToCreateOutputFolder =>
      l10n.statusStartCleaningFirstToCreateOutputFolder,
    RedactionStatusKind.openedOutputFolder => l10n.statusOpenedOutputFolder,
    RedactionStatusKind.encodingCleanImage => l10n.statusEncodingCleanImage(
      format,
    ),
    RedactionStatusKind.removingImageMetadata =>
      l10n.statusRemovingImageMetadata(format),
    RedactionStatusKind.preparingCleanImageToShare =>
      l10n.statusPreparingCleanImageToShare(format),
    RedactionStatusKind.savingCleanImageToPhotos =>
      l10n.statusSavingCleanImageToPhotos(format),
    RedactionStatusKind.exportedCleanImage =>
      count == 0
          ? l10n.statusExportedCleanImage(format)
          : l10n.statusExportedCleanImageWithRedactions(format, count),
    RedactionStatusKind.savedCleanImageToPhotos =>
      l10n.statusSavedCleanImageToPhotos(format),
    RedactionStatusKind.sharedCleanImage => l10n.statusSharedCleanImage(format),
    RedactionStatusKind.savedMetadataCleanImage =>
      l10n.statusSavedMetadataCleanImage(format),
    RedactionStatusKind.cleaningPdfMetadata => l10n.statusCleaningPdfMetadata,
    RedactionStatusKind.savedMetadataCleanPdf =>
      l10n.statusSavedMetadataCleanPdf,
    RedactionStatusKind.exportedCleanPdf =>
      count == 0
          ? l10n.statusExportedCleanPdf
          : l10n.statusExportedCleanPdfWithRedactions(count),
    RedactionStatusKind.exportCanceled => l10n.statusExportCanceled,
    RedactionStatusKind.metadataRemovalCanceled =>
      l10n.statusMetadataRemovalCanceled,
    RedactionStatusKind.pdfExportCanceled => l10n.statusPdfExportCanceled,
    RedactionStatusKind.pdfCleanCanceled => l10n.statusPdfCleanCanceled,
    RedactionStatusKind.shareCanceled => l10n.statusShareCanceled,
    RedactionStatusKind.saveCanceled => l10n.statusSaveCanceled,
    RedactionStatusKind.startingMetadataClean =>
      l10n.statusStartingMetadataClean,
    RedactionStatusKind.preparingOutputFolder =>
      l10n.statusPreparingOutputFolder,
    RedactionStatusKind.startingMetadataCleanToPhotos =>
      l10n.statusStartingMetadataCleanToPhotos,
    RedactionStatusKind.photosOutputImagesOnly =>
      l10n.statusPhotosOutputImagesOnly,
    RedactionStatusKind.cleaningMetadataItem => l10n.statusCleaningMetadataItem(
      label,
      current,
      total,
    ),
    RedactionStatusKind.cleaningMetadataPdfPage =>
      l10n.statusCleaningMetadataPdfPage(
        label,
        pageNumber,
        pageCount,
        current,
        total,
      ),
    RedactionStatusKind.savingMetadataItemToPhotos =>
      l10n.statusSavingMetadataItemToPhotos(label, current, total),
    RedactionStatusKind.metadataBatchResult => _localizedMetadataBatchResult(
      l10n: l10n,
      savedCount: savedCount,
      failedCount: failedCount,
      ignoredCount: ignoredCount,
      destinationName: destination,
      firstFailure: detail,
    ),
    RedactionStatusKind.redactionsCleared => l10n.statusRedactionsCleared,
    RedactionStatusKind.pdfPageRedactionsCleared =>
      l10n.statusPdfPageRedactionsCleared,
    RedactionStatusKind.redactionCountReady => l10n.redactionCountReady(count),
    RedactionStatusKind.pdfRedactionCountReady =>
      l10n.statusPdfRedactionCountReady(pageNumber, count),
    RedactionStatusKind.couldNotOpenPdf => _localizedFailure(
      l10n,
      l10n.statusCouldNotOpenPdf,
      detail,
    ),
    RedactionStatusKind.couldNotOpenImage => _localizedFailure(
      l10n,
      l10n.statusCouldNotOpenImage,
      detail,
    ),
    RedactionStatusKind.couldNotDecodeImage => l10n.statusCouldNotDecodeImage,
    RedactionStatusKind.couldNotExportImage => _localizedFailure(
      l10n,
      l10n.statusCouldNotExportImage,
      detail,
    ),
    RedactionStatusKind.couldNotExportPdf => _localizedFailure(
      l10n,
      l10n.statusCouldNotExportPdf,
      detail,
    ),
    RedactionStatusKind.couldNotChooseMetadataInput => _localizedFailure(
      l10n,
      l10n.statusCouldNotChooseMetadataInput,
      detail,
    ),
    RedactionStatusKind.couldNotAddMetadataFiles => _localizedFailure(
      l10n,
      l10n.statusCouldNotAddMetadataFiles,
      detail,
    ),
    RedactionStatusKind.couldNotAddPhotos => _localizedFailure(
      l10n,
      l10n.statusCouldNotAddPhotos,
      detail,
    ),
    RedactionStatusKind.couldNotChooseOutputFolder => _localizedFailure(
      l10n,
      l10n.statusCouldNotChooseOutputFolder,
      detail,
    ),
    RedactionStatusKind.couldNotOpenOutputFolder => _localizedFailure(
      l10n,
      l10n.statusCouldNotOpenOutputFolder,
      detail,
    ),
    RedactionStatusKind.couldNotCleanMetadata => _localizedFailure(
      l10n,
      l10n.statusCouldNotCleanMetadata,
      detail,
    ),
    RedactionStatusKind.couldNotCreateOutputFolder =>
      status.automaticOutputFailure
          ? l10n.statusCouldNotCreateOutputFolderAutomatic(status.path ?? '')
          : status.path == null
          ? l10n.statusCouldNotCreateOutputFolder
          : l10n.statusCouldNotCreateOutputFolderPath(status.path!),
    RedactionStatusKind.couldNotRenderPdfPage => _localizedFailure(
      l10n,
      l10n.statusCouldNotRenderPdfPage,
      detail,
    ),
    RedactionStatusKind.externalMessage => status.fallbackMessage,
  };
}

String _localizedFailure(AppLocalizations l10n, String title, String? detail) {
  if (detail == null || detail.trim().isEmpty) return title;
  return l10n.statusFailureWithDetail(title, detail.trim());
}

String _localizedMetadataBatchResult({
  required AppLocalizations l10n,
  required int savedCount,
  required int failedCount,
  required int ignoredCount,
  required String destinationName,
  required String? firstFailure,
}) {
  final details = <String>[
    if (ignoredCount > 0) l10n.statusMetadataBatchIgnoredDetail(ignoredCount),
    if (failedCount > 0 && firstFailure == null)
      l10n.statusMetadataBatchFailedDetail(failedCount),
    if (failedCount > 0 && firstFailure != null)
      l10n.statusMetadataBatchFailedWithReasonDetail(failedCount, firstFailure),
  ];
  final detailText = details.isEmpty
      ? ''
      : l10n.statusMetadataBatchDetailsWrapper(
          details.join(l10n.statusMetadataBatchDetailSeparator),
        );
  if (savedCount == 0) return l10n.statusMetadataBatchNoSaved(detailText);
  return l10n.statusMetadataBatchCompleted(
    savedCount,
    destinationName,
    detailText,
  );
}

String _localizedMetadataSummary(
  MetadataInputSummary? summary,
  String fallback,
  AppLocalizations l10n,
) {
  if (summary == null) return fallback;
  return switch (summary.kind) {
    MetadataInputSummaryKind.folder => l10n.metadataSummaryFolder(
      summary.name ?? '',
    ),
    MetadataInputSummaryKind.images => l10n.metadataSummaryImages(
      summary.count ?? 0,
    ),
    MetadataInputSummaryKind.photos => l10n.metadataSummaryPhotos(
      summary.count ?? 0,
    ),
    MetadataInputSummaryKind.pdfs => l10n.metadataSummaryPdfs(
      summary.count ?? 0,
    ),
    MetadataInputSummaryKind.files => l10n.metadataSummaryFiles(
      summary.count ?? 0,
    ),
  };
}

_CompletionNotice? _completionNoticeForStatus(
  RedactionStatus status,
  AppLocalizations l10n,
) {
  if (status.kind == RedactionStatusKind.exportedCleanImage) {
    return _CompletionNotice(
      title: l10n.cleanImageExported,
      message: l10n.redactionsBurnedMetadataRemoved,
      tone: _NoticeTone.success,
    );
  }

  if (status.kind == RedactionStatusKind.savedCleanImageToPhotos) {
    return _CompletionNotice(
      title: l10n.savedToPhotos,
      message: l10n.cleanImageReadyInPhotos,
      tone: _NoticeTone.success,
    );
  }

  if (status.kind == RedactionStatusKind.sharedCleanImage) {
    return _CompletionNotice(
      title: l10n.readyToShare,
      message: l10n.cleanCopyPreparedForSharing,
      tone: _NoticeTone.success,
    );
  }

  if (status.kind == RedactionStatusKind.savedMetadataCleanImage) {
    return _CompletionNotice(
      title: l10n.metadataRemoved,
      message: l10n.cleanImageSavedWithoutMetadata,
      tone: _NoticeTone.success,
    );
  }

  if (status.kind == RedactionStatusKind.savedMetadataCleanPdf) {
    return _CompletionNotice(
      title: l10n.pdfCleaned,
      message: l10n.flattenedPdfSavedWithoutOriginalMetadata,
      tone: _NoticeTone.success,
    );
  }

  if (status.kind == RedactionStatusKind.exportedCleanPdf) {
    return _CompletionNotice(
      title: l10n.cleanPdfExported,
      message: l10n.pagesFlattenedPdfMetadataRemoved,
      tone: _NoticeTone.success,
    );
  }

  if (status.kind == RedactionStatusKind.metadataBatchResult &&
      (status.failedCount ?? 0) == 0) {
    return _CompletionNotice(
      title: l10n.metadataCleaned,
      message: l10n.cleanCopiesSavedToOutputFolder,
      tone: _NoticeTone.success,
    );
  }

  if (status.kind == RedactionStatusKind.metadataBatchResult &&
      (status.failedCount ?? 0) > 0) {
    return _CompletionNotice(
      title: l10n.metadataCleanedWithNotes,
      message: l10n.someFilesNeedAttention,
      tone: _NoticeTone.warning,
    );
  }

  if (status.kind == RedactionStatusKind.couldNotExportImage ||
      status.kind == RedactionStatusKind.couldNotCleanMetadata ||
      status.kind == RedactionStatusKind.couldNotCreateOutputFolder) {
    return _CompletionNotice(
      title: l10n.couldNotFinish,
      message: _localizedStatus(status, l10n),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: redactKitSubtleBorderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: redactKitChromeShadowColor,
            blurRadius: 18,
            offset: Offset(0, 8),
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
                borderRadius: BorderRadius.circular(12),
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
                      fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w500,
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
    final isImageCropping = mode == _WorkspaceMode.redact && state.isCropping;

    return ColoredBox(
      color: redactKitBackgroundColor,
      child: Column(
        children: <Widget>[
          _TopBar(
            mode: mode,
            onModeChanged: onModeChanged,
            status: state.statusMessage,
            canUndo: mode == _WorkspaceMode.pdf
                ? state.currentPdfRedactions.isNotEmpty
                : state.hasRedactions && !isImageCropping,
            canClear: mode == _WorkspaceMode.pdf
                ? state.currentPdfRedactions.isNotEmpty
                : state.hasRedactions && !isImageCropping,
            canExport: mode == _WorkspaceMode.pdf
                ? state.hasPdf && !state.isExporting
                : state.hasImage && !state.isExporting && !isImageCropping,
            canCrop: state.hasImage && !state.isOpening && !state.isExporting,
            isCropping: isImageCropping,
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
            onStartCrop: controller.startCrop,
            onCancelCrop: controller.cancelCrop,
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
                      cropRect: state.cropRect,
                      onCropChanged: controller.updateCrop,
                      onCancelCrop: controller.cancelCrop,
                      onApplyCrop: controller.applyCrop,
                      onOpen: controller.openImage,
                      onOpenPhotos: controller.openPhotoLibrary,
                      emptyTitle: context.l10n.chooseImage,
                      openLabel: context.l10n.files,
                      fitPadding: 28,
                      showPhotoButton: true,
                      enablePanZoom: true,
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
                      emptyTitle: context.l10n.choosePdf,
                      openLabel: context.l10n.files,
                      fitPadding: 28,
                      enablePanZoom: true,
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
    final isImageCropping = mode == _WorkspaceMode.redact && state.isCropping;
    final canExport = mode == _WorkspaceMode.pdf
        ? state.hasPdf && !state.isExporting
        : state.hasImage && !state.isExporting && !isImageCropping;
    final hasDocument = mode == _WorkspaceMode.pdf
        ? state.hasPdf
        : state.hasImage;

    return ColoredBox(
      color: redactKitBackgroundColor,
      child: Column(
        children: <Widget>[
          _MobileTopBar(
            mode: mode,
            status: state.statusMessage,
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
                cropRect: state.cropRect,
                onCropChanged: controller.updateCrop,
                onCancelCrop: controller.cancelCrop,
                onApplyCrop: controller.applyCrop,
                onOpen: controller.openImage,
                onOpenPhotos: controller.openPhotoLibrary,
                emptyTitle: context.l10n.chooseImage,
                openLabel: context.l10n.files,
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
                emptyTitle: context.l10n.choosePdf,
                openLabel: context.l10n.files,
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
                  : state.hasRedactions && !isImageCropping,
              canClear: mode == _WorkspaceMode.pdf
                  ? state.currentPdfRedactions.isNotEmpty
                  : state.hasRedactions && !isImageCropping,
              isOpening: state.isOpening,
              canExport: canExport,
              canCrop: state.hasImage && !state.isOpening && !state.isExporting,
              isCropping: isImageCropping,
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
              onStartCrop: controller.startCrop,
              onCancelCrop: controller.cancelCrop,
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
    final isImageCropping = mode == _WorkspaceMode.redact && state.isCropping;
    final canExport = mode == _WorkspaceMode.pdf
        ? state.hasPdf && !state.isExporting
        : state.hasImage && !state.isExporting && !isImageCropping;

    return Column(
      children: <Widget>[
        _TabletTopBar(
          mode: mode,
          onModeChanged: onModeChanged,
          status: state.statusMessage,
          canUndo: mode == _WorkspaceMode.pdf
              ? state.currentPdfRedactions.isNotEmpty
              : state.hasRedactions && !isImageCropping,
          canClear: mode == _WorkspaceMode.pdf
              ? state.currentPdfRedactions.isNotEmpty
              : state.hasRedactions && !isImageCropping,
          canExport: canExport,
          canCrop: state.hasImage && !state.isOpening && !state.isExporting,
          isCropping: isImageCropping,
          isExporting: state.isExporting,
          onUndo: mode == _WorkspaceMode.pdf
              ? controller.undoPdfRedaction
              : controller.undo,
          onClear: mode == _WorkspaceMode.pdf
              ? controller.clearPdfPageRedactions
              : controller.clear,
          onStartCrop: controller.startCrop,
          onCancelCrop: controller.cancelCrop,
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
              cropRect: state.cropRect,
              onCropChanged: controller.updateCrop,
              onCancelCrop: controller.cancelCrop,
              onApplyCrop: controller.applyCrop,
              onOpen: controller.openImage,
              onOpenPhotos: controller.openPhotoLibrary,
              emptyTitle: context.l10n.chooseImage,
              openLabel: context.l10n.files,
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
              emptyTitle: context.l10n.choosePdf,
              openLabel: context.l10n.files,
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
    required this.canCrop,
    required this.isCropping,
    required this.isExporting,
    required this.onUndo,
    required this.onClear,
    required this.onStartCrop,
    required this.onCancelCrop,
    required this.onExport,
    required this.onSaveToPhotos,
    required this.onShare,
    required this.onHelp,
    required this.onSettings,
  });

  final _WorkspaceMode mode;
  final ValueChanged<_WorkspaceMode> onModeChanged;
  final RedactionStatus status;
  final bool canUndo;
  final bool canClear;
  final bool canExport;
  final bool canCrop;
  final bool isCropping;
  final bool isExporting;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onStartCrop;
  final VoidCallback onCancelCrop;
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
                Text(
                  context.l10n.appTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _localizedStatus(status, context.l10n),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: redactKitMutedTextColor,
                    fontWeight: FontWeight.w500,
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
              tooltip: context.l10n.undo,
              onPressed: canUndo ? onUndo : null,
              icon: const Icon(Icons.undo),
            ),
            _TopBarIconButton(
              tooltip: context.l10n.clear,
              onPressed: canClear ? onClear : null,
              icon: const Icon(Icons.delete_outline),
            ),
            if (mode == _WorkspaceMode.redact)
              _TopBarIconButton(
                tooltip: isCropping
                    ? context.l10n.cancelCrop
                    : context.l10n.crop,
                onPressed: canCrop
                    ? isCropping
                          ? onCancelCrop
                          : onStartCrop
                    : null,
                icon: const Icon(Icons.crop),
                tonal: isCropping,
              ),
            _TopBarIconButton(
              tooltip: context.l10n.saveToFiles,
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
                tooltip: context.l10n.saveToPhotos,
                onPressed: canExport ? onSaveToPhotos : null,
                icon: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill),
                tonal: true,
              ),
              _TopBarIconButton(
                tooltip: context.l10n.share,
                onPressed: canExport ? onShare : null,
                icon: const Icon(Icons.ios_share),
                tonal: true,
              ),
            ],
          ],
          _TopBarIconButton(
            tooltip: switch (mode) {
              _WorkspaceMode.redact => context.l10n.imageDetails,
              _WorkspaceMode.pdf => context.l10n.pdfDetails,
              _WorkspaceMode.metadata => context.l10n.metadataDetails,
            },
            onPressed: onHelp,
            icon: const Icon(CupertinoIcons.info),
          ),
          if (onSettings != null)
            _TopBarIconButton(
              tooltip: context.l10n.settings,
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
              label: context.l10n.files,
            ),
          ),
          if (!pdfMode && onPhotos != null) ...<Widget>[
            const SizedBox(width: 10),
            SizedBox(
              width: 156,
              child: _SourceActionButton(
                onPressed: isOpening ? null : onPhotos,
                icon: CupertinoIcons.photo_on_rectangle,
                label: context.l10n.photos,
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
        _WorkspaceMode.redact => context.l10n.image,
        _WorkspaceMode.pdf => context.l10n.pdf,
        _WorkspaceMode.metadata => context.l10n.metadata,
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
        backgroundColor: redactKitControlFillColor,
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
              fontWeight: FontWeight.w500,
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
            _CupertinoControlEmphasis.filled => Colors.white,
            _ => redactKitAccentColor,
          }
        : redactKitDisabledColor;
    final background = switch (emphasis) {
      _CupertinoControlEmphasis.filled =>
        enabled ? redactKitAccentColor : redactKitDisabledFillColor,
      _CupertinoControlEmphasis.tonal =>
        enabled ? redactKitAccentFillColor : redactKitDisabledFillColor,
      _CupertinoControlEmphasis.outlined => redactKitSecondaryBackgroundColor,
    };
    final borderColor = switch (emphasis) {
      _CupertinoControlEmphasis.filled =>
        enabled ? redactKitAccentColor : redactKitSubtleBorderColor,
      _CupertinoControlEmphasis.tonal => Colors.transparent,
      _CupertinoControlEmphasis.outlined =>
        enabled ? redactKitAccentBorderColor : redactKitSubtleBorderColor,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: onPressed,
          child: Container(
            constraints: BoxConstraints(
              minHeight: 44,
              minWidth: constraints.hasBoundedWidth ? constraints.maxWidth : 0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground, size: 18),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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
    final borderColor = switch (emphasis) {
      _CupertinoControlEmphasis.filled => Colors.transparent,
      _CupertinoControlEmphasis.tonal => Colors.transparent,
      _CupertinoControlEmphasis.outlined => redactKitBorderColor,
    };

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
          borderRadius: BorderRadius.circular(999),
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
                  label: context.l10n.prev,
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
                  label: context.l10n.next,
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
      placeholder: context.l10n.pagePlaceholder,
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
        borderRadius: BorderRadius.circular(12),
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
  final RedactionStatus status;
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
            ? context.l10n.redactionCountShort(redactionCount)
            : null,
      _WorkspaceMode.pdf =>
        hasPdf ? context.l10n.onPageCount(redactionCount) : null,
      _WorkspaceMode.metadata =>
        hasMetadataInput ? context.l10n.inputSelected : null,
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
                Text(
                  context.l10n.appTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        _localizedStatus(status, context.l10n),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: redactKitMutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
            message: context.l10n.details,
            child: _CupertinoIconControl(
              onPressed: onHelp,
              icon: const Icon(CupertinoIcons.info),
              emphasis: _CupertinoControlEmphasis.outlined,
            ),
          ),
          if (onSettings != null)
            _CupertinoTooltip(
              message: context.l10n.settings,
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
        borderRadius: BorderRadius.circular(999),
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
            fontWeight: FontWeight.w500,
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
    required this.canCrop,
    required this.isCropping,
    required this.onOpen,
    required this.onOpenPhotos,
    required this.onUndo,
    required this.onClear,
    required this.onStartCrop,
    required this.onCancelCrop,
    required this.onExportOptions,
    this.pdfMode = false,
  });

  final bool canUndo;
  final bool canClear;
  final bool isOpening;
  final bool canExport;
  final bool canCrop;
  final bool isCropping;
  final VoidCallback onOpen;
  final VoidCallback onOpenPhotos;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onStartCrop;
  final VoidCallback onCancelCrop;
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
      ),
      child: Row(
        children: <Widget>[
          _MobileToolbarItem(
            icon: pdfMode ? Icons.picture_as_pdf_outlined : Icons.folder_open,
            label: pdfMode ? context.l10n.pdf : context.l10n.files,
            onPressed: isOpening ? null : onOpen,
          ),
          if (!pdfMode)
            _MobileToolbarItem(
              icon: Icons.photo_library_outlined,
              label: context.l10n.photos,
              onPressed: isOpening ? null : onOpenPhotos,
            ),
          if (!pdfMode)
            _MobileToolbarItem(
              icon: Icons.crop,
              label: isCropping ? context.l10n.cancelCrop : context.l10n.crop,
              onPressed: canCrop
                  ? isCropping
                        ? onCancelCrop
                        : onStartCrop
                  : null,
            ),
          _MobileToolbarItem(
            icon: Icons.undo,
            label: context.l10n.undo,
            onPressed: canUndo ? onUndo : null,
          ),
          _MobileToolbarItem(
            icon: Icons.delete_outline,
            label: context.l10n.clear,
            onPressed: canClear ? onClear : null,
          ),
          _MobileToolbarItem(
            icon: canExport
                ? Icons.save_alt
                : CupertinoIcons.slider_horizontal_3,
            label: pdfMode ? context.l10n.save : context.l10n.export,
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
              borderRadius: BorderRadius.circular(12),
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
                          fontWeight: FontWeight.w500,
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
            final canExport =
                state.hasImage && !state.isExporting && !state.isCropping;

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
                        Expanded(
                          child: Text(
                            context.l10n.export,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _CupertinoTooltip(
                          message: context.l10n.close,
                          child: _CupertinoIconControl(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(CupertinoIcons.xmark),
                            emphasis: _CupertinoControlEmphasis.outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PanelHeading(context.l10n.tool),
                    Row(
                      children: <Widget>[
                        _ColorSwatchButton(
                          color: const Color(0xFF050505),
                          selected:
                              state.redactionColor == const Color(0xFF050505),
                          label: context.l10n.black,
                          onTap: () =>
                              controller.selectColor(const Color(0xFF050505)),
                        ),
                        const SizedBox(width: 10),
                        _ColorSwatchButton(
                          color: Colors.white,
                          selected: state.redactionColor == Colors.white,
                          label: context.l10n.white,
                          onTap: () => controller.selectColor(Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _PanelHeading(context.l10n.image),
                    _MetricRow(
                      label: context.l10n.pixels,
                      value: image == null
                          ? context.l10n.none
                          : '${image.width} x ${image.height}',
                    ),
                    _MetricRow(
                      label: context.l10n.redactions,
                      value: '${state.redactions.length}',
                    ),
                    _MetricRow(
                      label: context.l10n.cover,
                      value: context.l10n.coverOpaque,
                    ),
                    const SizedBox(height: 22),
                    const _DividerLine(),
                    const SizedBox(height: 22),
                    _PanelHeading(context.l10n.format),
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
                      label: context.l10n.keepFilename,
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
                                    child: CupertinoActivityIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_alt),
                            label: context.l10n.saveToFiles,
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
                              CupertinoIcons.photo_fill_on_rectangle_fill,
                            ),
                            label: context.l10n.saveToPhotos,
                            emphasis: _CupertinoControlEmphasis.filled,
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
                        label: context.l10n.share,
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
                      Expanded(
                        child: Text(
                          context.l10n.pdfExport,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _CupertinoTooltip(
                        message: context.l10n.close,
                        child: _CupertinoIconControl(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(CupertinoIcons.xmark),
                          emphasis: _CupertinoControlEmphasis.outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PanelHeading(context.l10n.tool),
                  Row(
                    children: <Widget>[
                      _ColorSwatchButton(
                        color: const Color(0xFF050505),
                        selected:
                            state.redactionColor == const Color(0xFF050505),
                        label: context.l10n.black,
                        onTap: () =>
                            controller.selectColor(const Color(0xFF050505)),
                      ),
                      const SizedBox(width: 10),
                      _ColorSwatchButton(
                        color: Colors.white,
                        selected: state.redactionColor == Colors.white,
                        label: context.l10n.white,
                        onTap: () => controller.selectColor(Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _PanelHeading(context.l10n.pdf),
                  _MetricRow(
                    label: context.l10n.pages,
                    value: state.hasPdf
                        ? '${state.pdfPageCount}'
                        : context.l10n.none,
                  ),
                  _MetricRow(
                    label: context.l10n.currentPage,
                    value: state.hasPdf
                        ? '${state.pdfCurrentPage}'
                        : context.l10n.none,
                  ),
                  _MetricRow(
                    label: context.l10n.redactions,
                    value: '${state.pdfRedactionCount}',
                  ),
                  const SizedBox(height: 18),
                  _PdfQualityPresetPicker(
                    selected: state.pdfQualityPreset,
                    onChanged: controller.setPdfQualityPreset,
                  ),
                  const SizedBox(height: 18),
                  _KeepFilenamesToggle(
                    label: context.l10n.keepFilename,
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
                                  child: CupertinoActivityIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_alt),
                          label: context.l10n.saveRedactedPdf,
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
  final l10n = context.l10n;
  _showDetails(
    context,
    title: l10n.imagePrivacy,
    children: <Widget>[
      _pixelLevelRedactionPoint(l10n),
      _PrivacyPoint(
        icon: _metadataRemovedIcon,
        title: l10n.metadataRemoved,
        body: l10n.imageMetadataRemovedBody,
      ),
      _PrivacyPoint(
        icon: _outputFormatIcon,
        title: l10n.outputFormatPoint,
        body: l10n.imageOutputFormatBody,
      ),
    ],
  );
}

void _showPdfDetails(BuildContext context) {
  final l10n = context.l10n;
  _showDetails(
    context,
    title: l10n.pdfPrivacy,
    children: <Widget>[
      _pixelLevelRedactionPoint(l10n),
      _PrivacyPoint(
        icon: Icons.layers_clear_outlined,
        title: l10n.hiddenPdfDataRemoved,
        body: l10n.hiddenPdfDataRemovedBody,
      ),
      _PrivacyPoint(
        icon: _metadataRemovedIcon,
        title: l10n.metadataRemoved,
        body: l10n.pdfMetadataRemovedBody,
      ),
      _PrivacyPoint(
        icon: Icons.picture_as_pdf_outlined,
        title: l10n.flattenRedactedPages,
        body: l10n.flattenRedactedPagesBody,
      ),
      _PrivacyPoint(
        icon: _outputFormatIcon,
        title: l10n.output,
        body: l10n.pdfOutputBody,
      ),
      _PrivacyPoint(
        icon: _noteIcon,
        iconBackgroundColor: _noteBackgroundColor,
        iconColor: _noteIconColor,
        title: l10n.tradeoff,
        body: l10n.pdfTradeoffBody,
      ),
    ],
  );
}

void _showMetadataDetails(BuildContext context) {
  final l10n = context.l10n;
  _showDetails(
    context,
    title: l10n.metadataOnlyInfo,
    children: <Widget>[
      _PrivacyPoint(
        icon: Icons.photo_library_outlined,
        title: l10n.cleanWithoutRedaction,
        body: l10n.cleanWithoutRedactionBody,
      ),
      _PrivacyPoint(
        icon: _metadataRemovedIcon,
        title: l10n.metadataRemoved,
        body: l10n.metadataOnlyRemovedBody,
      ),
      _PrivacyPoint(
        icon: _outputFormatIcon,
        title: l10n.output,
        body: l10n.metadataOnlyOutputBody,
      ),
      _PrivacyPoint(
        icon: _noteIcon,
        iconBackgroundColor: _noteBackgroundColor,
        iconColor: _noteIconColor,
        title: l10n.note,
        body: l10n.metadataOnlyNoteBody,
      ),
    ],
  );
}

const IconData _metadataRemovedIcon = Icons.cleaning_services_outlined;
const IconData _outputFormatIcon = CupertinoIcons.slider_horizontal_3;
const IconData _noteIcon = CupertinoIcons.exclamationmark_circle;
const Color _noteBackgroundColor = Color(0xFFFFF4D6);
const Color _noteIconColor = Color(0xFF9A6A00);

_PrivacyPoint _pixelLevelRedactionPoint(AppLocalizations l10n) {
  return _PrivacyPoint(
    icon: Icons.grid_on_outlined,
    title: l10n.pixelLevelRedaction,
    body: l10n.pixelLevelRedactionBody,
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _CupertinoTooltip(
                    message: context.l10n.close,
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
    this.iconColor = redactKitAccentColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, color: iconColor, size: 22);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (iconBackgroundColor case final background?)
            DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox.square(
                dimension: 30,
                child: Center(child: iconWidget),
              ),
            )
          else
            SizedBox.square(
              dimension: 30,
              child: Align(alignment: Alignment.topLeft, child: iconWidget),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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

String _metadataExportFormatDescription(
  RedactionState state,
  AppLocalizations l10n,
) {
  if (!state.hasMetadataInput) {
    return l10n.metadataExportDescriptionNoInput;
  }
  if (state.metadataHasImages && state.metadataHasPdfs) {
    return l10n.metadataExportDescriptionMixed;
  }
  if (state.metadataHasImages) {
    return l10n.metadataExportDescriptionImages;
  }
  if (state.metadataHasPdfs) {
    return l10n.metadataExportDescriptionPdfs;
  }
  return l10n.metadataExportDescriptionEmpty;
}

bool _metadataInputHasFolder(List<MetadataInputDisplayItem> items) {
  return items.any((item) => item.kind == MetadataInputDisplayKind.folder);
}

bool _metadataCanSaveToPhotos(
  RedactionState state, {
  required bool hasFolderInput,
}) {
  return state.hasMetadataInput &&
      state.metadataHasImages &&
      !state.metadataHasPdfs &&
      !hasFolderInput;
}

String _metadataChooserTitle(
  bool hasInput,
  bool hasFolderInput,
  AppLocalizations l10n,
) {
  if (hasFolderInput) return l10n.folderSelected;
  return l10n.filesOrFolder;
}

String _metadataChooserDescription(
  bool hasInput,
  bool hasFolderInput,
  AppLocalizations l10n,
) {
  if (hasFolderInput) {
    return l10n.metadataChooserFolderDisabled;
  }
  if (hasInput) {
    return l10n.metadataChooserAddMore;
  }
  return l10n.filesAndFoldersCanIncludeImagesOrPdfs;
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
    final l10n = context.l10n;
    final result = _MetadataResultSummaryData.fromStatus(
      state.statusMessage,
      l10n,
    );
    final showImageExportControls =
        state.hasMetadataInput && state.metadataHasImages;
    final showPdfExportControls =
        state.hasMetadataInput && state.metadataHasPdfs;
    final inputItems = controller.metadataInputItems;
    final hasFolderInput = _metadataInputHasFolder(inputItems);
    final openingPhotos = state.isOpening && state.statusMessage.isPhotoRelated;
    final canSaveToPhotos = _metadataCanSaveToPhotos(
      state,
      hasFolderInput: hasFolderInput,
    );
    final savingToPhotos =
        state.isExporting && state.statusMessage.isPhotosOutputRelated;

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.metadataOnly,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            l10n.metadataOnlySubtitle,
                            style: const TextStyle(
                              color: redactKitMutedTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      text: state.hasMetadataInput
                          ? l10n.selectedCount(state.metadataInputCount)
                          : l10n.noInput,
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
                            title: l10n.input,
                            icon: CupertinoIcons.tray_arrow_down,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                _MetadataInputChooserButton(
                                  title: _metadataChooserTitle(
                                    state.hasMetadataInput,
                                    hasFolderInput,
                                    l10n,
                                  ),
                                  description: _metadataChooserDescription(
                                    state.hasMetadataInput,
                                    hasFolderInput,
                                    l10n,
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
                                  title: l10n.photos,
                                  description: hasFolderInput
                                      ? l10n.removeFolderBeforeAddingPhotos
                                      : l10n.chooseImagesFromPhotos,
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
                                  emptyLabel: l10n.noInputSelected,
                                  emptyDescription:
                                      l10n.chooseFilesPhotosOrFolder,
                                  onRemove: canClean
                                      ? controller.removeMetadataInputAt
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DesktopMetadataPanel(
                            title: l10n.output,
                            icon: CupertinoIcons.folder,
                            child: _MetadataOutputFolderPicker(
                              displayName:
                                  state.metadataOutputDirectoryDisplayName ??
                                  l10n.chooseInputPreviewOutput,
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
                            title: l10n.exportFormat,
                            icon: CupertinoIcons.slider_horizontal_3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                if (!state.hasMetadataInput)
                                  Text(
                                    l10n.chooseInputShowControls,
                                    style: const TextStyle(
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
                                  label: l10n.keepFilenames,
                                  value: state.preserveMetadataCleanFileNames,
                                  onChanged: canClean
                                      ? controller
                                            .setPreserveMetadataCleanFileNames
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _metadataExportFormatDescription(state, l10n),
                                  style: const TextStyle(
                                    color: redactKitMutedTextColor,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _MetadataDestinationActions(
                            canStart: canClean && state.hasMetadataInput,
                            canSaveToPhotos: canSaveToPhotos,
                            isExporting: state.isExporting,
                            savingToPhotos: savingToPhotos,
                            onSaveToFolder: controller.startMetadataClean,
                            onSaveToPhotos:
                                controller.startMetadataCleanToPhotos,
                          ),
                          if (state.isCleaningMetadata) ...<Widget>[
                            const SizedBox(height: 14),
                            _MetadataProgressBanner(
                              progress: state.metadataCleanProgress,
                              status: state.statusMessage,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: redactKitSubtleBorderColor),
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
                    fontWeight: FontWeight.w500,
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
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: redactKitSecondaryBackgroundColor,
        borderRadius: BorderRadius.circular(12),
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
                  ? redactKitAccentFillColor
                  : redactKitDisabledFillColor,
              borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: redactKitMutedTextColor,
                    fontWeight: FontWeight.w400,
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
  final RedactionStatus message;
  final _NoticeTone tone;
  final int? savedCount;
  final int ignoredCount;
  final int failedCount;

  static _MetadataResultSummaryData? fromStatus(
    RedactionStatus status,
    AppLocalizations l10n,
  ) {
    if (status.kind == RedactionStatusKind.savedMetadataCleanPdf) {
      return _MetadataResultSummaryData(
        title: l10n.lastResult,
        message: status,
        tone: _NoticeTone.success,
        savedCount: null,
        ignoredCount: 0,
        failedCount: 0,
      );
    }

    if (status.kind == RedactionStatusKind.metadataBatchResult) {
      final saved = status.savedCount;
      final ignored = status.ignoredCount ?? 0;
      final failed = status.failedCount ?? 0;
      final tone = failed > 0 ? _NoticeTone.warning : _NoticeTone.success;

      return _MetadataResultSummaryData(
        title: failed > 0 ? l10n.lastResultNeedsReview : l10n.lastResult,
        message: status,
        tone: tone,
        savedCount: saved,
        ignoredCount: ignored,
        failedCount: failed,
      );
    }

    if (status.kind == RedactionStatusKind.couldNotCleanMetadata ||
        status.kind == RedactionStatusKind.couldNotCreateOutputFolder) {
      return _MetadataResultSummaryData(
        title: l10n.lastResultFailed,
        message: status,
        tone: _NoticeTone.error,
        savedCount: 0,
        ignoredCount: 0,
        failedCount: 1,
      );
    }

    return null;
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
        borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w500,
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
                  label: context.l10n.cleaned,
                  value: result.savedCount.toString(),
                ),
              _ResultCountPill(
                label: context.l10n.ignored,
                value: result.ignoredCount.toString(),
              ),
              _ResultCountPill(
                label: context.l10n.failed,
                value: result.failedCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _localizedStatus(result.message, context.l10n),
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
                    label: context.l10n.openFolder,
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
        borderRadius: BorderRadius.circular(12),
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
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: redactKitMutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
    final l10n = context.l10n;
    final showImageExportControls =
        state.hasMetadataInput && state.metadataHasImages;
    final showPdfExportControls =
        state.hasMetadataInput && state.metadataHasPdfs;
    final inputItems = controller.metadataInputItems;
    final hasFolderInput = _metadataInputHasFolder(inputItems);
    final openingPhotos = state.isOpening && state.statusMessage.isPhotoRelated;
    final canSaveToPhotos = _metadataCanSaveToPhotos(
      state,
      hasFolderInput: hasFolderInput,
    );
    final savingToPhotos =
        state.isExporting && state.statusMessage.isPhotosOutputRelated;

    return ColoredBox(
      color: redactKitBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.metadataOnly,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _StatusPill(
                  text: state.hasMetadataInput
                      ? l10n.selectedCount(state.metadataInputCount)
                      : l10n.noInput,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MobileMetadataSection(
              title: l10n.input,
              icon: CupertinoIcons.tray_arrow_down,
              children: <Widget>[
                _MetadataInputChooserButton(
                  title: _metadataChooserTitle(
                    state.hasMetadataInput,
                    hasFolderInput,
                    l10n,
                  ),
                  description: _metadataChooserDescription(
                    state.hasMetadataInput,
                    hasFolderInput,
                    l10n,
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
                  title: l10n.photos,
                  description: hasFolderInput
                      ? l10n.removeFolderBeforeAddingPhotos
                      : l10n.chooseImagesFromPhotos,
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
                  emptyLabel: l10n.noInputSelected,
                  emptyDescription: l10n.chooseFilesPhotosOrFolder,
                  onRemove: canClean ? controller.removeMetadataInputAt : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MobileMetadataSection(
              title: l10n.output,
              icon: CupertinoIcons.folder,
              children: <Widget>[
                _MetadataOutputFolderPicker(
                  displayName:
                      state.metadataOutputDirectoryDisplayName ??
                      l10n.outputAppCleanedFolder,
                  path: state.metadataOutputDirectoryPath,
                  onChoose: canClean && state.hasMetadataInput
                      ? controller.chooseMetadataOutputFolder
                      : null,
                  onOpen: canClean && state.metadataOutputDirectoryPath != null
                      ? controller.openMetadataOutputFolder
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MobileMetadataSection(
              title: l10n.exportFormat,
              icon: CupertinoIcons.slider_horizontal_3,
              children: <Widget>[
                if (!state.hasMetadataInput)
                  Text(
                    l10n.chooseInputShowControls,
                    style: const TextStyle(
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
                  label: l10n.keepFilenames,
                  value: state.preserveMetadataCleanFileNames,
                  onChanged: canClean
                      ? controller.setPreserveMetadataCleanFileNames
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  _metadataExportFormatDescription(state, l10n),
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
                status: state.statusMessage,
              ),
            ],
            const SizedBox(height: 14),
            _MetadataDestinationActions(
              canStart: canClean && state.hasMetadataInput,
              canSaveToPhotos: canSaveToPhotos,
              isExporting: state.isExporting,
              savingToPhotos: savingToPhotos,
              onSaveToFolder: controller.startMetadataClean,
              onSaveToPhotos: controller.startMetadataCleanToPhotos,
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
        borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w500,
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
  final RedactionStatus status;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress?.clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: redactKitSubtleBorderColor),
        color: redactKitSecondaryBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _localizedStatus(status, context.l10n),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
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
            label: _metadataInputDisplayLabel(items[index], context.l10n),
            detail: _localizedMetadataInputDetail(
              items[index].detail,
              context.l10n,
            ),
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
        borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(fontWeight: FontWeight.w500),
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

String _metadataInputDisplayLabel(
  MetadataInputDisplayItem item,
  AppLocalizations l10n,
) {
  if (item.kind != MetadataInputDisplayKind.folder) return item.label;
  return l10n.metadataSummaryFolder(item.label);
}

String _localizedMetadataInputDetail(
  MetadataInputDetail detail,
  AppLocalizations l10n,
) {
  return switch (detail.kind) {
    MetadataInputDetailKind.path => detail.path ?? detail.fallbackLabel,
    MetadataInputDetailKind.photoLibrary => l10n.metadataDetailPhotoLibrary,
    MetadataInputDetailKind.image => l10n.metadataDetailImage,
    MetadataInputDetailKind.pdf => l10n.metadataDetailPdf,
    MetadataInputDetailKind.contents => _localizedMetadataContentsDetail(
      detail,
      l10n,
    ),
  };
}

String _localizedMetadataContentsDetail(
  MetadataInputDetail detail,
  AppLocalizations l10n,
) {
  final parts = <String>[
    if (detail.imageCount > 0) l10n.metadataDetailImages(detail.imageCount),
    if (detail.pdfCount > 0) l10n.metadataDetailPdfs(detail.pdfCount),
    if (detail.ignoredCount > 0)
      l10n.metadataDetailIgnored(detail.ignoredCount),
  ];
  if (parts.isEmpty) return detail.fallbackLabel;
  return parts.join(l10n.metadataDetailSeparator);
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: redactKitSubtleBorderColor),
                color: redactKitGroupedFillColor,
              ),
              child: Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: redactKitMutedTextColor,
                  fontWeight: FontWeight.w400,
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
                  label: context.l10n.openFolder,
                  emphasis: _CupertinoControlEmphasis.outlined,
                ),
              if (onChoose != null)
                _CupertinoActionButton(
                  onPressed: onChoose,
                  icon: const Icon(Icons.drive_folder_upload_outlined),
                  label: context.l10n.chooseFolder,
                  emphasis: _CupertinoControlEmphasis.outlined,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MetadataDestinationActions extends StatelessWidget {
  const _MetadataDestinationActions({
    required this.canStart,
    required this.canSaveToPhotos,
    required this.isExporting,
    required this.savingToPhotos,
    required this.onSaveToFolder,
    required this.onSaveToPhotos,
  });

  final bool canStart;
  final bool canSaveToPhotos;
  final bool isExporting;
  final bool savingToPhotos;
  final VoidCallback onSaveToFolder;
  final VoidCallback onSaveToPhotos;

  @override
  Widget build(BuildContext context) {
    final folderButton = _CupertinoActionButton(
      onPressed: canStart ? onSaveToFolder : null,
      icon: isExporting && !savingToPhotos
          ? const SizedBox.square(
              dimension: 18,
              child: CupertinoActivityIndicator(color: Colors.white),
            )
          : const Icon(Icons.save_alt),
      label: context.l10n.saveToFiles,
      emphasis: _CupertinoControlEmphasis.filled,
    );

    if (!canSaveToPhotos) {
      return SizedBox(width: double.infinity, height: 48, child: folderButton);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: 48, child: folderButton),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: _CupertinoActionButton(
            onPressed: canStart ? onSaveToPhotos : null,
            icon: isExporting && savingToPhotos
                ? const SizedBox.square(
                    dimension: 18,
                    child: CupertinoActivityIndicator(color: Colors.white),
                  )
                : const Icon(CupertinoIcons.photo_fill_on_rectangle_fill),
            label: context.l10n.saveToPhotos,
            emphasis: _CupertinoControlEmphasis.filled,
          ),
        ),
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
                  Expanded(
                    child: Text(
                      context.l10n.fullOutput,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _CupertinoTooltip(
                    message: context.l10n.close,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (path != null && path != output) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  context.l10n.folderPath,
                  style: const TextStyle(fontWeight: FontWeight.w500),
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
                      fontWeight: FontWeight.w500,
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
                      _CompletionNotice(
                        title: context.l10n.copied,
                        message: context.l10n.outputPathCopied,
                        tone: _NoticeTone.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: context.l10n.copy,
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
    this.cropRect,
    this.onCropChanged,
    this.onCancelCrop,
    this.onApplyCrop,
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
  final Rect? cropRect;
  final ValueChanged<Rect>? onCropChanged;
  final VoidCallback? onCancelCrop;
  final VoidCallback? onApplyCrop;
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
                            label: context.l10n.photos,
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
          final cropRect = this.cropRect;
          final onCropChanged = this.onCropChanged;
          final onCancelCrop = this.onCancelCrop;
          final onApplyCrop = this.onApplyCrop;
          final hasCropControls =
              cropRect != null &&
              onCropChanged != null &&
              onCancelCrop != null &&
              onApplyCrop != null;
          final imageRect = _fitImageRect(
            image,
            size,
            bottomReserved: hasCropControls ? _cropActionReservedHeight : 0,
          );

          if (hasCropControls) {
            return _CropCanvas(
              state: state,
              image: image,
              imageRect: imageRect,
              canvasSize: size,
              redactions: redactions,
              cropRect: cropRect,
              onCropChanged: onCropChanged,
              onCancelCrop: onCancelCrop,
              onApplyCrop: onApplyCrop,
            );
          }

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

  static const double _cropActionReservedHeight = 92;

  Rect _fitImageRect(ui.Image image, Size bounds, {double bottomReserved = 0}) {
    final reservedHeight = bottomReserved
        .clamp(0.0, math.max(0.0, bounds.height * 0.28))
        .toDouble();
    final fittingHeight = math.max(1.0, bounds.height - reservedHeight);
    final available = Size(
      math.max(1, bounds.width - fitPadding * 2),
      math.max(1, fittingHeight - fitPadding * 2),
    );
    final scale = math.min(
      available.width / image.width,
      available.height / image.height,
    );
    final fitted = Size(image.width * scale, image.height * scale);

    return Rect.fromLTWH(
      (bounds.width - fitted.width) / 2,
      (fittingHeight - fitted.height) / 2,
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
                color: redactKitGroupedFillColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: redactKitSubtleBorderColor),
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
                fontWeight: FontWeight.w500,
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
                label: context.l10n.photos,
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: foreground, size: 18),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
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
  static const double _pointerZoomStep = 0.0018;

  double _scale = _minScale;
  double _gestureStartScale = _minScale;
  Offset _offset = Offset.zero;
  Offset _gestureStartOffset = Offset.zero;
  _CanvasGestureMode? _gestureMode;

  @override
  void didUpdateWidget(covariant _ZoomableRedactionCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _scale = _minScale;
      _gestureStartScale = _minScale;
      _offset = Offset.zero;
      _gestureStartOffset = Offset.zero;
      _gestureMode = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOffset = _clampOffset(_offset, _scale, widget.canvasSize);

    return Listener(
      onPointerSignal: (event) => _handlePointerSignal(event, effectiveOffset),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) {
          _gestureStartScale = _scale;
          _gestureStartOffset = effectiveOffset;

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
            }

            _setScaleAround(
              scale: _gestureStartScale * details.scale,
              focalPoint: details.localFocalPoint,
              currentOffset: _gestureStartOffset,
              currentScale: _gestureStartScale,
            );
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
      ),
    );
  }

  Offset _toCanvasPoint(Offset localPosition, Offset effectiveOffset) {
    return (localPosition - effectiveOffset) / _scale;
  }

  void _handlePointerSignal(PointerSignalEvent event, Offset effectiveOffset) {
    if (event is! PointerScrollEvent) return;

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final zooming =
        pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight) ||
        pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);

    if (zooming) {
      widget.onFinishRedaction();
      final scaleFactor = math.exp(-event.scrollDelta.dy * _pointerZoomStep);
      _setScaleAround(
        scale: _scale * scaleFactor,
        focalPoint: event.localPosition,
        currentOffset: effectiveOffset,
        currentScale: _scale,
      );
      return;
    }

    if (_scale <= _minScale) return;

    widget.onFinishRedaction();
    setState(() {
      _offset = _clampOffset(
        effectiveOffset - event.scrollDelta,
        _scale,
        widget.canvasSize,
      );
    });
  }

  void _setScaleAround({
    required double scale,
    required Offset focalPoint,
    required Offset currentOffset,
    required double currentScale,
  }) {
    final nextScale = scale.clamp(_minScale, _maxScale).toDouble();
    final focalCanvasPoint = (focalPoint - currentOffset) / currentScale;
    final nextOffset = focalPoint - focalCanvasPoint * nextScale;

    setState(() {
      _scale = nextScale;
      _offset = _clampOffset(nextOffset, nextScale, widget.canvasSize);
    });
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

enum _CropDragHandle {
  newRect,
  move,
  left,
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
}

class _CropCanvas extends StatefulWidget {
  const _CropCanvas({
    required this.state,
    required this.image,
    required this.imageRect,
    required this.canvasSize,
    required this.redactions,
    required this.cropRect,
    required this.onCropChanged,
    required this.onCancelCrop,
    required this.onApplyCrop,
  });

  final RedactionState state;
  final ui.Image image;
  final Rect imageRect;
  final Size canvasSize;
  final List<RedactionRegion> redactions;
  final Rect cropRect;
  final ValueChanged<Rect> onCropChanged;
  final VoidCallback onCancelCrop;
  final VoidCallback onApplyCrop;

  @override
  State<_CropCanvas> createState() => _CropCanvasState();
}

class _CropCanvasState extends State<_CropCanvas> {
  static const double _handleRadius = 24;

  _CropDragHandle? _dragHandle;
  Rect? _dragStartRect;
  Offset? _dragStartPoint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _RedactionPaintSurface(
          state: widget.state,
          image: widget.image,
          imageRect: widget.imageRect,
          redactions: widget.redactions,
        ),
        Positioned.fill(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: (_) => _clearDrag(),
              onPanCancel: _clearDrag,
              child: CustomPaint(
                painter: _CropOverlayPainter(
                  image: widget.image,
                  imageRect: widget.imageRect,
                  cropRect: widget.cropRect,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 18,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: redactKitSecondaryBackgroundColor.withValues(
                    alpha: 0.94,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: redactKitSubtleBorderColor),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: redactKitChromeShadowColor,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _CupertinoActionButton(
                          onPressed: widget.onCancelCrop,
                          icon: const Icon(CupertinoIcons.xmark),
                          label: context.l10n.cancelCrop,
                          emphasis: _CupertinoControlEmphasis.outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CupertinoActionButton(
                          onPressed: widget.onApplyCrop,
                          icon: const Icon(CupertinoIcons.check_mark),
                          label: context.l10n.applyCrop,
                          emphasis: _CupertinoControlEmphasis.filled,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handlePanStart(DragStartDetails details) {
    final position = details.localPosition;
    final displayCrop = _imageToDisplayRect(
      widget.cropRect,
      widget.imageRect,
      widget.image,
    );
    final hit = _hitTestHandle(displayCrop, position);
    if (hit == null && !widget.imageRect.contains(position)) return;

    final point = _displayToImagePoint(
      position,
      widget.imageRect,
      widget.image,
    );
    _dragHandle = hit ?? _CropDragHandle.newRect;
    _dragStartPoint = point;
    _dragStartRect = widget.cropRect;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final handle = _dragHandle;
    final startPoint = _dragStartPoint;
    final startRect = _dragStartRect;
    if (handle == null || startPoint == null || startRect == null) return;

    final point = _displayToImagePoint(
      details.localPosition,
      widget.imageRect,
      widget.image,
    );
    final delta = point - startPoint;
    final next = switch (handle) {
      _CropDragHandle.newRect => Rect.fromPoints(startPoint, point),
      _CropDragHandle.move => _clampMovedCropRect(
        startRect.shift(delta),
        widget.image,
      ),
      _CropDragHandle.left => Rect.fromLTRB(
        startRect.left + delta.dx,
        startRect.top,
        startRect.right,
        startRect.bottom,
      ),
      _CropDragHandle.topLeft => Rect.fromLTRB(
        startRect.left + delta.dx,
        startRect.top + delta.dy,
        startRect.right,
        startRect.bottom,
      ),
      _CropDragHandle.top => Rect.fromLTRB(
        startRect.left,
        startRect.top + delta.dy,
        startRect.right,
        startRect.bottom,
      ),
      _CropDragHandle.topRight => Rect.fromLTRB(
        startRect.left,
        startRect.top + delta.dy,
        startRect.right + delta.dx,
        startRect.bottom,
      ),
      _CropDragHandle.right => Rect.fromLTRB(
        startRect.left,
        startRect.top,
        startRect.right + delta.dx,
        startRect.bottom,
      ),
      _CropDragHandle.bottomRight => Rect.fromLTRB(
        startRect.left,
        startRect.top,
        startRect.right + delta.dx,
        startRect.bottom + delta.dy,
      ),
      _CropDragHandle.bottom => Rect.fromLTRB(
        startRect.left,
        startRect.top,
        startRect.right,
        startRect.bottom + delta.dy,
      ),
      _CropDragHandle.bottomLeft => Rect.fromLTRB(
        startRect.left + delta.dx,
        startRect.top,
        startRect.right,
        startRect.bottom + delta.dy,
      ),
    };

    widget.onCropChanged(_clampCropRectForImage(next, widget.image));
  }

  void _clearDrag() {
    _dragHandle = null;
    _dragStartRect = null;
    _dragStartPoint = null;
  }

  _CropDragHandle? _hitTestHandle(Rect rect, Offset position) {
    final corners = <_CropDragHandle, Offset>{
      _CropDragHandle.topLeft: rect.topLeft,
      _CropDragHandle.topRight: rect.topRight,
      _CropDragHandle.bottomRight: rect.bottomRight,
      _CropDragHandle.bottomLeft: rect.bottomLeft,
    };

    for (final entry in corners.entries) {
      if ((entry.value - position).distance <= _handleRadius) {
        return entry.key;
      }
    }

    final nearLeft = (position.dx - rect.left).abs() <= _handleRadius;
    final nearRight = (position.dx - rect.right).abs() <= _handleRadius;
    final nearTop = (position.dy - rect.top).abs() <= _handleRadius;
    final nearBottom = (position.dy - rect.bottom).abs() <= _handleRadius;
    final withinX = position.dx >= rect.left && position.dx <= rect.right;
    final withinY = position.dy >= rect.top && position.dy <= rect.bottom;

    if (nearLeft && withinY) return _CropDragHandle.left;
    if (nearTop && withinX) return _CropDragHandle.top;
    if (nearRight && withinY) return _CropDragHandle.right;
    if (nearBottom && withinX) return _CropDragHandle.bottom;
    if (rect.contains(position)) return _CropDragHandle.move;

    return null;
  }
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({
    required this.image,
    required this.imageRect,
    required this.cropRect,
  });

  final ui.Image image;
  final Rect imageRect;
  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final displayCrop = _imageToDisplayRect(cropRect, imageRect, image);
    final dimPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(imageRect)
      ..addRect(displayCrop);
    canvas.drawPath(dimPath, Paint()..color = const Color(0x77000000));

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 1;
    for (var index = 1; index <= 2; index += 1) {
      final dx = displayCrop.left + displayCrop.width * index / 3;
      final dy = displayCrop.top + displayCrop.height * index / 3;
      canvas.drawLine(
        Offset(dx, displayCrop.top),
        Offset(dx, displayCrop.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(displayCrop.left, dy),
        Offset(displayCrop.right, dy),
        gridPaint,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(displayCrop, const Radius.circular(8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = redactKitAccentColor,
    );

    final handlePaint = Paint()..color = redactKitAccentColor;
    for (final corner in <Offset>[
      displayCrop.topLeft,
      displayCrop.topRight,
      displayCrop.bottomRight,
      displayCrop.bottomLeft,
    ]) {
      canvas.drawCircle(corner, 6, Paint()..color = Colors.white);
      canvas.drawCircle(corner, 4, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.cropRect != cropRect;
  }
}

Rect _imageToDisplayRect(Rect imageSpaceRect, Rect imageRect, ui.Image image) {
  final scaleX = imageRect.width / image.width;
  final scaleY = imageRect.height / image.height;

  return Rect.fromLTRB(
    imageRect.left + imageSpaceRect.left * scaleX,
    imageRect.top + imageSpaceRect.top * scaleY,
    imageRect.left + imageSpaceRect.right * scaleX,
    imageRect.top + imageSpaceRect.bottom * scaleY,
  );
}

Offset _displayToImagePoint(Offset local, Rect imageRect, ui.Image image) {
  final x = ((local.dx - imageRect.left) * image.width / imageRect.width)
      .clamp(0.0, image.width.toDouble())
      .toDouble();
  final y = ((local.dy - imageRect.top) * image.height / imageRect.height)
      .clamp(0.0, image.height.toDouble())
      .toDouble();
  return Offset(x, y);
}

Rect _clampMovedCropRect(Rect rect, ui.Image image) {
  final imageWidth = math.max(1.0, image.width.toDouble());
  final imageHeight = math.max(1.0, image.height.toDouble());
  final width = math.min(rect.width, imageWidth);
  final height = math.min(rect.height, imageHeight);
  final left = rect.left
      .clamp(0.0, math.max(0.0, imageWidth - width))
      .toDouble();
  final top = rect.top
      .clamp(0.0, math.max(0.0, imageHeight - height))
      .toDouble();
  return Rect.fromLTWH(left, top, width, height);
}

Rect _clampCropRectForImage(Rect rect, ui.Image image) {
  final imageWidth = math.max(1.0, image.width.toDouble());
  final imageHeight = math.max(1.0, image.height.toDouble());
  final minSize = math.min(12.0, math.min(imageWidth, imageHeight));
  final normalized = Rect.fromLTRB(
    math.min(rect.left, rect.right),
    math.min(rect.top, rect.bottom),
    math.max(rect.left, rect.right),
    math.max(rect.top, rect.bottom),
  );

  var left = normalized.left.clamp(0.0, imageWidth).toDouble();
  var right = normalized.right.clamp(0.0, imageWidth).toDouble();
  var top = normalized.top.clamp(0.0, imageHeight).toDouble();
  var bottom = normalized.bottom.clamp(0.0, imageHeight).toDouble();

  if (right - left < minSize) {
    final centerX = ((left + right) / 2).clamp(0.0, imageWidth).toDouble();
    left = (centerX - minSize / 2)
        .clamp(0.0, math.max(0.0, imageWidth - minSize))
        .toDouble();
    right = math.min(imageWidth, left + minSize);
  }

  if (bottom - top < minSize) {
    final centerY = ((top + bottom) / 2).clamp(0.0, imageHeight).toDouble();
    top = (centerY - minSize / 2)
        .clamp(0.0, math.max(0.0, imageHeight - minSize))
        .toDouble();
    bottom = math.min(imageHeight, top + minSize);
  }

  return Rect.fromLTRB(left, top, right, bottom);
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
    required this.canCrop,
    required this.isCropping,
    required this.isOpening,
    required this.isExporting,
    required this.onOpen,
    required this.onOpenPhotos,
    required this.onUndo,
    required this.onClear,
    required this.onStartCrop,
    required this.onCancelCrop,
    required this.onExport,
    required this.onShare,
    required this.onSaveToPhotos,
    required this.onHelp,
  });

  final _WorkspaceMode mode;
  final ValueChanged<_WorkspaceMode> onModeChanged;
  final RedactionStatus status;
  final bool canUndo;
  final bool canClear;
  final bool canExport;
  final bool canCrop;
  final bool isCropping;
  final bool isOpening;
  final bool isExporting;
  final VoidCallback onOpen;
  final VoidCallback onOpenPhotos;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onStartCrop;
  final VoidCallback onCancelCrop;
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: redactKitSubtleBorderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _DesktopToolbarAction(
                      message: context.l10n.files,
                      onPressed: isOpening ? null : onOpen,
                      icon: isOpening
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CupertinoActivityIndicator(radius: 9),
                            )
                          : const Icon(Icons.folder_open),
                    ),
                    if (mode == _WorkspaceMode.redact)
                      _DesktopToolbarAction(
                        message: context.l10n.photos,
                        onPressed: isOpening ? null : onOpenPhotos,
                        icon: const Icon(Icons.photo_library_outlined),
                      ),
                    const _ToolbarDivider(),
                    _DesktopToolbarAction(
                      message: context.l10n.undo,
                      onPressed: canUndo ? onUndo : null,
                      icon: const Icon(Icons.undo),
                    ),
                    _DesktopToolbarAction(
                      message: context.l10n.clear,
                      onPressed: canClear ? onClear : null,
                      icon: const Icon(Icons.delete_outline),
                    ),
                    if (mode == _WorkspaceMode.redact)
                      _DesktopToolbarAction(
                        message: isCropping
                            ? context.l10n.cancelCrop
                            : context.l10n.crop,
                        onPressed: canCrop
                            ? isCropping
                                  ? onCancelCrop
                                  : onStartCrop
                            : null,
                        icon: const Icon(Icons.crop),
                        emphasis: isCropping
                            ? _ToolbarEmphasis.tonal
                            : _ToolbarEmphasis.plain,
                      ),
                    const _ToolbarDivider(),
                    _DesktopToolbarAction(
                      message: context.l10n.saveToFiles,
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
                        message: context.l10n.saveToPhotos,
                        onPressed: canExport ? onSaveToPhotos : null,
                        icon: const Icon(
                          CupertinoIcons.photo_fill_on_rectangle_fill,
                        ),
                        emphasis: _ToolbarEmphasis.tonal,
                      ),
                      _DesktopToolbarAction(
                        message: context.l10n.share,
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
              _WorkspaceMode.redact => context.l10n.imageDetails,
              _WorkspaceMode.pdf => context.l10n.pdfDetails,
              _WorkspaceMode.metadata => context.l10n.metadataDetails,
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
            color: redactKitGroupedFillColor,
            borderRadius: BorderRadius.circular(12),
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
        Text(
          context.l10n.appTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _DesktopStatusBadge extends StatelessWidget {
  const _DesktopStatusBadge({required this.status, required this.busy});

  final RedactionStatus status;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: redactKitGroupedFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: redactKitSubtleBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          busy
              ? context.l10n.workingStatus(
                  _localizedStatus(status, context.l10n),
                )
              : _localizedStatus(status, context.l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: redactKitMutedTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
    final l10n = context.l10n;
    final image = this.image;

    return Container(
      width: 320,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: redactKitBorderColor),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _InspectorSection(
              title: l10n.tool,
              icon: Icons.format_color_fill_outlined,
              child: Row(
                children: <Widget>[
                  _ColorSwatchButton(
                    color: const Color(0xFF050505),
                    selected: selectedColor == const Color(0xFF050505),
                    label: l10n.black,
                    onTap: () => onColorChanged(const Color(0xFF050505)),
                  ),
                  const SizedBox(width: 10),
                  _ColorSwatchButton(
                    color: Colors.white,
                    selected: selectedColor == Colors.white,
                    label: l10n.white,
                    onTap: () => onColorChanged(Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InspectorSection(
              title: l10n.image,
              icon: Icons.image_outlined,
              child: Column(
                children: <Widget>[
                  _MetricRow(
                    label: l10n.pixels,
                    value: image == null
                        ? l10n.none
                        : '${image.width} x ${image.height}',
                  ),
                  _MetricRow(label: l10n.redactions, value: '$redactionCount'),
                  _MetricRow(label: l10n.cover, value: l10n.coverOpaque),
                  _MetricRow(label: l10n.format, value: exportFormat.label),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InspectorSection(
              title: l10n.export,
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
                    label: l10n.keepFilename,
                    value: preserveRedactionExportFileName,
                    onChanged: onPreserveRedactionExportFileNameChanged,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    exportFormat == ExportFormat.png
                        ? l10n.pngLosslessExportNote
                        : l10n.jpegLossyExportNote,
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
    final l10n = context.l10n;
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: redactKitBorderColor),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _InspectorSection(
              title: l10n.tool,
              icon: Icons.format_color_fill_outlined,
              child: Row(
                children: <Widget>[
                  _ColorSwatchButton(
                    color: const Color(0xFF050505),
                    selected: selectedColor == const Color(0xFF050505),
                    label: l10n.black,
                    onTap: () => onColorChanged(const Color(0xFF050505)),
                  ),
                  const SizedBox(width: 10),
                  _ColorSwatchButton(
                    color: Colors.white,
                    selected: selectedColor == Colors.white,
                    label: l10n.white,
                    onTap: () => onColorChanged(Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InspectorSection(
              title: l10n.pdf,
              icon: Icons.picture_as_pdf_outlined,
              child: Column(
                children: <Widget>[
                  _MetricRow(
                    label: l10n.page,
                    value: state.hasPdf
                        ? '${state.pdfCurrentPage} / ${state.pdfPageCount}'
                        : l10n.none,
                  ),
                  _MetricRow(
                    label: l10n.pixels,
                    value: pageImage == null
                        ? l10n.none
                        : '${pageImage.width} x ${pageImage.height}',
                  ),
                  _MetricRow(
                    label: l10n.pageRedactions,
                    value: '${state.currentPdfRedactions.length}',
                  ),
                  _MetricRow(
                    label: l10n.totalRedactions,
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
                          label: l10n.prev,
                          emphasis: _CupertinoControlEmphasis.outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CupertinoActionButton(
                          onPressed: canMoveForward ? onNextPage : null,
                          icon: const Icon(Icons.chevron_right),
                          label: l10n.next,
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
              title: l10n.export,
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
                    label: l10n.keepFilename,
                    value: state.preservePdfExportFileName,
                    onChanged: onPreservePdfExportFileNameChanged,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.pdfFlattenExportNote,
                    style: const TextStyle(
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
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_alt),
                    label: l10n.saveRedactedPdf,
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
                  fontWeight: FontWeight.w500,
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
        title: context.l10n.imageQuality,
        selected: selected,
        onChanged: onChanged,
      );
    }

    return _ReadOnlyQualityIndicator(
      title: context.l10n.imageQuality,
      value: context.l10n.originalLossless,
      description: context.l10n.pngQualityDescription,
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
      title: context.l10n.pdfQuality,
      value: _pdfQualityLabel(selected, context.l10n),
      values: PdfQualityPreset.values,
      selected: selected,
      labelFor: (preset) => _pdfQualityLabel(preset, context.l10n),
      description: _pdfQualityDescription(selected, context.l10n),
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
      value: _jpegQualityLabel(selected, context.l10n),
      values: JpegQualityPreset.values,
      selected: selected,
      labelFor: (preset) => _jpegQualityLabel(preset, context.l10n),
      description: _jpegQualityDescription(selected, context.l10n),
      onChanged: onChanged,
    );
  }
}

String _jpegQualityLabel(JpegQualityPreset preset, AppLocalizations l10n) {
  return switch (preset) {
    JpegQualityPreset.low => l10n.low,
    JpegQualityPreset.medium => l10n.medium,
    JpegQualityPreset.high => l10n.high,
  };
}

String _jpegQualityDescription(
  JpegQualityPreset preset,
  AppLocalizations l10n,
) {
  return switch (preset) {
    JpegQualityPreset.low => l10n.jpegLowDescription,
    JpegQualityPreset.medium => l10n.jpegMediumDescription,
    JpegQualityPreset.high => l10n.jpegHighDescription,
  };
}

String _pdfQualityLabel(PdfQualityPreset preset, AppLocalizations l10n) {
  return switch (preset) {
    PdfQualityPreset.low => l10n.low,
    PdfQualityPreset.medium => l10n.medium,
    PdfQualityPreset.high => l10n.high,
  };
}

String _pdfQualityDescription(PdfQualityPreset preset, AppLocalizations l10n) {
  return switch (preset) {
    PdfQualityPreset.low => l10n.pdfLowDescription,
    PdfQualityPreset.medium => l10n.pdfMediumDescription,
    PdfQualityPreset.high => l10n.pdfHighDescription,
  };
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: redactKitGroupedFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: redactKitBorderColor),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 42,
            child: Center(
              child: Text(
                context.l10n.original,
                style: const TextStyle(fontWeight: FontWeight.w500),
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
          fontWeight: FontWeight.w500,
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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
            borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w500,
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
