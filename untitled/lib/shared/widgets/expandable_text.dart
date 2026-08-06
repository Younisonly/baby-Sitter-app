import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final TextAlign? textAlign;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
    this.textAlign,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;
  bool _isOverflowing = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, size) {
      final textSpan = TextSpan(
        text: widget.text,
        style: widget.style ?? AppTextStyles.bodyMedium(color: context.textSecondaryColor),
      );
      final tp = TextPainter(
        text: textSpan,
        maxLines: widget.maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.maxWidth);

      if (tp.didExceedMaxLines) {
        _isOverflowing = true;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: widget.style ?? AppTextStyles.bodyMedium(color: context.textSecondaryColor),
            maxLines: _isExpanded ? null : widget.maxLines,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
            textAlign: widget.textAlign,
          ),
          if (_isOverflowing)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _isExpanded ? 'Show less' : 'Show more',
                  style: AppTextStyles.labelMedium(color: context.primaryColor).copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
