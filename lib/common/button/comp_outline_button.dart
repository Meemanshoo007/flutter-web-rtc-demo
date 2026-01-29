import 'package:flutter/material.dart';
import 'package:new_flutter_firebase_webrtc/utils/sizing/app_sizing.dart';

class CompOutlineButton extends StatelessWidget {
  const CompOutlineButton({
    super.key,
    required this.onPressed,
    required this.title,
    required this.icon,
  });
  final VoidCallback? onPressed;
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
