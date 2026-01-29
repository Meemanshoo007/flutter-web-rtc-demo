import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_flutter_firebase_webrtc/common/dialog/comp_dialog.dart';
import 'package:new_flutter_firebase_webrtc/features/transcription/model/TranscriptEntryModel.dart';

import 'package:intl/intl.dart';

class TranscriptPage extends StatelessWidget {
  final List<TranscriptEntry> transcript;

  const TranscriptPage({super.key, required this.transcript});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Transcript'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: () => _copyFullTranscript(context),
            tooltip: 'Copy full transcript',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareTranscript(context),
            tooltip: 'Share transcript',
          ),
        ],
      ),
      body: transcript.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transcript.length,
                    itemBuilder: (context, index) {
                      return _buildTranscriptItem(transcript[index]);
                    },
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
          Icon(Icons.transcribe, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No transcript available',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'The conversation was not transcribed',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final duration = transcript.isNotEmpty
        ? transcript.last.timestamp.difference(transcript.first.timestamp)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Entries: ${transcript.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Duration: ${_formatDuration(duration)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
          ),
          if (transcript.isNotEmpty)
            Text(
              DateFormat('MMM dd, yyyy').format(transcript.first.timestamp),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildTranscriptItem(TranscriptEntry entry) {
    final isLocal = entry.speaker == 'local';
    final timeStr = DateFormat('HH:mm:ss').format(entry.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: isLocal ? Colors.blue : Colors.green,
            radius: 20,
            child: Icon(
              isLocal ? Icons.person : Icons.person_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isLocal ? 'You' : 'Remote',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLocal ? Colors.blue : Colors.green,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLocal ? Colors.blue.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLocal
                          ? Colors.blue.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Text(
                    entry.text,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _copyFullTranscript(BuildContext context) {
    final fullText = transcript
        .map((entry) {
          final speaker = entry.speaker == 'local' ? 'You' : 'Remote';
          final time = DateFormat('HH:mm:ss').format(entry.timestamp);
          return '[$time] $speaker: ${entry.text}';
        })
        .join('\n\n');

    Clipboard.setData(ClipboardData(text: fullText));
    CompDialog.show(
      context: context,
      message: "Transcript copied to clipboard",
      dialogStyle: DialogStyle.success,
    );
  }

  void _shareTranscript(BuildContext context) {
    // You can integrate with share_plus package for actual sharing
    final fullText = transcript
        .map((entry) {
          final speaker = entry.speaker == 'local' ? 'You' : 'Remote';
          final time = DateFormat('HH:mm:ss').format(entry.timestamp);
          return '[$time] $speaker: ${entry.text}';
        })
        .join('\n\n');

    // For now, just copy to clipboard
    Clipboard.setData(ClipboardData(text: fullText));

    CompDialog.show(
      context: context,
      message: 'Transcript ready to share (copied to clipboard)',
      dialogStyle: DialogStyle.success,
    );
  }
}
