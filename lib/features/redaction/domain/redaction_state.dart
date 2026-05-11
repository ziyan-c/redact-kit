import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'redaction_region.dart';

part 'redaction_state.freezed.dart';

@freezed
abstract class RedactionState with _$RedactionState {
  const RedactionState._();

  const factory RedactionState({
    ui.Image? image,
    @Default('Ready') String status,
    @Default(Color(0xFF050505)) Color redactionColor,
    Offset? draftStart,
    Rect? draftRect,
    Color? draftColor,
    @Default(false) bool isOpening,
    @Default(false) bool isExporting,
    @Default(<RedactionRegion>[]) List<RedactionRegion> redactions,
  }) = _RedactionState;

  bool get hasImage => image != null;
  bool get hasRedactions => redactions.isNotEmpty;
}
