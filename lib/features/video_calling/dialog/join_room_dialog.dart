import 'package:flutter/material.dart';
import 'package:new_flutter_firebase_webrtc/utils/sizing/app_sizing.dart';
import 'package:new_flutter_firebase_webrtc/utils/theme/controller/theme_controller.dart';
import 'package:provider/provider.dart';

class JoinRoomDialog extends StatefulWidget {
  final Function(String roomId) onRoomSelected;

  const JoinRoomDialog({super.key, required this.onRoomSelected});

  @override
  State<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<JoinRoomDialog> {
  late TextEditingController _joinRoomTextEditingController;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _joinRoomTextEditingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return AlertDialog(
      title: const Text('Join Room'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Room ID',
            style: themeNotifier.themeData.textTheme.bodySmall,
          ),
          AppSpacing.vMd,
          TextField(
            controller: _joinRoomTextEditingController,

            decoration: InputDecoration(hintText: 'Room ID'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'CANCEL',
            style: themeNotifier.themeData.textTheme.labelMedium,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onRoomSelected(_joinRoomTextEditingController.text);
          },
          child: Text(
            'JOIN',
            style: themeNotifier.themeData.textTheme.bodyLarge!.copyWith(
              color: themeNotifier.themeData.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

// Animated Live Indicator Widget
class _LiveIndicator extends StatefulWidget {
  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
