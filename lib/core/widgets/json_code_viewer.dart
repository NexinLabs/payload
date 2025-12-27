import 'package:flutter/material.dart';

class JsonCodeViewer extends StatelessWidget {
  final String json;
  final bool showLineNumbers;

  const JsonCodeViewer({
    super.key,
    required this.json,
    this.showLineNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
    final lines = json.split('\n');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D121C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLineNumbers)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF111722),
                  border: Border(
                    right: BorderSide(color: Color(0xFF1E293B), width: 1),
                  ),
                ),
                child: Column(
                  children: List.generate(
                    lines.length,
                    (index) => Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText.rich(
                    _highlightJson(json),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _highlightJson(String json) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(
      r'("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)',
      multiLine: true,
    );

    int lastIndex = 0;
    for (final Match match in regExp.allMatches(json)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: json.substring(lastIndex, match.start),
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        );
      }

      final String matchText = match.group(0)!;

      if (matchText.startsWith('"')) {
        if (matchText.endsWith(':')) {
          // Key
          spans.add(
            TextSpan(
              text: matchText.substring(0, matchText.length - 1),
              style: const TextStyle(color: Color(0xFFF9CB8B)),
            ),
          );
          spans.add(
            const TextSpan(
              text: ':',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          );
        } else {
          // String value
          spans.add(
            TextSpan(
              text: matchText,
              style: const TextStyle(color: Color(0xFF7EE787)),
            ),
          );
        }
      } else if (matchText == 'true' || matchText == 'false') {
        spans.add(
          TextSpan(
            text: matchText,
            style: const TextStyle(
              color: Color(0xFF79C0FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (matchText == 'null') {
        spans.add(
          TextSpan(
            text: matchText,
            style: const TextStyle(
              color: Color(0xFFD2A8FF),
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else {
        // Number
        spans.add(
          TextSpan(
            text: matchText,
            style: const TextStyle(color: Color(0xFFF78C6C)),
          ),
        );
      }

      lastIndex = match.end;
    }

    if (lastIndex < json.length) {
      spans.add(
        TextSpan(
          text: json.substring(lastIndex),
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return TextSpan(children: spans);
  }
}
