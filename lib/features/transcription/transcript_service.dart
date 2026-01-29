import 'package:new_flutter_firebase_webrtc/features/transcription/model/TranscriptEntryModel.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class TranscriptService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final List<TranscriptEntry> _transcript = [];
  bool _isListening = false;

  List<TranscriptEntry> get transcript => List.unmodifiable(_transcript);
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    // Initialize speech recognition
    bool available = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );

    return available;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required String speaker,
  }) async {
    if (!_isListening && await _speech.initialize()) {
      _isListening = true;

      await _speech.listen(
        onResult: (result) {
          print("meem listen finalResult - ${result.finalResult}");
          if (result.finalResult) {
            final entry = TranscriptEntry(
              speaker: speaker,
              text: result.recognizedWords,
              timestamp: DateTime.now(),
            );
            _transcript.add(entry);
            onResult(result.recognizedWords);
          }
        },
        listenFor: Duration(minutes: 30), // Max duration
        pauseFor: Duration(seconds: 3), // Pause detection
        partialResults: false,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  void addManualEntry(String speaker, String text) {
    _transcript.add(
      TranscriptEntry(speaker: speaker, text: text, timestamp: DateTime.now()),
    );
  }

  void clearTranscript() {
    _transcript.clear();
  }

  void dispose() {
    _speech.cancel();
  }
}
