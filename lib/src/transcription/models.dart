class TranscriptionResult {
  TranscriptionResult({
    required this.text,
    required this.chunks,
    required this.languages,
  });

  final String text;
  final List<WhisperChunk> chunks;
  final List<String>? languages;

  factory TranscriptionResult.fromMap(Map<String, dynamic> map) {
    final chunks = (map['chunks'] as List<dynamic>? ?? [])
        .map((e) => WhisperChunk.fromMap(e as Map<String, dynamic>))
        .toList();
    final langs = map['languages'] as List<dynamic>?;
    return TranscriptionResult(
      text: (map['text'] as String?) ?? '',
      chunks: chunks,
      languages: langs?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'chunks': chunks.map((c) => c.toMap()).toList(),
    'languages': languages,
  };
}

class WhisperChunk {
  WhisperChunk({
    required this.text,
    required this.timestamp,
  });

  final String text;
  final List<num>? timestamp;

  factory WhisperChunk.fromMap(Map<String, dynamic> map) {
    final ts = map['timestamp'] as List<dynamic>?;
    return WhisperChunk(
      text: (map['text'] as String?) ?? '',
      timestamp: ts?.map((e) => e as num).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'timestamp': timestamp,
  };
}

