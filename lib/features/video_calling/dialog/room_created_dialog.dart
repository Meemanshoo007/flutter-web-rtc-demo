import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_flutter_firebase_webrtc/common/dialog/comp_dialog.dart';
import 'package:new_flutter_firebase_webrtc/utils/constants/sizes.dart';
import 'package:new_flutter_firebase_webrtc/utils/sizing/app_sizing.dart';
import 'package:new_flutter_firebase_webrtc/utils/theme/controller/theme_controller.dart';
import 'package:provider/provider.dart';

class RoomCreatedDialog extends StatelessWidget {
  final String lRoomId;

  const RoomCreatedDialog({super.key, required this.lRoomId});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final roomLink = "${Uri.base.origin}/?roomId=$lRoomId";
    return AlertDialog(
      title: const Text('Room Created'),
      content: Container(
        margin: EdgeInsets.only(top: TSizes.sm),
        padding: EdgeInsets.symmetric(
          vertical: TSizes.sm,
          horizontal: TSizes.lg,
        ),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeNotifier.themeData.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                roomLink,
                style: themeNotifier.themeData.textTheme.titleLarge,
              ),
            ),
            AppSpacing.hLg,
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: roomLink));
                Navigator.of(context).pop();
                CompDialog.show(
                  context: context,
                  message: 'Room ID copied to clipboard',
                  dialogStyle: DialogStyle.success,
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
