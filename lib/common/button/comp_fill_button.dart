import 'package:flutter/material.dart';
import 'package:new_flutter_firebase_webrtc/utils/sizing/app_sizing.dart';

class CompFillButton extends StatelessWidget {
  const CompFillButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.icon,
  });
  final VoidCallback? onPressed;
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon == null ? SizedBox.shrink() : Icon(icon, size: 24),
            AppSpacing.hSm,
            Text(title),
          ],
        ),
      ),
    );
  }
}
