import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class RecordingPlaybackScreen extends StatefulWidget {
  // CHANGED: Now accepts a list of URLs instead of a single string
  final List<String> sourceUrls;

  const RecordingPlaybackScreen({super.key, required this.sourceUrls});

  @override
  State<RecordingPlaybackScreen> createState() =>
      _RecordingPlaybackScreenState();
}

class _RecordingPlaybackScreenState extends State<RecordingPlaybackScreen> {
  late AudioPlayer _audioPlayer;

  // State variables
  int playingIndex = -1; // -1 means nothing is selected/playing
  bool isPlaying = false;
  bool isLoading = false;

  // Duration of the CURRENT playing segment
  Duration currentSegmentDuration = Duration.zero;
  Duration currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  void _initAudio() {
    _audioPlayer = AudioPlayer();

    // 1. Listen to Play/Pause State
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    // 2. Listen to Duration (Updates when a new file is loaded)
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted && newDuration.inSeconds > 0) {
        setState(() {
          currentSegmentDuration = newDuration;
          isLoading = false;
        });
      }
    });

    // 3. Listen to Position
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          currentPosition = newPosition;

          // Web Fix: Self-correct duration if metadata was missing
          if (currentPosition > currentSegmentDuration) {
            currentSegmentDuration = currentPosition;
            isLoading = false;
          }
        });
      }
    });

    // 4. Auto-Play Next Part
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted && playingIndex < widget.sourceUrls.length - 1) {
        // If there is a next part, play it automatically
        _playSegment(playingIndex + 1);
      } else {
        // End of playlist
        setState(() {
          isPlaying = false;
          currentPosition = Duration.zero;
        });
      }
    });
  }

  // --- LOGIC TO PLAY A SPECIFIC FILE ---
  Future<void> _playSegment(int index) async {
    // If tapping the currently playing song, just toggle pause/resume
    if (playingIndex == index) {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
      return;
    }

    // Changing tracks
    try {
      setState(() {
        isLoading = true;
        playingIndex = index;
        currentPosition = Duration.zero;
        currentSegmentDuration = Duration.zero; // Reset until metadata loads
      });

      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(widget.sourceUrls[index]);
      await _audioPlayer.resume();
    } catch (e) {
      print("Error playing segment $index: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Call Recordings")),
      body: Column(
        children: [
          // Global Player Controls (Only visible if something is selected)
          if (playingIndex != -1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Playing Part ${playingIndex + 1}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isLoading
                            ? "Loading..."
                            : _formatDuration(currentSegmentDuration),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (currentSegmentDuration.inSeconds > 0)
                        ? (currentPosition.inSeconds /
                                  currentSegmentDuration.inSeconds)
                              .clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_formatDuration(currentPosition)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: playingIndex > 0
                            ? () => _playSegment(playingIndex - 1)
                            : null,
                      ),
                      FloatingActionButton(
                        mini: true,
                        onPressed: () {
                          if (isPlaying)
                            _audioPlayer.pause();
                          else
                            _audioPlayer.resume();
                        },
                        child: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: playingIndex < widget.sourceUrls.length - 1
                            ? () => _playSegment(playingIndex + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // The List of Files
          Expanded(
            child: widget.sourceUrls.isEmpty
                ? const Center(child: Text("No recordings available"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.sourceUrls.length,
                    itemBuilder: (context, index) {
                      final isSelected = (playingIndex == index);

                      return Card(
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          side: isSelected
                              ? const BorderSide(color: Colors.blue, width: 2)
                              : BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Colors.blue
                                : Colors.grey.shade200,
                            child: Icon(
                              isSelected
                                  ? (isPlaying ? Icons.pause : Icons.play_arrow)
                                  : Icons.play_arrow,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                          title: Text(
                            "Recording Part ${index + 1}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.blue : Colors.black,
                            ),
                          ),
                          subtitle: Text("Segment #${index + 1}"),
                          onTap: () => _playSegment(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
