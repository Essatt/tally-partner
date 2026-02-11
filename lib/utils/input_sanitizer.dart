/// Input sanitization utilities for security
class InputSanitizer {
  /// Sanitizes text input to prevent XSS and injection attacks
  /// - Removes HTML tags
  /// - Removes HTML entities
  /// - Removes potentially dangerous characters
  static String sanitizeText(String input) {
    if (input.isEmpty) return input;

    // Remove HTML tags
    var sanitized = input.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');

    // Remove common XSS patterns
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');

    // Remove excessive whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Trim
    return sanitized.trim();
  }

  /// Validates and sanitizes a name field
  static String sanitizeName(String name) {
    if (name.isEmpty) return name;

    final sanitized = sanitizeText(name);

    // Ensure name isn't just numbers or special chars
    if (RegExp(r'^[0-9\W_]+$').hasMatch(sanitized)) {
      return 'Untitled'; // Fallback for invalid names
    }

    // Remove leading/trailing special chars except for display names
    return sanitized.replaceAll(RegExp(r'^[^a-zA-Z0-9\s]+'), '');
  }

  /// Validates a monetary value input
  static double? sanitizeMonetaryValue(String input) {
    if (input.isEmpty) return null;

    // Remove currency symbols and commas
    final cleaned = input.replaceAll(RegExp(r'[\$,\s]'), '');

    final value = double.tryParse(cleaned);

    // Ensure value is reasonable (0 to 10 million)
    if (value == null || value.isNaN || value.isInfinite) {
      return null;
    }

    if (value < 0 || value > 10000000) {
      return null;
    }

    return value;
  }
}
