import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_theme.dart';

/// Renders AI-generated text with proper markdown formatting (bold headers,
/// bullet points, etc.) instead of showing raw "**text**" and "# Heading"
/// syntax literally. Use this anywhere Claude's response text is displayed.
class AiMarkdownText extends StatelessWidget {
  final String data;
  const AiMarkdownText({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;

    return MarkdownBody(
      data: data,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 15, height: 1.5, color: textColor),
        h1: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: textColor, height: 2),
        h2: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor, height: 1.8),
        h3: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor, height: 1.6),
        strong: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
        listBullet: TextStyle(fontSize: 15, color: textColor),
        listIndent: 20,
      ),
    );
  }
}
