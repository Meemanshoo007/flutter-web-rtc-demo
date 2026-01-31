import 'package:flutter/material.dart';
import 'package:new_flutter_firebase_webrtc/common/background/rive_background.dart';
import 'package:new_flutter_firebase_webrtc/features/audio_recorder/provider/audio_recorder_provider.dart';
import 'package:provider/provider.dart';

class RecordingPage extends StatelessWidget {
  const RecordingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioRecorderProvider>(context);

    return RiveBackground(
      child: Container(
        padding: EdgeInsets.only(bottom: 20),
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              iconSize: 120,
              icon: Icon(
                Icons.mic,
                color: provider.isRecording ? Colors.red : Colors.grey,
              ),
              onPressed: provider.isRecording
                  ? provider.stopRecording
                  : provider.startRecording,
            ),
            Text(
              provider.isRecording
                  ? "Recording Chunk: ${provider.chunkIndex}"
                  : "Idle",
            ),
          ],
        ),
      ),
    );
  }
}
