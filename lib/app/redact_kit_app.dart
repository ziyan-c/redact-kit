import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      routerConfig: router,
      theme: redactKitCupertinoTheme,
    );
  }
}
