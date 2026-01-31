import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class AudioRecorderProvider extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _onDataSubscription;

  // Buffer to hold the current minute of audio
  final List<int> _audioBuffer = [];

  Timer? _timer;
  bool _isRecording = false;
  int _chunkIndex = 0;
  String _sessionId = '';

  bool get isRecording => _isRecording;
  int get chunkIndex => _chunkIndex;

  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      _isRecording = true;
      _chunkIndex = 0;
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _audioBuffer.clear();

      // 1. Start the stream.
      // Using PCM 16-bit is safest for raw stream manipulation on Web.
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );

      // 2. Listen to the data chunks and add them to our buffer
      _onDataSubscription = stream.listen((data) {
        _audioBuffer.addAll(data);
      });

      // 3. Set a timer to "slice" the buffer every 60 seconds
      _timer = Timer.periodic(const Duration(seconds: 60), (t) {
        _uploadCurrentBuffer();
      });

      notifyListeners();
    }
  }

  void _uploadCurrentBuffer() {
    if (_audioBuffer.isEmpty) return;

    final rawBytes = Uint8List.fromList(_audioBuffer);
    // Convert RAW to WAV
    final wavBytes = _addWavHeader(rawBytes, 44100);

    _audioBuffer.clear();
    _uploadToFirebase(wavBytes, _chunkIndex++);
  }

  Future<void> _uploadToFirebase(Uint8List bytes, int index) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'recordings/$_sessionId/chunk_$index.wav', // Saving as .raw or .pcm
      );

      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'audio/wav; rate=44100'),
      );
    } catch (e) {
      debugPrint("Upload error: $e");
    }
  }

  Uint8List _addWavHeader(Uint8List pcmData, int sampleRate) {
    final int channels = 1;
    final int bitDepth = 16;
    final int byteRate = (sampleRate * channels * bitDepth) ~/ 8;
    final int blockAlign = (channels * bitDepth) ~/ 8;
    final int dataSize = pcmData.length;
    final int fileSize = 36 + dataSize;

    final ByteData header = ByteData(44);

    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little); // Subchunk1Size
    header.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitDepth, Endian.little);

    // data sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final Uint8List wavFile = Uint8List(44 + pcmData.length);
    wavFile.setRange(0, 44, header.buffer.asUint8List());
    wavFile.setRange(44, wavFile.length, pcmData);

    return wavFile;
  }

  Future<void> stopRecording() async {
    _isRecording = false;
    _timer?.cancel();

    // Stop the stream subscription
    await _onDataSubscription?.cancel();
    _onDataSubscription = null;

    // Stop the recorder hardware
    await _recorder.stop();

    // Upload the final remaining bits in the buffer
    if (_audioBuffer.isNotEmpty) {
      _uploadCurrentBuffer();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _onDataSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
