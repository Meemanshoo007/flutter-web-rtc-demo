import 'dart:async';
import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:new_flutter_firebase_webrtc/common/dialog/comp_dialog.dart';
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
  bool isInitializing = true;
  MediaRecorder? _mediaRecorder;
  bool _isRecording = false;
  // List<String> recordedSegments = []; // Stores the list of Blob URLs
  Timer? _segmentTimer; // Timer to cut audio_recorder every 60 seconds
  MediaStream? _activeStream; // Keep reference to stream for restarts

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

  // --- RECORDING LOGIC ---
  void _startFirstRecording(MediaStream stream) {
    print("meem1");
    // recordedSegments.clear(); // Clear old segments
    print("meem2");
    _startRecordingSegment(stream);
    print("meem3");
    // Start the 60-second timer
    _segmentTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _cycleRecording();
    });
  }

  void _startRecordingSegment(MediaStream stream) async {
    try {
      print("🔥 [Recording] Preparing Audio-Only Stream...");

      // 1. Get the Audio Track from the main stream
      var audioTracks = stream.getAudioTracks();
      if (audioTracks.isEmpty) {
        print("❌ No audio_recorder track found!");
        return;
      }
      var audioTrack = audioTracks.first;

      // 2. Create a NEW "Audio-Only" Stream
      // We give it a unique ID ('audio_only_segment')
      MediaStream audioOnlyStream = await createLocalMediaStream(
        'audio_only_segment',
      );

      // 3. Add the audio_recorder track to this new stream
      audioOnlyStream.addTrack(audioTrack);

      print(
        "🔥 [Recording] Stream Created. Tracks: ${audioOnlyStream.getTracks().length}",
      );

      // 4. Initialize Recorder
      _mediaRecorder = MediaRecorder();

      // 5. Record the NEW stream (Not the camera stream)
      // Now 'audio_recorder/webm' works perfectly because there is no video track!
      _mediaRecorder?.startWeb(
        audioOnlyStream,
        mimeType: 'audio_recorder/webm;codecs=opus',
      );

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print("❌ Error starting record: $e");
      // Fallback: If creating the stream fails, try the original just to be safe
      try {
        print("⚠️ Falling back to video recording...");
        _mediaRecorder?.startWeb(stream, mimeType: 'video/webm');
        setState(() => _isRecording = true);
      } catch (fallbackError) {
        print("❌ Fallback failed: $fallbackError");
      }
    }
  }

  Future<void> _cycleRecording() async {
    print(
      "🔥 [START] ${(!_isRecording || _mediaRecorder == null || _activeStream == null)}",
    );
    if (!_isRecording || _mediaRecorder == null || _activeStream == null)
      return;

    try {
      print("🔥 [START] CycleRecording.");
      // 1. Stop current
      // On Web, stop returns the Blob URL String
      final dynamic result = await _mediaRecorder?.stop();
      if (result != null) {
        // recordedSegments.add(result as String);
        // print("🔥Saved segment #${recordedSegments.length}: $result");

        uploadSegmentToFirebase(
          blobUrl: result,
          roomId: roomId ?? 'unknown_room',
          role: signaling?.currentRole ?? 'unknown',
        );
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
    // final finalSegments = List<String>.from(recordedSegments);
    setState(() {
      roomId = null;
      inCalling = false;
      isMicMuted = false;
      isVideoOff = false;
      // recordedSegments.clear();
    });

    SystemNavigator.routeInformationUpdated(uri: Uri.parse('/'));

    // if (finalSegments.isNotEmpty) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       // NOTE: You need to update RecordingPlaybackScreen to accept List<String>
    //       builder: (context) =>
    //           RecordingPlaybackScreen(sourceUrls: finalSegments),
    //     ),
    //   );
    // }
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

  void addToCloudnary({
    required String blobUrl,
    required String roomId,
    required String role,
  }) async {
    // === Upload to Cloudinary immediately ===
    String role = 'callee';
    final cloudUrl = await uploadSegmentToCloudinary(
      blobUrl: blobUrl,
      roomId: roomId ?? 'unknown_room',
      role: role,
    );

    if (cloudUrl != null) {
      print('Cloudinary URL: $cloudUrl');
      // Optionally store in Firestore:
      // await FirebaseFirestore.instance.collection('rooms/$roomId/segments').add({
      //   'url': cloudUrl,
      //   'role': role,
      //   'createdAt': FieldValue.serverTimestamp(),
      // });
    }
  }

  Future<String?> uploadSegmentToCloudinary({
    required String blobUrl,
    required String roomId,
    required String role,
  }) async {
    try {
      // 1️⃣ Fetch bytes from Blob URL
      final response = await http.get(Uri.parse(blobUrl));
      if (response.statusCode != 200) {
        print('Failed to fetch blob: ${response.statusCode}');
        return null;
      }
      final Uint8List bytes = response.bodyBytes;

      // 2️⃣ Prepare Cloudinary multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dkgrvkurl/video/upload'),
      );

      // Folder structure: roomId/role
      request.fields['upload_preset'] = 'webrtc_demo';
      request.fields['folder'] = '$roomId/$role';

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${DateTime.now().millisecondsSinceEpoch}.webm',
          contentType: http.MediaType('video', 'webm'),
        ),
      );

      // 3️⃣ Send request
      var cloudRes = await request.send();
      if (cloudRes.statusCode != 200 && cloudRes.statusCode != 201) {
        print('Cloudinary upload failed: ${cloudRes.statusCode}');
        return null;
      }

      final resStr = await cloudRes.stream.bytesToString();
      final jsonRes = json.decode(resStr);

      final String uploadedUrl = jsonRes['secure_url'];
      print('Uploaded segment to Cloudinary: $uploadedUrl');

      return uploadedUrl;
    } catch (e) {
      print('Error uploading segment: $e');
      return null;
    }
  }

  Future<String?> uploadSegmentToFirebase({
    required String blobUrl,
    required String roomId,
    required String role,
  }) async {
    print("🔥 [START] Upload to Firebase initiated.");
    print("🔥   -> Blob URL: $blobUrl");
    print("🔥   -> Room ID: $roomId");
    print("🔥   -> Role: $role");

    try {
      // 1️⃣ Fetch bytes from Blob URL
      print("🔥 [Step 1] Fetching bytes from Blob URL...");
      final response = await http.get(Uri.parse(blobUrl));

      print("🔥   -> HTTP Response Code: ${response.statusCode}");

      if (response.statusCode != 200) {
        print('🔥 [ERROR] Failed to fetch blob: ${response.statusCode}');
        return null;
      }

      final Uint8List bytes = response.bodyBytes;
      print(
        "🔥   -> Bytes fetched successfully. Size: ${bytes.lengthInBytes} bytes",
      );

      // 2️⃣ Prepare Firebase Storage Reference
      print("🔥 [Step 2] Preparing Storage Reference...");
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.webm';
      final String fullPath = 'firebaseWebRTCDemo/$roomId/$role/$fileName';

      final Reference ref = FirebaseStorage.instance
          .ref()
          .child(roomId)
          .child(role)
          .child(fileName);

      print("🔥   -> Target Path: $fullPath");

      // 3️⃣ Upload bytes with Metadata
      print("🔥 [Step 3] Starting Upload...");
      // Setting contentType is important for the browser to know it's audio_recorder when playing back
      final metadata = SettableMetadata(contentType: 'audio_recorder/webm');

      // Use putData for raw bytes (standard for Web)
      final UploadTask uploadTask = ref.putData(bytes, metadata);

      // Optional: Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('🔥   -> Upload Progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      print("🔥   -> Upload Task Completed. State: ${snapshot.state}");

      // 4️⃣ Get and return the Download URL
      print("🔥 [Step 4] Getting Download URL...");
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print(
        '🔥 [SUCCESS] Uploaded audio_recorder segment to Firebase: $downloadUrl',
      );

      return downloadUrl;
    } catch (e, stackTrace) {
      print('🔥 [EXCEPTION] Error uploading segment to Firebase:');
      print('🔥   -> Error: $e');
      print('🔥   -> StackTrace: $stackTrace');
      return null;
    }
  }
}
