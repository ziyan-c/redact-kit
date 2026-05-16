// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Redact Kit';

  @override
  String get ready => '就绪';

  @override
  String get fileDialogOpen => '打开';

  @override
  String get fileDialogChoose => '选择';

  @override
  String get fileDialogChooseFiles => '选择文件';

  @override
  String get fileDialogChooseFolder => '选择文件夹';

  @override
  String get fileDialogSave => '保存';

  @override
  String get shareCleanImageTitle => '分享清理后的图片';

  @override
  String get shareCleanPdfTitle => '分享清理后的 PDF';

  @override
  String get openFoldersUnsupportedMessage => '只有 macOS 可以打开输出文件夹。';

  @override
  String workingStatus(Object status) {
    return '处理中：$status';
  }

  @override
  String get image => '图片';

  @override
  String get pdf => 'PDF';

  @override
  String get metadata => '元数据';

  @override
  String get imageDetails => '图片说明';

  @override
  String get pdfDetails => 'PDF 说明';

  @override
  String get metadataDetails => '元数据说明';

  @override
  String get settings => '设置';

  @override
  String get files => '文件';

  @override
  String get photos => '照片';

  @override
  String get undo => '撤销';

  @override
  String get clear => '清除';

  @override
  String get export => '导出';

  @override
  String get save => '保存';

  @override
  String get share => '分享';

  @override
  String get saveToFiles => '保存到文件';

  @override
  String get saveToPhotos => '保存到照片';

  @override
  String get input => '输入';

  @override
  String get output => '输出';

  @override
  String get exportFormat => '导出格式';

  @override
  String get chooseImage => '选择图片';

  @override
  String get choosePdf => '选择 PDF';

  @override
  String get chooseFilesOrFolder => '选择文件或文件夹';

  @override
  String get filesAndFoldersCanIncludeImagesOrPdfs => '文件和文件夹可包含图片或 PDF。';

  @override
  String get choosePhotos => '选择照片';

  @override
  String get chooseImagesFromPhotos => '从照片中选择图片。';

  @override
  String get removeFolderBeforeAddingPhotos => '先移除文件夹，再添加照片。';

  @override
  String get noInput => '无输入';

  @override
  String get noInputSelected => '尚未选择输入';

  @override
  String get chooseFilesPhotosOrFolder => '选择文件、照片，或包含图片和 PDF 的文件夹。';

  @override
  String get metadataOnly => '仅清理元数据';

  @override
  String get metadataOnlySubtitle => '清理图片或 PDF 的隐藏元数据，不绘制遮盖框。';

  @override
  String selectedCount(int count) {
    return '已选择 $count 个';
  }

  @override
  String get chooseInputPreviewOutput => '选择输入后预览输出';

  @override
  String get outputAppCleanedFolder => '输出：App 的 Cleaned 文件夹';

  @override
  String get chooseInputShowControls => '选择输入后显示对应的导出控制项。';

  @override
  String get keepFilenames => '保留文件名';

  @override
  String get keepFilename => '保留文件名';

  @override
  String get openFolder => '打开文件夹';

  @override
  String get chooseFolder => '选择文件夹';

  @override
  String get fullOutput => '完整输出';

  @override
  String get folderPath => '文件夹路径';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get outputPathCopied => '输出路径已复制。';

  @override
  String get lastResult => '上次结果';

  @override
  String get lastResultNeedsReview => '上次结果：需检查';

  @override
  String get lastResultFailed => '上次结果：失败';

  @override
  String get lastResultSavedMetadataPdf => '已保存清理后的 PDF';

  @override
  String get cleaned => '已清理';

  @override
  String get ignored => '已忽略';

  @override
  String get failed => '失败';

  @override
  String get tool => '工具';

  @override
  String get black => '黑色';

  @override
  String get white => '白色';

  @override
  String get pixels => '像素';

  @override
  String get none => '无';

  @override
  String get redactions => '遮盖';

  @override
  String get cover => '覆盖';

  @override
  String get format => '格式';

  @override
  String get pages => '页数';

  @override
  String get page => '页码';

  @override
  String get currentPage => '当前页';

  @override
  String get pageRedactions => '本页遮盖';

  @override
  String get totalRedactions => '总遮盖数';

  @override
  String get prev => '上一页';

  @override
  String get next => '下一页';

  @override
  String get pagePlaceholder => '页码';

  @override
  String get saveRedactedPdf => '保存遮盖后的 PDF';

  @override
  String get pdfExport => 'PDF 导出';

  @override
  String get close => '关闭';

  @override
  String get details => '说明';

  @override
  String get imagePrivacy => '图片隐私';

  @override
  String get pdfPrivacy => 'PDF 隐私';

  @override
  String get metadataOnlyInfo => '仅清理元数据';

  @override
  String get pixelLevelRedaction => '像素级遮盖';

  @override
  String get pixelLevelRedactionBody =>
      '遮盖框会烧进导出的像素里，不会留下可编辑图层，也不会在遮盖区域下面保留隐藏内容。';

  @override
  String get metadataRemoved => '移除元数据';

  @override
  String get imageMetadataRemovedBody =>
      '导出会移除 EXIF、GPS、相机信息、缩略图、XMP/IPTC、注释和其他隐藏图片元数据。';

  @override
  String get outputFormatPoint => '输出格式';

  @override
  String get imageOutputFormatBody =>
      'PNG 为无损格式。JPEG 文件更小，但边缘可能略微变软。两者都会写成不含原始元数据的新文件。';

  @override
  String get hiddenPdfDataRemoved => '移除隐藏 PDF 数据';

  @override
  String get hiddenPdfDataRemovedBody => '导出会丢弃原始文字层、批注、表单、链接、附件、OCR 文本和文档元数据。';

  @override
  String get pdfMetadataRemovedBody =>
      '清理后的 PDF 不保留原始标题、作者、创建工具、生成工具、日期、关键词、trailer ID 或 XMP 元数据。';

  @override
  String get flattenRedactedPages => '扁平化遮盖页面';

  @override
  String get flattenRedactedPagesBody =>
      '每一页都会先渲染成图片，遮盖框烧进去后，再按原始页面尺寸生成新的 PDF。';

  @override
  String get pdfOutputBody => '导出的 PDF 会保留原始页面尺寸，并使用你选择的 PDF 质量设置。';

  @override
  String get tradeoff => '取舍';

  @override
  String get pdfTradeoffBody => '扁平化 PDF 更容易验证安全性，但文字将不能再选择或搜索。';

  @override
  String get cleanWithoutRedaction => '不遮盖，只清理';

  @override
  String get cleanWithoutRedactionBody =>
      '选择图片、PDF、照片或一个文件夹。这个模式只移除隐藏元数据，不绘制遮盖框。';

  @override
  String get metadataOnlyRemovedBody =>
      '图片会移除 EXIF、GPS、相机信息、缩略图、XMP/IPTC 和注释。PDF 会重建为不含原始文档元数据和隐藏结构的新文件。';

  @override
  String get metadataOnlyOutputBody =>
      '可保存到 App 的 Cleaned 文件夹、选择其他文件夹，或将纯图片结果保存到照片。';

  @override
  String get note => '注意';

  @override
  String get metadataOnlyNoteBody =>
      '仅清理元数据不会隐藏可见文字或像素。如果页面上能直接看到隐私内容，请使用图片或 PDF 模式。';

  @override
  String get metadataExportDescriptionNoInput => '先选择文件或文件夹。导出控制项会根据输入类型自动显示。';

  @override
  String get metadataExportDescriptionMixed =>
      '图片使用图片格式和质量设置。PDF 会按 PDF 质量设置扁平化。';

  @override
  String get metadataExportDescriptionImages => '图片会使用所选 PNG/JPEG 格式和图片质量。';

  @override
  String get metadataExportDescriptionPdfs => 'PDF 会按所选 PDF 质量扁平化。';

  @override
  String get metadataExportDescriptionEmpty => '未选择支持的文件。';

  @override
  String get folderSelected => '已选择文件夹';

  @override
  String get filesOrFolder => '文件或文件夹';

  @override
  String get metadataChooserFolderDisabled => '移除文件夹后才能选择文件或其他文件夹。';

  @override
  String get metadataChooserAddMore => '继续添加图片或 PDF 到列表。';

  @override
  String get imageQuality => '图片质量';

  @override
  String get pdfQuality => 'PDF 质量';

  @override
  String get originalLossless => '原始无损';

  @override
  String get pngQualityDescription => 'PNG 会保留可见像素的无损效果，并移除元数据。';

  @override
  String get original => '原始';

  @override
  String get low => '低';

  @override
  String get medium => '中';

  @override
  String get high => '高';

  @override
  String get jpegLowDescription => '文件最小，压缩痕迹更明显。';

  @override
  String get jpegMediumDescription => '文件大小和图片质量较均衡。';

  @override
  String get jpegHighDescription => '文件更大，画面更清晰。';

  @override
  String get pdfLowDescription => 'PDF 最小，页面图片更柔和。';

  @override
  String get pdfMediumDescription => '清晰度和文件大小较均衡。';

  @override
  String get pdfHighDescription => '页面更清晰，扁平化 PDF 更大。';

  @override
  String get pngLosslessExportNote => 'PNG 为无损格式。导出文件会从可见像素重新生成。';

  @override
  String get jpegLossyExportNote => 'JPEG 为有损格式。较低质量会让文件更小。';

  @override
  String get pdfFlattenExportNote => 'PDF 会扁平化为页面图片。遮盖导出会移除原始 PDF 元数据和隐藏文档结构。';

  @override
  String get cleanImageExported => '图片已导出';

  @override
  String get redactionsBurnedMetadataRemoved => '遮盖已烧进像素，元数据已移除。';

  @override
  String get savedToPhotos => '已保存到照片';

  @override
  String get cleanImageReadyInPhotos => '清理后的图片已保存到照片图库。';

  @override
  String get readyToShare => '可以分享';

  @override
  String get cleanCopyPreparedForSharing => '已准备好可分享的清理副本。';

  @override
  String get pdfCleaned => 'PDF 已清理';

  @override
  String get flattenedPdfSavedWithoutOriginalMetadata => '已保存不含原始元数据的扁平化 PDF。';

  @override
  String get cleanImageSavedWithoutMetadata => '已保存不含隐私元数据的图片副本。';

  @override
  String get cleanPdfExported => 'PDF 已导出';

  @override
  String get pagesFlattenedPdfMetadataRemoved => '页面已扁平化，PDF 元数据已移除。';

  @override
  String get metadataCleaned => '元数据已清理';

  @override
  String get cleanCopiesSavedToOutputFolder => '清理副本已保存到输出文件夹。';

  @override
  String get metadataCleanedWithNotes => '元数据已清理，有注意项';

  @override
  String get someFilesNeedAttention => '部分文件需要检查，请查看状态文字。';

  @override
  String get couldNotFinish => '未能完成';

  @override
  String redactionCountReady(int count) {
    return '已准备 $count 个遮盖';
  }

  @override
  String redactionCountShort(int count) {
    return '$count 个遮盖';
  }

  @override
  String onPageCount(int count) {
    return '本页 $count 个';
  }

  @override
  String get inputSelected => '已选择输入';

  @override
  String get coverOpaque => '100% 不透明';

  @override
  String metadataSummaryFolder(Object name) {
    return '文件夹：$name';
  }

  @override
  String metadataSummaryImages(int count) {
    return '$count 张图片';
  }

  @override
  String metadataSummaryPhotos(int count) {
    return '$count 张照片';
  }

  @override
  String metadataSummaryPdfs(int count) {
    return '$count 个 PDF';
  }

  @override
  String metadataSummaryFiles(int count) {
    return '$count 个文件';
  }

  @override
  String get metadataDetailPhotoLibrary => '照片图库';

  @override
  String get metadataDetailImage => '图片';

  @override
  String get metadataDetailPdf => 'PDF';

  @override
  String metadataDetailImages(int count) {
    return '$count 张图片';
  }

  @override
  String metadataDetailPdfs(int count) {
    return '$count 个 PDF';
  }

  @override
  String metadataDetailIgnored(int count) {
    return '$count 个已忽略';
  }

  @override
  String get metadataDetailSeparator => '，';

  @override
  String get statusOpeningImage => '正在打开图片';

  @override
  String get statusOpeningPhotoLibrary => '正在打开照片图库';

  @override
  String get statusOpeningPdf => '正在打开 PDF';

  @override
  String statusLoadedImage(int width, int height) {
    return '已载入 $width x ${height}px';
  }

  @override
  String statusPdfPage(int pageNumber, int pageCount) {
    return 'PDF 第 $pageNumber / $pageCount 页';
  }

  @override
  String statusRenderingPdfPage(int pageNumber) {
    return '正在渲染 PDF 第 $pageNumber 页';
  }

  @override
  String get statusFlatteningCleanPdf => '正在扁平化 PDF';

  @override
  String statusFlatteningPdfPage(int pageNumber, int pageCount) {
    return '正在扁平化 PDF 第 $pageNumber / $pageCount 页';
  }

  @override
  String get statusChoosingPdf => '正在选择 PDF';

  @override
  String get statusChoosingFilesOrFolder => '正在选择文件或文件夹';

  @override
  String get statusChoosingImageFile => '正在选择图片文件';

  @override
  String get statusChoosingImageFiles => '正在选择图片文件';

  @override
  String get statusChoosingPdfFile => '正在选择 PDF 文件';

  @override
  String get statusChoosingPdfFiles => '正在选择 PDF 文件';

  @override
  String get statusChoosingFolder => '正在选择文件夹';

  @override
  String get statusChoosingImagesFromPhotos => '正在从照片中选择图片';

  @override
  String get statusChoosingOutputFolder => '正在选择输出文件夹';

  @override
  String get statusAddingFiles => '正在添加文件';

  @override
  String get statusAddingPhotos => '正在添加照片';

  @override
  String statusSelectedMetadataInput(Object label) {
    return '已选择 $label';
  }

  @override
  String statusRemovedMetadataInput(Object label) {
    return '已移除 $label';
  }

  @override
  String get statusNoSupportedImagesOrPdfsSelected => '未选择支持的图片或 PDF';

  @override
  String get statusNoSupportedImagesOrPdfsFoundInFolder => '该文件夹中没有支持的图片或 PDF';

  @override
  String get statusNoPhotosSelected => '未选择照片';

  @override
  String get statusRemoveFolderBeforeAddingPhotos => '先移除文件夹，再添加照片';

  @override
  String get statusChooseMetadataInputFirst => '请先选择要清理的输入';

  @override
  String get statusMetadataOutputFolderSet => '已设置元数据输出文件夹';

  @override
  String get statusStartCleaningFirstToCreateOutputFolder =>
      '先开始清理，创建输出文件夹后才能打开';

  @override
  String get statusOpenedOutputFolder => '已打开输出文件夹';

  @override
  String statusEncodingCleanImage(Object format) {
    return '正在编码清理后的 $format';
  }

  @override
  String statusRemovingImageMetadata(Object format) {
    return '正在移除 $format 元数据';
  }

  @override
  String statusPreparingCleanImageToShare(Object format) {
    return '正在准备分享清理后的 $format';
  }

  @override
  String statusSavingCleanImageToPhotos(Object format) {
    return '正在保存清理后的 $format 到照片';
  }

  @override
  String statusExportedCleanImage(Object format) {
    return '已导出清理后的 $format';
  }

  @override
  String statusExportedCleanImageWithRedactions(Object format, int count) {
    return '已导出清理后的 $format，包含 $count 个遮盖';
  }

  @override
  String statusSavedCleanImageToPhotos(Object format) {
    return '已保存清理后的 $format 到照片';
  }

  @override
  String statusSharedCleanImage(Object format) {
    return '已准备分享清理后的 $format';
  }

  @override
  String statusSavedMetadataCleanImage(Object format) {
    return '已保存清理元数据后的 $format';
  }

  @override
  String get statusCleaningPdfMetadata => '正在清理 PDF 元数据';

  @override
  String get statusSavedMetadataCleanPdf => '已保存清理后的 PDF';

  @override
  String get statusExportedCleanPdf => '已导出清理后的 PDF';

  @override
  String statusExportedCleanPdfWithRedactions(int count) {
    return '已导出清理后的 PDF，包含 $count 个遮盖';
  }

  @override
  String get statusExportCanceled => '导出已取消';

  @override
  String get statusMetadataRemovalCanceled => '元数据清理已取消';

  @override
  String get statusPdfExportCanceled => 'PDF 导出已取消';

  @override
  String get statusPdfCleanCanceled => 'PDF 清理已取消';

  @override
  String get statusShareCanceled => '分享已取消';

  @override
  String get statusSaveCanceled => '保存已取消';

  @override
  String get statusStartingMetadataClean => '正在开始清理元数据';

  @override
  String get statusPreparingOutputFolder => '正在准备输出文件夹';

  @override
  String get statusStartingMetadataCleanToPhotos => '正在清理并保存到照片';

  @override
  String get statusPhotosOutputImagesOnly => '保存到照片仅适用于图片文件';

  @override
  String statusCleaningMetadataItem(Object label, int current, int total) {
    return '正在清理 $label（$current/$total）';
  }

  @override
  String statusCleaningMetadataPdfPage(
    Object label,
    int pageNumber,
    int pageCount,
    int current,
    int total,
  ) {
    return '正在清理 $label 第 $pageNumber / $pageCount 页（$current/$total）';
  }

  @override
  String statusSavingMetadataItemToPhotos(
    Object label,
    int current,
    int total,
  ) {
    return '正在保存 $label 到照片（$current/$total）';
  }

  @override
  String statusMetadataBatchNoSaved(Object details) {
    return '未能清理所选文件$details';
  }

  @override
  String statusMetadataBatchCompleted(
    int savedCount,
    Object destinationName,
    Object details,
  ) {
    return '已清理 $savedCount 个文件到 $destinationName$details';
  }

  @override
  String statusMetadataBatchIgnoredDetail(int count) {
    return '$count 个已忽略';
  }

  @override
  String statusMetadataBatchFailedDetail(int count) {
    return '$count 个失败';
  }

  @override
  String statusMetadataBatchFailedWithReasonDetail(int count, Object reason) {
    return '$count 个失败：$reason';
  }

  @override
  String statusMetadataBatchDetailsWrapper(Object details) {
    return '（$details）';
  }

  @override
  String get statusMetadataBatchDetailSeparator => '，';

  @override
  String get statusRedactionsCleared => '遮盖已清除';

  @override
  String get statusPdfPageRedactionsCleared => '本页 PDF 遮盖已清除';

  @override
  String statusPdfRedactionCountReady(int pageNumber, int count) {
    return 'PDF 第 $pageNumber 页：已准备 $count 个遮盖';
  }

  @override
  String get statusCouldNotOpenPdf => '无法打开 PDF';

  @override
  String get statusCouldNotOpenImage => '无法打开图片';

  @override
  String get statusCouldNotDecodeImage => '无法解码这张图片';

  @override
  String get statusCouldNotExportImage => '无法导出图片';

  @override
  String get statusCouldNotExportPdf => '无法导出 PDF';

  @override
  String get statusCouldNotChooseMetadataInput => '无法选择元数据输入';

  @override
  String get statusCouldNotAddMetadataFiles => '无法添加元数据文件';

  @override
  String get statusCouldNotAddPhotos => '无法添加照片';

  @override
  String get statusCouldNotChooseOutputFolder => '无法选择输出文件夹';

  @override
  String get statusCouldNotOpenOutputFolder => '无法打开输出文件夹';

  @override
  String get statusCouldNotCleanMetadata => '无法清理元数据';

  @override
  String get statusCouldNotCreateOutputFolder => '无法创建输出文件夹';

  @override
  String statusCouldNotCreateOutputFolderAutomatic(Object path) {
    return '无法创建输出文件夹：macOS 沙盒不允许计划输出位置。请在输出里选择或创建 $path。';
  }

  @override
  String statusCouldNotCreateOutputFolderPath(Object path) {
    return '无法创建输出文件夹：$path。请选择其他输出文件夹。';
  }

  @override
  String get statusCouldNotRenderPdfPage => '无法渲染 PDF 页面';

  @override
  String statusFailureWithDetail(Object title, Object detail) {
    return '$title：$detail';
  }
}
