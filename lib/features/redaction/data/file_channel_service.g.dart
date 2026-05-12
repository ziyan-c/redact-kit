// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_channel_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
    r'4889531b9b48cf2c905b094ae99f394e7de3c39a';
