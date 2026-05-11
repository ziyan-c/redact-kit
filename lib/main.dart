import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/redact_kit_app.dart';

void main() {
  runApp(const ProviderScope(child: RedactKitApp()));
}
