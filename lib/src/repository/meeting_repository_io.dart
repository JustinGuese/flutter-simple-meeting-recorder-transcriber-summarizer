import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/meeting.dart';

class MeetingRepository {
  MeetingRepository({required Object meetingsDir})
      : _meetingsDir = meetingsDir is Directory
            ? meetingsDir
            : throw ArgumentError.value(
                meetingsDir,
                'meetingsDir',
                'Expected a dart:io Directory on IO platforms.',
              );

  final Directory _meetingsDir;

  String get meetingsDirPath => _meetingsDir.path;

  Future<List<Meeting>> loadAll() async {
    if (!await _meetingsDir.exists()) return [];
    final files = await _meetingsDir
        .list()
        .where((e) => e is File && e.path.endsWith('.md'))
        .cast<File>()
        .toList();
    final meetings = <Meeting>[];
    for (final file in files) {
      try {
        final markdown = await file.readAsString();
        meetings.add(_parseMeetingMarkdown(markdown));
      } catch (_) {
        // Skip corrupt files silently
      }
    }
    meetings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return meetings;
  }

  Future<void> save(Meeting meeting) async {
    if (!await _meetingsDir.exists()) {
      await _meetingsDir.create(recursive: true);
    }
    final filename = '${meeting.safeFilename}_${meeting.id}.md';
    // Delete any existing file for this meeting (handles renames)
    await _deleteById(meeting.id, except: filename);
    final file = File(p.join(_meetingsDir.path, filename));
    final markdown = _meetingToMarkdown(meeting);
    await file.writeAsString(markdown, flush: true);
  }

  Future<void> delete(Meeting meeting) async {
    await _deleteById(meeting.id);
  }

  Future<void> _deleteById(String id, {String? except}) async {
    if (!await _meetingsDir.exists()) return;
    final files = await _meetingsDir.list().toList();
    for (final file in files) {
      if (file is File && file.path.endsWith('.md') && file.path.contains(id)) {
        if (except != null && file.path.endsWith(except)) continue;
        await file.delete();
      }
    }
  }

  String _meetingToMarkdown(Meeting meeting) {
    final buffer = StringBuffer();
    buffer.writeln('# ${meeting.title}');
    buffer.writeln();
    buffer.writeln('**Date**: ${meeting.createdAt.toIso8601String()}');
    buffer.writeln('**Status**: ${meeting.transcriptionStatus.name}');
    if (meeting.languages.isNotEmpty) {
      buffer.writeln('**Languages**: ${meeting.languages.join(", ")}');
    }
    if (meeting.summaryStatus == SummaryStatus.completed &&
        (meeting.summary?.trim().isNotEmpty ?? false)) {
      buffer.writeln('**SummaryStatus**: ${meeting.summaryStatus.name}');
    }
    buffer.writeln();

    if (meeting.notes.isNotEmpty) {
      buffer.writeln('## Notes');
      buffer.writeln();
      buffer.writeln(meeting.notes);
      buffer.writeln();
    }

    if (meeting.summaryStatus == SummaryStatus.completed &&
        (meeting.summary?.trim().isNotEmpty ?? false)) {
      buffer.writeln('## Summary');
      buffer.writeln();
      buffer.writeln(meeting.summary!.trim());
      buffer.writeln();
    }

    if (meeting.transcription.isNotEmpty) {
      buffer.writeln('## Transcript');
      buffer.writeln();
      buffer.writeln(meeting.transcription);
    }

    return buffer.toString();
  }

  Meeting _parseMeetingMarkdown(String markdown) {
    final lines = markdown.split('\n');
    String title = 'Meeting';
    DateTime createdAt = DateTime.now();
    String notes = '';
    String summary = '';
    SummaryStatus summaryStatus = SummaryStatus.none;
    String transcription = '';
    List<String> languages = [];
    TranscriptionStatus status = TranscriptionStatus.none;

    int i = 0;
    // Parse title
    if (lines.isNotEmpty && lines[0].startsWith('#')) {
      title = lines[0].replaceFirst('# ', '').trim();
      i = 1;
    }

    while (i < lines.length) {
      final line = lines[i];

      if (line.startsWith('**Date**:')) {
        try {
          createdAt = DateTime.parse(line.replaceFirst('**Date**:', '').trim());
        } catch (_) {}
      } else if (line.startsWith('**Status**:')) {
        final statusStr = line.replaceFirst('**Status**:', '').trim();
        status = TranscriptionStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => TranscriptionStatus.none,
        );
      } else if (line.startsWith('**Languages**:')) {
        final langsStr = line.replaceFirst('**Languages**:', '').trim();
        languages = langsStr.split(',').map((l) => l.trim()).toList();
      } else if (line.startsWith('**SummaryStatus**:')) {
        final statusStr = line.replaceFirst('**SummaryStatus**:', '').trim();
        summaryStatus = SummaryStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => SummaryStatus.none,
        );
      } else if (line == '## Notes') {
        i++;
        // Collect note lines until next section
        while (i < lines.length && !lines[i].startsWith('##')) {
          if (lines[i].isNotEmpty) notes += '${lines[i]}\n';
          i++;
        }
        notes = notes.trim();
        continue;
      } else if (line == '## Summary') {
        i++;
        // Collect summary lines until next section
        while (i < lines.length && !lines[i].startsWith('##')) {
          if (lines[i].isNotEmpty) summary += '${lines[i]}\n';
          i++;
        }
        summary = summary.trim();
        continue;
      } else if (line == '## Transcript') {
        i++;
        // Collect transcript lines
        while (i < lines.length) {
          transcription += '${lines[i]}\n';
          i++;
        }
        transcription = transcription.trim();
        break;
      }

      i++;
    }

    // Generate a deterministic ID from the creation timestamp
    final id = '${createdAt.year}-${createdAt.month.toString().padLeft(2, "0")}-'
        '${createdAt.day.toString().padLeft(2, "0")}-${createdAt.hour.toString().padLeft(2, "0")}-'
        '${createdAt.minute.toString().padLeft(2, "0")}-${createdAt.second.toString().padLeft(2, "0")}';

    return Meeting(
      id: id,
      title: title,
      createdAt: createdAt,
      notes: notes,
      transcription: transcription,
      summary: summary.isNotEmpty ? summary : null,
      summaryStatus: summaryStatus,
      transcriptionStatus: status,
      languages: languages,
    );
  }
}

