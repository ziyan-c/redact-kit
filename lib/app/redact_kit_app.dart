import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/redaction/data/file_channel_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'platform_style.dart';
import 'redact_kit_router.dart';

class RedactKitApp extends ConsumerWidget {
  const RedactKitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(redactKitRouterProvider);

    return CupertinoApp.router(
      title: 'Redact Kit',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      theme: redactKitCupertinoTheme,
      builder: (context, child) {
        final l10n = AppLocalizations.of(context);
        return ProviderScope(
          overrides: [
            fileDialogTextProvider.overrideWithValue(
              FileDialogText(
                openButtonText: l10n.fileDialogOpen,
                chooseButtonText: l10n.fileDialogChoose,
                chooseFilesButtonText: l10n.fileDialogChooseFiles,
                chooseFolderButtonText: l10n.fileDialogChooseFolder,
                saveButtonText: l10n.fileDialogSave,
                shareCleanImageTitle: l10n.shareCleanImageTitle,
                shareCleanPdfTitle: l10n.shareCleanPdfTitle,
                openFoldersUnsupportedMessage:
                    l10n.openFoldersUnsupportedMessage,
              ),
            ),
          ],
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
