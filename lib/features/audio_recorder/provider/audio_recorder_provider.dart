import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class AudioRecorderProvider extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _onDataSubscription;

  final List<int> _audioBuffer = [];

  Timer? _timer;
  bool _isRecording = false;
  int _chunkIndex = 0;
  String _sessionId = '';

  bool get isRecording => _isRecording;
  int get chunkIndex => _chunkIndex;

  Future<void> startRecording1() async {
    if (await _recorder.hasPermission()) {
      _isRecording = true;
      _chunkIndex = 0;
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _audioBuffer.clear();

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );

      _onDataSubscription = stream.listen((data) {
        _audioBuffer.addAll(data);
      });

      _timer = Timer.periodic(const Duration(seconds: 60), (t) {
        _uploadCurrentBuffer();
      });

      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    try {
      debugPrint("Checking permissions...");
      final hasPermission = await _recorder.hasPermission();

      if (hasPermission) {
        _isRecording = true;
        _chunkIndex = 0;
        _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
        _audioBuffer.clear();

        debugPrint("Starting stream...");
        final stream = await _recorder
            .startStream(
              const RecordConfig(
                encoder: AudioEncoder.pcm16bits,
                sampleRate: 44100,
                numChannels: 1,
              ),
            )
            .catchError((e) {
              debugPrint("Stream error: $e");
              throw e;
            });

        _onDataSubscription = stream.listen((data) {
          _audioBuffer.addAll(data);
        });

        _timer = Timer.periodic(const Duration(seconds: 60), (t) {
          _uploadCurrentBuffer();
        });

        notifyListeners();
      } else {
        debugPrint("User denied microphone access.");
      }
    } catch (e, stack) {
      _isRecording = false;
      debugPrint("Fatal error during startRecording: $e");
      debugPrint("Stack: $stack");
      notifyListeners();
    }
  }

  void _uploadCurrentBuffer() {
    if (_audioBuffer.isEmpty) return;

    final rawBytes = Uint8List.fromList(_audioBuffer);

    final wavBytes = _addWavHeader(rawBytes, 44100);

    _audioBuffer.clear();
    _uploadToFirebase(wavBytes, _chunkIndex++);
  }

  Future<void> _uploadToFirebase(Uint8List bytes, int index) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'recordings/$_sessionId/chunk_$index.wav',
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

    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);

    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitDepth, Endian.little);

    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);

    final Uint8List wavFile = Uint8List(44 + pcmData.length);
    wavFile.setRange(0, 44, header.buffer.asUint8List());
    wavFile.setRange(44, wavFile.length, pcmData);

    return wavFile;
  }

  Future<void> stopRecording() async {
    _isRecording = false;
    _timer?.cancel();

    await _onDataSubscription?.cancel();
    _onDataSubscription = null;

    await _recorder.stop();

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
