import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Non-deprecated alternative to withOpacity()
  /// Uses withValues(alpha:) for better color manipulation
  Color withOpacitySafe(double opacity) {
    return withValues(alpha: opacity.clamp(0.0, 1.0));
  }
}

/// Parses a hex color string (e.g. '#FF3B30') into a [Color].
/// Returns [fallback] if parsing fails or [hexColor] is null.
Color parseHexColor(String? hexColor, Color fallback) {
  if (hexColor == null || hexColor.isEmpty) return fallback;
  final parsed = int.tryParse(hexColor.replaceFirst('#', '0xFF'));
  return parsed != null ? Color(parsed) : fallback;
}
