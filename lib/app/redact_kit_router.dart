import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/redaction/presentation/redact_workspace.dart';

part 'redact_kit_router.g.dart';

@riverpod
GoRouter redactKitRouter(Ref ref) {
  return GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'redact',
        builder: (context, state) => const RedactWorkspace(),
      ),
    ],
  );
}
