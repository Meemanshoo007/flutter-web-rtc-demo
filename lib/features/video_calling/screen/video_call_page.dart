import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_flutter_firebase_webrtc/common/dialog/comp_dialog.dart';
import 'package:new_flutter_firebase_webrtc/features/recording_playback_screen.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/screen/calling_screen.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/screen/home_screen.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/signaling.dart';
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

  MediaRecorder? _mediaRecorder;
  bool _isRecording = false;
  List<String> _recordedSegments = []; // Stores the list of Blob URLs
  Timer? _segmentTimer; // Timer to cut audio every 60 seconds
  MediaStream? _activeStream; // Keep reference to stream for restarts

  bool isVideoOff = false;
  bool isMicMuted = false;

  @override
  void initState() {
    _connect().then((va) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeepLink();
      });
    });
    super.initState();
  }

  void _handleDeepLink() {
    // 1. Get the current URL
    final uri = Uri.base;

    // 2. Check for 'roomId' query parameter
    if (uri.queryParameters.containsKey('roomId')) {
      final String? deepLinkRoomId = uri.queryParameters['roomId'];

      if (deepLinkRoomId != null && deepLinkRoomId.isNotEmpty) {
        setState(() {
          _handleJoinRoom(deepLinkRoomId);
        });
      }
    }
  }

  Future<void> _connect() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    if (signaling == null) {
      signaling = Signaling();

      signaling?.onLocalStream = ((stream) {
        localRenderer.srcObject = stream;
        _activeStream = stream;
        _startFirstRecording(stream);
      });

      signaling?.onAddRemoteStream = ((stream) {
        remoteRenderer.srcObject = stream;
      });

      signaling?.onRemoveRemoteStream = (() {
        remoteRenderer.srcObject = null;
      });

      signaling?.onDisconnect = (() {
        if (mounted && inCalling) {
          _handleHangUp();
        }
      });
    }
  }

  @override
  deactivate() {
    super.deactivate();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _mediaRecorder = null;
  }

  // --- RECORDING LOGIC ---
  void _startFirstRecording(MediaStream stream) {
    _recordedSegments.clear(); // Clear old segments
    _startRecordingSegment(stream);

    // Start the 60-second timer
    _segmentTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _cycleRecording();
    });
  }

  void _startRecordingSegment(MediaStream stream) {
    try {
      _mediaRecorder = MediaRecorder();

      // Start recording (WebM format)
      _mediaRecorder?.startWeb(stream, mimeType: 'video/webm;codecs=vp8,opus');

      setState(() {
        _isRecording = true;
      });
      print("Started recording segment #${_recordedSegments.length + 1}");
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<void> _cycleRecording() async {
    if (!_isRecording || _mediaRecorder == null || _activeStream == null)
      return;

    try {
      // 1. Stop current
      // On Web, stop returns the Blob URL String
      final dynamic result = await _mediaRecorder?.stop();
      if (result != null) {
        _recordedSegments.add(result as String);
        print("Saved segment #${_recordedSegments.length}: $result");
      }

      // 2. Restart immediately
      _startRecordingSegment(_activeStream!);
    } catch (e) {
      print("Error cycling recording: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: inCalling
          ? CallingUI(
              localRenderer: localRenderer,
              remoteRenderer: remoteRenderer,
              isVideoOff: isVideoOff,
              isMicMuted: isMicMuted,
              roomId: roomId,
              signaling: signaling,
              onToggleVideo: _handleToggleVideo,
              onToggleMic: _handleToggleMic,
              onHangUp: _handleHangUp,
            )
          : HomeUI(
              signaling: signaling,
              onCreateRoom: _handleCreateRoom,
              onJoinRoom: _handleJoinRoom,
            ),
    );
  }

  void _handleToggleVideo() {
    _toggleVideo();
    setState(() {
      isVideoOff = !isVideoOff;
    });
  }

  void _handleToggleMic() {
    signaling?.muteMic();
    setState(() {
      isMicMuted = !isMicMuted;
    });
  }

  Future<void> _handleHangUp() async {
    if (_isRecording && _mediaRecorder != null) {
      try {
        // On Web, stopWeb returns the Blob URL string
        dynamic result = await _mediaRecorder?.stop();
        if (result != null) {
          _recordedSegments.add(result as String);
          print(
            "Saved final segment. Total segments: ${_recordedSegments.length}",
          );
        }
      } catch (e) {
        print("Error stopping recorder: $e");
      }
      _isRecording = false;
    }

    await signaling?.hungUp();
    final finalSegments = List<String>.from(_recordedSegments);
    setState(() {
      roomId = null;
      inCalling = false;
      isMicMuted = false;
      isVideoOff = false;
      _recordedSegments.clear();
    });

    SystemNavigator.routeInformationUpdated(uri: Uri.parse('/'));

    if (finalSegments.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          // NOTE: You need to update RecordingPlaybackScreen to accept List<String>
          builder: (context) =>
              RecordingPlaybackScreen(sourceUrls: finalSegments),
        ),
      );
    }
  }

  void _handleCreateRoom(String lRoomId) {
    setState(() {
      roomId = lRoomId;
      inCalling = true;
    });
  }

  Future<void> _handleJoinRoom(String roomId) async {
    try {
      setState(() => inCalling = true);

      final response = await signaling?.joinRoomById(roomId);

      if ((response ?? "").isNotEmpty) {
        setState(() => inCalling = false);

        CompDialog.show(
          context: context,
          message: 'Failed to join room. ${response.toString()}',
          dialogStyle: DialogStyle.error,
        );
      } else {
        setState(() => this.roomId = roomId);
        CompDialog.show(
          context: context,
          message: 'Successfully joined room!',
          dialogStyle: DialogStyle.success,
        );
      }
    } catch (e) {
      setState(() => inCalling = false);

      CompDialog.show(
        context: context,
        message: 'Error joining room: $e',
        dialogStyle: DialogStyle.error,
      );
    }
  }

  void _toggleVideo() {
    final stream = localRenderer.srcObject;
    if (stream == null) return;

    for (var track in stream.getVideoTracks()) {
      track.enabled = !track.enabled;
    }
  }
}
