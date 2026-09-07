import 'package:flutter/material.dart';

/// Item 18.3 — a response/result text that's LARGE and expressive by
/// default, and only shrinks as far as it actually needs to for long
/// content: tries [style]'s own font size first, and steps down (never
/// below [minFontSize]) until the text fits within [maxLines] at the
/// available width. Always wraps normally — this is not a single-line
/// "shrink to one row" trick, long text still spans multiple lines, just
/// at a smaller size when it has to.
///
/// A short response therefore renders at full size; a very long one
/// scales down and wraps, but never overflows or gets clipped (a
/// TextOverflow.ellipsis floor only ever triggers if [minFontSize] itself
/// still doesn't fit [maxLines], which is the same "content simply cannot
/// fit" case any fixed-size text would hit anyway).
class ResponsiveGameText extends StatelessWidget {
  const ResponsiveGameText(
    this.text, {
    super.key,
    required this.style,
    this.minFontSize = 12,
    this.maxLines = 6,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final double minFontSize;
  final int maxLines;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final baseSize = style.fontSize ?? 16;
        var fontSize = baseSize;

        if (maxWidth.isFinite && text.isNotEmpty) {
          while (fontSize > minFontSize) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: style.copyWith(fontSize: fontSize)),
              maxLines: maxLines,
              textDirection: direction,
              textAlign: textAlign,
            )..layout(maxWidth: maxWidth);
            if (!painter.didExceedMaxLines) break;
            fontSize -= 1;
          }
        }

        return Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(fontSize: fontSize),
        );
      },
    );
  }
}
