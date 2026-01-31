import 'package:flutter/material.dart';

class CompDialog {
  static show({
    required BuildContext context,
    required String message,
    required DialogStyle dialogStyle,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: getDialogColor(dialogStyle),
      ),
    );
  }

  static Color getDialogColor(DialogStyle dialogStyle) {
    switch (dialogStyle) {
      case DialogStyle.error:
        return Colors.red;
      case DialogStyle.warning:
        return Colors.red;
      case DialogStyle.info:
        return Colors.red;
      case DialogStyle.success:
        return Colors.green;
    }
  }
}

enum DialogStyle { error, warning, info, success }
