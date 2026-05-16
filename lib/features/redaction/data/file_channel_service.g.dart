// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_channel_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fileDialogText)
final fileDialogTextProvider = FileDialogTextProvider._();

final class FileDialogTextProvider
    extends $FunctionalProvider<FileDialogText, FileDialogText, FileDialogText>
    with $Provider<FileDialogText> {
  FileDialogTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileDialogTextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileDialogTextHash();

  @$internal
  @override
  $ProviderElement<FileDialogText> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileDialogText create(Ref ref) {
    return fileDialogText(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileDialogText value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileDialogText>(value),
    );
  }
}

String _$fileDialogTextHash() => r'e15a8924eed383abe68e0b6745bd497ea871d612';

@ProviderFor(fileChannelService)
final fileChannelServiceProvider = FileChannelServiceProvider._();

final class FileChannelServiceProvider
    extends
        $FunctionalProvider<
          FileChannelService,
          FileChannelService,
          FileChannelService
        >
    with $Provider<FileChannelService> {
  FileChannelServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileChannelServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileChannelServiceHash();

  @$internal
  @override
  $ProviderElement<FileChannelService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FileChannelService create(Ref ref) {
    return fileChannelService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileChannelService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileChannelService>(value),
    );
  }
}

String _$fileChannelServiceHash() =>
    r'a4a379d9e1258281f0b3fb05355159162187be2e';
