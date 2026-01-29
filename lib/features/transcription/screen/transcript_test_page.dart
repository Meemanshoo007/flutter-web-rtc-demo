import 'package:flutter/material.dart';
import 'package:new_flutter_firebase_webrtc/common/dialog/comp_dialog.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class TranscriptionTestPage extends StatefulWidget {
  const TranscriptionTestPage({Key? key}) : super(key: key);

  @override
  State<TranscriptionTestPage> createState() => _TranscriptionTestPageState();
}

class _TranscriptionTestPageState extends State<TranscriptionTestPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool isReconnecting = false;
  bool _isAvailable = false;
  String _currentWords = '';

  double soundLevel = 0;

  String _fullTranscript = '';
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showPermissionDialog();
      return;
    }

    // Initialize speech recognition
    bool available = await _speech.initialize(
      onError: (error) {
        print('Speech error: $error');
        setState(() {
          _isListening = false;
        });
        _showErrorSnackbar('Error: ${error.errorMsg}');
      },
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );

    setState(() {
      _isAvailable = available;
    });

    if (!available) {
      _showErrorSnackbar('Speech recognition not available on this device');
    }
  }

  void _startListening() async {
    if (!_isAvailable) {
      _showErrorSnackbar('Speech recognition not available');
      return;
    }

    await _speech.listen(
      pauseFor: const Duration(seconds: 30),
      onResult: (result) {
        setState(() {
          _currentWords = result.recognizedWords;
          _confidence = result.confidence;

          // When result is final, add to history
          print("meem - finalResult ${result.finalResult}");
          if (result.finalResult) {
            if (isReconnecting) {
              _startListening();
            }

            if (_currentWords.isNotEmpty) {
              _fullTranscript += '${_currentWords}\n';
            }
          }
        });
      },
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    setState(() {
      _isListening = true;
      isReconnecting = true;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      isReconnecting = false;
      if (_currentWords.isNotEmpty) {
        _fullTranscript += '${_currentWords}\n';
      }
    });
  }

  void _clearTranscript() {
    setState(() {
      _fullTranscript = '';
      _currentWords = '';
      _confidence = 0.0;
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'This app needs microphone access to transcribe your speech. Please grant permission in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    CompDialog.show(
      context: context,
      message: message,
      dialogStyle: DialogStyle.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcription Test'),
        actions: [
          if (_currentWords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearTranscript,
              tooltip: 'Clear transcript',
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          _buildStatusCard(),

          // Current Speaking Text (Real-time)
          if (_currentWords.isNotEmpty) _buildCurrentSpeakingCard(),
        ],
      ),
      floatingActionButton: _buildMicButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isListening
              ? [Colors.red.shade400, Colors.orange.shade400]
              : [Colors.blue.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isListening ? Colors.red : Colors.blue).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isListening ? 'Listening...' : 'Ready to Listen',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isListening
                      ? 'Speak now and see real-time transcription'
                      : 'Tap the microphone to start',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_isListening)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const _AnimatedSoundWave(),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentSpeakingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.keyboard_voice, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Speaking now...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const Spacer(),
              if (_confidence > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(_confidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_confidence * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              Text(
                soundLevel.toString(),
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentWords,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'No transcript yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the microphone button to start',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.blue.shade600),
                const SizedBox(height: 8),
                Text(
                  'Tips for best results:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Speak clearly and at a moderate pace\n'
                  '• Reduce background noise\n'
                  '• Hold device at comfortable distance',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _isListening
              ? [Colors.red.shade400, Colors.orange.shade400]
              : [Colors.blue.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isListening ? Colors.red : Colors.blue).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isListening ? _stopListening : _startListening,
          borderRadius: BorderRadius.circular(40),
          child: Center(
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 36,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

// Animated sound wave widget
class _AnimatedSoundWave extends StatefulWidget {
  const _AnimatedSoundWave();

  @override
  State<_AnimatedSoundWave> createState() => _AnimatedSoundWaveState();
}

class _AnimatedSoundWaveState extends State<_AnimatedSoundWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final height = 4 + (value * 12);

            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
