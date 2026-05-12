// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redaction_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RedactionController)
final redactionControllerProvider = RedactionControllerProvider._();

final class RedactionControllerProvider
    extends $NotifierProvider<RedactionController, RedactionState> {
  RedactionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'redactionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$redactionControllerHash();

  @$internal
  @override
  RedactionController create() => RedactionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RedactionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RedactionState>(value),
    );
  }
}

String _$redactionControllerHash() =>
    r'13baded334d87a3553f0b849c3bc811baf80e476';

abstract class _$RedactionController extends $Notifier<RedactionState> {
  RedactionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RedactionState, RedactionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RedactionState, RedactionState>,
              RedactionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
