/// Sanitizes strings for safe display in Flutter Text widgets.
///
/// Flutter's Text widget requires valid UTF-16 strings. Telegram messages
/// may contain invalid Unicode sequences (broken surrogate pairs, etc.)
/// that crash the rendering engine.
class StringSanitizer {
  /// Sanitizes a string for safe display in Flutter widgets.
  /// Replaces invalid UTF-16 sequences with the replacement character.
  static String sanitize(String? text) {
    if (text == null) return '';
    if (text.isEmpty) return '';

    try {
      final buffer = StringBuffer();
      for (int i = 0; i < text.length; i++) {
        final code = text.codeUnitAt(i);

        // Check for unpaired surrogates
        if (code >= 0xD800 && code <= 0xDBFF) {
          // High surrogate — check if followed by low surrogate
          if (i + 1 < text.length) {
            final nextCode = text.codeUnitAt(i + 1);
            if (nextCode >= 0xDC00 && nextCode <= 0xDFFF) {
              // Valid surrogate pair
              buffer.write(text[i]);
              buffer.write(text[i + 1]);
              i++;
              continue;
            }
          }
          // Unpaired high surrogate — replace
          buffer.write('\uFFFD');
        } else if (code >= 0xDC00 && code <= 0xDFFF) {
          // Unpaired low surrogate — replace
          buffer.write('\uFFFD');
        } else if (code == 0xFFFD || code > 0x10FFFF) {
          // Already replacement char or out of range
          buffer.write('\uFFFD');
        } else {
          buffer.write(text[i]);
        }
      }
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }
}
