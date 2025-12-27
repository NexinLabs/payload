import 'package:flutter/material.dart';

class EditorUtils {
  static void handleAutoClosing(
    TextEditingController controller,
    String val,
    bool enabled,
  ) {
    if (!enabled) return;

    final selection = controller.selection;
    if (selection.start < 1) return;

    final lastChar = val[selection.start - 1];
    String? closingChar;

    if (lastChar == '{') closingChar = '}';
    if (lastChar == '[') closingChar = ']';
    if (lastChar == '"') closingChar = '"';
    if (lastChar == "'") closingChar = "'";

    if (closingChar != null) {
      final text = controller.text;
      final newText = text.replaceRange(
        selection.start,
        selection.start,
        closingChar,
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
  }
}
