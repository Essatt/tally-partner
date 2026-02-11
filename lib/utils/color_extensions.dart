import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Non-deprecated alternative to withOpacity()
  /// Uses withValues(alpha:) for better color manipulation
  Color withOpacitySafe(double opacity) {
    return withValues(alpha: opacity.clamp(0.0, 1.0));
  }
}
