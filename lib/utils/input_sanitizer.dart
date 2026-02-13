/// Input sanitization utilities for security
class InputSanitizer {
  /// Sanitizes text input to prevent XSS and injection attacks
  /// - Removes HTML tags
  /// - Removes HTML entities
  /// - Removes potentially dangerous characters
  static String sanitizeText(String input) {
    if (input.isEmpty) return input;

    // Remove control characters and zero-width chars
    var sanitized = input
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '')
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // Remove HTML tags - multiple passes for nested/malformed tags
    for (var i = 0; i < 3; i++) {
      sanitized =
          sanitized.replaceAll(RegExp(r'<[^>]*>?', caseSensitive: false), '');
    }

    // Remove HTML entities
    sanitized = sanitized.replaceAll(RegExp(r'&[#\w]+;?'), '');

    // Remove XSS patterns (case-insensitive)
    final xssPatterns = [
      r'javascript\s*:',
      r'data\s*:',
      r'vbscript\s*:',
      r'on\w+\s*=',
    ];
    for (final pattern in xssPatterns) {
      sanitized =
          sanitized.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }

    // Remove excessive whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    return sanitized.trim();
  }

  /// Validates and sanitizes a name field
  static String sanitizeName(String name, {int maxLength = 100}) {
    if (name.isEmpty) return name;

    final sanitized = sanitizeText(name);

    // Enforce maximum length
    final truncated = sanitized.length > maxLength
        ? sanitized.substring(0, maxLength)
        : sanitized;

    // Ensure name isn't just numbers or special chars
    if (RegExp(r'^[0-9\W_]+$').hasMatch(truncated)) {
      return 'Untitled';
    }

    // Remove leading special chars except for display names
    return truncated.replaceAll(RegExp(r'^[^a-zA-Z0-9\s]+'), '');
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
