class TranscriptEntry {
  final String speaker; // 'local' or 'remote'
  final String text;
  final DateTime timestamp;

  TranscriptEntry({
    required this.speaker,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'speaker': speaker,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TranscriptEntry.fromJson(Map<String, dynamic> json) =>
      TranscriptEntry(
        speaker: json['speaker'],
        text: json['text'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}
