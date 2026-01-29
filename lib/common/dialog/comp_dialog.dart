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
        // TODO: Handle this case.
        return Colors.red;
      case DialogStyle.warning:
        // TODO: Handle this case.
        return Colors.red;
      case DialogStyle.info:
        // TODO: Handle this case.
        return Colors.red;
      case DialogStyle.success:
        // TODO: Handle this case.
        return Colors.green;
    }
  }
}

enum DialogStyle { error, warning, info, success }
