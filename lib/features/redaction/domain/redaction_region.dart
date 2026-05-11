import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'redaction_region.freezed.dart';

@freezed
abstract class RedactionRegion with _$RedactionRegion {
  const factory RedactionRegion({required Rect rect, required Color color}) =
      _RedactionRegion;
}
