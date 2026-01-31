import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:new_flutter_firebase_webrtc/common/dialog/comp_dialog.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/screen/calling_screen.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/screen/home_screen.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:new_flutter_firebase_webrtc/utils/print/print.dart';

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
  bool isInitializing = true;
  MediaRecorder? _mediaRecorder;
  bool _isRecording = false;
  Timer? _segmentTimer;
  MediaStream? _activeStream;

  bool isVideoOff = false;
  bool isMicMuted = false;

  @override
  void initState() {
    signaling = Signaling();
    _connect().then((va) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            isInitializing = false;
          });
          _handleDeepLink();
        }
      });
    });
    super.initState();
  }

  void _handleDeepLink() {
    final uri = Uri.base;

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

  @override
  deactivate() {
    super.deactivate();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _mediaRecorder = null;
    if (_segmentTimer != null) {
      _segmentTimer!.cancel();
    }
  }

  void _startFirstRecording(MediaStream stream) {
    _startRecordingSegment(stream);

    _segmentTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _cycleRecording();
    });
  }

  void _startRecordingSegment(MediaStream stream) async {
    try {
      var audioTracks = stream.getAudioTracks();
      if (audioTracks.isEmpty) {
        compPrint(" No audio_recorder track found!");
        return;
      }
      var audioTrack = audioTracks.first;

      MediaStream audioOnlyStream = await createLocalMediaStream(
        'audio_only_segment',
      );

      audioOnlyStream.addTrack(audioTrack);

      _mediaRecorder = MediaRecorder();

      _mediaRecorder?.startWeb(
        audioOnlyStream,
        mimeType: 'audio_recorder/webm;codecs=opus',
      );

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      compPrint(" Error starting record: $e");

      try {
        compPrint("Falling back to video recording...");
        _mediaRecorder?.startWeb(stream, mimeType: 'video/webm');
        setState(() => _isRecording = true);
      } catch (fallbackError) {
        compPrint("Fallback failed: $fallbackError");
      }
    }
  }

  Future<void> _cycleRecording() async {
    if (!_isRecording || _mediaRecorder == null || _activeStream == null) {
      return;
    }

    try {
      final dynamic result = await _mediaRecorder?.stop();
      if (result != null) {
        uploadSegmentToFirebase(
          blobUrl: result,
          roomId: roomId ?? 'unknown_room',
          role: signaling?.currentRole ?? 'unknown',
        );
      }

      _startRecordingSegment(_activeStream!);
    } catch (e) {
      compPrint("Error cycling recording: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isInitializing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Initializing Camera..."),
                ],
              ),
            )
          : inCalling
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
          // recordedSegments.add(result as String);
        }
      } catch (e) {
        print("Error stopping recorder: $e");
      }
      _isRecording = false;
    }

    await signaling?.hungUp();
    setState(() {
      roomId = null;
      inCalling = false;
      isMicMuted = false;
      isVideoOff = false;
    });

    SystemNavigator.routeInformationUpdated(uri: Uri.parse('/'));
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

  Future<String?> uploadSegmentToFirebase({
    required String blobUrl,
    required String roomId,
    required String role,
  }) async {
    try {
      final response = await http.get(Uri.parse(blobUrl));

      if (response.statusCode != 200) {
        compPrint('Failed to fetch blob: ${response.statusCode}');
        return null;
      }

      final Uint8List bytes = response.bodyBytes;

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.webm';

      final Reference ref = FirebaseStorage.instance
          .ref()
          .child(roomId)
          .child(role)
          .child(fileName);

      final metadata = SettableMetadata(contentType: 'audio_recorder/webm');

      final UploadTask uploadTask = ref.putData(bytes, metadata);

      // Optional: Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        compPrint('Upload Progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      compPrint('Uploaded audio_recorder segment to Firebase: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      compPrint('Error: $e');
      return null;
    }
  }
}
