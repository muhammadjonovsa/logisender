import 'package:flutter/widgets.dart';
import 'package:logisender/core/utils/string_sanitizer.dart';

/// A Text widget that automatically sanitizes strings for valid UTF-16.
/// Use this instead of Text() for any user-generated or Telegram content.
class SafeText extends StatelessWidget {
  final String? text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;

  const SafeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.textDirection,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      StringSanitizer.sanitize(text),
      style: style,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
    );
  }
}
