import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lottie/lottie.dart';
import 'package:new_flutter_firebase_webrtc/common/background/rive_background.dart';
import 'package:new_flutter_firebase_webrtc/common/dialog/comp_dialog.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/signaling.dart';

class CallingUI extends StatelessWidget {
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;
  final bool isVideoOff;
  final bool isMicMuted;
  final String? roomId;
  final Signaling? signaling;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleMic;
  final VoidCallback onHangUp;

  const CallingUI({
    super.key,
    required this.localRenderer,
    required this.remoteRenderer,
    required this.isVideoOff,
    required this.isMicMuted,
    required this.roomId,
    required this.signaling,
    required this.onToggleVideo,
    required this.onToggleMic,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    return RiveBackground(
      child: Stack(
        children: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: _buildRemoteView(context),
          ),

          Positioned(
            right: 20.0,
            top: 50.0,
            child: Container(
              width: 120.0,
              height: 160.0,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: isVideoOff
                  ? const Center(
                      child: Icon(
                        Icons.videocam_off,
                        color: Colors.white,
                        size: 40,
                      ),
                    )
                  : RTCVideoView(localRenderer, mirror: true),
            ),
          ),

          if (roomId != null)
            Positioned(
              top: 50.0,
              left: 20.0,
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: roomId ?? ""));

                  CompDialog.show(
                    context: context,
                    message: "Room ID copied successfully",
                    dialogStyle: DialogStyle.success,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.meeting_room,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Room: ${(roomId ?? "").length > 7 ? roomId!.substring(0, 8) : roomId}...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 40.0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Mute button
                    _buildControlButton(
                      icon: isMicMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      onPressed: onToggleMic,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      iconColor: Colors.white,
                    ),

                    const SizedBox(width: 20),

                    _buildControlButton(
                      icon: Icons.call_end_rounded,
                      onPressed: onHangUp,
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                      size: 60,
                    ),

                    const SizedBox(width: 20),

                    _buildControlButton(
                      icon: isVideoOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      onPressed: onToggleVideo,
                      backgroundColor: isVideoOff
                          ? Colors.red.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.2),
                      iconColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteView(BuildContext context) {
    if (remoteRenderer.srcObject == null) {
      return Center(
        child: Container(
          alignment: Alignment.center,
          width: 200,
          height: 200,
          child: Lottie.asset(
            'assets/lottie/searchDoctor.json',
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    if (remoteRenderer.srcObject!.getVideoTracks().isEmpty) {
      return Container(
        color: Colors.grey[900],
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 80,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "User Connected (Audio Only)",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RTCVideoView(
      remoteRenderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color iconColor,
    double size = 50,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: size * 0.45),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
