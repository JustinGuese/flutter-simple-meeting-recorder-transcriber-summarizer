import 'dart:convert';

enum TranscriptionStatus { none, inProgress, completed, failed }

enum SummaryStatus { none, inProgress, completed, failed }

class Meeting {
  final String id;
  String title;
  final DateTime createdAt;
  String notes;
  String transcription;
  List<WhisperChunkRecord> chunks;
  List<String> languages;
  TranscriptionStatus transcriptionStatus;
  String? audioFilePath;
  String? errorMessage;
  String? summary;
  SummaryStatus summaryStatus;
  String? summaryModel;
  DateTime? summaryGeneratedAt;
  String? summaryErrorMessage;
  DateTime? updatedAt;

  Meeting({
    required this.id,
    required this.title,
    required this.createdAt,
    this.notes = '',
    this.transcription = '',
    this.chunks = const [],
    this.languages = const [],
    this.transcriptionStatus = TranscriptionStatus.none,
    this.audioFilePath,
    this.errorMessage,
    this.summary,
    this.summaryStatus = SummaryStatus.none,
    this.summaryModel,
    this.summaryGeneratedAt,
    this.summaryErrorMessage,
    this.updatedAt,
  });

  factory Meeting.create() {
    final now = DateTime.now();
    final id = _generateId(now);
    final title = _defaultTitle(now);
    return Meeting(id: id, title: title, createdAt: now);
  }

  static String _generateId(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$y-$m-$d-$h-$min-$s';
  }

  static String _defaultTitle(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return 'Meeting $y-$m-$d $h:$min';
  }

  /// Generate filename safe version of title for file storage
  String get safeFilename {
    final safe = title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '-');
    return safe.length > 50 ? safe.substring(0, 50) : safe;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'notes': notes,
    'transcription': transcription,
    'chunks': chunks.map((c) => c.toJson()).toList(),
    'languages': languages,
    'transcriptionStatus': transcriptionStatus.name,
    'audioFilePath': audioFilePath,
    'errorMessage': errorMessage,
    'summary': summary,
    'summaryStatus': summaryStatus.name,
    'summaryModel': summaryModel,
    'summaryGeneratedAt': summaryGeneratedAt?.toIso8601String(),
    'summaryErrorMessage': summaryErrorMessage,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    notes: (json['notes'] as String?) ?? '',
    transcription: (json['transcription'] as String?) ?? '',
    chunks: ((json['chunks'] as List<dynamic>?) ?? [])
        .map((e) => WhisperChunkRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    languages: ((json['languages'] as List<dynamic>?) ?? [])
        .map((e) => e as String)
        .toList(),
    transcriptionStatus: TranscriptionStatus.values.firstWhere(
      (s) => s.name == (json['transcriptionStatus'] as String?),
      orElse: () => TranscriptionStatus.none,
    ),
    audioFilePath: json['audioFilePath'] as String?,
    errorMessage: json['errorMessage'] as String?,
    summary: json['summary'] as String?,
    summaryStatus: SummaryStatus.values.firstWhere(
      (s) => s.name == (json['summaryStatus'] as String?),
      orElse: () => SummaryStatus.none,
    ),
    summaryModel: json['summaryModel'] as String?,
    summaryGeneratedAt: json['summaryGeneratedAt'] != null
        ? DateTime.tryParse(json['summaryGeneratedAt'] as String)
        : null,
    summaryErrorMessage: json['summaryErrorMessage'] as String?,
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null,
  );

  String toJsonString() => jsonEncode(toJson());

  factory Meeting.fromJsonString(String s) =>
      Meeting.fromJson(jsonDecode(s) as Map<String, dynamic>);

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        transcription.toLowerCase().contains(q) ||
        notes.toLowerCase().contains(q);
  }
}

class WhisperChunkRecord {
  final String text;
  final double? start;
  final double? end;

  const WhisperChunkRecord({required this.text, this.start, this.end});

  Map<String, dynamic> toJson() => {
    'text': text,
    'start': start,
    'end': end,
  };

  factory WhisperChunkRecord.fromJson(Map<String, dynamic> json) =>
      WhisperChunkRecord(
        text: json['text'] as String,
        start: (json['start'] as num?)?.toDouble(),
        end: (json['end'] as num?)?.toDouble(),
      );
}
