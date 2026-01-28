import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_flutter_firebase_webrtc/roomListDialog.dart';
import 'package:new_flutter_firebase_webrtc/signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  Signaling? signaling;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool inCalling = false;
  String? roomId;

  bool isVideoOff = false;
  bool isMicMuted = false;
  late TextEditingController _joinRoomTextEditingController;

  @override
  void initState() {
    _joinRoomTextEditingController = TextEditingController();
    _connect();
    super.initState();
  }

  void _connect() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    if (signaling == null) {
      signaling = Signaling();

      signaling?.onLocalStream = ((stream) {
        localRenderer.srcObject = stream;
      });

      signaling?.onAddRemoteStream = ((stream) {
        remoteRenderer.srcObject = stream;
      });

      signaling?.onRemoveRemoteStream = (() {
        remoteRenderer.srcObject = null;
      });

      signaling?.onDisconnect = (() {
        setState(() {
          inCalling = false;
          roomId = null;
        });
      });
    }
  }

  @override
  deactivate() {
    super.deactivate();
    localRenderer.dispose();
    remoteRenderer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),

      body: inCalling ? _buildCallingUI() : _buildHomeUI(),
    );
  }

  Widget _buildCallingUI() {
    return Stack(
      children: <Widget>[
        // Remote video (full screen)
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(color: Colors.black),
          child: RTCVideoView(remoteRenderer),
        ),

        // Local video (small overlay)
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
                  color: Colors.black.withOpacity(0.3),
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

        // Room ID display
        if (roomId != null)
          Positioned(
            top: 50.0,
            left: 20.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
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

        // Control buttons at bottom
        Positioned(
          bottom: 40.0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
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
                    onPressed: () {
                      signaling?.muteMic();
                      setState(() {
                        isMicMuted = !isMicMuted;
                      });
                    },
                    backgroundColor: Colors.white.withOpacity(0.2),
                    iconColor: Colors.white,
                  ),

                  const SizedBox(width: 20),

                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end_rounded,
                    onPressed: () async {
                      await signaling?.hungUp();
                      setState(() {
                        roomId = null;
                        inCalling = false;
                        isMicMuted = false;
                        isVideoOff = false;
                      });
                    },
                    backgroundColor: Colors.red,
                    iconColor: Colors.white,
                    size: 60,
                  ),

                  const SizedBox(width: 20),

                  // Camera switch button (placeholder)
                  _buildControlButton(
                    icon: isVideoOff
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,

                    onPressed: () {
                      _toggleVideo();
                      // Camera switch functionality can be added here
                      setState(() {
                        isVideoOff = !isVideoOff;
                      });
                    },
                    backgroundColor: isVideoOff
                        ? Colors.red.withOpacity(0.8)
                        : Colors.white.withOpacity(0.2),
                    iconColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
            color: backgroundColor.withOpacity(0.4),
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

  Widget _buildHomeUI() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            alignment: Alignment.center,
            width: constraints.maxWidth < 600
                ? constraints.maxWidth
                : constraints.maxWidth / 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.video_call_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  const Text(
                    'Start Video Call',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Create a new room or join an existing one',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                  // Version
                  const SizedBox(height: 12),
                  Text(
                    'Version 1.1.1',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // Create Room Button
                  _buildActionButton(
                    label: 'Create Room',
                    icon: Icons.add_circle_outline_rounded,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onPressed: () async {
                      final lRoomId = await signaling?.createRoom();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Room Created',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Text(
                                    lRoomId!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: lRoomId),
                                    );
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Room ID copied to clipboard',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
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
                        ),
                      );
                      setState(() {
                        roomId = lRoomId;
                        inCalling = true;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Join Room Button
                  _buildActionButton(
                    label: 'Join Room',
                    icon: Icons.login_rounded,
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onPressed: () async {
                      // showDialog(
                      //   context: context,
                      //   builder: (context) => RoomListDialog(
                      //     onRoomSelected: (roomId) async {
                      //       _joinRoom(roomId);
                      //     },
                      //   ),
                      // );
                      _joinRoomTextEditingController.text = "";
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Join Room',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enter Room ID',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _joinRoomTextEditingController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Room ID',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black26,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.meeting_room,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'CANCEL',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('JOIN'),
                            ),
                          ],
                        ),
                      );
                      if (_joinRoomTextEditingController.text.isNotEmpty) {
                        signaling
                            ?.joinRoomById(_joinRoomTextEditingController.text)
                            .then((value) {
                              if (value.isEmpty) {
                                setState(() {
                                  inCalling = true;
                                  roomId = _joinRoomTextEditingController.text;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(value),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            });
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _joinRoom(String roomId) async {
    try {
      setState(() => inCalling = true);

      final response = await signaling?.joinRoomById(roomId);

      if ((response ?? "").isNotEmpty) {
        setState(() => inCalling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join room. ${response.toString()}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Successfully joined room!')));
      }
    } catch (e) {
      setState(() => inCalling = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error joining room: $e')));
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 24, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _toggleVideo() {
    final stream = localRenderer.srcObject;
    if (stream == null) return;

    for (var track in stream.getVideoTracks()) {
      track.enabled = !track.enabled;
    }
  }
}
